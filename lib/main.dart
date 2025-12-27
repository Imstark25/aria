import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

/// =====================
/// MAIN APP
/// =====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        fontFamily: 'Roboto', 
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('volume_overlay');
  bool running = false;
  double _currentVolume = 0.5;
  double _mediaVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _initVolume();
  }

  Future<void> _initVolume() async {
    try {
      double? vol = await FlutterVolumeController.getVolume(stream: AudioStream.voiceCall);
      double? mediaVol = await FlutterVolumeController.getVolume(stream: AudioStream.music);
      if (vol != null || mediaVol != null) {
        setState(() {
          if (vol != null) _currentVolume = vol;
          if (mediaVol != null) _mediaVolume = mediaVol;
        });
      }
    } catch (e) {
      debugPrint("Error getting volume: $e");
    }
  }

  Future<void> startOverlay() async {
    // Check overlay permission using permission_handler
    var status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) {
        debugPrint("Overlay permission denied");
        return;
      }
    }

    try {
      await platform.invokeMethod('showOverlay');
      setState(() => running = true);
    } on PlatformException catch (e) {
      debugPrint("Failed to show overlay: '${e.message}'.");
    }
  }

  Future<void> stopOverlay() async {
    try {
      await platform.invokeMethod('hideOverlay');
      setState(() => running = false);
    } on PlatformException catch (e) {
      debugPrint("Failed to hide overlay: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Volume Master"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView( // Added to prevent overflow on small screens
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 100), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center, // Center contents
              children: [
                const SizedBox(height: 20),
                _buildInfoCard(),
                const SizedBox(height: 30),
                _buildVolumeCard(
                  title: "Call Volume",
                  icon: Icons.phone_in_talk,
                  amount: _currentVolume,
                  onChanged: (val) async {
                    setState(() => _currentVolume = val);
                    await FlutterVolumeController.setVolume(val, stream: AudioStream.voiceCall);
                  },
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 20),
                _buildVolumeCard(
                  title: "Media Volume",
                  icon: Icons.music_note_rounded,
                  amount: _mediaVolume,
                  onChanged: (val) async {
                    setState(() => _mediaVolume = val);
                    await FlutterVolumeController.setVolume(val, stream: AudioStream.music);
                  },
                  color: Colors.pinkAccent,
                ),
                const SizedBox(height: 50),
                _buildFloatingActionButton(),
                 const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 40, color: Colors.white.withOpacity(0.8)),
          const SizedBox(height: 10),
          const Text(
            "Native Overlay Control",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enable 'Display over other apps' to use the floating bubble.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard({
    required String title,
    required IconData icon,
    required double amount,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                "${(amount * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              trackHeight: 6.0,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayColor: color.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            ),
            child: Slider(
              value: amount,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Center(
      child: GestureDetector(
        onTap: running ? stopOverlay : startOverlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: running
                  ? [Colors.redAccent, Colors.red]
                  : [Colors.deepPurpleAccent, Colors.blueAccent],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (running ? Colors.red : Colors.blue).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                running ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                running ? "Stop Button" : "Start Floating Button",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
