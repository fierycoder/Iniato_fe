import 'dart:convert';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Handles authentication: OTP, login, register, logout, token management.
class AuthService {
  // ─── OTP ───

  /// Send OTP for login or registration.
  static Future<bool> sendOtp(String phone, {required bool isLogin}) async {
    final path = isLogin ? ApiConfig.loginSendOtp : ApiConfig.registerSendOtp;
    final response = await ApiService.post(
      path,
      body: {'phoneNumber': phone},
      auth: false,
    );
    return response.statusCode == 200;
  }

  /// Verify OTP. Returns AuthResponse on success, null on failure.
  static Future<AuthResponse?> verifyOtp(
    String phone,
    String otp, {
    required bool isLogin,
  }) async {
    final path =
        isLogin ? ApiConfig.loginVerifyOtp : ApiConfig.registerVerifyOtp;
    final response = await ApiService.post(
      path,
      body: {'phoneNumber': phone, 'otp': otp},
      auth: false,
    );
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('token')) {
          final authResponse = AuthResponse.fromJson(data);
          await ApiService.saveToken(authResponse.token);
          // Save refresh token for silent renewal
          if (authResponse.refreshToken != null &&
              authResponse.refreshToken!.isNotEmpty) {
            await ApiService.saveRefreshToken(authResponse.refreshToken!);
          }
          // Phone is the primary key — save it directly (already known from the call)
          await ApiService.savePhone(phone);
          return authResponse;
        }
      } catch (_) {
        // OTP verified but no token in response (registration flow)
      }
    }
    return null;
  }

  // ─── Registration ───

  /// Register a new rider. Returns true on success.
  static Future<bool> registerRider({
    required String phone,
    required String fullName,
    required String email,
    required String password,
    String gender = 'MALE',
    String preferredPaymentMethod = 'CASH',
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.registerRider}/$phone',
      body: {
        'email': email,
        'password': password,
        'roles': ['PASSENGER'],
        'name': fullName,
        'gender': gender,
        'preferredPaymentMethod': preferredPaymentMethod,
        'phoneNumber': phone,
      },
      auth: false,
    );
    return response.statusCode == 200;
  }

  // ─── Email Login (legacy — not used in OTP-only flow) ───

  static Future<AuthResponse?> loginWithEmail(
      String email, String password) async {
    final response = await ApiService.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
      auth: false,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await ApiService.saveToken(authResponse.token);
      return authResponse;
    }
    return null;
  }

  // ─── Logout ───

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logout);
    } catch (_) {}
    await ApiService.clearToken();
  }

  // ─── Token Check ───

  static Future<bool> isLoggedIn() => ApiService.isLoggedIn();

  // ─── Profile ───

  static Future<User?> getProfile() async {
    final response = await ApiService.get(ApiConfig.passengerProfile);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<User?> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final response = await ApiService.put(
      ApiConfig.passengerProfile,
      body: {'fullName': fullName, 'phoneNumber': phoneNumber},
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
