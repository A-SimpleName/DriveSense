import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/vehicle.dart';
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
  void initState() {
    super.initState();
    unawaited(_loadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    final currentVehicle = RuntimeStore.getCurrentVehicle();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: hasActiveTrip
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurrentTripCard(
                      onStop: _onStopTrip,
                      onAbort: _onAbortTrip,
                      currentTripDistance: _totalDistanceMeters,
                      currentTripDuration: _currentTripDuration,
                      currentVehicle: _formatVehicleName(currentVehicle),
                    ),
                    const SizedBox(height: 12),
                    Text('Lat: $currentLatitude'),
                    Text('Lng: $currentLongitude'),
                    Text('Events: $_eventCount'),
                    Text(
                      'Last added: ${_lastAddedMeters.toStringAsFixed(2)} m',
                    ),
                    Text('Total: ${_totalDistanceMeters.toStringAsFixed(2)} m'),
                    Text('Accuracy: ${_lastAccuracy?.toStringAsFixed(1)} m'),
                    Text('Speed: ${_lastSpeed?.toStringAsFixed(2)} m/s'),
                    const SizedBox(height: 16),
                  ],
                )
              : Column(
                  children: [
                    StartTripCard(
                      onStart: _onStartTrip,
                      vehicles: RuntimeStore.vehicles,
                      selectedVehicleId: RuntimeStore.getCurrentVehicleId(),
                      onVehicleChanged: _onVehicleChanged,
                    ),
                    const SizedBox(height: 24),
                    LastTripCard(lastTrip: _lastTrip),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _loadVehicles() async {
    final vehicles = await VehicleService.fetchVehicles();
    if (!mounted) return;

    setState(() {
      RuntimeStore.setVehicles(vehicles);
    });
  }

  void _onVehicleChanged(int vehicleId) {
    setState(() {
      RuntimeStore.setCurrentVehicleId(vehicleId);
    });
  }

  void _onStartTrip() {
    unawaited(_onStartTripAsync());
  }

  Future<void> _onStartTripAsync() async {
    final int? profileId = RuntimeStore.currentProfileId;
    int vehicleId = RuntimeStore.getCurrentVehicleId();

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

    final int? resolvedProtocolId =
        await ProtocolService.resolveCurrentOrFirstAvailableProtocolId();
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

    final int protocolId = resolvedProtocolId;
    RuntimeStore.setCurrentProtocolId(protocolId);

    if (RuntimeStore.vehicles.isEmpty) {
      await _loadVehicles();
    }

    final bool selectedVehicleExists = RuntimeStore.vehicles.any(
      (vehicle) => vehicle.id == vehicleId,
    );
    if (!selectedVehicleExists && RuntimeStore.vehicles.isNotEmpty) {
      vehicleId = RuntimeStore.vehicles.first.id;
      RuntimeStore.setCurrentVehicleId(vehicleId);
    }

    if (vehicleId <= 0) {
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

    RuntimeStore.setCurrentVehicleId(vehicleId);

    setState(() {
      hasActiveTrip = true;
      tripStartTime = DateTime.now();

      _totalDistanceMeters = 0;
      trackingPositions = [];
    });

    final Vehicle? selectedVehicle = RuntimeStore.getCurrentVehicle();
    final int startMileage = selectedVehicle?.mileage ?? 0;

    _activeTrip = TripSummary(
      id: DateTime.now().millisecondsSinceEpoch,
      profileId: profileId,
      vehicleId: vehicleId,
      vehicleLicensePlate: selectedVehicle?.licensePlate,
      protocolId: protocolId,
      startTime: tripStartTime!,
      endTime: null,
      distanceKm: 0,
      roadSurfaceConditions: '',
      type: null,
      startMileage: startMileage,
      endMileage: startMileage,
      isSynced: false,
    );

    _setupTrackingCallbacks();
    _trackingService.startTracking();
    _startUiTicker();
  }

  String _formatVehicleName(Vehicle? vehicle) {
    if (vehicle == null) {
      return 'Kein Fahrzeug';
    }

    return '${vehicle.model} (${vehicle.licensePlate})';
  }

  void _onAbortTrip() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Fahrt abbrechen?'),
          content: Text(
            'MÃ¶chtest du die aktuelle Fahrt wirklich abbrechen? Alle gesammelten Daten gehen verloren.',
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

    final double distanceKm = _totalDistanceMeters / 1000;
    final int endMileage = _activeTrip!.startMileage + distanceKm.round();

    // Trip finalisieren
    final finishedTrip = _activeTrip!.copyWith(
      endTime: end,
      distanceKm: distanceKm,
      endMileage: endMileage,
    );

    final finishedTripDetail = TripDetailed(
      summary: finishedTrip,
      trackingpoints: trackingPositions,
    );

    RuntimeStore.addTrip(finishedTrip); // oben einfÃ¼gen
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
    final Vehicle? updatedVehicle = _updateRuntimeVehicleMileage(finishedTrip);

    // Trip in Db speichern (mit Retry-Logik fÃ¼r Offline-FÃ¤lle)
    Object? syncError;

    try {
      await widget.tripSyncService.saveTripWithRetry(
        finishedTrip,
        trackingPositions,
      );
    } catch (e) {
      syncError = e;
    }

    final bool vehicleMileageSaved = await _persistVehicleMileage(
      updatedVehicle,
    );

    if (syncError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(syncError.toString())));
      }
      return;
    }

    if (updatedVehicle != null && !vehicleMileageSaved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fahrt gespeichert, aber Fahrzeug-Kilometerstand konnte nicht aktualisiert werden.',
          ),
        ),
      );
    }
  }

  Future<bool> _persistVehicleMileage(Vehicle? updatedVehicle) async {
    if (updatedVehicle == null) {
      return true;
    }

    return VehicleService.updateVehicle(updatedVehicle);
  }

  Vehicle? _updateRuntimeVehicleMileage(TripSummary finishedTrip) {
    final Vehicle? vehicle = RuntimeStore.getCurrentVehicle();
    if (vehicle == null || vehicle.id != finishedTrip.vehicleId) {
      return null;
    }

    if (finishedTrip.endMileage <= vehicle.mileage) {
      return null;
    }

    final Vehicle updatedVehicle = Vehicle(
      id: vehicle.id,
      userId: vehicle.userId,
      model: vehicle.model,
      licensePlate: vehicle.licensePlate,
      mileage: finishedTrip.endMileage,
    );

    RuntimeStore.upsertVehicle(updatedVehicle);
    return updatedVehicle;
  }

  /// Setup Callbacks fÃ¼r den Tracking-Service
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
