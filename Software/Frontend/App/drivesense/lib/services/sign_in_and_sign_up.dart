import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drivesense/constants/api_config.dart';
import 'package:drivesense/model/account.dart';
import 'package:drivesense/model/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SignUpResult {
  final bool isSuccess;
  final String message;
  final int? statusCode;

  const SignUpResult({
    required this.isSuccess,
    required this.message,
    this.statusCode,
  });
}

class SignInResult {
  final bool isSuccess;
  final String? accountToken;
  final String? refreshToken;
  final List<Profile> profiles;
  final String message;
  final int? statusCode;

  const SignInResult({
    required this.isSuccess,
    required this.message,
    this.accountToken,
    this.refreshToken,
    this.profiles = const <Profile>[],
    this.statusCode,
  });
}

class SignInAndSignUp {
  SignInAndSignUp._();

  static Future<SignUpResult> signUp(Account account) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/account/signUp');
    final Map<String, dynamic> payload = account.toJson();

    debugPrint('SignUp request -> url=$uri');
    debugPrint('SignUp payload -> $payload');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final int statusCode = response.statusCode;
      debugPrint(
        'SignUp response <- status=$statusCode, body=${response.body}',
      );
      final Map<String, dynamic>? body = _parseJsonObject(response.body);

      if (statusCode >= 200 && statusCode < 300) {
        return SignUpResult(
          isSuccess: true,
          message: 'Registrierung erfolgreich.',
          statusCode: statusCode,
        );
      }

      if (statusCode == 401) {
        return SignUpResult(
          isSuccess: false,
          message:
              '401 Unauthorized: SignUp-Endpoint ist durch Security geschützt oder URL/Method passt nicht.',
          statusCode: statusCode,
        );
      }

      if (statusCode == 403) {
        return SignUpResult(
          isSuccess: false,
          message:
              '403 Forbidden: Backend blockiert den Aufruf (oft CSRF/CORS/Security-Rule).',
          statusCode: statusCode,
        );
      }

      return SignUpResult(
        isSuccess: false,
        message: 'Registrierung fehlgeschlagen (HTTP $statusCode).',
        statusCode: statusCode,
      );
    } on TimeoutException {
      return const SignUpResult(
        isSuccess: false,
        message:
            'Zeitueberschreitung bei der Registrierung. Bitte erneut versuchen.',
      );
    } on SocketException {
      return const SignUpResult(
        isSuccess: false,
        message: 'Keine Netzwerkverbindung. Bitte Internetverbindung pruefen.',
      );
    } on http.ClientException {
      return const SignUpResult(
        isSuccess: false,
        message: 'Verbindungsfehler beim Senden der Registrierung.',
      );
    } catch (_) {
      return const SignUpResult(
        isSuccess: false,
        message: 'Unerwarteter Fehler bei der Registrierung.',
      );
    }
  }

  static Map<String, dynamic>? _parseJsonObject(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(rawBody);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<SignInResult> signIn(String email, String password) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/account/login');
    final Map<String, String> payload = {'email': email, 'password': password};

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'X-Client-Type': 'mobile',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic>? body = _parseJsonObject(response.body);
        final String? accountToken = _extractAccountToken(body);
        final String? refreshToken = _extractRefreshToken(body);
        final List<Profile> profiles = _extractProfiles(body);

        return SignInResult(
          isSuccess: true,
          accountToken: accountToken,
          refreshToken: refreshToken,
          profiles: profiles,
          message: 'Login erfolgreich.',
          statusCode: response.statusCode,
        );
      } else {
        return SignInResult(
          isSuccess: false,
          message: 'Login fehlgeschlagen (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return SignInResult(isSuccess: false, message: 'Fehler beim Login: $e');
    }
  }

  static String? _extractAccountToken(Map<String, dynamic>? body) {
    if (body == null) {
      return null;
    }

    final dynamic token = body['accountToken'];
    return token is String && token.isNotEmpty ? token : null;
  }

  static String? _extractRefreshToken(Map<String, dynamic>? body) {
    if (body == null) {
      return null;
    }

    final dynamic token = body['refreshToken'];
    return token is String && token.isNotEmpty ? token : null;
  }

  static List<Profile> _extractProfiles(Map<String, dynamic>? body) {
    if (body == null) {
      return <Profile>[];
    }

    final dynamic profilesValue = body['profiles'];
    if (profilesValue is! List) {
      return <Profile>[];
    }

    return profilesValue
        .whereType<Map<String, dynamic>>()
        .map(Profile.fromJson)
        .where((Profile profile) => profile.id > 0)
        .toList();
  }

  static String redirectToProfileSelectPage({String? token}) {
    return token == null || token.isEmpty ? 'SignInPage' : 'ProfileSelectPage';
  }
}
