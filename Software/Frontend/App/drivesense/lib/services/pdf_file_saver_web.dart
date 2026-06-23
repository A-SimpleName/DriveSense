import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> savePdfFile({
  required List<int> bytes,
  required String filename,
}) async {
  final String safeFilename = filename.trim().isEmpty
      ? 'protocol.pdf'
      : filename.trim();
  final web.Blob blob = web.Blob(
    <web.BlobPart>[Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = safeFilename
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);

  return safeFilename;
}

String userVisiblePdfPath(String path) {
  return path;
}
