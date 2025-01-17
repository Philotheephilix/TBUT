import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rtmp_broadcaster/camera.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CameraRTMPStream extends StatefulWidget {
  const CameraRTMPStream({super.key});

  @override
  _CameraRTMPStreamState createState() {
    return _CameraRTMPStreamState();
  }
}

class _CameraRTMPStreamState extends State<CameraRTMPStream> with WidgetsBindingObserver {
  CameraController? controller;
  String? url;
  String? _localIpAddress;
  bool useOpenGL = true;
  late SharedPreferences _prefs;
  double _sensitivity = 50.0;
  final TextEditingController _textFieldController = TextEditingController();
  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  
  bool _isCountingDown = false;
  int _countdown = 3;
  static const String IP_ADDRESS_KEY = 'server_ip_address';

  bool get isStreaming => controller?.value.isStreamingVideoRtmp ?? false;
  bool isVisible = true;
  bool get isControllerInitialized => controller?.value.isInitialized ?? false;
  bool get isStreamingVideoRtmp => controller?.value.isStreamingVideoRtmp ?? false;
  bool get isStreamingPaused => controller?.value.isStreamingPaused ?? false;

  HttpServer? _server;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePreferences();
    _initializeCamera();
    _startLocalServer();
    _initializeNetwork();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedIp = _prefs.getString(IP_ADDRESS_KEY);
    if (savedIp != null) {
      _localIpAddress = savedIp;
      _textFieldController.text = "rtmp://$savedIp:1935/live/";
    } else {
      _textFieldController.text = "rtmp://192.168.50.129:1935/live/";
    }
  }

  Future<void> _initializeNetwork() async {
    try {
      final interfaces = await NetworkInterface.list();
      
      for (var interface in interfaces) {
        print('Interface: ${interface.name}');
        for (var addr in interface.addresses) {
          print('  ${addr.address} (${addr.type.name})');
        }
      }

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.') &&
              (addr.address.startsWith('192.168.') || 
               addr.address.startsWith('10.') ||
               addr.address.startsWith('172.'))) {
            _localIpAddress ??= addr.address;
            print('Selected IP address: $_localIpAddress');
            break;
          }
        }
        if (_localIpAddress != null) break;
      }

      await _startLocalServer();
      
    } catch (e) {
      print('Network initialization error: $e');
    }
  }

  Future<void> _startLocalServer() async {
    if (_localIpAddress == null) {
      print('No suitable IP address found');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      print('Server listening on port 8080');
      
      _server!.listen((HttpRequest request) async {
        print('Received request from: ${request.connectionInfo?.remoteAddress.address}');
        
        if (request.method == 'POST' && request.uri.path == '/detection-complete') {
          try {
            final content = await utf8.decoder.bind(request).join();
            print('Received content: $content');
            
            final data = json.decode(content);
            
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(json.encode({'status': 'success'}));
            await request.response.close();

            if (mounted) {
              await stopVideoStreaming();
              _showElapsedTimeDialog(data['elapsed_time']);
            }
          } catch (e) {
            print('Error processing request: $e');
            request.response.statusCode = 500;
            await request.response.close();
          }
        } else {
          request.response.statusCode = 404;
          await request.response.close();
        }
      });
    } catch (e) {
      print('Error starting local server: $e');
    }
  }

  Future<void> _showIpSettingsDialog() async {
    String currentIp = _localIpAddress ?? '192.168.50.129';
    _ipAddressController.text = currentIp;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Server IP Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ipAddressController,
                decoration: const InputDecoration(
                  labelText: 'Server IP Address',
                  hintText: "Enter server IP address",
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () async {
                String newIp = _ipAddressController.text.trim();
                if (newIp.isNotEmpty) {
                  await _prefs.setString(IP_ADDRESS_KEY, newIp);
                  setState(() {
                    _localIpAddress = newIp;
                    _textFieldController.text = "rtmp://$newIp:1935/live/";
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showElapsedTimeDialog(double elapsedTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detection Complete'),
          content: Text(
            'Tear break-up time: ${elapsedTime.toStringAsFixed(2)} seconds',
            style: const TextStyle(fontSize: 18),
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

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    onNewCameraSelected(backCamera);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _server?.close();
    controller?.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (controller == null || !isControllerInitialized) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      isVisible = false;
      if (isStreaming) {
        await pauseVideoStreaming();
      }
    } else if (state == AppLifecycleState.resumed) {
      isVisible = true;
      if (controller != null) {
        if (isStreaming) {
          await resumeVideoStreaming();
        } else {
          onNewCameraSelected(controller!.description);
        }
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFE5),
      key: _scaffoldKey,
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Center(
                    child: _cameraPreviewWidget(),
                  ),
                ),
              ),
              _captureControlRowWidget(),
              const SizedBox(height: 20),
            ],
          ),
          if (_isCountingDown)
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  _countdown.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !isControllerInitialized) {
      return const Text(
        'Initializing camera...',
        style: TextStyle(
          color: Color(0xFF674188),
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller!.value.aspectRatio,
      child: CameraPreview(controller!),
    );
  }

  Widget _captureControlRowWidget() {
    if (controller == null) return Container();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.settings),
          color: const Color(0xFF674188),
          onPressed: _showIpSettingsDialog,
        ),
        IconButton(
          icon: const Icon(Icons.stream),
          color: const Color(0xFF674188),
          onPressed: controller != null && isControllerInitialized && !isStreamingVideoRtmp 
            ? startVideoStreaming 
            : null,
        ),
        IconButton(
          icon: isStreamingPaused ? const Icon(Icons.play_arrow) : const Icon(Icons.pause),
          color: const Color(0xFF674188),
          onPressed: controller != null && isControllerInitialized && isStreamingVideoRtmp
            ? (isStreamingPaused ? onResumeStreamingButtonPressed : onPauseStreamingButtonPressed)
            : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.red,
          onPressed: controller != null && isControllerInitialized && isStreamingVideoRtmp 
            ? onStopStreamingButtonPressed 
            : null,
        ),
      ],
    );
  }

  Future<bool> _validateAndCreateStream(String doctorId, String patientId, String streamUrl) async {
    try {
      final response = await http.post(
        Uri.parse('http://${_localIpAddress ?? '192.168.50.129'}:5000/api/start'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'doctorId': doctorId,
          'patientId': patientId,
          'streamUrl': '$streamUrl$doctorId$patientId',
          'sensitivity': _sensitivity.toString(), // Add sensitivity to request
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating stream: $e');
      return false;
    }
  }
    Future<String?> _getUrl() async {
    String result = _textFieldController.text;
    String doctorId = '';
    String patientId = '';

    return await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update slider state
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Stream Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _doctorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor ID',
                      hintText: "Enter Doctor ID",
                    ),
                    onChanged: (value) => doctorId = value,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _patientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID',
                      hintText: "Enter Patient ID",
                    ),
                    onChanged: (value) => patientId = value,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sensitivity: ${_sensitivity.round()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Slider(
                    value: _sensitivity,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _sensitivity.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _sensitivity = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                  onPressed: () {
                    if (doctorId.isEmpty || patientId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter both Doctor and Patient IDs'))
                      );
                      return;
                    }

                    _validateAndCreateStream(doctorId, patientId, result);

                    try {
                      Navigator.pop(context, result);
                    } on FlutterError {
                      // Handle any error here if necessary
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }


  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await stopVideoStreaming();
      await controller?.dispose();
    }
    
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.veryHigh,
      androidUseOpenGL: useOpenGL,
    );

    controller!.addListener(() async {
      if (mounted) setState(() {});

      if (controller != null && controller!.value.hasError) {
        showInSnackBar('Camera error ${controller!.value.errorDescription}');
        await stopVideoStreaming();
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onStopStreamingButtonPressed() {
    stopVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video not streaming to: $url');
    });
  }

  void onPauseStreamingButtonPressed() {
    pauseVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video streaming paused');
    });
  }

  void onResumeStreamingButtonPressed() {
    resumeVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video streaming resumed');
    });
  }

  Future<String?> startVideoStreaming() async {
    if (!isControllerInitialized) {
      showInSnackBar('Error: camera not initialized.');
      return null;
    }

    if (isStreamingVideoRtmp) {
      return null;
    }

    String? myUrl = await _getUrl();
    String myUri = myUrl.toString()+_doctorIdController.text.toString()+_patientIdController.text.toString();

    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _countdown--;
      });
      return _countdown > 0;
    }).then((_) {
      setState(() {
        _isCountingDown = false;
      });
    });
    try {
      await controller!.startVideoStreaming(myUri);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return url;
  }

  Future<void> stopVideoStreaming() async {
    if (controller == null || !isControllerInitialized) {
      return;
    }
    if (!isStreamingVideoRtmp) {
      return;
    }

    try {
      await controller!.stopVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> pauseVideoStreaming() async {
    if (!isStreamingVideoRtmp) {
      return;
    }

    try {
      await controller!.pauseVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoStreaming() async {
    if (!isStreamingVideoRtmp) {
      return;
    }

    try {
      await controller!.resumeVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    showInSnackBar('Error: ${e.code}\n${e.description ?? "No description found"}');
  }
}