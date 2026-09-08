import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// If you want Gemini online AI, run: flutter pub add http
// import 'package:http/http.dart' as http;
// import 'dart:convert';

void main() => runApp(const ZisoTriviaApp());

class ZisoTriviaApp extends StatelessWidget {
  const ZisoTriviaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ziso Trivia',
      theme: ThemeData.dark(),
      home: const ZisoTriviaScreen(),
    );
  }
}

class Topic {
  final String name;
  final String diagram;
  final List<String> keywords; // for AI check
  Topic(this.name, this.diagram, this.keywords);
}
class Question {
  final String type; final String text; final List<String> mustContain;
  Question(this.type, this.text, this.mustContain);
}
class SpeedQ {
  final String type; final String q; final String a; final List<String>? options;
  SpeedQ(this.type, this.q, this.a, [this.options]);
}
class FeedItem {
  final String user; final String text; final bool correct; final bool firstGreen; final String? feedback;
  FeedItem(this.user, this.text, this.correct, this.firstGreen, {this.feedback});
}
class UserScore { String name; int score; UserScore(this.name, this.score); }

class ZisoTriviaScreen extends StatefulWidget {
  const ZisoTriviaScreen({super.key});
  @override State<ZisoTriviaScreen> createState() => _ZisoTriviaScreenState();
}

class _ZisoTriviaScreenState extends State<ZisoTriviaScreen> {
  final feedbackCorrect = ["Correct!", "Good!", "Impressive!", "Excellent!", "Awesome!", "Fantastic!", "Amazing!", "Great!", "Marvelous!"];
  final botNames = ["VoltVandal", "SolderSista"];

  // --- TOPICS WITH KEYWORDS FOR REAL AI CHECK (0% maths) ---
  final topics = [
    Topic("DC Circuits & Power Rails", "Circuit: 18V & 24V batteries, R1=2Ω R2=5Ω R3=8Ω R4=6Ω", ["complex", "multi-loop", "junction", "opposing"]),
    Topic("MOSFETs & VRM Section", "Laptop VRM: Dual MOSFET + Inductor + CPU Core Voltage", ["mosfet", "vrm", "switching", "gate"]),
    Topic("SMPS & TV Power Board", "Smart TV PSU: Bridge Rectifier + Transformer + LED Driver", ["smps", "rectifier", "transformer", "feedback"]),
    Topic("T-Con & LVDS Cable", "TV T-Con Board: LVDS Signals + Panel Voltages", ["t-con", "lvds", "timing", "panel"]),
    Topic("Battery Charging Circuit", "Laptop Charging: DC Jack + MOSFET + Charging IC", ["charging", "mosfet", "adapter", "battery"]),
  ];

  final conceptQuestions = [
    Question("short", "WHAT type of circuit structure is this? Series, parallel, or complex multi-loop?", ["complex", "multi", "loop", "network"]),
    Question("medium", "WHAT does it mean when 18V and 24V oppose each other? HOW do you know dominating battery?", ["oppose", "opposing", "dominating", "direction", "higher", "24"]),
    Question("long", "WHAT rule governs current at junction of R2,R3,R4? HOW does it describe I1,I2,I3 without calculating?", ["kirchhoff", "junction", "kcl", "split", "sum", "conservation"]),
    Question("medium", "WHAT is voltage drop in terms of energy conversion? HOW is energy shared?", ["energy", "conversion", "heat", "shared", "dissipated"]),
    Question("long", "WHAT is purpose of R4 branch? HOW does it create alternative loop?", ["alternative", "branch", "parallel", "path", "loop"]),
    Question("short", "WHAT principle determines biggest energy conversion in a resistor?", ["power", "resistance", "current", "p=i", "bigger", "higher"]),
    Question("medium", "WHAT happens if one branch has higher resistance conceptually?", ["less current", "higher opposition", "current split"]),
    Question("long", "HOW many distinct closed loops can you identify for energy conservation?", ["2 loops", "two loops", "3 loops", "three", "loop"]),
    Question("short", "WHAT does it mean R1 and R2 are in same path?", ["series", "same current", "single path"]),
    Question("medium", "WHAT is first conceptual step with two batteries?", ["polarity", "direction", "net emf", "dominating"]),
    Question("long", "WHAT happens to current direction with opposing batteries?", ["reverse", "opposite", "net", "24v dominates"]),
    Question("short", "WHAT does it mean R3 and R4 are NOT in series?", ["parallel", "different path", "separate branch"]),
  ];

  final speedQuestions = [
    SpeedQ("fill", "Fill missing: The sum of currents at a junction is ____", "zero"),
    SpeedQ("scramble", "Unscramble: SMFTEO", "MOSFET"),
    SpeedQ("truefalse", "True/False: R1 and R2 are in parallel", "false"),
    SpeedQ("mcq", "Which board drives LEDs in Smart TV?", "c", ["a) T-Con", "b) Main Board", "c) Inverter/LED Driver", "d) LVDS"]),
  ];

