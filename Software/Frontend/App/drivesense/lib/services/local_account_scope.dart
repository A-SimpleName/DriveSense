class LocalAccountScope {
  LocalAccountScope._();

  static int? accountId;

  static int requireAccountId() {
    final int? currentAccountId = accountId;
    if (currentAccountId == null || currentAccountId <= 0) {
      throw StateError('Kein Account-Kontext für lokale Fahrtdaten.');
    }
    return currentAccountId;
  }
}
