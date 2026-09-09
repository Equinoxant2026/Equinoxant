import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ZisoTriviaApp());
class ZisoTriviaApp extends StatelessWidget { const ZisoTriviaApp({super.key}); @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Ziso Trivia', theme: ThemeData.dark(), home: const ZisoTriviaScreen()); }

class FeedItem { final String user; final String text; final bool correct; final bool firstGreen; final String? feedback; FeedItem(this.user,this.text,this.correct,this.firstGreen,{this.feedback}); }
class UserScore { String name; int score; UserScore(this.name,this.score); }
class Question { final String type; final String text; final List<String> mustContain; final bool needsDiagram; Question(this.type,this.text,this.mustContain,{this.needsDiagram=false}); }
class SpeedQ { final String type; final String q; final String correctText; final List<String> options; SpeedQ(this.type,this.q,this.correctText,this.options); }

class ZisoTriviaScreen extends StatefulWidget { const ZisoTriviaScreen({super.key}); @override State<ZisoTriviaScreen> createState()=>_ZisoTriviaScreenState(); }

class _ZisoTriviaScreenState extends State<ZisoTriviaScreen> {
  final topics = ["DC Circuits & Power Rails", "MOSFETs & VRM Section", "SMPS & TV Power Board", "T-Con & LVDS Cable", "Battery Charging"];

  final textOnlyQuestions = [
    Question("short","WHAT is KCL in simple words? WHAT & HOW?",["sum","zero","junction"]),
    Question("medium","WHAT does MOSFET do as a switch? HOW does gate control?",["gate","switch","control"]),
    Question("short","WHAT is SMPS full form? WHAT & HOW does it work?",["switch","mode","power"]),
    Question("medium","WHY does T-Con fail cause white screen? WHAT & HOW?",["timing","lvds","signal"]),
    Question("short","WHAT protects battery from overcharging? WHAT & HOW?",["charging","ic","protection"]),
    Question("long","HOW do you test if VRM is shorted without power? WHAT rule?",["resistance","ground","multimeter"]),
    Question("medium","WHAT causes TV to blink 3 times? WHAT & HOW is protection?",["backlight","led","protection"]),
    Question("short","WHAT is series vs parallel in laptop charging path?",["same current","different"]),
    Question("short","WHAT is KVL? WHAT & HOW around loop?",["voltage","zero","loop","sum"]),
    Question("medium","WHAT is difference between N-channel and P-channel MOSFET? HOW to identify?",["n channel","p channel","gate","source"]),
    Question("short","WHAT does VRM do in laptop? WHAT & HOW?",["voltage","regulator","cpu","core"]),
    Question("long","WHY does laptop not power on but charging LED on? WHAT rail to check & HOW?",["3v","5v","always","rail"]),
    Question("medium","WHAT is gate driver IC? WHAT & HOW does it drive MOSFET?",["driver","gate","pwm","high"]),
    Question("short","WHAT is buck converter? WHAT & HOW does it step down?",["buck","step down","voltage","coil"]),
    Question("medium","WHAT causes 19V short? HOW to isolate? WHAT method?",["remove","mosfet","injection","resistance"]),
    Question("short","WHAT is LVDS? WHAT & HOW many pairs?",["low voltage","differential","signal","pair"]),
    Question("long","HOW does T-Con create VGH VGL? WHAT & HOW does charge pump work?",["charge pump","vgh","vgl","gate"]),
    Question("medium","WHAT is difference between T-Con and main board? HOW they connect?",["timing","main","lvds","cable"]),
    Question("short","WHAT is fuse role in SMPS? WHAT & HOW it blows?",["overcurrent","protect","short"]),
    Question("medium","WHAT is PFC in TV power board? WHAT & HOW?",["power factor","correction","boost"]),
    Question("short","WHAT is ESD protection? WHAT & HOW?",["electrostatic","discharge","diode"]),
    Question("long","HOW to test SMD capacitor short without removing? WHAT trick?",["in circuit","resistance","beep","parallel"]),
    Question("short","WHAT is BIOS role in no display? WHAT & HOW?",["bios","boot","display","corrupt"]),
    Question("medium","WHAT is charging IC BQ24725? WHAT & HOW does it work?",["charge","controller","battery","adapter"]),
    Question("short","WHAT is backlight driver? WHAT & HOW does it boost?",["boost","led","backlight","voltage"]),
    Question("long","WHY does CPU VRM have 2-3 phases? WHAT & HOW does phase help?",["phase","current","share","heat"]),
    Question("medium","WHAT is low-side vs high-side MOSFET? HOW to test?",["high side","low side","switching"]),
    Question("short","WHAT is SIO chip? WHAT & HOW controls power?",["super io","power","sequence"]),
    Question("medium","WHAT is RTC section? WHAT & HOW does 3V keep BIOS?",["rtc","battery","3v","cmos"]),
    Question("short","WHAT causes no backlight but picture faint? WHAT & HOW?",["inverter","led driver","backlight"]),
  ];

