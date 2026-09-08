import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ZisoTriviaApp());
class ZisoTriviaApp extends StatelessWidget { const ZisoTriviaApp({super.key}); @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Ziso Trivia', theme: ThemeData.dark(), home: const ZisoTriviaScreen()); }

class FeedItem { final String user; final String text; final bool correct; final bool firstGreen; final String? feedback; FeedItem(this.user,this.text,this.correct,this.firstGreen,{this.feedback}); }
class UserScore { String name; int score; UserScore(this.name,this.score); }
class Question { final String type; final String text; final List<String> mustContain; final bool needsDiagram; Question(this.type,this.text,this.mustContain,{this.needsDiagram=false}); }
class SpeedQ { final String type; final String q; final String a; final List<String>? options; SpeedQ(this.type,this.q,this.a,[this.options]); }

class ZisoTriviaScreen extends StatefulWidget { const ZisoTriviaScreen({super.key}); @override State<ZisoTriviaScreen> createState()=>_ZisoTriviaScreenState(); }

class _ZisoTriviaScreenState extends State<ZisoTriviaScreen> {
  final topics = ["DC Circuits & Power Rails", "MOSFETs & VRM Section", "SMPS & TV Power Board", "T-Con & LVDS Cable", "Battery Charging"];
  final textOnlyQuestions = [
    Question("short","WHAT is KCL in simple words? WHAT & HOW?",["sum","zero","junction","current"]),
    Question("medium","WHAT does MOSFET do as a switch? HOW does gate control?",["gate","switch","controls","on off"]),
    Question("short","WHAT is SMPS full form? WHAT & HOW does it work?",["switch","mode","power","supply"]),
    Question("medium","WHY does T-Con fail cause white screen? WHAT & HOW?",["timing","lvds","panel","signal"]),
    Question("short","WHAT protects battery from overcharging? WHAT & HOW?",["charging","ic","protection","mosfet"]),
    Question("long","HOW do you test if VRM is shorted without power? WHAT rule?",["resistance","multimeter","short","continuity"]),
    Question("medium","WHAT causes TV to blink 3 times? WHAT & HOW is protection?",["backlight","led","driver","protection"]),
    Question("short","WHAT is series vs parallel in laptop charging path?",["same current","different","path"]),
  ];
  final diagramQuestions = [
    Question("long","In THIS diagram, WHAT circuit is this? HOW many loops for KVL?",["complex","multi","loop","2 loops"], needsDiagram: true),
    Question("medium","In THIS VRM diagram, WHAT controls MOSFET? HOW if gate fails?",["gate","driver","pwm"], needsDiagram: true),
    Question("long","In THIS SMPS, WHAT converts AC to DC first? WHAT after transformer?",["bridge","rectifier","led driver"], needsDiagram: true),
  ];
  final speedQuestions = [
    SpeedQ("fill","Fill missing: The sum of currents at a junction is ____","zero"),
    SpeedQ("scramble","Unscramble: SMFTEO (hint: laptop switch)","MOSFET"),
    SpeedQ("truefalse","True/False: R1 and R2 are in parallel (diagram above shows series)","false"),
    SpeedQ("mcq","Which board drives LEDs in Smart TV?","c",["a) T-Con","b) Main Board","c) Inverter/LED Driver","d) LVDS"]),
    SpeedQ("fill","Fill: KVL says sum of ____ around loop is zero","voltage"),
    SpeedQ("scramble","Unscramble: SMPS = Switch Mode ____ Supply","POWER"),
    SpeedQ("truefalse","True/False: T-Con generates backlight voltage","false"),
    SpeedQ("mcq","Fastest way to find shorted VRM?","b",["a) Replace CPU","b) Check resistance to ground","c) Replace battery","d) Update BIOS"]),
  ];

  final feedbackCorrect = ["Correct!","Good!","Impressive!","Excellent!","Awesome!","Fantastic!"];
  final botNames = ["VoltVandal","SolderSista"];
  int onlineUsers=10, topicIndex=0, topicTimeLeft=200, qIndex=0, timer=30, myScore=0, topicChangeCount=0, conceptCountSinceSpeed=0;
  String phase='concept'; // concept | speed
  bool showDiagramNow = false;
  List<FeedItem> feed=[];
  TextEditingController inputCtrl=TextEditingController();
  FocusNode inputFocus = FocusNode();
  List<UserScore> leaderboard=[UserScore("You",0),UserScore("VoltVandal",120),UserScore("SolderSista",90),UserScore("CapKing",200),UserScore("DiodeSlayer",180)];
  Timer? topicTimer, questionTimer;

