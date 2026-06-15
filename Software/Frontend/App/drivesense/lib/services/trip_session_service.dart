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
  final TripDetailed localDetail;
  final Future<TripSessionSyncResult> syncFuture;

  const TripSessionStopResult({
    required this.trip,
    required this.localDetail,
    required this.syncFuture,
  });
}

class TripSessionSyncResult {
  final TripDetailed detail;
  final bool vehicleMileageSaved;

  const TripSessionSyncResult({
    required this.detail,
    required this.vehicleMileageSaved,
  });
}

class TripSessionState {
  final bool hasActiveTrip;
  final bool isPaused;
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
    required this.isPaused,
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
      isPaused: false,
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
    bool? isPaused,
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
      isPaused: isPaused ?? this.isPaused,
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
  Future<TripSessionStopResult>? _pendingStopTrip;
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
    RuntimeStore.setCurrentTripPurpose(activeDraft.type ?? '');

    _activeDraft = activeDraft;
    _trackingPositions = _decodeTrackingPoints(activeDraft.trackingPointsJson);
    final Trackingpoint? lastPoint =
        _decodeTrackingPoint(activeDraft.lastAcceptedPointJson) ??
        (_trackingPositions.isNotEmpty ? _trackingPositions.last : null);

    _state = TripSessionState(
      hasActiveTrip: true,
      isPaused: activeDraft.isPaused,
      totalDistanceMeters: activeDraft.distanceMeters,
      currentTripDuration: _currentTripDuration(activeDraft),
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

    if (activeDraft.isPaused) {
      await trackingService.stopTracking();
      return;
    }

    trackingService.seedLastAcceptedPoint(lastPoint);
    _setupTrackingCallbacks();
    try {
      await trackingService.startTracking();
    } catch (e) {
      debugPrint('Tracking restart failed: $e');
    }
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
    final String? tripType = _tripTypeForActiveProfile();
    final ActiveTrip activeDraft = ActiveTrip()
      ..profileId = profileId
      ..vehicleId = vehicleId
      ..protocolId = resolvedProtocolId
      ..startTime = startTime
      ..startMileage = startMileage
      ..distanceMeters = 0
      ..trackingPointsJson = '[]'
      ..lastAcceptedPointJson = null
      ..type = tripType
      ..isPaused = false
      ..pausedAt = null
      ..pausedDurationSeconds = 0
      ..createdAt = startTime
      ..updatedAt = startTime;

    await activeTripRepository.save(activeDraft);

    _activeDraft = activeDraft;
    _trackingPositions = <Trackingpoint>[];
    _state = TripSessionState(
      hasActiveTrip: true,
      isPaused: false,
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
    try {
      await trackingService.startTracking();
    } catch (_) {
      await activeTripRepository.clear();
      _clearActiveState(lastTrip: _state.lastTrip);
      rethrow;
    }
    _startUiTicker();
  }

  Future<void> pauseTrip() async {
    await _waitForPendingTrackingUpdate();
    await _refreshActiveDraftFromRepository();

    final ActiveTrip? activeDraft = _activeDraft;
    if (activeDraft == null) {
      throw const TripSessionException('Es ist keine aktive Fahrt vorhanden.');
    }

    if (activeDraft.isPaused) {
      return;
    }

    await trackingService.emitCurrentPoint();
    await _waitForPendingTrackingUpdate();
    await trackingService.stopTracking();
    await _waitForPendingTrackingUpdate();
    await _refreshActiveDraftFromRepository();

    final ActiveTrip? refreshedDraft = _activeDraft;
    if (refreshedDraft == null) {
      throw const TripSessionException('Es ist keine aktive Fahrt vorhanden.');
    }

    final DateTime pausedAt = DateTime.now();
    refreshedDraft
      ..isPaused = true
      ..pausedAt = pausedAt
      ..updatedAt = pausedAt;
    await activeTripRepository.update(refreshedDraft);
    _activeDraft = refreshedDraft;
    _stopUiTicker();

    _state = _state.copyWith(
      isPaused: true,
      currentTripDuration: _currentTripDuration(refreshedDraft),
      activeTrip: _summaryFromActiveTrip(refreshedDraft),
    );
    notifyListeners();
  }

  Future<void> resumeTrip() async {
    await _waitForPendingTrackingUpdate();
    await _refreshActiveDraftFromRepository();

    final ActiveTrip? activeDraft = _activeDraft;
    if (activeDraft == null) {
      throw const TripSessionException('Es ist keine aktive Fahrt vorhanden.');
    }

    if (!activeDraft.isPaused) {
      return;
    }

    final DateTime resumedAt = DateTime.now();
    final DateTime? pausedAt = activeDraft.pausedAt;
    if (pausedAt != null && resumedAt.isAfter(pausedAt)) {
      activeDraft.pausedDurationSeconds += resumedAt
          .difference(pausedAt)
          .inSeconds;
    }

    activeDraft
      ..isPaused = false
      ..pausedAt = null
      ..updatedAt = resumedAt;
    await activeTripRepository.update(activeDraft);
    _activeDraft = activeDraft;

    final Trackingpoint? lastPoint =
        _decodeTrackingPoint(activeDraft.lastAcceptedPointJson) ??
        (_trackingPositions.isNotEmpty ? _trackingPositions.last : null);
    trackingService.seedLastAcceptedPoint(lastPoint);
    _setupTrackingCallbacks();

    _state = _state.copyWith(
      isPaused: false,
      currentTripDuration: _currentTripDuration(activeDraft),
      activeTrip: _summaryFromActiveTrip(activeDraft),
    );
    notifyListeners();

    try {
      await trackingService.startTracking();
      _startUiTicker();
    } catch (_) {
      final DateTime failedAt = DateTime.now();
      activeDraft
        ..isPaused = true
        ..pausedAt = failedAt
        ..updatedAt = failedAt;
      await activeTripRepository.update(activeDraft);
      _activeDraft = activeDraft;
      _state = _state.copyWith(
        isPaused: true,
        currentTripDuration: _currentTripDuration(activeDraft),
        activeTrip: _summaryFromActiveTrip(activeDraft),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<TripSessionStopResult> stopTrip() async {
    final Future<TripSessionStopResult>? pendingStopTrip = _pendingStopTrip;
    if (pendingStopTrip != null) {
      return pendingStopTrip;
    }

    final Future<TripSessionStopResult> stopFuture = _stopTripInternal();
    _pendingStopTrip = stopFuture;

    try {
      return await stopFuture;
    } finally {
      _pendingStopTrip = null;
    }
  }

  Future<TripSessionStopResult> _stopTripInternal() async {
    if (_activeDraft == null) {
      throw const TripSessionException('Es ist keine aktive Fahrt vorhanden.');
    }

    if (!_activeDraft!.isPaused) {
      await trackingService.emitCurrentPoint();
    }
    await _waitForPendingTrackingUpdate();
    await trackingService.stopTracking();
    await _waitForPendingTrackingUpdate();
    await _refreshActiveDraftFromRepository();
    _stopUiTicker();

    final ActiveTrip? activeDraft = _activeDraft;
    if (activeDraft == null) {
      throw const TripSessionException('Es ist keine aktive Fahrt vorhanden.');
    }

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
    final List<Trackingpoint> finishedTrackingPositions =
        List<Trackingpoint>.from(_trackingPositions);
    final TripSummary finishedTrip = _summaryFromActiveTrip(
      activeDraft,
    ).copyWith(endTime: end, distanceKm: distanceKm, endMileage: endMileage);
    final TripDetailed finishedTripDetail = TripDetailed(
      summary: finishedTrip,
      trackingpoints: finishedTrackingPositions,
    );

    RuntimeStore.addTrip(finishedTrip);
    RuntimeStore.addTripDetail(finishedTrip.id, finishedTripDetail);

    final Vehicle? updatedVehicle = _updateRuntimeVehicleMileage(finishedTrip);
    final Future<TripSessionSyncResult> syncFuture = _syncFinishedTrip(
      finishedTrip,
      finishedTrackingPositions,
      updatedVehicle,
    );

    await activeTripRepository.clear();
    _clearActiveState(lastTrip: finishedTrip);

    return TripSessionStopResult(
      trip: finishedTrip,
      localDetail: finishedTripDetail,
      syncFuture: syncFuture,
    );
  }

  Future<TripSessionSyncResult> _syncFinishedTrip(
    TripSummary finishedTrip,
    List<Trackingpoint> trackingPositions,
    Vehicle? updatedVehicle,
  ) async {
    try {
      final TripDetailed syncedDetail = await tripSyncService.saveTripWithRetry(
        finishedTrip,
        trackingPositions,
      );
      final TripSummary resultTrip = _mergeSyncedSummary(
        syncedDetail.summary,
        fallback: finishedTrip,
      );
      final TripDetailed resultDetail = syncedDetail.copyWith(
        summary: resultTrip,
      );

      RuntimeStore.upsertTrip(resultTrip, replaceTripId: finishedTrip.id);
      RuntimeStore.addTripDetail(resultTrip.id, resultDetail);

      _updateLastTripIfStillCurrent(finishedTrip, resultTrip);

      final bool vehicleMileageSaved = await _persistVehicleMileage(
        updatedVehicle,
      );
      return TripSessionSyncResult(
        detail: resultDetail,
        vehicleMileageSaved: vehicleMileageSaved,
      );
    } catch (e) {
      await _persistVehicleMileage(updatedVehicle);
      rethrow;
    }
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
        (Trackingpoint point, double distanceAdded, bool alreadyPersisted) {
          _pendingTrackingUpdate = _pendingTrackingUpdate
              .catchError((Object e) {
                debugPrint('Previous tracking update failed: $e');
              })
              .then((_) {
                return _acceptTrackingUpdate(
                  point,
                  distanceAdded,
                  alreadyPersisted,
                );
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
    bool alreadyPersisted,
  ) async {
    final ActiveTrip? activeDraft = _activeDraft;
    if (activeDraft == null || !_state.hasActiveTrip || activeDraft.isPaused) {
      return;
    }

    if (alreadyPersisted) {
      final ActiveTrip? persistedDraft = await activeTripRepository.getActive();
      if (persistedDraft == null) {
        return;
      }

      _activeDraft = persistedDraft;
      _trackingPositions = _decodeTrackingPoints(
        persistedDraft.trackingPointsJson,
      );
      if (persistedDraft.isPaused) {
        _state = _state.copyWith(
          isPaused: true,
          currentTripDuration: _currentTripDuration(persistedDraft),
          activeTrip: _summaryFromActiveTrip(persistedDraft),
        );
        notifyListeners();
        return;
      }

      final Trackingpoint lastPoint =
          _decodeTrackingPoint(persistedDraft.lastAcceptedPointJson) ??
          (_trackingPositions.isNotEmpty ? _trackingPositions.last : point);

      _state = _state.copyWith(
        totalDistanceMeters: persistedDraft.distanceMeters,
        currentTripDuration: _currentTripDuration(persistedDraft),
        eventCount: _trackingPositions.length,
        lastAddedMeters: distanceAdded,
        lastAccuracy: lastPoint.accuracy,
        lastSpeed: lastPoint.speed,
        currentLatitude: lastPoint.latitude,
        currentLongitude: lastPoint.longitude,
        activeTrip: _summaryFromActiveTrip(persistedDraft),
      );
      notifyListeners();
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
      currentTripDuration: _currentTripDuration(activeDraft),
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
      if (activeDraft == null ||
          !_state.hasActiveTrip ||
          activeDraft.isPaused) {
        return;
      }

      _state = _state.copyWith(
        currentTripDuration: _currentTripDuration(activeDraft),
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

  Future<void> _refreshActiveDraftFromRepository() async {
    final ActiveTrip? persistedDraft = await activeTripRepository.getActive();
    if (persistedDraft == null) {
      return;
    }

    _activeDraft = persistedDraft;
    _trackingPositions = _decodeTrackingPoints(
      persistedDraft.trackingPointsJson,
    );
  }

  void _clearActiveState({TripSummary? lastTrip}) {
    _activeDraft = null;
    _trackingPositions = <Trackingpoint>[];
    _state = TripSessionState.inactive(lastTrip: lastTrip);
    notifyListeners();
  }

  void _updateLastTripIfStillCurrent(
    TripSummary localTrip,
    TripSummary syncedTrip,
  ) {
    final TripSummary? currentLastTrip = _state.lastTrip;
    if (currentLastTrip != null &&
        currentLastTrip.id != localTrip.id &&
        currentLastTrip.startTime != localTrip.startTime) {
      return;
    }

    _state = _state.copyWith(lastTrip: syncedTrip);
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
      type: activeTrip.type,
      startMileage: activeTrip.startMileage,
      endMileage: activeTrip.startMileage + distanceKm.round(),
      isSynced: false,
    );
  }

  String? _tripTypeForActiveProfile() {
    if (RuntimeStore.getActiveProfileRole() != 'BERUFSFAHRER') {
      return null;
    }

    final String tripType = RuntimeStore.getCurrentTripPurpose().trim();
    return tripType.isEmpty ? null : tripType;
  }

  Duration _currentTripDuration(ActiveTrip activeTrip) {
    final DateTime referenceTime = activeTrip.isPaused
        ? activeTrip.pausedAt ?? DateTime.now()
        : DateTime.now();
    final int activeSeconds =
        referenceTime.difference(activeTrip.startTime).inSeconds -
        activeTrip.pausedDurationSeconds;

    if (activeSeconds <= 0) {
      return Duration.zero;
    }
    return Duration(seconds: activeSeconds);
  }

  TripSummary _mergeSyncedSummary(
    TripSummary syncedSummary, {
    required TripSummary fallback,
  }) {
    return syncedSummary.copyWith(
      vehicleLicensePlate:
          syncedSummary.vehicleLicensePlate ?? fallback.vehicleLicensePlate,
      accountFirstName:
          syncedSummary.accountFirstName ?? fallback.accountFirstName,
      accountLastName:
          syncedSummary.accountLastName ?? fallback.accountLastName,
      vehicleModel: syncedSummary.vehicleModel ?? fallback.vehicleModel,
      startPoint: syncedSummary.startPoint ?? fallback.startPoint,
      furthestPoint: syncedSummary.furthestPoint ?? fallback.furthestPoint,
      endPoint: syncedSummary.endPoint ?? fallback.endPoint,
      type: syncedSummary.type ?? fallback.type,
      endTime: syncedSummary.endTime ?? fallback.endTime,
      distanceKm: syncedSummary.distanceKm > 0 || fallback.distanceKm <= 0
          ? syncedSummary.distanceKm
          : fallback.distanceKm,
      roadSurfaceConditions:
          syncedSummary.roadSurfaceConditions.trim().isNotEmpty
          ? syncedSummary.roadSurfaceConditions
          : fallback.roadSurfaceConditions,
      startMileage: syncedSummary.startMileage > 0 || fallback.startMileage <= 0
          ? syncedSummary.startMileage
          : fallback.startMileage,
      endMileage: syncedSummary.endMileage > 0 || fallback.endMileage <= 0
          ? syncedSummary.endMileage
          : fallback.endMileage,
      isSynced: true,
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
    final TripSummary? serverLatestTrip = await RuntimeStore.tripService
        .fetchLatestTrip();
    if (serverLatestTrip != null) {
      return serverLatestTrip;
    }

    try {
      final Trip? latestTrip = await tripRepository.getLatestCompleted(
        profileId: RuntimeStore.currentProfileId,
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
