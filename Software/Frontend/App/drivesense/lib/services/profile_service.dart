import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/service_error_messages.dart';
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

class ProfileFetchResult {
  final bool isSuccess;
  final List<Profile> profiles;
  final String? message;

  const ProfileFetchResult({
    required this.isSuccess,
    required this.profiles,
    this.message,
  });
}

class ProfileService {
  ProfileService._();

  static Future<List<Profile>> fetchProfiles() async {
    final ProfileFetchResult result = await fetchProfilesWithResult();
    return result.isSuccess ? result.profiles : <Profile>[];
  }

  static Future<ProfileFetchResult> fetchProfilesWithResult() async {
    final Map<String, String> headers = RequestHeaders.authenticated(
      clientType: 'mobile',
      includeProfileToken: false,
    );
    if (!headers.containsKey('Cookie')) {
      return const ProfileFetchResult(
        isSuccess: false,
        profiles: <Profile>[],
        message: 'Kein Account-Token vorhanden. Bitte erneut einloggen.',
      );
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles/byAccount');

    try {
      final http.Response response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('FetchProfiles <- ${response.statusCode} $uri');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ProfileFetchResult(
          isSuccess: false,
          profiles: const <Profile>[],
          message: ServiceErrorMessages.forHttpStatus(
            statusCode: response.statusCode,
            action: 'Profile konnten nicht geladen werden',
            responseBody: response.body,
          ),
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      return ProfileFetchResult(
        isSuccess: true,
        profiles: _extractProfiles(decoded),
      );
    } on TimeoutException catch (e) {
      debugPrint('FetchProfiles timed out at $uri: $e');
      return const ProfileFetchResult(
        isSuccess: false,
        profiles: <Profile>[],
        message:
            'Profile konnten nicht geladen werden. Bitte Internetverbindung prüfen.',
      );
    } on SocketException catch (e) {
      debugPrint('FetchProfiles network failed at $uri: $e');
      return const ProfileFetchResult(
        isSuccess: false,
        profiles: <Profile>[],
        message:
            'Profile konnten nicht geladen werden. Bitte Internetverbindung prüfen.',
      );
    } catch (e) {
      debugPrint('FetchProfiles failed at $uri: $e');
      return ProfileFetchResult(
        isSuccess: false,
        profiles: <Profile>[],
        message: ServiceErrorMessages.forException(
          e,
          action: 'Profile konnten nicht geladen werden',
        ),
      );
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
        message: 'Kein Profil-Token vorhanden. Bitte Profil erneut auswählen.',
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
          message: ServiceErrorMessages.forHttpStatus(
            statusCode: response.statusCode,
            action: 'Profilname konnte nicht gespeichert werden',
            responseBody: response.body,
          ),
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
      return ProfileMutationResponse(
        isSuccess: false,
        message: ServiceErrorMessages.forException(
          e,
          action: 'Profilname konnte nicht gespeichert werden',
        ),
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
        message: 'Kein Profil-Token vorhanden. Bitte Profil erneut auswählen.',
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
          message: ServiceErrorMessages.forHttpStatus(
            statusCode: response.statusCode,
            action: 'Profil konnte nicht gelöscht werden',
            responseBody: response.body,
          ),
        );
      }

      return const ProfileMutationResponse(
        isSuccess: true,
        message: 'Profil wurde entfernt.',
      );
    } catch (e) {
      debugPrint('DeleteProfile failed at $uri: $e');
      return ProfileMutationResponse(
        isSuccess: false,
        message: ServiceErrorMessages.forException(
          e,
          action: 'Profil konnte nicht gelöscht werden',
        ),
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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SelectProfileResponse(
          isSuccess: false,
          message: _selectProfileFailureMessage(
            statusCode: response.statusCode,
            responseBody: response.body,
          ),
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
          message:
              'Die Serverantwort war unvollständig. Bitte erneut versuchen.',
        );
      }

      try {
        await TokenStorage.instance.saveSelectedProfile(
          profileId: profile?.id ?? profileId,
          profileToken: profileToken,
          profileRole: profile?.role,
        );
        await RuntimeStore.refreshTrips();
      } catch (e) {
        debugPrint('SelectProfile post-processing failed at $uri: $e');
        return const SelectProfileResponse(
          isSuccess: false,
          message:
              'Das Profil wurde ausgewählt, aber die App konnte nicht aktualisiert werden. Bitte erneut versuchen.',
        );
      }

      return SelectProfileResponse(
        isSuccess: true,
        message: 'Profil erfolgreich ausgewählt.',
        profile: profile,
        profileToken: profileToken,
      );
    } on TimeoutException {
      return const SelectProfileResponse(
        isSuccess: false,
        message:
            'Der Profilwechsel dauert zu lange. Bitte Internetverbindung prüfen und erneut versuchen.',
      );
    } on SocketException {
      return const SelectProfileResponse(
        isSuccess: false,
        message:
            'Keine Verbindung zum Server. Bitte Internetverbindung prüfen und erneut versuchen.',
      );
    } on http.ClientException catch (e) {
      debugPrint('SelectProfile HTTP client failure at $uri: $e');
      return SelectProfileResponse(
        isSuccess: false,
        message: _selectProfileClientFailureMessage(e),
      );
    } catch (e) {
      debugPrint('SelectProfile failed at $uri: $e');
      return SelectProfileResponse(
        isSuccess: false,
        message:
            'Das Profil konnte nicht ausgewählt werden. Bitte später erneut versuchen.',
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
    return ServiceErrorMessages.extractServerMessage(rawBody);
  }

  static String _selectProfileFailureMessage({
    required int statusCode,
    required String responseBody,
  }) {
    final String? serverMessage = _extractServerMessage(responseBody);
    if (serverMessage != null) {
      return serverMessage;
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Die Anmeldung ist abgelaufen oder die Auswahl ist nicht erlaubt. Bitte erneut einloggen.';
    }

    if (statusCode == 404) {
      return 'Das ausgewählte Profil wurde nicht gefunden.';
    }

    if (statusCode == 400 || statusCode == 409) {
      return 'Das Profil konnte gerade nicht gewechselt werden. Bitte erneut versuchen.';
    }

    if (statusCode >= 500) {
      return 'Der Server ist momentan nicht erreichbar. Bitte später erneut versuchen.';
    }

    return 'Das Profil konnte nicht ausgewahlt werden. Bitte erneut versuchen.';
  }

  static String _selectProfileClientFailureMessage(http.ClientException error) {
    final String message = error.message.toLowerCase();

    if (_looksLikeOfflineError(message)) {
      return 'Keine Verbindung zum Server. Bitte Internetverbindung prüfen und erneut versuchen.';
    }

    if (_looksLikeTimeoutError(message)) {
      return 'Der Profilwechsel dauert zu lange. Bitte Verbindung prüfen und erneut versuchen.';
    }

    if (_looksLikeTlsError(message)) {
      return 'Die sichere Verbindung zum Server ist fehlgeschlagen. Bitte später erneut versuchen.';
    }

    return 'Der Profilwechsel konnte nicht abgeschlossen werden. Bitte erneut versuchen.';
  }

  static bool _looksLikeOfflineError(String message) {
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connectionerror') ||
        message.contains('network is unreachable') ||
        message.contains('connection errored') ||
        message.contains('connection refused') ||
        message.contains('no address associated with hostname') ||
        message.contains('software caused connection abort');
  }

  static bool _looksLikeTimeoutError(String message) {
    return message.contains('timeout') ||
        message.contains('connection timed out') ||
        message.contains('receivetimeout') ||
        message.contains('sendtimeout') ||
        message.contains('connectiontimeout');
  }

  static bool _looksLikeTlsError(String message) {
    return message.contains('certificate') ||
        message.contains('badcertificate') ||
        message.contains('handshake') ||
        message.contains('tls') ||
        message.contains('ssl');
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
