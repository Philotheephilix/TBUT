import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
  late Isolate _isolate;
  late StreamController<Uint8List> _streamController;
  late ReceivePort _receivePort;
  String _clientId = Uuid().v4();
  List<String> _predictions = []; // List to store predictions

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    _connectToServer();

    _streamController = StreamController<Uint8List>();
    _receivePort = ReceivePort();
  }

  void _connectToServer() {
    _socket = IO.io('http://172.31.98.196:5000', <String, dynamic>{
      'transports': ['websocket'],
    });
    _socket.onConnect((_) {
      print('Connected to server with client ID: $_clientId');
    });

    // Listen for prediction results from the server
    _socket.on('inference_result', (data) {
      setState(() {
        _predictions.add(data.toString()); 
        print(data);
        // Assuming the result is a string
      });
    });
  }

  void _startStreaming() async {
    setState(() {
      _isStreaming = true;
    });

    await _initializeIsolate();

    while (_isStreaming) {
      try {
        final XFile image = await _controller.takePicture();
        final Uint8List imageBytes = await image.readAsBytes();
        _streamController.add(imageBytes);
      } catch (e) {
        print("Error taking picture: $e");
      }
    }
  }

  void _stopStreaming() {
    setState(() {
      _isStreaming = false;
    });
    _streamController.close();
    _isolate.kill(priority: Isolate.immediate);

    // Display predictions when streaming stops
    _showPredictions();
  }

  Future<void> _initializeIsolate() async {
    _isolate = await Isolate.spawn(_processImages, _receivePort.sendPort);

    _receivePort.listen((data) {
      if (data is Uint8List) {
        _socket.emit('frame', {'image': data, 'client_id': _clientId});
      }
    });

    _streamController.stream.listen((imageBytes) {
      _sendToIsolate(imageBytes);
    });
  }

  void _sendToIsolate(Uint8List imageBytes) {
    _receivePort.sendPort.send(imageBytes);
  }

  static void _processImages(SendPort sendPort) {
    final receivePort = ReceivePort();

    receivePort.listen((data) async {
      if (data is Uint8List) {
        sendPort.send(data);
      }
    });

    sendPort.send(receivePort.sendPort);
  }

  void _showPredictions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Predictions'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _predictions.map((prediction) => Text(prediction)).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