  int onlineUsers = 10;
  int topicIndex = 0;
  int topicTimeLeft = 0;
  int qIndex = 0;
  String phase = 'concept';
  int timer = 120;
  List<FeedItem> feed = [];
  TextEditingController inputCtrl = TextEditingController();
  int myScore = 0;
  List<UserScore> leaderboard = [
    UserScore("You", 0), UserScore("VoltVandal", 120), UserScore("SolderSista", 90), UserScore("CapKing", 200), UserScore("DiodeSlayer", 180),
  ];
  Timer? topicTimer; Timer? questionTimer;
  bool isCheckingAI = false;

  @override
  void initState() {
    super.initState();
    topicTimeLeft = _getRandomTime();
    _startTopicTimer(); _startQuestionTimer();
  }
  int _getRandomTime() => Random().nextInt(60) + 240;
  int _getRandomTopic(int current) { int n; do { n = Random().nextInt(topics.length); } while (n==current && topics.length>1); return n; }
  bool get botsEnabled => (onlineUsers>=9 && onlineUsers<=11)? true : (onlineUsers>=15 && onlineUsers<=17)? false : onlineUsers<15;
  Question get currentConceptQ => conceptQuestions[qIndex % conceptQuestions.length];
  SpeedQ get currentSpeedQ => speedQuestions[qIndex % speedQuestions.length];

  // --- REAL AI CHECK - 0% MATHS, CONCEPT ONLY ---
  bool _realAICheck(String userAnswer, Question q) {
    String ans = userAnswer.toLowerCase().trim();
    // Block maths attempts
    if (RegExp(r'\d+\.?\d*\s*[v,a,Ω]').hasMatch(ans) || ans.contains("v=ir") || ans.contains("ohm")) {
      return false; // Reject maths, we want concept only
    }
    // Check if answer contains at least 1 keyword from mustContain
    int matches = q.mustContain.where((k) => ans.contains(k.toLowerCase())).length;
    return matches >= 1 && ans.length > 8;
  }

  // Optional: Online Gemini AI (uncomment if you add http package + API key)
  // Future<bool> _geminiCheck(String question, String answer) async {
  // const apiKey = "YOUR_GEMINI_API_KEY";
  // var url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey");
  // var body = jsonEncode({"contents":[{"parts":[{"text":"You are NQF5 electronics tutor. 0% maths. Question: $question. Student answer: $answer. Is concept correct? Reply only YES or NO"}]}]});
  // var res = await http.post(url, headers: {"Content-Type":"application/json"}, body: body);
  // return res.body.toLowerCase().contains("yes");
  // }

