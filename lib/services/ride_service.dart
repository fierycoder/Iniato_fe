import 'dart:convert';
import '../config/api_config.dart';
import '../models/ride.dart';
import '../models/ride_match.dart';
import '../models/route_model.dart';
import '../models/fare_estimate.dart';
import 'api_service.dart';

/// Handles ride booking, matching, routes, and fare estimation.
class RideService {
  // ─── Matching ───

  /// Find matching rides and nearby drivers for given pickup/destination.
  static Future<RideMatchResponse?> findMatches({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    required String pickupLocation,
    required String destination,
  }) async {
    final response = await ApiService.post(
      ApiConfig.matchingFind,
      body: {
        'rideId': null,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destLat': destLat,
        'destLng': destLng,
        'pickupTime': DateTime.now().toIso8601String(),
        'pickupLocation': pickupLocation,
        'destination': destination,
      },
    );
    if (response.statusCode == 200) {
      return RideMatchResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // ─── Ride Request ───

  /// Request to join a shared ride.
  static Future<Ride?> requestRide(RideRequestDTO request) async {
    final response = await ApiService.post(
      ApiConfig.rideRequest,
      body: request.toJson(),
    );
    if (response.statusCode == 200) {
      return Ride.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  /// Get all rides the authenticated passenger is part of.
  static Future<List<Ride>> getMyRides() async {
    final response = await ApiService.get(ApiConfig.myRides);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((r) => Ride.fromJson(r)).toList();
    }
    return [];
  }

  /// Leave a shared ride.
  static Future<Ride?> leaveRide(int rideId) async {
    final response = await ApiService.post(ApiConfig.leaveRide(rideId));
    if (response.statusCode == 200) {
      return Ride.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  /// Cancel participation in any non-completed ride (handles stuck POOL_FORMING / STARTED).
  static Future<bool> cancelRide(int rideId) async {
    final response = await ApiService.post(ApiConfig.cancelRide(rideId));
    return response.statusCode == 200;
  }

  /// Request to be dropped off at the next stop (while ride is STARTED).
  static Future<bool> requestDropOff(int rideId) async {
    final response = await ApiService.post(ApiConfig.requestDropOff(rideId));
    return response.statusCode == 200;
  }

  /// Submit a 1–5 star rating for the driver after a completed ride.
  static Future<bool> rateDriver(int rideId, int rating) async {
    final response = await ApiService.post(
      ApiConfig.rateDriver(rideId),
      body: {'rating': rating},
    );
    return response.statusCode == 200;
  }

  // ─── Routes ───

  /// Find active routes near a location.
  static Future<List<RouteModel>> getNearbyRoutes(
      double lat, double lng) async {
    final response = await ApiService.get(
      '${ApiConfig.nearbyRoutes}?lat=$lat&lng=$lng',
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((r) => RouteModel.fromJson(r)).toList();
    }
    return [];
  }

  // ─── Fare ───

  /// Estimate fare for a ride with given number of passengers.
  static Future<FareEstimate?> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    int passengers = 1,
  }) async {
    final response = await ApiService.post(
      ApiConfig.fareEstimate,
      body: {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destLat': destLat,
        'destLng': destLng,
        'passengers': passengers,
      },
    );
    if (response.statusCode == 200) {
      return FareEstimate.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
