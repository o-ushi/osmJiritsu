import 'package:flutter/services.dart' show rootBundle;

import '../../models/project.dart';
import '../services/analysis_export_service.dart';

/// Bundled 例題 (sample) 案件, seeded once on first install (see
/// `AnalysisHistoryNotifier.build()`) so a new user immediately sees what a
/// finished 案件 looks like, rather than an empty list. Reuses the
/// export/import backup format — the bundled file is itself a real
/// exported backup — so [AnalysisExportService.decodeBackup] can read it
/// directly.
Future<List<Project>> loadSampleProjects() async {
  final jsonText = await rootBundle.loadString(
    'assets/data/sample_project.json',
  );
  return AnalysisExportService.decodeBackup(jsonText).projects;
}
