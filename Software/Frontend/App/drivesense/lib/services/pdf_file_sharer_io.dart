import 'package:share_plus/share_plus.dart';

Future<bool> sharePdfFile({
  required String path,
  required String filename,
}) async {
  try {
    final String safeFilename = _safeFilename(filename);
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(path, mimeType: 'application/pdf')],
        fileNameOverrides: <String>[safeFilename],
        subject: safeFilename,
        text: 'DriveSense PDF',
      ),
    );

    return result.status != ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}

String _safeFilename(String filename) {
  final String trimmed = filename.trim().isEmpty
      ? 'protocol.pdf'
      : filename.trim();
  final String sanitized = trimmed.replaceAll(
    RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
    '_',
  );
  return sanitized.toLowerCase().endsWith('.pdf')
      ? sanitized
      : '$sanitized.pdf';
}
