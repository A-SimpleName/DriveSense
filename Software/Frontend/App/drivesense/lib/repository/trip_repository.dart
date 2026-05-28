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

  Future<Trip?> getLatestCompleted({int? profileId, int? protocolId}) async {
    final List<Trip> trips = await getAll();
    final List<Trip> completedTrips = trips.where((Trip trip) {
      if (trip.endTime == null) {
        return false;
      }
      if (profileId != null && trip.profileId != profileId) {
        return false;
      }
      if (protocolId != null &&
          protocolId > 0 &&
          trip.protocolId != protocolId) {
        return false;
      }
      return true;
    }).toList();

    if (completedTrips.isEmpty) {
      return null;
    }

    completedTrips.sort((Trip a, Trip b) {
      final DateTime aTime = a.endTime ?? a.startTime;
      final DateTime bTime = b.endTime ?? b.startTime;
      return bTime.compareTo(aTime);
    });
    return completedTrips.first;
  }

  Future<List<Trip>> getByProfileAndProtocol(
    int profileId,
    int protocolId,
  ) async {
    final isar = await IsarService.getInstance();
    return isar.trips
        .filter()
        .profileIdEqualTo(profileId)
        .and()
        .protocolIdEqualTo(protocolId)
        .findAll();
  }

  Future<List<Trip>> getUnsynced() async {
    final isar = await IsarService.getInstance();
    return isar.trips.filter().isSyncedEqualTo(false).findAll();
  }

  Future<Trip?> getByLocalId(String localId) async {
    final isar = await IsarService.getInstance();
    return isar.trips.filter().localIdEqualTo(localId).findFirst();
  }

  Future<Trip?> getById(Id id) async {
    final isar = await IsarService.getInstance();
    return isar.trips.get(id);
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

  Future<void> deleteAll() async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.trips.clear();
    });
  }
}
