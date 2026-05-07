import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';
import '../models/route_model.dart';
import 'active_ride_screen.dart';
import 'search_screen.dart';

/// Enhanced home screen with map, search bar, and nearby routes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapboxMap? _mapController;
  final LocationService _locationService = LocationService();
  PointAnnotationManager? _annotationManager;
  List<RouteModel> _nearbyRoutes = [];
  bool _isLoadingRoutes = false;
  gl.Position? _currentPosition;
  // Active ride resume
  Ride? _activeRide;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _checkActiveRide();
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() => _currentPosition = position);
      _loadNearbyRoutes(position.latitude, position.longitude);
    }
    _locationService.startTracking(
      onPosition: (pos) {
        if (mounted) setState(() => _currentPosition = pos);
      },
    );
  }

  /// Checks if the rider has an in-progress ride and stores it for the banner.
  Future<void> _checkActiveRide() async {
    try {
      final rides = await RideService.getMyRides();
      final active = rides.where((r) => r.isActive).toList();
      if (mounted) {
        setState(() => _activeRide = active.isNotEmpty ? active.first : null);
      }
    } catch (_) {}
  }

  Future<void> _loadNearbyRoutes(double lat, double lng) async {
    setState(() => _isLoadingRoutes = true);
    try {
      final routes = await RideService.getNearbyRoutes(lat, lng);
      if (mounted) setState(() => _nearbyRoutes = routes);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingRoutes = false);
  }

  void _onMapCreated(MapboxMap controller) {
    _mapController = controller;
    _mapController?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
  }

  void _centerOnUser() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ─── Full-screen Map ───
          MapWidget(
            onMapCreated: _onMapCreated,
          ),

          // ─── "Where to?" Search Bar ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      currentLat: _currentPosition?.latitude,
                      currentLng: _currentPosition?.longitude,
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(IniatoTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: IniatoTheme.green, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Where are you going?',
                        style: TextStyle(
                          color: IniatoTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule,
                        color: IniatoTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // ─── Active Ride Resume Banner ───
          if (_activeRide != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveRideScreen(
                        ride: _activeRide!,
                        pickupName: _activeRide!.passengerPickup.isNotEmpty
                            ? _activeRide!.passengerPickup
                            : _activeRide!.pickupLocation,
                        destName: _activeRide!.passengerDest.isNotEmpty
                            ? _activeRide!.passengerDest
                            : _activeRide!.destination,
                      ),
                    ),
                  ).then((_) => _checkActiveRide());
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: IniatoTheme.green,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: IniatoTheme.green.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ride in progress',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text(
                              _activeRide!.passengerPickup.isNotEmpty
                                  ? '${_activeRide!.passengerPickup} → ${_activeRide!.passengerDest}'
                                  : 'Tap to resume',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Resume',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── My Location Button ───
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'location',
              backgroundColor: Colors.white,
              onPressed: _centerOnUser,
              child: const Icon(Icons.my_location, color: IniatoTheme.green),
            ),
          ),

          // ─── Bottom Sheet: Nearby Routes / Recent ───
          DraggableScrollableSheet(
            initialChildSize: 0.12,
            minChildSize: 0.12,
            maxChildSize: 0.45,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick actions
                    Row(
                      children: [
                        _buildQuickAction(Icons.home_outlined, 'Home', () {}),
                        const SizedBox(width: 12),
                        _buildQuickAction(Icons.work_outline, 'Work', () {}),
                        const SizedBox(width: 12),
                        _buildQuickAction(Icons.star_outline, 'Saved', () {}),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nearby routes
                    if (_isLoadingRoutes)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (_nearbyRoutes.isNotEmpty) ...[
                      Text('Nearby Auto Routes', style: IniatoTheme.subheading.copyWith(fontSize: 15)),
                      const SizedBox(height: 8),
                      ..._nearbyRoutes.map(_buildRouteItem),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Search for a destination to find shared rides',
                            style: IniatoTheme.caption, textAlign: TextAlign.center),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: IniatoTheme.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: IniatoTheme.green, size: 22),
              const SizedBox(height: 4),
              Text(label, style: IniatoTheme.caption.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteItem(RouteModel route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: IniatoTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_taxi,
              color: IniatoTheme.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route #${route.routeId}',
                  style: IniatoTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${route.availableSeats} seats available',
                  style: IniatoTheme.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: IniatoTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              route.status,
              style: TextStyle(
                color: IniatoTheme.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
