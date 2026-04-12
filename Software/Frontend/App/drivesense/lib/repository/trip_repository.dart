import 'package:drivesense/model/trip.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:isar/isar.dart';

class TripRepository {
  Future<void> save(Trip trip) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });
  }

  Future<List<Trip>> getAll() async {
    final isar = await IsarService.getInstance();
    return isar.trips.where().findAll();
  }

  Future<List<Trip>> getUnsynced() async {
    final isar = await IsarService.getInstance();
    return isar.trips.filter().isSyncedEqualTo(false).findAll();
  }

  Future<Trip?> getByLocalId(String localId) async {
    final isar = await IsarService.getInstance();
    return isar.trips.filter().localIdEqualTo(localId).findFirst();
  }

  Future<void> deleteById(Id id) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.trips.delete(id);
    });
  }

  Future<void> update(Trip trip) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });
  }
}