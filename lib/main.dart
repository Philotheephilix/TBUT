import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(CameraApp(camera: firstCamera));
}

class CameraApp extends StatelessWidget {
  final CameraDescription camera;

  CameraApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraStream(camera: camera),
    );
  }
}

class CameraStream extends StatefulWidget {
  final CameraDescription camera;

  CameraStream({required this.camera});

  @override
  _CameraStreamState createState() => _CameraStreamState();
}

class _CameraStreamState extends State<CameraStream> {
  late CameraController _controller;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;

      // Initialize Socket.IO
      socket = IO.io('http://192.168.43.98:5000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.onConnect((_) {
        print('Connected to server');
        _controller.startImageStream((CameraImage image) {
          _sendFrame(image);
        });
      });

      socket.onDisconnect((_) => print('Disconnected from server'));

      socket.connect();

      setState(() {});
    });
  }

  Future<void> _sendFrame(CameraImage image) async {
    try {
      // Convert CameraImage to JPEG
      Uint8List jpegData = _convertCameraImageToJpeg(image);

      // Encode JPEG bytes to Base64
      String encodedImage = base64Encode(jpegData);

      // Emit the image data to the server
      socket.emit('live_stream', encodedImage);
      print("Frame sent to server");
    } catch (e) {
      print('Error sending frame: $e');
    }
  }


Uint8List _convertCameraImageToJpeg(CameraImage image) {
  // Create Image object
  img.Image rgbImage = img.Image(width: image.width, height: image.height);

  // YUV420 to RGB conversion
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final int index = y * image.width + x;

      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];

      // Convert YUV to RGB
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

      // Set pixel color
      rgbImage.setPixelRgb(x, y, r, g, b);
    }
  }

  // Encode to JPEG
  return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 90));
}
  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Camera Stream')),
      body: CameraPreview(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    socket.dispose();
    super.dispose();
  }
}
