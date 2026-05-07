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
  final _rideStatusController =
      StreamController<RideStatusEvent>.broadcast();

  /// Stream of driver location updates for a subscribed ride.
  Stream<DriverLocationUpdate> get locationUpdates =>
      _locationController.stream;

  /// Stream of ride status events (passenger accepted, ride started/completed).
  Stream<RideStatusEvent> get rideStatusUpdates =>
      _rideStatusController.stream;

  void Function()? _onConnectedCallback;
  void Function()? _onDisconnectedCallback;

  final _newRouteController = StreamController<NewRouteEvent>.broadcast();
  final _routeUpdateController = StreamController<RouteUpdateEvent>.broadcast();

  /// Stream of new route/ride availability events.
  Stream<NewRouteEvent> get newRouteUpdates => _newRouteController.stream;

  /// Stream of route update/cancellation events.
  Stream<RouteUpdateEvent> get routeUpdateEvents => _routeUpdateController.stream;

  /// Connect to the WebSocket endpoint. [onConnected] fires once STOMP handshake completes.
  void connect({void Function()? onConnected, void Function()? onDisconnected}) {
    _onConnectedCallback = onConnected;
    _onDisconnectedCallback = onDisconnected;
    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiConfig.wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (error) {},
        onStompError: (frame) {},
        onDisconnect: (frame) {
          _onDisconnectedCallback?.call();
        },
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _onConnectedCallback?.call();
    _onConnectedCallback = null;
  }

  /// Subscribe to new route availability broadcasts.
  void subscribeToRouteAvailability() {
    _client?.subscribe(
      destination: '/topic/routes/new',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            _newRouteController.add(NewRouteEvent.fromMap(data));
          } catch (_) {}
        }
      },
    );
  }

  /// Subscribe to route update/cancellation broadcasts.
  void subscribeToRouteUpdates() {
    _client?.subscribe(
      destination: '/topic/routes/updates',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            _routeUpdateController.add(RouteUpdateEvent.fromMap(data));
          } catch (_) {}
        }
      },
    );
  }

  /// Subscribe to ride status events (passenger accepted, ride started/completed).
  /// Location updates come on a separate /location sub-topic.
  void subscribeToRide(int rideId) {
    _client?.subscribe(
      destination: '/topic/ride/$rideId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            final type = data['type'] as String?;
            if (type != null) {
              _rideStatusController.add(RideStatusEvent(type: type, data: data));
            }
          } catch (_) {}
        }
      },
    );

    // Subscribe to driver location updates on the location sub-topic
    _client?.subscribe(
      destination: '/topic/ride/$rideId/location',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final update = DriverLocationUpdate.fromJson(frame.body!);
            _locationController.add(update);
          } catch (_) {}
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
    _rideStatusController.close();
    _newRouteController.close();
    _routeUpdateController.close();
  }
}

/// A new ride/route availability event broadcast from the server.
class NewRouteEvent {
  final String? type;
  final int? rideId;
  final String? driverPhone;
  final String? originAddress;
  final String? destinationAddress;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final int? availableSeats;

  NewRouteEvent({
    this.type,
    this.rideId,
    this.driverPhone,
    this.originAddress,
    this.destinationAddress,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.availableSeats,
  });

  factory NewRouteEvent.fromMap(Map<String, dynamic> map) {
    return NewRouteEvent(
      type: map['type'] as String?,
      rideId: (map['rideId'] as num?)?.toInt(),
      driverPhone: map['driverPhone'] as String?,
      originAddress: map['originAddress'] as String?,
      destinationAddress: map['destinationAddress'] as String?,
      originLat: (map['originLat'] as num?)?.toDouble(),
      originLng: (map['originLng'] as num?)?.toDouble(),
      destinationLat: (map['destinationLat'] as num?)?.toDouble(),
      destinationLng: (map['destinationLng'] as num?)?.toDouble(),
      availableSeats: (map['availableSeats'] as num?)?.toInt(),
    );
  }
}

/// A route update or cancellation event broadcast from the server.
class RouteUpdateEvent {
  final String? type;
  final int? rideId;
  final int? routeId;
  final int? availableSeats;

  RouteUpdateEvent({this.type, this.rideId, this.routeId, this.availableSeats});

  factory RouteUpdateEvent.fromMap(Map<String, dynamic> map) {
    return RouteUpdateEvent(
      type: map['type'] as String?,
      rideId: (map['rideId'] as num?)?.toInt(),
      routeId: (map['routeId'] as num?)?.toInt(),
      availableSeats: (map['availableSeats'] as num?)?.toInt(),
    );
  }
}

/// A ride status event broadcast from the server (PASSENGER_ADDED, RIDE_STARTED, RIDE_COMPLETED).
class RideStatusEvent {
  final String type;
  final Map<String, dynamic> data;

  RideStatusEvent({required this.type, required this.data});
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

