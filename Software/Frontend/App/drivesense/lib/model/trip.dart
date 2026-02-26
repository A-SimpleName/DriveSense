class Trip {
  final int id;
  final int userId;
  final int carId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final String weatherMain;
  final String weatherDescription;
  final String type;

  Trip({
    required this.id,
    required this.userId,
    required this.carId,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.weatherMain,
    required this.weatherDescription,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "carId": carId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime?.toIso8601String(),
      "distanceKm": distanceKm,
      "weatherMain": weatherMain,
      "weatherDescription": weatherDescription,
      "type": type,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json["id"],
      userId: json["userId"],
      carId: json["carId"],
      startTime: DateTime.parse(json["startTime"]),
      endTime: json["endTime"] != null
          ? DateTime.parse(json["endTime"])
          : null,
      distanceKm: json["distanceKm"].toDouble(),
      weatherMain: json["weatherMain"],
      weatherDescription: json["weatherDescription"],
      type: json["type"],
    );
  }
}