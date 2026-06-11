import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:drivesense/services/jwt_identity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _accountTokenKey = 'accountToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _profileTokenKey = 'profileToken';
  static const String _profileIdKey = 'profileId';
  static const String _profileRoleKey = 'profileRole';
  static const String _localDataAccountIdKey = 'localDataAccountId';

  Future<void> loadIntoRuntimeStore() async {
    final String accountToken = await readAccountToken() ?? '';
    final String refreshToken = await readRefreshToken() ?? '';
    final String? profileToken = await readProfileToken();
    final int? profileId = await readProfileId();
    final String? profileRole = await readProfileRole();

    RuntimeStore.setAuthToken(accountToken);
    RuntimeStore.setRefreshToken(refreshToken);

    if (profileId != null && profileId > 0) {
      RuntimeStore.setActiveProfile(
        profileId: profileId,
        profileToken: profileToken,
        profileRole: profileRole,
      );
    }
  }

  Future<String?> readAccountToken() => _storage.read(key: _accountTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readProfileToken() => _storage.read(key: _profileTokenKey);

  Future<String?> readProfileRole() => _storage.read(key: _profileRoleKey);

  Future<int?> readLocalDataAccountId() async {
    final String? raw = await _storage.read(key: _localDataAccountIdKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  Future<int?> readProfileId() async {
    final String? raw = await _storage.read(key: _profileIdKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  Future<void> saveAccountToken(String token) async {
    await _clearLocalTripsIfAccountChanged(token);
    RuntimeStore.setAuthToken(token);
    await _storage.write(key: _accountTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    RuntimeStore.setRefreshToken(token);
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> saveLoginTokens({
    required String accountToken,
    required String refreshToken,
  }) async {
    await Future.wait(<Future<void>>[
      saveAccountToken(accountToken),
      saveRefreshToken(refreshToken),
      clearProfile(),
    ]);
  }

  Future<void> saveSelectedProfile({
    required int profileId,
    required String profileToken,
    String? profileRole,
  }) async {
    RuntimeStore.setActiveProfile(
      profileId: profileId,
      profileToken: profileToken,
      profileRole: profileRole,
    );

    await Future.wait(<Future<void>>[
      _storage.write(key: _profileIdKey, value: profileId.toString()),
      _storage.write(key: _profileTokenKey, value: profileToken),
      if (profileRole == null || profileRole.trim().isEmpty)
        _storage.delete(key: _profileRoleKey)
      else
        _storage.write(key: _profileRoleKey, value: profileRole.trim()),
    ]);
  }

  Future<void> clearProfile() async {
    RuntimeStore.clearActiveProfile();
    await Future.wait(<Future<void>>[
      _storage.delete(key: _profileTokenKey),
      _storage.delete(key: _profileIdKey),
      _storage.delete(key: _profileRoleKey),
    ]);
  }

  Future<void> clearSession() async {
    RuntimeStore.clearSession();
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accountTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _profileTokenKey),
      _storage.delete(key: _profileIdKey),
      _storage.delete(key: _profileRoleKey),
    ]);
  }

  Future<void> _clearLocalTripsIfAccountChanged(String accountToken) async {
    final int? nextAccountId = JwtIdentity.accountIdFromToken(accountToken);
    if (nextAccountId == null || nextAccountId <= 0) {
      return;
    }

    final String? previousToken = await readAccountToken();
    final int? previousTokenAccountId = JwtIdentity.accountIdFromToken(
      previousToken,
    );
    final int? previousLocalDataAccountId = await readLocalDataAccountId();
    final int? previousAccountId =
        previousLocalDataAccountId ?? previousTokenAccountId;

    if (previousAccountId != null &&
        previousAccountId > 0 &&
        previousAccountId != nextAccountId) {
      await IsarService.clearLocalTripData();
    }

    await _storage.write(
      key: _localDataAccountIdKey,
      value: nextAccountId.toString(),
    );
  }
}
