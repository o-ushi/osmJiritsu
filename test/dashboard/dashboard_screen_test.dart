import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/dashboard/screens/dashboard_screen.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/reflection_entry.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';
import 'package:osm_jiritsu/theme/app_theme.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_project_order_repository.dart';

// Local (not `.utc`) so `.toLocal()` inside DashboardScreen's date
// formatting is a no-op regardless of the test machine's timezone.
final _now = DateTime(2026, 1, 1, 9, 30);

Project _project({
  ProjectStatus status = ProjectStatus.inProgress,
  DateTime? deadline,
  List<ReflectionEntry> reflectionHistory = const [],
}) {
  return Project(
    createdAt: _now,
    updatedAt: _now,
    theme: '新しいキャリアについて',
    desiredGoal: '在りたい姿の中身',
    undesiredGoal: '在りたくない姿の中身',
    decidedStrategy: '決めた方策',
    decidedFirstStep: '決めた最初の一歩',
    declaration: '宣言文の中身',
    status: status,
    deadline: deadline,
    matrix: SwotMatrix(
      strengths: [SwotItem(category: SwotCategory.strength, content: '強み1')],
    ),
    reflectionHistory: reflectionHistory,
  );
}

Future<InMemoryAnalysisHistoryRepository> pumpScreen(
  WidgetTester tester, {
  required Project project,
}) async {
  // Tall enough that every field renders without scrolling — the
  // dashboard's ListView is a Sliver, which only builds children within
  // (or near) the viewport, so the default test surface would leave
  // anything below the SWOT grid unbuilt and unfindable.
  tester.view.physicalSize = const Size(1080, 3400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = InMemoryAnalysisHistoryRepository();
  await repository.save(project);
  final container = ProviderContainer(
    overrides: [
      analysisHistoryRepositoryProvider.overrideWithValue(repository),
      appLanguageRepositoryProvider.overrideWithValue(
        InMemoryAppLanguageRepository(AppLanguage.japanese),
      ),
      projectOrderRepositoryProvider.overrideWithValue(
        InMemoryProjectOrderRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: DashboardScreen(project: project),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'renders theme/goals/strategy/first step/dates/期限/備考',
    (tester) async {
      await pumpScreen(tester, project: _project());

      expect(find.text('新しいキャリアについて'), findsOneWidget);
      expect(find.text('進捗度'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('振り返り回数'), findsOneWidget);
      expect(find.text('振り返り 0回'), findsOneWidget);
      expect(find.text('在りたい姿の中身'), findsOneWidget);
      expect(find.text('在りたくない姿の中身'), findsOneWidget);
      expect(find.text('決めた方策'), findsOneWidget);
      expect(find.text('決めた最初の一歩'), findsOneWidget);
      expect(find.text('「宣言文の中身」'), findsOneWidget);
      // 登録日 and 最終更新日 are both `_now` for a freshly seeded project.
      expect(find.text('2026/01/01 09:30'), findsNWidgets(2));
      expect(find.text('未設定'), findsOneWidget);
      expect(find.text('備考を入力…'), findsOneWidget);
    },
  );

  testWidgets('現況 chip opens a picker and changing it persists', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      project: _project(status: ProjectStatus.inProgress),
    );

    expect(find.text('実施中'), findsOneWidget);

    await tester.tap(find.text('実施中'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(find.text('完了'), findsOneWidget);
    final saved = (await repository.loadAll()).single;
    expect(saved.status, ProjectStatus.completed);
  });

  testWidgets('備考 auto-saves 600ms after typing stops', (tester) async {
    final repository = await pumpScreen(tester, project: _project());

    await tester.enterText(find.byType(TextField), '追記したメモ');
    await tester.pump(const Duration(milliseconds: 700));

    final saved = (await repository.loadAll()).single;
    expect(saved.note, '追記したメモ');
  });

  testWidgets('期限 shows the set date and the clear button removes it', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      project: _project(deadline: DateTime(2026, 3, 1)),
    );

    expect(find.text('2026/03/01'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('未設定'), findsOneWidget);
    final saved = (await repository.loadAll()).single;
    expect(saved.deadline, isNull);
  });

  testWidgets('振り返り button navigates to the reflection screen', (
    tester,
  ) async {
    await pumpScreen(tester, project: _project());

    await tester.tap(find.byTooltip('振り返り'));
    await tester.pumpAndSettle();

    expect(find.text('どうだった？'), findsOneWidget);
  });

  testWidgets(
    '振り返り履歴 shows each recorded comment, newest first',
    (tester) async {
      await pumpScreen(
        tester,
        project: _project(
          reflectionHistory: [
            ReflectionEntry(
              recordedAt: DateTime(2026, 1, 2, 10, 0),
              howItWent: '最初の振り返りコメント',
              nextChoice: '続ける',
            ),
            ReflectionEntry(
              recordedAt: DateTime(2026, 1, 5, 15, 45),
              howItWent: '二回目の振り返りコメント',
              nextChoice: '完了',
            ),
          ],
        ),
      );

      expect(find.text('振り返り履歴'), findsOneWidget);
      expect(find.text('最初の振り返りコメント'), findsOneWidget);
      expect(find.text('二回目の振り返りコメント'), findsOneWidget);
      expect(find.text('2026/01/05 15:45'), findsOneWidget);
      expect(find.text('2026/01/02 10:00'), findsOneWidget);

      // Newest entry (完了, recorded 01/05) renders before the older one
      // (続ける, recorded 01/02).
      final newestOffset = tester.getTopLeft(find.text('二回目の振り返りコメント')).dy;
      final oldestOffset = tester.getTopLeft(find.text('最初の振り返りコメント')).dy;
      expect(newestOffset, lessThan(oldestOffset));
    },
  );

  testWidgets(
    '長押しで振り返りを編集 saves the rewritten comment',
    (tester) async {
      final repository = await pumpScreen(
        tester,
        project: _project(
          reflectionHistory: [
            ReflectionEntry(
              id: 'reflection-1',
              recordedAt: DateTime(2026, 1, 2, 10, 0),
              howItWent: '最初の振り返りコメント',
              nextChoice: '続ける',
            ),
          ],
        ),
      );

      await tester.longPress(find.text('最初の振り返りコメント'));
      await tester.pumpAndSettle();

      expect(find.text('振り返りを編集'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '書き換えた振り返り',
      );
      // Same as the theme-edit test: 保存's ValueListenableBuilder needs a
      // pump so it rebuilds against the new text before we tap.
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('書き換えた振り返り'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.reflectionHistory.single.howItWent, '書き換えた振り返り');
      expect(saved.reflectionHistory.single.nextChoice, '続ける');
      expect(saved.reflectionHistory.single.id, 'reflection-1');
    },
  );

  testWidgets(
    '左スワイプで振り返りを削除できる',
    (tester) async {
      final repository = await pumpScreen(
        tester,
        project: _project(
          reflectionHistory: [
            ReflectionEntry(
              id: 'reflection-1',
              recordedAt: DateTime(2026, 1, 2, 10, 0),
              howItWent: '消す振り返り',
              nextChoice: '続ける',
            ),
            ReflectionEntry(
              id: 'reflection-2',
              recordedAt: DateTime(2026, 1, 5, 15, 45),
              howItWent: '残す振り返り',
              nextChoice: '完了',
            ),
          ],
        ),
      );

      await tester.drag(find.text('消す振り返り'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('この振り返りを削除しますか？'), findsOneWidget);
      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      expect(find.text('消す振り返り'), findsNothing);
      expect(find.text('残す振り返り'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.reflectionHistory.map((e) => e.id), ['reflection-2']);
    },
  );

  testWidgets('no 振り返り履歴 section when reflectionHistory is empty', (
    tester,
  ) async {
    await pumpScreen(tester, project: _project());

    expect(find.text('振り返り履歴'), findsNothing);
  });

  testWidgets(
    '方策 の「やっぱりやらない」 clears it after confirmation and leaves 最初の一歩 alone',
    (tester) async {
      final repository = await pumpScreen(tester, project: _project());

      expect(find.text('決めた方策'), findsOneWidget);
      expect(find.byTooltip('やっぱりやらない'), findsNWidgets(2));

      await tester.tap(find.byTooltip('やっぱりやらない').first);
      await tester.pumpAndSettle();

      expect(find.text('方策を取り消しますか？'), findsOneWidget);
      await tester.tap(find.text('やっぱりやらない'));
      await tester.pumpAndSettle();

      expect(find.text('決めた方策'), findsNothing);
      expect(find.text('方策を決める'), findsOneWidget);
      expect(find.text('決めた最初の一歩'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.decidedStrategy, '');
      expect(saved.decidedFirstStep, '決めた最初の一歩');
    },
  );

  testWidgets(
    '最初の一歩 の「やっぱりやらない」 clears it after confirmation and leaves 方策 alone',
    (tester) async {
      final repository = await pumpScreen(tester, project: _project());

      expect(find.text('決めた最初の一歩'), findsOneWidget);

      await tester.tap(find.byTooltip('やっぱりやらない').last);
      await tester.pumpAndSettle();

      expect(find.text('最初の一歩を取り消しますか？'), findsOneWidget);
      await tester.tap(find.text('やっぱりやらない'));
      await tester.pumpAndSettle();

      expect(find.text('決めた最初の一歩'), findsNothing);
      expect(find.text('最初の一歩を決める'), findsOneWidget);
      expect(find.text('決めた方策'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.decidedFirstStep, '');
      expect(saved.decidedStrategy, '決めた方策');
    },
  );

  testWidgets(
    'canceling the discard dialog keeps 方策 unchanged',
    (tester) async {
      final repository = await pumpScreen(tester, project: _project());

      await tester.tap(find.byTooltip('やっぱりやらない').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('決めた方策'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.decidedStrategy, '決めた方策');
    },
  );

  testWidgets(
    '宣言文を長押しすると編集画面に移動し、ボトムツールバーは表示されたまま保存できる',
    (tester) async {
      final repository = await pumpScreen(tester, project: _project());

      await tester.longPress(find.text('「宣言文の中身」'));
      await tester.pumpAndSettle();

      expect(find.text('宣言文を編集'), findsOneWidget);
      expect(find.text('宣言文の中身'), findsOneWidget);
      // The bottom toolbar (共有/リターン/その他) stays visible on this
      // child screen, same as every other dashboard child screen.
      expect(find.byTooltip('リターン'), findsOneWidget);
      expect(find.byTooltip('共有'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '書き換えた宣言文');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('「書き換えた宣言文」'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.declaration, '書き換えた宣言文');
    },
  );

  testWidgets(
    'long-pressing the theme in the app bar opens an editor that renames it',
    (tester) async {
      final repository = await pumpScreen(tester, project: _project());

      await tester.longPress(find.text('新しいキャリアについて'));
      await tester.pumpAndSettle();

      expect(find.text('テーマを編集'), findsOneWidget);

      // Scoped to the dialog — 備考's own TextField is still in the tree
      // underneath it.
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '書き換えたテーマ',
      );
      // The 保存 button is wrapped in a ValueListenableBuilder that only
      // picks up the new text on its own rebuild — needs an explicit pump
      // between enterText and tap, or it taps a stale button still bound
      // to the original (pre-edit) value.
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('書き換えたテーマ'), findsOneWidget);
      expect(find.text('新しいキャリアについて'), findsNothing);
      final saved = (await repository.loadAll()).single;
      expect(saved.theme, '書き換えたテーマ');
    },
  );

  testWidgets(
    'long-pressing either goal opens an editor that updates both together',
    (tester) async {
      final repository = await pumpScreen(tester, project: _project());

      await tester.longPress(find.text('在りたい姿の中身'));
      await tester.pumpAndSettle();

      // Scoped to the dialog — the underlying screen's own "在りたい姿"/
      // "在りたくない姿" labels are still in the tree behind it.
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('在りたい姿')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('在りたくない姿')),
        findsOneWidget,
      );

      final fields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.first, '書き換えた在りたい姿');
      await tester.enterText(fields.last, '書き換えた在りたくない姿');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('書き換えた在りたい姿'), findsOneWidget);
      expect(find.text('書き換えた在りたくない姿'), findsOneWidget);
      final saved = (await repository.loadAll()).single;
      expect(saved.desiredGoal, '書き換えた在りたい姿');
      expect(saved.undesiredGoal, '書き換えた在りたくない姿');
    },
  );

  testWidgets(
    'empty SWOT quadrant "なし" stays readable on the scene background',
    (tester) async {
      await pumpScreen(tester, project: _project());

      expect(find.text('なし'), findsWidgets);

      for (final element in find.text('なし').evaluate()) {
        final text = element.widget as Text;
        final color = text.style?.color;
        expect(color, isNotNull);
        expect(
          AppPalette.contrastRatio(AppPalette.scene, color!),
          greaterThanOrEqualTo(4.5),
          reason: 'placeholder $color on scene ${AppPalette.scene}',
        );
      }
    },
  );
}
