import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/model/trip_detailed.dart';

class RuntimeStore {
  static final List<TripSummary> trips = [];
  static final Map<int, TripDetailed> tripDetailCache = {};
  static String authToken = '';

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

  static void setAuthToken(String token) {
    authToken = token;
  }

  static String? getAuthToken() {
    return authToken;
  }
}
