import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> predictions = [];
  bool isLoading = false;
  String? selectedPatientId;
  String? selectedDoctorId;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController doctorIdController = TextEditingController();
  String? ipAddress;

  @override
  void initState() {
    super.initState();
    _loadIpAddress();
  }

  Future<void> _loadIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ipAddress = prefs.getString('server_ip_address');
    });
    if (ipAddress != null) {
      fetchPredictions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP Address not found. Please set it in settings.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> fetchPredictions() async {
    if (ipAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP Address not configured'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (selectedPatientId != null && selectedPatientId!.isNotEmpty) {
        queryParams['patient_id'] = selectedPatientId!;
      }
      if (selectedDoctorId != null && selectedDoctorId!.isNotEmpty) {
        queryParams['doctor_id'] = selectedDoctorId!;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate!.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate!.toIso8601String();
      }

      final uri = Uri.parse('http://$ipAddress:5000/api/predictions')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          predictions = List<Map<String, dynamic>>.from(data['predictions']);
        });
      } else {
        throw Exception('Failed to load predictions: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
      fetchPredictions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ipAddress == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7EFE5),
        appBar: AppBar(
          title: const Text('Test History'),
          backgroundColor: const Color(0xFF6B4389),
        ),
        body: const Center(
          child: Text('Please configure IP address in settings'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7EFE5),
      appBar: AppBar(
        title: const Text('Test History'),
        backgroundColor: const Color(0xFF6B4389),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: patientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            selectedPatientId = value;
                          });
                          fetchPredictions();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: doctorIdController,
                        decoration: const InputDecoration(
                          labelText: 'Doctor ID',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            selectedDoctorId = value;
                          });
                          fetchPredictions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selectDate(context, true),
                        child: Text(
                          startDate != null
                              ? 'Start: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                              : 'Select Start Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selectDate(context, false),
                        child: Text(
                          endDate != null
                              ? 'End: ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                              : 'Select End Date',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedPatientId = null;
                      selectedDoctorId = null;
                      startDate = null;
                      endDate = null;
                      patientIdController.clear();
                      doctorIdController.clear();
                    });
                    fetchPredictions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4389),
                  ),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
          // Rest of the widgets remain the same...
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Patient ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4389),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Doctor ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4389),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TBUT (s)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4389),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4389),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF6B4389)),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : predictions.isEmpty
                    ? const Center(child: Text('No records found'))
                    : ListView.builder(
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = predictions[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestDetails(
                                    patientId: prediction['patient_id'],
                                    doctorId: prediction['doctor_id'],
                                    elapsedTime: prediction['elapsed_time'],
                                    confidence: prediction['confidence'],
                                    timestamp: DateTime.parse(prediction['timestamp']),
                                    sensitivity: prediction['sensitivity'],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      prediction['patient_id'],
                                      style: const TextStyle(color: Color(0xFF6B4389)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      prediction['doctor_id'],
                                      style: const TextStyle(color: Color(0xFF6B4389)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      prediction['elapsed_time'].toStringAsFixed(2),
                                      style: const TextStyle(color: Color(0xFF6B4389)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(DateTime.parse(prediction['timestamp'])),
                                      style: const TextStyle(color: Color(0xFF6B4389)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class TestDetails extends StatelessWidget {
  final String patientId;
  final String doctorId;
  final double elapsedTime;
  final double confidence;
  final DateTime timestamp;
  final double sensitivity;

  const TestDetails({
    super.key,
    required this.patientId,
    required this.doctorId,
    required this.elapsedTime,
    required this.confidence,
    required this.timestamp,
    required this.sensitivity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Details'),
        backgroundColor: const Color(0xFF6B4389),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Patient ID', patientId),
            _buildDetailRow('Doctor ID', doctorId),
            _buildDetailRow('TBUT Time', '${elapsedTime.toStringAsFixed(2)} seconds'),
            _buildDetailRow('Confidence', '${(confidence * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Sensitivity', '${(sensitivity * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Date & Time', DateFormat('yyyy-MM-dd HH:mm').format(timestamp)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4389),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B4389),
              ),
            ),
          ),
        ],
      ),
    );
  }
}