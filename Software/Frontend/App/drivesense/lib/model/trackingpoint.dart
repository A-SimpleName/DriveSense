class Trackingpoint {
  final int id;
  final int tripId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double bearing;
  final DateTime timestamp;

  Trackingpoint({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      "lat": latitude,
      "lng": longitude,
      "accuracy": accuracy,
      "speed": speed,
      "bearing": bearing,
      "timestamp": timestamp.toIso8601String(),
    };
  }

  factory Trackingpoint.fromJson(Map<String, dynamic> json) {
    return Trackingpoint(
      id: json["id"],
      tripId: json["tripId"],
      latitude: json["lat"].toDouble(),
      longitude: json["lng"].toDouble(),
      accuracy: json["accuracy"].toDouble(),
      speed: json["speed"].toDouble(),
      bearing: json["bearing"].toDouble(),
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}