import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GroupListingScreen extends StatefulWidget {
  @override
  _GroupListingScreenState createState() => _GroupListingScreenState();
}

class _GroupListingScreenState extends State<GroupListingScreen> {
  List<dynamic> workGroups = [];

  @override
  void initState() {
    super.initState();
    fetchWorkGroups();
  }

  Future<void> fetchWorkGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final subDeptOffice = prefs.getString('sub_dept_office_name');

    final url = Uri.parse(
      'http://192.168.107.231:8000/api/v1/workgroups/?sub_dept_office=$subDeptOffice',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          workGroups = jsonData['data'];
        });
      } else {
        print('Failed to load work groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching work groups: $e');
    }
  }

  Widget buildGroupCard(String name, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Column(
            children: const [
              Icon(Icons.add, size: 28),
              Text("Add Users", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Work Group"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView.builder(
        itemCount: workGroups.length,
        itemBuilder: (context, index) {
          final group = workGroups[index];
          return buildGroupCard(
            group['group_name'] ?? 'Unnamed Group',
            group['group_description'] ?? '',
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // DeviceHub tab
        onTap: (index) {
          // handle screen changes if needed
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.device_hub), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
