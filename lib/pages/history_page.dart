import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> patientData = [];

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  Future<void> fetchPatientData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.5:5000/api/predictions'));

      if (response.statusCode == 200) {
        setState(() {
          patientData = List<Map<String, dynamic>>.from(json.decode(response.body));
          print('Fetched patient data: $patientData'); // Log fetched data
        });
      } else {
        print('Error: ${response.statusCode}'); // Log status code
        throw Exception('Failed to load patient data');
      }
    } catch (e) {
      print('Fetch error: $e'); // Log error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFE5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Patient ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4389)))),
                Expanded(child: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4389)))),
              ],
            ),
            const Divider(color: Color(0xFF6B4389)),
            Expanded(
              child: ListView.builder(
                itemCount: patientData.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      print('Tapped on item: $index'); // Log tap event
                      final patient = patientData[index];

                      // Check if patient has results
                      final results = patient['results'];
                      if (results == null || results.isEmpty) {
                        print('No results for patient: ${patient['patient_id']}'); // Log missing results
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return TestDetails(
                              patientName: patient['patient_name'] ?? 'Ilayaraja', // Default value
                              patientID: patient['patient_id'] ?? 'Unknown ID', // Handle null patient_id
                              result: (results != null && results.isNotEmpty)
                                  ? _formatPredictions(results[0]['result']['predictions']) // Get predictions
                                  : 'No Result Available', // Handle case where 'results' is empty or null
                            );
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(patientData[index]['patient_id'] ?? 'N/A', style: const TextStyle(color: Color(0xFF6B4389)))),
                          Expanded(child: Text(patientData[index]['patient_name'] ?? 'Ilayaraja', style: const TextStyle(color: Color(0xFF6B4389)))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPredictions(List<dynamic> predictions) {
    if (predictions.isEmpty) {
      return 'No Predictions Available';
    } else {
      return predictions.map((prediction) => prediction.toString()).join(', '); // Join predictions into a string
    }
  }
}


class TestDetails extends StatelessWidget {
  final String patientName;
  final String patientID;
  final String result;

  const TestDetails({Key? key, required this.patientName, required this.patientID, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: const Color(0xFF6B4389),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patient Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Patient Name: $patientName', style: const TextStyle(fontSize: 18)),
            Text('Patient ID: $patientID', style: const TextStyle(fontSize: 18)),
            Text('Result: $result', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
