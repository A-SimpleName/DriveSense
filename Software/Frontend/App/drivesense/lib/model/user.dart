class User {
  final int id;
  final String name;
  final String role;
  final int accountId;
  final int groupId;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.accountId,
    required this.groupId,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "role": role,
      "accountId": accountId,
      "groupId": groupId,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      name: json["name"],
      role: json["role"],
      accountId: json["accountId"],
      groupId: json["groupId"],
    );
  }
}