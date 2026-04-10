import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/fare_estimate.dart';

/// Widget displaying fare breakdown: distance, total, per-passenger share.
class FareBreakdownWidget extends StatelessWidget {
  final FareEstimate fare;
  final int passengers;

  const FareBreakdownWidget({
    super.key,
    required this.fare,
    this.passengers = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IniatoTheme.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
        border: Border.all(color: IniatoTheme.green.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildRow('Distance', '${fare.distanceKm.toStringAsFixed(1)} km'),
          const Divider(height: 16),
          _buildRow('Total fare', '₹${fare.totalFare.toStringAsFixed(0)}'),
          const Divider(height: 16),
          _buildRow(
            'Your share ($passengers riders)',
            '₹${fare.perPassengerFare.toStringAsFixed(0)}',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isHighlighted
              ? IniatoTheme.subheading.copyWith(fontSize: 15)
              : IniatoTheme.body,
        ),
        Text(
          value,
          style: isHighlighted
              ? IniatoTheme.subheading.copyWith(
                  color: IniatoTheme.green,
                  fontSize: 18,
                )
              : IniatoTheme.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
