import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/model/profile.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/protocol_service.dart';
import 'package:drivesense/services/vehicle_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

class ProfileService {
  ProfileService._();

  static Map<String, String> _authHeaders() {
    final String? cookieHeader = RuntimeStore.getCookieHeader();
    return <String, String>{
      'Content-Type': 'application/json',
      'X-Client-Type': 'mobile',
      ..._cookieHeaders(cookieHeader),
    };
  }

  static Future<List<Profile>> fetchProfiles() async {
    final String? cookieHeader = RuntimeStore.getCookieHeader(
      includeProfileToken: false,
    );
    if (cookieHeader == null) {
      return <Profile>[];
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles/byAccount');

    try {
      final http.Response response = await http
          .get(uri, headers: _authHeaders())
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

  static Future<Profile?> createDefaultStudentProfile() async {
    final String? cookieHeader = RuntimeStore.getCookieHeader(
      includeProfileToken: false,
    );
    if (cookieHeader == null) {
      return null;
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/profiles');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode(<String, dynamic>{
              'name': 'Fahrschüler',
              'role': 'FAHRSCHÜLER',
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'CreateDefaultProfile <- status=${response.statusCode}, uri=$uri, body=${response.body}',
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
      debugPrint('CreateDefaultProfile failed at $uri: $e');
    }

    return null;
  }

  static Future<SelectProfileResponse> selectProfile(int profileId) async {
    final String? cookieHeader = RuntimeStore.getCookieHeader(
      includeProfileToken: false,
    );
    if (cookieHeader == null) {
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
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode(<String, dynamic>{}),
          )
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

      RuntimeStore.setActiveProfile(
        profileId: profile?.id ?? profileId,
        profileToken: profileToken,
      );
      final int activeProfileId = profile?.id ?? profileId;
      await ProtocolService.ensureDefaultProtocolForActiveProfile();
      await VehicleService.ensureDefaultVehicleForActiveProfile(activeProfileId);
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

  static Future<SelectProfileResponse> selectFirstProfileAsDefault() async {
    final List<Profile> profiles = await fetchProfiles();
    if (profiles.isEmpty) {
      return const SelectProfileResponse(
        isSuccess: false,
        message: 'Kein Profil verfuegbar.',
      );
    }

    final Profile first = profiles.first;
    return selectProfile(first.id);
  }

  static Future<SelectProfileResponse> ensureDefaultStudentProfile() async {
    final List<Profile> existingProfiles = await fetchProfiles();
    if (existingProfiles.isNotEmpty) {
      return selectProfile(existingProfiles.first.id);
    }

    final Profile? createdProfile = await createDefaultStudentProfile();
    if (createdProfile == null) {
      return const SelectProfileResponse(
        isSuccess: false,
        message: 'Default-Fahrschüler-Profil konnte nicht erstellt werden.',
      );
    }

    return selectProfile(createdProfile.id);
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

  static Map<String, String> _cookieHeaders(String? cookieHeader) {
    if (cookieHeader == null) {
      return const <String, String>{};
    }

    return <String, String>{'Cookie': cookieHeader};
  }
}
