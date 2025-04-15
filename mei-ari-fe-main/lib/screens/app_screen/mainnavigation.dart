import 'package:flutter/material.dart';
import 'package:meiarife/screens/app_screen/dashboard_screen.dart';
import 'package:meiarife/screens/app_screen/group_listing.dart';
import 'package:meiarife/screens/app_screen/report_listing_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    GroupListingScreen(),
    ReportListingScreen(),
    // DepartmentScreen(),
    // ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
