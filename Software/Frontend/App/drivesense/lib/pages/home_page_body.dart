import 'dart:convert';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/trip_tracking_service.dart';
import 'dart:async';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/widgets/position_widgets.dart';
import 'package:drivesense/runtime_store.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  // UI State
  double _lastAddedMeters = 0;
  int _eventCount = 0;
  double? _lastAccuracy;
  double? _lastSpeed;
  bool hasActiveTrip = false;
  double? currentLatitude;
  double? currentLongitude;
  
  // Trip Data
  double? startMileage;
  double? endMileage;
  double _totalDistanceMeters = 0;
  Duration _currentTripDuration = Duration.zero;
  DateTime? tripStartTime;
  DateTime? tripEndTime;
  List<Trackingpoint> trackingPositions = [];
  TripSummary? _activeTrip;
  
  // Services & Timers
  final TripTrackingService _trackingService = TripTrackingService();
  Timer? _uiTimer;

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
                    onAbort: _onAbortTrip,
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

    _activeTrip = TripSummary(
      id: 5, // TODO
      profileId: 1, // TODO
      vehicleId: 1, // TODO
      startTime: tripStartTime!,
      endTime: tripEndTime, // = null
      distanceKm: 0, // TODO
      roadSurfaceConditions: 'Clear', // TODO
      type: null, // TODO
    );

    _setupTrackingCallbacks();
    _trackingService.startTracking();
    _startUiTicker();
  }

  void _onAbortTrip() {
    _trackingService.stopTracking();
    _stopUiTicker();

    setState(() {
      hasActiveTrip = false;
      tripEndTime = DateTime.now();
      _eventCount = 0;
      _totalDistanceMeters = 0;
      _activeTrip = null;
      currentLatitude = null;
      currentLongitude = null;
      _lastAddedMeters = 0;
      _lastAccuracy = null;
      _lastSpeed = null;
    });
  }

  Future<void> _onStopTrip() async {
    await _trackingService.stopTracking();
    _stopUiTicker();

    final end = DateTime.now();

    // Trip finalisieren
    final finishedTrip = _activeTrip!.copyWith(
      endTime: end,
      distanceKm: _totalDistanceMeters / 1000,
      trackingPoints: List<Trackingpoint>.from(trackingPositions),
    );

    final finishedTripDetail = TripDetailed(summary: finishedTrip, trackingpoints: trackingPositions);

    RuntimeStore.addTrip(finishedTrip); // oben einfügen
    RuntimeStore.addTripDetail(finishedTrip.id, finishedTripDetail);

    setState(() {
      hasActiveTrip = false;
      tripEndTime = end;
      _eventCount = 0;
      _totalDistanceMeters = 0;
      _activeTrip = null;
      currentLatitude = null;
      currentLongitude = null;
      _lastAddedMeters = 0;
      _lastAccuracy = null;
      _lastSpeed = null;
    });

    saveTripToDb(finishedTrip, trackingPositions);
    // TODO: hier speichern (Backend/DB)
  }

  /// Setup Callbacks für den Tracking-Service
  void _setupTrackingCallbacks() {
    _trackingService.onTrackingUpdate = (Trackingpoint tp, double distanceAdded) {
      if (!hasActiveTrip) return;

      setState(() {
        _eventCount++;
        currentLatitude = tp.latitude;
        currentLongitude = tp.longitude;
        _lastAddedMeters = distanceAdded;
        _lastAccuracy = tp.accuracy;
        _lastSpeed = tp.speed;
        _totalDistanceMeters += distanceAdded;
        trackingPositions.add(tp);
      });
    };

    _trackingService.onError = (String error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS Error: $error')),
        );
      }
    };
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
    _trackingService.dispose();
    _uiTimer?.cancel();
    super.dispose();
  }
}