  @override void initState(){super.initState(); _startTopicTimer(); _startQuestionTimer();}
  int _getRandomTime()=>Random().nextInt(30)+150;
  int _getRandomTopic(int c){int n;do{n=Random().nextInt(topics.length);}while(n==c);return n;}
  bool get botsEnabled=>(onlineUsers>=9&&onlineUsers<=11)?true:(onlineUsers>=15&&onlineUsers<=17)?false:onlineUsers<15;
  Question get currentConceptQ => showDiagramNow? diagramQuestions[qIndex%diagramQuestions.length] : textOnlyQuestions[qIndex%textOnlyQuestions.length];
  SpeedQ get currentSpeedQ=>speedQuestions[qIndex%speedQuestions.length];
  bool _realAICheck(String a, Question q){String ans=a.toLowerCase();if(ans.length<8)return false;int m=q.mustContain.where((k)=>ans.contains(k)).length;return m>=1;}

  void _startTopicTimer(){
    topicTimer?.cancel();
    topicTimer=Timer.periodic(const Duration(seconds:1),(t){
      setState((){
        if(topicTimeLeft<=1){
          topicIndex=_getRandomTopic(topicIndex); topicChangeCount++; qIndex=0; phase='concept'; feed=[]; timer=30; topicTimeLeft=_getRandomTime();
          if (topicChangeCount % 5 == 0 && topicChangeCount!=0) showDiagramNow=true; else showDiagramNow=false;
        } else topicTimeLeft--;
      });
    });
  }
  void _startQuestionTimer(){
    questionTimer?.cancel();
    questionTimer=Timer.periodic(const Duration(seconds:1),(t){
      setState((){
        if(timer<=1){ _goNextQuestion(auto: true); } else { timer--; if(phase=='speed'&&timer>7) timer=7; }
      });
    });
  }

  void _goNextQuestion({bool auto=false}) {
    setState(() {
      // LOGIC YOU ASKED: After 4 concept Qs -> go to speed (7s)
      if (phase=='concept') {
        conceptCountSinceSpeed++;
        if (conceptCountSinceSpeed >= 4) {
          phase='speed'; qIndex=0; timer=7; // START SPEED SERIES
          conceptCountSinceSpeed=0;
          return;
        }
        // next concept
        qIndex++; timer=30; // change to 90/120/180 later for final
      } else {
        // speed phase: 4 speed questions then back to concept
        qIndex++;
        if (qIndex >= 4) {
          phase='concept'; qIndex=0; timer=30; qIndex=Random().nextInt(textOnlyQuestions.length);
        } else {
          timer=7;
        }
      }
    });
    _triggerBot();
  }

  void _triggerBot(){
    if(!botsEnabled||phase!='concept') return;
    Future.delayed(Duration(milliseconds:1500+Random().nextInt(2500)),(){
      if(!mounted) return;
      bool ok=Random().nextDouble()<0.666;
      String name=botNames[Random().nextInt(botNames.length)];
      bool isFirst =!feed.any((f)=>f.correct);
      setState(() {
        if (ok) {
          feed.add(FeedItem(name,"${currentConceptQ.mustContain.first} - junction rule / split current concept",true,isFirst, feedback: isFirst? "FIRST GREEN! → Next Q in 2s" : feedbackCorrect[Random().nextInt(feedbackCorrect.length)]));
          leaderboard.firstWhere((u)=>u.name==name).score+= isFirst?20:10;
          if (isFirst) {
            Future.delayed(const Duration(milliseconds: 2000), () { if(!mounted) return; setState(()=>feed=[]); _goNextQuestion(); });
          }
        } else {
          feed.add(FeedItem(name,"maybe series?",false,false,feedback:"wrong!"));
        }
      });
    });
  }

  void submitAnswer(){
    if(inputCtrl.text.trim().isEmpty) return;
    bool ok=false;
    if (phase=='concept') ok=_realAICheck(inputCtrl.text,currentConceptQ);
    else ok=inputCtrl.text.toLowerCase().trim()==currentSpeedQ.a.toLowerCase() || inputCtrl.text.toLowerCase().trim().contains(currentSpeedQ.a.toLowerCase());

    bool isFirst = ok &&!feed.any((f)=>f.correct);
    setState(() {
      feed.add(FeedItem("You",inputCtrl.text,ok,isFirst,feedback: ok? (isFirst? "YOU FIRST GREEN! → Next Q in 2s" : feedbackCorrect[Random().nextInt(feedbackCorrect.length)]) : "wrong!"));
      if (ok) { myScore+=isFirst?20:10; leaderboard.firstWhere((u)=>u.name=="You").score+=isFirst?20:10; }
    });
    inputCtrl.clear();
    inputFocus.requestFocus();

    if (ok && isFirst) {
      // First correct moves everyone after 2s - NO LOCK, everyone can still answer for 10 XP
      Future.delayed(const Duration(milliseconds: 2000), () { if(!mounted) return; setState(()=>feed=[]); _goNextQuestion(); });
    }
  }

