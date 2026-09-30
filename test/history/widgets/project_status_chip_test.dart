import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/widgets/project_status_chip.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/models/project_status.dart';

/// EN/VI's translated 現況 labels ("Đang chuẩn bị" etc.) used to ellipsize
/// inside the history card's tight row — see [ProjectStatusChip]'s doc.
/// These tests lock down the fix: the badge itself never renders text (so
/// it can't truncate in any language), and the label survives as the
/// [Tooltip] message instead of being dropped.
void main() {
  Future<void> pump(WidgetTester tester, ProjectStatus status, AppLanguage lang) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectStatusChip(status: status, lang: lang),
        ),
      ),
    );
  }

  for (final status in ProjectStatus.values) {
    testWidgets('${status.name}: renders no text, in any language', (
      tester,
    ) async {
      for (final lang in AppLanguage.values) {
        await pump(tester, status, lang);
        expect(
          find.byType(Text),
          findsNothing,
          reason: '$lang label must not appear as on-badge text',
        );
        expect(find.byType(Icon), findsOneWidget);
      }
    });

    testWidgets('${status.name}: keeps its label as the Tooltip message', (
      tester,
    ) async {
      await pump(tester, status, AppLanguage.japanese);
      expect(find.byTooltip(status.displayName), findsOneWidget);
    });
  }

  testWidgets('every status gets its own icon', (tester) async {
    final icons = <IconData>{};
    for (final status in ProjectStatus.values) {
      await pump(tester, status, AppLanguage.japanese);
      icons.add(tester.widget<Icon>(find.byType(Icon)).icon!);
    }
    expect(icons, hasLength(ProjectStatus.values.length));
  });
}
