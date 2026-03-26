import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:drivesense/model/trip_detailed.dart';
import 'package:drivesense/constants/api_config.dart';
import 'package:drivesense/exceptions/trip_http_exception.dart';

final String _baseUrl = ApiConfig.baseUrl;

class TripService {
  Future<void> saveTripToDb(
    TripSummary trip,
    List<Trackingpoint> trackingPoints,
  ) async {
    final res = await _postTripDetailed(
      TripDetailed(summary: trip, trackingpoints: trackingPoints),
    );

    if (res.statusCode != 200) {
      throw TripHttpException('Failed to save trip: ${res.statusCode} - ${res.body}', statusCode: res.statusCode);
    }
  }

  Future<http.Response> _postTripDetailed(TripDetailed tripDetailed) async {
    return http.post(
      Uri.parse('$_baseUrl/api/trips'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${RuntimeStore.getAuthToken()}',
      },

      body: jsonEncode(tripDetailed.toJson()),
    );
  }

  Future<List<TripSummary>> fetchTrips(int profileId, int protocolId) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/profiles/$profileId/protocols/$protocolId/trips',
      ),
    );

    if (response.statusCode != 200) {
      throw TripHttpException('Failed to load trips: ${response.statusCode} - ${response.body}', statusCode: response.statusCode);
    }

    final List<dynamic> jsonList = jsonDecode(response.body);

    return jsonList
        .map((json) => TripSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
