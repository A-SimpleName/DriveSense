import 'package:drivesense/model/trip.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:isar/isar.dart';

/// Account-scoped Isar repository for completed trip drafts and cached trips.
///
/// Finished trips are written locally before upload. Unsynced rows remain here
/// until TripSyncService can upload them and replace their local id with the
/// server-backed identity.
class TripRepository {
  /// Temporary marker used while a newly finished trip is being uploaded.
  static const String syncInProgressMarker = '__sync_in_progress__';

  /// Age after which an interrupted in-progress sync may be retried.
  static const Duration syncInProgressTimeout = Duration(minutes: 5);

  /// Saves a new trip for the active account.
  Future<void> save(Trip trip) async {
    final isar = await IsarService.getInstance();
    trip.accountId = _requireAccountId(trip.accountId);
    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });
  }

  /// Returns all trips belonging to the active account.
  Future<List<Trip>> getAll() async {
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      return <Trip>[];
    }

    final isar = await IsarService.getInstance();
    return isar.trips.filter().accountIdEqualTo(accountId).findAll();
  }

  /// Returns the newest completed trip, optionally filtered by profile/protocol.
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

  /// Returns trips for one profile/protocol pair in the active account.
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

  /// Returns unsynced trips that are ready for retry.
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

  /// Looks up a trip by its stable local/server identity string.
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

  /// Reads a trip by Isar id, rejecting rows from another account.
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

  /// Deletes a trip by Isar id when it belongs to the active account.
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

  /// Persists updates to a trip for the active account.
  Future<void> update(Trip trip) async {
    final isar = await IsarService.getInstance();
    trip.accountId = _requireAccountId(trip.accountId);
    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });
  }

  /// Removes stale synced cache rows that are no longer present on the server.
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

  /// Clears all locally stored trips.
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
