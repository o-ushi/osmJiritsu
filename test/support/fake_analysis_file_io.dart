import 'package:osm_jiritsu/history/data/analysis_file_io.dart';

/// Records shared files and returns a pre-programmed picked file, so tests
/// can exercise export/import without a real share sheet or file picker.
class FakeAnalysisFileIO implements AnalysisFileIO {
  final List<({String fileName, String jsonText})> sharedFiles = [];
  String? pickedJsonText;
  bool temporaryExportsDeleted = false;

  @override
  Future<void> shareJsonFile({
    required String fileName,
    required String jsonText,
  }) async {
    sharedFiles.add((fileName: fileName, jsonText: jsonText));
  }

  @override
  Future<String?> pickJsonFile() async => pickedJsonText;

  @override
  Future<void> deleteTemporaryExports() async {
    temporaryExportsDeleted = true;
  }
}
