import 'package:isar/isar.dart';

part 'pending_trip.g.dart';

@collection
class PendingTrip {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String localId;

  late String tripSummaryJson;
  late String trackingPointsJson;

  late DateTime createdAt;

  int retryCount = 0;
  String? lastError;
}