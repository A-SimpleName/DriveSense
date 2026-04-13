class Profile {
  final int id;
  final String? name;
  final String? role;
  final int? accountId;

  const Profile({required this.id, this.name, this.role, this.accountId});

  factory Profile.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String? asString(dynamic value) {
      if (value == null) {
        return null;
      }
      final String text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return Profile(
      id: asInt(json['id']),
      name: asString(json['name']),
      role: asString(json['role']),
      accountId: asInt(json['account_id'] ?? json['accountId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role, 'account_id': accountId};
  }
}
