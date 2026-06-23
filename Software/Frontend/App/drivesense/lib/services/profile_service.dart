import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/token_storage.dart';
import 'package:flutter/foundation.dart';

class SelectProfileResponse {
  final bool isSuccess;
  final String message;
  final Profile? profile;
  final String? profileToken;

  const SelectProfileResponse({
    required this.isSuccess,
    required this.message,
    this.profile,
    this.profileToken,
  });
}

class ProfileMutationResponse {
  final bool isSuccess;
  final String message;
  final Profile? profile;

  const ProfileMutationResponse({
    required this.isSuccess,
    required this.message,
    this.profile,
  });
}

class ProfileService {
  ProfileService._();

  static Future<List<Profile>> fetchProfiles() async {
    final Map<String, String> headers = RequestHeaders.authenticated(
      clientType: 'mobile',
      includeProfileToken: false,
    );
    if (!headers.containsKey('Cookie')) {
      return <Profile>[];
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles/byAccount');

    try {
      final http.Response response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('FetchProfiles <- ${response.statusCode} $uri');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <Profile>[];
      }

      final dynamic decoded = _decodeJson(response.body);
      return _extractProfiles(decoded);
    } catch (e) {
      debugPrint('FetchProfiles failed at $uri: $e');
      return <Profile>[];
    }
  }

  static Future<Profile?> createProfile({
    required String name,
    required String role,
  }) async {
    final Map<String, String> headers = RequestHeaders.authenticatedJson(
      clientType: 'mobile',
      includeProfileToken: false,
    );
    if (!headers.containsKey('Cookie')) {
      return null;
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(<String, dynamic>{
              'name': name.trim(),
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'CreateProfile <- status=${response.statusCode}, uri=$uri, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      final List<Profile> profiles = _extractProfiles(decoded);
      if (profiles.isNotEmpty) {
        return profiles.first;
      }
    } catch (e) {
      debugPrint('CreateProfile failed at $uri: $e');
    }

    return null;
  }

  static Future<ProfileMutationResponse> updateProfileName({
    required Profile profile,
    required String name,
  }) async {
    final Map<String, String> headers = RequestHeaders.authenticatedJson(
      clientType: 'mobile',
    );
    if (!headers.containsKey('Cookie')) {
      return const ProfileMutationResponse(
        isSuccess: false,
        message: 'Kein Profil-Token vorhanden. Bitte Profil erneut auswaehlen.',
      );
    }

    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/profiles/${profile.id}',
    );
    final String? role = profile.role ?? RuntimeStore.activeProfileRole;
    if (role == null || role.trim().isEmpty) {
      return const ProfileMutationResponse(
        isSuccess: false,
        message: 'Profiltyp konnte nicht ermittelt werden.',
      );
    }

    try {
      final http.Response response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(<String, dynamic>{
              'name': name.trim(),
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'UpdateProfileName <- status=${response.statusCode}, uri=$uri, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ProfileMutationResponse(
          isSuccess: false,
          message:
              _extractServerMessage(response.body) ??
              'Profilname konnte nicht gespeichert werden.',
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      final List<Profile> profiles = _extractProfiles(decoded);
      return ProfileMutationResponse(
        isSuccess: true,
        message: 'Profilname wurde gespeichert.',
        profile: profiles.isNotEmpty
            ? profiles.first
            : Profile(
                id: profile.id,
                name: name.trim(),
                role: role,
                accountId: profile.accountId,
              ),
      );
    } catch (e) {
      debugPrint('UpdateProfileName failed at $uri: $e');
      return const ProfileMutationResponse(
        isSuccess: false,
        message: 'Profilname konnte nicht gespeichert werden.',
      );
    }
  }

  static Future<ProfileMutationResponse> deleteProfile(int profileId) async {
    final Map<String, String> headers = RequestHeaders.authenticated(
      clientType: 'mobile',
    );
    if (!headers.containsKey('Cookie')) {
      return const ProfileMutationResponse(
        isSuccess: false,
        message: 'Kein Profil-Token vorhanden. Bitte Profil erneut auswaehlen.',
      );
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles/$profileId');

    try {
      final http.Response response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'DeleteProfile <- status=${response.statusCode}, uri=$uri, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ProfileMutationResponse(
          isSuccess: false,
          message:
              _extractServerMessage(response.body) ??
              'Profil konnte nicht geloescht werden.',
        );
      }

      return const ProfileMutationResponse(
        isSuccess: true,
        message: 'Profil wurde entfernt.',
      );
    } catch (e) {
      debugPrint('DeleteProfile failed at $uri: $e');
      return const ProfileMutationResponse(
        isSuccess: false,
        message: 'Profil konnte nicht geloescht werden.',
      );
    }
  }

  static Future<SelectProfileResponse> selectProfile(int profileId) async {
    final Map<String, String> headers = RequestHeaders.authenticatedJson(
      clientType: 'mobile',
      includeProfileToken: false,
    );
    if (!headers.containsKey('Cookie')) {
      return const SelectProfileResponse(
        isSuccess: false,
        message: 'Kein Account-Token vorhanden. Bitte erneut einloggen.',
      );
    }

    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/account/select-profile?profileId=$profileId',
    );

    try {
      debugPrint('SelectProfile request -> uri=$uri, id=$profileId');

      final http.Response response = await http
          .post(uri, headers: headers, body: jsonEncode(<String, dynamic>{}))
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'SelectProfile response <- status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return SelectProfileResponse(
          isSuccess: false,
          message:
              'Keine Berechtigung fuer Profilauswahl (HTTP ${response.statusCode}).',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SelectProfileResponse(
          isSuccess: false,
          message:
              'HTTP ${response.statusCode}: ${_extractServerMessage(response.body) ?? response.body}',
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      final Map<String, dynamic>? decodedBody = decoded is Map<String, dynamic>
          ? decoded
          : null;
      final String? profileToken = _extractProfileToken(decodedBody);
      final Profile? profile = _extractProfile(decodedBody);
      if (profileToken == null || profileToken.isEmpty) {
        return const SelectProfileResponse(
          isSuccess: false,
          message: 'Profil-Token fehlt in der Serverantwort.',
        );
      }

      await TokenStorage.instance.saveSelectedProfile(
        profileId: profile?.id ?? profileId,
        profileToken: profileToken,
        profileRole: profile?.role,
      );
      await RuntimeStore.refreshTrips();

      return SelectProfileResponse(
        isSuccess: true,
        message: 'Profil erfolgreich ausgewaehlt.',
        profile: profile,
        profileToken: profileToken,
      );
    } on TimeoutException {
      return const SelectProfileResponse(
        isSuccess: false,
        message: 'Timeout beim Profilwechsel.',
      );
    } on SocketException {
      return const SelectProfileResponse(
        isSuccess: false,
        message: 'Keine Netzwerkverbindung beim Profilwechsel.',
      );
    } on http.ClientException catch (e) {
      return SelectProfileResponse(
        isSuccess: false,
        message: 'HTTP-Clientfehler beim Profilwechsel: $e',
      );
    } catch (e) {
      return SelectProfileResponse(
        isSuccess: false,
        message: 'Unerwarteter Fehler beim Profilwechsel: $e',
      );
    }
  }

  static dynamic _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return null;
    }
  }

