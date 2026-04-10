/// Centralized API configuration for the Iniato app.
/// Change rl] to match your backend server address.
class ApiConfig {
  // ─── Change this to your machine's LAN IP when running on a real device ───
  // Emulator: 'http://10.0.2.2:8081'
  // Real device: 'http://192.168.31.119:8081'
  // Windows desktop: 'http://localhost:8081'
  static const String baseUrl = 'http://192.168.33.99:8081';

  // WebSocket
  static const String wsUrl = 'ws://192.168.33.99:8081/ws/driver-location';

  // Mapbox
  static const String mapboxToken =
      'pk.eyJ1IjoiaW10aWZheiIsImEiOiJjbWprN3U3bGUwMTJ1M2twZ2s3bG45MWFpIn0.hNw5ey_P0O2t2VPMw-Ss2A';
  static const String mapboxGeocodingBase =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  // ─── Auth ───
  static const String registerRider = '/api/auth/register/rider'; // + /{phone}
  static const String registerSendOtp = '/api/auth/register/rider/send-otp';
  static const String registerVerifyOtp = '/api/auth/register/rider/verify-otp';
  static const String loginSendOtp = '/api/auth/login/send-otp';
  static const String loginVerifyOtp = '/api/auth/login/verify-otp';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';

  // ─── Passenger Profile ───
  static const String passengerProfile = '/api/passenger/profile';

  // ─── Rides ───
  static const String rideRequest = '/api/rides/request';
  static const String myRides = '/api/rides/my';
  static String leaveRide(int rideId) => '/api/rides/$rideId/leave';

  // ─── Matching ───
  static const String matchingFind = '/api/matching/find';
  static const String matchingRequest = '/api/matching/request';

  // ─── Routes ───
  static const String nearbyRoutes = '/api/routes/nearby';

  // ─── Fare ───
  static const String fareEstimate = '/api/fare/estimate';

  // ─── Payments ───
  static const String paymentSplit = '/api/payments/split';
}
