import 'package:flutter/material.dart';
import 'camera.dart';
class CapturingButton extends StatelessWidget {
  const CapturingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      
      child: Center(
       
        child: ElevatedButton.icon(
          onPressed: () {
        _showInputDialog(context);          },
          label: const Text('Start Capturing',style: TextStyle(color: Color(0xFFF7EFE5),fontWeight:FontWeight.w600,fontSize: 22)),
                  icon: const Icon(Icons.radio_button_checked_rounded, color: Colors.white),
      
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4389), // Button color (matches the purple in the screenshot)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          ),
        ),
      ),
    );
  }
}
void _showInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Details'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Doctor ID'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Patient ID'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
               Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
                ); // Close the dialog
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
  

