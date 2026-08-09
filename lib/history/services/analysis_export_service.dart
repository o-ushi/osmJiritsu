import 'dart:convert';

import '../../models/project.dart';

/// Builds and reads the JSON file format used for export/import on the
/// home screen: a full backup of every saved [Project] (all fields via
/// [Project.toJson]), plus the list's manual display order when set —
/// re-importable on this or another device for migration.
///
/// Kept as pure functions (no file I/O, no platform channels) so the format
/// itself is unit-testable independent of `AnalysisFileIO`'s file
/// picker/share-sheet plumbing.
abstract final class AnalysisExportService {
  /// Bumped if the payload shape ever changes in a way old readers can't
  /// tolerate; [decodeBackup] doesn't currently gate on it (every field is
  /// read tolerantly) but it's captured for future migrations.
  static const int projectFormatVersion = 2;

  /// A decoded backup file: every [Project] plus optional list order.
  static AnalysisBackup decodeBackup(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid export file: expected a JSON object at the top level.',
      );
    }

    List<String>? projectOrder;
    final rawOrder = decoded['projectOrder'];
    if (rawOrder is List) {
      projectOrder = rawOrder.whereType<String>().toList();
      if (projectOrder.isEmpty) projectOrder = null;
    }

    final rawProjects = decoded['projects'];
    if (rawProjects is List) {
      final projects = <Project>[];
      for (final raw in rawProjects) {
        if (raw is! Map<String, dynamic>) continue;
        try {
          projects.add(Project.fromJson(raw));
        } on FormatException {
          // Skip one bad record rather than rejecting the whole file.
        }
      }
      return AnalysisBackup(projects: projects, projectOrder: projectOrder);
    }

    throw const FormatException(
      'Invalid export file: missing "projects" array.',
    );
  }

  static Map<String, dynamic> buildProjectPayload(
    List<Project> projects, {
    List<String>? projectOrder,
  }) =>
      {
        'formatVersion': projectFormatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'projects': projects.map((p) => p.toJson()).toList(),
        if (projectOrder != null && projectOrder.isNotEmpty)
          'projectOrder': projectOrder,
      };

  static String encodeProjects(
    List<Project> projects, {
    List<String>? projectOrder,
  }) =>
      const JsonEncoder.withIndent('  ').convert(
        buildProjectPayload(projects, projectOrder: projectOrder),
      );

  /// Throws [FormatException] if [jsonText] isn't valid JSON or doesn't
  /// have the expected `"projects"` shape at the top level. Individual
  /// malformed records are skipped rather than failing the whole import
  /// (see [decodeBackup]).
  static List<Project> decodeProjects(String jsonText) =>
      decodeBackup(jsonText).projects;

  static String exportFileName([DateTime? now]) {
    final t = now ?? DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return 'osmjiritsu_history_${t.year}${pad(t.month)}${pad(t.day)}_${pad(t.hour)}${pad(t.minute)}.json';
  }
}

/// Full backup payload decoded from an export file.
class AnalysisBackup {
  const AnalysisBackup({
    required this.projects,
    this.projectOrder,
  });

  final List<Project> projects;
  final List<String>? projectOrder;
}
