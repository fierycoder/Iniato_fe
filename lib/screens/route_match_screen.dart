import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/ride_service.dart';
import '../services/websocket_service.dart';
import '../models/ride_match.dart';
import '../models/fare_estimate.dart';
import '../widgets/empty_state.dart';
import '../widgets/iniato_button.dart';
import 'ride_details_screen.dart';

/// Shows matching rides and nearby drivers for the selected route.
/// New rides slide in automatically via WebSocket — no manual refresh needed.
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
  // Mutable lists — AnimatedList reads from these
  final List<MatchingRide> _rides = [];
  final List<NearbyDriver> _drivers = [];
  FareEstimate? _fareEstimate;
  String? _error;

  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Tracks available seats per rideId so we can update the card label live.
  final Map<int, int> _seatsMap = {};

  // Real-time WebSocket
  final WebSocketService _ws = WebSocketService();
  StreamSubscription<NewRouteEvent>? _newRouteSub;
  StreamSubscription<RouteUpdateEvent>? _routeUpdateSub;

  @override
  void initState() {
    super.initState();
    _findMatches();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _newRouteSub?.cancel();
    _routeUpdateSub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  // ── WebSocket ────────────────────────────────────────────────────────────

  void _connectWebSocket() {
    _ws.connect(
      onConnected: () {
        _ws.subscribeToRouteAvailability();
        _ws.subscribeToRouteUpdates();
        _newRouteSub = _ws.newRouteUpdates.listen(_onNewRoute);
        _routeUpdateSub = _ws.routeUpdateEvents.listen(_onRouteUpdate);
      },
    );
  }

  void _onNewRoute(NewRouteEvent event) {
    if (!mounted) return;
    if (!_isDirectionMatch(event)) return;
    final rideId = event.rideId;
    if (rideId == null) return;
    if (_rides.any((r) => r.rideId == rideId)) return;

    final newRide = MatchingRide(
      rideId: rideId,
      pickupLocation: event.originAddress ?? 'Origin',
      destination: event.destinationAddress ?? 'Destination',
      status: 'POOL_FORMING',
      driverName: event.driverPhone ?? 'Driver',
      passengerNames: const [],
    );

    if (event.availableSeats != null) {
      _seatsMap[rideId] = event.availableSeats!;
    }

    final wasEmpty = _rides.isEmpty && _drivers.isEmpty;
    if (wasEmpty) {
      setState(() => _rides.insert(0, newRide));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _listKey.currentState?.insertItem(0,
            duration: const Duration(milliseconds: 450));
      });
    } else {
      _rides.insert(0, newRide);
      _listKey.currentState?.insertItem(0,
          duration: const Duration(milliseconds: 450));
    }
  }

  /// Handles seat-count updates (ROUTE_UPDATED) and cancellations (ROUTE_CANCELLED).
  void _onRouteUpdate(RouteUpdateEvent event) {
    if (!mounted) return;

    if (event.type == 'ROUTE_CANCELLED') {
      _removeRideCard(rideId: event.rideId, routeId: event.routeId);
      return;
    }

    // ROUTE_UPDATED — refresh seat count, remove card if no seats left
    if (event.rideId == null) return;
    final seats = event.availableSeats ?? 0;
    setState(() => _seatsMap[event.rideId!] = seats);

    if (seats <= 0) {
      _removeRideCard(rideId: event.rideId);
    }
  }

  /// Slides a ride card out of the list with a reverse animation, then removes it.
  void _removeRideCard({int? rideId, int? routeId}) {
    final idx = _rides.indexWhere((r) => rideId != null && r.rideId == rideId);
    if (idx < 0) return;

    final removed = _rides[idx];
    _rides.removeAt(idx);
    _seatsMap.remove(rideId);

    // Offset by 1 for the "Matching Rides" header item at index 0
    final listIdx = idx + 1;
    _listKey.currentState?.removeItem(
      listIdx,
      (context, animation) => _animatedRideCard(removed, animation),
      duration: const Duration(milliseconds: 350),
    );

    // If all rides gone, rebuild to show EmptyState (or just drivers)
    if (_rides.isEmpty) {
      Future.delayed(const Duration(milliseconds: 360), () {
        if (mounted) setState(() {});
      });
    }
  }

  /// Cosine-similarity direction check (≤ 60°) — mirrors backend logic.
  bool _isDirectionMatch(NewRouteEvent event) {
    final oLat = event.originLat;
    final oLng = event.originLng;
    final dLat = event.destinationLat;
    final dLng = event.destinationLng;
    if (oLat == null || oLng == null || dLat == null || dLng == null) return true;

    final cosLat = cos((oLat + dLat) / 2 * pi / 180);
    final rVecLat = dLat - oLat;
    final rVecLng = (dLng - oLng) * cosLat;
    final pVecLat = widget.destLat - widget.pickupLat;
    final pVecLng = (widget.destLng - widget.pickupLng) * cosLat;

    final rMag = sqrt(rVecLat * rVecLat + rVecLng * rVecLng);
    final pMag = sqrt(pVecLat * pVecLat + pVecLng * pVecLng);
    if (rMag < 1e-9 || pMag < 1e-9) return false;

    final cosAngle =
        ((rVecLat * pVecLat + rVecLng * pVecLng) / (rMag * pMag)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi <= 60.0;
  }

  // ── Data loading ─────────────────────────────────────────────────────────

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
        final matchResponse = results[0] as RideMatchResponse?;
        setState(() {
          _rides
            ..clear()
            ..addAll(matchResponse?.matchingRides ?? []);
          _drivers
            ..clear()
            ..addAll(matchResponse?.nearbyDrivers ?? []);
          _fareEstimate = results[1] as FareEstimate?;
          _seatsMap.clear();
          for (final r in _rides) {
            if (r.availableSeats != null) _seatsMap[r.rideId] = r.availableSeats!;
          }
          _listKey = GlobalKey<AnimatedListState>(); // reset AnimatedList
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Error finding rides');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: IniatoTheme.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _findMatches,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRouteHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: const BoxDecoration(
        color: IniatoTheme.green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.white70),
              Container(width: 2, height: 24, color: Colors.white38),
              const Icon(Icons.location_on, size: 14, color: IniatoTheme.yellow),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pickupName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Text(widget.destName,
                    style: const TextStyle(
                        color: IniatoTheme.yellow, fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (_fareEstimate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('₹${_fareEstimate!.perPassengerFare.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('${_fareEstimate!.distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: _error!,
        action: IniatoButton(label: 'Retry', onPressed: _findMatches, outlined: true),
      );
    }
    if (_rides.isEmpty && _drivers.isEmpty) {
      return EmptyState(
        icon: Icons.no_transfer,
        title: 'No rides available',
        subtitle: 'No autos on this route yet.\nWe\'ll slide one in the moment a driver goes live!',
        action: IniatoButton(label: 'Refresh', onPressed: _findMatches, outlined: true),
      );
    }
    return _buildAnimatedList();
  }

  /// Builds a unified AnimatedList of section headers + ride cards + driver cards.
  /// We flatten everything into a single indexed list so AnimatedList can manage it.
  Widget _buildAnimatedList() {
    // Section structure:
    //  index 0             → "Matching Rides" header  (only if _rides non-empty)
    //  index 1…N           → ride cards
    //  index N+1           → "Nearby Drivers" header  (only if _drivers non-empty)
    //  index N+2…          → driver cards
    // We build the AnimatedList over _rides only (drivers are static after load).
    // For simplicity, we embed drivers in a footer inside the AnimatedList.

    return AnimatedList(
      key: _listKey,
      padding: const EdgeInsets.all(16),
      initialItemCount: _itemCount,
      itemBuilder: (context, index, animation) => _buildItem(index, animation),
    );
  }

  int get _itemCount {
    int count = 0;
    if (_rides.isNotEmpty) count += 1 + _rides.length; // header + cards
    if (_drivers.isNotEmpty) count += 1 + _drivers.length; // header + cards
    return count;
  }

  Widget _buildItem(int index, Animation<double> animation) {
    // Determine what this index maps to
    int cursor = 0;

    if (_rides.isNotEmpty) {
      if (index == cursor) {
        return _sectionHeader('Matching Rides', animation);
      }
      cursor++;
      if (index < cursor + _rides.length) {
        final ride = _rides[index - cursor];
        return _animatedRideCard(ride, animation);
      }
      cursor += _rides.length;
    }

    if (_drivers.isNotEmpty) {
      if (index == cursor) {
        return _sectionHeader('Nearby Drivers', animation);
      }
      cursor++;
      if (index < cursor + _drivers.length) {
        return _buildDriverCard(_drivers[index - cursor]);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _sectionHeader(String title, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(title, style: IniatoTheme.subheading.copyWith(fontSize: 16)),
      ),
    );
  }

  /// Slide-in + fade animation for a ride card.
  Widget _animatedRideCard(MatchingRide ride, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
        child: _buildRideCard(ride),
      ),
    );
  }

  Widget _buildRideCard(MatchingRide ride) {
    final seats = _seatsMap[ride.rideId] ?? ride.availableSeats;
    final isFull = seats != null && seats <= 0;

    return GestureDetector(
      onTap: isFull
          ? null // don't allow tapping a full ride
          : () => Navigator.push(
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
              ),
      child: Opacity(
        opacity: isFull ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: IniatoTheme.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_taxi, color: IniatoTheme.green, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.driverName ?? 'Driver',
                        style: IniatoTheme.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${ride.pickupLocation} → ${ride.destination}',
                        style: IniatoTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: IniatoTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${ride.coRiderCount} co-riders',
                            style: IniatoTheme.caption.copyWith(fontSize: 12)),
                        if (seats != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : IniatoTheme.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFull ? 'Full' : '$seats seat${seats == 1 ? '' : 's'} left',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isFull ? Colors.red : IniatoTheme.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_fareEstimate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fareEstimate!.perPassengerFare.toStringAsFixed(0)}',
                      style: IniatoTheme.subheading
                          .copyWith(color: IniatoTheme.green, fontSize: 18),
                    ),
                    Text('your share',
                        style: IniatoTheme.caption.copyWith(fontSize: 11)),
                  ],
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: isFull
                      ? Colors.grey.shade300
                      : IniatoTheme.textSecondary),
            ],
          ),
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
              color: IniatoTheme.yellow.withValues(alpha: 0.2),
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
                Text('${driver.distanceKm} km away', style: IniatoTheme.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: IniatoTheme.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
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
















