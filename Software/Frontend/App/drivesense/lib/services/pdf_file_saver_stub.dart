Future<String> savePdfFile({
  required List<int> bytes,
  required String filename,
}) {
  throw UnsupportedError('PDF export is not supported on this platform.');
}

String userVisiblePdfPath(String path) {
  return path;
}
