/// Response from POST /api/matching/find
class RideMatchResponse {
  final List<MatchingRide> matchingRides;
  final List<NearbyDriver> nearbyDrivers;

  RideMatchResponse({
    required this.matchingRides,
    required this.nearbyDrivers,
  });

  factory RideMatchResponse.fromJson(Map<String, dynamic> json) {
    return RideMatchResponse(
      matchingRides: (json['matchingRides'] as List? ?? [])
          .map((r) => MatchingRide.fromJson(r))
          .toList(),
      nearbyDrivers: (json['nearbyDrivers'] as List? ?? [])
          .map((d) => NearbyDriver.fromJson(d))
          .toList(),
    );
  }
}

class MatchingRide {
  final int rideId;
  final String pickupLocation;
  final String destination;
  final String status;
  final String? requestedTime;
  final String? driverName;
  final List<String> passengerNames;

  MatchingRide({
    required this.rideId,
    required this.pickupLocation,
    required this.destination,
    required this.status,
    this.requestedTime,
    this.driverName,
    this.passengerNames = const [],
  });

  factory MatchingRide.fromJson(Map<String, dynamic> json) {
    return MatchingRide(
      rideId: json['rideId'] ?? 0,
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      status: json['status'] ?? '',
      requestedTime: json['requestedTime'],
      driverName: json['driverName'],
      passengerNames: List<String>.from(json['passengerNames'] ?? []),
    );
  }

  int get coRiderCount => passengerNames.length;
}

class NearbyDriver {
  final int driverId;
  final double latitude;
  final double longitude;
  final double distanceMeters;

  NearbyDriver({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      driverId: json['driverId'] ?? 0,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      distanceMeters: (json['distanceMeters'] ?? 0).toDouble(),
    );
  }

  /// Distance in km, rounded to 1 decimal.
  String get distanceKm => (distanceMeters / 1000).toStringAsFixed(1);
}
