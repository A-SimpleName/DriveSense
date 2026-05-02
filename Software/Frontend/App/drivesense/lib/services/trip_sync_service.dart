import 'dart:convert';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/services/trip_service.dart';
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

  String _createLocalId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> saveTripWithRetry(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    final localTrip = Trip()
      ..localId = _createLocalId()
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
      ..createdAt = DateTime.now()
      ..isSynced = false
      ..retryCount = 0;

    await isarTripRepository.save(localTrip);

    try {
      await tripService.saveTripToDb(trip, trackingPoints);
      localTrip.isSynced = true;
      localTrip.lastError = null;
      await isarTripRepository.update(localTrip);
    } catch (e) {
      localTrip.retryCount += 1;
      localTrip.lastError = e.toString();
      await isarTripRepository.update(localTrip);
      throw Exception("Trip lokal gespeichert, wird später synchronisiert");
    }
  }

  Future<TripSyncResult> syncPendingTrips() async {
    final List<Trip> pendingTrips = await isarTripRepository.getUnsynced();
    int successful = 0;
    int failed = 0;

    for (final pendingTrip in pendingTrips) {
      try {
        final List<dynamic> trackingList =
            jsonDecode(pendingTrip.trackingPointsJson) as List<dynamic>;

        await _repairMileageForPendingTrip(pendingTrip);
        final TripSummary trip = TripSummary.fromTrip(pendingTrip);
        final List<Trackingpoint> trackingPoints = trackingList
            .map((item) => Trackingpoint.fromJson(item as Map<String, dynamic>))
            .toList();

        await tripService.saveTripToDb(trip, trackingPoints);
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
