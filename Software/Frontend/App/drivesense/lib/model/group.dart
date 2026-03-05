class Group {
  final int id;
  final String name;
  final int ownerId;

  Group({
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

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json["id"],
      name: json["name"],
      ownerId: json["ownerId"],
    );
  }
}