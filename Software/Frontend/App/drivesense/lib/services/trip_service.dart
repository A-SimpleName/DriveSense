import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/exceptions/trip_http_exception.dart';
import 'package:flutter/foundation.dart';

final String _baseUrl = ApiConfig.baseUrl;

class TripService {
  final TripRepository _tripRepository = TripRepository();

  Future<void> saveTripToDb(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    final int profileId = trip.profileId > 0
        ? trip.profileId
        : (RuntimeStore.currentProfileId ?? 0);

    if (profileId <= 0) {
      throw TripHttpException(
        'Trip kann nicht synchronisiert werden: profileId fehlt oder ist ungueltig.',
      );
    }

    if (RuntimeStore.currentProfileId != profileId) {
      throw TripHttpException(
        'Trip kann nicht synchronisiert werden: aktives Profil passt nicht zum Trip.',
      );
    }

    final int? protocolId = await _resolveProtocolIdForSync(
      preferredProtocolId: trip.protocolId,
    );
    if (protocolId == null || protocolId <= 0) {
      throw TripHttpException(
        'Trip kann nicht synchronisiert werden: protocolId fehlt oder ist ungueltig.',
      );
    }

    final int? vehicleId = await _resolveVehicleIdForSync(
      profileId: profileId,
      preferredVehicleId: trip.vehicleId,
    );
    if (vehicleId == null || vehicleId <= 0) {
      throw TripHttpException(
        'Trip kann nicht synchronisiert werden: vehicleId fehlt oder ist ungueltig.',
      );
    }

    RuntimeStore.setCurrentProtocolId(protocolId);
    RuntimeStore.setCurrentVehicleId(vehicleId);

    if (trip.endTime == null) {
      throw TripHttpException(
        'Trip kann nicht synchronisiert werden: endTime fehlt.',
      );
    }

    final http.Response summaryRes = await _postTripSummary(
      trip,
      profileId: profileId,
      vehicleId: vehicleId,
      protocolId: protocolId,
    );
    if (summaryRes.statusCode < 200 || summaryRes.statusCode >= 300) {
      if (summaryRes.statusCode == 405) {
        throw TripHttpException(
          'Backend unter $_baseUrl unterstuetzt POST /api/trips/summary nicht (HTTP 405). Bitte Backend neu deployen/neustarten oder die richtige Instanz verwenden.',
          statusCode: summaryRes.statusCode,
        );
      }
      throw TripHttpException(
        'Failed to create trip summary: ${summaryRes.statusCode} - ${summaryRes.body}',
        statusCode: summaryRes.statusCode,
      );
    }

    final Map<String, dynamic> createdTripJson =
        jsonDecode(summaryRes.body) as Map<String, dynamic>;
    final TripSummary createdTrip = TripSummary.fromJson(createdTripJson);

    final List<Trackingpoint> trackingPointsWithTripId = trackingPoints
        .map(
          (tp) => Trackingpoint(
            id: tp.id,
            tripId: createdTrip.id,
            latitude: tp.latitude,
            longitude: tp.longitude,
            accuracy: tp.accuracy,
            speed: tp.speed,
            bearing: tp.bearing,
            timestamp: tp.timestamp,
          ),
        )
        .toList();

    final http.Response trackingpointsRes = await _postTrackingpoints(
      createdTrip.id,
      trackingPointsWithTripId,
    );
    if (trackingpointsRes.statusCode < 200 ||
        trackingpointsRes.statusCode >= 300) {
      throw TripHttpException(
        'Failed to save trackingpoints: ${trackingpointsRes.statusCode} - ${trackingpointsRes.body}',
        statusCode: trackingpointsRes.statusCode,
      );
    }
  }

  Future<http.Response> _postTripSummary(
    TripSummary tripSummary, {
    required int profileId,
    required int vehicleId,
    required int protocolId,
  }) async {
    final Map<String, dynamic> payload = _createTripSummaryPayload(
      tripSummary,
      profileId: profileId,
      vehicleId: vehicleId,
      protocolId: protocolId,
    );

    debugPrint('POST /api/trips/summary payload=$payload');

    return http.post(
      Uri.parse('$_baseUrl/api/trips/summary'),
      headers: <String, String>{
        ...RequestHeaders.authenticatedJson(),
      },
      body: jsonEncode(payload),
    );
  }

