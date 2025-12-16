import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

void main() {
  runApp(const MyApp());
}

/// =====================
/// MAIN APP (Launcher UI)
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
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      width: 70,
      height: 70,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
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
/// OVERLAY ENTRY POINT
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

  @override
  void initState() {
    super.initState();
    FlutterVolumeController.getVolume()
        .then((v) => setState(() => volume = v ?? 0.5));
  }

  @override
  Widget build(BuildContext context) {
    return expanded ? expandedUI() : collapsedBubble();
  }

  /// 🔵 COLLAPSED FLOATING BUTTON
  Widget collapsedBubble() {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await FlutterOverlayWindow.resizeOverlay(320, 360, true);
            setState(() => expanded = true);
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.volume_up,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  /// 🟠 EXPANDED PANEL (tap outside to close)
  Widget expandedUI() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 👇 TAP ANYWHERE OUTSIDE → COLLAPSE + SNAP
          GestureDetector(
            onTap: collapseAndSnap,
            child: Container(color: Colors.transparent),
          ),

          // PANEL
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Volume Control",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    Icons.volume_up,
                    size: 40,
                    color: Colors.deepOrange.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${(volume * 100).round()}%",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: volume,
                    onChanged: (v) {
                      setState(() => volume = v);
                      FlutterVolumeController.setVolume(v);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 COLLAPSE + SNAP TO EDGE
  Future<void> collapseAndSnap() async {
    await FlutterOverlayWindow.resizeOverlay(70, 70, true);
    await FlutterOverlayWindow.updateOverlayAlignment(
      OverlayAlignment.centerRight,
    );
    setState(() => expanded = false);
  }
}
