import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:app_settings/app_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const EquinoxantApp());
}

class EquinoxantApp extends StatelessWidget {
  const EquinoxantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equinoxant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSensorConnected = false;
  Color bgColor = Colors.white;
  bool isScanning = false;
  bool isTorchOn = false; // FIX 1: added ;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _scanAndConnect() async {
    if (!mounted) return;
    setState(() => isScanning = true);
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      await for (var results in FlutterBluePlus.scanResults) {
        for (ScanResult r in results) {
          if (r.device.name.toUpperCase().contains("EQUINOXANT") &&
              r.device.name.toUpperCase().contains("CHALK")) {
            await FlutterBluePlus.stopScan();
            await r.device.connect();
            setState(() {
              connectedDevice = r.device;
              isSensorConnected = true;
              isScanning = false;
            });
            return;
          }
        }
      }
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Scan error: $e");
    }
    if (!mounted) return;
    setState(() => isScanning = false);
    if (!isSensorConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sensor not found. Check ESP32 is ON")),
      );
    }
  }

  Future<void> _toggleTorch() async {
    try {
      if (isTorchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      if (!mounted) return;
      setState(() => isTorchOn =!isTorchOn);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Torch not available: $e")),
      );
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'bt') {
                if (isSensorConnected) {
                  await connectedDevice?.disconnect();
                  setState(() {
                    isSensorConnected = false;
                    connectedDevice = null;
                  });
                } else {
                  AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                  await Future.delayed(Duration(seconds: 2));
                  await _scanAndConnect();
                }
              }
              if (value == 'color') {
                setState(() => bgColor = bgColor == Colors.white? Colors.grey[200]! : Colors.white);
              }
              // FIX 2 & 3: fixed broken brackets here
              if (value == 'torch') {
                await _toggleTorch();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'bt', child: Text(isSensorConnected? 'Disconnect Sensor' : 'Bluetooth Settings')),
              PopupMenuItem(value: 'color', child: Text('Background Colour Picker')),
              PopupMenuItem(value: 'torch', child: Text(isTorchOn? 'Turn OFF Torch' : 'Turn ON Torch')),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSensorConnected)
              Text("Connect your sensor", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            if (isSensorConnected)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.bluetooth_connected, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text("Sensor Connected", style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              onPressed: isScanning? null : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TimerPage(isSensorConnected: isSensorConnected, bgColor: bgColor, device: connectedDevice)),
              ),
              child: Text(isScanning? "Scanning..." : "Ready!!!", style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class TimerPage extends StatefulWidget {
  final bool isSensorConnected;
  final Color bgColor;
  final BluetoothDevice? device;
  const TimerPage({required this.isSensorConnected, required this.bgColor, this.device});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int currentLoop = 1;
  int totalLoops = 9;
  int loop1Duration = 60000;
  int loopOtherDuration = 8000;
  int remainingMs = 60000;
  bool isPaused = false;
  bool isWritingDetected = false;
  Timer? _timer;
  Timer? _resumeDelayTimer;
  DateTime? _lastTick;
  bool _waitingToResume = false;

  StreamSubscription<List<int>>? _sensorSub;
  BluetoothCharacteristic? _chalkChar;
  DateTime _lastMove = DateTime.now();

  @override
  void initState() {
    super.initState();
    remainingMs = loop1Duration;
    _startTimer();
    if (widget.device!= null) _setupSensorListener();
  }

  Future<void> _setupSensorListener() async {
    try {
      List<BluetoothService> services = await widget.device!.discoverServices();
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.uuid.toString().toLowerCase() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            _chalkChar = c;
            await c.setNotifyValue(true);
            _sensorSub = c.onValueReceived.listen((value) {
              if (value.isEmpty) return;
              String data = utf8.decode(value);
              if (data.contains("WRITING")) {
                _lastMove = DateTime.now();
                if (!isWritingDetected) _onWritingStart();
              } else {
                if (DateTime.now().difference(_lastMove).inMilliseconds > 500) {
                  if (isWritingDetected) _onWritingStop();
                }
              }
            });
          }
        }
      }
    } catch (e) {
      print("Sensor error: $e");
    }
  }

  bool get _isAfterLoop1 => currentLoop >= 2;
  bool get _shouldRunTimer {
    if (_waitingToResume) return false;
    if (_isAfterLoop1) {
      return!isWritingDetected;
    } else {
      return!isWritingDetected &&!isPaused;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(Duration(milliseconds: 50), (t) {
      if (_shouldRunTimer) {
        final now = DateTime.now();
        final elapsed = now.difference(_lastTick!).inMilliseconds;
        _lastTick = now;
        setState(() {
          remainingMs -= elapsed;
          if (remainingMs <= 0) _nextLoop();
        });
      } else {
        _lastTick = DateTime.now();
      }
    });
  }

  Future<void> _blinkTorch() async {
    try {
      bool isTorchAvailable = await TorchLight.isTorchAvailable();
      if (!isTorchAvailable) return;
      await TorchLight.enableTorch();
      await Future.delayed(Duration(milliseconds: 150));
      await TorchLight.disableTorch();
      await Future.delayed(Duration(milliseconds: 100));
      await TorchLight.enableTorch();
      await Future.delayed(Duration(milliseconds: 150));
      await TorchLight.disableTorch();
    } catch (e) {}
  }

  void _nextLoop() {
    _blinkTorch();
    if (currentLoop < totalLoops) {
      setState(() {
        currentLoop++;
        remainingMs = loopOtherDuration;
        _lastTick = DateTime.now();
      });
    } else {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  void _resetCurrentLoop() {
    setState(() {
      remainingMs = currentLoop == 1? loop1Duration : loopOtherDuration;
      _lastTick = DateTime.now();
    });
  }

  void _triggerResumeDelay() {
    if (_waitingToResume) return;
    setState(() => _waitingToResume = true);
    _resumeDelayTimer?.cancel();
    _resumeDelayTimer = Timer(Duration(seconds: 1), () {
      if (mounted) setState(() => _waitingToResume = false);
    });
  }

  void _onWritingStart() {
    _resumeDelayTimer?.cancel();
    setState(() {
      _waitingToResume = false;
      isWritingDetected = true;
      if (_isAfterLoop1 && isPaused) {
      } else {
        _resetCurrentLoop();
      }
    });
  }

  void _onWritingStop() {
    setState(() {
      isWritingDetected = false;
      if (currentLoop == 1) {
        _nextLoop();
      } else {
        if (isPaused) {
          _triggerResumeDelay();
        }
      }
    });
  }

  Color _getArcColor(double progress) {
    if (currentLoop == 1) return Colors.green;
    if (progress > 0.67) return Colors.green;
    if (progress > 0.34) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeDelayTimer?.cancel();
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int loopDuration = currentLoop == 1? loop1Duration : loopOtherDuration;
    double progress = (remainingMs / loopDuration).clamp(0.0, 1.0);
    int seconds = (remainingMs / 1000).floor();
    int ms = ((remainingMs % 1000) / 10).floor();
    bool actuallyPaused = isPaused || isWritingDetected || _waitingToResume;

    return Scaffold(
      backgroundColor: widget.bgColor,
      body: Stack(
        children: [
          Positioned(top: 10, left: 10, child: TextButton.icon(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: Colors.black), label: Text("BACK", style: TextStyle(color: Colors.black)))),
          if (!widget.isSensorConnected) Positioned(top: 10, right: 10, child: Icon(Icons.bluetooth_disabled, color: Colors.red, size: 30)),
          if (widget.isSensorConnected) Positioned(top: 10, right: 10, child: Icon(Icons.bluetooth_connected, color: Colors.green, size: 30)),
          if (isWritingDetected) Positioned(top: 10, right: 50, child: Icon(Icons.edit, color: Colors.green, size: 30)),
          if (isWritingDetected) Positioned(top: 10, left: 0, right: 0, child: Center(child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit, color: Colors.white, size: 18), SizedBox(width: 4), Text("WRITING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))),
          if (_waitingToResume) Positioned(top: 50, left: 0, right: 0, child: Center(child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)), child: Text("RESUMING IN 1s...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
          Positioned(left: 30, top: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$seconds s", style: TextStyle(fontSize: 70, color: Colors.red, fontWeight: FontWeight.bold)), Text("${ms.toString().padLeft(2, '0')} ms", style: TextStyle(fontSize: 22, color: Colors.red))])),
          Center(child: CustomPaint(size: Size(MediaQuery.of(context).size.width * 0.70, MediaQuery.of(context).size.width * 0.70), painter: ArcPainter(progress: progress, arcColor: _getArcColor(progress)))),
          Positioned(
            bottom: 60,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isPaused =!isPaused;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: actuallyPaused? Colors.grey : Colors.blue,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Icon(isPaused? Icons.play_arrow : Icons.pause, color: Colors.white)
              )
            )
          ),
          Positioned(bottom: 20, left: 0, right: 0, child: Center(child: Text("Loop $currentLoop / $totalLoops", style: TextStyle(fontSize: 18)))),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: isWritingDetected? Colors.green : Colors.grey, onPressed: null, child: Icon(Icons.edit)),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double progress;
  final Color arcColor;
  ArcPainter({required this.progress, required this.arcColor});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint basePaint = Paint()..color = Colors.grey[800]!..strokeWidth = 30..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, basePaint);
    Paint progressPaint = Paint()..color = arcColor..strokeWidth = 30..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi * progress, false, progressPaint);
    double handAngle = pi - (pi * progress);
    Offset handEnd = Offset(center.dx + radius * cos(handAngle), center.dy - radius * sin(handAngle));
    Paint handPaint = Paint()..color = Colors.grey..strokeWidth = 20;
    canvas.drawLine(center, handEnd, handPaint);
  }
  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) => oldDelegate.progress!= progress || oldDelegate.arcColor!= arcColor;
}