  Future<void> updateTripSummary(TripSummary tripSummary) async {
    if (tripSummary.endTime == null) {
      throw TripHttpException(
        'Trip kann nicht aktualisiert werden: endTime fehlt.',
      );
    }

    final int profileId = tripSummary.profileId > 0
        ? tripSummary.profileId
        : (RuntimeStore.currentProfileId ?? 0);
    final int protocolId = tripSummary.protocolId > 0
        ? tripSummary.protocolId
        : RuntimeStore.getCurrentProtocolId();
    final int vehicleId = tripSummary.vehicleId > 0
        ? tripSummary.vehicleId
        : RuntimeStore.getCurrentVehicleId();

    if (profileId <= 0 || protocolId <= 0 || vehicleId <= 0) {
      throw TripHttpException(
        'Trip kann nicht aktualisiert werden: Profil, Protokoll oder Fahrzeug fehlt.',
      );
    }

    final Map<String, dynamic> payload = _createTripSummaryPayload(
      tripSummary,
      profileId: profileId,
      vehicleId: vehicleId,
      protocolId: protocolId,
    );

    debugPrint('PUT /api/trips/${tripSummary.id} payload=$payload');

    final http.Response response = await http.put(
      Uri.parse('$_baseUrl/api/trips/${tripSummary.id}'),
      headers: <String, String>{
        ...RequestHeaders.authenticatedJson(),
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TripHttpException(
        'Failed to update trip summary: ${response.statusCode} - ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<bool> deleteTripSummary(int tripId) async {
    if (tripId <= 0) {
      return false;
    }


    try {
      final http.Response response = await http.delete(
        Uri.parse('$_baseUrl/api/trips/$tripId'),
        headers: RequestHeaders.authenticated(),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _createTripSummaryPayload(
    TripSummary tripSummary, {
    required int profileId,
    required int vehicleId,
    required int protocolId,
  }) {
    return <String, dynamic>{
      'profileId': profileId,
      'vehicleId': vehicleId,
      'protocolId': protocolId,
      'startTime': _toBackendLocalDateTime(tripSummary.startTime),
      'endTime': _toBackendLocalDateTime(tripSummary.endTime!),
      'distance': tripSummary.distanceKm,
      'roadSurfaceConditions': tripSummary.roadSurfaceConditions,
      'startPoint': tripSummary.startPoint,
      'endPoint': tripSummary.endPoint,
      'type': tripSummary.type,
      'startMileage': tripSummary.startMileage,
      'endMileage': tripSummary.endMileage,
      'start_mileage': tripSummary.startMileage,
      'end_mileage': tripSummary.endMileage,
    };
  }

  String _toBackendLocalDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    final String ss = local.second.toString().padLeft(2, '0');
    final String ms = local.millisecond.toString().padLeft(3, '0');
    return '$y-$m-${d}T$hh:$mm:$ss.$ms';
  }

  Future<http.Response> _postTrackingpoints(
    int tripId,
    List<Trackingpoint> trackingpoints,
  ) async {
    final List<Map<String, dynamic>> payload = trackingpoints
        .map((Trackingpoint tp) => _createTrackingpointPayload(tp))
        .toList();

    return http.post(
      Uri.parse('$_baseUrl/api/trips/$tripId/trackingpoints'),
      headers: <String, String>{
        ...RequestHeaders.authenticatedJson(),
      },
      body: jsonEncode(payload),
    );
  }

  Map<String, dynamic> _createTrackingpointPayload(Trackingpoint tp) {
    return <String, dynamic>{
      'tripId': tp.tripId,
      'lat': _finite(tp.latitude),
      'lng': _finite(tp.longitude),
      'accuracy': _finite(tp.accuracy),
      'speed': _finite(tp.speed),
      'bearing': _finite(tp.bearing),
      'timestamp': _toBackendLocalDateTime(tp.timestamp),
    };
  }

  double _finite(double value) {
    if (value.isFinite) {
      return value;
    }
    return 0;
  }

  Future<int?> _resolveProtocolIdForSync({
    int preferredProtocolId = 0,
  }) async {
    final int? resolved =
        await ProtocolService.resolvePreferredCurrentOrFirstAvailableProtocolId(
          preferredProtocolId: preferredProtocolId,
        );
    if (resolved != null && resolved > 0) {
      return resolved;
    }

    return ProtocolService.createDefaultProtocol();
  }

  Future<int?> _resolveVehicleIdForSync({
    required int profileId,
    int preferredVehicleId = 0,
  }) async {
    final int? resolved =
        await VehicleService.resolvePreferredCurrentOrFirstAvailableVehicleId(
          preferredVehicleId: preferredVehicleId,
        );
    if (resolved != null && resolved > 0) {
      return resolved;
    }

    return VehicleService.createDefaultVehicle(profileId);
  }

  Future<List<TripSummary>> fetchTrips(int profileId, int protocolId) async {
    // Isar is the source of truth: return local data even when server sync fails.
    final List<Trip> localBeforeSync = await _tripRepository
        .getByProfileAndProtocol(profileId, protocolId);
    final List<TripSummary> serverSummaries = <TripSummary>[];


    try {
      final http.Response response = await http.get(
        Uri.parse('$_baseUrl/api/trips/protocols/$protocolId'),
        headers: RequestHeaders.authenticated(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;

        for (final dynamic item in jsonList) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final TripSummary summary = TripSummary.fromJson(item);
          if (summary.id <= 0) {
            continue;
          }

          serverSummaries.add(summary);

          await _upsertServerTrip(
            profileId: profileId,
            protocolId: protocolId,
            summary: summary,
          );
        }
      } else {
        debugPrint(
          'fetchTrips server sync skipped: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, st) {
      debugPrint(
        'fetchTrips server sync failed, using local Isar only: $e\n$st',
      );
    }

    final List<Trip> localAfterSync = await _tripRepository
        .getByProfileAndProtocol(profileId, protocolId);

    if (serverSummaries.isNotEmpty) {
      final List<TripSummary> unsyncedLocals = localAfterSync
          .where((Trip trip) => !trip.isSynced)
          .map((Trip trip) => TripSummary.fromTrip(trip))
          .toList();

      final List<TripSummary> merged = <TripSummary>[
        ...serverSummaries,
        ...unsyncedLocals,
      ];
      merged.sort(
        (TripSummary a, TripSummary b) => b.startTime.compareTo(a.startTime),
      );
      return merged;
    }

    final List<Trip> source = localAfterSync.isNotEmpty
        ? localAfterSync
        : localBeforeSync;

    source.sort((Trip a, Trip b) => b.startTime.compareTo(a.startTime));
    return source.map((Trip trip) => TripSummary.fromTrip(trip)).toList();
  }

  Future<void> _upsertServerTrip({
    required int profileId,
    required int protocolId,
    required TripSummary summary,
  }) async {
    final String serverLocalId = 'server:${summary.id}';
    final Trip? existing = await _tripRepository.getByLocalId(serverLocalId);

    final Trip trip = existing ?? Trip();
    trip.localId = serverLocalId;
    trip.profileId = profileId;
    trip.vehicleId = summary.vehicleId;
    trip.protocolId = protocolId;
    trip.startTime = summary.startTime;
    trip.endTime = summary.endTime;
    trip.distanceKm = summary.distanceKm;
    trip.roadSurfaceConditions = summary.roadSurfaceConditions;
    trip.type = summary.type;
    trip.startMileage = summary.startMileage;
    trip.endMileage = summary.endMileage;
    trip.createdAt = existing?.createdAt ?? DateTime.now();
    trip.isSynced = true;
    trip.retryCount = 0;
    trip.lastError = null;
    trip.trackingPointsJson = existing?.trackingPointsJson ?? '[]';

    await _tripRepository.save(trip);
  }

}
