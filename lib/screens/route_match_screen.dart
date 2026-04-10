import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/ride_service.dart';
import '../models/ride_match.dart';
import '../models/fare_estimate.dart';
import '../widgets/empty_state.dart';
import '../widgets/iniato_button.dart';
import 'ride_details_screen.dart';

/// Shows matching rides and nearby drivers for the selected route.
class RouteMatchScreen extends StatefulWidget {
  final double pickupLat, pickupLng;
  final double destLat, destLng;
  final String pickupName, destName;

  const RouteMatchScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.pickupName,
    required this.destName,
  });

  @override
  State<RouteMatchScreen> createState() => _RouteMatchScreenState();
}

class _RouteMatchScreenState extends State<RouteMatchScreen> {
  bool _isLoading = true;
  RideMatchResponse? _matchResponse;
  FareEstimate? _fareEstimate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _findMatches();
  }

  Future<void> _findMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        RideService.findMatches(
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          destLat: widget.destLat,
          destLng: widget.destLng,
          pickupLocation: widget.pickupName,
          destination: widget.destName,
        ),
        RideService.estimateFare(
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          destLat: widget.destLat,
          destLng: widget.destLng,
          passengers: 1,
        ),
      ]);

      if (mounted) {
        setState(() {
          _matchResponse = results[0] as RideMatchResponse?;
          _fareEstimate = results[1] as FareEstimate?;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error finding rides');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: IniatoTheme.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Route header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: IniatoTheme.green,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.white70),
                    Container(
                      width: 2,
                      height: 24,
                      color: Colors.white38,
                    ),
                    const Icon(Icons.location_on, size: 14, color: IniatoTheme.yellow),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pickupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.destName,
                        style: const TextStyle(
                          color: IniatoTheme.yellow,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_fareEstimate != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '₹${_fareEstimate!.perPassengerFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${_fareEstimate!.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: 'Something went wrong',
                        subtitle: _error!,
                        action: IniatoButton(
                          label: 'Retry',
                          onPressed: _findMatches,
                          outlined: true,
                        ),
                      )
                    : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final rides = _matchResponse?.matchingRides ?? [];
    final drivers = _matchResponse?.nearbyDrivers ?? [];

    if (rides.isEmpty && drivers.isEmpty) {
      return EmptyState(
        icon: Icons.no_transfer,
        title: 'No rides available',
        subtitle: 'No autos are currently on this route.\nTry again in a few minutes.',
        action: IniatoButton(
          label: 'Refresh',
          onPressed: _findMatches,
          outlined: true,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rides.isNotEmpty) ...[
          Text(
            'Matching Rides',
            style: IniatoTheme.subheading.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...rides.map(_buildRideCard),
          const SizedBox(height: 16),
        ],
        if (drivers.isNotEmpty) ...[
          Text(
            'Nearby Drivers',
            style: IniatoTheme.subheading.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...drivers.map(_buildDriverCard),
        ],
      ],
    );
  }

  Widget _buildRideCard(MatchingRide ride) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideDetailsScreen(
              ride: ride,
              fareEstimate: _fareEstimate,
              pickupLat: widget.pickupLat,
              pickupLng: widget.pickupLng,
              destLat: widget.destLat,
              destLng: widget.destLng,
              pickupName: widget.pickupName,
              destName: widget.destName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Auto icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: IniatoTheme.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_taxi,
                  color: IniatoTheme.green, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.driverName ?? 'Driver',
                    style:
                        IniatoTheme.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ride.pickupLocation} → ${ride.destination}',
                    style: IniatoTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: IniatoTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${ride.coRiderCount} co-riders',
                          style: IniatoTheme.caption.copyWith(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Fare
            if (_fareEstimate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_fareEstimate!.perPassengerFare.toStringAsFixed(0)}',
                    style: IniatoTheme.subheading.copyWith(
                      color: IniatoTheme.green,
                      fontSize: 18,
                    ),
                  ),
                  Text('your share', style: IniatoTheme.caption.copyWith(fontSize: 11)),
                ],
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: IniatoTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(NearbyDriver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: IniatoTheme.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: IniatoTheme.yellowDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Driver #${driver.driverId}',
                    style: IniatoTheme.body.copyWith(fontWeight: FontWeight.w600)),
                Text('${driver.distanceKm} km away',
                    style: IniatoTheme.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: IniatoTheme.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Nearby',
              style: TextStyle(
                color: IniatoTheme.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
