import 'package:drivesense/model/trackingpoint.dart';
import 'package:drivesense/model/trip.dart';

class TripSummary {
  final int id;
  final int profileId;
  final int vehicleId;
  final int protocolId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final String roadSurfaceConditions;
  final String? type;
  bool isSynced;

  TripSummary({
    required this.id,
    required this.profileId,
    required this.vehicleId,
    required this.protocolId,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.roadSurfaceConditions,
    required this.type,
    required this.isSynced,
  });

  Map<String, dynamic> toJson() {
    return {
      "profileId": profileId,
      "vehicleId": vehicleId,
      "protocolId": protocolId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime?.toIso8601String(),
      "distance": distanceKm,
      "roadSurfaceConditions": roadSurfaceConditions,
      "type": type,
      "isSynced": isSynced,
    };
  }

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? fallback;
    }

    return TripSummary(
      id: asInt(json["id"]),
      profileId: asInt(json["profileId"]),
      vehicleId: asInt(json["vehicleId"]),
      protocolId: asInt(json["protocolId"]),
      startTime: DateTime.parse(json["startTime"].toString()),
      endTime: json["endTime"] != null
          ? DateTime.parse(json["endTime"].toString())
          : null,
      distanceKm: asDouble(json["distance"]),
      roadSurfaceConditions: json["roadSurfaceConditions"]?.toString() ?? '',
      type: json["type"]?.toString(),
      isSynced: json["isSynced"] == true,
    );
  }

  factory TripSummary.fromTrip(Trip trip) {
    return TripSummary(
      id: trip.id,
      profileId: trip.profileId,
      vehicleId: trip.vehicleId,
      protocolId: trip.protocolId,
      startTime: trip.startTime,
      endTime: trip.endTime,
      distanceKm: trip.distanceKm,
      roadSurfaceConditions: trip.roadSurfaceConditions,
      type: trip.type,
      isSynced: trip.isSynced,
    );
  }

  TripSummary copyWith({
    required DateTime endTime,
    required double distanceKm,
    required List<Trackingpoint> trackingPoints,
  }) {
    return TripSummary(
      id: id,
      profileId: profileId,
      vehicleId: vehicleId,
      protocolId: protocolId,
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      roadSurfaceConditions: roadSurfaceConditions,
      type: type,
      isSynced: isSynced,
    );
  }
}
