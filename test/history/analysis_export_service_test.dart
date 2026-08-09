import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/history/services/analysis_export_service.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';

Project _project(String theme) {
  final now = DateTime.utc(2026, 3, 1);
  return Project(
    createdAt: now,
    updatedAt: now,
    theme: theme,
    desiredGoal: 'ゴール',
    matrix: SwotMatrix(
      strengths: [SwotItem(category: SwotCategory.strength, content: '強み')],
    ),
  );
}

void main() {
  group('AnalysisExportService.encodeProjects / decodeProjects', () {
    test('round-trips a full backup, preserving every project', () {
      final projects = [_project('テーマA'), _project('テーマB')];
      final order = projects.map((p) => p.id).toList();

      final jsonText = AnalysisExportService.encodeProjects(
        projects,
        projectOrder: order,
      );
      final decoded = AnalysisExportService.decodeProjects(jsonText);

      expect(decoded, hasLength(2));
      expect(decoded.map((p) => p.theme), containsAll(['テーマA', 'テーマB']));
      expect(decoded.first.matrix.strengths.single.content, '強み');
      expect(jsonText, contains('"projects"'));
      expect(jsonText, contains('"formatVersion": 2'));
      expect(jsonText, contains('"projectOrder"'));
    });

    test('decodeBackup restores projectOrder when present', () {
      final projects = [_project('テーマA'), _project('テーマB')];
      final order = [projects[1].id, projects[0].id];
      final jsonText = AnalysisExportService.encodeProjects(
        projects,
        projectOrder: order,
      );

      final backup = AnalysisExportService.decodeBackup(jsonText);

      expect(backup.projectOrder, order);
      expect(backup.projects, hasLength(2));
    });

    test('throws FormatException when "projects" is missing', () {
      expect(
        () => AnalysisExportService.decodeProjects('{"formatVersion": 2}'),
        throwsFormatException,
      );
    });

    test('skips a malformed project instead of rejecting the whole file', () {
      final good = _project('良いテーマ').toJson();
      final jsonText = jsonEncode({
        'projects': [
          good,
          {'bogus': true},
        ],
      });

      final decoded = AnalysisExportService.decodeProjects(jsonText);

      expect(decoded, hasLength(1));
      expect(decoded.single.theme, '良いテーマ');
    });
  });

  group('AnalysisExportService.exportFileName', () {
    test('embeds the date/time and ends in .json', () {
      final name = AnalysisExportService.exportFileName(
        DateTime(2026, 7, 15, 9, 5),
      );
      expect(name, 'osmjiritsu_history_20260715_0905.json');
    });
  });
}
