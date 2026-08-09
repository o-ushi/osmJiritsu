import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Seam between the history screen and the platform's file-share/file-pick
/// plumbing, so tests can fake both without touching a real filesystem or
/// share sheet.
abstract class AnalysisFileIO {
  /// Writes [jsonText] to a real file named [fileName] and hands it to the
  /// OS share sheet — a proper file attachment (importable back into the
  /// app), not a plain text share.
  Future<void> shareJsonFile({
    required String fileName,
    required String jsonText,
  });

  /// Opens a file picker restricted to `.json` files and returns its text
  /// contents, or `null` if the user cancelled.
  Future<String?> pickJsonFile();

  /// Removes temporary backup files created by this app.
  Future<void> deleteTemporaryExports();
}

class DeviceAnalysisFileIO implements AnalysisFileIO {
  const DeviceAnalysisFileIO();

  @override
  Future<void> shareJsonFile({
    required String fileName,
    required String jsonText,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonText);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          fileNameOverrides: [fileName],
          subject: 'osmJiritsu 分析履歴のバックアップ',
        ),
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<String?> pickJsonFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    if (picked.bytes != null) return utf8.decode(picked.bytes!);
    final path = picked.path;
    if (path != null) return File(path).readAsString();
    return null;
  }

  @override
  Future<void> deleteTemporaryExports() async {
    final dir = await getTemporaryDirectory();
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.toLowerCase();
      // Current export prefix (`osmjiritsu_history_…`) plus the older
      // `osmJiritsu-analysis-` name, in case any leftover temp files remain.
      final isExport =
          name.endsWith('.json') &&
          (name.startsWith('osmjiritsu_history_') ||
              name.startsWith('osmjiritsu-analysis-'));
      if (isExport) await entity.delete();
    }
  }
}

final analysisFileIOProvider = Provider<AnalysisFileIO>((ref) {
  return const DeviceAnalysisFileIO();
});
