import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';


class CameraStreamPage extends StatefulWidget {
  final CameraDescription camera;
  final String doctorId;
  final String patientId;

  const CameraStreamPage({
    super.key,
    required this.camera,
    required this.doctorId,
    required this.patientId,
  });

  @override
  _CameraStreamPageState createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late IO.Socket _socket;
  bool _isStreaming = false;
  final String _clientId = const Uuid().v4();
  final List<String> _predictions = [];

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
  }

  void _connectToServer() {
    _socket = IO.io('http://172.31.98.196:5000', <String, dynamic>{
      'transports': ['websocket'],
    });
    _socket.onConnect((_) {
      print('Connected to server with client ID: $_clientId');
    });

    _socket.on('inference_result', (data) {
      setState(() {
        _predictions.add(data['result'].toString());
        print(data);
      });
    });
  }

  void _startStreaming() async {
    setState(() {
      _isStreaming = true;
    });

    while (_isStreaming) {
      try {
        final XFile image = await _controller.takePicture();
        final Uint8List imageBytes = await image.readAsBytes();
        _sendImageToServer(imageBytes);
      } catch (e) {
        print("Error taking picture: $e");
      }
    }
  }

  void _stopStreaming() {
    setState(() {
      _isStreaming = false;
    });

    // Display predictions when streaming stops
    _showPredictions();
  }

  void _sendImageToServer(Uint8List imageBytes) {
    _socket.emit('frame', {
      'image': base64Encode(imageBytes),
      'client_id': _clientId,
      'doctor_id': widget.doctorId,
      'patient_id': widget.patientId,
    });
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