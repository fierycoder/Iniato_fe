import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../models/ride_match.dart';
import '../models/fare_estimate.dart';
import '../services/ride_service.dart';
import '../widgets/iniato_button.dart';
import '../widgets/fare_breakdown.dart';
import 'active_ride_screen.dart';

/// Confirm and book a ride — shows driver, route, fare, co-riders.
class RideDetailsScreen extends StatefulWidget {
  final MatchingRide ride;
  final FareEstimate? fareEstimate;
  final double pickupLat, pickupLng;
  final double destLat, destLng;
  final String pickupName, destName;

  const RideDetailsScreen({
    super.key,
    required this.ride,
    this.fareEstimate,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.pickupName,
    required this.destName,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  bool _isBooking = false;
  String _selectedPayment = 'CASH';

  Future<void> _confirmRide() async {
    setState(() => _isBooking = true);
    try {
      final ride = await RideService.requestRide(RideRequestDTO(
        rideId: widget.ride.rideId,
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        destLat: widget.destLat,
        destLng: widget.destLng,
        pickupLocation: widget.pickupName,
        destination: widget.destName,
      ));

      if (!mounted) return;

      if (ride != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveRideScreen(
              ride: ride,
              pickupName: widget.pickupName,
              destName: widget.destName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book ride')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    }
    if (mounted) setState(() => _isBooking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: IniatoTheme.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Route Card ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pickup
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: IniatoTheme.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PICKUP',
                                style: IniatoTheme.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1)),
                            const SizedBox(height: 2),
                            Text(widget.pickupName,
                                style: IniatoTheme.body
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 30,
                          color: IniatoTheme.green.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  // Destination
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: IniatoTheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DROP-OFF',
                                style: IniatoTheme.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1)),
                            const SizedBox(height: 2),
                            Text(widget.destName,
                                style: IniatoTheme.body
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Driver Info ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: IniatoTheme.green.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        color: IniatoTheme.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ride.driverName ?? 'Driver',
                          style: IniatoTheme.subheading.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: IniatoTheme.yellowDark),
                            const SizedBox(width: 4),
                            Text('4.8',
                                style: IniatoTheme.caption
                                    .copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Icon(Icons.people,
                                size: 14, color: IniatoTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('${widget.ride.coRiderCount} co-riders',
                                style: IniatoTheme.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Co-riders ───
            if (widget.ride.passengerNames.isNotEmpty) ...[
              Text('Co-riders',
                  style: IniatoTheme.subheading.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.ride.passengerNames.map((name) {
                  return Chip(
                    avatar: const CircleAvatar(
                      backgroundColor: IniatoTheme.green,
                      child:
                          Icon(Icons.person, color: Colors.white, size: 14),
                    ),
                    label: Text(name, style: IniatoTheme.caption),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Fare Breakdown ───
            if (widget.fareEstimate != null) ...[
              Text('Fare Estimate',
                  style: IniatoTheme.subheading.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              FareBreakdownWidget(
                fare: widget.fareEstimate!,
                passengers: widget.ride.coRiderCount + 1,
              ),
              const SizedBox(height: 16),
            ],

            // ─── Payment Method ───
            Text('Payment Method',
                style: IniatoTheme.subheading.copyWith(fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: ['CASH', 'UPI', 'WALLET'].map((method) {
                final selected = _selectedPayment == method;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPayment = method),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: method != 'WALLET' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? IniatoTheme.green.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? IniatoTheme.green
                              : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            method == 'CASH'
                                ? Icons.money
                                : method == 'UPI'
                                    ? Icons.account_balance
                                    : Icons.account_balance_wallet,
                            color: selected
                                ? IniatoTheme.green
                                : IniatoTheme.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method[0] + method.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected
                                  ? IniatoTheme.green
                                  : IniatoTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ─── Confirm Button ───
            IniatoButton(
              label: 'Confirm Ride',
              onPressed: _confirmRide,
              isLoading: _isBooking,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
