import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/ride_service.dart';
import '../models/ride.dart';
import '../widgets/empty_state.dart';

/// Displays all rides the authenticated passenger has ever been part of.
class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() => _isLoading = true);
    try {
      final rides = await RideService.getMyRides();
      if (mounted) setState(() => _rides = rides);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Ride> get _filteredRides {
    switch (_filter) {
      case 'ACTIVE':
        return _rides.where((r) => r.isActive).toList();
      case 'COMPLETED':
        return _rides
            .where((r) => r.status == 'COMPLETED' || r.status == 'CANCELLED')
            .toList();
      default:
        return _rides;
    }
  }

  Future<void> _cancelRide(Ride ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?'),
        content: Text(
          ride.status == 'POOL_FORMING'
              ? 'This will remove you from the ride. Are you sure?'
              : 'This ride is stuck in "${ride.statusLabel}". Cancel your participation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await RideService.cancelRide(ride.rideId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Ride cancelled' : 'Could not cancel — try again'),
        backgroundColor: ok ? IniatoTheme.green : Colors.red,
      ),
    );
    if (ok) _loadRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      appBar: AppBar(
        title: const Text('My Rides'),
        automaticallyImplyLeading: false,
        backgroundColor: IniatoTheme.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Filter Chips ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            color: IniatoTheme.green,
            child: Row(
              children: ['ALL', 'ACTIVE', 'COMPLETED'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f[0] + f.substring(1).toLowerCase(),
                        style: TextStyle(
                          color: selected ? IniatoTheme.green : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Rides List ───
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRides.isEmpty
                    ? EmptyState(
                        icon: Icons.directions_car_outlined,
                        title: _filter == 'ALL'
                            ? 'No rides yet'
                            : 'No ${_filter.toLowerCase()} rides',
                        subtitle: _filter == 'ALL'
                            ? 'Your ride history will appear here'
                            : 'No rides match this filter',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRides,
                        color: IniatoTheme.green,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRides.length,
                          itemBuilder: (_, i) =>
                              _buildRideCard(_filteredRides[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final statusColor = _statusColor(ride.status);
    final canCancel = ride.isCancellable;

    // Use rider's own boarding/alighting point (falls back to route origin/dest
    // when the backend doesn't return a passenger-specific field).
    final pickup = ride.passengerPickup.isNotEmpty
        ? ride.passengerPickup
        : 'Pickup location';
    final dest = ride.passengerDest.isNotEmpty
        ? ride.passengerDest
        : 'Destination';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status + date ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ride.passengerStatusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (ride.requestedTime != null)
                      Text(
                        DateFormat('dd MMM, hh:mm a')
                            .format(ride.requestedTime!),
                        style: const TextStyle(
                            fontSize: 11,
                            color: IniatoTheme.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Route line ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        children: [
                          const Icon(Icons.circle,
                              size: 10, color: IniatoTheme.green),
                          Container(
                              width: 2,
                              height: 22,
                              color: IniatoTheme.green
                                  .withValues(alpha: 0.3)),
                          const Icon(Icons.location_on,
                              size: 14, color: IniatoTheme.error),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pickup,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: IniatoTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 14),
                          Text(dest,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: IniatoTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // ── Fare chip ──
                    if (ride.fareShare != null && ride.fareShare! > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: IniatoTheme.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '₹${ride.fareShare!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: IniatoTheme.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Text('your share',
                                style: TextStyle(
                                    color: IniatoTheme.green,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Cancel button ──
          if (canCancel) ...[
            Container(height: 1, color: Colors.grey.shade100),
            InkWell(
              onTap: () => _cancelRide(ride),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(IniatoTheme.radiusMd)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      ride.status == 'POOL_FORMING'
                          ? 'Leave Ride'
                          : 'Cancel Participation',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED': return IniatoTheme.green;
      case 'STARTED':   return Colors.blue;
      case 'CANCELLED': return IniatoTheme.textSecondary;
      default:          return const Color(0xFFF57F17); // amber for POOL_FORMING
    }
  }
}
