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
}
