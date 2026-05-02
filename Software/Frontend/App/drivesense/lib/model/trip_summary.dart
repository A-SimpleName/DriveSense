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
  final String? startPoint;
  final String? endPoint;
  final String? type;
  final int startMileage;
  final int endMileage;
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
    this.startPoint,
    this.endPoint,
    required this.type,
    required this.isSynced,
    required this.startMileage,
    required this.endMileage,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "profileId": profileId,
      "vehicleId": vehicleId,
      "protocolId": protocolId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime?.toIso8601String(),
      "distance": distanceKm,
      "roadSurfaceConditions": roadSurfaceConditions,
      "startPoint": startPoint,
      "endPoint": endPoint,
      "type": type,
      "isSynced": isSynced,
      "startMileage": startMileage,
      "endMileage": endMileage,
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
      startPoint: (json["startPoint"] ?? json["start_point"])?.toString(),
      endPoint: (json["endPoint"] ?? json["end_point"])?.toString(),
      type: json["type"]?.toString(),
      isSynced: json["isSynced"] == true,
      startMileage: asInt(
        json["startMileage"] ?? json["start_mileage"],
      ),
      endMileage: asInt(
        json["endMileage"] ?? json["end_mileage"],
      ),
    );
  }

  factory TripSummary.fromTrip(Trip trip) {
    int mappedId = trip.id;
    if (trip.localId.startsWith('server:')) {
      final String remoteIdValue = trip.localId.substring('server:'.length);
      final int? remoteId = int.tryParse(remoteIdValue);
      if (remoteId != null && remoteId > 0) {
        mappedId = remoteId;
      }
    }

    return TripSummary(
      id: mappedId,
      profileId: trip.profileId,
      vehicleId: trip.vehicleId,
      protocolId: trip.protocolId,
      startTime: trip.startTime,
      endTime: trip.endTime,
      distanceKm: trip.distanceKm,
      roadSurfaceConditions: trip.roadSurfaceConditions,
      startPoint: null,
      endPoint: null,
      type: trip.type,
      isSynced: trip.isSynced,
      startMileage: trip.startMileage,
      endMileage: trip.endMileage,
    );
  }

  TripSummary copyWith({
    required DateTime endTime,
    required double distanceKm,
    required int endMileage,
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
      startPoint: startPoint,
      endPoint: endPoint,
      type: type,
      isSynced: isSynced,
      startMileage: startMileage,
      endMileage: endMileage,
    );
  }
}
