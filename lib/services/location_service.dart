import 'dart:async';
import 'package:geolocator/geolocator.dart' as gl;

/// Extracted geolocation logic for reuse across screens.
class LocationService {
  StreamSubscription<gl.Position>? _positionStream;
  gl.Position? lastPosition;

  /// Check and request location permissions. Returns true if granted.
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) return false;
    }
    if (permission == gl.LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current position once.
  Future<gl.Position?> getCurrentPosition() async {
    if (!await ensurePermission()) return null;
    final position = await gl.Geolocator.getCurrentPosition(
      locationSettings: const gl.LocationSettings(
        accuracy: gl.LocationAccuracy.high,
      ),
    );
    lastPosition = position;
    return position;
  }

  /// Start listening to position updates.
  void startTracking({
    required void Function(gl.Position position) onPosition,
    int distanceFilter = 50,
  }) {
    _positionStream?.cancel();
    _positionStream = gl.Geolocator.getPositionStream(
      locationSettings: gl.LocationSettings(
        accuracy: gl.LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen((position) {
      lastPosition = position;
      onPosition(position);
    });
  }

  /// Stop tracking.
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void dispose() => stopTracking();
}
