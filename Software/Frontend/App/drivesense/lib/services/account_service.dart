import 'dart:convert';
import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/account.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:flutter/foundation.dart';

class AccountService {
  AccountService._();

  static Future<Account?> fetchAccount() async {
    final headers = RequestHeaders.authenticated(
      clientType: 'mobile',
      includeProfileToken: false,
    );

    if (!headers.containsKey('Cookie')) return null;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/account/me');

    try {
      final response = await http.get(uri, headers: headers);

      debugPrint('Account <- ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body);

      return Account.fromJson(data);
    } catch (e) {
      debugPrint('Account fetch failed: $e');
      return null;
    }
  }

  static Future<Account?> updateAccount({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final headers = RequestHeaders.authenticated(
      clientType: 'mobile',
      includeProfileToken: false,
    );

    if (!headers.containsKey('Cookie')) return null;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/account');

    try {
      final response = await http.put(
        uri,
        headers: <String, String>{
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        }),
      );

      debugPrint('Account update <- ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body);

      return Account.fromJson(data);
    } catch (e) {
      debugPrint('Account update failed: $e');
      return null;
    }
  }

  static Future<String?> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final headers = RequestHeaders.authenticatedJson(
      clientType: 'mobile',
      includeProfileToken: false,
    );

    if (!headers.containsKey('Cookie')) return 'Keine aktive Sitzung gefunden';

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/account/password');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(<String, String>{
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      debugPrint('Account password update <- ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }

      return _extractErrorMessage(response.body) ??
          'Passwort konnte nicht geaendert werden';
    } catch (e) {
      debugPrint('Account password update failed: $e');
      return 'Passwort konnte nicht geaendert werden';
    }
  }

  static Future<String?> deleteAccount() async {
    final headers = RequestHeaders.authenticated(
      clientType: 'mobile',
      includeProfileToken: false,
    );

    if (!headers.containsKey('Cookie')) return 'Keine aktive Sitzung gefunden';

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/account');

    try {
      final response = await http.delete(uri, headers: headers);

      debugPrint('Account delete <- ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }

      return _extractErrorMessage(response.body) ??
          'Account konnte nicht geloescht werden';
    } catch (e) {
      debugPrint('Account delete failed: $e');
      return 'Account konnte nicht geloescht werden';
    }
  }

  static Future<String?> requestPasswordReset(String email) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/account/forgot-password',
    );

    try {
      final response = await http.post(
        uri,
        headers: RequestHeaders.json(clientType: 'mobile'),
        body: jsonEncode(<String, String>{'email': email}),
      );

      debugPrint('Account forgot-password <- ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }

      return _extractErrorMessage(response.body) ??
          'Code konnte nicht gesendet werden';
    } catch (e) {
      debugPrint('Account forgot-password failed: $e');
      return 'Code konnte nicht gesendet werden';
    }
  }

  static Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/account/reset-password',
    );

    try {
      final response = await http.post(
        uri,
        headers: RequestHeaders.json(clientType: 'mobile'),
        body: jsonEncode(<String, String>{
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      debugPrint('Account reset-password <- ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }

      return _extractErrorMessage(response.body) ??
          'Passwort konnte nicht zurückgesetzt werden';
    } catch (e) {
      debugPrint('Account reset-password failed: $e');
      return 'Passwort konnte nicht zurückgesetzt werden';
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
      // Fall back to raw body below.
    }

    return body.trim();
  }
}
