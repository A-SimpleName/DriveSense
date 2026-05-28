import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:drivesense/config/api_config.dart';

class PdfService {
  static Future<void> generatePdf() async {
    final Map<String, String> headers = RequestHeaders.authenticated();
    if (!headers.containsKey('Cookie')) {
      return;
    }

    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/export/${RuntimeStore.currentProtocolId}');
    try {
      final http.Response response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('GeneratePdf <- ${response.statusCode} $uri');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Failed to generate PDF: ${response.body}');
        return;
      }
    } catch (e) {
      debugPrint('GeneratePdf failed at $uri: $e');
    }
  }
}
