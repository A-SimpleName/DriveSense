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
import 'package:drivesense/services/trip_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:flutter/foundation.dart';

class TripSyncResult {
  final int total;
  final int successful;
  final int failed;

  const TripSyncResult({
    required this.total,
    required this.successful,
    required this.failed,
  });
}

class TripSyncService {
  final TripRepository isarTripRepository;
  final TripService tripService;

  TripSyncService({
    required this.isarTripRepository,
    required this.tripService,
  });

  String _createLocalId(int accountId, TripSummary trip) {
    final int localTripId = trip.id > 0
        ? trip.id
        : trip.startTime.microsecondsSinceEpoch;
    return 'local:$accountId:$localTripId';
  }

  Future<TripDetailed> saveTripWithRetry(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    if (trackingPoints.isEmpty) {
      throw TripHttpException(
        'Trip verworfen: Es wurden keine Trackingpunkte aufgezeichnet.',
      );
    }

    final int accountId = LocalAccountScope.requireAccountId();
    final String localId = _createLocalId(accountId, trip);
    final Trip? existingLocalTrip = await isarTripRepository.getByLocalId(
      localId,
    );
    final Trip localTrip = existingLocalTrip ?? Trip();

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
      localTrip.lastError = e.toString();
      await isarTripRepository.update(localTrip);
      throw Exception('Trip lokal gespeichert, wird spaeter synchronisiert.');
    }
  }

  Future<void> _applySyncedSummary(
    Trip localTrip,
    TripSummary syncedSummary,
    int accountId,
  ) async {
    final double fallbackDistanceKm = localTrip.distanceKm;
    final String fallbackRoadSurfaceConditions =
        localTrip.roadSurfaceConditions;
    final int fallbackStartMileage = localTrip.startMileage;
    final int fallbackEndMileage = localTrip.endMileage;

    if (syncedSummary.id > 0) {
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

  Future<TripSyncResult> syncPendingTrips() async {
    final List<Trip> pendingTrips = await isarTripRepository.getUnsynced();
    int successful = 0;
    int failed = 0;

    for (final pendingTrip in pendingTrips) {
      try {
        final List<dynamic> trackingList =
            jsonDecode(pendingTrip.trackingPointsJson) as List<dynamic>;

        if (trackingList.isEmpty) {
          await isarTripRepository.deleteById(pendingTrip.id);
          debugPrint(
            'Discarded pending trip without tracking points (localId=${pendingTrip.localId}, dbId=${pendingTrip.id}).',
          );
          continue;
        }

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
        pendingTrip.lastError = e.toString();
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

  Future<void> clearLocalTrips() async {
    await isarTripRepository.deleteAll();
  }

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
}
