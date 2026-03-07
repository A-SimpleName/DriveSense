import 'package:drivesense/model/trackingpoint.dart';

class TripSummary {
  final int id;
  final int userId;
  final int vehicleId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final String weatherMain;
  final String? type;
  

  TripSummary({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.weatherMain,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "vehicleId": vehicleId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime?.toIso8601String(),
      "distanceKm": distanceKm,
      "weatherMain": weatherMain,
      "type": type,
    };
  }

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      id: json["id"],
      userId: json["userId"],
      vehicleId: json["vehicleId"],
      startTime: DateTime.parse(json["startTime"]),
      endTime: json["endTime"] != null
          ? DateTime.parse(json["endTime"])
          : null,
      distanceKm: json["distanceKm"].toDouble(),
      weatherMain: json["weatherMain"],
      type: json["type"],
    );
  }

  TripSummary copyWith({required DateTime endTime, required double distanceKm, required List<Trackingpoint> trackingPoints}) {
    return TripSummary(
      id: id,
      userId: userId,
      vehicleId: vehicleId,
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      weatherMain: weatherMain,
      type: type,
    );
  }
}