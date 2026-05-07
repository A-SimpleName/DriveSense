import 'dart:async';
import 'dart:convert';

import 'package:drivesense/exceptions/trip_http_exception.dart';
import 'package:drivesense/model/active_trip.dart';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/repository/active_trip_repository.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/trip_sync_service.dart';
import 'package:drivesense/services/trip_tracking_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:flutter/foundation.dart';

class TripSessionException implements Exception {
  final String message;

  const TripSessionException(this.message);

  @override
  String toString() => message;
}

class TripSessionStopResult {
  final TripSummary trip;
  final Object? syncError;
  final bool vehicleMileageSaved;

  const TripSessionStopResult({
    required this.trip,
    required this.syncError,
    required this.vehicleMileageSaved,
  });
}

class TripSessionState {
  final bool hasActiveTrip;
  final double totalDistanceMeters;
  final Duration currentTripDuration;
  final int eventCount;
  final double lastAddedMeters;
  final double? lastAccuracy;
  final double? lastSpeed;
  final double? currentLatitude;
  final double? currentLongitude;
  final TripSummary? activeTrip;
  final TripSummary? lastTrip;

  const TripSessionState({
    required this.hasActiveTrip,
    required this.totalDistanceMeters,
    required this.currentTripDuration,
    required this.eventCount,
    required this.lastAddedMeters,
    required this.lastAccuracy,
    required this.lastSpeed,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.activeTrip,
    required this.lastTrip,
  });

  factory TripSessionState.inactive({TripSummary? lastTrip}) {
    return TripSessionState(
      hasActiveTrip: false,
      totalDistanceMeters: 0,
      currentTripDuration: Duration.zero,
      eventCount: 0,
      lastAddedMeters: 0,
      lastAccuracy: null,
      lastSpeed: null,
      currentLatitude: null,
      currentLongitude: null,
      activeTrip: null,
      lastTrip: lastTrip,
    );
  }

  TripSessionState copyWith({
    bool? hasActiveTrip,
    double? totalDistanceMeters,
    Duration? currentTripDuration,
    int? eventCount,
    double? lastAddedMeters,
    Object? lastAccuracy = _sentinel,
    Object? lastSpeed = _sentinel,
    Object? currentLatitude = _sentinel,
    Object? currentLongitude = _sentinel,
    Object? activeTrip = _sentinel,
    Object? lastTrip = _sentinel,
  }) {
    return TripSessionState(
      hasActiveTrip: hasActiveTrip ?? this.hasActiveTrip,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      currentTripDuration: currentTripDuration ?? this.currentTripDuration,
      eventCount: eventCount ?? this.eventCount,
      lastAddedMeters: lastAddedMeters ?? this.lastAddedMeters,
      lastAccuracy: identical(lastAccuracy, _sentinel)
          ? this.lastAccuracy
          : lastAccuracy as double?,
      lastSpeed: identical(lastSpeed, _sentinel)
          ? this.lastSpeed
          : lastSpeed as double?,
      currentLatitude: identical(currentLatitude, _sentinel)
          ? this.currentLatitude
          : currentLatitude as double?,
      currentLongitude: identical(currentLongitude, _sentinel)
          ? this.currentLongitude
          : currentLongitude as double?,
      activeTrip: identical(activeTrip, _sentinel)
          ? this.activeTrip
          : activeTrip as TripSummary?,
      lastTrip: identical(lastTrip, _sentinel)
          ? this.lastTrip
          : lastTrip as TripSummary?,
    );
  }
}

const Object _sentinel = Object();

class TripSessionService extends ChangeNotifier {
  final TripSyncService tripSyncService;
  final ActiveTripRepository activeTripRepository;
  final TripRepository tripRepository;
  final TripTrackingService trackingService;

  TripSessionState _state = TripSessionState.inactive();
  ActiveTrip? _activeDraft;
  List<Trackingpoint> _trackingPositions = <Trackingpoint>[];
  Future<void> _pendingTrackingUpdate = Future<void>.value();
  Timer? _uiTimer;

