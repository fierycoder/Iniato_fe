import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// Reusable Iniato-branded button with gradient, haptic feedback, and press animation.
class IniatoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;
  final double? width;
  final Color? color;

  const IniatoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
    this.width,
    this.color,
  });

  @override
  State<IniatoButton> createState() => _IniatoButtonState();
}

class _IniatoButtonState extends State<IniatoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null || widget.isLoading) return;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) {
    _controller.reverse();
    if (!widget.isLoading) widget.onPressed?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    if (widget.outlined) return _buildOutlined();

    final bg = widget.color ?? IniatoTheme.green;
    final disabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: disabled ? null : _onTapDown,
      onTapUp: disabled ? null : _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedOpacity(
          opacity: disabled && !widget.isLoading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.width ?? double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
              gradient: LinearGradient(
                colors: [bg, Color.lerp(bg, Colors.black, 0.18)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2.5,
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label, style: IniatoTheme.buttonText),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlined() {
    final color = widget.color ?? IniatoTheme.green;
    return OutlinedButton.icon(
      onPressed: widget.isLoading ? null : widget.onPressed,
      icon: widget.icon != null
          ? Icon(widget.icon, size: 18, color: color)
          : const SizedBox.shrink(),
      label: widget.isLoading
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Text(widget.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        minimumSize: Size(widget.width ?? double.infinity, 52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IniatoTheme.radiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
