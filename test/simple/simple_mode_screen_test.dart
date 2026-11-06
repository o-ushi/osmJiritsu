import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_file_io.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';
import 'package:osm_jiritsu/history/state/analysis_history_notifier.dart';
import 'package:osm_jiritsu/icloud_sync/data/icloud_sync_settings_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/simple_line.dart';
import 'package:osm_jiritsu/simple/screens/simple_mode_screen.dart';
import 'package:osm_jiritsu/theme/app_theme.dart';

import '../support/fake_analysis_file_io.dart';
import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_icloud_sync_settings_repository.dart';
import '../support/in_memory_project_order_repository.dart';
import '../support/in_memory_start_screen_settings_repository.dart';

Project _newSimpleProject() => Project(theme: '', entryMode: Project.modeSimple);

/// Set by [pumpSimpleScreen] so a test can read history back without
/// re-plumbing a container each time.
ProviderContainer? _container;

/// Awaited rather than read off `.value`: nothing on this screen *watches*
/// the history provider, so a test that hasn't triggered a save yet would
/// otherwise catch it still in its initial `AsyncLoading`.
Future<List<Project>> _history() =>
    _container!.read(analysisHistoryProvider.future);

Future<void> pumpSimpleScreen(
  WidgetTester tester, {
  Project? project,
  List<Project> seed = const [],
}) async {
  // Tall enough that the board and the 最初の一歩 strip both lay out without
  // the keyboard-squeeze scroll kicking in.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = InMemoryAnalysisHistoryRepository();
  for (final seeded in seed) {
    await repository.save(seeded);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analysisHistoryRepositoryProvider.overrideWithValue(repository),
        analysisFileIOProvider.overrideWithValue(FakeAnalysisFileIO()),
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
        ),
        projectOrderRepositoryProvider.overrideWithValue(
          InMemoryProjectOrderRepository(),
        ),
        startScreenSettingsRepositoryProvider.overrideWithValue(
          InMemoryStartScreenSettingsRepository(false, false),
        ),
        icloudSyncSettingsRepositoryProvider.overrideWithValue(
          InMemoryIcloudSyncSettingsRepository(),
        ),
      ],
      child: MaterialApp(
        home: SimpleModeScreen(project: project ?? _newSimpleProject()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Read from a descendant, not from the scope's own element — `containerOf`
  // looks upwards, so the scope can't find itself.
  _container = ProviderScope.containerOf(
    tester.element(find.byType(SimpleModeScreen)),
    listen: false,
  );
  addTearDown(() => _container = null);
}

/// Commits the field's text the way leaving it does — 簡易モード saves on
/// 確定 (focus loss), not per keystroke.
Future<void> _enterAndCommit(
  WidgetTester tester,
  Key fieldKey,
  String text,
) async {
  await tester.enterText(find.byKey(fieldKey), text);
  await tester.pumpAndSettle();
  // Unfocusing is what fires the save listener.
  tester.widget<TextField>(find.byKey(fieldKey)).focusNode!.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _tapHome(WidgetTester tester) async {
  await tester.tap(find.byTooltip('ホーム'));
  await tester.pumpAndSettle();
}

/// The colour a row's own [TextField] is actually painting its text in.
Color? _fieldColor(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).style?.color;

Future<void> _addLines(
  WidgetTester tester,
  Key addKey,
  Key Function(int) fieldKeyFor,
  List<String> texts,
) async {
  for (var index = 0; index < texts.length; index++) {
    await tester.tap(find.byKey(addKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(fieldKeyFor(index)), texts[index]);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('a new 簡易 project shows all four boxes', (tester) async {
    await pumpSimpleScreen(tester);

    // ゴール and 最初の一歩 are always exactly one box each…
    expect(find.byKey(SimpleModeScreen.goalCardKey), findsOneWidget);
    expect(find.byKey(SimpleModeScreen.goalFieldKey), findsOneWidget);
    expect(find.byKey(SimpleModeScreen.firstStepCardKey), findsOneWidget);
    expect(find.byKey(SimpleModeScreen.firstStepFieldKey), findsOneWidget);
    // …and 現状 / 方策 show their box (and label) even with no rows in them.
    expect(find.byKey(SimpleModeScreen.situationCardKey), findsOneWidget);
    expect(find.byKey(SimpleModeScreen.strategyCardKey), findsOneWidget);
    expect(find.text('現状'), findsOneWidget);
    expect(find.text('方策'), findsOneWidget);
    expect(find.byKey(SimpleModeScreen.situationFieldKey(0)), findsNothing);
    expect(find.byKey(SimpleModeScreen.strategyFieldKey(0)), findsNothing);
  });

  testWidgets('the board keeps ゴール top-right, 方策 centre, 現状 bottom-left', (
    tester,
  ) async {
    await pumpSimpleScreen(tester);

    final goal = tester.getRect(find.byKey(SimpleModeScreen.goalCardKey));
    final strategy = tester.getRect(
      find.byKey(SimpleModeScreen.strategyCardKey),
    );
    final situation = tester.getRect(
      find.byKey(SimpleModeScreen.situationCardKey),
    );
    final firstStep = tester.getRect(
      find.byKey(SimpleModeScreen.firstStepCardKey),
    );

    // Vertical order down the board: ゴール → 方策 → 現状 → 最初の一歩.
    expect(goal.top, lessThan(strategy.top));
    expect(strategy.top, lessThan(situation.top));
    expect(situation.bottom, lessThanOrEqualTo(firstStep.top));

    // ゴール hugs the right edge, 現状 the left.
    expect(goal.left, greaterThan(situation.left));
    expect(situation.left, lessThan(strategy.left));

    // 最初の一歩 spans the full width, unlike anything on the board.
    expect(firstStep.width, greaterThan(goal.width));
    expect(firstStep.width, greaterThan(strategy.width));
  });

  testWidgets('現状 stops at three rows', (tester) async {
    await pumpSimpleScreen(tester);

    await _addLines(
      tester,
      SimpleModeScreen.situationAddKey,
      SimpleModeScreen.situationFieldKey,
      ['現状1', '現状2', '現状3'],
    );

    expect(find.byKey(SimpleModeScreen.situationFieldKey(2)), findsOneWidget);
    // No way to reach a fourth row at all: the ＋ is gone.
    expect(find.byKey(SimpleModeScreen.situationAddKey), findsNothing);
    expect(find.byKey(SimpleModeScreen.situationFieldKey(3)), findsNothing);
  });

  testWidgets('方策 stops at three rows', (tester) async {
    await pumpSimpleScreen(tester);

    await _addLines(
      tester,
      SimpleModeScreen.strategyAddKey,
      SimpleModeScreen.strategyFieldKey,
      ['方策1', '方策2', '方策3'],
    );

    expect(find.byKey(SimpleModeScreen.strategyFieldKey(2)), findsOneWidget);
    expect(find.byKey(SimpleModeScreen.strategyAddKey), findsNothing);
    expect(find.byKey(SimpleModeScreen.strategyFieldKey(3)), findsNothing);
  });

  testWidgets('checking a 方策 row greys it, unchecking restores it', (
    tester,
  ) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '',
        entryMode: Project.modeSimple,
        simpleStrategies: [SimpleLine(text: '寝る前にスマホを置く')],
      ),
    );

    final fieldKey = SimpleModeScreen.strategyFieldKey(0);
    expect(_fieldColor(tester, fieldKey), isNot(AppPalette.inkMuted));

    await tester.tap(find.byKey(SimpleModeScreen.strategyCheckKey(0)));
    await tester.pumpAndSettle();
    expect(_fieldColor(tester, fieldKey), AppPalette.inkMuted);
    // The text itself stays readable — no strikethrough, nothing removed.
    expect(
      tester.widget<TextField>(find.byKey(fieldKey)).controller?.text,
      '寝る前にスマホを置く',
    );

    await tester.tap(find.byKey(SimpleModeScreen.strategyCheckKey(0)));
    await tester.pumpAndSettle();
    expect(_fieldColor(tester, fieldKey), isNot(AppPalette.inkMuted));
  });

  testWidgets('checking 最初の一歩 greys the card, unchecking restores it', (
    tester,
  ) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '',
        entryMode: Project.modeSimple,
        simpleFirstStep: SimpleLine(text: '今夜23時に充電器へ置く'),
      ),
    );

    const fieldKey = SimpleModeScreen.firstStepFieldKey;
    expect(_fieldColor(tester, fieldKey), isNot(AppPalette.inkMuted));

    await tester.tap(find.byKey(SimpleModeScreen.firstStepCheckKey));
    await tester.pumpAndSettle();
    expect(_fieldColor(tester, fieldKey), AppPalette.inkMuted);

    await tester.tap(find.byKey(SimpleModeScreen.firstStepCheckKey));
    await tester.pumpAndSettle();
    expect(_fieldColor(tester, fieldKey), isNot(AppPalette.inkMuted));
  });

  testWidgets('現状 carries no checkbox, unlike every other box', (
    tester,
  ) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '',
        entryMode: Project.modeSimple,
        simpleSituations: [SimpleLine(text: '夜ふかししている')],
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(SimpleModeScreen.situationCardKey),
        matching: find.byType(Checkbox),
      ),
      findsNothing,
    );
    // ゴール / 最初の一歩 both do, so this isn't just「no checkboxes anywhere」.
    expect(
      find.descendant(
        of: find.byKey(SimpleModeScreen.goalCardKey),
        matching: find.byType(Checkbox),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(SimpleModeScreen.firstStepCardKey),
        matching: find.byType(Checkbox),
      ),
      findsOneWidget,
    );
  });

  testWidgets('checking ゴール greys the card, unchecking restores it', (
    tester,
  ) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '朝の習慣を整える',
        desiredGoal: '朝の習慣を整える',
        entryMode: Project.modeSimple,
      ),
    );

    const fieldKey = SimpleModeScreen.goalFieldKey;
    expect(_fieldColor(tester, fieldKey), isNot(AppPalette.inkMuted));

    await tester.tap(find.byKey(SimpleModeScreen.goalCheckKey));
    await tester.pumpAndSettle();
    expect(_fieldColor(tester, fieldKey), AppPalette.inkMuted);
    expect(
      tester.widget<TextField>(find.byKey(fieldKey)).controller?.text,
      '朝の習慣を整える',
    );

    await tester.tap(find.byKey(SimpleModeScreen.goalCheckKey));
    await tester.pumpAndSettle();
    expect(_fieldColor(tester, fieldKey), isNot(AppPalette.inkMuted));
  });

  testWidgets('long-pressing a row deletes it once confirmed', (tester) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '',
        entryMode: Project.modeSimple,
        simpleStrategies: [
          SimpleLine(text: '方策A'),
          SimpleLine(text: '方策B'),
          SimpleLine(text: '方策C'),
        ],
      ),
    );

    expect(find.byKey(SimpleModeScreen.strategyAddKey), findsNothing);

    await tester.longPress(find.byKey(SimpleModeScreen.strategyHandleKey(0)));
    await tester.pumpAndSettle();
    expect(find.text('この行を削除しますか？'), findsOneWidget);

    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.byKey(SimpleModeScreen.strategyFieldKey(2)), findsNothing);
    // Deleting frees a slot, so the ＋ comes back.
    expect(find.byKey(SimpleModeScreen.strategyAddKey), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(SimpleModeScreen.strategyFieldKey(0)),
          )
          .controller
          ?.text,
      '方策B',
    );
  });

  testWidgets('cancelling the delete dialog keeps the row', (tester) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '',
        entryMode: Project.modeSimple,
        simpleSituations: [SimpleLine(text: '夜ふかししている')],
      ),
    );

    await tester.longPress(find.byKey(SimpleModeScreen.situationHandleKey(0)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.byKey(SimpleModeScreen.situationFieldKey(0)), findsOneWidget);
  });

  testWidgets('an existing 簡易 project restores all four boxes', (
    tester,
  ) async {
    await pumpSimpleScreen(
      tester,
      project: Project(
        theme: '朝の習慣を整える',
        desiredGoal: '朝の習慣を整える',
        entryMode: Project.modeSimple,
        simpleGoalDone: true,
        simpleSituations: [SimpleLine(text: '夜ふかししている')],
        simpleStrategies: [SimpleLine(text: '寝る前にスマホを置く', done: true)],
        simpleFirstStep: SimpleLine(text: '今夜23時に充電器へ置く'),
      ),
    );

    expect(
      tester
          .widget<TextField>(find.byKey(SimpleModeScreen.goalFieldKey))
          .controller
          ?.text,
      '朝の習慣を整える',
    );
    expect(
      tester.widget<Checkbox>(find.byKey(SimpleModeScreen.goalCheckKey)).value,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(SimpleModeScreen.situationFieldKey(0)),
          )
          .controller
          ?.text,
      '夜ふかししている',
    );
    expect(
      tester
          .widget<Checkbox>(find.byKey(SimpleModeScreen.strategyCheckKey(0)))
          .value,
      isTrue,
    );
    expect(
      _fieldColor(tester, SimpleModeScreen.strategyFieldKey(0)),
      AppPalette.inkMuted,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(SimpleModeScreen.firstStepFieldKey))
          .controller
          ?.text,
      '今夜23時に充電器へ置く',
    );
  });

  group('保存', () {
    testWidgets('committing ゴール saves it as both theme and desiredGoal', (
      tester,
    ) async {
      await pumpSimpleScreen(tester);

      await _enterAndCommit(
        tester,
        SimpleModeScreen.goalFieldKey,
        '  朝の習慣を整える  ',
      );

      final saved = (await _history()).single;
      expect(saved.entryMode, Project.modeSimple);
      // ゴール is the list row's heading, so it lands in `theme` too — both
      // trimmed.
      expect(saved.theme, '朝の習慣を整える');
      expect(saved.desiredGoal, '朝の習慣を整える');
      expect(saved.status, ProjectStatus.inProgress);
    });

    testWidgets('a wholly blank board is never written to history', (
      tester,
    ) async {
      await pumpSimpleScreen(tester);

      // Adding rows and ticking them is not content.
      await tester.tap(find.byKey(SimpleModeScreen.situationAddKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SimpleModeScreen.strategyAddKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SimpleModeScreen.strategyCheckKey(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SimpleModeScreen.firstStepCheckKey));
      await tester.pumpAndSettle();
      await _tapHome(tester);

      expect((await _history()), isEmpty);
    });

    testWidgets('ホーム flushes text that was never unfocused', (tester) async {
      await pumpSimpleScreen(tester);

      await tester.enterText(
        find.byKey(SimpleModeScreen.goalFieldKey),
        '朝の習慣を整える',
      );
      await tester.pumpAndSettle();
      expect((await _history()), isEmpty);

      await _tapHome(tester);

      expect((await _history()).single.theme, '朝の習慣を整える');
    });

    testWidgets('rows are trimmed, blanks dropped, and ids kept', (
      tester,
    ) async {
      final existing = Project(
        theme: '朝の習慣',
        desiredGoal: '朝の習慣',
        entryMode: Project.modeSimple,
        simpleStrategies: [
          SimpleLine(text: '寝る前にスマホを置く'),
          SimpleLine(text: 'カーテンを開けて寝る'),
        ],
      );
      await pumpSimpleScreen(tester, project: existing, seed: [existing]);

      // Blank out the second row and pad the first with whitespace.
      await tester.enterText(
        find.byKey(SimpleModeScreen.strategyFieldKey(1)),
        '   ',
      );
      await _enterAndCommit(
        tester,
        SimpleModeScreen.strategyFieldKey(0),
        '  寝る前にスマホを別室へ置く  ',
      );

      final saved = (await _history()).single;
      expect(saved.id, existing.id);
      expect(saved.simpleStrategies.single.text, '寝る前にスマホを別室へ置く');
      // Same row, same id — editing text doesn't mint a new one.
      expect(saved.simpleStrategies.single.id, existing.simpleStrategies.first.id);
    });

    testWidgets('toggling a 方策 checkbox saves and raises 進捗', (
      tester,
    ) async {
      final existing = Project(
        theme: '朝の習慣',
        desiredGoal: '朝の習慣',
        entryMode: Project.modeSimple,
        simpleStrategies: [SimpleLine(text: '寝る前にスマホを置く')],
      );
      await pumpSimpleScreen(tester, project: existing, seed: [existing]);
      expect((await _history()).single.progressRatio, 0.4);

      await tester.tap(find.byKey(SimpleModeScreen.strategyCheckKey(0)));
      await tester.pumpAndSettle();

      final saved = (await _history()).single;
      expect(saved.simpleStrategies.single.done, isTrue);
      expect(saved.progressRatio, 0.9);
    });

    testWidgets('checking ゴール saves 100% and flips 現況 to 完了', (
      tester,
    ) async {
      final existing = Project(
        theme: '朝の習慣',
        desiredGoal: '朝の習慣',
        entryMode: Project.modeSimple,
        status: ProjectStatus.inProgress,
      );
      await pumpSimpleScreen(tester, project: existing, seed: [existing]);
      expect((await _history()).single.progressRatio, 0.2);

      await tester.tap(find.byKey(SimpleModeScreen.goalCheckKey));
      await tester.pumpAndSettle();

      final saved = (await _history()).single;
      expect(saved.simpleGoalDone, isTrue);
      expect(saved.progressRatio, 1.0);
      // 100%なのに 実施中 のままでは辻褄が合わない — チェックが完了の宣言そのもの。
      expect(saved.status, ProjectStatus.completed);
    });

    testWidgets('unchecking ゴール reverts 現況 back to 実施中', (tester) async {
      final existing = Project(
        theme: '朝の習慣',
        desiredGoal: '朝の習慣',
        entryMode: Project.modeSimple,
        simpleGoalDone: true,
        status: ProjectStatus.completed,
      );
      await pumpSimpleScreen(tester, project: existing, seed: [existing]);

      await tester.tap(find.byKey(SimpleModeScreen.goalCheckKey));
      await tester.pumpAndSettle();

      final saved = (await _history()).single;
      expect(saved.simpleGoalDone, isFalse);
      expect(saved.status, ProjectStatus.inProgress);
    });

    testWidgets('emptying an existing 案件 and going ホーム deletes it', (
      tester,
    ) async {
      final existing = Project(
        theme: '朝の習慣',
        desiredGoal: '朝の習慣',
        entryMode: Project.modeSimple,
        simpleSituations: [SimpleLine(text: '夜ふかししている')],
        simpleFirstStep: SimpleLine(text: '今夜23時に充電器へ置く'),
      );
      await pumpSimpleScreen(tester, project: existing, seed: [existing]);
      expect((await _history()), hasLength(1));

      await tester.enterText(find.byKey(SimpleModeScreen.goalFieldKey), '');
      await tester.enterText(
        find.byKey(SimpleModeScreen.situationFieldKey(0)),
        '',
      );
      await tester.enterText(
        find.byKey(SimpleModeScreen.firstStepFieldKey),
        '',
      );
      await tester.pumpAndSettle();
      await _tapHome(tester);

      // No blank row left behind in 案件一覧.
      expect((await _history()), isEmpty);
    });

    testWidgets('a goal-less but written-on board stays 作成中', (tester) async {
      await pumpSimpleScreen(tester);

      await tester.tap(find.byKey(SimpleModeScreen.situationAddKey));
      await tester.pumpAndSettle();
      await _enterAndCommit(
        tester,
        SimpleModeScreen.situationFieldKey(0),
        '夜ふかししている',
      );

      final saved = (await _history()).single;
      expect(saved.status, ProjectStatus.preparing);
      expect(saved.simpleSituations.single.text, '夜ふかししている');
    });

    testWidgets('full-mode fields are never written from this screen', (
      tester,
    ) async {
      await pumpSimpleScreen(tester);

      await _enterAndCommit(
        tester,
        SimpleModeScreen.goalFieldKey,
        '朝の習慣を整える',
      );

      final saved = (await _history()).single;
      expect(saved.matrix.isEmpty, isTrue);
      expect(saved.decidedStrategy, '');
      expect(saved.decidedFirstStep, '');
      expect(saved.declaration, '');
      expect(saved.situationNotes, isEmpty);
      expect(saved.undesiredGoal, '');
    });
  });
}
