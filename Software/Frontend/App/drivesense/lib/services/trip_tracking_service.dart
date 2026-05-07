import 'dart:async';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS tracking service while a trip is active.
class TripTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  Trackingpoint? _lastAcceptedPoint;

  Function(Trackingpoint point, double distanceAdded)? onTrackingUpdate;
  Function(String error)? onError;

  bool get isTracking => _positionSubscription != null;

  void seedLastAcceptedPoint(Trackingpoint? point) {
    _lastAcceptedPoint = point;
  }

  void startTracking() {
    if (_positionSubscription != null) {
      debugPrint('Tracking is already running');
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _handlePositionUpdate,
          onError: (e) {
            debugPrint('GPS STREAM ERROR: $e');
            onError?.call(e.toString());
          },
          onDone: () {
            debugPrint('GPS STREAM DONE');
          },
        );

    unawaited(emitCurrentPoint());
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastAcceptedPoint = null;
  }

  Future<void> emitCurrentPoint() async {
    try {
      final Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 5));
      _handlePositionUpdate(currentPosition);
    } catch (e) {
      debugPrint('Current GPS point failed: $e');
    }
  }

  void _handlePositionUpdate(Position position) {
    final Trackingpoint trackingpoint = _positionToTrackingPoint(position);

    if (!_shouldAcceptPoint(trackingpoint)) {
      debugPrint(
        'Point rejected: acc=${trackingpoint.accuracy}, spd=${trackingpoint.speed}',
      );
      return;
    }

    double distanceAdded = 0;
    if (_lastAcceptedPoint != null) {
      distanceAdded = Geolocator.distanceBetween(
        _lastAcceptedPoint!.latitude,
        _lastAcceptedPoint!.longitude,
        trackingpoint.latitude,
        trackingpoint.longitude,
      );
    }

    _lastAcceptedPoint = trackingpoint;
    onTrackingUpdate?.call(trackingpoint, distanceAdded);
  }

  bool _shouldAcceptPoint(Trackingpoint trackingpoint) {
    final double accuracy = trackingpoint.accuracy;
    if (accuracy > 25) {
      return false;
    }

    if (_lastAcceptedPoint == null) {
      return true;
    }

    final double speed = trackingpoint.speed;
    if (speed < 0.5) {
      return false;
    }

    final double distance = Geolocator.distanceBetween(
      _lastAcceptedPoint!.latitude,
      _lastAcceptedPoint!.longitude,
      trackingpoint.latitude,
      trackingpoint.longitude,
    );

    return distance >= 5;
  }

  Trackingpoint _positionToTrackingPoint(Position position) {
    return Trackingpoint(
      id: 0,
      tripId: 0,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      bearing: position.heading,
      timestamp: position.timestamp,
    );
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