  TripSessionService({
    required this.tripSyncService,
    required this.activeTripRepository,
    TripRepository? tripRepository,
    TripTrackingService? trackingService,
  }) : tripRepository = tripRepository ?? TripRepository(),
       trackingService = trackingService ?? TripTrackingService();

  TripSessionState get state => _state;

  Future<void> initialize() async {
    final TripSummary? lastTrip = await _loadLatestCompletedTrip();
    final ActiveTrip? activeDraft = await activeTripRepository.getActive();
    if (activeDraft == null) {
      _state = _state.copyWith(lastTrip: lastTrip);
      notifyListeners();
      return;
    }

    final int? currentProfileId = RuntimeStore.currentProfileId;
    if (currentProfileId != null && activeDraft.profileId != currentProfileId) {
      _state = _state.copyWith(lastTrip: lastTrip);
      notifyListeners();
      return;
    }

    RuntimeStore.setCurrentProtocolId(activeDraft.protocolId);
    RuntimeStore.setCurrentVehicleId(activeDraft.vehicleId);

    _activeDraft = activeDraft;
    _trackingPositions = _decodeTrackingPoints(activeDraft.trackingPointsJson);
    final Trackingpoint? lastPoint =
        _decodeTrackingPoint(activeDraft.lastAcceptedPointJson) ??
        (_trackingPositions.isNotEmpty ? _trackingPositions.last : null);

    _state = TripSessionState(
      hasActiveTrip: true,
      totalDistanceMeters: activeDraft.distanceMeters,
      currentTripDuration: DateTime.now().difference(activeDraft.startTime),
      eventCount: _trackingPositions.length,
      lastAddedMeters: 0,
      lastAccuracy: lastPoint?.accuracy,
      lastSpeed: lastPoint?.speed,
      currentLatitude: lastPoint?.latitude,
      currentLongitude: lastPoint?.longitude,
      activeTrip: _summaryFromActiveTrip(activeDraft),
      lastTrip: lastTrip,
    );
    notifyListeners();

    trackingService.seedLastAcceptedPoint(lastPoint);
    _setupTrackingCallbacks();
    trackingService.startTracking();
    _startUiTicker();
  }

  Future<void> startTrip() async {
    if (_state.hasActiveTrip) {
      return;
    }

    final int? profileId = RuntimeStore.currentProfileId;
    int vehicleId = RuntimeStore.getCurrentVehicleId();

    if (profileId == null) {
      throw const TripSessionException(
        'Fahrt kann noch nicht gestartet werden. Profil fehlt.',
      );
    }

    final int? resolvedProtocolId =
        await ProtocolService.resolveCurrentOrFirstAvailableProtocolId();
    if (resolvedProtocolId == null) {
      throw const TripSessionException(
        'Fahrt kann nicht gestartet werden. Kein gueltiges Protokoll verfuegbar.',
      );
    }

    RuntimeStore.setCurrentProtocolId(resolvedProtocolId);

    if (RuntimeStore.vehicles.isEmpty) {
      RuntimeStore.setVehicles(await VehicleService.fetchVehicles());
    }

    final bool selectedVehicleExists = RuntimeStore.vehicles.any(
      (Vehicle vehicle) => vehicle.id == vehicleId,
    );
    if (!selectedVehicleExists && RuntimeStore.vehicles.isNotEmpty) {
      vehicleId = RuntimeStore.vehicles.first.id;
      RuntimeStore.setCurrentVehicleId(vehicleId);
    }

    if (vehicleId <= 0) {
      throw const TripSessionException(
        'Fahrt kann nicht gestartet werden. Kein gueltiges Fahrzeug verfuegbar.',
      );
    }

    final Vehicle? selectedVehicle = RuntimeStore.getCurrentVehicle();
    final DateTime startTime = DateTime.now();
    final int startMileage = selectedVehicle?.mileage ?? 0;
    final ActiveTrip activeDraft = ActiveTrip()
      ..profileId = profileId
      ..vehicleId = vehicleId
      ..protocolId = resolvedProtocolId
      ..startTime = startTime
      ..startMileage = startMileage
      ..distanceMeters = 0
      ..trackingPointsJson = '[]'
      ..lastAcceptedPointJson = null
      ..createdAt = startTime
      ..updatedAt = startTime;

    await activeTripRepository.save(activeDraft);

    _activeDraft = activeDraft;
    _trackingPositions = <Trackingpoint>[];
    _state = TripSessionState(
      hasActiveTrip: true,
      totalDistanceMeters: 0,
      currentTripDuration: Duration.zero,
      eventCount: 0,
      lastAddedMeters: 0,
      lastAccuracy: null,
      lastSpeed: null,
      currentLatitude: null,
      currentLongitude: null,
      activeTrip: _summaryFromActiveTrip(activeDraft),
      lastTrip: _state.lastTrip,
    );
    notifyListeners();

    _setupTrackingCallbacks();
    trackingService.startTracking();
    _startUiTicker();
  }

