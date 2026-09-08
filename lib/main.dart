import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ZisoTriviaApp());

class ZisoTriviaApp extends StatelessWidget {
  const ZisoTriviaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Ziso Trivia', theme: ThemeData.dark(), home: const ZisoTriviaScreen());
}

class FeedItem { final String user; final String text; final bool correct; final bool firstGreen; final String? feedback; FeedItem(this.user,this.text,this.correct,this.firstGreen,{this.feedback}); }
class UserScore { String name; int score; UserScore(this.name,this.score); }
class Question { final String type; final String text; final List<String> mustContain; Question(this.type,this.text,this.mustContain); }
class SpeedQ { final String type; final String q; final String a; final List<String>? options; SpeedQ(this.type,this.q,this.a,[this.options]); }

class _ZisoTriviaScreenState extends State<ZisoTriviaScreen> {
  final topics = ["DC Circuits & Power Rails", "MOSFETs & VRM Section", "SMPS & TV Power Board", "T-Con & LVDS Cable", "Battery Charging"];
  final conceptQuestions = [
    Question("short","WHAT type of circuit structure is this? Series, parallel, or complex multi-loop?",["complex","multi","loop"]),
    Question("medium","WHAT does it mean when 18V and 24V oppose each other? HOW do you know dominating battery?",["oppose","dominating","24"]),
    Question("long","WHAT rule governs current at junction of R2,R3,R4?",["kirchhoff","junction","kcl","split"]),
    Question("medium","WHAT is voltage drop in terms of energy?",["energy","heat","conversion"]),
    Question("long","WHAT is purpose of R4 branch?",["alternative","branch","parallel"]),
    Question("short","WHAT principle determines biggest energy conversion?",["power","resistance","current"]),
    Question("medium","WHAT happens if one branch has higher resistance?",["less current","higher"]),
    Question("long","HOW many distinct closed loops can you identify?",["2 loops","3 loops","two","three"]),
    Question("short","WHAT does it mean R1 and R2 are in same path?",["series","same current"]),
    Question("medium","WHAT is first step with two batteries?",["polarity","direction","net"]),
    Question("long","WHAT happens to current direction with opposing batteries?",["reverse","opposite","24v"]),
    Question("short","WHAT does it mean R3 and R4 are NOT in series?",["parallel","different"]),
  ];
  final speedQuestions = [
    SpeedQ("fill","The sum of currents at a junction is ____","zero"),
    SpeedQ("scramble","Unscramble: SMFTEO","MOSFET"),
    SpeedQ("truefalse","R1 and R2 are in parallel","false"),
    SpeedQ("mcq","Which board drives LEDs?","c",["a) T-Con","b) Main Board","c) Inverter/LED Driver","d) LVDS"]),
  ];
  final feedbackCorrect = ["Correct!","Good!","Impressive!","Excellent!","Awesome!"];
  final botNames = ["VoltVandal","SolderSista"];
  int onlineUsers=10, topicIndex=0, topicTimeLeft=280, qIndex=0, timer=120, myScore=0;
  String phase='concept';
  List<FeedItem> feed=[];
  TextEditingController inputCtrl=TextEditingController();
  List<UserScore> leaderboard=[UserScore("You",0),UserScore("VoltVandal",120),UserScore("SolderSista",90),UserScore("CapKing",200),UserScore("DiodeSlayer",180)];
  Timer? topicTimer, questionTimer;

  @override void initState(){super.initState(); _startTopicTimer(); _startQuestionTimer();}
  int _getRandomTime()=>Random().nextInt(60)+240;
  int _getRandomTopic(int c){int n;do{n=Random().nextInt(topics.length);}while(n==c);return n;}
  bool get botsEnabled=>(onlineUsers>=9&&onlineUsers<=11)?true:(onlineUsers>=15&&onlineUsers<=17)?false:onlineUsers<15;
  Question get currentConceptQ=>conceptQuestions[qIndex%conceptQuestions.length];
  SpeedQ get currentSpeedQ=>speedQuestions[qIndex%speedQuestions.length];
  bool _realAICheck(String a, Question q){String ans=a.toLowerCase();if(ans.length<8)return false;int m=q.mustContain.where((k)=>ans.contains(k)).length;return m>=1;}

