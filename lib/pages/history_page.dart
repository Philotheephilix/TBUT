import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
           backgroundColor: Color(0xFFF7EFE5),

      body: Center(
        child: Text(
          'History Page',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF6B4389), // Purple color matching the design
          ),
        ),
      ),
    );
  }
}
