import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportListingScreen extends StatefulWidget {
  @override
  _ReportListingScreenState createState() => _ReportListingScreenState();
}

class _ReportListingScreenState extends State<ReportListingScreen> {
  Map<String, List<dynamic>> groupedReports = {
    'Created': [],
    'Completed': [],
    'Verified': [],
    'Signed': [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('sub_dept_office_name') ?? '';
    final url = Uri.parse(
      'http://192.168.107.231:8000/api/v1/report-records/$uuid/',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      setState(() {
        for (var report in data) {
          final status = report['ticket_status_type'];
          if (groupedReports.containsKey(status)) {
            groupedReports[status]!.add(report);
          } else {
            groupedReports[status] = [report];
          }
        }
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateReportStatus(String id, String status) async {
    final url = Uri.parse(
      'http://192.168.107.231:8000/api/v1/update-status/$id/?status=$status',
    );
    await http.get(url);
  }

  Widget buildReportCard(Map<String, dynamic> report, String status) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(report['access_id'], style: TextStyle(fontSize: 24)),
        subtitle: Text("${report['city']} - ${report['created_at']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                String nextStatus;

                // Determine the next status based on current status
                if (status == 'Created') {
                  nextStatus = 'Completed';
                } else if (status == 'Completed') {
                  nextStatus = 'Verified';
                } else if (status == 'Verified') {
                  nextStatus = 'Signed';
                } else {
                  // If already 'Signed', do nothing or show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('This report is already Signed.')),
                  );
                  return;
                }

                updateReportStatus(report['id'], nextStatus).then((_) {
                  // Optionally refresh UI after status change
                  setState(() {
                    groupedReports[status]?.remove(report);
                    groupedReports[nextStatus]?.add(report);
                  });
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.remove_red_eye, color: Colors.blue),
              onPressed: () async {
                final response = await http.get(
                  Uri.parse(
                    "http://192.168.107.231:8000/api/v1/download-report/${report['id']}/",
                  ),
                );

                if (response.statusCode == 200) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        insetPadding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        child: Scaffold(
                          appBar: AppBar(
                            title: Text("Report Viewer"),
                            backgroundColor: Colors.blue,
                            automaticallyImplyLeading: false,
                            actions: [
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          body: SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              response.body,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load report.')),
                  );
                }
              },
            ),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status == 'Completed'
                      ? 'Completed'
                      : status == 'Verified'
                      ? 'Verified'
                      : status == 'Signed'
                      ? 'Signed'
                      : 'Created',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReportSection(String title, String status) {
    final reports = groupedReports[status] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              "$title - Reports",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          reports.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Text("No $title reports available."),
              )
              : Column(
                children:
                    reports
                        .map((report) => buildReportCard(report, status))
                        .toList(),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reports')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildReportSection('Created', 'Created'),
                    buildReportSection('Completed', 'Completed'),
                    buildReportSection('Verified', 'Verified'),
                    buildReportSection('Signed', 'Signed'),
                  ],
                ),
              ),
    );
  }
}
