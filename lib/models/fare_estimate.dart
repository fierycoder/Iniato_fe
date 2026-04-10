/// Maps to FareEstimateResponseDTO.
class FareEstimate {
  final double distanceKm;
  final double totalFare;
  final double perPassengerFare;

  FareEstimate({
    required this.distanceKm,
    required this.totalFare,
    required this.perPassengerFare,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      totalFare: (json['totalFare'] ?? 0).toDouble(),
      perPassengerFare: (json['perPassengerFare'] ?? 0).toDouble(),
    );
  }
}
