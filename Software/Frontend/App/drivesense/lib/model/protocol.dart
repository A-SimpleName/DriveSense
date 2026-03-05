class Protocol {
  final int id;
  final int trackingId;
  final String roadSurfaceConditions;

  Protocol({
    required this.id,
    required this.trackingId,
    required this.roadSurfaceConditions,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "trackingId": trackingId,
      "roadSurfaceConditions": roadSurfaceConditions,
    };
  }

  factory Protocol.fromJson(Map<String, dynamic> json) {
    return Protocol(
      id: json["id"],
      trackingId: json["trackingId"],
      roadSurfaceConditions: json["roadSurfaceConditions"],
    );
  }
}