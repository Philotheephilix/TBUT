import 'package:eyetear/components/start_recording.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: Color(0xFFF7EFE5),
      body: Center(
        child: CapturingButton()
      ),
    );
  }
}