  void _startTopicTimer() {
    topicTimer?.cancel();
    topicTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (topicTimeLeft<=1) {
          topicIndex=_getRandomTopic(topicIndex); qIndex=0; phase='concept'; feed=[]; timer=120; topicTimeLeft=_getRandomTime();
        } else topicTimeLeft--;
      });
    });
  }
  void _startQuestionTimer() {
    questionTimer?.cancel();
    questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (timer<=1) {
          if (phase=='concept' && qIndex>=9) { phase='speed'; qIndex=0; timer=7; _triggerBot(); return; }
          if (phase=='speed') { qIndex++; timer=7; }
          else { qIndex++; var next=conceptQuestions[qIndex % conceptQuestions.length]; timer= next.type=='short'?90: next.type=='medium'?120:180; }
          _triggerBot();
        } else { timer--; if (phase=='speed' && timer>7) timer=7; }
      });
    });
  }
  void _triggerBot() {
    if (!botsEnabled || phase!='concept') return;
    Future.delayed(Duration(milliseconds: 2000+Random().nextInt(2000)), () {
      if (!mounted) return;
      bool isCorrect = Random().nextDouble()<0.666;
      String botName = botNames[Random().nextInt(botNames.length)];
      String answer = isCorrect? "Conceptually, ${currentConceptQ.mustContain.first} and junction rule - currents split" : "Maybe it's series?";
      bool isFirst =!feed.any((f)=>f.firstGreen);
      setState(() {
        feed.add(FeedItem(botName, answer, isCorrect, isCorrect && isFirst));
        if (isCorrect) leaderboard.firstWhere((u)=>u.name==botName).score+=10;
      });
    });
  }

  Future<void> submitAnswer() async {
    if (inputCtrl.text.trim().isEmpty) return;
    setState(()=>isCheckingAI=true);

    // REAL AI CHECK HERE
    bool isCorrect = false;
    if (phase=='concept') {
      isCorrect = _realAICheck(inputCtrl.text, currentConceptQ);
      // For online AI, use: isCorrect = await _geminiCheck(currentConceptQ.text, inputCtrl.text);
    } else {
      isCorrect = inputCtrl.text.toLowerCase().trim() == currentSpeedQ.a.toLowerCase();
    }

    bool isFirstCorrect = isCorrect &&!feed.any((f)=>f.firstGreen);
    String fb = isCorrect? feedbackCorrect[Random().nextInt(feedbackCorrect.length)] : "wrong!";
    setState(() {
      feed.add(FeedItem("You", inputCtrl.text, isCorrect, isFirstCorrect, feedback: fb));
      if (isCorrect) {
        myScore+= isFirstCorrect?20:10;
        leaderboard.firstWhere((u)=>u.name=="You").score+= isFirstCorrect?20:10;
      }
      isCheckingAI=false;
    });
    inputCtrl.clear();
  }

  @override void dispose() { topicTimer?.cancel(); questionTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    var sorted=[...leaderboard]..sort((a,b)=>b.score.compareTo(a.score));
    String currentQText = phase=='concept'? currentConceptQ.text : currentSpeedQ.q;
    double progress = phase=='speed'? timer/7 : timer/180;
    var customKeys = "1234567890QWERTYUIOPASDFGHJKLZXCVBNM".split("");

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF283593)]), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Ziso Trivia", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)), child: Text("NQF 5 • ${topics[topicIndex].name}", style: const TextStyle(fontSize: 10)))])),
            const SizedBox(height:6),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Shuffle: ${topicTimeLeft~/60}:${(topicTimeLeft%60).toString().padLeft(2,'0')} left (4-5min)", style: const TextStyle(fontSize:11)), Text("Online: $onlineUsers ${botsEnabled?'• Bots ON':'• Bots OFF'}", style: const TextStyle(fontSize:11))])),
            const SizedBox(height:6),
            Container(height: 120, width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber, width: 3)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("DIAGRAM STAYS FIXED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), const SizedBox(height:6), Text(topics[topicIndex].diagram, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize:12))])),
            const SizedBox(height:8),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${phase.toUpperCase()} - Q${qIndex+1} ${phase=='speed'?'(7s ONLY!)':'($timer s)'}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize:12)), const Text("Same Q for all", style: TextStyle(fontSize:10))]), const SizedBox(height:6), LinearProgressIndicator(value: progress.clamp(0,1), backgroundColor: Colors.grey[700], color: Colors.greenAccent), const SizedBox(height:10), Text(currentQText, style: const TextStyle(fontSize:14)), if (phase=='speed' && currentSpeedQ.options!=null) Padding(padding: const EdgeInsets.only(top:6), child: Text(currentSpeedQ.options!.join(" | "), style: const TextStyle(fontSize:11, color: Colors.white70))) ])),
            const SizedBox(height:8),
            Container(height: 140, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade800)), child: feed.isEmpty? const Text("Live answers from all users appear here...", style: TextStyle(color: Colors.white38, fontSize:12)) : ListView.builder(itemCount: feed.length, itemBuilder: (c,i){ var f=feed[i]; return Container(margin: const EdgeInsets.only(bottom:4), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: f.firstGreen? Colors.green[700] : f.correct? const Color(0xFF424242) : Colors.transparent, borderRadius: BorderRadius.circular(4)), child: Text("${f.user}: ${f.text} ${f.feedback!=null?'→ ${f.feedback}':''} ${f.firstGreen?'[FIRST GREEN!]':''}", style: TextStyle(fontSize:12, color: f.firstGreen? Colors.white : f.correct? Colors.white : Colors.redAccent, fontWeight: f.firstGreen? FontWeight.bold : FontWeight.normal))); })),
            const SizedBox(height:8),
            TextField(controller: inputCtrl, enableSuggestions: false, autocorrect: false, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Type concept (no numbers, no V=IR)...", filled: true, fillColor: const Color(0xFF424242), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixIcon: isCheckingAI? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2))) : null)),
            const SizedBox(height:6),
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1.2), itemCount: customKeys.length+2, itemBuilder: (c,i){
              if (i<customKeys.length) return ElevatedButton(style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: const Color(0xFF424242)), onPressed: ()=>setState(()=>inputCtrl.text+=customKeys[i]), child: Text(customKeys[i], style: const TextStyle(fontSize:10)));
              else if (i==customKeys.length) return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]), onPressed: ()=>setState(()=>inputCtrl.text=inputCtrl.text.isNotEmpty?inputCtrl.text.substring(0,inputCtrl.text.length-1):""), child: const Text("DEL", style: TextStyle(fontSize:10)));
              else return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), onPressed: isCheckingAI? null : submitAnswer, child: const Text("SEND", style: TextStyle(fontSize:10, fontWeight: FontWeight.bold)));
            }),
            const SizedBox(height:8),
            Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Leaderboard Top 3", style: TextStyle(fontWeight: FontWeight.bold, fontSize:12)),...sorted.take(3).map((u)=>Padding(padding: const EdgeInsets.symmetric(vertical:2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("#${sorted.indexOf(u)+1} ${u.name}"), Text("${u.score} XP")]))), const SizedBox(height:6), Text("Your position: #${sorted.indexWhere((u)=>u.name=='You')+1} - $myScore XP", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), const SizedBox(height:8), Row(children: [ElevatedButton(onPressed: ()=>setState(()=>onlineUsers=10), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[900]), child: const Text("10 users (ON)", style: TextStyle(fontSize:10))), const SizedBox(width:8), ElevatedButton(onPressed: ()=>setState(()=>onlineUsers=16), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]), child: const Text("16 users (OFF)", style: TextStyle(fontSize:10)))])])),
          ]),
        ),
      ),
    );
  }
}
