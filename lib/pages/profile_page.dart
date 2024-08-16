import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
           backgroundColor: Color(0xFFF7EFE5),

      body: Center(
        child: Text(
          'Profile Page',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF6B4389), // Purple color matching the design
          ),
        ),
      ),
    );
  }
}
