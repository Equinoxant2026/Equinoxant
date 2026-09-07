import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text("EQUINOXANT\nWORKS!", 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    ),
  ));
}
