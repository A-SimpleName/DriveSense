import 'package:flutter/foundation.dart';
import 'package:drivesense/model/protocol.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/services/jwt_identity.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/trip_service.dart';

class RuntimeStore {
  static List<Vehicle> vehicles = [];
  static List<Protocol> protocols = [];
  static List<TripSummary> trips = [];
  static Map<int, TripDetailed> tripDetailCache = {};
  static String authToken = '';
  static String refreshToken = '';
  static int? currentAccountId;
  static String? activeProfileToken;
  static String? activeProfileRole;
  static int? currentProfileId;
  static int currentVehicleId = 0;
  static int currentProtocolId = 0;
  static final TripService tripService = TripService();
  static final TripRepository pendingTripRepository = TripRepository();

  static void addTrip(TripSummary trip) {
    upsertTrip(trip);
  }

  static void upsertTrip(TripSummary trip, {int? replaceTripId}) {
    int index = -1;
    for (int i = 0; i < trips.length; i++) {
      if (_sameTripIdentity(trips[i], trip, replaceTripId: replaceTripId)) {
        index = i;
        break;
      }
    }

    if (index < 0) {
      trips.add(trip);
      return;
    }

    final List<TripSummary> nextTrips = <TripSummary>[];
    for (int i = 0; i < trips.length; i++) {
      final TripSummary existing = trips[i];
      if (i == index) {
        nextTrips.add(trip);
        continue;
      }

      if (!_sameTripIdentity(existing, trip, replaceTripId: replaceTripId)) {
        nextTrips.add(existing);
      }
    }
    trips = nextTrips;
  }

  static void setVehicles(List<Vehicle> newVehicles) {
    vehicles = newVehicles;

    final bool currentVehicleStillAvailable = vehicles.any(
      (Vehicle vehicle) => vehicle.id == currentVehicleId,
    );
    if (!currentVehicleStillAvailable) {
      currentVehicleId = vehicles.isNotEmpty ? vehicles.first.id : 0;
    }
  }

  static void setProtocols(List<Protocol> newProtocols) {
    protocols = newProtocols;

    final bool currentProtocolStillAvailable = protocols.any(
      (Protocol protocol) => protocol.id == currentProtocolId,
    );
    if (!currentProtocolStillAvailable) {
      currentProtocolId = protocols.isNotEmpty ? protocols.first.id : 0;
    }
  }

  static void upsertVehicle(Vehicle vehicle) {
    bool replaced = false;
    vehicles = vehicles.map((Vehicle existing) {
      if (existing.id == vehicle.id) {
        replaced = true;
        return vehicle;
      }
      return existing;
    }).toList();

    if (!replaced) {
      vehicles = <Vehicle>[...vehicles, vehicle];
    }
  }

  static void upsertProtocol(Protocol protocol) {
    if (protocol.id <= 0) {
      return;
    }

    bool replaced = false;
    protocols = protocols.map((Protocol existing) {
      if (existing.id == protocol.id) {
        replaced = true;
        return protocol;
      }
      return existing;
    }).toList();

    if (!replaced) {
      protocols = <Protocol>[...protocols, protocol];
    }

    if (currentProtocolId <= 0) {
      currentProtocolId = protocol.id;
    }
  }

  static void removeProtocol(int protocolId) {
    protocols = protocols
        .where((Protocol protocol) => protocol.id != protocolId)
        .toList();

    final bool currentProtocolStillAvailable = protocols.any(
      (Protocol protocol) => protocol.id == currentProtocolId,
    );
    if (!currentProtocolStillAvailable) {
      currentProtocolId = protocols.isNotEmpty ? protocols.first.id : 0;
    }
  }

  static Vehicle? getCurrentVehicle() {
    for (final Vehicle vehicle in vehicles) {
      if (vehicle.id == currentVehicleId) {
        return vehicle;
      }
    }

    return vehicles.isNotEmpty ? vehicles.first : null;
  }

  static Protocol? getCurrentProtocol() {
    for (final Protocol protocol in protocols) {
      if (protocol.id == currentProtocolId) {
        return protocol;
      }
    }

    return protocols.isNotEmpty ? protocols.first : null;
  }

  static void addTripDetail(int tripId, TripDetailed detail) {
    tripDetailCache[tripId] = detail;
  }

  static TripDetailed? getTripDetail(int tripId) {
    return tripDetailCache[tripId];
  }

  static void setTrips(List<TripSummary> newTrips) {
    trips = _dedupeTrips(newTrips);
  }

  static List<TripSummary> _dedupeTrips(List<TripSummary> source) {
    final List<TripSummary> deduped = <TripSummary>[];
    for (final TripSummary trip in source) {
      final int existingIndex = deduped.indexWhere(
        (TripSummary existing) => _sameTripIdentity(existing, trip),
      );
      if (existingIndex >= 0) {
        deduped[existingIndex] = _preferTripSummary(
          deduped[existingIndex],
          trip,
        );
      } else {
        deduped.add(trip);
      }
    }
    return deduped;
  }

  static TripSummary _preferTripSummary(TripSummary a, TripSummary b) {
    if (b.isSynced && !a.isSynced) {
      return b;
    }
    if (a.isSynced && !b.isSynced) {
      return a;
    }
    final int aScore = _tripCompletenessScore(a);
    final int bScore = _tripCompletenessScore(b);
    return bScore >= aScore ? b : a;
  }

