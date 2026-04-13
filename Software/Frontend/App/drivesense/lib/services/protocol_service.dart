import 'dart:async';
import 'dart:convert';

import 'package:drivesense/constants/api_config.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProtocolService {
  ProtocolService._();

  static Map<String, String> _authHeaders() {
    final String? cookieHeader = RuntimeStore.getCookieHeader();
    return <String, String>{
      'Content-Type': 'application/json',
      if (cookieHeader != null) 'Cookie': cookieHeader,
    };
  }

  static Future<int?> resolveFirstAvailableProtocolId() async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols');

    try {
      final http.Response response = await http
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! List) {
        return null;
      }

      for (final dynamic item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final dynamic idValue = item['id'];
        int? id;
        if (idValue is int) {
          id = idValue;
        } else if (idValue is num) {
          id = idValue.toInt();
        } else if (idValue != null) {
          id = int.tryParse(idValue.toString());
        }

        if (id != null && id > 0) {
          return id;
        }
      }
    } catch (e) {
      debugPrint('ResolveFirstAvailableProtocolId failed at $uri: $e');
    }

    return null;
  }

  static Future<int?> createDefaultProtocol(int profileId) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols');

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode(<String, dynamic>{
              'createdByProfileId': profileId,
              'usergroupId': 0,
              'name': 'L17 Protokoll',
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'CreateDefaultProtocol <- status=${response.statusCode}, uri=$uri, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final dynamic idValue = decoded['id'];
      if (idValue is int && idValue > 0) {
        return idValue;
      }
      if (idValue is num) {
        final int value = idValue.toInt();
        return value > 0 ? value : null;
      }
      if (idValue != null) {
        final int? value = int.tryParse(idValue.toString());
        if (value != null && value > 0) {
          return value;
        }
      }
    } catch (e) {
      debugPrint('CreateDefaultProtocol failed at $uri: $e');
    }

    return null;
  }

  static Future<int> ensureDefaultProtocolForActiveProfile(int profileId) async {
    int? protocolId = await resolveFirstAvailableProtocolId();
    protocolId ??= await createDefaultProtocol(profileId);
    final int resolved = protocolId ?? 0;
    RuntimeStore.setCurrentProtocolId(resolved);
    return resolved;
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
}
