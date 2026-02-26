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
    return Vehicle(
      id: json["id"],
      userId: json["userId"],
      model: json["model"],
      licensePlate: json["licensePlate"],
      mileage: json["mileage"],
    );
  }
}