  static int _tripCompletenessScore(TripSummary trip) {
    int score = 0;
    if (_hasUsefulText(trip.startPoint)) score++;
    if (_hasUsefulText(trip.furthestPoint)) score++;
    if (_hasUsefulText(trip.endPoint)) score++;
    if (_hasUsefulText(trip.roadSurfaceConditions)) score++;
    if (trip.distanceKm > 0) score++;
    if (trip.startMileage > 0) score++;
    if (trip.endMileage > 0) score++;
    return score;
  }

  static bool _hasUsefulText(String? value) {
    final String text = (value ?? '').trim().toLowerCase();
    return text.isNotEmpty &&
        text != 'undefined' &&
        text != 'null' &&
        text != 'unbekannt';
  }

  static bool _sameTripIdentity(
    TripSummary existing,
    TripSummary trip, {
    int? replaceTripId,
  }) {
    if (existing.id == trip.id ||
        (replaceTripId != null && existing.id == replaceTripId)) {
      return true;
    }

    if (existing.profileId != trip.profileId ||
        existing.protocolId != trip.protocolId ||
        existing.vehicleId != trip.vehicleId) {
      return false;
    }

    final int startDeltaMs = existing.startTime
        .difference(trip.startTime)
        .inMilliseconds
        .abs();
    return startDeltaMs <= 2500;
  }

  static void setAuthToken(String token) {
    final int? previousAccountId = currentAccountId;
    final int? nextAccountId = JwtIdentity.accountIdFromToken(token);

    authToken = token;
    currentAccountId = nextAccountId;
    LocalAccountScope.accountId = nextAccountId;

    if (previousAccountId != null &&
        nextAccountId != null &&
        previousAccountId != nextAccountId) {
      clearActiveProfile();
    }
  }

  static String? getAuthToken() {
    return authToken;
  }

  static void setRefreshToken(String token) {
    refreshToken = token;
  }

  static String? getRefreshToken() {
    return refreshToken;
  }

  static void setActiveProfile({
    required int profileId,
    String? profileToken,
    String? profileRole,
  }) {
    final bool profileChanged =
        currentProfileId != null && currentProfileId != profileId;

    currentProfileId = profileId;
    activeProfileToken = profileToken;
    activeProfileRole = profileRole;

    if (profileChanged) {
      currentVehicleId = 0;
      currentProtocolId = 0;
      vehicles = [];
      protocols = [];
      trips = [];
      tripDetailCache = {};
    }
  }

  static String? getActiveProfileToken() {
    return activeProfileToken;
  }

  static String getActiveProfileRole() {
    return activeProfileRole ?? 'PRIVAT';
  }

  static void setCurrentVehicleId(int vehicleId) {
    currentVehicleId = vehicleId;
  }

  static int getCurrentVehicleId() {
    return currentVehicleId;
  }

  static void setCurrentProtocolId(int protocolId) {
    currentProtocolId = protocolId;
  }

  static int getCurrentProtocolId() {
    return currentProtocolId;
  }

  static String? getCookieHeader({
    bool includeProfileToken = true,
    bool includeRefreshToken = false,
  }) {
    final List<String> cookies = <String>[];

    if (authToken.isNotEmpty) {
      cookies.add('accountToken=$authToken');
    }

    if (includeProfileToken &&
        activeProfileToken != null &&
        activeProfileToken!.isNotEmpty) {
      cookies.add('profileToken=$activeProfileToken');
    }

    if (includeRefreshToken && refreshToken.isNotEmpty) {
      cookies.add('refreshToken=$refreshToken');
    }

    if (cookies.isEmpty) {
      return null;
    }

    return cookies.join('; ');
  }

  static void clearSession() {
    authToken = '';
    refreshToken = '';
    currentAccountId = null;
    LocalAccountScope.accountId = null;
    clearActiveProfile();
  }

  static void clearActiveProfile() {
    activeProfileToken = null;
    activeProfileRole = null;
    currentProfileId = null;
    currentVehicleId = 0;
    currentProtocolId = 0;
    vehicles = [];
    protocols = [];
    trips = [];
    tripDetailCache = {};
  }

  static Future<void> refreshTrips() async {
    debugPrint(
      '[refreshTrips] START - currentProfileId=$currentProfileId, currentProtocolId=$currentProtocolId',
    );
    if (currentProfileId == null) {
      debugPrint('[refreshTrips] EARLY RETURN: currentProfileId is null');
      return;
    }
    if (currentProtocolId <= 0) {
      debugPrint('[refreshTrips] EARLY RETURN: currentProtocolId is invalid');
      trips = [];
      return;
    }

    try {
      debugPrint(
        '[refreshTrips] Fetching trips for profileId=$currentProfileId, protocolId=$currentProtocolId',
      );
      final fetchedTrips = await tripService.fetchTrips(
        currentProfileId!,
        currentProtocolId,
      );

      debugPrint(
        '[refreshTrips] SUCCESS: fetched ${fetchedTrips.length} trips',
      );
      // fetchTrips already returns Isar-backed data (including unsynced entries)
      // and optionally enriches it from server, so no extra merge is needed.
      trips = fetchedTrips;
    } catch (e, st) {
      debugPrint('[refreshTrips] ERROR: $e\n$st');
    }
  }
}
