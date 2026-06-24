import 'dart:convert';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/exceptions/trip_http_exception.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/service_error_messages.dart';
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:flutter/foundation.dart';

/// Aggregate result of a manual/background pending-trip sync attempt.
class TripSyncResult {
  /// Number of queued trips considered for syncing.
  final int total;

  /// Number of trips uploaded successfully.
  final int successful;

  /// Number of trips that failed and remain queued.
  final int failed;

  const TripSyncResult({
    required this.total,
    required this.successful,
    required this.failed,
  });
}

/// Coordinates offline-first trip persistence and backend upload.
///
/// Finished trips are saved to Isar before the network request is attempted.
/// This keeps recorded drives recoverable when the app closes or connectivity
/// fails during stop-trip handling.
class TripSyncService {
  /// Local trip repository that stores queued and synced trip rows.
  final TripRepository isarTripRepository;

  /// Backend trip service used to upload queued trips.
  final TripService tripService;

  TripSyncService({
    required this.isarTripRepository,
    required this.tripService,
  });

  String _createLocalId(int accountId, TripSummary trip) {
    // The local id must stay stable across retries until the backend assigns a
    // server id and _applySyncedSummary rewrites it to server:<account>:<id>.
    final int localTripId = trip.id > 0
        ? trip.id
        : trip.startTime.microsecondsSinceEpoch;
    return 'local:$accountId:$localTripId';
  }

  /// Saves the finished trip locally first, then attempts immediate upload.
  ///
  /// If upload fails, the local row remains unsynced with the error attached so
  /// the background/manual sync flow can retry without losing the drive.
  Future<TripDetailed> saveTripWithRetry(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    if (trackingPoints.isEmpty) {
      throw TripHttpException(
        'Fahrt wurde verworfen, weil keine GPS-Punkte aufgezeichnet wurden.',
      );
    }

    final int accountId = LocalAccountScope.requireAccountId();
    final String localId = _createLocalId(accountId, trip);
    final Trip? existingLocalTrip = await isarTripRepository.getByLocalId(
      localId,
    );
    final Trip localTrip = existingLocalTrip ?? Trip();

    // Persist first, then try the network. If the request fails, the trip stays
    // queued in Isar and syncPendingTrips can retry it later.
    localTrip
      ..localId = localId
      ..accountId = accountId
      ..trackingPointsJson = jsonEncode(
        trackingPoints.map((tp) => tp.toJson()).toList(),
      )
      ..profileId = trip.profileId
      ..vehicleId = trip.vehicleId
      ..protocolId = trip.protocolId
      ..startTime = trip.startTime
      ..endTime = trip.endTime
      ..durationSeconds = trip.durationSeconds
      ..distanceKm = trip.distanceKm
      ..roadSurfaceConditions = trip.roadSurfaceConditions
      ..type = trip.type
      ..startMileage = trip.startMileage
      ..endMileage = trip.endMileage
      ..createdAt = existingLocalTrip?.createdAt ?? DateTime.now()
      ..isSynced = false
      ..retryCount = existingLocalTrip?.retryCount ?? 0
      ..lastError = TripRepository.syncInProgressMarker;

    await isarTripRepository.save(localTrip);

    try {
      final TripDetailed syncedDetail = await tripService.saveTripToDb(
        trip,
        trackingPoints,
      );
      await _applySyncedSummary(localTrip, syncedDetail.summary, accountId);
      localTrip.isSynced = true;
      localTrip.retryCount = 0;
      localTrip.lastError = null;
      await isarTripRepository.update(localTrip);
      return syncedDetail;
    } catch (e) {
      localTrip.retryCount += 1;
      localTrip.lastError = _syncFailureMessage(e);
      await isarTripRepository.update(localTrip);
      throw Exception('Fahrt lokal gespeichert, wird später synchronisiert.');
    }
  }

  /// Copies backend-confirmed values onto the local row after a successful
  /// upload, preserving local values when the backend sends empty placeholders.
  Future<void> _applySyncedSummary(
    Trip localTrip,
    TripSummary syncedSummary,
    int accountId,
  ) async {
    final double fallbackDistanceKm = localTrip.distanceKm;
    final int fallbackDurationSeconds = localTrip.durationSeconds;
    final String fallbackRoadSurfaceConditions =
        localTrip.roadSurfaceConditions;
    final int fallbackStartMileage = localTrip.startMileage;
    final int fallbackEndMileage = localTrip.endMileage;

    if (syncedSummary.id > 0) {
      // Once the backend returns a permanent id, replace any stale cached
      // server copy so the local queue does not show duplicate trips.
      final String serverLocalId = 'server:$accountId:${syncedSummary.id}';
      final Trip? conflictingServerTrip = await isarTripRepository.getByLocalId(
        serverLocalId,
      );
      if (conflictingServerTrip != null &&
          conflictingServerTrip.id != localTrip.id) {
        await isarTripRepository.deleteById(conflictingServerTrip.id);
      }
      localTrip.localId = serverLocalId;
    }
    localTrip.profileId = syncedSummary.profileId > 0
        ? syncedSummary.profileId
        : localTrip.profileId;
    localTrip.vehicleId = syncedSummary.vehicleId > 0
        ? syncedSummary.vehicleId
        : localTrip.vehicleId;
    localTrip.protocolId = syncedSummary.protocolId > 0
        ? syncedSummary.protocolId
        : localTrip.protocolId;
    localTrip.startTime = syncedSummary.startTime;
    localTrip.endTime = syncedSummary.endTime ?? localTrip.endTime;
    localTrip.durationSeconds = syncedSummary.durationSeconds > 0
        ? syncedSummary.durationSeconds
        : fallbackDurationSeconds;
    localTrip.distanceKm =
        syncedSummary.distanceKm > 0 || fallbackDistanceKm <= 0
        ? syncedSummary.distanceKm
        : fallbackDistanceKm;
    localTrip.roadSurfaceConditions =
        syncedSummary.roadSurfaceConditions.trim().isNotEmpty
        ? syncedSummary.roadSurfaceConditions
        : fallbackRoadSurfaceConditions;
    localTrip.type = syncedSummary.type ?? localTrip.type;
    localTrip.startMileage =
        syncedSummary.startMileage > 0 || fallbackStartMileage <= 0
        ? syncedSummary.startMileage
        : fallbackStartMileage;
    localTrip.endMileage =
        syncedSummary.endMileage > 0 || fallbackEndMileage <= 0
        ? syncedSummary.endMileage
        : fallbackEndMileage;
  }

