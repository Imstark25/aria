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
  double volume = 0.6;

  @override
  void initState() {
    super.initState();
    FlutterVolumeController.getVolume(
      stream: AudioStream.music,
    ).then((v) => setState(() => volume = v ?? 0.6));
  }

  @override
  Widget build(BuildContext context) {
    return expanded ? expandedPanel() : bubble();
  }

  /// 🔵 TINY FLOATING BUBBLE
  Widget bubble() {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await FlutterOverlayWindow.resizeOverlay(260, 420, false);
            setState(() => expanded = true);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// 🧊 IMAGE-3 ACCURATE PANEL
  Widget expandedPanel() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // 🔥 TOUCH ANYWHERE → CLOSE
        onTap: collapse,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 240,
            height: 380,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 25),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // BIG GHOST NUMBER
                Positioned(
                  top: 30,
                  child: Text(
                    "${(volume * 100).round()}",
                    style: TextStyle(
                      fontSize: 160,
                      fontWeight: FontWeight.w200,
                      color: Colors.black.withOpacity(0.04),
                    ),
                  ),
                ),

                Column(
                  children: [
                    const Text(
                      "VOLUME CONTROL",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "MAX",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // VERTICAL SLIDER
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 10,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 16),
                            activeTrackColor: Colors.deepOrange,
                            inactiveTrackColor: Colors.grey.shade300,
                            overlayShape:
                                const RoundSliderOverlayShape(overlayRadius: 0),
                          ),
                          child: Slider(
                            min: 0,
                            max: 1,
                            value: volume,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              setState(() => volume = v);
                              FlutterVolumeController.setVolume(v);
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "MIN",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📍 COLLAPSE PANEL
  Future<void> collapse() async {
    await FlutterOverlayWindow.resizeOverlay(44, 44, true);
    setState(() => expanded = false);
  }
}
