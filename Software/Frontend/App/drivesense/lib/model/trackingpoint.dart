class Trackingpoint {
  final int id;
  final int trackingId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double bearing;
  final DateTime timestamp;

  Trackingpoint({
    required this.id,
    required this.trackingId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "trackingId": trackingId,
      "latitude": latitude,
      "longitude": longitude,
      "accuracy": accuracy,
      "speed": speed,
      "bearing": bearing,
      "timestamp": timestamp.toIso8601String(),
    };
  }

  factory Trackingpoint.fromJson(Map<String, dynamic> json) {
    return Trackingpoint(
      id: json["id"],
      trackingId: json["trackingId"],
      latitude: json["latitude"].toDouble(),
      longitude: json["longitude"].toDouble(),
      accuracy: json["accuracy"].toDouble(),
      speed: json["speed"].toDouble(),
      bearing: json["bearing"].toDouble(),
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}