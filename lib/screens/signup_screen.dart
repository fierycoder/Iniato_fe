import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_screen.dart';
import 'login_screen.dart'; // Make sure you have this imported

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  bool isPressed = false;

  Future<void> registerRider() async {
    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      "http://localhost:8080/api/auth/register/rider/${phoneController.text.trim()}",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": nameController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // send OTP
        await http.post(
          Uri.parse("http://localhost:8080/api/auth/register/rider/send-otp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phoneNumber": phoneController.text.trim()}),
        );

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OtpScreen(
              phoneNumber: phoneController.text.trim(),
              isLogin: false,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(1, 0), // slide from right
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to server")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void goToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(-1, 0), // slide from left
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color green = Color(0xFF1B5E20);
    final Color yellow = Color(0xFFFFEB3B);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              green.withOpacity(0.9),
              green.withOpacity(0.6),
              yellow.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Rider Signup",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: green,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Full Name Field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: TextStyle(color: green),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: green.withOpacity(0.5), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: green, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Phone Number Field
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: green),
                      prefixIcon: Icon(Icons.phone, color: green),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: green.withOpacity(0.5), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: green, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Register Button
                  GestureDetector(
                    onTapDown: (_) => setState(() => isPressed = true),
                    onTapUp: (_) {
                      setState(() => isPressed = false);
                      registerRider();
                    },
                    onTapCancel: () => setState(() => isPressed = false),
                    child: AnimatedScale(
                      scale: isPressed ? 0.95 : 1.0,
                      duration: Duration(milliseconds: 100),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [green, green.withOpacity(0.7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? CircularProgressIndicator(color: yellow)
                              : Text(
                            "Register",
                            style: TextStyle(
                              color: yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Back to Login Link
                  TextButton(
                    onPressed: goToLogin,
                    child: Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: green,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
