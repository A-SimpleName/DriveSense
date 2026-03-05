import 'dart:convert';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/model/trip.dart';
import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/gps_tracking.dart';
import 'dart:async';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/widgets/position_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drivesense/runtime_store.dart';


class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  double _lastAddedMeters = 0;
  int _eventCount = 0;
  double? _lastAccuracy;
  double? _lastSpeed;
  bool hasActiveTrip = false;
  double? startMileage;
  double? endMileage;
  Trackingpoint? _lastPoint;
  double _totalDistanceMeters = 0;
  Duration _currentTripDuration = Duration.zero;
  DateTime? tripStartTime;
  DateTime? tripEndTime;
  double? currentLatitude;
  double? currentLongitude;
  StreamSubscription<Position>? _positionSubscription;
  List<Trackingpoint> trackingPositions = [];
  Timer? _uiTimer;
  Trip? _activeTrip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hasActiveTrip
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CurrentTripCard(
                    onStop: _onStopTrip,
                    currentTripDistance: _totalDistanceMeters,
                    currentTripDuration: _currentTripDuration,
                    currentVehicle: 'BMW i3',
                  ),
                  const SizedBox(height: 12),
                  Text('Lat: $currentLatitude'),
                  Text('Lng: $currentLongitude'),
                  Text('Events: $_eventCount'),
                  Text('Last added: ${_lastAddedMeters.toStringAsFixed(2)} m'),
                  Text('Total: ${_totalDistanceMeters.toStringAsFixed(2)} m'),
                  Text('Accuracy: ${_lastAccuracy?.toStringAsFixed(1)} m'),
                  Text('Speed: ${_lastSpeed?.toStringAsFixed(2)} m/s'),
                  const SizedBox(height: 16),
                ],
              )
            : Column(
                children: [
                  StartTripCard(onStart: _onStartTrip),
                  const SizedBox(height: 24),
                  LastTripCard(),
                ],
              ),
      ),
    );
  }

  void _onStartTrip() {
    setState(() {
      hasActiveTrip = true;
      tripStartTime = DateTime.now();

      _totalDistanceMeters = 0;
      trackingPositions = [];
    });

    _activeTrip = Trip(
      id: 0, // TODO
      userId: 0, // TODO
      vehicleId: 0, // TODO
      startTime: tripStartTime!,
      endTime: tripEndTime, // = null
      distanceKm: 0, // TODO
      weatherMain: 'Clear', // TODO
      type: null, // TODO
    );

    _startGpsLogging();
    _startUiTicker();
  }

  Future<void> _onStopTrip() async {
  await _stopGpsLogging();
  _stopUiTicker();

  final end = DateTime.now();

  // Trip finalisieren
  final finishedTrip = _activeTrip!.copyWith(
    endTime: end,
    distanceKm: _totalDistanceMeters / 1000,
    trackingPoints: List<Trackingpoint>.from(trackingPositions),
  );

  RuntimeStore.trips.add(finishedTrip); // oben einfügen

  setState(() {
    hasActiveTrip = false;
    tripEndTime = end;
    _activeTrip = null;
  });

  // TODO: hier speichern (Backend/DB)
}

  void _startGpsLogging() {
    if (_positionSubscription != null) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // <- im Stand testen: keine Mindestbewegung
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            if (!hasActiveTrip) return;

            final tp = _toTrackingPoint(position);

            double added = 0;
            if (_lastPoint != null) {
              added = Geolocator.distanceBetween(
                _lastPoint!.latitude,
                _lastPoint!.longitude,
                tp.latitude,
                tp.longitude,
              );
            }
            _lastPoint = tp;

            setState(() {
              _eventCount++;

              currentLatitude = tp.latitude;
              currentLongitude = tp.longitude;

              _lastAddedMeters = added;
              _lastAccuracy = tp.accuracy;
              _lastSpeed = tp.speed;

              _totalDistanceMeters += added;
              trackingPositions.add(tp);
            });
          },
          onError: (e) {
            debugPrint('GPS STREAM ERROR: $e');
          },
          onDone: () {
            debugPrint('GPS STREAM DONE');
          },
        );
  }

  Future<void> _stopGpsLogging() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPoint = null;
    _stopUiTicker();

    setState(() {
      currentLatitude = null;
      currentLongitude = null;
      _lastAddedMeters = 0;
      _lastAccuracy = null;
      _lastSpeed = null;
    });
  }

  Trackingpoint _toTrackingPoint(Position p) {
    return Trackingpoint(
      id: 0, // TODO backend
      trackingId: 0, // TODO backend tripId
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      speed: p.speed,
      bearing: p.heading,
      timestamp: p.timestamp,
    );
  }

  bool _shouldAcceptPoint(Trackingpoint tp) {
    // Unzuverlässig -> skip
    final acc = tp.accuracy;
    if (acc != null && acc > 25) return false;

    // Stehst (oder GPS spinnt) -> skip (0.5 m/s ~ 1.8 km/h)
    final spd = tp.speed;
    if (spd != null && spd < 0.5) return false;

    if (_lastPoint == null) return true;

    final d = Geolocator.distanceBetween(
      _lastPoint!.latitude,
      _lastPoint!.longitude,
      tp.latitude,
      tp.longitude,
    );

    return d >= 10; // Auto: 10m = weniger Müll, weniger Daten
  }

  void _startUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !hasActiveTrip) return;

      setState(() {
        _currentTripDuration = DateTime.now().difference(tripStartTime!);
      });
    });
  }

  void _stopUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }
}
