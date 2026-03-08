import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';

class TripDetailed {
  final TripSummary summary;
  final List<Trackingpoint> trackingpoints;

  TripDetailed({
    required this.summary,
    required this.trackingpoints,
  });

  Map<String, dynamic> toJson() {
    return {
      "tripSummary": summary.toJson(),
      "trackingpoints": trackingpoints.map((p) => p.toJson()).toList(),
    };
  }

  factory TripDetailed.fromJson(Map<String, dynamic> json) {
    return TripDetailed(
      summary: TripSummary.fromJson(json["trip"]),
      trackingpoints: json["trackingpoints"] != null
          ? (json["trackingpoints"] as List).map((p) => Trackingpoint.fromJson(p)).toList()
          : [],
    );
  }

  TripDetailed copyWith({required TripSummary summary, required List<Trackingpoint> trackingpoints}) {
    return TripDetailed(
      summary: summary,
      trackingpoints: trackingpoints,
    );
  }
}