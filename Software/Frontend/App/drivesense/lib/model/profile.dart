class Profile {
  final int id;
  final String name;
  final String role;
  final int accountId;
  final int userGroupId;

  Profile({
    required this.id,
    required this.name,
    required this.role,
    required this.accountId,
    required this.userGroupId,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "role": role,
      "accountId": accountId,
      "userGroupId": userGroupId,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json["id"],
      name: json["name"],
      role: json["role"],
      accountId: json["accountId"],
      userGroupId: json["userGroupId"],
    );
  }
}