  void _startTopicTimer(){topicTimer?.cancel();topicTimer=Timer.periodic(const Duration(seconds:1),(t){setState((){if(topicTimeLeft<=1){topicIndex=_getRandomTopic(topicIndex);qIndex=0;phase='concept';feed=[];timer=120;topicTimeLeft=_getRandomTime();}else topicTimeLeft--;});});}
  void _startQuestionTimer(){questionTimer?.cancel();questionTimer=Timer.periodic(const Duration(seconds:1),(t){setState((){if(timer<=1){if(phase=='concept'&&qIndex>=9){phase='speed';qIndex=0;timer=7;_triggerBot();return;}if(phase=='speed'){qIndex++;timer=7;}else{qIndex++;var next=conceptQuestions[qIndex%conceptQuestions.length];timer=next.type=='short'?90:next.type=='medium'?120:180;}_triggerBot();}else{timer--;if(phase=='speed'&&timer>7)timer=7;}});});}
  void _triggerBot(){if(!botsEnabled||phase!='concept')return;Future.delayed(Duration(milliseconds:2000+Random().nextInt(2000)),(){if(!mounted)return;bool ok=Random().nextDouble()<0.666;String name=botNames[Random().nextInt(botNames.length)];bool first=!feed.any((f)=>f.firstGreen);setState((){feed.add(FeedItem(name,ok?"Conceptually, ${currentConceptQ.mustContain.first} - currents split":"Maybe series?",ok,ok&&first));if(ok)leaderboard.firstWhere((u)=>u.name==name).score+=10;});});}
  void submitAnswer(){if(inputCtrl.text.trim().isEmpty)return;bool ok=phase=='concept'?_realAICheck(inputCtrl.text,currentConceptQ):inputCtrl.text.toLowerCase().trim()==currentSpeedQ.a.toLowerCase();bool first=ok&&!feed.any((f)=>f.firstGreen);setState((){feed.add(FeedItem("You",inputCtrl.text,ok,first,feedback:ok?feedbackCorrect[Random().nextInt(feedbackCorrect.length)]:"wrong!"));if(ok){myScore+=first?20:10;leaderboard.firstWhere((u)=>u.name=="You").score+=first?20:10;}});inputCtrl.clear();}
  @override void dispose(){topicTimer?.cancel();questionTimer?.cancel();super.dispose();}

  Widget _buildDiagram() {
    // REAL DIAGRAM - changes with topicIndex
    if (topicIndex==0) {
      return CustomPaint(size: const Size(320, 110), painter: CircuitPainter1());
    } else if (topicIndex==1) {
      return CustomPaint(size: const Size(320, 110), painter: MosfetPainter());
    } else if (topicIndex==2) {
      return CustomPaint(size: const Size(320, 110), painter: SmpsPainter());
    } else {
      return CustomPaint(size: const Size(320, 110), painter: CircuitPainter1());
    }
  }

  @override Widget build(BuildContext context){
    var sorted=[...leaderboard]..sort((a,b)=>b.score.compareTo(a.score));
    String qText=phase=='concept'?currentConceptQ.text:currentSpeedQ.q;
    double prog=phase=='speed'?timer/7:timer/180;
    var keys="1234567890QWERTYUIOPASDFGHJKLZXCVBNM".split("");
    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(8), child: Column(children:[
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A1B9A),Color(0xFF283593)]), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Ziso Trivia",style:TextStyle(fontWeight:FontWeight.w900,fontSize:20)), Text("NQF 5 • ${topics[topicIndex]}",style: const TextStyle(fontSize:10))])),
      const SizedBox(height:6),
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Shuffle: ${topicTimeLeft~/60}:${(topicTimeLeft%60).toString().padLeft(2,'0')} left (4-5min)",style: const TextStyle(fontSize:11)), Text("Online: $onlineUsers ${botsEnabled?'• Bots ON':'• Bots OFF'}",style: const TextStyle(fontSize:11))])),
      const SizedBox(height:6),
      Container(height: 150, width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber,width:3)), child: Column(children:[const Text("DIAGRAM STAYS FIXED - REAL",style:TextStyle(color:Colors.black,fontWeight:FontWeight.bold,fontSize:11)), const SizedBox(height:4), Expanded(child: _buildDiagram())])),
      const SizedBox(height:8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("${phase.toUpperCase()} - Q${qIndex+1} ${phase=='speed'?'(7s ONLY!)':'($timer s)'}",style: const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold,fontSize:12)), const Text("Same Q for all",style:TextStyle(fontSize:10))]), const SizedBox(height:6), LinearProgressIndicator(value: prog.clamp(0,1), backgroundColor: Colors.grey[700], color: Colors.greenAccent), const SizedBox(height:10), Text(qText,style: const TextStyle(fontSize:14))])),
      const SizedBox(height:8),
      Container(height: 120, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade800)), child: feed.isEmpty? const Text("Live answers...",style:TextStyle(color:Colors.white38,fontSize:12)) : ListView.builder(itemCount: feed.length, itemBuilder: (c,i){var f=feed[i];return Container(margin: const EdgeInsets.only(bottom:4), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: f.firstGreen?Colors.green[700]:f.correct?const Color(0xFF424242):Colors.transparent, borderRadius: BorderRadius.circular(4)), child: Text("${f.user}: ${f.text} ${f.feedback!=null?'→ ${f.feedback}':''}",style:TextStyle(fontSize:12,color: f.firstGreen?Colors.white: f.correct?Colors.white:Colors.redAccent)));})),
      const SizedBox(height:8),
      TextField(controller: inputCtrl, enableSuggestions: false, autocorrect: false, style: const TextStyle(color:Colors.white), decoration: InputDecoration(hintText: "Type concept (no numbers, no V=IR)...", filled: true, fillColor: const Color(0xFF424242), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height:6),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1.2), itemCount: keys.length+2, itemBuilder: (c,i){if(i<keys.length)return ElevatedButton(style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: const Color(0xFF424242)), onPressed: ()=>setState(()=>inputCtrl.text+=keys[i]), child: Text(keys[i],style: const TextStyle(fontSize:10)));else if(i==keys.length)return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]), onPressed: ()=>setState(()=>inputCtrl.text=inputCtrl.text.isNotEmpty?inputCtrl.text.substring(0,inputCtrl.text.length-1):""), child: const Text("DEL",style:TextStyle(fontSize:10)));else return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), onPressed: submitAnswer, child: const Text("SEND",style:TextStyle(fontSize:10)));}),
      const SizedBox(height:8),
      Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Text("Leaderboard Top 3",style:TextStyle(fontWeight:FontWeight.bold,fontSize:12)),...sorted.take(3).map((u)=>Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("#${sorted.indexOf(u)+1} ${u.name}"), Text("${u.score} XP")])), Text("Your position: #${sorted.indexWhere((u)=>u.name=='You')+1} - $myScore XP",style: const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold))]))
    ]))));
  }
}

