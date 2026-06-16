class Vehicle {
  final int id;
  final int userId;
  final String model;
  final String licensePlate;
  final int mileage;
  final String myRole;
  final String ownerAccountName;
  final String ownerProfileName;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.model,
    required this.licensePlate,
    required this.mileage,
    this.myRole = '',
    this.ownerAccountName = '',
    this.ownerProfileName = '',
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "model": model,
      "licensePlate": licensePlate,
      "mileage": mileage,
      "myRole": myRole,
      "ownerAccountName": ownerAccountName,
      "ownerProfileName": ownerProfileName,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: _asInt(json["id"]),
      userId: _asInt(json["userId"] ?? json["user_id"] ?? 0),
      model: _asString(json["model"]),
      licensePlate: _asString(json["licensePlate"] ?? json["license_plate"]),
      mileage: _asInt(json["mileage"]),
      myRole: _asString(json["myRole"] ?? json["my_role"]),
      ownerAccountName: _asString(
        json["ownerAccountName"] ?? json["owner_account_name"],
      ),
      ownerProfileName: _asString(
        json["ownerProfileName"] ?? json["owner_profile_name"],
      ),
    );
  }
}

class VehicleMember {
  final int profileId;
  final String profileName;
  final String profileRole;
  final String accountName;
  final String accountEmail;
  final String vehicleRole;

  const VehicleMember({
    required this.profileId,
    required this.profileName,
    required this.profileRole,
    required this.accountName,
    required this.accountEmail,
    required this.vehicleRole,
  });

  factory VehicleMember.fromJson(Map<String, dynamic> json) {
    return VehicleMember(
      profileId: _asInt(json["profileId"] ?? json["profile_id"]),
      profileName: _asString(json["profileName"] ?? json["profile_name"]),
      profileRole: _asString(json["profileRole"] ?? json["profile_role"]),
      accountName: _asString(json["accountName"] ?? json["account_name"]),
      accountEmail: _asString(json["accountEmail"] ?? json["account_email"]),
      vehicleRole: _asString(json["vehicleRole"] ?? json["vehicle_role"]),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) {
  return value == null ? '' : value.toString().trim();
}
