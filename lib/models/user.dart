/// Represents the authenticated user (passenger/rider).
class User {
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? gender;
  final String? preferredPaymentMethod;
  final bool? onlineStatus;

  User({
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.gender,
    this.preferredPaymentMethod,
    this.onlineStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'],
      preferredPaymentMethod: json['preferredPaymentMethod'],
      onlineStatus: json['onlineStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      if (gender != null) 'gender': gender,
      if (preferredPaymentMethod != null)
        'preferredPaymentMethod': preferredPaymentMethod,
    };
  }
}

/// JWT auth response from login/register.
class AuthResponse {
  final String token;
  final String email;
  final List<String> roles;

  AuthResponse({
    required this.token,
    required this.email,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      email: json['email'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}
