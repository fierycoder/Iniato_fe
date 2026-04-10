import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Color-coded status badge for ride status.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case 'POOL_FORMING':
        return 'Finding riders';
      case 'IN_PROGRESS':
        return 'In progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get _bgColor {
    switch (status) {
      case 'POOL_FORMING':
        return IniatoTheme.yellow.withOpacity(0.2);
      case 'IN_PROGRESS':
        return IniatoTheme.green.withOpacity(0.15);
      case 'COMPLETED':
        return IniatoTheme.success.withOpacity(0.15);
      case 'CANCELLED':
        return IniatoTheme.error.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color get _textColor {
    switch (status) {
      case 'POOL_FORMING':
        return IniatoTheme.yellowDark;
      case 'IN_PROGRESS':
        return IniatoTheme.green;
      case 'COMPLETED':
        return IniatoTheme.success;
      case 'CANCELLED':
        return IniatoTheme.error;
      default:
        return IniatoTheme.textSecondary;
    }
  }
}