  @override void dispose(){topicTimer?.cancel();questionTimer?.cancel();inputFocus.dispose();super.dispose();}
  Widget _buildDiagram() {
    if (!showDiagramNow) return const Center(child: Text("No diagram - Text only concept (saves data)", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 11)));
    if (topicIndex==0) return CustomPaint(size: const Size(320, 110), painter: CircuitPainter1());
    else if (topicIndex==1) return CustomPaint(size: const Size(320, 110), painter: MosfetPainter());
    else return CustomPaint(size: const Size(320, 110), painter: SmpsPainter());
  }

  @override Widget build(BuildContext context){
    var sorted=[...leaderboard]..sort((a,b)=>b.score.compareTo(a.score));
    String qText=phase=='concept'?currentConceptQ.text:currentSpeedQ.q;
    double prog=phase=='speed'?timer/7:timer/30;
    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(8), child: Column(children:[
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A1B9A),Color(0xFF283593)]), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Ziso Trivia",style:TextStyle(fontWeight:FontWeight.w900,fontSize:20)), Text("NQF 5 • ${topics[topicIndex]}",style: const TextStyle(fontSize:10))])),
      const SizedBox(height:6),
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Column(children:[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Shuffle: ${topicTimeLeft~/60}:${(topicTimeLeft%60).toString().padLeft(2,'0')} left",style: const TextStyle(fontSize:11)), Text("Changes: $topicChangeCount/5 → Diagram | ${conceptCountSinceSpeed}/4 → Speed",style: const TextStyle(fontSize:9, color: Colors.amber))]),
        const SizedBox(height:4),
        Row(children:[Expanded(child: LinearProgressIndicator(value: (topicChangeCount%5)/5, backgroundColor: Colors.grey[800], color: Colors.amber)), const SizedBox(width:8), Expanded(child: LinearProgressIndicator(value: conceptCountSinceSpeed/4, backgroundColor: Colors.grey[800], color: Colors.greenAccent))]),
        Text(phase=='speed'? "⚡ SPEED ROUND - 7s ONLY! Fill/Scramble/TF/MCQ" : showDiagramNow? "★ DIAGRAM QUESTION" : "Concept phase - ${4-conceptCountSinceSpeed} Qs left then SPEED", style: TextStyle(fontSize:10, color: phase=='speed'? Colors.yellowAccent : Colors.white54))
      ])),
      const SizedBox(height:6),
      AnimatedContainer(duration: const Duration(milliseconds:400), height: showDiagramNow? 150 : 55, width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: showDiagramNow? Colors.white : Colors.grey[300], borderRadius: BorderRadius.circular(8), border: Border.all(color: showDiagramNow? Colors.amber : Colors.grey, width: showDiagramNow?3:1)), child: Column(children:[Text(showDiagramNow? "DIAGRAM FIXED" : "NO DIAGRAM",style: const TextStyle(color:Colors.black,fontWeight:FontWeight.bold,fontSize:10)), const SizedBox(height:2), Expanded(child: _buildDiagram())])),
      const SizedBox(height:8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("${phase.toUpperCase()} - Q${qIndex+1} ${phase=='speed'?'7s ONLY!':'${timer}s'} ${feed.any((f)=>f.correct)?'• FIRST FOUND - 2s to next':''}",style: const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold,fontSize:12)), Text(phase=='speed'? currentSpeedQ.type.toUpperCase() : showDiagramNow? "With Diagram" : "Text Only", style: TextStyle(fontSize:9, color: phase=='speed'? Colors.yellowAccent : Colors.white54))]), const SizedBox(height:6), LinearProgressIndicator(value: prog.clamp(0,1), backgroundColor: Colors.grey[700], color: phase=='speed'? Colors.yellowAccent : Colors.greenAccent), const SizedBox(height:10), Text(qText,style: const TextStyle(fontSize:14)), if(phase=='speed' && currentSpeedQ.options!=null) Padding(padding: const EdgeInsets.only(top:6), child: Text(currentSpeedQ.options!.join(" | "), style: const TextStyle(fontSize:11, color: Colors.white70)))])),
      const SizedBox(height:8),
      Container(height: 130, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade800)), child: feed.isEmpty? Text(phase=='speed'? "Speed Q! Type fast - 7s only!" : "No lock! First correct = 20 XP, others = 10 XP before next Q",style: const TextStyle(color:Colors.white38,fontSize:12)) : ListView.builder(itemCount: feed.length, itemBuilder: (c,i){var f=feed[i];return Container(margin: const EdgeInsets.only(bottom:3), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: f.firstGreen?Colors.green[700]:f.correct?const Color(0xFF424242):Colors.transparent, borderRadius: BorderRadius.circular(4)), child: Text("${f.user}: ${f.text} ${f.feedback!=null?'→ ${f.feedback}':''}",style:TextStyle(fontSize:12,color: f.firstGreen?Colors.white: f.correct?Colors.white:Colors.redAccent, fontWeight: f.firstGreen? FontWeight.bold : FontWeight.normal)));})),
      const SizedBox(height:8),
      TextField(controller: inputCtrl, focusNode: inputFocus, autofocus: true, enableSuggestions: true, textInputAction: TextInputAction.send, onSubmitted: (v)=>submitAnswer(), style: const TextStyle(color:Colors.white), decoration: InputDecoration(hintText: phase=='speed'? "FAST! 7s only - type answer..." : "Type concept (phone keyboard)...", filled: true, fillColor: const Color(0xFF424242), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.greenAccent), onPressed: submitAnswer))),
      const SizedBox(height:8),
      Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Text("Leaderboard Top 3",style:TextStyle(fontWeight:FontWeight.bold,fontSize:12)),...sorted.take(3).map((u)=>Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("#${sorted.indexOf(u)+1} ${u.name}"), Text("${u.score} XP")])), Text("You: #${sorted.indexWhere((u)=>u.name=='You')+1} - $myScore XP",style: const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold, fontSize:11))]))
    ]))));
  }
}
class CircuitPainter1 extends CustomPainter { @override void paint(Canvas canvas, Size size) { var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:10,fontWeight:FontWeight.bold)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);}; canvas.drawRect(const Rect.fromLTWH(20,30,10,40), paint); tp("18V", const Offset(15,75)); canvas.drawRect(const Rect.fromLTWH(260,60,10,40), paint); tp("24V", const Offset(255,105)); canvas.drawLine(const Offset(30,30), const Offset(100,30), paint); tp("R1=2Ω", const Offset(60,15)); canvas.drawLine(const Offset(100,30), const Offset(100,60), paint); canvas.drawLine(const Offset(100,60), const Offset(30,60), paint); canvas.drawLine(const Offset(30,60), const Offset(30,70), paint); canvas.drawLine(const Offset(100,60), const Offset(180,60), paint); tp("R2=5Ω", const Offset(130,45)); canvas.drawLine(const Offset(180,60), const Offset(180,30), paint); canvas.drawLine(const Offset(180,30), const Offset(260,30), paint); canvas.drawLine(const Offset(260,30), const Offset(260,60), paint); canvas.drawCircle(const Offset(180,60), 4, Paint()..color=Colors.red); canvas.drawLine(const Offset(180,60), const Offset(220,60), paint); tp("R3=8Ω", const Offset(200,62)); canvas.drawLine(const Offset(220,60), const Offset(220,90), paint); canvas.drawLine(const Offset(220,90), const Offset(30,90), paint); canvas.drawLine(const Offset(180,65), const Offset(180,90), paint); tp("R4=6Ω", const Offset(155,85)); canvas.drawLine(const Offset(180,90), const Offset(30,90), paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
class MosfetPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:9)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);}; canvas.drawRect(const Rect.fromLTWH(40,20,60,50), paint); tp("Dual MOSFET", const Offset(45,5)); canvas.drawRect(const Rect.fromLTWH(140,30,30,30), paint); tp("L=Coil", const Offset(140,10)); canvas.drawRect(const Rect.fromLTWH(210,20,60,50), paint); tp("CPU CORE", const Offset(220,5)); canvas.drawLine(const Offset(100,45), const Offset(140,45), paint); canvas.drawLine(const Offset(170,45), const Offset(210,45), paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
class SmpsPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:8)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);}; canvas.drawRect(const Rect.fromLTWH(10,30,50,30), paint); tp("Bridge", const Offset(15,15)); canvas.drawRect(const Rect.fromLTWH(80,20,40,50), paint); tp("Transformer", const Offset(80,5)); canvas.drawRect(const Rect.fromLTWH(140,30,50,30), paint); tp("LED Driver", const Offset(140,15)); canvas.drawRect(const Rect.fromLTWH(210,30,50,30), paint); tp("Fuse", const Offset(220,15)); canvas.drawLine(const Offset(60,45), const Offset(80,45), paint); canvas.drawLine(const Offset(120,45), const Offset(140,45), paint); canvas.drawLine(const Offset(190,45), const Offset(210,45), paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
