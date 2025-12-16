import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool running = false;

  Future<void> startOverlay() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      width: 44,
      height: 44,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
    );

    setState(() => running = true);
  }

  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Volume Control"),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: running ? stopOverlay : startOverlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: running ? Colors.redAccent : Colors.deepOrange,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: Text(
            running ? "Stop Floating Button" : "Start Floating Button",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// =====================
/// OVERLAY ENTRY
/// =====================
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloatingOverlay(),
    );
  }
}

/// =====================
/// FLOATING OVERLAY
/// =====================
class FloatingOverlay extends StatefulWidget {
  const FloatingOverlay({super.key});

  @override
  State<FloatingOverlay> createState() => _FloatingOverlayState();
}

class _FloatingOverlayState extends State<FloatingOverlay> {
  bool expanded = false;
  double volume = 0.5;
  Timer? autoHide;

  @override
  void initState() {
    super.initState();
    FlutterVolumeController.getVolume(
      stream: AudioStream.music,
    ).then((v) => setState(() => volume = v ?? 0.5));
  }

  void startAutoHide() {
    autoHide?.cancel();
    autoHide = Timer(const Duration(seconds: 5), collapse);
  }

  @override
  Widget build(BuildContext context) {
    return expanded ? expandedPanel() : bubble();
  }

  /// 🔵 TINY BUBBLE
  Widget bubble() {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await FlutterOverlayWindow.resizeOverlay(260, 420, false);
            startAutoHide();
            setState(() => expanded = true);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up,
                color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  /// 🫧 IMAGE-3 STYLE PANEL
  Widget expandedPanel() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: collapse,
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: Container(
              height: 380,
              width: 240,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 30,
                    child: Text(
                      "${(volume * 100).round()}",
                      style: TextStyle(
                        fontSize: 160,
                        fontWeight: FontWeight.w200,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        "VOLUME",
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      RotatedBox(
                        quarterTurns: -1,
                        child: Slider(
                          min: 0,
                          max: 1,
                          value: volume,
                          onChanged: (v) {
                            HapticFeedback.lightImpact();
                            startAutoHide();
                            setState(() => volume = v);
                            FlutterVolumeController.setVolume(v);
                          },
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📍 COLLAPSE
  Future<void> collapse() async {
    autoHide?.cancel();
    await FlutterOverlayWindow.resizeOverlay(44, 44, true);
    setState(() => expanded = false);
  }
}
