import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';

class TripDetailed {
  final TripSummary summary;
  final List<Trackingpoint> trackingPoints;

  TripDetailed({
    required this.summary,
    required this.trackingPoints,
  });

  Map<String, dynamic> toJson() {
    return {
      "summary": summary.toJson(),
      "trackingPoints": trackingPoints.map((p) => p.toJson()).toList(),
    };
  }

  factory TripDetailed.fromJson(Map<String, dynamic> json) {
    return TripDetailed(
      summary: TripSummary.fromJson(json["summary"]),
      trackingPoints: json["trackingPoints"] != null
          ? (json["trackingPoints"] as List).map((p) => Trackingpoint.fromJson(p)).toList()
          : [],
    );
  }

  TripDetailed copyWith({required TripSummary summary, required List<Trackingpoint> trackingPoints}) {
    return TripDetailed(
      summary: summary,
      trackingPoints: trackingPoints,
    );
  }
}