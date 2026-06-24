import 'dart:async';
import 'dart:convert';

/// Normalizes backend, timeout, and offline failures into messages that can be
/// shown directly in the UI.
///
/// The helper keeps server validation text when it is already readable, but
/// replaces transport- and framework-level noise with short German guidance.
class ServiceErrorMessages {
  ServiceErrorMessages._();

  /// Builds a user-facing message for a failed HTTP response.
  static String forHttpStatus({
    required int statusCode,
    required String action,
    String? responseBody,
    String? fallback,
    bool preferServerMessage = true,
  }) {
    final String? serverMessage = preferServerMessage
        ? extractServerMessage(responseBody ?? '')
        : null;
    if (serverMessage != null) {
      return serverMessage;
    }

    if (statusCode == 400 || statusCode == 422) {
      return '$action. Bitte Eingaben prüfen und erneut versuchen.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return '$action. Die Anmeldung ist abgelaufen oder die Aktion ist nicht erlaubt. Bitte erneut einloggen.';
    }

    if (statusCode == 404) {
      return '$action. Der Eintrag wurde nicht gefunden oder bereits entfernt.';
    }

    if (statusCode == 409) {
      return '$action. Die Daten wurden zwischenzeitlich geändert. Bitte neu laden und erneut versuchen.';
    }

    if (statusCode >= 500) {
      return '$action. Der Server ist momentan nicht erreichbar. Bitte später erneut versuchen.';
    }

    return fallback ?? '$action. Bitte erneut versuchen.';
  }

  /// Builds a user-facing message for a thrown exception or client failure.
  static String forException(Object error, {required String action}) {
    if (error is TimeoutException || _looksLikeTimeout(error)) {
      return '$action. Die Anfrage dauert zu lange. Bitte Verbindung prüfen und erneut versuchen.';
    }

    if (_looksLikeOfflineError(error)) {
      return '$action. Keine Verbindung zum Server. Bitte Internetverbindung prüfen und erneut versuchen.';
    }

    if (_looksLikeTlsError(error)) {
      return '$action. Die sichere Verbindung zum Server ist fehlgeschlagen. Bitte später erneut versuchen.';
    }

    if (error is FormatException) {
      return '$action. Die Serverantwort konnte nicht gelesen werden. Bitte später erneut versuchen.';
    }

    return '$action. Bitte später erneut versuchen.';
  }

  /// Extracts a readable server message from JSON or plain-text error bodies.
  static String? extractServerMessage(String rawBody) {
    final String trimmedBody = rawBody.trim();
    if (trimmedBody.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final String? errorsMessage = _errorsMessage(decoded['errors']);
        if (errorsMessage != null) {
          return errorsMessage;
        }

        final dynamic message = decoded['message'] ?? decoded['error'];
        if (message is String) {
          final String trimmedMessage = message.trim();
          if (trimmedMessage.isNotEmpty && !_looksTechnical(trimmedMessage)) {
            return trimmedMessage;
          }
        }
      }
    } catch (_) {
      return _looksTechnical(trimmedBody) ? null : trimmedBody;
    }

    return null;
  }

  static String? _errorsMessage(dynamic errors) {
    if (errors is! Map<String, dynamic> || errors.isEmpty) {
      return null;
    }

    final String combined = errors.values
        .map((dynamic value) => value.toString().trim())
        .where((String value) => value.isNotEmpty && !_looksTechnical(value))
        .join(', ');
    return combined.isEmpty ? null : combined;
  }

  static bool _looksLikeOfflineError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connectionerror') ||
        message.contains('network is unreachable') ||
        message.contains('connection errored') ||
        message.contains('connection refused') ||
        message.contains('no address associated with hostname') ||
        message.contains('software caused connection abort');
  }

  static bool _looksLikeTimeout(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('connection timed out') ||
        message.contains('receivetimeout') ||
        message.contains('sendtimeout') ||
        message.contains('connectiontimeout');
  }

  static bool _looksLikeTlsError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('certificate') ||
        message.contains('badcertificate') ||
        message.contains('handshake') ||
        message.contains('tls') ||
        message.contains('ssl');
  }

  static bool _looksTechnical(String message) {
    final String lower = message.toLowerCase();
    return lower.startsWith('<!doctype') ||
        lower.startsWith('<html') ||
        lower.startsWith('{') ||
        lower.startsWith('[') ||
        lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('org.springframework') ||
        lower.contains('java.') ||
        lower.contains('trace":') ||
        lower.contains('timestamp":') ||
        lower.contains('clientexception') ||
        lower.contains('dioexception');
  }
}
