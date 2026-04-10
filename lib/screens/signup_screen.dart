import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/iniato_button.dart';
import '../widgets/iniato_text_field.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedGender = 'MALE';
  String selectedPayment = 'CASH';
  bool isLoading = false;
  bool obscurePassword = true;

  final List<String> genders = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> paymentMethods = ['CASH', 'UPI', 'WALLET'];

  Future<void> registerRider() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    if (passwordController.text.trim().length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => isLoading = true);
    try {
      final success = await AuthService.registerRider(
        phone: phoneController.text.trim(),
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        gender: selectedGender,
        preferredPaymentMethod: selectedPayment,
      );

      if (!mounted) return;

      if (success) {
        // Send OTP after registration
        await AuthService.sendOtp(phoneController.text.trim(), isLogin: false);
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => OtpScreen(
              phoneNumber: phoneController.text.trim(),
              isLogin: false,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        _showSnackBar('Registration failed. Phone or email may already exist.');
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
                  const Text('Create Account', style: IniatoTheme.heading),
                  const SizedBox(height: 6),
                  Text(
                    'Join Iniato to start sharing rides',
                    style: IniatoTheme.caption.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  IniatoTextField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  IniatoTextField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  IniatoTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // Password
                  IniatoTextField(
                    controller: passwordController,
                    label: 'Password',
                    icon: Icons.lock,
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: IniatoTheme.green,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Gender + Payment Row
                  Row(
                    children: [
                      // Gender dropdown
                      Expanded(
                        child: _buildDropdown(
                          value: selectedGender,
                          items: genders,
                          label: 'Gender',
                          onChanged: (v) =>
                              setState(() => selectedGender = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Payment method dropdown
                      Expanded(
                        child: _buildDropdown(
                          value: selectedPayment,
                          items: paymentMethods,
                          label: 'Payment',
                          onChanged: (v) =>
                              setState(() => selectedPayment = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  IniatoButton(
                    label: 'Register',
                    onPressed: registerRider,
                    isLoading: isLoading,
                    icon: Icons.person_add,
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: IniatoTheme.caption.copyWith(fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Login',
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: IniatoTheme.inputDecoration(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(
                e[0] + e.substring(1).toLowerCase(),
                style: IniatoTheme.body.copyWith(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
