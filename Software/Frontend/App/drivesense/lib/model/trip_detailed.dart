import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip_summary.dart';

class TripDetailed {
  final TripSummary summary;
  final List<Trackingpoint> trackingpoints;

  TripDetailed({required this.summary, required this.trackingpoints});

  Map<String, dynamic> toJson() {
    return {
      "tripSummary": summary.toJson(),
      "trackingpoints": trackingpoints.map((p) => p.toJson()).toList(),
    };
  }

  factory TripDetailed.fromJson(Map<String, dynamic> json) {
    final dynamic summaryJson =
        json["tripSummary"] ?? json["trip"] ?? json["summary"];
    final dynamic trackingpointsJson =
        json["trackingpoints"] ?? json["trackingPoints"];

    return TripDetailed(
      summary: TripSummary.fromJson(summaryJson as Map<String, dynamic>),
      trackingpoints: trackingpointsJson is List
          ? trackingpointsJson
                .whereType<Map<String, dynamic>>()
                .map(Trackingpoint.fromJson)
                .toList()
          : <Trackingpoint>[],
    );
  }

  TripDetailed copyWith({
    TripSummary? summary,
    List<Trackingpoint>? trackingpoints,
  }) {
    return TripDetailed(
      summary: summary ?? this.summary,
      trackingpoints: trackingpoints ?? this.trackingpoints,
    );
  }
}
