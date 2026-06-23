class Protocol {
  final int id;
  final int createdByProfileId;
  final int usergroupId;
  final String name;

  Protocol({
    required this.id,
    required this.createdByProfileId,
    required this.usergroupId,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdByProfileId': createdByProfileId,
      'created_by_profile_id': createdByProfileId,
      'usergroupId': usergroupId,
      'usergroup_id': usergroupId,
      'name': name,
    };
  }

  factory Protocol.fromJson(Map<String, dynamic> json) {
    return Protocol(
      id: _asInt(
        json['id'] ??
            json['protocolId'] ??
            json['protocol_id'] ??
            json['currentProtocolId'] ??
            json['current_protocol_id'] ??
            json['currentprocolid'],
      ),
      createdByProfileId: _asInt(
        json['createdByProfileId'] ?? json['created_by_profile_id'],
      ),
      usergroupId: _asInt(json['usergroupId'] ?? json['usergroup_id']),
      name: (json['name'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
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
}
