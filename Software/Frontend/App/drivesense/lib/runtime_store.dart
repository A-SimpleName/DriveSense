import 'package:flutter/foundation.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/repository/trip_repository.dart';
import 'package:drivesense/services/trip_service.dart';

class RuntimeStore {
  static List<TripSummary> trips = [];
  static Map<int, TripDetailed> tripDetailCache = {};
  static String authToken = '';
  static int? currentProfileId = 1;
  static final TripService tripService = TripService();
  static final TripRepository pendingTripRepository =
      TripRepository();

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

  static Future<void> refreshTrips() async {
    if (currentProfileId == null) return;

    try {
      final fetchedTrips = await tripService.fetchTrips(
        currentProfileId!,
        1,
      ); // TODO: protocolId dynamisch setzen

      final pendingTrips = await pendingTripRepository.getUnsynced();
      final pendingTripSummaries = pendingTrips
          .map((pendingTrip) => TripSummary.fromTrip(pendingTrip))
          .toList();

      // Only replace global state after a fully successful refresh.
      trips = [...fetchedTrips, ...pendingTripSummaries];
    } catch (e, st) {
      debugPrint('refreshTrips failed - keeping existing trips: $e\n$st');
    }
  }
}
