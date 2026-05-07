import 'package:drivesense/model/active_trip.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:isar/isar.dart';

class ActiveTripRepository {
  Future<ActiveTrip?> getActive() async {
    final isar = await IsarService.getInstance();
    return isar.activeTrips.where().findFirst();
  }

  Future<void> save(ActiveTrip activeTrip) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.activeTrips.clear();
      await isar.activeTrips.put(activeTrip);
    });
  }

  Future<void> update(ActiveTrip activeTrip) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.activeTrips.put(activeTrip);
    });
  }

  Future<void> clear() async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.activeTrips.clear();
    });
  }
}
