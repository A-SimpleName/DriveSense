import 'package:isar/isar.dart';

part 'active_trip.g.dart';

@collection
class ActiveTrip {
  Id id = Isar.autoIncrement;

  int accountId = 0;
  late int profileId;
  late int vehicleId;
  late int protocolId;
  late DateTime startTime;
  late int startMileage;

  late double distanceMeters;
  late String trackingPointsJson;
  String? lastAcceptedPointJson;

  late DateTime createdAt;
  late DateTime updatedAt;
}