  final diagramQuestions = [
    Question("long","In THIS complex diagram, WHAT circuit is this? HOW many loops for KVL? WHAT is KCL at junction?",["complex","multi","loop","kcl","kvl"], needsDiagram: true),
    Question("medium","In THIS VRM diagram, WHAT controls MOSFET? HOW if gate stuck high?",["gate","driver","pwm"], needsDiagram: true),
    Question("long","In THIS SMPS, WHAT converts AC to DC first? WHAT after transformer? HOW does it regulate?",["bridge","rectifier","regulation"], needsDiagram: true),
    Question("medium","In THIS T-Con, WHAT is VGH? HOW much volt? WHAT if missing?",["vgh","20","30","gate"], needsDiagram: true),
    Question("long","In THIS battery path, WHAT is charging MOSFET? HOW does it block reverse?",["charging","mosfet","blocking"], needsDiagram: true),
    Question("medium","In THIS diagram with 18V and 24V opposing, WHAT is I1 relation to I2 and I3? HOW KCL?",["i1","i2","i3","kcl"], needsDiagram: true),
  ];

  final speedQuestions = [
    SpeedQ("fill","Fill missing: Sum of currents at a junction is ____","zero",["zero","infinite","voltage","current"]),
    SpeedQ("fill","Fill: KVL says sum of ____ around a closed loop is zero","voltage",["voltage","current","resistance","power"]),
    SpeedQ("fill","Fill: MOSFET full form is Metal Oxide ____ FET","semiconductor",["semiconductor","silicon","super","switch"]),
    SpeedQ("fill","Fill: SMPS = Switch Mode ____ Supply","power",["power","panel","phase","pulse"]),
    SpeedQ("fill","Fill: T-Con = Timing ____ Board","control",["control","converter","cable","circuit"]),
    SpeedQ("fill","Fill: LVDS = Low Voltage ____ Signaling","differential",["differential","digital","direct","dual"]),
    SpeedQ("fill","Fill: VRM = Voltage ____ Module","regulator",["regulator","rail","resistor","rectifier"]),
    SpeedQ("fill","Fill: Buck converter steps ____ voltage","down",["down","up","ac","high"]),
    SpeedQ("scramble","Unscramble: SMFTEO (laptop switch)","mosfet",["mosfet","fetsom","mosfte","fetmos"]),
    SpeedQ("scramble","Unscramble: SPMS (power board type)","smps",["smps","psms","smsp","msp s"]),
    SpeedQ("scramble","Unscramble: MVR (cpu power)","vrm",["vrm","mvr","rmv","vmr"]),
    SpeedQ("scramble","Unscramble: SVDL (display cable)","lvds",["lvds","svdl","ldvs","dlvs"]),
    SpeedQ("scramble","Unscramble: NOCT (timing board)","tcon",["tcon","noct","cotn","tocn"]),
    SpeedQ("scramble","Unscramble: TAEG (mosfet pin)","gate",["gate","taeg","etga","gaet"]),
    SpeedQ("scramble","Unscramble: KCL law = Kirchhoff's ____ Law","current",["current","circuit","charge","control"]),
    SpeedQ("truefalse","True/False: R1 and R2 in your diagram are in series","true",["true","false"]),
    SpeedQ("truefalse","True/False: T-Con generates backlight voltage","false",["true","false"]),
    SpeedQ("truefalse","True/False: VRM provides 19V to CPU","false",["true","false"]),
    SpeedQ("truefalse","True/False: KCL says sum of currents at junction = 0","true",["true","false"]),
    SpeedQ("truefalse","True/False: N-channel MOSFET needs negative gate to turn on","false",["true","false"]),
    SpeedQ("truefalse","True/False: SMPS uses high frequency transformer","true",["true","false"]),
    SpeedQ("truefalse","True/False: 3V/5V always rail is present when battery in","true",["true","false"]),
    SpeedQ("truefalse","True/False: Backlight driver failure gives white screen","false",["true","false"]),
    SpeedQ("mcq","Which board drives LED strips in TV?","Inverter/LED Driver",["T-Con","Main Board","Inverter/LED Driver","LVDS Cable"]),
    SpeedQ("mcq","Fastest way to find shorted VRM?","Check resistance to ground",["Replace CPU","Check resistance to ground","Replace battery","Update BIOS"]),
    SpeedQ("mcq","What controls MOSFET on/off?","Gate voltage",["Drain current","Gate voltage","Source resistance","Temperature"]),
    SpeedQ("mcq","Which voltage is VGH approx?","+20 to +30V",["+3.3V","-6V","+20 to +30V","+12V"]),
    SpeedQ("mcq","KVL deals with?","Voltage around loop",["Current at junction","Voltage around loop","Resistance in parallel","Power in circuit"]),
    SpeedQ("mcq","In your 18V/24V diagram, I1 =?","I2 + I3",["I2 - I3","I2 + I3","I2 * I3","I2 / I3"]),
    SpeedQ("mcq","What blows when 19V shorted?","Fuse",["T-Con","LVDS","Speaker"]),
    SpeedQ("mcq","Which tool to test short to ground?","Multimeter on ohms",["Oscilloscope","Soldering iron","Heat gun"]),
    SpeedQ("mcq","What does buck coil store?","Energy as magnetic field",["Data","Voltage","Heat","Light"]),
    SpeedQ("mcq","T-Con white screen common cause?","VGH missing",["Backlight short","19V missing","WiFi card"]),
    SpeedQ("mcq","Battery charging IC senses?","Adapter and battery current",["Only temperature","Only voltage","Screen brightness"]),
    SpeedQ("mcq","Series resistors have same?","Current",["Voltage","Power","Charge"]),
    SpeedQ("mcq","Parallel resistors have same?","Voltage",["Current","Resistance","Inductance"]),
  ];

