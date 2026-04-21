import 'dart:async';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Service für GPS-Tracking während einer Fahrt
/// Verwaltet den GPS-Stream und validiert Tracking-Points
class TripTrackingService {
  StreamSubscription<Position>? _positionSubscription;
  Trackingpoint? _lastAcceptedPoint;
  
  // Callbacks für UI-Updates
  Function(Trackingpoint point, double distanceAdded)? onTrackingUpdate;
  Function(String error)? onError;

  bool get isTracking => _positionSubscription != null;

  /// Startet GPS-Tracking
  void startTracking() {
    if (_positionSubscription != null) {
      debugPrint('Tracking läuft bereits');
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handlePositionUpdate,
      onError: (e) {
        debugPrint('GPS STREAM ERROR: $e');
        onError?.call(e.toString());
      },
      onDone: () {
        debugPrint('GPS STREAM DONE');
      },
    );

    // Emit one initial point right after start so a standing start is captured.
    unawaited(_emitInitialPoint());
  }

  /// Stoppt GPS-Tracking
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastAcceptedPoint = null;
  }

  /// Verarbeitet Position-Updates vom GPS-Stream
  void _handlePositionUpdate(Position position) {
    final tp = _positionToTrackingPoint(position);

    // Validierung: Punkt akzeptieren?
    if (!_shouldAcceptPoint(tp)) {
      debugPrint('Point rejected: acc=${tp.accuracy}, spd=${tp.speed}');
      return;
    }

    // Distanz zum letzten Punkt berechnen
    double distanceAdded = 0;
    if (_lastAcceptedPoint != null) {
      distanceAdded = Geolocator.distanceBetween(
        _lastAcceptedPoint!.latitude,
        _lastAcceptedPoint!.longitude,
        tp.latitude,
        tp.longitude,
      );
    }

    _lastAcceptedPoint = tp;

    // UI benachrichtigen
    onTrackingUpdate?.call(tp, distanceAdded);
  }

  /// Validiert ob ein Tracking-Point akzeptiert werden soll
  bool _shouldAcceptPoint(Trackingpoint tp) {
    // Unzuverlässig -> skip
    final acc = tp.accuracy;
    if (acc > 25) return false;

    // Always accept the very first point, even with 0 speed/low movement.
    if (_lastAcceptedPoint == null) return true;

    // Stehst (oder GPS spinnt) -> skip (0.5 m/s ~ 1.8 km/h)
    final spd = tp.speed;
    if (spd < 0.5) return false;

    final d = Geolocator.distanceBetween(
      _lastAcceptedPoint!.latitude,
      _lastAcceptedPoint!.longitude,
      tp.latitude,
      tp.longitude,
    );

    return d > 10; // Auto: 10m = weniger Müll, weniger Daten
  }

  /// Konvertiert Position zu Trackingpoint
  Trackingpoint _positionToTrackingPoint(Position p) {
    return Trackingpoint(
      id: 0, // TODO backend
      tripId: 0, // TODO backend tripId
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      speed: p.speed,
      bearing: p.heading,
      timestamp: p.timestamp,
    );
  }

  Future<void> _emitInitialPoint() async {
    try {
      final Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 5));
      _handlePositionUpdate(initialPosition);
    } catch (e) {
      debugPrint('Initial GPS point failed: $e');
    }
  }

  /// Cleanup
  void dispose() {
    _positionSubscription?.cancel();
  }
}
