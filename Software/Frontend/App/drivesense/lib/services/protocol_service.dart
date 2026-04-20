import 'dart:async';
import 'dart:convert';

import 'package:drivesense/constants/api_config.dart';
import 'package:drivesense/model/protocol.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProtocolService {
  ProtocolService._();

  static Map<String, String> _authHeaders() {
    final String? cookieHeader = RuntimeStore.getCookieHeader();
    return <String, String>{
      'Content-Type': 'application/json',
      ..._cookieHeaders(cookieHeader),
    };
  }

  static Future<List<Protocol>> fetchProtocols() async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols');

    try {
      final http.Response response = await http
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <Protocol>[];
      }

      final dynamic decoded = _decodeJson(response.body);
      return _extractProtocols(decoded);
    } catch (e) {
      debugPrint('FetchProtocols failed at $uri: $e');
      return <Protocol>[];
    }
  }

  static Future<int?> resolveFirstAvailableProtocolId() async {
    final List<Protocol> protocols = await fetchProtocols();
    if (protocols.isEmpty) {
      return null;
    }

    return protocols.first.id > 0 ? protocols.first.id : null;
  }

  static Future<int?> resolveCurrentOrFirstAvailableProtocolId() async {
    final List<Protocol> protocols = await fetchProtocols();
    if (protocols.isEmpty) {
      return null;
    }

    final int currentProtocolId = RuntimeStore.getCurrentProtocolId();
    for (final Protocol protocol in protocols) {
      if (protocol.id == currentProtocolId && protocol.id > 0) {
        return protocol.id;
      }
    }

    return protocols.first.id > 0 ? protocols.first.id : null;
  }

  static Future<Protocol?> createProtocol({
    required int profileId,
    required String name,
    int? usergroupId,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols');
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return null;
    }

    try {
      final http.Response response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode(<String, dynamic>{
              'createdByProfileId': profileId,
              if (usergroupId != null) 'usergroupId': usergroupId,
              'name': trimmedName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'CreateProtocol <- status=${response.statusCode}, uri=$uri, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = _decodeJson(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final Protocol protocol = Protocol.fromJson(decoded);
      return protocol.id > 0 ? protocol : null;
    } catch (e) {
      debugPrint('CreateProtocol failed at $uri: $e');
      return null;
    }
  }

  static Future<int?> createDefaultProtocol(int profileId) async {
    final Protocol? protocol = await createProtocol(
      profileId: profileId,
      name: 'L17 Protokoll',
    );
    return protocol?.id;
  }

  static Future<int> ensureDefaultProtocolForActiveProfile(
    int profileId,
  ) async {
    int? protocolId = await resolveCurrentOrFirstAvailableProtocolId();
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

  static List<Protocol> _extractProtocols(dynamic decoded) {
    if (decoded is! List) {
      return <Protocol>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Protocol.fromJson)
        .where((Protocol protocol) => protocol.id > 0)
        .toList();
  }

  static Map<String, String> _cookieHeaders(String? cookieHeader) {
    if (cookieHeader == null) {
      return const <String, String>{};
    }

    return <String, String>{'Cookie': cookieHeader};
  }
}
