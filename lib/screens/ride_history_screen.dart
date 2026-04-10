import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/ride_service.dart';
import '../models/ride.dart';
import '../widgets/ride_card.dart';
import '../widgets/empty_state.dart';

/// Displays all rides the authenticated passenger is part of.
class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;
  String _filter = 'ALL'; // ALL, ACTIVE, COMPLETED

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() => _isLoading = true);
    try {
      final rides = await RideService.getMyRides();
      if (mounted) {
        setState(() {
          _rides = rides;
          _rides.sort((a, b) {
            final aTime = a.requestedTime ?? DateTime(2000);
            final bTime = b.requestedTime ?? DateTime(2000);
            return bTime.compareTo(aTime); // newest first
          });
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Ride> get _filteredRides {
    if (_filter == 'ACTIVE') {
      return _rides.where((r) => r.isActive).toList();
    } else if (_filter == 'COMPLETED') {
      return _rides
          .where((r) => r.status == 'COMPLETED' || r.status == 'CANCELLED')
          .toList();
    }
    return _rides;
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: IniatoTheme.green,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: ['ALL', 'ACTIVE', 'COMPLETED'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      f[0] + f.substring(1).toLowerCase(),
                      style: TextStyle(
                        color: selected ? IniatoTheme.green : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    checkmarkColor: IniatoTheme.green,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                          itemBuilder: (context, index) {
                            return RideCard(
                              ride: _filteredRides[index],
                              onTap: () {
                                // Could open ride detail view
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
