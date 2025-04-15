import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class MeiAriHomeScreen extends StatefulWidget {
  const MeiAriHomeScreen({super.key});

  @override
  State<MeiAriHomeScreen> createState() => _MeiAriHomeScreenState();
}

class _MeiAriHomeScreenState extends State<MeiAriHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 5 seconds and navigate to LoginPage
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA6B1E1),
              Color(0xFF3F51B5),
            ], // Light to Dark Blue
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/MeiAriHome.png', // Ensure this is in your assets folder
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: 'Mei',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Ari',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Colors.white, // Loader color
              ),
            ],
          ),
        ),
      ),
    );
  }
}
