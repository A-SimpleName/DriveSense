import 'package:drivesense/model/active_trip.dart';
import 'package:drivesense/services/local_account_scope.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:isar/isar.dart';

class ActiveTripRepository {
  Future<ActiveTrip?> getActive({bool allowUnscoped = false}) async {
    final isar = await IsarService.getInstance();
    final int? accountId = _currentAccountId();
    if (accountId == null) {
      if (!allowUnscoped) {
        return null;
      }
      final ActiveTrip? activeTrip = await isar.activeTrips.where().findFirst();
      if (activeTrip == null || activeTrip.accountId <= 0) {
        return null;
      }
      return activeTrip;
    }

    return isar.activeTrips.filter().accountIdEqualTo(accountId).findFirst();
  }

  Future<void> save(ActiveTrip activeTrip) async {
    final isar = await IsarService.getInstance();
    activeTrip.accountId = _requireAccountId(activeTrip.accountId);
    await isar.writeTxn(() async {
      await isar.activeTrips.clear();
      await isar.activeTrips.put(activeTrip);
    });
  }

  Future<void> update(ActiveTrip activeTrip) async {
    final isar = await IsarService.getInstance();
    activeTrip.accountId = _requireAccountId(activeTrip.accountId);
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

  int? _currentAccountId() {
    final int? accountId = LocalAccountScope.accountId;
    if (accountId == null || accountId <= 0) {
      return null;
    }
    return accountId;
  }

  int _requireAccountId(int existingAccountId) {
    final int? currentAccountId = _currentAccountId();
    if (existingAccountId > 0) {
      if (currentAccountId != null && existingAccountId != currentAccountId) {
        throw StateError('Aktive Fahrt gehoert zu einem anderen Account.');
      }
      return existingAccountId;
    }
    return LocalAccountScope.requireAccountId();
  }
}
