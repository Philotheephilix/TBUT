import 'package:flutter/material.dart';
import 'package:rtmp_broadcaster/camera.dart';
import 'package:http/http.dart' as http;

class CameraRTMPStream extends StatefulWidget {
  @override
  _CameraRTMPStreamState createState() {
    return _CameraRTMPStreamState();
  }
}

class _CameraRTMPStreamState extends State<CameraRTMPStream> with WidgetsBindingObserver {
  CameraController? controller;
  String? url;
  bool useOpenGL = true;
  TextEditingController _textFieldController = TextEditingController(text: "rtmp://192.168.7.129:1935/live/your_stream");

  bool get isStreaming => controller?.value.isStreamingVideoRtmp ?? false;
  bool isVisible = true;

  bool get isControllerInitialized => controller?.value.isInitialized ?? false;
  bool get isStreamingVideoRtmp => controller?.value.isStreamingVideoRtmp ?? false;
  bool get isStreamingPaused => controller?.value.isStreamingPaused ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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
          color: const Color(0xFF674188),
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
          icon: const Icon(Icons.stream),
          color: const Color(0xFF674188),
          onPressed: controller != null && isControllerInitialized && !isStreamingVideoRtmp 
            ? onVideoStreamingButtonPressed 
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
        )
      ],
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

 TextEditingController _doctorIdController = TextEditingController();
  TextEditingController _patientIdController = TextEditingController();
  bool _isCountingDown = false;
  int _countdown = 3;

  Future<bool> _validateAndCreateStream(String doctorId, String patientId, String streamUrl) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.7.129:3000/stream/start'), 
        body: {
          'doctorId': doctorId,
          'patientId': patientId,
          'streamUrl': streamUrl,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating stream: $e');
      return false;
    }
  }

  void _startCountdown() {
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
      startVideoStreaming();
    });
  }

  Future<String?> _getUrl() async {
    String result = _textFieldController.text;
    String doctorId = '';
    String patientId = '';

    return await showDialog(
      context: context,
      builder: (context) {
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
              const SizedBox(height: 8),
              TextField(
                controller: _textFieldController,
                decoration: const InputDecoration(
                  labelText: 'Stream URL',
                  hintText: "URL to Stream to"
                ),
                onChanged: (value) => result = value,
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
                if (doctorId.isEmpty || patientId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both Doctor and Patient IDs'))
                  );
                  return;
                }
                
                final success = await _validateAndCreateStream(
                  doctorId,
                  patientId,
                  result
                );
                
                if (success) {
                  Navigator.pop(context, result);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create stream. Please try again.'))
                  );
                }
              },
            ),
          ],
        );
      }
    );
  }


  void onVideoStreamingButtonPressed() {
      _startCountdown();
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

    try {
      url = myUrl;
      await controller!.startVideoStreaming(url!);
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