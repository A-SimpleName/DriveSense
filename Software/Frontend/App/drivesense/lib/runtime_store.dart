import 'package:flutter/foundation.dart';
import 'package:drivesense/model/protocol.dart';
import 'package:drivesense/model/vehicle.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/services/jwt_identity.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/trip_service.dart';

/// Process-wide runtime state for the active account/profile session.
///
/// This store intentionally holds only short-lived UI/session data. Durable
/// tokens live in [TokenStorage], and durable trip drafts/caches live in Isar.
/// Changing account or profile clears scoped values so selections and cached
/// lists cannot leak across user boundaries.
class RuntimeStore {
  /// Vehicles available to the selected profile.
  static List<Vehicle> vehicles = [];

  /// Protocols available to the selected profile.
  static List<Protocol> protocols = [];

  /// Visible trip summaries for the selected profile/protocol.
  static List<TripSummary> trips = [];

  /// In-memory cache of fetched trip details by visible trip id.
  static Map<int, TripDetailed> tripDetailCache = {};

  /// Current account JWT used for backend authentication.
  static String authToken = '';

  /// Refresh JWT used to renew [authToken].
  static String refreshToken = '';

  /// Account id decoded from [authToken].
  static int? currentAccountId;

  /// JWT for the selected profile, when profile-scoped API access is active.
  static String? activeProfileToken;

  /// Role of the selected profile, for UI and trip-purpose rules.
  static String? activeProfileRole;

  /// Id of the selected profile.
  static int? currentProfileId;

  /// Id of the selected vehicle, or `0` when no valid vehicle is selected.
  static int currentVehicleId = 0;

  /// Id of the selected protocol, or `0` when no valid protocol is selected.
  static int currentProtocolId = 0;

  /// Trip purpose selected for professional-driver profiles.
  static String currentTripPurpose = '';

  /// Shared trip service used by simple UI refresh paths.
  static final TripService tripService = TripService();

  /// Adds a trip summary while keeping one visible entry per physical trip.
  static void addTrip(TripSummary trip) {
    upsertTrip(trip);
  }

  /// Inserts or replaces a trip while collapsing the old local row and the new
  /// server row into one visible entry.
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

  /// Replaces the vehicle list and keeps the selected vehicle valid.
  static void setVehicles(List<Vehicle> newVehicles) {
    vehicles = newVehicles;

    final bool currentVehicleStillAvailable = vehicles.any(
      (Vehicle vehicle) => vehicle.id == currentVehicleId,
    );
    if (!currentVehicleStillAvailable) {
      currentVehicleId = vehicles.isNotEmpty ? vehicles.first.id : 0;
    }
  }

  /// Replaces the protocol list and keeps the selected protocol valid.
  static void setProtocols(List<Protocol> newProtocols) {
    protocols = newProtocols;

    final bool currentProtocolStillAvailable = protocols.any(
      (Protocol protocol) => protocol.id == currentProtocolId,
    );
    if (!currentProtocolStillAvailable) {
      currentProtocolId = protocols.isNotEmpty ? protocols.first.id : 0;
    }
  }

  /// Inserts or replaces a vehicle by id.
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

  /// Inserts or replaces a protocol by id.
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

  /// Removes a protocol and moves the current selection to a valid fallback.
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

  /// Returns the selected vehicle, or the first available vehicle as fallback.
  static Vehicle? getCurrentVehicle() {
    for (final Vehicle vehicle in vehicles) {
      if (vehicle.id == currentVehicleId) {
        return vehicle;
      }
    }

    return vehicles.isNotEmpty ? vehicles.first : null;
  }

  /// Returns the selected protocol, or the first available protocol as fallback.
  static Protocol? getCurrentProtocol() {
    for (final Protocol protocol in protocols) {
      if (protocol.id == currentProtocolId) {
        return protocol;
      }
    }

    return protocols.isNotEmpty ? protocols.first : null;
  }

  /// Caches a fetched trip detail.
  static void addTripDetail(int tripId, TripDetailed detail) {
    tripDetailCache[tripId] = detail;
  }

  /// Returns a cached trip detail, if one has already been fetched.
  static TripDetailed? getTripDetail(int tripId) {
    return tripDetailCache[tripId];
  }

  /// Replaces the trip list after removing local/server duplicates.
  static void setTrips(List<TripSummary> newTrips) {
    // Server and local Isar data can overlap during sync; prefer the most
    // complete version without showing duplicates in the protocol table.
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
    // Unsynced trips use local ids until the backend returns a permanent id,
    // so identity falls back to the same profile/protocol/vehicle and start
    // time tolerance used by the repository merge path.
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

  /// Stores the account token and resets profile-owned state when a different
  /// account becomes active.
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

  /// Stores the refresh token used by AuthHttpClient.
  static void setRefreshToken(String token) {
    refreshToken = token;
  }

  /// Activates a profile token/role and clears profile-scoped data when the
  /// user switches to another profile.
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
      // Profile-owned data must not leak across profile switches.
      currentVehicleId = 0;
      currentProtocolId = 0;
      currentTripPurpose = '';
      vehicles = [];
      protocols = [];
      trips = [];
      tripDetailCache = {};
    }
  }

  static String? getActiveProfileToken() {
    return activeProfileToken;
  }

  /// Returns the selected profile role, defaulting to a private driver profile.
  static String getActiveProfileRole() {
    return activeProfileRole ?? 'PRIVAT';
  }

  /// Selects the current vehicle id.
  static void setCurrentVehicleId(int vehicleId) {
    currentVehicleId = vehicleId;
  }

  /// Returns the selected vehicle id, or `0` when none is selected.
  static int getCurrentVehicleId() {
    return currentVehicleId;
  }

  /// Selects the current protocol id.
  static void setCurrentProtocolId(int protocolId) {
    currentProtocolId = protocolId;
  }

  /// Returns the selected protocol id, or `0` when none is selected.
  static int getCurrentProtocolId() {
    return currentProtocolId;
  }

  /// Builds the Cookie header expected by the backend auth filters.
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

  /// Clears profile-scoped selections, lists, and caches.
  static void clearActiveProfile() {
    activeProfileToken = null;
    activeProfileRole = null;
    currentProfileId = null;
    currentVehicleId = 0;
    currentProtocolId = 0;
    currentTripPurpose = '';
    vehicles = [];
    protocols = [];
    trips = [];
    tripDetailCache = {};
  }

  /// Refreshes the visible trip list for the selected profile/protocol.
  ///
  /// Invalid selections intentionally return early because the UI can show an
  /// empty protocol table until the user selects a valid context.
  static Future<void> refreshTrips() async {
    if (currentProfileId == null) {
      return;
    }
    if (currentProtocolId <= 0) {
      trips = [];
      return;
    }

    try {
      final fetchedTrips = await tripService.fetchTrips(
        currentProfileId!,
        currentProtocolId,
      );

      // fetchTrips already returns Isar-backed data (including unsynced entries)
      // and optionally enriches it from server, so no extra merge is needed.
      trips = fetchedTrips;
    } catch (e, st) {
      debugPrint('[refreshTrips] ERROR: $e\n$st');
    }
  }

  static void setCurrentTripPurpose(String value) {
    currentTripPurpose = value;
  }

  /// Returns the selected trip purpose for the next professional-driver trip.
  static String getCurrentTripPurpose() {
    return currentTripPurpose;
  }
}
