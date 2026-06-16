import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'dart:convert';
import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/exceptions/trip_http_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;

final String _baseUrl = ApiConfig.baseUrl;

class TripService {
  final TripRepository _tripRepository = TripRepository();

  /// Uploads a completed trip by creating its summary first and then attaching
  /// all recorded tracking points to the server-created trip id.
  Future<TripDetailed> saveTripToDb(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    final int profileId = trip.profileId > 0
        ? trip.profileId
        : (RuntimeStore.currentProfileId ?? 0);

    // Resolve and validate the ids before making HTTP calls. Without these
    // checks, an offline trip could be uploaded into the wrong active context.
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
      preferredVehicleId: trip.vehicleId,
    );
    if (vehicleId == null || vehicleId <= 0) {
      throw TripHttpException(
        'Trip kann nicht synchronisiert werden: vehicleId fehlt oder ist ungueltig.',
      );
    }

    RuntimeStore.setCurrentProtocolId(protocolId);
    RuntimeStore.setCurrentVehicleId(vehicleId);

    // Only completed trips can be synced. Active trip drafts are persisted by
    // TripSessionService until the user stops the trip.
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
      // HTTP 405 is a deployment mismatch signal, so return a message that
      // points to the backend endpoint instead of a generic sync failure.
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

    // Tracking points are stored under the server-created trip id, not the
    // temporary local id used while the trip was offline.
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

    return _detailFromTrackingpointsResponse(
      trackingpointsRes,
      fallbackSummary: createdTrip,
      fallbackTrackingPoints: trackingPointsWithTripId,
    );
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

