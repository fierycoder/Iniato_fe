import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/iniato_button.dart';
import '../widgets/iniato_text_field.dart';
import 'main_nav_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isLogin;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.isLogin,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;
  bool isResending = false;

  Future<void> verifyOtp() async {
    if (otpController.text.trim().isEmpty) {
      _showSnackBar('Please enter the OTP');
      return;
    }

    setState(() => isLoading = true);
    try {
      final authResponse = await AuthService.verifyOtp(
        widget.phoneNumber,
        otpController.text.trim(),
        isLogin: widget.isLogin,
      );

      if (!mounted) return;

      if (authResponse != null) {
        // Successfully verified — token is stored, go to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false, // Clear entire back stack
        );
      } else {
        _showSnackBar('Invalid OTP');
      }
    } catch (e) {
      _showSnackBar('Error connecting to server');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resendOtp() async {
    setState(() => isResending = true);
    try {
      final success = await AuthService.sendOtp(
        widget.phoneNumber,
        isLogin: widget.isLogin,
      );
      if (!mounted) return;
      _showSnackBar(success ? 'OTP sent again' : 'Failed to resend OTP');
    } catch (e) {
      _showSnackBar('Error connecting to server');
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
                  // Lock icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: IniatoTheme.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: IniatoTheme.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Verify OTP', style: IniatoTheme.heading),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the code sent to',
                    style: IniatoTheme.caption.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.phoneNumber,
                    style: IniatoTheme.subheading.copyWith(
                      color: IniatoTheme.green,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // OTP Field
                  IniatoTextField(
                    controller: otpController,
                    label: 'OTP Code',
                    icon: Icons.pin,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),

                  // Verify Button
                  IniatoButton(
                    label: 'Verify',
                    onPressed: verifyOtp,
                    isLoading: isLoading,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(height: 16),

                  // Resend + Go Back
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isResending ? null : resendOtp,
                        child: isResending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: IniatoTheme.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Go Back',
                          style: TextStyle(
                            color: IniatoTheme.green,
                            fontWeight: FontWeight.w600,
                          ),
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
