import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/iniato_button.dart';
import '../widgets/iniato_text_field.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> sendLoginOtp() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Please enter a phone number');
      return;
    }

    setState(() => isLoading = true);
    try {
      final success = await AuthService.sendOtp(phone, isLogin: true);
      if (!mounted) return;
      if (success) {
        Navigator.push(
          context,
          _fadeRoute(OtpScreen(phoneNumber: phone, isLogin: true)),
        );
      } else {
        _showSnackBar('Failed to send OTP. Are you registered?');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: IniatoTheme.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: IniatoTheme.cardDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: IniatoTheme.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      size: 32,
                      color: IniatoTheme.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Welcome Back', style: IniatoTheme.heading),
                  const SizedBox(height: 6),
                  Text(
                    'Login with your phone number',
                    style: IniatoTheme.caption.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 28),

                  // Phone
                  IniatoTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Send OTP Button
                  IniatoButton(
                    label: 'Send OTP',
                    onPressed: sendLoginOtp,
                    isLoading: isLoading,
                    icon: Icons.sms,
                  ),
                  const SizedBox(height: 20),

                  // Signup link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: IniatoTheme.caption.copyWith(fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: IniatoTheme.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
