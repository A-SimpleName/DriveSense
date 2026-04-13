import 'package:flutter/foundation.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/services/trip_service.dart';

class RuntimeStore {
  static List<TripSummary> trips = [];
  static Map<int, TripDetailed> tripDetailCache = {};
  static String authToken = '';
  static String refreshToken = '';
  static String? activeProfileToken;
  static int? currentProfileId;
  static int currentVehicleId = 0;
  static int currentProtocolId = 0;
  static final TripService tripService = TripService();
  static final TripRepository pendingTripRepository = TripRepository();

  static void addTrip(TripSummary trip) {
    trips.add(trip);
  }

  static void addTripDetail(int tripId, TripDetailed detail) {
    if (!tripDetailCache.containsKey(tripId)) {
      tripDetailCache[tripId] = detail;
    }
  }

  static TripDetailed? getTripDetail(int tripId) {
    return tripDetailCache[tripId];
  }

  static void setTrips(List<TripSummary> newTrips) {
    trips = newTrips;
  }

  static void setAuthToken(String token) {
    authToken = token;
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

  static void setActiveProfile({required int profileId, String? profileToken}) {
    currentProfileId = profileId;
    activeProfileToken = profileToken;
  }

  static String? getActiveProfileToken() {
    return activeProfileToken;
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
    activeProfileToken = null;
    currentProfileId = null;
    currentVehicleId = 0;
    currentProtocolId = 0;
    trips = [];
    tripDetailCache = {};
  }

  static Future<void> refreshTrips() async {
    debugPrint('[refreshTrips] START - currentProfileId=$currentProfileId, currentProtocolId=$currentProtocolId');
    if (currentProfileId == null) {
      debugPrint('[refreshTrips] EARLY RETURN: currentProfileId is null');
      return;
    }

    try {
      debugPrint('[refreshTrips] Fetching trips for profileId=$currentProfileId, protocolId=$currentProtocolId');
      final fetchedTrips = await tripService.fetchTrips(
        currentProfileId!,
        currentProtocolId,
      );

      debugPrint('[refreshTrips] SUCCESS: fetched ${fetchedTrips.length} trips');
      // fetchTrips already returns Isar-backed data (including unsynced entries)
      // and optionally enriches it from server, so no extra merge is needed.
      trips = fetchedTrips;
    } catch (e, st) {
      debugPrint('[refreshTrips] ERROR: $e\n$st');
    }
  }
}
