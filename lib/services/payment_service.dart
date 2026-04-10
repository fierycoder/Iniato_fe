import 'dart:convert';
import '../config/api_config.dart';
import '../models/payment.dart';
import 'api_service.dart';

/// Handles payment operations.
class PaymentService {
  /// Process split fare payment.
  static Future<PaymentResponse?> splitPayment(PaymentRequest request) async {
    final response = await ApiService.post(
      ApiConfig.paymentSplit,
      body: request.toJson(),
    );
    if (response.statusCode == 200) {
      return PaymentResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
