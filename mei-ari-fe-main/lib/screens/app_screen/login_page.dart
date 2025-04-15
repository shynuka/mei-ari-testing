import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meiarife/screens/app_screen/mainnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meiarife/screens/app_screen/department_list_screen.dart';
import 'package:meiarife/screens/app_screen/dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final LocalAuthentication authentication = LocalAuthentication();

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter email and password.");
      return;
    }

    final Uri url = Uri.parse("http://192.168.107.231:8000/api/v1/signin/");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          responseData['status']['status'] == "Success") {
        final session = responseData['session'];
        final data = responseData['data'];

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Store session tokens
        await prefs.setString('refresh_token', session['refresh']);
        await prefs.setString('access_token', session['token']);
        await prefs.setInt('token_validity', session['validity']);
        if (session['specialMessage'] != null) {
          await prefs.setString('special_message', session['specialMessage']);
        }

        // Store user details
        await prefs.setString('user_id', data['user_id']);
        await prefs.setString('email', data['email']);
        await prefs.setString('access_id', data['access_id']);
        await prefs.setBool('is_active', data['is_active']);
        await prefs.setString('role', data['role']);
        await prefs.setString('department_name', data['department_name']);
        await prefs.setString(
          'sub_department_name',
          data['sub_department_name'],
        );
        await prefs.setString(
          'sub_dept_office_name',
          data['sub_dept_office_name'],
        );

        // Proceed with biometric auth
        _authenticateUser();
      } else {
        _showError("Login failed: ${responseData['status']['message']}");
      }
    } catch (e) {
      _showError("Error: Unable to connect to the server.");
    }
  }

  Future<String?> getAccessId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_id');
  }

  Future<void> _authenticateUser() async {
    try {
      bool isAuthenticated = await authentication.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainNavigation()),
        );
      } else {
        _showError("Fingerprint authentication failed.");
      }
    } on PlatformException catch (e) {
      _showError("Authentication error: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA6B1E1), Color(0xFF3F51B5)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/MeiAriHome.png', width: 100, height: 100),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter your EmailID / AccessID",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter your Password:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    // Handle signup navigation
                  },
                  child: const Text(
                    "Don’t have an account? Signup",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
