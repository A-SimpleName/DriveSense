import 'dart:async';
import 'dart:convert';

import 'package:drivesense/config/api_config.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/model/protocol.dart';
import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/service_error_messages.dart';
import 'package:flutter/foundation.dart';

class ProtocolFetchResult {
  /// True when the server request completed and a protocol list was parsed.
  final bool isSuccess;

  /// Protocols returned by the backend or an empty list on failure.
  final List<Protocol> protocols;

  /// Optional message for the UI when the fetch did not succeed.
  final String? message;

  const ProtocolFetchResult({
    required this.isSuccess,
    required this.protocols,
    this.message,
  });
}

class ProtocolActionResult {
  /// True when the action completed successfully.
  final bool isSuccess;

  /// Message intended for a snackbar or inline status label.
  final String message;

  const ProtocolActionResult({
    required this.isSuccess,
    required this.message,
  });
}

class ProtocolService {
  ProtocolService._();

  static Future<List<Protocol>> fetchProtocols() async {
    final ProtocolFetchResult result = await fetchProtocolsWithResult();
    return result.isSuccess ? result.protocols : <Protocol>[];
  }

  static Future<ProtocolFetchResult> fetchProtocolsWithResult() async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols');

    try {
      final http.Response response = await http
          .get(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ProtocolFetchResult(
          isSuccess: false,
          protocols: const <Protocol>[],
          message: ServiceErrorMessages.forHttpStatus(
            statusCode: response.statusCode,
            action: 'Protokolle konnten nicht geladen werden',
            responseBody: response.body,
          ),
        );
      }

      final dynamic decoded = _decodeJson(response.body);
      final List<Protocol> protocols = _extractProtocols(decoded);
      RuntimeStore.setProtocols(protocols);
      return ProtocolFetchResult(isSuccess: true, protocols: protocols);
    } on TimeoutException catch (e) {
      debugPrint('FetchProtocols timed out at $uri: $e');
      return const ProtocolFetchResult(
        isSuccess: false,
        protocols: <Protocol>[],
        message:
            'Protokolle konnten nicht geladen werden. Bitte Internetverbindung prüfen.',
      );
    } catch (e) {
      debugPrint('FetchProtocols failed at $uri: $e');
      return ProtocolFetchResult(
        isSuccess: false,
        protocols: <Protocol>[],
        message: ServiceErrorMessages.forException(
          e,
          action: 'Protokolle konnten nicht geladen werden',
        ),
      );
    }
  }

  static Future<int?> resolveFirstAvailableProtocolId() async {
    List<Protocol> protocols = RuntimeStore.protocols;
    if (protocols.isEmpty) {
      protocols = await fetchProtocols();
    }
    if (protocols.isEmpty) {
      return null;
    }

    return protocols.first.id > 0 ? protocols.first.id : null;
  }

  static Future<int?> resolveCurrentOrFirstAvailableProtocolId() async {
    return resolvePreferredCurrentOrFirstAvailableProtocolId();
  }

  static Future<int?> resolvePreferredCurrentOrFirstAvailableProtocolId({
    int preferredProtocolId = 0,
  }) async {
    List<Protocol> protocols = RuntimeStore.protocols;
    if (protocols.isEmpty) {
      protocols = await fetchProtocols();
    }
    if (protocols.isEmpty) {
      return null;
    }

    if (preferredProtocolId > 0) {
      for (final Protocol protocol in protocols) {
        if (protocol.id == preferredProtocolId) {
          return protocol.id;
        }
      }
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
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(<String, dynamic>{
              'name': trimmedName,
              'usergroupId': usergroupId,
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
        return _resolveProtocolByNameFallback(trimmedName);
      }

      final Protocol protocol = Protocol.fromJson(decoded);
      if (protocol.id > 0) {
        RuntimeStore.upsertProtocol(protocol);
        return protocol;
      }

      return _resolveProtocolByNameFallback(trimmedName);
    } catch (e) {
      debugPrint('CreateProtocol failed at $uri: $e');
      return null;
    }
  }

  static Future<ProtocolActionResult> updateProtocol({
    required Protocol protocol,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols/${protocol.id}');
    final String trimmedName = protocol.name.trim();
    if (protocol.id <= 0) {
      return const ProtocolActionResult(
        isSuccess: false,
        message: 'Protokoll konnte nicht umbenannt werden.',
      );
    }
    if (trimmedName.isEmpty) {
      return const ProtocolActionResult(
        isSuccess: false,
        message: 'Protokollname darf nicht leer sein.',
      );
    }

    try {
      final http.Response response = await http
          .put(
            uri,
            headers: RequestHeaders.authenticatedJson(),
            body: jsonEncode(protocol.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        RuntimeStore.upsertProtocol(
          Protocol(
            id: protocol.id,
            createdByProfileId: protocol.createdByProfileId,
            usergroupId: protocol.usergroupId,
            name: trimmedName,
          ),
        );
        return const ProtocolActionResult(
          isSuccess: true,
          message: 'Protokoll wurde umbenannt.',
        );
      }

      return ProtocolActionResult(
        isSuccess: false,
        message: ServiceErrorMessages.forHttpStatus(
          statusCode: response.statusCode,
          action: 'Protokoll konnte nicht umbenannt werden',
          responseBody: response.body,
        ),
      );
    } catch (e) {
      debugPrint('UpdateProtocol failed at $uri: $e');
      return ProtocolActionResult(
        isSuccess: false,
        message: ServiceErrorMessages.forException(
          e,
          action: 'Protokoll konnte nicht umbenannt werden',
        ),
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

  static Future<Protocol?> _resolveProtocolByNameFallback(String name) async {
    final String expected = name.trim().toLowerCase();
    if (expected.isEmpty) {
      return null;
    }

    final List<Protocol> protocols = await fetchProtocols();
    for (final Protocol protocol in protocols.reversed) {
      if (protocol.name.trim().toLowerCase() == expected) {
        return protocol;
      }
    }

    return null;
  }

  static Future<bool> deleteProtocol(int protocolId) async {
    final ProtocolActionResult result = await deleteProtocolWithResult(
      protocolId,
    );
    return result.isSuccess;
  }

  /// Deletes a protocol on the backend and removes its cached local copy.
  ///
  /// This returns a structured result so the UI can explain why deletion
  /// failed instead of falling back to a generic "failed" snackbar.
  static Future<ProtocolActionResult> deleteProtocolWithResult(
    int protocolId,
  ) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/protocols/$protocolId');

    try {
      final http.Response response = await http
          .delete(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      debugPrint('DeleteProtocol <- status=${response.statusCode}, uri=$uri');

      final bool success =
          response.statusCode >= 200 && response.statusCode < 300;
      if (success) {
        RuntimeStore.removeProtocol(protocolId);
        return const ProtocolActionResult(
          isSuccess: true,
          message: 'Protokoll wurde gelöscht.',
        );
      }

      return ProtocolActionResult(
        isSuccess: false,
        message: ServiceErrorMessages.forHttpStatus(
          statusCode: response.statusCode,
          action: 'Protokoll konnte nicht gelöscht werden',
          responseBody: response.body,
        ),
      );
    } catch (e) {
      debugPrint('DeleteProtocol failed at $uri: $e');
      return ProtocolActionResult(
        isSuccess: false,
        message: ServiceErrorMessages.forException(
          e,
          action: 'Protokoll konnte nicht gelöscht werden',
        ),
      );
    }
  }
}
