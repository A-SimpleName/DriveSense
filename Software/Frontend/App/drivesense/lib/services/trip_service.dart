import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:drivesense/model/trip_detailed.dart';

Future<void> saveTripToDb(TripSummary trip, List<Trackingpoint> trackingPoints) async {
  final res = await _postTripDetailed(
    TripDetailed(summary: trip, trackingpoints: trackingPoints),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('POST failed: ${res.statusCode} ${res.body}');
  }
}

Future<http.Response> _postTripDetailed(TripDetailed tripDetailed) async {
  return http.post(
    Uri.parse('http://172.16.100.124:8080/api/trips/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${RuntimeStore.getAuthToken}',
    },
    
    body: jsonEncode(tripDetailed.toJson()),
  );
}
