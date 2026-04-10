import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Reusable styled text field matching Iniato design.
class IniatoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  const IniatoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      autofocus: autofocus,
      readOnly: readOnly,
      onTap: onTap,
      decoration: IniatoTheme.inputDecoration(label, icon: icon).copyWith(
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
      style: IniatoTheme.body,
    );
  }
}
