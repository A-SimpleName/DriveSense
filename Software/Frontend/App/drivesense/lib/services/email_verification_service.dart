import 'dart:convert';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:flutter/foundation.dart';

class EmailVerificationService {
  EmailVerificationService._();

  static Future<String?> verifySignupEmail({
    required String email,
    required String code,
  }) async {
    return _postJson('/api/account/verify-email', <String, String>{
      'email': email,
      'code': code,
    });
  }

  static Future<String?> resendSignupVerification(String email) async {
    return _postJson('/api/account/resend-verification', <String, String>{
      'email': email,
    });
  }

  static Future<String?> confirmEmailChange(String code) async {
    return _postJson('/api/account/confirm-email-change', <String, String>{
      'code': code,
    }, authenticated: true);
  }

  static Future<String?> requestEmailChange(String newEmail) async {
    return _postJson('/api/account/change-email', <String, String>{
      'newEmail': newEmail,
    }, authenticated: true);
  }

  static Future<String?> _postJson(
    String path,
    Map<String, String> body, {
    bool authenticated = false,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      final http.Response response = await http.post(
        uri,
        headers: authenticated
            ? RequestHeaders.authenticatedJson(clientType: 'mobile')
            : RequestHeaders.json(clientType: 'mobile'),
        body: jsonEncode(body),
      );

      debugPrint('Email verification request <- ${response.statusCode} $uri');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }

      return _extractErrorMessage(response.body) ??
          'Die Bestätigung konnte nicht verarbeitet werden.';
    } catch (e) {
      debugPrint('Email verification request failed: $e');
      return 'Die Bestätigung konnte nicht verarbeitet werden.';
    }
  }

  static String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Fall back to the raw body below.
    }

    return body.trim();
  }
}
