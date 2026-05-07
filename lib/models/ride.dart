/// Maps to RideResponseDTO from the backend.
class Ride {
  final int rideId;
  final String? passengerPhone;
  final String? driverPhone;
  final String pickupLocation;   // full route origin (A→C)
  final String destination;       // full route destination (A→C)
  /// Rider's own boarding point — populated when the backend returns a
  /// passenger-specific field (passengerPickup / boardingLocation).
  /// Falls back to [pickupLocation] when absent.
  final String passengerPickup;
  /// Rider's own alighting point — populated from passengerDestination /
  /// alightingLocation. Falls back to [destination] when absent.
  final String passengerDest;
  final DateTime? requestedTime;
  final String status;
  final String? passengerStatus;
  final double? fareShare;
  final List<String> passengers;

  Ride({
    required this.rideId,
    this.passengerPhone,
    this.driverPhone,
    required this.pickupLocation,
    required this.destination,
    String? passengerPickup,
    String? passengerDest,
    this.requestedTime,
    required this.status,
    this.passengerStatus,
    this.fareShare,
    this.passengers = const [],
  })  : passengerPickup = passengerPickup?.isNotEmpty == true
            ? passengerPickup!
            : pickupLocation,
        passengerDest = passengerDest?.isNotEmpty == true
            ? passengerDest!
            : destination;

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      rideId: json['rideId'] ?? 0,
      passengerPhone: json['passengerPhone'] ?? json['passengerEmail'],
      driverPhone: json['driverPhone'] ?? json['driverEmail'],
      pickupLocation: json['pickupLocation'] ?? '',
      destination: json['destination'] ?? '',
      // Try several naming conventions for the rider's own boarding/alighting.
      passengerPickup: (json['passengerPickup']
              ?? json['passengerPickupLocation']
              ?? json['boardingLocation']
              ?? json['riderPickup']
              ?? '') as String,
      passengerDest: (json['passengerDestination']
              ?? json['passengerDest']
              ?? json['alightingLocation']
              ?? json['riderDestination']
              ?? '') as String,
      requestedTime: json['requestedTime'] != null
          ? DateTime.tryParse(json['requestedTime'])
          : null,
      status: json['status'] ?? 'POOL_FORMING',
      passengerStatus: json['passengerStatus'] as String?,
      fareShare: (json['fareShare'] as num?)?.toDouble(),
      passengers: List<String>.from(json['passengers'] ?? []),
    );
  }

  /// Human-readable ride status label.
  String get statusLabel {
    switch (status) {
      case 'POOL_FORMING': return 'Waiting for driver';
      case 'STARTED':      return 'In progress';
      case 'COMPLETED':    return 'Completed';
      case 'CANCELLED':    return 'Cancelled';
      default:             return status;
    }
  }

  /// Human-readable label for the passenger's own status on this ride.
  String get passengerStatusLabel {
    switch (passengerStatus) {
      case 'PENDING':   return 'Awaiting acceptance';
      case 'CONFIRMED': return 'Confirmed';
      case 'DROPPED':   return 'Dropped off';
      case 'COMPLETED': return 'Completed';
      case 'LEFT':      return 'Left';
      default:          return passengerStatus ?? statusLabel;
    }
  }

  bool get isActive =>
      (status == 'POOL_FORMING' || status == 'STARTED') &&
      passengerStatus != 'DROPPED' &&
      passengerStatus != 'DROPPED_OFF' &&
      passengerStatus != 'LEFT' &&
      passengerStatus != 'COMPLETED';

  bool get isCancellable =>
      status != 'COMPLETED' && status != 'CANCELLED' &&
      passengerStatus != 'LEFT' && passengerStatus != 'DROPPED' &&
      passengerStatus != 'COMPLETED';
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
