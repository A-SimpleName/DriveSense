class Vehicle {
  final int id;
  final int userId;
  final String model;
  final String licensePlate;
  final int mileage;

  Vehicle({
    required this.id,
    required this.userId,
    required this.model,
    required this.licensePlate,
    required this.mileage,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "model": model,
      "licensePlate": licensePlate,
      "mileage": mileage,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Hilfsfunktion: int aus verschiedenen JSON-Typen lesen (int, num, String)
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v != null) return int.tryParse(v.toString()) ?? 0;
      return 0;
    }

    return Vehicle(
      id: asInt(json["id"]),
      // userId ist in der Vehicle-Entity nicht vorhanden → 0 als Fallback
      userId: asInt(json["userId"] ?? json["user_id"] ?? 0),
      model: json["model"] as String? ?? '',
      // Backend-Entity hat "licenseplate" (lowercase), DTO hat "licensePlate"
      // Wir probieren beide Varianten
      licensePlate: (json["licensePlate"] ?? json["licenseplate"] ?? '') as String,
      mileage: asInt(json["mileage"]),
    );
  }
}