// --- REAL CIRCUIT PAINTERS ---

class CircuitPainter1 extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    var paint = Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke;
    var textPainter = (String t, Offset o){var tp=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:10,fontWeight:FontWeight.bold)), textDirection:TextDirection.ltr);tp.layout();tp.paint(canvas,o);};
    // 18V Battery left
    canvas.drawRect(const Rect.fromLTWH(20, 30, 10, 40), paint);
    textPainter("18V", const Offset(15, 75));
    // 24V Battery right bottom
    canvas.drawRect(const Rect.fromLTWH(260, 60, 10, 40), paint);
    textPainter("24V", const Offset(255, 105));
    // Wires + Resistors R1,R2,R3,R4
    canvas.drawLine(const Offset(30,30), const Offset(100,30), paint); textPainter("R1=2Ω", const Offset(60,15));
    canvas.drawLine(const Offset(100,30), const Offset(100,60), paint);
    canvas.drawLine(const Offset(100,60), const Offset(30,60), paint);
    canvas.drawLine(const Offset(30,60), const Offset(30,70), paint);
    canvas.drawLine(const Offset(100,60), const Offset(180,60), paint); textPainter("R2=5Ω", const Offset(130,45));
    canvas.drawLine(const Offset(180,60), const Offset(180,30), paint);
    canvas.drawLine(const Offset(180,30), const Offset(260,30), paint);
    canvas.drawLine(const Offset(260,30), const Offset(260,60), paint);
    // Junction at 180,60
    canvas.drawCircle(const Offset(180,60), 4, Paint()..color=Colors.red);
    // R3 branch
    canvas.drawLine(const Offset(180,60), const Offset(220,60), paint); textPainter("R3=8Ω", const Offset(200,62));
    canvas.drawLine(const Offset(220,60), const Offset(220,90), paint);
    canvas.drawLine(const Offset(220,90), const Offset(30,90), paint);
    // R4 branch
    canvas.drawLine(const Offset(180,65), const Offset(180,90), paint); textPainter("R4=6Ω", const Offset(155,85));
    canvas.drawLine(const Offset(180,90), const Offset(30,90), paint);
    // Arrows I1,I2,I3
    textPainter("I1→", const Offset(40,32)); textPainter("I2→", const Offset(120,62)); textPainter("I3→", const Offset(190,92));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}
class MosfetPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke;
    var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:9)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);};
    canvas.drawRect(const Rect.fromLTWH(40,20,60,50), paint); tp("Dual MOSFET", const Offset(45,5));
    canvas.drawRect(const Rect.fromLTWH(140,30,30,30), paint); tp("L=Coil", const Offset(140,10));
    canvas.drawRect(const Rect.fromLTWH(210,20,60,50), paint); tp("CPU CORE", const Offset(220,5));
    canvas.drawLine(const Offset(100,45), const Offset(140,45), paint); canvas.drawLine(const Offset(170,45), const Offset(210,45), paint);
    tp("VRM", const Offset(120,70));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}
class SmpsPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke;
    var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:8)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);};
    canvas.drawRect(const Rect.fromLTWH(10,30,50,30), paint); tp("Bridge", const Offset(15,15));
    canvas.drawRect(const Rect.fromLTWH(80,20,40,50), paint); tp("Transformer", const Offset(80,5));
    canvas.drawRect(const Rect.fromLTWH(140,30,50,30), paint); tp("LED Driver", const Offset(140,15));
    canvas.drawRect(const Rect.fromLTWH(210,30,50,30), paint); tp("Fuse", const Offset(220,15));
    canvas.drawLine(const Offset(60,45), const Offset(80,45), paint); canvas.drawLine(const Offset(120,45), const Offset(140,45), paint); canvas.drawLine(const Offset(190,45), const Offset(210,45), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

class ZisoTriviaScreen extends StatefulWidget { const ZisoTriviaScreen({super.key}); @override State<ZisoTriviaScreen> createState()=>_ZisoTriviaScreenState(); }
