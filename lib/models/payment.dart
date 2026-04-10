/// Maps to PaymentResponseDTO.
class PaymentResponse {
  final String status; // SUCCESS, FAILED
  final String message;
  final double amount;

  PaymentResponse({
    required this.status,
    required this.message,
    required this.amount,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  bool get isSuccess => status == 'SUCCESS';
}

/// Payment request DTO.
class PaymentRequest {
  final int rideId;
  final int passengerId;
  final double amount;
  final String paymentMethod; // WALLET, CASH, UPI

  PaymentRequest({
    required this.rideId,
    required this.passengerId,
    required this.amount,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'rideId': rideId,
        'passengerId': passengerId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      };
}
