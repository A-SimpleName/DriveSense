import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> savePdfFile({
  required List<int> bytes,
  required String filename,
}) async {
  final String safeFilename = _safeFilename(filename);
  Object? lastError;

  for (final Directory directory in await _exportDirectories()) {
    try {
      final File file = await _availableFile(directory, safeFilename);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      lastError = e;
    }
  }

  throw FileSystemException(
    'PDF konnte nicht gespeichert werden',
    safeFilename,
    lastError is OSError ? lastError : null,
  );
}

Future<List<Directory>> _exportDirectories() async {
  final List<Directory> directories = <Directory>[];

  try {
    final Directory? downloadsDirectory = await getDownloadsDirectory();
    if (downloadsDirectory != null) {
      directories.add(
        await Directory(
          '${downloadsDirectory.path}${Platform.pathSeparator}DriveSense',
        ).create(recursive: true),
      );
    }
  } catch (_) {}

  if (Platform.isAndroid) {
    try {
      directories.add(
        await Directory(
          '/storage/emulated/0/Download/DriveSense',
        ).create(recursive: true),
      );
    } catch (_) {}

    try {
      final Directory? externalDirectory = await getExternalStorageDirectory();
      if (externalDirectory != null) {
        directories.add(
          await Directory(
            '${externalDirectory.path}${Platform.pathSeparator}DriveSense',
          ).create(recursive: true),
        );
      }
    } catch (_) {}
  }

  final Directory documentsDirectory = await getApplicationDocumentsDirectory();
  directories.add(
    await Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}DriveSense',
    ).create(recursive: true),
  );

  final Directory tempDirectory = await getTemporaryDirectory();
  directories.add(
    await Directory(
      '${tempDirectory.path}${Platform.pathSeparator}DriveSense',
    ).create(recursive: true),
  );

  return directories;
}

Future<File> _availableFile(Directory directory, String filename) async {
  File file = File('${directory.path}${Platform.pathSeparator}$filename');
  final int dotIndex = filename.lastIndexOf('.');
  final String baseName = dotIndex > 0
      ? filename.substring(0, dotIndex)
      : filename;
  final String extension = dotIndex > 0 ? filename.substring(dotIndex) : '';

  var suffix = 1;
  while (await file.exists()) {
    file = File(
      '${directory.path}${Platform.pathSeparator}$baseName ($suffix)$extension',
    );
    suffix++;
  }

  return file;
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
