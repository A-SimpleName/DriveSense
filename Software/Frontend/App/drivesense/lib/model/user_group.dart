class UserGroup {
  final int id;
  final String name;
  final int ownerId;

  UserGroup({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "ownerId": ownerId,
    };
  }

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      id: json["id"],
      name: json["name"],
      ownerId: json["ownerId"],
    );
  }
}