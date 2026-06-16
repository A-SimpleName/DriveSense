class UserGroup {
  final int id;
  final String name;
  final int ownerId;
  final String owner;

  const UserGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    this.owner = '',
  });

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "ownerId": ownerId, "owner": owner};
  }

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      id: _asInt(json["id"]),
      name: _asString(json["name"]),
      ownerId: _asInt(json["ownerId"] ?? json["owner_id"]),
      owner: _asString(json["owner"] ?? json["Owner"]),
    );
  }

  UserGroup copyWith({int? id, String? name, int? ownerId, String? owner}) {
    return UserGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
    );
  }
}

class GroupMember {
  final int profileId;
  final String name;
  final String groupRole;

  const GroupMember({
    required this.profileId,
    required this.name,
    required this.groupRole,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      profileId: _asInt(json["profileId"] ?? json["profile_id"]),
      name: _asString(json["name"]),
      groupRole: _asString(json["groupRole"] ?? json["group_role"]),
    );
  }

  GroupMember copyWith({int? profileId, String? name, String? groupRole}) {
    return GroupMember(
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      groupRole: groupRole ?? this.groupRole,
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
  if (value == null) {
    return 0;
  }
  return int.tryParse(value.toString()) ?? 0;
}

String _asString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}
