import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:drivesense/model/trip_detailed.dart';

Future<void> saveTripToDb(TripSummary trip, List<Trackingpoint> trackingPoints) async {
  final res = await _postTripDetailed(
    TripDetailed(summary: trip, trackingPoints: trackingPoints),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('POST failed: ${res.statusCode} ${res.body}');
  }
}

Future<http.Response> _postTripDetailed(TripDetailed tripDetailed) async {
  return http.post(
    Uri.parse('http://192.168.1.126:8080/api/trips/save'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(tripDetailed.toJson()),
  );
}
