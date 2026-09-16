// FINAL Ziso Trivia main.dart - All features merged
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BookTeacherApp());

class BookTeacherApp extends StatelessWidget {
  const BookTeacherApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const TeacherScreen()
  );
}

class QuestionItem {
  final String type;
  final String q;
  final String answerText;
  final List<String> options;
  final List<String> scrambleVariants;
  final int timeLimit;
  final String source;
  QuestionItem(this.type,this.q,this.answerText,this.options,this.scrambleVariants,this.timeLimit, this.source);
}

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState()=>_TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  List<Map<String,dynamic>> rawData=[];
  int sentenceIndex=0, poolIndex=0;
  String mode='mode1';
  QuestionItem? currentQ;
  List<String> currentShuffledOptions=[];
  String currentCorrectLetter="";
  String currentScrambleDisplay="";
  List<String> feed=[];
  TextEditingController inputCtrl=TextEditingController();
  int timer=0; Timer? t;
  bool waitingForFirst=true;
  int myXP=0;

  @override
  void initState(){super.initState(); _load();}

  Future<void> _load() async {
    String s = await rootBundle.loadString('assets/questions.json');
    rawData = List<Map<String,dynamic>>.from(json.decode(s));
    rawData.shuffle(Random());
    _nextQuestion();
  }

  void _nextQuestion(){
    if(rawData.isEmpty) return;
    var sentenceObj = rawData[sentenceIndex % rawData.length];
    var pool = List<Map<String,dynamic>>.from(sentenceObj['pool']);
    pool.shuffle(Random());
    var qMap = pool[poolIndex % pool.length];

    currentQ = QuestionItem(
      qMap['type'], qMap['q'], qMap['answer_text'],
      List<String>.from(qMap['options']?? []),
      List<String>.from(qMap['scramble_variants']?? []),
      qMap['time_limit']?? 15,
      sentenceObj['source']?? ''
    );

    if(currentQ!.type=='mcq'){
      currentShuffledOptions = List.from(currentQ!.options);
      currentShuffledOptions.shuffle(Random());
      int pos = currentShuffledOptions.indexWhere((e)=>e.toLowerCase()==currentQ!.answerText.toLowerCase());
      if(pos==-1) pos=0;
      currentCorrectLetter = ['a','b','c','d','e'][pos];
    } else if(currentQ!.type=='scramble'){
      if(currentQ!.scrambleVariants.isNotEmpty){
        currentScrambleDisplay = currentQ!.scrambleVariants[Random().nextInt(currentQ!.scrambleVariants.length)];
      } else {
        var w = currentQ!.answerText;
        currentScrambleDisplay = (w.split('')..shuffle()).join();
      }
    } else if(currentQ!.type=='truefalse'){
      currentShuffledOptions = ["True","False"];
      currentShuffledOptions.shuffle(Random());
      int pos = currentShuffledOptions.indexWhere((e)=>e.toLowerCase()==currentQ!.answerText.toLowerCase());
      if(pos==-1) pos=0;
      currentCorrectLetter = ['a','b'][pos];
    } else {
      currentShuffledOptions = currentQ!.options;
      currentShuffledOptions.shuffle(Random());
    }

    waitingForFirst=true;
    feed.clear();

    if(mode=='mode2'){
      timer=currentQ!.timeLimit;
      t?.cancel();
      t=Timer.periodic(const Duration(seconds:1),(tt){
        setState((){
          if(timer<=1){
            feed.add("TIME UP! Feedback: Correct was '${currentQ!.answerText}'. Source: ${currentQ!.source}");
            _nextQuestion();
          } else timer--;
        });
      });
    }
    setState((){});
  }

  void submit(){
    if(currentQ==null || inputCtrl.text.isEmpty) return;
    String ans = inputCtrl.text.toLowerCase().trim();
    bool ok=false;

    if(currentQ!.type=='mcq' || currentQ!.type=='truefalse'){
      ok = ans==currentCorrectLetter || ans.contains(currentQ!.answerText.toLowerCase());
    } else {
      ok = ans==currentQ!.answerText.toLowerCase() || ans.contains(currentQ!.answerText.toLowerCase());
    }

    bool isFirst = ok && waitingForFirst;

    setState((){
      if(isFirst){
        waitingForFirst=false;
        t?.cancel();
        feed.add("YOU FIRST CORRECT! +20 XP");
        myXP+=20;
        feed.add(">> SYSTEM: Feedback sent ONLY to wrong/silent users: 'Correct was ${currentQ!.answerText}. Source: ${currentQ!.source}'");
        feed.add(">> YOU get no feedback, you get NEXT QUESTION in 3s");
        Future.delayed(const Duration(seconds:3),(){
          sentenceIndex++; poolIndex=0;
          rawData.shuffle(Random());
          _nextQuestion();
        });
      } else if(ok &&!waitingForFirst){
        feed.add("You correct +10 XP (but not first)");
        myXP+=10;
      } else if(!ok && waitingForFirst){
        feed.add("Wrong: ${inputCtrl.text} - waiting for first correct");
      } else if(!ok &&!waitingForFirst){
        feed.add("Wrong: ${inputCtrl.text}");
      }
    });
    inputCtrl.clear();
  }

  @override
  Widget build(BuildContext c){
    if(currentQ==null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    String displayQ = currentQ!.type=='scramble'? "Unscramble: $currentScrambleDisplay (Hint: ${currentQ!.q})" : currentQ!.q;
    String optionsText="";
    if(currentQ!.type=='mcq'){
      optionsText = List.generate(currentShuffledOptions.length, (i)=>"${['a','b','c','d','e'][i]}) ${currentShuffledOptions[i]}").join(" | ");
    } else if(currentQ!.type=='truefalse'){
      optionsText = List.generate(currentShuffledOptions.length, (i)=>"${['a','b'][i]}) ${currentShuffledOptions[i]}").join(" | ") + " (No 'not' trick)";
    }

    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Column(children:[
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/IMG-20260910-WA7526.jpg', height: 90, width: double.infinity, fit: BoxFit.cover),
      ),
      const SizedBox(height:10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
        const Text("Book Teacher",style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
        DropdownButton(value: mode, items: const [DropdownMenuItem(value:'mode1',child:Text("MODE 1 No Timer")),DropdownMenuItem(value:'mode2',child:Text("MODE 2 Timed"))], onChanged:(v){setState(()=>mode=v!); _nextQuestion();})
      ]),
      const SizedBox(height:10),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text("${mode.toUpperCase()} ${mode=='mode2'?"- $timer s (AI fair: ${currentQ!.timeLimit}s)":"- No limit, first correct triggers"}",style: const TextStyle(color: Colors.amber)),
        const SizedBox(height:8),
        if(mode=='mode2') LinearProgressIndicator(value: timer/currentQ!.timeLimit),
        const SizedBox(height:8),
        Text(displayQ,style: const TextStyle(fontSize:16)),
        if(optionsText.isNotEmpty) Padding(padding: const EdgeInsets.only(top:6), child: Text(optionsText,style: const TextStyle(color: Colors.white70))),
      ])),
      const SizedBox(height:10),
      Container(height:110, width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.grey[900], child: ListView(children: feed.map((e)=>Text(e, style: TextStyle(color: e.contains("SYSTEM")?Colors.amber:Colors.white))).toList())),
      TextField(controller: inputCtrl, onSubmitted: (_)=>submit(), decoration: InputDecoration(hintText: mode=='mode2'?"Type ${currentCorrectLetter} or full answer":"Type answer - first correct wins", suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: submit))),
      Text("XP: $myXP | Sentence ${sentenceIndex+1}/${rawData.length} | Anti-cramming ON", style: const TextStyle(fontSize: 11))
    ]))));
  }
}
