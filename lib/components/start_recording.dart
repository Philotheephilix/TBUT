import 'package:eyetear/components/captureSend.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class CapturingButton extends StatefulWidget {
  const CapturingButton({super.key});

  @override
  _CapturingButtonState createState() => _CapturingButtonState();
}

class _CapturingButtonState extends State<CapturingButton> {
  CameraDescription? firstCamera;
  String doctorId = '';
  String patientId = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    setState(() {
      firstCamera = cameras.first;
    });
  }

  void _showInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Doctor ID'),
                onChanged: (value) {
                  doctorId = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Patient ID'),
                onChanged: (value) {
                  patientId = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (firstCamera != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CameraStreamPage(
                        camera: firstCamera!,
                        doctorId: doctorId,
                        patientId: patientId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera not initialized yet. Please try again.')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          _showInputDialog(context);
        },
        label: const Text('Start Capturing',
            style: TextStyle(color: Color(0xFFF7EFE5), fontWeight: FontWeight.w600, fontSize: 22)),
        icon: const Icon(Icons.radio_button_checked_rounded, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4389),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
        ),
      ),
    );
  }
}
