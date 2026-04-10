import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Reusable Iniato-branded gradient button with press animation.
class IniatoButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  const IniatoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  @override
  State<IniatoButton> createState() => _IniatoButtonState();
}

class _IniatoButtonState extends State<IniatoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.outlined) {
      return _buildOutlined();
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
            gradient: IniatoTheme.buttonGradient,
            boxShadow: IniatoTheme.buttonShadow,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: IniatoTheme.yellow,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: IniatoTheme.yellow, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(widget.label, style: IniatoTheme.buttonText),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlined() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: IniatoTheme.green, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: widget.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                widget.label,
                style: IniatoTheme.subheading
                    .copyWith(color: IniatoTheme.green, fontSize: 16),
              ),
      ),
    );
  }
}
