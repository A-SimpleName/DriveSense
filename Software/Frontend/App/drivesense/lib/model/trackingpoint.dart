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
      "id": id,
      "tripId": tripId,
      "lat": latitude,
      "lng": longitude,
      "accuracy": accuracy,
      "speed": speed,
      "bearing": bearing,
      "timestamp": timestamp.toIso8601String(),
    };
  }

  factory Trackingpoint.fromJson(Map<String, dynamic> json) {
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

    return Trackingpoint(
      id: asInt(json["id"]),
      tripId: asInt(json["tripId"] ?? json["trip_id"]),
      latitude: asDouble(json["lat"]),
      longitude: asDouble(json["lng"]),
      accuracy: asDouble(json["accuracy"]),
      speed: asDouble(json["speed"]),
      bearing: asDouble(json["bearing"]),
      timestamp: DateTime.parse(json["timestamp"].toString()),
    );
  }
}
