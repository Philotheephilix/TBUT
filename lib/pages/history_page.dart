import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, String>> patientData = [
    {
      'dateTime': '21/3/24 15:06',
      'patientID': '467',
      'patientName': 'Raja',
      'result': 'Positive'
    },
    {
      'dateTime': '21/4/24 12:06',
      'patientID': '676',
      'patientName': 'Rahman',
      'result': 'Positive'
    },
    {
      'dateTime': '21/5/24 11:06',
      'patientID': '46',
      'patientName': 'Yesudas',
      'result': 'Positive'
    },
  ];

  HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFE5), // Background color from your design

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header row
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Patient ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4389)))),
                Expanded(child: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4389)))),
              ],
            ),
            const Divider(color: Color(0xFF6B4389)), // Divider matching the purple color
            // List builder for dynamic content
            Expanded(
              child: ListView.builder(
                itemCount: patientData.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      // Dummy redirection logic
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>const TestDetails(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(patientData[index]['patientID'] ?? '', style: const TextStyle(color: Color(0xFF6B4389)))),
                          Expanded(child: Text(patientData[index]['patientName'] ?? '', style: const TextStyle(color: Color(0xFF6B4389)))),
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
}

class DummyRedirectPage extends StatelessWidget {
  final String patientName;

  const DummyRedirectPage({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dummy Redirect'),
        backgroundColor: const Color(0xFF6B4389), // Matching purple color
      ),
      body: Center(
        child: Text(
          'Redirected to details for $patientName',
          style: const TextStyle(fontSize: 24, color: Color(0xFF6B4389)),
        ),
      ),
    );
  }
}
class TestDetails extends StatelessWidget {
  const TestDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: const Color(0xFF6B4389), // Matching purple color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Details Section
            const Text(
              'Patient Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Patient Name: Raja',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              'Patient ID: 467',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              'Doctor Incharge: Jayachandran R',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              'Patient Age: 47',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Test History Table
            Table(
              border: TableBorder.all(color: Colors.black),
              children: [
                const TableRow(children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Doctor ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Doctor Attended', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Results', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]),
                buildTableRow('21/3/24 15:06', '467', 'Jayachandran', 'Positive'),
                buildTableRow('21/4/24 12:06', '467', 'Jayachandran', 'Positive'),
                buildTableRow('21/5/24 11:06', '467', 'Jayachandran', 'Positive'),
              ],
            ),
          ],
        ),
      ),
      );
    
  }
}
TableRow buildTableRow(String dateTime, String doctorId, String doctorName, String result) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(dateTime),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(doctorId),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(doctorName),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(result),
      ),
    ]);
  }
