class Vehicle {
  final int id;
  final int userId;
  final String model;
  final String licensePlate;
  final int mileage;
  final String myRole;

  Vehicle({
    required this.id,
    required this.userId,
    required this.model,
    required this.licensePlate,
    required this.mileage,
    this.myRole = '',
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "model": model,
      "licensePlate": licensePlate,
      "mileage": mileage,
      "myRole": myRole,
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
      licensePlate: (json["licensePlate"] ?? '') as String,
      mileage: asInt(json["mileage"]),
      myRole: (json["myRole"] ?? json["my_role"] ?? '') as String,
    );
  }
}
