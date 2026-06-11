import 'package:drivesense/runtime_store.dart';
import 'package:drivesense/config/request_headers.dart';
import 'package:drivesense/services/auth_http_client.dart' as http;
import 'package:drivesense/services/pdf_file_saver.dart';
import 'package:drivesense/services/pdf_file_sharer.dart';
import 'package:flutter/foundation.dart';
import 'package:drivesense/config/api_config.dart';

class PdfService {
  static Future<PdfExportResult> generatePdf({int? protocolId}) async {
    final int selectedProtocolId =
        protocolId ?? RuntimeStore.getCurrentProtocolId();
    if (selectedProtocolId <= 0) {
      return const PdfExportResult.failure('Kein Protokoll ausgewaehlt.');
    }

    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/export/$selectedProtocolId',
    );
    try {
      final http.Response response = await http
          .getBytes(uri, headers: RequestHeaders.authenticated())
          .timeout(const Duration(seconds: 10));

      debugPrint('GeneratePdf <- ${response.statusCode} $uri');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Failed to generate PDF: ${response.body}');
        return PdfExportResult.failure(_failureMessage(response));
      }

      final List<int> pdfBytes = response.bodyBytes;
      if (pdfBytes.isEmpty) {
        return const PdfExportResult.failure(
          'PDF wurde leer vom Server geliefert.',
        );
      }

      final String filename =
          _filenameFromHeaders(response.headers) ??
          'protocol_$selectedProtocolId.pdf';
      final String path = await savePdfFile(
        bytes: pdfBytes,
        filename: filename,
      );
      final bool shareOpened = await sharePdfFile(
        path: path,
        filename: filename,
      );
      final String visiblePath = userVisiblePdfPath(path);
      final String message = shareOpened
          ? 'PDF exportiert. Teilen/Speichern geoeffnet.'
          : 'PDF exportiert: $visiblePath';
      return PdfExportResult.success(message, path);
    } catch (e) {
      debugPrint('GeneratePdf failed at $uri: $e');
      return PdfExportResult.failure('PDF Export fehlgeschlagen: $e');
    }
  }

  static String _failureMessage(http.Response response) {
    final String body = response.body.trim();
    if (body.isNotEmpty) {
      return 'PDF Export fehlgeschlagen (${response.statusCode}): $body';
    }
    return 'PDF Export fehlgeschlagen (${response.statusCode}).';
  }

  static String? _filenameFromHeaders(Map<String, String> headers) {
    final String? disposition =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (disposition == null || disposition.trim().isEmpty) {
      return null;
    }

    final RegExp filenamePattern = RegExp(
      r'''filename\*?=(?:UTF-8''|")?([^";]+)"?''',
      caseSensitive: false,
    );
    final RegExpMatch? match = filenamePattern.firstMatch(disposition);
    return match == null ? null : Uri.decodeComponent(match.group(1)!.trim());
  }
}

class PdfExportResult {
  const PdfExportResult._({
    required this.success,
    required this.message,
    this.path,
  });

  const PdfExportResult.success(String message, String path)
    : this._(success: true, message: message, path: path);

  const PdfExportResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
  final String? path;
}
