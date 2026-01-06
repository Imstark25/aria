import 'dart:async';
import 'dart:ui';
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
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.2), // Slight overlay for legibility
            ),
          ),

          // 2. Main Content with Glass Effect
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _buildGlassCard(
                    child: Column(
                      children: [
                         Icon(Icons.layers_outlined, size: 40, color: Colors.white.withOpacity(0.9)),
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
                             color: Colors.white.withOpacity(0.7),
                           ),
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Call Volume
                  _buildGlassVolumeCard(
                    title: "Call Volume",
                    icon: Icons.phone_in_talk,
                    amount: _currentVolume,
                    color: Colors.cyanAccent,
                    onChanged: (val) async {
                       setState(() => _currentVolume = val);
                       await FlutterVolumeController.setVolume(val, stream: AudioStream.voiceCall);
                    }
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Media Volume
                  _buildGlassVolumeCard(
                    title: "Media Volume",
                    icon: Icons.music_note_rounded,
                    amount: _mediaVolume,
                    color: Colors.pinkAccent,
                    onChanged: (val) async {
                      setState(() => _mediaVolume = val);
                      await FlutterVolumeController.setVolume(val, stream: AudioStream.music);
                    }
                  ),

                  const SizedBox(height: 50),
                  _buildFloatingActionButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassVolumeCard({
    required String title,
    required IconData icon,
    required double amount,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
                  shadows: [
                    Shadow(color: color.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: running
                      ? [const Color(0xFFFF512F).withOpacity(0.9), const Color(0xFFDD2476).withOpacity(0.9)] // Reddish
                      : [const Color(0xFF4776E6).withOpacity(0.9), const Color(0xFF8E54E9).withOpacity(0.9)], // Bluish
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: (running ? const Color(0xFFDD2476) : const Color(0xFF8E54E9)).withOpacity(0.4),
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
        ),
      ),
    );
  }
}
