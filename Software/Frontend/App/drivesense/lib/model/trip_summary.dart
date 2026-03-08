import 'package:drivesense/model/trackingpoint.dart';

class TripSummary {
  final int id;
  final int profileId;
  final int vehicleId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final String roadSurfaceConditions;
  final String? type;
  

  TripSummary({
    required this.id,
    required this.profileId,
    required this.vehicleId,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.roadSurfaceConditions,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      "profileId": profileId,
      "vehicleId": vehicleId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime?.toIso8601String(),
      "distance": distanceKm,
      "roadSurfaceConditions": roadSurfaceConditions,
      "type": type,
    };
  }

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      id: json["id"],
      profileId: json["profileId"],
      vehicleId: json["vehicleId"],
      startTime: DateTime.parse(json["startTime"]),
      endTime: json["endTime"] != null
          ? DateTime.parse(json["endTime"])
          : null,
      distanceKm: json["distance"].toDouble(),
      roadSurfaceConditions: json["roadSurfaceConditions"],
      type: json["type"],
    );
  }

  TripSummary copyWith({required DateTime endTime, required double distanceKm, required List<Trackingpoint> trackingPoints}) {
    return TripSummary(
      id: id,
      profileId: profileId,
      vehicleId: vehicleId,
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      roadSurfaceConditions: roadSurfaceConditions,
      type: type,
    );
  }
}