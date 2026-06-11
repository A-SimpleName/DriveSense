import 'package:drivesense/model/trip.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:isar/isar.dart';

class TripRepository {
  static const String syncInProgressMarker = '__sync_in_progress__';
  static const Duration syncInProgressTimeout = Duration(minutes: 5);

  Future<void> save(Trip trip) async {
    final isar = await IsarService.getInstance();
    trip.accountId = _requireAccountId(trip.accountId);
    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });
  }

  Future<List<Trip>> getAll() async {
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return <Trip>[];
    }

    final isar = await IsarService.getInstance();
    return isar.trips.filter().accountIdEqualTo(accountId).findAll();
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
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return <Trip>[];
    }

    final isar = await IsarService.getInstance();
    return isar.trips
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .profileIdEqualTo(profileId)
        .and()
        .protocolIdEqualTo(protocolId)
        .findAll();
  }

  Future<List<Trip>> getUnsynced() async {
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return <Trip>[];
    }

    final isar = await IsarService.getInstance();
    final List<Trip> unsyncedTrips = await isar.trips
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .isSyncedEqualTo(false)
        .findAll();
    final DateTime now = DateTime.now();

    return unsyncedTrips.where((Trip trip) {
      if (trip.lastError != syncInProgressMarker) {
        return true;
      }

      return now.difference(trip.createdAt) >= syncInProgressTimeout;
    }).toList();
  }

  Future<Trip?> getByLocalId(String localId) async {
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return null;
    }

    final isar = await IsarService.getInstance();
    return isar.trips
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .localIdEqualTo(localId)
        .findFirst();
  }

  Future<Trip?> getById(Id id) async {
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return null;
    }

    final isar = await IsarService.getInstance();
    final Trip? trip = await isar.trips.get(id);
    if (trip == null || trip.accountId != accountId) {
      return null;
    }
    return trip;
  }

  Future<void> deleteById(Id id) async {
    final isar = await IsarService.getInstance();
    final Trip? trip = await getById(id);
    if (trip == null) {
      return;
    }

    await isar.writeTxn(() async {
      await isar.trips.delete(id);
    });
  }

  Future<void> update(Trip trip) async {
    final isar = await IsarService.getInstance();
    trip.accountId = _requireAccountId(trip.accountId);
    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });
  }

  Future<void> deleteSyncedByProfileAndProtocolExceptServerIds({
    required int profileId,
    required int protocolId,
    required Set<int> serverIds,
  }) async {
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return;
    }

    final isar = await IsarService.getInstance();
    final List<Trip> cachedTrips = await isar.trips
        .filter()
        .accountIdEqualTo(accountId)
        .and()
        .profileIdEqualTo(profileId)
        .and()
        .protocolIdEqualTo(protocolId)
        .and()
        .isSyncedEqualTo(true)
        .findAll();

    final List<Id> staleIds = cachedTrips
        .where((Trip trip) {
          final int? serverId = _serverIdFromLocalId(trip.localId);
          return serverId == null || !serverIds.contains(serverId);
        })
        .map((Trip trip) => trip.id)
        .toList();

    if (staleIds.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      await isar.trips.deleteAll(staleIds);
    });
  }

  Future<void> deleteAll() async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.trips.clear();
    });
  }

  int? _currentAccountId() {
    final int? accountId = LocalAccountScope.accountId;
    if (accountId == null || accountId <= 0) {
      return null;
    }
    return accountId;
  }

  int _requireAccountId(int existingAccountId) {
    final int accountId = LocalAccountScope.requireAccountId();
    if (existingAccountId > 0) {
      if (existingAccountId != accountId) {
        throw StateError('Lokale Fahrt gehoert zu einem anderen Account.');
      }
      return existingAccountId;
    }
    return accountId;
  }

  int? _serverIdFromLocalId(String localId) {
    final List<String> parts = localId.split(':');
    if (parts.length == 3 && parts[0] == 'server') {
      return int.tryParse(parts[2]);
    }
    if (parts.length == 2 && parts[0] == 'server') {
      return int.tryParse(parts[1]);
    }
    return null;
  }
}