  /// Uploads every unsynced local trip and returns counts for the UI message.
  ///
  /// Each row is handled independently so one bad trip does not block the rest
  /// of the local queue.
  Future<TripSyncResult> syncPendingTrips() async {
    final List<Trip> pendingTrips = await isarTripRepository.getUnsynced();
    int successful = 0;
    int failed = 0;

    for (final pendingTrip in pendingTrips) {
      try {
        final List<dynamic> trackingList =
            jsonDecode(pendingTrip.trackingPointsJson) as List<dynamic>;

        if (trackingList.isEmpty) {
          // A trip without positions cannot be accepted by the backend and is
          // not useful locally, so remove it instead of retrying forever.
          await isarTripRepository.deleteById(pendingTrip.id);
          debugPrint(
            'Discarded pending trip without tracking points (localId=${pendingTrip.localId}, dbId=${pendingTrip.id}).',
          );
          continue;
        }

        // Repair before creating the summary so the backend receives the same
        // mileage values the local table will display after sync.
        await _repairMileageForPendingTrip(pendingTrip);
        final TripSummary trip = TripSummary.fromTrip(pendingTrip);
        final List<Trackingpoint> trackingPoints = trackingList
            .map((item) => Trackingpoint.fromJson(item as Map<String, dynamic>))
            .toList();

        final TripDetailed syncedDetail = await tripService.saveTripToDb(
          trip,
          trackingPoints,
        );
        await _applySyncedSummary(
          pendingTrip,
          syncedDetail.summary,
          pendingTrip.accountId,
        );
        await _syncVehicleMileageForTrip(trip);
        pendingTrip.isSynced = true;
        pendingTrip.lastError = null;
        await isarTripRepository.update(pendingTrip);
        successful += 1;
      } catch (e, st) {
        pendingTrip.retryCount += 1;
        pendingTrip.lastError = _syncFailureMessage(e);
        await isarTripRepository.update(pendingTrip);
        failed += 1;

        debugPrint(
          'Pending trip sync failed (localId=${pendingTrip.localId}, dbId=${pendingTrip.id}): $e\n$st',
        );
      }
    }

    return TripSyncResult(
      total: pendingTrips.length,
      successful: successful,
      failed: failed,
    );
  }

  /// Pushes the trip's end mileage to the vehicle when the completed trip moved
  /// the odometer forward.
  Future<void> _syncVehicleMileageForTrip(TripSummary trip) async {
    List<Vehicle> vehicles = RuntimeStore.vehicles;
    if (vehicles.isEmpty) {
      vehicles = await VehicleService.fetchVehicles();
    }

    Vehicle? vehicle;
    for (final Vehicle candidate in vehicles) {
      if (candidate.id == trip.vehicleId) {
        vehicle = candidate;
        break;
      }
    }

    if (vehicle == null || trip.endMileage <= vehicle.mileage) {
      return;
    }

    final Vehicle updatedVehicle = Vehicle(
      id: vehicle.id,
      userId: vehicle.userId,
      model: vehicle.model,
      licensePlate: vehicle.licensePlate,
      mileage: trip.endMileage,
    );

    final bool updated = await VehicleService.updateVehicle(updatedVehicle);
    if (updated) {
      RuntimeStore.upsertVehicle(updatedVehicle);
      return;
    }

    debugPrint(
      'Vehicle mileage sync skipped after trip sync (vehicleId=${trip.vehicleId}, endMileage=${trip.endMileage}).',
    );
  }

  Future<void> _repairMileageForPendingTrip(Trip pendingTrip) async {
    // Older local drafts may have been saved before mileage repair existed.
    // Normalize them once before sending to the backend.
    final int startMileage = pendingTrip.startMileage < 0
        ? 0
        : pendingTrip.startMileage;
    final int calculatedEndMileage =
        startMileage + pendingTrip.distanceKm.round();
    final bool missingEndMileage =
        pendingTrip.endMileage == 0 && pendingTrip.distanceKm > 0;
    final int endMileage =
        pendingTrip.endMileage < startMileage || missingEndMileage
        ? calculatedEndMileage
        : pendingTrip.endMileage;

    if (startMileage == pendingTrip.startMileage &&
        endMileage == pendingTrip.endMileage) {
      return;
    }

    pendingTrip.startMileage = startMileage;
    pendingTrip.endMileage = endMileage;
    await isarTripRepository.update(pendingTrip);
  }

  /// Converts sync failures into the message stored on the local trip row.
  ///
  /// The UI later reuses this text for retry and status displays, so it should
  /// stay short and readable rather than exposing raw exception details.
  String _syncFailureMessage(Object error) {
    if (error is TripHttpException) {
      return error.message;
    }

    return ServiceErrorMessages.forException(
      error,
      action: 'Fahrt konnte nicht synchronisiert werden',
    );
  }
}
