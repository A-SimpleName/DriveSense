import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/services/trip_sync_service.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:drivesense/widgets/current_trip_card.dart';
import 'package:drivesense/widgets/start_trip_card.dart';
import 'package:drivesense/widgets/last_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/trip_tracking_service.dart';
import 'dart:async';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/runtime_store.dart';

class HomePageBody extends StatefulWidget {
  final TripSyncService tripSyncService;
  const HomePageBody({super.key, required this.tripSyncService});

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
  TripSummary? _lastTrip;

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
                  LastTripCard(lastTrip: _lastTrip),
                ],
              ),
      ),
    );
  }

  void _onStartTrip() {
    unawaited(_onStartTripAsync());
  }

  Future<void> _onStartTripAsync() async {
    final int? profileId = RuntimeStore.currentProfileId;
    int vehicleId = RuntimeStore.getCurrentVehicleId();
    int protocolId = RuntimeStore.getCurrentProtocolId();

    if (profileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fahrt kann noch nicht gestartet werden. Profil fehlt.',
          ),
        ),
      );
      return;
    }

    final int? resolvedProtocolId = protocolId > 0
        ? protocolId
        : await ProtocolService.resolveCurrentOrFirstAvailableProtocolId();
    if (resolvedProtocolId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fahrt kann nicht gestartet werden. Kein gueltiges Protokoll verfuegbar.',
          ),
        ),
      );
      return;
    }

    protocolId = resolvedProtocolId;
    RuntimeStore.setCurrentProtocolId(protocolId);

    final int? resolvedVehicleId =
        await VehicleService.resolveFirstAvailableVehicleId();
    if (resolvedVehicleId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fahrt kann nicht gestartet werden. Kein gueltiges Fahrzeug verfuegbar.',
          ),
        ),
      );
      return;
    }

    vehicleId = resolvedVehicleId;
    RuntimeStore.setCurrentVehicleId(vehicleId);

    setState(() {
      hasActiveTrip = true;
      tripStartTime = DateTime.now();

      _totalDistanceMeters = 0;
      trackingPositions = [];
    });

    _activeTrip = TripSummary(
      id: DateTime.now().millisecondsSinceEpoch,
      profileId: profileId,
      vehicleId: vehicleId,
      protocolId: protocolId,
      startTime: tripStartTime!,
      endTime: null,
      distanceKm: 0,
      roadSurfaceConditions: '',
      type: null,
      isSynced: false,
    );

    _setupTrackingCallbacks();
    _trackingService.startTracking();
    _startUiTicker();
  }

  void _onAbortTrip() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Fahrt abbrechen?'),
          content: Text(
            'Möchtest du die aktuelle Fahrt wirklich abbrechen? Alle gesammelten Daten gehen verloren.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _stopTrackingAndReset();
              },
              child: Text('Fahrt abbrechen'),
            ),
          ],
        );
      },
    );
  }

  void _stopTrackingAndReset() {
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
    );

    final finishedTripDetail = TripDetailed(
      summary: finishedTrip,
      trackingpoints: trackingPositions,
    );

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

    _lastTrip = finishedTrip;

    // Trip in Db speichern (mit Retry-Logik für Offline-Fälle)
    try {
      await widget.tripSyncService.saveTripWithRetry(
        finishedTrip,
        trackingPositions,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Setup Callbacks für den Tracking-Service
  void _setupTrackingCallbacks() {
    _trackingService.onTrackingUpdate =
        (Trackingpoint tp, double distanceAdded) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('GPS Error: $error')));
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
