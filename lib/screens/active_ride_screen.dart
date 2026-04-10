import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../services/websocket_service.dart';
import '../services/ride_service.dart';
import '../widgets/iniato_button.dart';
import 'ride_complete_screen.dart';
import 'main_nav_screen.dart';

/// Real-time ride tracking with WebSocket driver location updates.
class ActiveRideScreen extends StatefulWidget {
  final Ride ride;
  final String pickupName;
  final String destName;

  const ActiveRideScreen({
    super.key,
    required this.ride,
    required this.pickupName,
    required this.destName,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final WebSocketService _wsService = WebSocketService();
  MapboxMap? _mapController;
  StreamSubscription? _locationSub;

  String _rideStatus = '';
  double? _driverLat, _driverLng;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _rideStatus = widget.ride.status;
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _wsService.connect();
    // Small delay to wait for connection
    Future.delayed(const Duration(seconds: 1), () {
      _wsService.subscribeToRide(widget.ride.rideId);
    });

    _locationSub = _wsService.locationUpdates.listen((update) {
      if (mounted) {
        setState(() {
          _driverLat = update.latitude;
          _driverLng = update.longitude;
        });
        _updateDriverOnMap(update.latitude, update.longitude);
      }
    });
  }

  void _updateDriverOnMap(double lat, double lng) {
    _mapController?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  void _onMapCreated(MapboxMap controller) {
    _mapController = controller;
    _mapController?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _cancelRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Ride?'),
        content: const Text(
          'Are you sure you want to leave this shared ride? '
          'You may be charged a cancellation fee.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Leave', style: TextStyle(color: IniatoTheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      await RideService.leaveRide(widget.ride.rideId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave ride')),
        );
      }
    }
    if (mounted) setState(() => _isCancelling = false);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApproaching = _rideStatus == 'POOL_FORMING';
    final isInProgress = _rideStatus == 'IN_PROGRESS';

    return Scaffold(
      body: Stack(
        children: [
          // ─── Map ───
          MapWidget(onMapCreated: _onMapCreated),

          // ─── Status Bar ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isInProgress
                    ? IniatoTheme.green
                    : IniatoTheme.yellowDark,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isInProgress ? Icons.directions_car : Icons.schedule,
                    color: isInProgress ? Colors.white : IniatoTheme.greenDark,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isInProgress
                          ? 'Ride in progress'
                          : 'Waiting for auto...',
                      style: TextStyle(
                        color: isInProgress
                            ? Colors.white
                            : IniatoTheme.greenDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (_driverLat != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: isInProgress
                              ? Colors.white
                              : IniatoTheme.greenDark,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Bottom Panel ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Route info
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.circle,
                              size: 10, color: IniatoTheme.green),
                          Container(
                            width: 2,
                            height: 20,
                            color: IniatoTheme.green.withOpacity(0.3),
                          ),
                          const Icon(Icons.location_on,
                              size: 14, color: IniatoTheme.error),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.pickupName,
                                style: IniatoTheme.body
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 12),
                            Text(widget.destName,
                                style: IniatoTheme.body
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Driver info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: IniatoTheme.green.withOpacity(0.1),
                        child: const Icon(Icons.person,
                            color: IniatoTheme.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ride.driverEmail ?? 'Driver',
                              style: IniatoTheme.body
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${widget.ride.passengers.length} riders sharing',
                              style: IniatoTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      // Call button
                      Container(
                        decoration: BoxDecoration(
                          color: IniatoTheme.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone,
                              color: IniatoTheme.green),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: IniatoButton(
                          label: 'Leave Ride',
                          onPressed: _cancelRide,
                          isLoading: _isCancelling,
                          outlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // SOS
                      Container(
                        decoration: BoxDecoration(
                          color: IniatoTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.sos, color: IniatoTheme.error),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Emergency SOS triggered')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
