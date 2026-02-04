import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

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
  double _ringVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _initVolume();
  }

  Future<void> _initVolume() async {
    try {
      double? vol = await FlutterVolumeController.getVolume(stream: AudioStream.voiceCall);
      double? mediaVol = await FlutterVolumeController.getVolume(stream: AudioStream.music);
      double? ringVol = await FlutterVolumeController.getVolume(stream: AudioStream.ring);
      
      setState(() {
        if (vol != null) _currentVolume = vol;
        if (mediaVol != null) _mediaVolume = mediaVol;
        if (ringVol != null) _ringVolume = ringVol;
      });
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Title Card
                        _buildGlassCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                size: isSmallScreen ? 50 : 60,
                                color: Colors.cyanAccent,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Volume Master",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Control your device volume with ease",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Call Volume
                        _buildGlassVolumeCard(
                          title: "Call Volume",
                          icon: Icons.phone_in_talk,
                          amount: _currentVolume,
                          color: Colors.cyanAccent,
                          isSmallScreen: isSmallScreen,
                          onChanged: (val) async {
                            setState(() => _currentVolume = val);
                            await FlutterVolumeController.setVolume(val, stream: AudioStream.voiceCall);
                          }
                        ),
                        
                        SizedBox(height: screenHeight * 0.025),
                        
                        // Media Volume
                        _buildGlassVolumeCard(
                          title: "Media Volume",
                          icon: Icons.music_note_rounded,
                          amount: _mediaVolume,
                          color: Colors.pinkAccent,
                          isSmallScreen: isSmallScreen,
                          onChanged: (val) async {
                            setState(() => _mediaVolume = val);
                            await FlutterVolumeController.setVolume(val, stream: AudioStream.music);
                          }
                        ),
                        
                        SizedBox(height: screenHeight * 0.025),
                        
                        // Ring Volume
                        _buildGlassVolumeCard(
                          title: "Ring Volume",
                          icon: Icons.notifications_active,
                          amount: _ringVolume,
                          color: Colors.orangeAccent,
                          isSmallScreen: isSmallScreen,
                          onChanged: (val) async {
                            setState(() => _ringVolume = val);
                            await FlutterVolumeController.setVolume(val, stream: AudioStream.ring);
                          }
                        ),

                        SizedBox(height: screenHeight * 0.04),
                        
                        // Floating Button Control
                        _buildFloatingActionButton(isSmallScreen),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
    required bool isSmallScreen,
  }) {
    return _buildGlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 20 : 25,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
                child: Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
              ),
              SizedBox(width: isSmallScreen ? 12 : 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                "${(amount * 100).toInt()}%",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: [
                    Shadow(color: color.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 20 : 25),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              trackHeight: isSmallScreen ? 5.0 : 6.0,
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: isSmallScreen ? 8.0 : 10.0,
              ),
              overlayColor: color.withOpacity(0.2),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: isSmallScreen ? 20.0 : 24.0,
              ),
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
  
  Widget _buildFloatingActionButton(bool isSmallScreen) {
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
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 30 : 40,
                vertical: isSmallScreen ? 12 : 15,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: running
                      ? [const Color(0xFFFF512F).withOpacity(0.9), const Color(0xFFDD2476).withOpacity(0.9)]
                      : [const Color(0xFF4776E6).withOpacity(0.9), const Color(0xFF8E54E9).withOpacity(0.9)],
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
                    size: isSmallScreen ? 24 : 28,
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Text(
                    running ? "Stop Floating Button" : "Start Floating Button",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
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