    return http.post(
      Uri.parse('$_baseUrl/api/trips/summary'),
      headers: <String, String>{...RequestHeaders.authenticatedJson()},
      body: jsonEncode(payload),
    );
  }

  /// Sends edited table fields for a completed trip back to the backend.
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

    final http.Response response = await http.put(
      Uri.parse('$_baseUrl/api/trips/${tripSummary.id}'),
      headers: <String, String>{...RequestHeaders.authenticatedJson()},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TripHttpException(
        'Failed to update trip summary: ${response.statusCode} - ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<bool> deleteTripSummary(TripSummary tripSummary) async {
    final int tripId = tripSummary.id;
    if (tripId <= 0) {
      return false;
    }

    if (!tripSummary.isSynced) {
      return _deleteLocalTripSummary(tripId);
    }

    try {
      final http.Response response = await http.delete(
        Uri.parse('$_baseUrl/api/trips/$tripId'),
        headers: RequestHeaders.authenticated(),
      );

      final bool success =
          response.statusCode >= 200 && response.statusCode < 300;
      if (success) {
        await _deleteCachedServerTrip(tripId);
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteLocalTripSummary(int tripId) async {
    final Trip? localTrip = await _tripRepository.getById(tripId);
    if (localTrip == null || localTrip.isSynced) {
      return false;
    }

    await _tripRepository.deleteById(localTrip.id);
    return true;
  }

  Future<void> _deleteCachedServerTrip(int tripId) async {
    final int accountId = LocalAccountScope.requireAccountId();
    final Trip? cachedTrip = await _tripRepository.getByLocalId(
      'server:$accountId:$tripId',
    );
    if (cachedTrip != null) {
      await _tripRepository.deleteById(cachedTrip.id);
    }
  }

  /// Loads details from the server when possible, then falls back to cached or
  /// local Isar data so the detail dialog can still open while offline.
  Future<TripDetailed> fetchTripDetail(
    int tripId, {
    TripSummary? fallbackSummary,
    bool forceRefresh = false,
  }) async {
    final TripDetailed? cached = RuntimeStore.getTripDetail(tripId);
    if (!forceRefresh && cached != null) {
      return cached;
    }

    try {
      // Server detail data is preferred because it may include normalized
      // addresses or tracking points that are not yet in the local cache.
      final http.Response response = await http
          .get(
            Uri.parse('$_baseUrl/api/trips/$tripId'),
            headers: RequestHeaders.authenticated(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final TripDetailed detail = _withFallbackSummaryFields(
            TripDetailed.fromJson(decoded),
            fallbackSummary,
          );
          RuntimeStore.addTripDetail(tripId, detail);
          return detail;
        }
      } else {
        debugPrint(
          'fetchTripDetail server lookup skipped: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, st) {
      debugPrint('fetchTripDetail server lookup failed: $e\n$st');
    }

    if (cached != null) {
      return cached;
    }

    final TripDetailed? localDetail = await _fetchLocalTripDetail(
      tripId,
      fallbackSummary: fallbackSummary,
    );
    if (localDetail != null) {
      RuntimeStore.addTripDetail(tripId, localDetail);
      return localDetail;
    }

    if (fallbackSummary != null) {
      return TripDetailed(
        summary: fallbackSummary,
        trackingpoints: <Trackingpoint>[],
      );
    }

    throw TripHttpException('Fahrtdetails konnten nicht geladen werden.');
  }

  TripDetailed _detailFromTrackingpointsResponse(
    http.Response response, {
    required TripSummary fallbackSummary,
    required List<Trackingpoint> fallbackTrackingPoints,
  }) {
    final String rawBody = response.body.trim();
    if (rawBody.isEmpty) {
      return TripDetailed(
        summary: fallbackSummary,
        trackingpoints: fallbackTrackingPoints,
      );
    }

    try {
      final dynamic decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return _withFallbackSummaryFields(
          TripDetailed.fromJson(decoded),
          fallbackSummary,
        );
      }
    } catch (e, st) {
      debugPrint('Trackingpoints response parsing failed: $e\n$st');
    }

    return TripDetailed(
      summary: fallbackSummary,
      trackingpoints: fallbackTrackingPoints,
    );
  }

  Future<TripDetailed?> _fetchLocalTripDetail(
    int tripId, {
    TripSummary? fallbackSummary,
  }) async {
    final Trip? trip = await _tripRepository.getById(tripId);
    if (trip == null) {
      return null;
    }

    return _withFallbackSummaryFields(
      TripDetailed(
        summary: TripSummary.fromTrip(trip),
        trackingpoints: _decodeTrackingPoints(trip.trackingPointsJson),
      ),
      fallbackSummary,
    );
  }

  TripDetailed _withFallbackSummaryFields(
    TripDetailed detail,
    TripSummary? fallbackSummary,
  ) {
    if (fallbackSummary == null) {
      return detail;
    }

    return detail.copyWith(
      summary: detail.summary.copyWith(
        vehicleLicensePlate:
            detail.summary.vehicleLicensePlate ??
            fallbackSummary.vehicleLicensePlate,
        accountFirstName:
            detail.summary.accountFirstName ?? fallbackSummary.accountFirstName,
        accountLastName:
            detail.summary.accountLastName ?? fallbackSummary.accountLastName,
        vehicleModel:
            detail.summary.vehicleModel ?? fallbackSummary.vehicleModel,
        startPoint: detail.summary.startPoint ?? fallbackSummary.startPoint,
        furthestPoint:
            detail.summary.furthestPoint ?? fallbackSummary.furthestPoint,
        endPoint: detail.summary.endPoint ?? fallbackSummary.endPoint,
        type: detail.summary.type ?? fallbackSummary.type,
        endTime: detail.summary.endTime ?? fallbackSummary.endTime,
        distanceKm:
            detail.summary.distanceKm > 0 || fallbackSummary.distanceKm <= 0
            ? detail.summary.distanceKm
            : fallbackSummary.distanceKm,
        roadSurfaceConditions:
            detail.summary.roadSurfaceConditions.trim().isNotEmpty
            ? detail.summary.roadSurfaceConditions
            : fallbackSummary.roadSurfaceConditions,
        startMileage:
            detail.summary.startMileage > 0 || fallbackSummary.startMileage <= 0
            ? detail.summary.startMileage
            : fallbackSummary.startMileage,
        endMileage:
            detail.summary.endMileage > 0 || fallbackSummary.endMileage <= 0
            ? detail.summary.endMileage
            : fallbackSummary.endMileage,
      ),
    );
  }

  List<Trackingpoint> _decodeTrackingPoints(String value) {
    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is! List) {
        return <Trackingpoint>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Trackingpoint.fromJson)
          .toList();
    } catch (_) {
      return <Trackingpoint>[];
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
      'furthestPoint': tripSummary.furthestPoint,
      'endPoint': tripSummary.endPoint,
      'type': tripSummary.type,
      // Keep both key styles because older backend builds read snake_case
      // mileage fields while newer ones use camelCase.
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
      headers: <String, String>{...RequestHeaders.authenticatedJson()},
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

  Future<int?> _resolveProtocolIdForSync({int preferredProtocolId = 0}) async {
    final int? resolved =
        await ProtocolService.resolvePreferredCurrentOrFirstAvailableProtocolId(
          preferredProtocolId: preferredProtocolId,
        );
    if (resolved != null && resolved > 0) {
      return resolved;
    }

    return null;
  }

  Future<int?> _resolveVehicleIdForSync({
    int preferredVehicleId = 0,
  }) async {
    final int? resolved =
        await VehicleService.resolvePreferredCurrentOrFirstAvailableVehicleId(
          preferredVehicleId: preferredVehicleId,
        );
    if (resolved != null && resolved > 0) {
      return resolved;
    }

    return null;
  }

  Future<TripSummary?> fetchLatestTrip() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$_baseUrl/api/trips/latest'),
        headers: RequestHeaders.authenticated(),
      );

      if (response.statusCode == 204 || response.body.trim().isEmpty) {
        return null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'fetchLatestTrip skipped: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final TripSummary summary = TripSummary.fromJson(decoded);
      if (summary.id <= 0) {
        return null;
      }

      if (summary.profileId > 0 && summary.protocolId > 0) {
        await _upsertServerTrip(
          profileId: summary.profileId,
          protocolId: summary.protocolId,
          summary: summary,
        );
      }

      return summary;
    } catch (e, st) {
      debugPrint('fetchLatestTrip failed, using local data only: $e\n$st');
      return null;
    }
  }

  /// Builds the protocol table data from both Isar and the backend.
  ///
  /// Isar is read first so offline trips remain visible. If the backend fetch
  /// succeeds, synced cache rows are refreshed/pruned while unsynced rows stay
  /// in the result until they can be uploaded.
  Future<List<TripSummary>> fetchTrips(int profileId, int protocolId) async {
    final List<Trip> localBeforeSync = await _tripRepository
        .getByProfileAndProtocol(profileId, protocolId);
    final List<TripSummary> serverSummaries = <TripSummary>[];
    final Set<int> serverTripIds = <int>{};
    bool serverFetchSucceeded = false;

    try {
      final http.Response response = await http.get(
        Uri.parse('$_baseUrl/api/trips/protocols/$protocolId'),
        headers: RequestHeaders.authenticated(),
      );

      if (response.statusCode == 204 || response.body.trim().isEmpty) {
        serverFetchSucceeded = true;
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        serverFetchSucceeded = true;
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;

        // Each server row is checked against unsynced local trips so the table
        // does not show a local draft beside the already-created server trip.
        for (final dynamic item in jsonList) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final TripSummary summary = TripSummary.fromJson(item);
          if (summary.id <= 0) {
            continue;
          }

          serverTripIds.add(summary.id);

          final Trip? matchingUnsyncedLocal = _findMatchingUnsyncedLocal(
            localBeforeSync,
            summary,
          );
          serverSummaries.add(
            _mergeServerSummaryWithLocal(summary, matchingUnsyncedLocal),
          );

          if (matchingUnsyncedLocal == null) {
            await _upsertServerTrip(
              profileId: profileId,
              protocolId: protocolId,
              summary: summary,
            );
          }
        }
      } else {
        debugPrint(
          'fetchTrips server sync skipped: ${response.statusCode} ${response.body}',
        );
      }

      if (serverFetchSucceeded) {
        // A successful server response is authoritative for synced rows. Local
        // synced trips missing from the response were deleted or moved remotely.
        await _tripRepository.deleteSyncedByProfileAndProtocolExceptServerIds(
          profileId: profileId,
          protocolId: protocolId,
          serverIds: serverTripIds,
        );
      }
    } catch (e, st) {
      debugPrint(
        'fetchTrips server sync failed, using local Isar only: $e\n$st',
      );
    }

    final List<Trip> localAfterSync = await _tripRepository
        .getByProfileAndProtocol(profileId, protocolId);

    if (serverFetchSucceeded) {
      // Append only unsynced locals that are not represented by a server row.
      // These are the trips the user expects to see while sync is pending.
      final List<TripSummary> unsyncedLocals = localAfterSync
          .where(
            (Trip trip) =>
                !trip.isSynced &&
                !_isRepresentedByServer(trip, serverSummaries),
          )
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

  /// Stores a backend trip in Isar unless it would duplicate an unsynced local
  /// draft for the same physical drive.
  Future<void> _upsertServerTrip({
    required int profileId,
    required int protocolId,
    required TripSummary summary,
  }) async {
    final int accountId = LocalAccountScope.requireAccountId();
    final String serverLocalId = 'server:$accountId:${summary.id}';
    final Trip? existing = await _tripRepository.getByLocalId(serverLocalId);
    if (existing == null) {
      // Leave matching unsynced locals untouched; the normal sync path will
      // replace their local ids once upload succeeds.
      final List<Trip> localTrips = await _tripRepository
          .getByProfileAndProtocol(profileId, protocolId);
      if (_findMatchingUnsyncedLocal(localTrips, summary) != null) {
        return;
      }
    }

    final Trip trip = existing ?? Trip();
    trip.localId = serverLocalId;
    trip.accountId = accountId;
    trip.profileId = profileId;
    trip.vehicleId = summary.vehicleId;
    trip.protocolId = protocolId;
    trip.startTime = summary.startTime;
    trip.endTime = summary.endTime;
    trip.distanceKm = summary.distanceKm > 0 || existing == null
        ? summary.distanceKm
        : existing.distanceKm;
    trip.roadSurfaceConditions = summary.roadSurfaceConditions.trim().isNotEmpty
        ? summary.roadSurfaceConditions
        : existing?.roadSurfaceConditions ?? '';
    trip.type = summary.type ?? existing?.type;
    trip.startMileage = summary.startMileage > 0 || existing == null
        ? summary.startMileage
        : existing.startMileage;
    trip.endMileage = summary.endMileage > 0 || existing == null
        ? summary.endMileage
        : existing.endMileage;
    trip.createdAt = existing?.createdAt ?? DateTime.now();
    trip.isSynced = true;
    trip.retryCount = 0;
    trip.lastError = null;
    trip.trackingPointsJson = existing?.trackingPointsJson ?? '[]';

    await _tripRepository.save(trip);
  }

  /// Searches only unsynced rows because synced rows already have stable
  /// server-local ids and are handled by direct lookup.
  Trip? _findMatchingUnsyncedLocal(
    List<Trip> localTrips,
    TripSummary serverSummary,
  ) {
    for (final Trip localTrip in localTrips) {
      if (!localTrip.isSynced &&
          _isSamePhysicalTrip(localTrip, serverSummary)) {
        return localTrip;
      }
    }

    return null;
  }

  bool _isRepresentedByServer(
    Trip localTrip,
    List<TripSummary> serverSummaries,
  ) {
    for (final TripSummary serverSummary in serverSummaries) {
      if (_isSamePhysicalTrip(localTrip, serverSummary)) {
        return true;
      }
    }

    return false;
  }

  bool _isSamePhysicalTrip(Trip localTrip, TripSummary serverSummary) {
    // Server-created trips and local drafts can have different ids; match by
    // owner fields plus tight time/distance tolerances to avoid duplicates.
    if (serverSummary.profileId > 0 &&
        localTrip.profileId != serverSummary.profileId) {
      return false;
    }
    if (serverSummary.protocolId > 0 &&
        localTrip.protocolId != serverSummary.protocolId) {
      return false;
    }
    if (serverSummary.vehicleId > 0 &&
        localTrip.vehicleId != serverSummary.vehicleId) {
      return false;
    }

    final int startDeltaMs = localTrip.startTime
        .difference(serverSummary.startTime)
        .inMilliseconds
        .abs();
    if (startDeltaMs <= 2500) {
      return true;
    }

    final DateTime? localEndTime = localTrip.endTime;
    final DateTime? serverEndTime = serverSummary.endTime;
    if (localEndTime == null || serverEndTime == null) {
      return false;
    }

    final int endDeltaMs = localEndTime
        .difference(serverEndTime)
        .inMilliseconds
        .abs();
    final double distanceDelta =
        (localTrip.distanceKm - serverSummary.distanceKm).abs();
    return endDeltaMs <= 2500 && distanceDelta <= 0.2;
  }

  /// Fills missing server fields from the local draft while keeping backend
  /// values when the backend supplied useful data.
  TripSummary _mergeServerSummaryWithLocal(
    TripSummary serverSummary,
    Trip? localTrip,
  ) {
    if (localTrip == null) {
      return serverSummary;
    }

    return serverSummary.copyWith(
      profileId: serverSummary.profileId > 0
          ? serverSummary.profileId
          : localTrip.profileId,
      vehicleId: serverSummary.vehicleId > 0
          ? serverSummary.vehicleId
          : localTrip.vehicleId,
      protocolId: serverSummary.protocolId > 0
          ? serverSummary.protocolId
          : localTrip.protocolId,
      endTime: serverSummary.endTime ?? localTrip.endTime,
      distanceKm: serverSummary.distanceKm > 0 || localTrip.distanceKm <= 0
          ? serverSummary.distanceKm
          : localTrip.distanceKm,
      startMileage:
          serverSummary.startMileage > 0 || localTrip.startMileage <= 0
          ? serverSummary.startMileage
          : localTrip.startMileage,
      endMileage: serverSummary.endMileage > 0 || localTrip.endMileage <= 0
          ? serverSummary.endMileage
          : localTrip.endMileage,
    );
  }
}
