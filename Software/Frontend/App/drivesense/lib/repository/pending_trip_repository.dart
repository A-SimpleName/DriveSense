import 'package:drivesense/model/pending_trip.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:isar/isar.dart';

class PendingTripRepository {
  Future<void> save(PendingTrip trip) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTrips.put(trip);
    });
  }

  Future<List<PendingTrip>> getAll() async {
    final isar = await IsarService.getInstance();
    return isar.pendingTrips.where().findAll();
  }

  Future<PendingTrip?> getByLocalId(String localId) async {
    final isar = await IsarService.getInstance();
    return isar.pendingTrips.filter().localIdEqualTo(localId).findFirst();
  }

  Future<void> deleteById(Id id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTrips.delete(id);
    });
  }

  Future<void> update(PendingTrip trip) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTrips.put(trip);
    });
  }
}