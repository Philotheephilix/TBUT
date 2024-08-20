import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CameraStreamPage(camera: camera),
    );
  }
}

class CameraStreamPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraStreamPage({super.key, required this.camera});

  @override
  _CameraStreamPageState createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late IO.Socket _socket;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    _connectToServer();
  }

  void _connectToServer() {
    _socket = IO.io('http://192.168.43.98:5000', <String, dynamic>{
      'transports': ['websocket'],
    });
    _socket.onConnect((_) {
      print('Connected to server');
    });
  }

  void _startStreaming() async {
    setState(() {
      _isStreaming = true;
    });

    while (_isStreaming) {
      final XFile image = await _controller.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      _sendFrameToServer(imageBytes);
    }
  }

  void _stopStreaming() {
    setState(() {
      _isStreaming = false;
    });
  }

  void _sendFrameToServer(Uint8List imageBytes) {
    String base64Image = base64Encode(imageBytes);
    _socket.emit('frame', {'image': base64Image});
  }

  @override
  void dispose() {
    _controller.dispose();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Camera Stream')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isStreaming ? _stopStreaming : _startStreaming,
        child: Icon(_isStreaming ? Icons.stop : Icons.videocam),
      ),
    );
  }
}
