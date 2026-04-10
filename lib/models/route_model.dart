/// Maps to RouteResponseDTO from the backend.
class RouteModel {
  final int routeId;
  final int? rideId;
  final String? driverPhone;
  final String status; // ACTIVE, COMPLETED
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final int totalSeats;
  final int availableSeats;

  RouteModel({
    required this.routeId,
    this.rideId,
    this.driverPhone,
    required this.status,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.totalSeats,
    required this.availableSeats,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId: json['routeId'] ?? 0,
      rideId: json['rideId'],
      driverPhone: json['driverPhone'],
      status: json['status'] ?? '',
      originLat: (json['originLat'] ?? 0).toDouble(),
      originLng: (json['originLng'] ?? 0).toDouble(),
      destinationLat: (json['destinationLat'] ?? 0).toDouble(),
      destinationLng: (json['destinationLng'] ?? 0).toDouble(),
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
    );
  }

  bool get hasSeats => availableSeats > 0;
  int get occupiedSeats => totalSeats - availableSeats;
}
