import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isLogin;

  OtpScreen({required this.phoneNumber, required this.isLogin});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool isPressed = false;
  bool isResending = false;

  Future<void> verifyOtp() async {
    if (otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      widget.isLogin
          ? "http://10.0.2.2:8080/api/auth/login/verify-otp"
          : "http://10.0.2.2:8080/api/auth/register/rider/verify-otp",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": widget.phoneNumber,
          "otp": otpController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP")),
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

  Future<void> resendOtp() async {
    setState(() => isResending = true);
    final url = Uri.parse(
      "http://10.0.2.2:8080/api/auth/${widget.isLogin ? 'login' : 'register/rider'}/send-otp",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": widget.phoneNumber}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent again")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to resend OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to server")),
      );
    } finally {
      setState(() => isResending = false);
    }
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
                    "Verify OTP",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: green,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Enter the OTP sent to",
                    style: TextStyle(fontSize: 16, color: green.withOpacity(0.8)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.phoneNumber,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green),
                  ),
                  SizedBox(height: 24),

                  // OTP Field
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "OTP",
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
                  SizedBox(height: 24),

                  // Verify Button
                  GestureDetector(
                    onTapDown: (_) => setState(() => isPressed = true),
                    onTapUp: (_) {
                      setState(() => isPressed = false);
                      verifyOtp();
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
                            "Verify",
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

                  SizedBox(height: 16),

                  // Resend OTP & Go Back Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isResending ? null : resendOtp,
                        child: isResending
                            ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(
                          "Resend OTP",
                          style: TextStyle(color: green, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Go Back",
                          style: TextStyle(color: green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
