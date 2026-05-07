import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../models/ride.dart';
import '../models/fare_estimate.dart';
import '../services/api_service.dart';
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
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;

  const ActiveRideScreen({
    super.key,
    required this.ride,
    required this.pickupName,
    required this.destName,
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.destLat = 0.0,
    this.destLng = 0.0,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final WebSocketService _wsService = WebSocketService();
  MapboxMap? _mapController;
  StreamSubscription? _locationSub;
  StreamSubscription? _statusSub;
  Timer? _wsReconnectTimer;

  String _rideStatus = 'PENDING_ACCEPTANCE';
  double? _driverLat, _driverLng;
  bool _isCancelling = false;
  bool _isRequestingDropOff = false;
  bool _dropOffRequested = false;
  bool _alreadyDropped = false;
  String? _myPhone;

  // Map layer state
  bool _routeDrawn = false;
  bool _driverLayerReady = false;

  // Queued PASSENGER_DROPPED events that arrived before phone loaded
  String? _pendingDroppedPhone;
  double? _pendingDroppedFare;
  double? _pendingDroppedDist;

  // Queued RIDE_COMPLETED event that arrived before phone loaded
  bool _pendingRideCompleted = false;
  double? _pendingCompletedFare;
  double? _pendingCompletedDist;

  // Queued PASSENGER_ADDED that arrived before phone loaded
  bool _pendingPassengerAdded = false;

  // 4-digit boarding OTP — shown to rider, driver scans/reads it to confirm boarding
  late final String _boardingOtp;

  /// Navigate to RideCompleteScreen, always using the rider's own
  /// pickup → drop-off segment for both display and fare calculation.
  /// [serverFare] is used only as a fallback if the fare-estimate API call fails.
  Future<void> _navigateToComplete({double? serverFare, double? serverDist}) async {
    if (!mounted) return;
    FareEstimate? estimate;

    // Prefer a fresh estimate based on the rider's actual route segment.
    if (widget.pickupLat != 0.0 && widget.destLat != 0.0) {
      estimate = await RideService.estimateFare(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        destLat: widget.destLat,
        destLng: widget.destLng,
        passengers: 1,
      );
    }

    // Fall back to server value if the API call failed.
    estimate ??= serverFare != null
        ? FareEstimate(
            perPassengerFare: serverFare,
            distanceKm: serverDist ?? 0,
            totalFare: serverFare,
          )
        : null;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RideCompleteScreen(
          ride: widget.ride,
          fareEstimate: estimate,
          riderPickup: widget.pickupName,
          riderDest: widget.destName,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Always start as PENDING_ACCEPTANCE — the driver hasn't confirmed yet.
    // Status advances only when we receive websocket events.
    _rideStatus = 'PENDING_ACCEPTANCE';
    // Generate a 4-digit boarding OTP tied to this ride session
    _boardingOtp = (1000 + Random().nextInt(9000)).toString();
    _loadPhone();
    _connectWebSocket();
  }

  Future<void> _loadPhone() async {
    final phone = await ApiService.getPhone();
    if (!mounted) return;
    setState(() => _myPhone = phone);

    // Replay any PASSENGER_ADDED that arrived before phone was ready
    if (_pendingPassengerAdded) {
      _pendingPassengerAdded = false;
      setState(() => _rideStatus = 'POOL_FORMING_CONFIRMED');
    }

    // Process any PASSENGER_DROPPED event that arrived before phone was ready
    if (_pendingDroppedPhone != null) {
      final pendingPhone = _pendingDroppedPhone!;
      final fare = _pendingDroppedFare;
      final dist = _pendingDroppedDist;
      _pendingDroppedPhone = null;
      _pendingDroppedFare = null;
      _pendingDroppedDist = null;
      if (pendingPhone == phone) {
        _alreadyDropped = true;
        if (mounted) {
          _navigateToComplete(serverFare: fare, serverDist: dist);
        }
        return;
      }
    }

    // Process any RIDE_COMPLETED event that arrived before phone was ready
    if (_pendingRideCompleted && !_alreadyDropped) {
      final fare = _pendingCompletedFare;
      final dist = _pendingCompletedDist;
      _pendingRideCompleted = false;
      _pendingCompletedFare = null;
      _pendingCompletedDist = null;
      if (mounted) {
        _navigateToComplete(serverFare: fare, serverDist: dist);
      }
    }
  }

  void _connectWebSocket() {
    _wsService.connect(
      onConnected: () {
        _wsReconnectTimer?.cancel();
        _wsService.subscribeToRide(widget.ride.rideId);
      },
      onDisconnected: () {
        _wsReconnectTimer?.cancel();
        _wsReconnectTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) _connectWebSocket();
        });
      },
    );

    _locationSub = _wsService.locationUpdates.listen((update) {
      if (mounted) {
        setState(() {
          _driverLat = update.latitude;
          _driverLng = update.longitude;
        });
        _updateDriverOnMap(update.latitude, update.longitude);
      }
    });

    _statusSub = _wsService.rideStatusUpdates.listen((event) {
      if (!mounted) return;
      switch (event.type) {
        case 'PASSENGER_ADDED':
          // passengerPhone is the identifier — fall back to passengerEmail for legacy backends
          final addedPhone = (event.data['passengerPhone']
              ?? event.data['passengerEmail']) as String?;
          if (_myPhone == null) {
            _pendingPassengerAdded = true;
          } else if (addedPhone == null || addedPhone == _myPhone) {
            setState(() => _rideStatus = 'POOL_FORMING_CONFIRMED');
          }
          break;
        case 'RIDE_STARTED':
          setState(() => _rideStatus = 'STARTED');
          _drawRoute();
          break;
        case 'RIDE_CANCELLED':
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride was cancelled by the system'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavScreen()),
              (route) => false,
            );
          }
          break;
        case 'PASSENGER_DROPPED':
          final droppedPhone = (event.data['passengerPhone']
              ?? event.data['passengerEmail']) as String?;
          final fare = (event.data['fareAmount'] as num?)?.toDouble();
          final dist = (event.data['distanceKm'] as num?)?.toDouble();
          // null identifier = broadcast drop → navigate all riders
          if (droppedPhone == null) {
            _alreadyDropped = true;
            _navigateToComplete(serverFare: fare, serverDist: dist);
          } else if (_myPhone == null) {
            _pendingDroppedPhone = droppedPhone;
            _pendingDroppedFare = fare;
            _pendingDroppedDist = dist;
          } else if (droppedPhone == _myPhone) {
            _alreadyDropped = true;
            _navigateToComplete(serverFare: fare, serverDist: dist);
          }
          break;
        case 'RIDE_COMPLETED':
          if (_alreadyDropped) break;
          final completedPhone = (event.data['passengerPhone']
              ?? event.data['passengerEmail']) as String?;
          final completedFare = (event.data['fareAmount'] as num?)?.toDouble();
          final completedDist = (event.data['distanceKm'] as num?)?.toDouble();
          if (completedPhone != null && _myPhone != null && completedPhone != _myPhone) break;
          if (completedPhone != null && _myPhone == null) {
            _pendingRideCompleted = true;
            _pendingCompletedFare = completedFare;
            _pendingCompletedDist = completedDist;
            break;
          }
          _navigateToComplete(serverFare: completedFare, serverDist: completedDist);
          break;
      }
    });
  }

  void _updateDriverOnMap(double lat, double lng) {
    if (_mapController == null) return;

    if (_driverLayerReady) {
      // Update existing GeoJSON source with new driver position
      _mapController!.style.setStyleSourceProperty(
        'driver-source',
        'data',
        jsonEncode(_driverGeoJson(lat, lng)),
      );
    } else {
      _addDriverLayers(lat, lng);
    }

    // Fit camera to show driver + rider's destination together
    if (widget.destLat != 0.0) {
      final allLats = [lat, widget.pickupLat, widget.destLat];
      final allLngs = [lng, widget.pickupLng, widget.destLng];
      final minLat = allLats.reduce(min);
      final maxLat = allLats.reduce(max);
      final minLng = allLngs.reduce(min);
      final maxLng = allLngs.reduce(max);
      _mapController!
          .cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(minLng, minLat)),
          northeast: Point(coordinates: Position(maxLng, maxLat)),
          infiniteBounds: false,
        ),
        MbxEdgeInsets(top: 100, left: 60, bottom: 320, right: 60),
        null, null, null, null,
      )
          .then((camera) {
        _mapController?.flyTo(camera, MapAnimationOptions(duration: 600));
      });
    } else {
      _mapController!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  Map<String, dynamic> _driverGeoJson(double lat, double lng) => {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [lng, lat],
            },
            'properties': {},
          }
        ],
      };

  Future<void> _addDriverLayers(double lat, double lng) async {
    if (_mapController == null) return;
    try {
      try { await _mapController!.style.removeStyleLayer('driver-halo-layer'); } catch (_) {}
      try { await _mapController!.style.removeStyleLayer('driver-dot-layer'); } catch (_) {}
      try { await _mapController!.style.removeStyleSource('driver-source'); } catch (_) {}

      await _mapController!.style.addSource(GeoJsonSource(
        id: 'driver-source',
        data: jsonEncode(_driverGeoJson(lat, lng)),
      ));

      // Outer semi-transparent halo
      await _mapController!.style.addLayer(CircleLayer(
        id: 'driver-halo-layer',
        sourceId: 'driver-source',
        circleRadius: 18.0,
        circleColor: const Color(0xFF1DB954).value,
        circleOpacity: 0.25,
        circleStrokeWidth: 0.0,
      ));

      // Inner solid dot
      await _mapController!.style.addLayer(CircleLayer(
        id: 'driver-dot-layer',
        sourceId: 'driver-source',
        circleRadius: 10.0,
        circleColor: const Color(0xFF1DB954).value,
        circleOpacity: 1.0,
        circleStrokeWidth: 2.5,
        circleStrokeColor: Colors.white.value,
      ));

      _driverLayerReady = true;
    } catch (_) {}
  }

  void _onMapCreated(MapboxMap controller) {
    _mapController = controller;
    _mapController?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  void _onStyleLoaded(StyleLoadedEventData _) {
    // Reset layer flags — the style was (re)loaded
    _routeDrawn = false;
    _driverLayerReady = false;

    if (mounted && widget.pickupLat != 0.0 && widget.destLat != 0.0) {
      _drawRoutePolyline();
      _addPickupDestPins();
    }
    // Re-add driver marker if we already had a location before style reload
    if (_driverLat != null && _driverLng != null) {
      _addDriverLayers(_driverLat!, _driverLng!);
    }
  }

  /// Adds static circle pins for the rider's pickup (green) and destination (red).
  Future<void> _addPickupDestPins() async {
    if (_mapController == null) return;
    try {
      try { await _mapController!.style.removeStyleLayer('pickup-pin-layer'); } catch (_) {}
      try { await _mapController!.style.removeStyleLayer('dest-pin-layer'); } catch (_) {}
      try { await _mapController!.style.removeStyleSource('pickup-dest-source'); } catch (_) {}

      await _mapController!.style.addSource(GeoJsonSource(
        id: 'pickup-dest-source',
        data: jsonEncode({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [widget.pickupLng, widget.pickupLat],
              },
              'properties': {'pinType': 'pickup'},
            },
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [widget.destLng, widget.destLat],
              },
              'properties': {'pinType': 'destination'},
            },
          ],
        }),
      ));

      // Green pin — pickup
      await _mapController!.style.addLayer(CircleLayer(
        id: 'pickup-pin-layer',
        sourceId: 'pickup-dest-source',
        circleRadius: 9.0,
        circleColor: const Color(0xFF1DB954).value,
        circleStrokeWidth: 2.5,
        circleStrokeColor: Colors.white.value,
        circleOpacity: 1.0,
        // Filter to only the pickup feature
        filter: ['==', ['get', 'pinType'], 'pickup'],
      ));

      // Red pin — destination
      await _mapController!.style.addLayer(CircleLayer(
        id: 'dest-pin-layer',
        sourceId: 'pickup-dest-source',
        circleRadius: 9.0,
        circleColor: const Color(0xFFE53935).value,
        circleStrokeWidth: 2.5,
        circleStrokeColor: Colors.white.value,
        circleOpacity: 1.0,
        filter: ['==', ['get', 'pinType'], 'destination'],
      ));
    } catch (_) {}
  }

  /// Called on RIDE_STARTED — ensures the route polyline is drawn.
  void _drawRoute() {
    _routeDrawn = false; // force re-draw
    if (_mapController != null && widget.pickupLat != 0.0 && widget.destLat != 0.0) {
      _drawRoutePolyline();
    }
  }

  /// Fetch turn-by-turn geometry from Mapbox Directions and render as a polyline.
  Future<void> _drawRoutePolyline() async {
    if (_routeDrawn) return;
    _routeDrawn = true;
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${widget.pickupLng},${widget.pickupLat};'
        '${widget.destLng},${widget.destLat}'
        '?geometries=geojson&overview=full&access_token=${ApiConfig.mapboxToken}',
      );
      final resp = await http.get(url);
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final coords = (routes[0]['geometry']['coordinates'] as List)
          .map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble()))
          .toList();

      if (_mapController == null || !mounted) return;

      try { await _mapController!.style.removeStyleLayer('route-layer'); } catch (_) {}
      try { await _mapController!.style.removeStyleSource('route-source'); } catch (_) {}

      await _mapController!.style.addSource(GeoJsonSource(
        id: 'route-source',
        data: jsonEncode({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'LineString',
                'coordinates': coords.map((p) => [p.lng, p.lat]).toList(),
              },
              'properties': {},
            }
          ],
        }),
      ));

      await _mapController!.style.addLayer(LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: const Color(0xFF1DB954).value,
        lineWidth: 5.0,
        lineJoin: LineJoin.ROUND,
        lineCap: LineCap.ROUND,
        lineOpacity: 0.85,
      ));

      // Fit camera to show full rider route
      if (coords.isNotEmpty) {
        final lngs = coords.map((p) => p.lng).toList();
        final lats = coords.map((p) => p.lat).toList();
        final minLng = lngs.reduce((a, b) => a < b ? a : b);
        final maxLng = lngs.reduce((a, b) => a > b ? a : b);
        final minLat = lats.reduce((a, b) => a < b ? a : b);
        final maxLat = lats.reduce((a, b) => a > b ? a : b);
        await _mapController!
            .cameraForCoordinateBounds(
          CoordinateBounds(
            southwest: Point(coordinates: Position(minLng, minLat)),
            northeast: Point(coordinates: Position(maxLng, maxLat)),
            infiniteBounds: false,
          ),
          MbxEdgeInsets(top: 80, left: 40, bottom: 280, right: 40),
          null, null, null, null,
        )
            .then((camera) {
          _mapController?.flyTo(camera, MapAnimationOptions(duration: 800));
        });
      }
    } catch (_) {
      _routeDrawn = false; // allow retry
    }
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

  Future<void> _requestDropOff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Drop-off?'),
        content: const Text(
          'This will notify the driver that you want to be dropped off '
          'at the next safe stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, Drop me off',
                style: TextStyle(color: IniatoTheme.green)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isRequestingDropOff = true);
    try {
      final success = await RideService.requestDropOff(widget.ride.rideId);
      if (mounted) {
        if (success) {
          setState(() => _dropOffRequested = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Drop-off requested! Driver has been notified.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to request drop-off')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error requesting drop-off')),
        );
      }
    }
    if (mounted) setState(() => _isRequestingDropOff = false);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    _wsReconnectTimer?.cancel();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _rideStatus == 'PENDING_ACCEPTANCE';
    final isConfirmed = _rideStatus == 'POOL_FORMING_CONFIRMED';
    final isInProgress = _rideStatus == 'STARTED';

    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      body: Stack(
        children: [
          // ─── Map (native only) / Web fallback ───
          if (kIsWeb)
            _buildWebMapFallback()
          else
            MapWidget(
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
            ),

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
                    : isConfirmed
                        ? IniatoTheme.green.withValues(alpha: 0.9)
                        : isPending
                            ? IniatoTheme.yellowDark.withValues(alpha: 0.85)
                            : IniatoTheme.yellowDark,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isInProgress
                        ? Icons.directions_car
                        : isConfirmed
                            ? Icons.check_circle
                            : Icons.hourglass_top,
                    color: (isInProgress || isConfirmed)
                        ? Colors.white
                        : IniatoTheme.greenDark,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isInProgress
                          ? 'Ride in progress'
                          : isConfirmed
                              ? 'Driver confirmed! Waiting to start...'
                              : 'Waiting for driver to accept...',
                      style: TextStyle(
                        color: (isInProgress || isConfirmed)
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
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: (isInProgress || isConfirmed)
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                            color: IniatoTheme.green.withValues(alpha: 0.3),
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
                        backgroundColor:
                            IniatoTheme.green.withValues(alpha: 0.1),
                        child: const Icon(Icons.person,
                            color: IniatoTheme.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ride.driverPhone ?? 'Driver',
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
                      Container(
                        decoration: BoxDecoration(
                          color: IniatoTheme.green.withValues(alpha: 0.1),
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

                  // ─── Boarding OTP (shown until ride starts) ───
                  if (!isInProgress)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: IniatoTheme.yellowDark.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(IniatoTheme.radiusMd),
                        border: Border.all(
                            color:
                                IniatoTheme.yellowDark.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pin,
                              color: IniatoTheme.yellowDark, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Boarding OTP',
                                  style: IniatoTheme.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: IniatoTheme.greenDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Share this with your driver to confirm boarding',
                                  style: IniatoTheme.caption
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _boardingOtp,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: IniatoTheme.greenDark,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ─── Actions ───
                  Row(
                    children: [
                      Expanded(
                        child: isInProgress
                            ? IniatoButton(
                                label: _dropOffRequested
                                    ? 'Drop-off Requested ✓'
                                    : 'Request Drop-off',
                                onPressed: _dropOffRequested
                                    ? null
                                    : () => _requestDropOff(),
                                isLoading: _isRequestingDropOff,
                                icon: Icons.arrow_downward,
                              )
                            : IniatoButton(
                                label: 'Leave Ride',
                                onPressed: _cancelRide,
                                isLoading: _isCancelling,
                                outlined: true,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: IniatoTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.sos, color: IniatoTheme.error),
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

  /// Web fallback: a full-screen green gradient background with a
  /// pulsing driver-location card instead of a map.
  Widget _buildWebMapFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            IniatoTheme.green.withValues(alpha: 0.08),
            IniatoTheme.green.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated driver pin
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.05),
              duration: const Duration(seconds: 1),
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: IniatoTheme.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car,
                    color: IniatoTheme.green, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _driverLat != null
                  ? 'Driver nearby\n${_driverLat!.toStringAsFixed(4)}, ${_driverLng!.toStringAsFixed(4)}'
                  : 'Locating driver...',
              textAlign: TextAlign.center,
              style: IniatoTheme.caption.copyWith(
                fontSize: 13,
                color: IniatoTheme.textSecondary,
              ),
            ),
            if (_driverLat == null) ...[
              const SizedBox(height: 12),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: IniatoTheme.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
