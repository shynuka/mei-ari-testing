import 'package:flutter/material.dart';
import 'package:meiarife/screens/app_screen/section_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name = "";
  String role = "";
  int created = 0;
  int completed = 0;
  int verified = 0;
  int signed = 0;
  String departmentName = "";
  String subDepartmentName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTicketStatus();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('email')?.split('@')[0] ?? "";
      role = prefs.getString('role') ?? "";
      departmentName = prefs.getString('department_name') ?? "";
      subDepartmentName = prefs.getString('sub_department_name') ?? "";
    });
  }

  Future<void> _fetchTicketStatus() async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.107.231:8000/api/v1/workgroup/b1b902ef-ce5e-449d-91a1-d12148628610/ticket-status-count/',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      setState(() {
        created = data['Created'];
        completed = data['Completed'];
        verified = data['Verified'];
        signed = data['Signed'];
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Group"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Group Name"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Group Description",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Create"),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final subDeptOffice = prefs.getString('sub_dept_office_name');

                if (subDeptOffice == null || nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields.")),
                  );
                  return;
                }

                final body = {
                  "sub_dept_office": subDeptOffice,
                  "group_name": nameController.text,
                  "is_active": true,
                  "group_description": descriptionController.text,
                };

                final response = await http.post(
                  Uri.parse(
                    'http://192.168.107.231:8000/api/v1/create-workgroup-with-details/',
                  ),
                  headers: {"Content-Type": "application/json"},
                  body: json.encode(body),
                );

                Navigator.pop(context); // Close dialog

                if (response.statusCode == 200 || response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Group created successfully!"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${response.body}")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Bar with Department Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded, color: Colors.blue[900]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            departmentName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchTicketStatus,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ],
              ),

              const Divider(height: 24),

              /// Sub Department Name
              Row(
                children: [
                  const Icon(Icons.verified, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subDepartmentName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Greeting
              Text(
                "Hi, $name",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(role, style: TextStyle(color: Colors.grey[600])),

              const SizedBox(height: 30),

              /// Status Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatusCard("Created", created),
                  _buildStatusCard("Completed", completed),
                  _buildStatusCard("Verified", verified),
                  _buildStatusCard("Signed", signed),
                ],
              ),

              const SizedBox(height: 30),

              /// Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SectionFormScreen(
                                  departmentId: "67cfde1dbc4626b26252cb81",
                                ),
                          ),
                        );
                      },
                      child: const Text("Create a Report"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showCreateGroupDialog();
                      },
                      child: const Text("Create a Group"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString().padLeft(2, '0'),
            style: TextStyle(fontSize: 48, color: Colors.indigo[700]),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
