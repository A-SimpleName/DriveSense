import 'dart:convert';
import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/account.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/service_error_messages.dart';
import 'package:flutter/foundation.dart';

class AccountService {
  AccountService._();

  static Future<AccountLoadResult> fetchAccount() async {
    final headers = RequestHeaders.authenticated(
      clientType: 'mobile',
      includeProfileToken: false,
    );

    if (!headers.containsKey('Cookie')) {
      return const AccountLoadResult(
        message: 'Keine aktive Sitzung gefunden.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/account/me');

    try {
      final response = await http.get(uri, headers: headers);

      debugPrint('Account <- ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AccountLoadResult(
          message: ServiceErrorMessages.forHttpStatus(
            statusCode: response.statusCode,
            action: 'Account konnte nicht geladen werden',
            responseBody: response.body,
          ),
        );
      }

      final data = jsonDecode(response.body);

      return AccountLoadResult(account: Account.fromJson(data));
    } catch (e) {
      debugPrint('Account fetch failed: $e');
      return AccountLoadResult(
        message: ServiceErrorMessages.forException(
          e,
          action: 'Account konnte nicht geladen werden',
        ),
      );
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

      return ServiceErrorMessages.forHttpStatus(
        statusCode: response.statusCode,
        action: 'Passwort konnte nicht geändert werden',
        responseBody: response.body,
      );
    } catch (e) {
      debugPrint('Account password update failed: $e');
      return ServiceErrorMessages.forException(
        e,
        action: 'Passwort konnte nicht geändert werden',
      );
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

      return ServiceErrorMessages.forHttpStatus(
        statusCode: response.statusCode,
        action: 'Account konnte nicht gelöscht werden',
        responseBody: response.body,
      );
    } catch (e) {
      debugPrint('Account delete failed: $e');
      return ServiceErrorMessages.forException(
        e,
        action: 'Account konnte nicht gelöscht werden',
      );
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

      return ServiceErrorMessages.forHttpStatus(
        statusCode: response.statusCode,
        action: 'Code konnte nicht gesendet werden',
        responseBody: response.body,
      );
    } catch (e) {
      debugPrint('Account forgot-password failed: $e');
      return ServiceErrorMessages.forException(
        e,
        action: 'Code konnte nicht gesendet werden',
      );
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

      return ServiceErrorMessages.forHttpStatus(
        statusCode: response.statusCode,
        action: 'Passwort konnte nicht zurückgesetzt werden',
        responseBody: response.body,
      );
    } catch (e) {
      debugPrint('Account reset-password failed: $e');
      return ServiceErrorMessages.forException(
        e,
        action: 'Passwort konnte nicht zurückgesetzt werden',
      );
    }
  }

}

class AccountLoadResult {
  final Account? account;
  final String? message;

  const AccountLoadResult({this.account, this.message});
}
