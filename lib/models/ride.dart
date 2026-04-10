/// Maps to RideResponseDTO from the backend.
class Ride {
  final int rideId;
  final String? passengerEmail;
  final String? driverEmail;
  final String pickupLocation;
  final String destination;
  final DateTime? requestedTime;
  final String status; // POOL_FORMING, IN_PROGRESS, COMPLETED, CANCELLED
  final List<String> passengers;

  Ride({
    required this.rideId,
    this.passengerEmail,
    this.driverEmail,
    required this.pickupLocation,
    required this.destination,
    this.requestedTime,
    required this.status,
    this.passengers = const [],
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      rideId: json['rideId'] ?? 0,
      passengerEmail: json['passengerEmail'],
      driverEmail: json['driverEmail'],
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      requestedTime: json['requestedTime'] != null
          ? DateTime.tryParse(json['requestedTime'])
          : null,
      status: json['status'] ?? 'POOL_FORMING',
      passengers: List<String>.from(json['passengers'] ?? []),
    );
  }

  /// Human-readable status label.
  String get statusLabel {
    switch (status) {
      case 'POOL_FORMING':
        return 'Finding riders';
      case 'IN_PROGRESS':
        return 'In progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isActive =>
      status == 'POOL_FORMING' || status == 'IN_PROGRESS';
}

/// Ride request DTO sent to the backend.
class RideRequestDTO {
  final int? rideId;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final String? pickupTime;
  final String pickupLocation;
  final String destination;

  RideRequestDTO({
    this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    this.pickupTime,
    required this.pickupLocation,
    required this.destination,
  });

  Map<String, dynamic> toJson() {
    return {
      if (rideId != null) 'rideId': rideId,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destLat': destLat,
      'destLng': destLng,
      'pickupTime':
          pickupTime ?? DateTime.now().toIso8601String(),
      'pickupLocation': pickupLocation,
      'destination': destination,
    };
  }
}
