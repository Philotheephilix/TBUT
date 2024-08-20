import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isStreaming = false;

  static const platform = MethodChannel('rtmp_streaming'); // Corrected this line

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
    await _cameraController!.initialize();
    setState(() {});
  }

  void startStreaming() async {
    try {
      await platform.invokeMethod('startStream');
      setState(() {
        _isStreaming = true;
      });
    } on PlatformException catch (e) {
      print("Failed to start streaming: ${e.message}");
    }
  }

  void stopStreaming() async {
    try {
      await platform.invokeMethod('stopStream');
      setState(() {
        _isStreaming = false;
      });
    } on PlatformException catch (e) {
      print("Failed to stop streaming: ${e.message}");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RTMP Streaming'),
      ),
      body: Column(
        children: [
          _cameraController != null && _cameraController!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                )
              : const Center(child: CircularProgressIndicator()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isStreaming ? null : startStreaming,
                child: const Text('Start Streaming'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isStreaming ? stopStreaming : null,
                child: const Text('Stop Streaming'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
