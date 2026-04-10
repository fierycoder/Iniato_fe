import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../config/api_config.dart';

/// Real-time driver location tracking via STOMP over WebSocket.
class WebSocketService {
  StompClient? _client;
  final _locationController =
      StreamController<DriverLocationUpdate>.broadcast();

  /// Stream of driver location updates for a subscribed ride.
  Stream<DriverLocationUpdate> get locationUpdates =>
      _locationController.stream;

  /// Connect to the WebSocket endpoint.
  void connect() {
    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiConfig.wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (error) {
          print('WebSocket error: $error');
        },
        onStompError: (frame) {
          print('STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          print('WebSocket disconnected');
        },
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    print('WebSocket connected');
  }

  /// Subscribe to real-time location updates for a specific ride.
  void subscribeToRide(int rideId) {
    _client?.subscribe(
      destination: '/topic/ride/$rideId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final update = DriverLocationUpdate.fromJson(frame.body!);
            _locationController.add(update);
          } catch (e) {
            print('Error parsing location update: $e');
          }
        }
      },
    );
  }

  /// Disconnect and clean up.
  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _locationController.close();
  }
}

/// Driver location broadcast from the server.
class DriverLocationUpdate {
  final int driverId;
  final double latitude;
  final double longitude;
  final int rideId;

  DriverLocationUpdate({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.rideId,
  });

  factory DriverLocationUpdate.fromJson(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    return DriverLocationUpdate(
      driverId: map['driverId'] ?? 0,
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      rideId: (map['rideId'] ?? 0).toInt(),
    );
  }
}
