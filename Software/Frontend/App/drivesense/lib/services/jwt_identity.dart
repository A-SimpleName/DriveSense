import 'dart:convert';

class JwtIdentity {
  JwtIdentity._();

  static int? accountIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final String payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final dynamic subject = decoded['sub'];
      if (subject is int) {
        return subject;
      }
      if (subject is num) {
        return subject.toInt();
      }
      return int.tryParse(subject?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