  Future<TripSessionStopResult> stopTrip() async {
    final ActiveTrip? activeDraft = _activeDraft;
    if (activeDraft == null) {
      throw const TripSessionException('Es ist keine aktive Fahrt vorhanden.');
    }

    await trackingService.emitCurrentPoint();
    await _waitForPendingTrackingUpdate();
    await trackingService.stopTracking();
    _stopUiTicker();

    if (_trackingPositions.isEmpty) {
      await activeTripRepository.clear();
      _clearActiveState(lastTrip: _state.lastTrip);
      throw TripHttpException(
        'Trip verworfen: Es wurden keine Trackingpunkte aufgezeichnet.',
      );
    }

    final DateTime end = DateTime.now();
    final double distanceKm = activeDraft.distanceMeters / 1000;
    final int endMileage = activeDraft.startMileage + distanceKm.round();
    final Trackingpoint firstPoint = _trackingPositions.first;
    final Trackingpoint lastPoint = _trackingPositions.last;

    final String startPoint = '${firstPoint.latitude}, ${firstPoint.longitude}';

    final String endPoint = '${lastPoint.latitude}, ${lastPoint.longitude}';

    final TripSummary finishedTrip = _summaryFromActiveTrip(activeDraft)
        .copyWith(
          endTime: end,
          distanceKm: distanceKm,
          endMileage: endMileage,
          startPoint: startPoint,
          endPoint: endPoint,
        );
    final TripDetailed finishedTripDetail = TripDetailed(
      summary: finishedTrip,
      trackingpoints: List<Trackingpoint>.from(_trackingPositions),
    );

    RuntimeStore.addTrip(finishedTrip);
    RuntimeStore.addTripDetail(finishedTrip.id, finishedTripDetail);

    final Vehicle? updatedVehicle = _updateRuntimeVehicleMileage(finishedTrip);
    Object? syncError;
    try {
      await tripSyncService.saveTripWithRetry(finishedTrip, _trackingPositions);
    } catch (e) {
      syncError = e;
    }

    final bool vehicleMileageSaved = await _persistVehicleMileage(
      updatedVehicle,
    );

    await activeTripRepository.clear();
    _clearActiveState(lastTrip: finishedTrip);

    return TripSessionStopResult(
      trip: finishedTrip,
      syncError: syncError,
      vehicleMileageSaved: vehicleMileageSaved,
    );
  }

  Future<void> abortTrip() async {
    await trackingService.stopTracking();
    await _waitForPendingTrackingUpdate();
    await activeTripRepository.clear();
    _stopUiTicker();
    _clearActiveState(lastTrip: _state.lastTrip);
  }

  String formatVehicleName(Vehicle? vehicle) {
    if (vehicle == null) {
      return 'Kein Fahrzeug';
    }

    return '${vehicle.model} (${vehicle.licensePlate})';
  }

  void _setupTrackingCallbacks() {
    trackingService.onTrackingUpdate =
        (Trackingpoint point, double distanceAdded) {
          _pendingTrackingUpdate = _pendingTrackingUpdate
              .catchError((Object e) {
                debugPrint('Previous tracking update failed: $e');
              })
              .then((_) {
                return _acceptTrackingUpdate(point, distanceAdded);
              });
          unawaited(_pendingTrackingUpdate);
        };

    trackingService.onError = (String error) {
      debugPrint('GPS Error: $error');
    };
  }

