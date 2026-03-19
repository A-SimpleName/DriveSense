import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/services/trip_service.dart' as TripService;

class RuntimeStore {
  static List<TripSummary> trips = [];
  static Map<int, TripDetailed> tripDetailCache = {};
  static String authToken = '';
  static int? currentProfileId = 1;

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

    trips = await TripService.fetchTrips(currentProfileId!, 1); // TODO: protocolId dynamisch setzen
  }
}
