import 'package:isar/isar.dart';

part 'trip.g.dart';

@collection
class Trip {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String localId;

  late String trackingPointsJson;

  late int profileId;
  late int vehicleId;
  late int protocolId;
  late DateTime startTime;
  DateTime? endTime;
  late double distanceKm;
  late String roadSurfaceConditions;

  String? startPoint;
  String? endPoint;
  String? furthestPoint;

  String? type;

  late DateTime createdAt;
  late int startMileage;
  late int endMileage;

  bool isSynced = false;
  int retryCount = 0;
  String? lastError;
}