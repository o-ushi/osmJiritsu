// Widget tests for Stage1 Step 11's ProjectExportScreen. Tapping "共有する"
// itself is intentionally not exercised here — it calls the real
// `SharePlus.instance.share(...)` platform channel directly (there's no
// `AnalysisFileIO`-style seam for it, matching how `DeviceAnalysisFileIO`'s
// own share call is never invoked for real in this suite either), so this
// covers everything else: the rendered summary, the PDF note, and "完了"'s
// navigation to the project detail "dashboard".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/export/screens/project_export_screen.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';
import 'package:osm_jiritsu/wizard/state/wizard_state.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_project_order_repository.dart';

class _PreloadedWizardNotifier extends WizardNotifier {
  @override
  WizardState build() => WizardState(
    theme: '新しいキャリアについて',
    desiredGoal: '納得感のある転職をしている',
    undesiredGoal: '妥協して転職している',
    decidedStrategy: '強みを活かして転職エージェントに登録する',
    decidedFirstStep: '転職エージェントに登録する',
    declaration: '私は納得感のある転職を目指しています。まずは転職エージェントに登録します。',
  );
}

Future<void> pumpScreen(
  WidgetTester tester, {
  bool fromProjectDashboard = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wizardProvider.overrideWith(_PreloadedWizardNotifier.new),
        analysisHistoryRepositoryProvider.overrideWithValue(
          InMemoryAnalysisHistoryRepository(),
        ),
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
        ),
        projectOrderRepositoryProvider.overrideWithValue(
          InMemoryProjectOrderRepository(),
        ),
      ],
      child: MaterialApp(
        home: ProjectExportScreen(fromProjectDashboard: fromProjectDashboard),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the fixed テーマ/ゴール/方策/最初の一歩/宣言文 summary', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.textContaining('テーマ: 新しいキャリアについて'), findsOneWidget);
    expect(find.textContaining('ゴール1️⃣（在りたい姿）: 納得感のある転職をしている'), findsOneWidget);
    expect(find.textContaining('ゴール2️⃣（在りたくない姿）: 妥協して転職している'), findsOneWidget);
    expect(find.textContaining('方策: 強みを活かして転職エージェントに登録する'), findsOneWidget);
    expect(find.textContaining('最初の一歩: 転職エージェントに登録する'), findsOneWidget);
    expect(
      find.textContaining('私は納得感のある転職を目指しています。まずは転職エージェントに登録します。'),
      findsOneWidget,
    );
  });

  testWidgets('explains text share (no PDF teaser)', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('テキストで共有します'), findsOneWidget);
    expect(find.textContaining('PDF書き出し'), findsNothing);
  });

  testWidgets('"完了" navigates to the project detail screen', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    // DashboardScreen's AppBar title is the project's theme.
    expect(find.text('新しいキャリアについて'), findsOneWidget);
    expect(find.text('まとめを共有'), findsNothing);
  });

  testWidgets(
    '共有する is shown when reached fresh from Stage1 — there is no other share entry point yet',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('共有する'), findsOneWidget);
    },
  );

  testWidgets(
    '共有する is hidden when reached from an existing project — the '
    'dashboard toolbar already has its own 共有 button there',
    (tester) async {
      await pumpScreen(tester, fromProjectDashboard: true);

      expect(find.text('共有する'), findsNothing);
      expect(find.byTooltip('共有'), findsOneWidget);
      // The rest of the screen (summary, PDF note, 完了) is unaffected.
      expect(find.textContaining('テーマ: 新しいキャリアについて'), findsOneWidget);
      expect(find.text('完了'), findsOneWidget);
    },
  );
}
