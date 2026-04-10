import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import 'status_badge.dart';

/// Card displaying ride summary — used in history and matching screens.
class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;

  const RideCard({super.key, required this.ride, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: ride.status),
                if (ride.requestedTime != null)
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(ride.requestedTime!),
                    style: IniatoTheme.caption,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup → Destination
            Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.circle, size: 10, color: IniatoTheme.green),
                    Container(
                      width: 2,
                      height: 24,
                      color: IniatoTheme.green.withOpacity(0.3),
                    ),
                    Icon(Icons.location_on, size: 14, color: IniatoTheme.error),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupLocation,
                        style: IniatoTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ride.destination,
                        style: IniatoTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Riders count
            if (ride.passengers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: IniatoTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${ride.passengers.length} rider(s)',
                    style: IniatoTheme.caption,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
