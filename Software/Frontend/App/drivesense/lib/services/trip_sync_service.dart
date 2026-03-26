import 'dart:convert';
import 'package:drivesense/model/pending_trip.dart';
import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/repository/pending_trip_repository.dart';
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
  final PendingTripRepository pendingTripRepository;
  final TripService tripService;

  TripSyncService({
    required this.pendingTripRepository,
    required this.tripService,
  });

  String _createLocalId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> saveTripWithRetry(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    try {
      await tripService.saveTripToDb(trip, trackingPoints);
    } catch (e) {
      
      final pendingTrip = PendingTrip()
        ..localId = _createLocalId()
        ..tripSummaryJson = jsonEncode(trip.toJson())
        ..trackingPointsJson = jsonEncode(
          trackingPoints.map((tp) => tp.toJson()).toList(),
        )
        ..createdAt = DateTime.now()
        ..retryCount = 1
        ..lastError = e.toString();

      await pendingTripRepository.save(pendingTrip);
      throw Exception("Trip lokal gespeichert, wird später synchronisiert");
    }
  }

  Future<TripSyncResult> syncPendingTrips() async {
    final pendingTrips = await pendingTripRepository.getAll();
    var successful = 0;
    var failed = 0;

    for (final pendingTrip in pendingTrips) {
      try {
        final Map<String, dynamic> tripMap =
            jsonDecode(pendingTrip.tripSummaryJson) as Map<String, dynamic>;

        final List<dynamic> trackingList =
            jsonDecode(pendingTrip.trackingPointsJson) as List<dynamic>;

        final trip = TripSummary.fromJson(tripMap);
        final trackingPoints = trackingList
            .map((item) => Trackingpoint.fromJson(item as Map<String, dynamic>))
            .toList();

        await tripService.saveTripToDb(trip, trackingPoints);
        await pendingTripRepository.deleteById(pendingTrip.id);
        successful += 1;
      } catch (e) {
        pendingTrip.retryCount += 1;
        pendingTrip.lastError = e.toString();
        await pendingTripRepository.update(pendingTrip);
        failed += 1;

        debugPrint('Pending trip sync failed: $e');
      }
    }

    return TripSyncResult(
      total: pendingTrips.length,
      successful: successful,
      failed: failed,
    );
  }
}