  final feedbackCorrect = ["Correct!","Good!","Impressive!","Excellent!","Awesome!","Fantastic!","Great!","Amazing!"];
  final botNames = ["VoltVandal","SolderSista"];
  int onlineUsers=10, topicIndex=0, topicTimeLeft=200, qIndex=0, timer=30, myScore=0, topicChangeCount=0, conceptCountSinceSpeed=0;
  String phase='concept';
  bool showDiagramNow = false;
  List<FeedItem> feed=[];
  TextEditingController inputCtrl=TextEditingController();
  FocusNode inputFocus = FocusNode();
  List<UserScore> leaderboard=[UserScore("You",0),UserScore("VoltVandal",120),UserScore("SolderSista",90),UserScore("CapKing",200),UserScore("DiodeSlayer",180)];
  Timer? topicTimer, questionTimer;

  // Speed shuffling vars
  List<String> currentShuffledOptions=[];
  String currentCorrectLetter="";
  String currentCorrectText="";
  int currentSpeedIndex=0;
  List<int> speedOrder=[];

  @override void initState(){
    super.initState();
    _generateNewSpeedOrder();
    _prepareSpeedQuestion();
    _startTopicTimer(); _startQuestionTimer();
  }

  void _generateNewSpeedOrder(){
    speedOrder = List.generate(speedQuestions.length, (i)=>i);
    speedOrder.shuffle(Random());
    currentSpeedIndex=0;
  }

  void _prepareSpeedQuestion(){
    if(phase!='speed') return;
    var sq = speedQuestions[speedOrder[currentSpeedIndex % speedOrder.length]];
    currentCorrectText = sq.correctText;
    // shuffle options for MCQ / truefalse etc
    currentShuffledOptions = List.from(sq.options);
    currentShuffledOptions.shuffle(Random());
    int correctPos = currentShuffledOptions.indexWhere((o)=>o.toLowerCase()==sq.correctText.toLowerCase());
    if(correctPos==-1) correctPos=0; // fallback if not found
    currentCorrectLetter = ['a','b','c','d','e'][correctPos % 5];
  }