  static List<Profile> _extractProfiles(dynamic decoded) {
    if (decoded == null) {
      return <Profile>[];
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Profile.fromJson)
          .where((Profile profile) => profile.id > 0)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic listLike =
          decoded['profiles'] ?? decoded['items'] ?? decoded['data'];

      if (listLike is List) {
        return listLike
            .whereType<Map<String, dynamic>>()
            .map(Profile.fromJson)
            .where((Profile profile) => profile.id > 0)
            .toList();
      }

      final Profile single = Profile.fromJson(decoded);
      if (single.id > 0) {
        return <Profile>[single];
      }
    }

    return <Profile>[];
  }

  static String? _extractServerMessage(String rawBody) {
    final dynamic decoded = _decodeJson(rawBody);
    if (decoded is Map<String, dynamic>) {
      final dynamic message = decoded['message'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  static String? _extractProfileToken(Map<String, dynamic>? decodedBody) {
    if (decodedBody == null) {
      return null;
    }

    final dynamic token = decodedBody['profileToken'];
    return token is String && token.trim().isNotEmpty ? token.trim() : null;
  }

  static Profile? _extractProfile(Map<String, dynamic>? decodedBody) {
    if (decodedBody == null) {
      return null;
    }

    final dynamic profileValue = decodedBody['profile'];
    if (profileValue is Map<String, dynamic>) {
      final Profile profile = Profile.fromJson(profileValue);
      return profile.id > 0 ? profile : null;
    }

    return null;
  }
}
