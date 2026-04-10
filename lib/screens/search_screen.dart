import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import 'route_match_screen.dart';

/// Destination search with Mapbox Geocoding autocomplete.
class SearchScreen extends StatefulWidget {
  final double? currentLat;
  final double? currentLng;

  const SearchScreen({super.key, this.currentLat, this.currentLng});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _pickupController = TextEditingController();
  final _destController = TextEditingController();
  bool _isSearching = false;
  List<_GeoResult> _searchResults = [];
  List<String> _recentSearches = [];
  bool _editingPickup = false; // true = editing pickup, false = editing dest

  // Selected locations
  double? _pickupLat, _pickupLng;
  double? _destLat, _destLng;
  String _pickupName = 'Current Location';
  String _destName = '';

  @override
  void initState() {
    super.initState();
    _pickupLat = widget.currentLat;
    _pickupLng = widget.currentLng;
    _pickupController.text = 'Current Location';
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String place) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(place);
    _recentSearches.insert(0, place);
    if (_recentSearches.length > 8) {
      _recentSearches = _recentSearches.sublist(0, 8);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);

    try {
      final proximity = (widget.currentLng != null && widget.currentLat != null)
          ? '&proximity=${widget.currentLng},${widget.currentLat}'
          : '';
      final url =
          '${ApiConfig.mapboxGeocodingBase}/$query.json?access_token=${ApiConfig.mapboxToken}&country=in&limit=5$proximity';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;
        setState(() {
          _searchResults = features.map((f) {
            final coords = f['geometry']['coordinates'];
            return _GeoResult(
              name: f['text'] ?? '',
              fullAddress: f['place_name'] ?? '',
              lat: coords[1].toDouble(),
              lng: coords[0].toDouble(),
            );
          }).toList();
        });
      }
    } catch (_) {}
    setState(() => _isSearching = false);
  }

  void _selectResult(_GeoResult result) {
    if (_editingPickup) {
      setState(() {
        _pickupLat = result.lat;
        _pickupLng = result.lng;
        _pickupName = result.name;
        _pickupController.text = result.name;
      });
    } else {
      setState(() {
        _destLat = result.lat;
        _destLng = result.lng;
        _destName = result.name;
        _destController.text = result.name;
      });
      _saveRecentSearch(result.name);
    }
    setState(() => _searchResults = []);
    FocusScope.of(context).unfocus();

    // If both are selected, navigate
    if (_pickupLat != null && _destLat != null && _destName.isNotEmpty) {
      _navigateToMatching();
    }
  }

  void _navigateToMatching() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteMatchScreen(
          pickupLat: _pickupLat!,
          pickupLng: _pickupLng!,
          destLat: _destLat!,
          destLng: _destLng!,
          pickupName: _pickupName,
          destName: _destName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Search Header ───
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back button row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Expanded(
                        child: Text(
                          'Set your route',
                          style: IniatoTheme.subheading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pickup & Destination fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Route dots
                        Column(
                          children: [
                            Icon(Icons.circle,
                                size: 10, color: IniatoTheme.green),
                            Container(
                              width: 2,
                              height: 30,
                              color: IniatoTheme.green.withOpacity(0.3),
                            ),
                            Icon(Icons.location_on,
                                size: 16, color: IniatoTheme.error),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              // Pickup
                              TextField(
                                controller: _pickupController,
                                onTap: () =>
                                    setState(() => _editingPickup = true),
                                onChanged: (v) {
                                  _editingPickup = true;
                                  _searchPlaces(v);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Pickup location',
                                  hintStyle: IniatoTheme.caption,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: IniatoTheme.body.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              // Destination
                              TextField(
                                controller: _destController,
                                autofocus: true,
                                onTap: () =>
                                    setState(() => _editingPickup = false),
                                onChanged: (v) {
                                  _editingPickup = false;
                                  _searchPlaces(v);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Where are you going?',
                                  hintStyle: IniatoTheme.caption,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: IniatoTheme.body.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Results / Recent ───
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isNotEmpty
                      ? _buildSearchResults()
                      : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final r = _searchResults[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: IniatoTheme.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined,
                color: IniatoTheme.green, size: 20),
          ),
          title: Text(r.name,
              style: IniatoTheme.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(r.fullAddress,
              style: IniatoTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => _selectResult(r),
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Search for your destination',
              style: IniatoTheme.caption.copyWith(fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recent', style: IniatoTheme.caption.copyWith(
          fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        ..._recentSearches.map((s) => ListTile(
              leading: Icon(Icons.history, color: IniatoTheme.textSecondary),
              title: Text(s, style: IniatoTheme.body),
              dense: true,
              onTap: () {
                _destController.text = s;
                _searchPlaces(s);
              },
            )),
      ],
    );
  }
}

class _GeoResult {
  final String name;
  final String fullAddress;
  final double lat;
  final double lng;

  _GeoResult({
    required this.name,
    required this.fullAddress,
    required this.lat,
    required this.lng,
  });
}
