import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../models/fare_estimate.dart';
import '../services/ride_service.dart';
import '../widgets/iniato_button.dart';
import '../widgets/fare_breakdown.dart';
import 'main_nav_screen.dart';

/// Post-ride summary screen with fare, rating, and completion.
class RideCompleteScreen extends StatefulWidget {
  final Ride ride;
  final FareEstimate? fareEstimate;
  /// The rider's own pickup name (may differ from the full route's origin).
  final String? riderPickup;
  /// The rider's own drop-off name (may differ from the full route's destination).
  final String? riderDest;

  const RideCompleteScreen({
    super.key,
    required this.ride,
    this.fareEstimate,
    this.riderPickup,
    this.riderDest,
  });

  @override
  State<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends State<RideCompleteScreen> {
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitAndExit() async {
    setState(() => _isSubmitting = true);
    // Submit rating if the user selected one
    if (_rating > 0) {
      await RideService.rateDriver(widget.ride.rideId, _rating);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ─── Success Icon ───
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: IniatoTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: IniatoTheme.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ride Completed!',
                style: IniatoTheme.heading,
              ),
              const SizedBox(height: 4),
              Text(
                'Thanks for riding with Iniato',
                style: IniatoTheme.caption.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 28),

              // ─── Route Summary ───
              Container(
                width: double.infinity,
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
                    Column(
                      children: [
                        const Icon(Icons.circle,
                            size: 10, color: IniatoTheme.green),
                        Container(
                          width: 2,
                          height: 24,
                          color: IniatoTheme.green.withOpacity(0.3),
                        ),
                        const Icon(Icons.location_on,
                            size: 14, color: IniatoTheme.error),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              widget.riderPickup?.isNotEmpty == true
                                  ? widget.riderPickup!
                                  : widget.ride.pickupLocation,
                              style: IniatoTheme.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          Text(
                              widget.riderDest?.isNotEmpty == true
                                  ? widget.riderDest!
                                  : widget.ride.destination,
                              style: IniatoTheme.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Fare ───
              if (widget.fareEstimate != null)
                FareBreakdownWidget(
                  fare: widget.fareEstimate!,
                  passengers: widget.ride.passengers.length,
                ),
              const SizedBox(height: 24),

              // ─── Rate Driver ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Text('Rate your driver',
                        style: IniatoTheme.subheading.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < _rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 36,
                              color: index < _rating
                                  ? IniatoTheme.yellowDark
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_rating > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _rating >= 4
                            ? 'Great ride! 🎉'
                            : _rating >= 3
                                ? 'Good ride 👍'
                                : 'We\'ll improve 🙏',
                        style: IniatoTheme.caption.copyWith(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ─── Done ───
              IniatoButton(
                label: 'Done',
                onPressed: _isSubmitting ? null : _submitAndExit,
                icon: Icons.home,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