  Future<void> _acceptTrackingUpdate(
    Trackingpoint point,
    double distanceAdded,
  ) async {
    final ActiveTrip? activeDraft = _activeDraft;
    if (activeDraft == null || !_state.hasActiveTrip) {
      return;
    }

    _trackingPositions.add(point);
    activeDraft.distanceMeters += distanceAdded;
    activeDraft.trackingPointsJson = jsonEncode(
      _trackingPositions.map((Trackingpoint tp) => tp.toJson()).toList(),
    );
    activeDraft.lastAcceptedPointJson = jsonEncode(point.toJson());
    activeDraft.updatedAt = DateTime.now();
    await activeTripRepository.update(activeDraft);

    _state = _state.copyWith(
      totalDistanceMeters: activeDraft.distanceMeters,
      currentTripDuration: DateTime.now().difference(activeDraft.startTime),
      eventCount: _state.eventCount + 1,
      lastAddedMeters: distanceAdded,
      lastAccuracy: point.accuracy,
      lastSpeed: point.speed,
      currentLatitude: point.latitude,
      currentLongitude: point.longitude,
      activeTrip: _summaryFromActiveTrip(activeDraft),
    );
    notifyListeners();
  }

  void _startUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final ActiveTrip? activeDraft = _activeDraft;
      if (activeDraft == null || !_state.hasActiveTrip) {
        return;
      }

      _state = _state.copyWith(
        currentTripDuration: DateTime.now().difference(activeDraft.startTime),
      );
      notifyListeners();
    });
  }

  void _stopUiTicker() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  Future<void> _waitForPendingTrackingUpdate() async {
    try {
      await _pendingTrackingUpdate;
    } catch (e) {
      debugPrint('Tracking update flush failed: $e');
    }
  }

  void _clearActiveState({TripSummary? lastTrip}) {
    _activeDraft = null;
    _trackingPositions = <Trackingpoint>[];
    _state = TripSessionState.inactive(lastTrip: lastTrip);
    notifyListeners();
  }

  TripSummary _summaryFromActiveTrip(ActiveTrip activeTrip) {
    final double distanceKm = activeTrip.distanceMeters / 1000;
    return TripSummary(
      id: activeTrip.startTime.microsecondsSinceEpoch,
      profileId: activeTrip.profileId,
      vehicleId: activeTrip.vehicleId,
      vehicleLicensePlate: RuntimeStore.getCurrentVehicle()?.licensePlate,
      protocolId: activeTrip.protocolId,
      startTime: activeTrip.startTime,
      endTime: null,
      distanceKm: distanceKm,
      roadSurfaceConditions: '',
      type: null,
      startMileage: activeTrip.startMileage,
      endMileage: activeTrip.startMileage + distanceKm.round(),
      isSynced: false,
    );
  }

  List<Trackingpoint> _decodeTrackingPoints(String value) {
    try {
      final List<dynamic> raw = jsonDecode(value) as List<dynamic>;
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Trackingpoint.fromJson)
          .toList();
    } catch (_) {
      return <Trackingpoint>[];
    }
  }

  Trackingpoint? _decodeTrackingPoint(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return Trackingpoint.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
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

  Future<TripSummary?> _loadLatestCompletedTrip() async {
    try {
      final Trip? latestTrip = await tripRepository.getLatestCompleted(
        profileId: RuntimeStore.currentProfileId,
        protocolId: RuntimeStore.getCurrentProtocolId(),
      );
      if (latestTrip != null) {
        return TripSummary.fromTrip(latestTrip);
      }
    } catch (e) {
      debugPrint('Latest trip lookup failed: $e');
    }

    if (RuntimeStore.trips.isEmpty) {
      return null;
    }

    final List<TripSummary> trips = List<TripSummary>.from(RuntimeStore.trips);
    trips.sort((TripSummary a, TripSummary b) {
      final DateTime aTime = a.endTime ?? a.startTime;
      final DateTime bTime = b.endTime ?? b.startTime;
      return bTime.compareTo(aTime);
    });
    return trips.first;
  }

  @override
  void dispose() {
    _stopUiTicker();
    trackingService.dispose();
    super.dispose();
  }
}
