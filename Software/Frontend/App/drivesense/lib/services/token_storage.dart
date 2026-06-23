import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/isar_service.dart';
import 'package:drivesense/services/jwt_identity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists authentication tokens and mirrors them into RuntimeStore.
///
/// Secure storage is the source of truth across app restarts. RuntimeStore is
/// updated whenever tokens or the selected profile change so services can build
/// request headers without reading secure storage on every call.
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

  /// Hydrates RuntimeStore from secure storage during app startup.
  Future<void> loadIntoRuntimeStore() async {
    // Restore secure-storage tokens into the in-memory store before services
    // build authenticated headers.
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

  /// Saves the account token and clears local trip data when the account
  /// changes on the same device.
  Future<void> saveAccountToken(String token) async {
    await _clearLocalTripsIfAccountChanged(token);
    RuntimeStore.setAuthToken(token);
    await _storage.write(key: _accountTokenKey, value: token);
  }

  /// Saves the refresh token used to renew the account token.
  Future<void> saveRefreshToken(String token) async {
    RuntimeStore.setRefreshToken(token);
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Saves a fresh account session and clears any previously selected profile,
  /// because profile tokens belong to the old account session.
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

  /// Persists the active profile context used for authenticated API calls.
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

  /// Clears only the profile token and selection, leaving the account session.
  Future<void> clearProfile() async {
    RuntimeStore.clearActiveProfile();
    await Future.wait(<Future<void>>[
      _storage.delete(key: _profileTokenKey),
      _storage.delete(key: _profileIdKey),
      _storage.delete(key: _profileRoleKey),
    ]);
  }

  /// Clears every persisted token and resets the in-memory session.
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
    // Local trip data belongs to one account. When a different user signs in on
    // the same device, drop drafts and cached trips before storing new tokens.
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