  int _getRandomTime()=>Random().nextInt(60)+180;
  int _getRandomTopic(int c){int n;do{n=Random().nextInt(topics.length);}while(n==c);return n;}
  bool get botsEnabled=>(onlineUsers>=9&&onlineUsers<=11)?true:(onlineUsers>=15&&onlineUsers<=17)?false:onlineUsers<15;
  Question get currentConceptQ => showDiagramNow? diagramQuestions[qIndex%diagramQuestions.length] : textOnlyQuestions[qIndex%textOnlyQuestions.length];
  SpeedQ get currentSpeedQ=>speedQuestions[speedOrder[currentSpeedIndex%speedOrder.length]];
  bool _realAICheck(String a, Question q){String ans=a.toLowerCase();if(ans.length<8)return false;int m=q.mustContain.where((k)=>ans.contains(k)).length;return m>=1;}

  void _startTopicTimer(){
    topicTimer?.cancel();
    topicTimer=Timer.periodic(const Duration(seconds:1),(t){
      setState((){
        if(topicTimeLeft<=1){
          topicIndex=_getRandomTopic(topicIndex); topicChangeCount++; qIndex=Random().nextInt(textOnlyQuestions.length); phase='concept'; feed=[]; timer=30; topicTimeLeft=_getRandomTime();
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
      if (phase=='concept') {
        conceptCountSinceSpeed++;
        if (conceptCountSinceSpeed >= 4) {
          phase='speed';
          if(speedOrder.isEmpty) _generateNewSpeedOrder();
          currentSpeedIndex=0;
          _prepareSpeedQuestion();
          timer=7;
          conceptCountSinceSpeed=0;
          return;
        }
        qIndex = Random().nextInt(textOnlyQuestions.length);
        timer=30;
      } else {
        currentSpeedIndex++;
        if (currentSpeedIndex >= 12) { // LONGER SESSION = 12 QUESTIONS
          if(currentSpeedIndex >= speedQuestions.length) _generateNewSpeedOrder();
          phase='concept'; qIndex=Random().nextInt(textOnlyQuestions.length); timer=30;
        } else {
          _prepareSpeedQuestion();
          timer=7;
        }
      }
    });
    _triggerBot();
  }

  void _triggerBot(){
    if(!botsEnabled||phase!='concept') return;
    Future.delayed(Duration(milliseconds:1200+Random().nextInt(2000)),(){
      if(!mounted) return;
      bool ok=Random().nextDouble()<0.666;
      String name=botNames[Random().nextInt(botNames.length)];
      bool isFirst =!feed.any((f)=>f.correct);
      setState(() {
        if (ok) {
          feed.add(FeedItem(name,"${currentConceptQ.mustContain.first} rule explanation example",true,isFirst, feedback: isFirst? "FIRST GREEN! → Next Q in 2s" : feedbackCorrect[Random().nextInt(feedbackCorrect.length)]));
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
    else {
      String ans = inputCtrl.text.toLowerCase().trim();
      // Accept letter OR text
      ok = ans==currentCorrectLetter || ans.contains(currentCorrectText.toLowerCase()) || (currentCorrectLetter=="a"&&ans=="a") || (currentCorrectLetter=="b"&&ans=="b") || (currentCorrectLetter=="c"&&ans=="c") || (currentCorrectLetter=="d"&&ans=="d");
    }

    bool isFirst = ok &&!feed.any((f)=>f.correct);
    setState(() {
      feed.add(FeedItem("You",inputCtrl.text,ok,isFirst,feedback: ok? (isFirst? "YOU FIRST GREEN! → Next Q in 2s" : feedbackCorrect[Random().nextInt(feedbackCorrect.length)]) : "wrong!"));
      if (ok) { myScore+=isFirst?20:10; leaderboard.firstWhere((u)=>u.name=="You").score+=isFirst?20:10; }
    });
    inputCtrl.clear();
    inputFocus.requestFocus();

    if (ok && isFirst) {
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

  String _buildSpeedOptionsText(){
    if(currentShuffledOptions.isEmpty) return "";
    List<String> letters = ['a','b','c','d','e'];
    List<String> parts=[];
    for(int i=0;i<currentShuffledOptions.length;i++){
      parts.add("${letters[i]}) ${currentShuffledOptions[i]}");
    }
    return parts.join(" | ");
  }

  @override Widget build(BuildContext context){
    var sorted=[...leaderboard]..sort((a,b)=>b.score.compareTo(a.score));
    String qText=phase=='concept'?currentConceptQ.text:currentSpeedQ.q;
    double prog=phase=='speed'?timer/7:timer/30;
    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(8), child: Column(children:[
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A1B9A),Color(0xFF283593)]), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Ziso Trivia",style:TextStyle(fontWeight:FontWeight.w900,fontSize:20)), Text("NQF 5 • ${topics[topicIndex]}",style: const TextStyle(fontSize:10))])),
      const SizedBox(height:6),
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Column(children:[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("Shuffle: ${topicTimeLeft~/60}:${(topicTimeLeft%60).toString().padLeft(2,'0')} left",style: const TextStyle(fontSize:11)), Text("Changes: $topicChangeCount/5 → Diagram | ${conceptCountSinceSpeed}/4 → Speed (12 Qs)",style: const TextStyle(fontSize:8, color: Colors.amber))]),
        const SizedBox(height:4),
        Row(children:[Expanded(child: LinearProgressIndicator(value: (topicChangeCount%5)/5, backgroundColor: Colors.grey[800], color: Colors.amber)), const SizedBox(width:8), Expanded(child: LinearProgressIndicator(value: conceptCountSinceSpeed/4, backgroundColor: Colors.grey[800], color: Colors.greenAccent))]),
        Text(phase=='speed'? "⚡ SPEED ROUND ${currentSpeedIndex+1}/12 - 7s ONLY! ${currentSpeedQ.type.toUpperCase()}" : showDiagramNow? "★ DIAGRAM QUESTION" : "Concept phase - ${4-conceptCountSinceSpeed} Qs left then 12x SPEED", style: TextStyle(fontSize:10, color: phase=='speed'? Colors.yellowAccent : Colors.white54))
      ])),
      const SizedBox(height:6),
      AnimatedContainer(duration: const Duration(milliseconds:400), height: showDiagramNow? 150 : 55, width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: showDiagramNow? Colors.white : Colors.grey[300], borderRadius: BorderRadius.circular(8), border: Border.all(color: showDiagramNow? Colors.amber : Colors.grey, width: showDiagramNow?3:1)), child: Column(children:[Text(showDiagramNow? "DIAGRAM FIXED - SAME FOR ALL" : "NO DIAGRAM",style: const TextStyle(color:Colors.black,fontWeight:FontWeight.bold,fontSize:10)), const SizedBox(height:2), Expanded(child: _buildDiagram())])),
      const SizedBox(height:8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("${phase.toUpperCase()} - Q${phase=='speed'?currentSpeedIndex+1:qIndex+1} ${phase=='speed'?'7s ONLY!':'${timer}s'} ${feed.any((f)=>f.correct)?'• FIRST FOUND - 2s':''}",style: const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold,fontSize:12)), Text(phase=='speed'? currentSpeedQ.type.toUpperCase() : showDiagramNow? "With Diagram" : "Text Only", style: TextStyle(fontSize:9, color: phase=='speed'? Colors.yellowAccent : Colors.white54))]), const SizedBox(height:6), LinearProgressIndicator(value: prog.clamp(0,1), backgroundColor: Colors.grey[700], color: phase=='speed'? Colors.yellowAccent : Colors.greenAccent), const SizedBox(height:10), Text(qText,style: const TextStyle(fontSize:14)), if(phase=='speed') Padding(padding: const EdgeInsets.only(top:6), child: Text(_buildSpeedOptionsText(), style: const TextStyle(fontSize:11, color: Colors.white70)))])),
      const SizedBox(height:8),
      Container(height: 130, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade800)), child: feed.isEmpty? Text(phase=='speed'? "Speed ${currentSpeedIndex+1}/12! Type ${currentCorrectLetter} or text - 7s only!" : "No lock! First = 20 XP, others = 10 XP before next Q",style: const TextStyle(color:Colors.white38,fontSize:12)) : ListView.builder(itemCount: feed.length, itemBuilder: (c,i){var f=feed[i];return Container(margin: const EdgeInsets.only(bottom:3), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: f.firstGreen?Colors.green[700]:f.correct?const Color(0xFF424242):Colors.transparent, borderRadius: BorderRadius.circular(4)), child: Text("${f.user}: ${f.text} ${f.feedback!=null?'→ ${f.feedback}':''}",style:TextStyle(fontSize:12,color: f.firstGreen?Colors.white: f.correct?Colors.white:Colors.redAccent, fontWeight: f.firstGreen? FontWeight.bold : FontWeight.normal)));})),
      const SizedBox(height:8),
      TextField(controller: inputCtrl, focusNode: inputFocus, autofocus: true, enableSuggestions: true, textInputAction: TextInputAction.send, onSubmitted: (v)=>submitAnswer(), style: const TextStyle(color:Colors.white), decoration: InputDecoration(hintText: phase=='speed'? "FAST! Type ${currentCorrectLetter} or full answer... 7s!" : "Type concept (phone keyboard)...", filled: true, fillColor: const Color(0xFF424242), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.greenAccent), onPressed: submitAnswer))),
      const SizedBox(height:8),
      Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Text("Leaderboard Top 3",style:TextStyle(fontWeight:FontWeight.bold,fontSize:12)),...sorted.take(3).map((u)=>Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("#${sorted.indexOf(u)+1} ${u.name}"), Text("${u.score} XP")])), Text("You: #${sorted.indexWhere((u)=>u.name=='You')+1} - $myScore XP | Bank: ${speedQuestions.length} speed, ${textOnlyQuestions.length} concept",style: const TextStyle(color:Colors.amber,fontWeight:FontWeight.bold, fontSize:10))]))
    ]))));
  }
}
class CircuitPainter1 extends CustomPainter { @override void paint(Canvas canvas, Size size) { var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:10,fontWeight:FontWeight.bold)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);}; canvas.drawRect(const Rect.fromLTWH(20,30,10,40), paint); tp("18V", const Offset(15,75)); canvas.drawRect(const Rect.fromLTWH(260,60,10,40), paint); tp("24V", const Offset(255,105)); canvas.drawLine(const Offset(30,30), const Offset(100,30), paint); tp("R1=2Ω", const Offset(60,15)); canvas.drawLine(const Offset(100,30), const Offset(100,60), paint); canvas.drawLine(const Offset(100,60), const Offset(30,60), paint); canvas.drawLine(const Offset(30,60), const Offset(30,70), paint); canvas.drawLine(const Offset(100,60), const Offset(180,60), paint); tp("R2=5Ω", const Offset(130,45)); canvas.drawLine(const Offset(180,60), const Offset(180,30), paint); canvas.drawLine(const Offset(180,30), const Offset(260,30), paint); canvas.drawLine(const Offset(260,30), const Offset(260,60), paint); canvas.drawCircle(const Offset(180,60), 4, Paint()..color=Colors.red); canvas.drawLine(const Offset(180,60), const Offset(220,60), paint); tp("R3=8Ω", const Offset(200,62)); canvas.drawLine(const Offset(220,60), const Offset(220,90), paint); canvas.drawLine(const Offset(220,90), const Offset(30,90), paint); canvas.drawLine(const Offset(180,65), const Offset(180,90), paint); tp("R4=6Ω", const Offset(155,85)); canvas.drawLine(const Offset(180,90), const Offset(30,90), paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
class MosfetPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:9)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);}; canvas.drawRect(const Rect.fromLTWH(40,20,60,50), paint); tp("Dual MOSFET", const Offset(45,5)); canvas.drawRect(const Rect.fromLTWH(140,30,30,30), paint); tp("L=Coil", const Offset(140,10)); canvas.drawRect(const Rect.fromLTWH(210,20,60,50), paint); tp("CPU CORE", const Offset(220,5)); canvas.drawLine(const Offset(100,45), const Offset(140,45), paint); canvas.drawLine(const Offset(170,45), const Offset(210,45), paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
class SmpsPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { var paint=Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; var tp=(String t, Offset o){var tPainter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Colors.black,fontSize:8)),textDirection:TextDirection.ltr);tPainter.layout();tPainter.paint(canvas,o);}; canvas.drawRect(const Rect.fromLTWH(10,30,50,30), paint); tp("Bridge", const Offset(15,15)); canvas.drawRect(const Rect.fromLTWH(80,20,40,50), paint); tp("Transformer", const Offset(80,5)); canvas.drawRect(const Rect.fromLTWH(140,30,50,30), paint); tp("LED Driver", const Offset(140,15)); canvas.drawRect(const Rect.fromLTWH(210,30,50,30), paint); tp("Fuse", const Offset(220,15)); canvas.drawLine(const Offset(60,45), const Offset(80,45), paint); canvas.drawLine(const Offset(120,45), const Offset(140,45), paint); canvas.drawLine(const Offset(190,45), const Offset(210,45), paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
