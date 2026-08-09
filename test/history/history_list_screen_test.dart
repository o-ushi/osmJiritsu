import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_file_io.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';
import 'package:osm_jiritsu/history/screens/history_list_screen.dart';
import 'package:osm_jiritsu/icloud_sync/data/icloud_sync_settings_repository.dart';
import 'package:osm_jiritsu/history/services/analysis_export_service.dart';
import 'package:osm_jiritsu/history/state/analysis_history_notifier.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';
import 'package:osm_jiritsu/theme/app_theme.dart';

import '../support/fake_analysis_file_io.dart';
import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_icloud_sync_settings_repository.dart';
import '../support/in_memory_project_order_repository.dart';
import '../support/in_memory_start_screen_settings_repository.dart';

Future<void> _tapDataMenuItem(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('データ'));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

Future<void> _tapMoreMenuItem(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('その他'));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

Project _project(
  String theme, {
  DateTime? updatedAt,
  ProjectStatus status = ProjectStatus.preparing,
  DateTime? deadline,
}) {
  final now = updatedAt ?? DateTime.utc(2026, 1, 1);
  return Project(
    createdAt: now,
    updatedAt: now,
    theme: theme,
    desiredGoal: 'ゴール',
    status: status,
    deadline: deadline,
    matrix: SwotMatrix(
      strengths: [SwotItem(category: SwotCategory.strength, content: '強み1')],
    ),
  );
}

Future<InMemoryAnalysisHistoryRepository> pumpScreen(
  WidgetTester tester, {
  required FakeAnalysisFileIO fileIO,
  List<Project> seed = const [],
  bool alwaysShowStartScreen = false,
}) async {
  final repository = InMemoryAnalysisHistoryRepository();
  for (final project in seed) {
    await repository.save(project);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analysisHistoryRepositoryProvider.overrideWithValue(repository),
        analysisFileIOProvider.overrideWithValue(fileIO),
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
        ),
        projectOrderRepositoryProvider.overrideWithValue(
          InMemoryProjectOrderRepository(),
        ),
        startScreenSettingsRepositoryProvider.overrideWithValue(
          InMemoryStartScreenSettingsRepository(alwaysShowStartScreen),
        ),
        icloudSyncSettingsRepositoryProvider.overrideWithValue(
          InMemoryIcloudSyncSettingsRepository(),
        ),
      ],
      child: const MaterialApp(home: HistoryListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _tapStart(WidgetTester tester) async {
  await tester.tap(find.text('はじめる'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the Gradus-style start screen when the setting is on', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      alwaysShowStartScreen: true,
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('osmJiritsu'), findsOneWidget);
    expect(
      find.text('自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。'),
      findsOneWidget,
    );
    expect(find.text('次回から表示しない'), findsOneWidget);
    expect(find.text('はじめる'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsWidgets);
  });

  testWidgets(
    '起動時にスタート画面を表示 が off の場合、案件があれば直接一覧を表示する',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [_project('既存の案件')],
      );

      expect(find.text('既存の案件'), findsOneWidget);
      expect(
        find.text('自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。'),
        findsNothing,
      );
    },
  );

  testWidgets(
    '案件が0件の状態で「はじめる」をタップすると、空の一覧ではなく新規作成画面（テーマ入力）に移る',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        alwaysShowStartScreen: true,
      );

      await _tapStart(tester);

      expect(find.text('まずテーマを決めよう'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    '起動時にスタート画面を表示 が on の場合、案件があってもスタート画面から始まり、「はじめる」で一覧に移る',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [_project('既存の案件')],
        alwaysShowStartScreen: true,
      );

      expect(
        find.text('自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。'),
        findsOneWidget,
      );
      expect(find.text('既存の案件'), findsNothing);
      expect(find.text('はじめる'), findsOneWidget);

      await _tapStart(tester);

      expect(find.text('既存の案件'), findsOneWidget);
      expect(
        find.text('自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。'),
        findsNothing,
      );
    },
  );

  testWidgets(
    '「次回から表示しない」にチェックして「はじめる」と設定がオフになる',
    (tester) async {
      final settings = InMemoryStartScreenSettingsRepository(true);
      final repository = InMemoryAnalysisHistoryRepository();
      await repository.save(_project('既存の案件'));
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
            startScreenSettingsRepositoryProvider.overrideWithValue(settings),
            icloudSyncSettingsRepositoryProvider.overrideWithValue(
              InMemoryIcloudSyncSettingsRepository(),
            ),
          ],
          child: const MaterialApp(home: HistoryListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapStart(tester);

      expect(find.text('既存の案件'), findsOneWidget);
      expect(settings.load(), isFalse);
    },
  );

  testWidgets(
    '起動時にスタート画面を表示 が on の場合、案件一覧を右スワイプするとスタート画面に戻る',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [_project('既存の案件')],
        alwaysShowStartScreen: true,
      );

      // Dismiss the forced start screen first, landing on the project list.
      await _tapStart(tester);
      expect(find.text('既存の案件'), findsOneWidget);

      // Swipe right starting from the list's top-left padding — outside
      // any row's own swipe-to-delete Dismissible — which the outer
      // detector picks up directly.
      await tester.flingFrom(const Offset(8, 8), const Offset(300, 0), 800);
      await tester.pumpAndSettle();

      expect(
        find.text('自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。'),
        findsOneWidget,
      );
      expect(find.text('既存の案件'), findsNothing);
    },
  );

  testWidgets('"新規追加" in the bottom toolbar also starts the wizard', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      seed: [_project('既存の案件')],
    );

    await tester.tap(find.byTooltip('新規追加'));
    await tester.pumpAndSettle();

    expect(find.text('それでは始めましょう'), findsOneWidget);
  });

  testWidgets(
    '▶️ opens the dashboard for a project past 作成中',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [
          _project(
            '古い案件',
            updatedAt: DateTime.utc(2026, 1, 1),
            status: ProjectStatus.inProgress,
          ),
          _project(
            '新しい案件',
            updatedAt: DateTime.utc(2026, 1, 5),
            status: ProjectStatus.inProgress,
          ),
        ],
      );

      expect(find.text('新しい案件'), findsOneWidget);
      expect(find.text('古い案件'), findsOneWidget);

      // Newest-first: "新しい案件" is the first row's ▶️.
      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded).first);
      await tester.pumpAndSettle();

      // DashboardScreen's AppBar title is the project's theme.
      expect(find.text('新しい案件'), findsOneWidget);
      expect(find.text('強み1'), findsOneWidget);
    },
  );

  testWidgets(
    '▶️ on a 作成中 project with a finished matrix resumes at the matrix screen',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [_project('準備中の案件', status: ProjectStatus.preparing)],
      );

      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pumpAndSettle();

      // Matrix AppBar shows goals, not a fixed "今の状況" title.
      expect(find.textContaining('在りたい姿'), findsWidgets);
      expect(find.text('強み1'), findsOneWidget);
    },
  );

  testWidgets(
    '▶️ on a 作成中 project with no matrix yet resumes the input wizard',
    (tester) async {
      final now = DateTime.utc(2026, 1, 1);
      final barelyStarted = Project(
        createdAt: now,
        updatedAt: now,
        theme: 'テーマのみ決めた案件',
        status: ProjectStatus.preparing,
      );
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [barelyStarted],
      );

      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pumpAndSettle();

      // theme is already set, desiredGoal isn't — lands on the goal step.
      expect(find.text('ゴールを教えてください'), findsOneWidget);
    },
  );

  testWidgets('進捗率 shows for every project regardless of 現況', (tester) async {
    await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      seed: [
        _project(
          '準備中の案件',
          updatedAt: DateTime.utc(2026, 1, 1),
          status: ProjectStatus.preparing,
        ),
        _project(
          '実施中の案件',
          updatedAt: DateTime.utc(2026, 1, 2),
          status: ProjectStatus.inProgress,
        ),
        _project(
          '休憩中の案件',
          updatedAt: DateTime.utc(2026, 1, 3),
          status: ProjectStatus.onBreak,
        ),
      ],
    );

    expect(find.textContaining('%'), findsNWidgets(3));
  });

  testWidgets('editing a theme via the row\'s edit icon renames it', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      seed: [_project('元のテーマ')],
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('テーマを編集'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '新しいテーマ');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('新しいテーマ'), findsOneWidget);
    expect(find.text('元のテーマ'), findsNothing);
    expect((await repository.loadAll()).single.theme, '新しいテーマ');
  });

  testWidgets('tapping ⭐️ on a row toggles Project.isFavorite', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      seed: [_project('お気に入り候補')],
    );

    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    expect((await repository.loadAll()).single.isFavorite, isTrue);

    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect((await repository.loadAll()).single.isFavorite, isFalse);
  });

  testWidgets('deleting a project from its row removes it from the list', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      seed: [_project('削除対象')],
    );

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.text('削除対象'), findsNothing);
    // With the start-screen setting off (pumpScreen default), an empty
    // list is just empty — no forced Gradus start screen.
    expect(find.text('はじめる'), findsNothing);
  });

  testWidgets(
    'long-pressing a row and dragging it onto another swaps their order',
    (tester) async {
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [
          _project('A', updatedAt: DateTime.utc(2026, 1, 1)),
          _project('B', updatedAt: DateTime.utc(2026, 1, 2)),
        ],
      );

      List<String> currentThemeOrder() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((text) => text == 'A' || text == 'B')
          .toList();

      // Newest-first by default: B, then A.
      expect(currentThemeOrder(), ['B', 'A']);

      // Long-press the second row (A), hold past the long-press threshold
      // so `LongPressDraggable` picks it up, then drag it onto the first
      // row (B) and release.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('A')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(tester.getCenter(find.text('B')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(currentThemeOrder(), ['A', 'B']);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final projects = container.read(analysisHistoryProvider).value!;
      expect(projects.map((p) => p.theme), ['A', 'B']);
    },
  );

  testWidgets('export shares a JSON file containing every project', (
    tester,
  ) async {
    final fileIO = FakeAnalysisFileIO();
    await pumpScreen(tester, fileIO: fileIO, seed: [_project('テーマA')]);

    await _tapDataMenuItem(tester, 'JSONバックアップ');
    final shared = fileIO.sharedFiles.single;
    expect(shared.fileName, endsWith('.json'));

    final decoded = AnalysisExportService.decodeProjects(shared.jsonText);
    expect(decoded.single.theme, 'テーマA');
  });

  testWidgets('export with no history shows a snackbar instead of sharing', (
    tester,
  ) async {
    final fileIO = FakeAnalysisFileIO();
    await pumpScreen(tester, fileIO: fileIO);

    await _tapDataMenuItem(tester, 'JSONバックアップ');

    expect(fileIO.sharedFiles, isEmpty);
    expect(find.text('エクスポートできる分析がまだありません'), findsOneWidget);
  });

  testWidgets('import merges projects from a picked file into history', (
    tester,
  ) async {
    final fileIO = FakeAnalysisFileIO()
      ..pickedJsonText = AnalysisExportService.encodeProjects([
        _project('インポートされた分析'),
      ]);
    await pumpScreen(tester, fileIO: fileIO);

    await _tapDataMenuItem(tester, 'JSONを取り込む');
    expect(find.text('インポートされた分析'), findsOneWidget);
  });

  testWidgets(
    'import shows an error for a malformed file instead of crashing',
    (tester) async {
      final fileIO = FakeAnalysisFileIO()..pickedJsonText = 'not valid json';
      await pumpScreen(tester, fileIO: fileIO);

      await _tapDataMenuItem(tester, 'JSONを取り込む');

      expect(find.textContaining('読み込みに失敗しました'), findsOneWidget);
    },
  );

  testWidgets(
    '設定 consolidates 言語/初期化/プライバシーとデータ, and deletes history plus temporary exports',
    (tester) async {
      final fileIO = FakeAnalysisFileIO();
      final repository = await pumpScreen(
        tester,
        fileIO: fileIO,
        seed: [_project('削除対象')],
      );

      await _tapMoreMenuItem(tester, '設定');
      expect(find.text('言語'), findsOneWidget);
      expect(find.text('すべてのデータを削除'), findsWidgets);
      expect(find.text('プライバシーとデータ'), findsOneWidget);

      await tester.tap(find.text('プライバシーとデータ'));
      await tester.pumpAndSettle();
      expect(find.text('プライバシーポリシー'), findsOneWidget);
      expect(find.text('Google プライバシーポリシー'), findsOneWidget);
      expect(find.text('Apple プライバシーポリシー'), findsOneWidget);
      expect(find.text('Google AIによる方策提案'), findsOneWidget);
      expect(find.text('JSONバックアップ'), findsNothing);

      final deleteAll = find.widgetWithText(
        FilledButton,
        'すべてのデータを削除',
      );
      await tester.scrollUntilVisible(deleteAll, 200);
      await tester.pumpAndSettle();
      expect(deleteAll, findsOneWidget);

      await tester.tap(deleteAll);
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      expect(await repository.loadAll(), isEmpty);
      expect(fileIO.temporaryExportsDeleted, isTrue);
      expect(find.text('端末内のアプリデータを削除しました'), findsOneWidget);
    },
  );

  testWidgets('HELP opens the 自律とは explanation screen', (tester) async {
    await pumpScreen(tester, fileIO: FakeAnalysisFileIO());

    await _tapMoreMenuItem(tester, 'ヘルプ');

    expect(find.text('自律とは'), findsOneWidget);

    await tester.tap(find.text('自律とは'));
    await tester.pumpAndSettle();

    expect(find.text('自律の定義'), findsOneWidget);
  });

  testWidgets('shows deadline on a list row when set', (tester) async {
    await pumpScreen(
      tester,
      fileIO: FakeAnalysisFileIO(),
      seed: [
        _project('期限あり案件', deadline: DateTime(2099, 3, 15)),
        _project('期限なし案件'),
      ],
    );

    expect(find.text('期限: 2099/03/15'), findsOneWidget);
    expect(find.textContaining('期限:'), findsOneWidget);
  });

  testWidgets(
    'overdue deadline paints the row background overdueYellow',
    (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await pumpScreen(
        tester,
        fileIO: FakeAnalysisFileIO(),
        seed: [
          _project('期限切れ案件', deadline: yesterday),
          _project('期限内案件', deadline: DateTime(2099, 12, 31)),
        ],
      );

      expect(find.textContaining('期限:'), findsNWidgets(2));

      final overdueCard = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('期限切れ案件'),
              matching: find.byType(Container),
            )
            .first,
      );
      final okCard = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('期限内案件'),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(
        (overdueCard.decoration as BoxDecoration).color,
        AppPalette.overdueYellow,
      );
      expect(
        (okCard.decoration as BoxDecoration).color,
        isNot(AppPalette.overdueYellow),
      );
    },
  );
}
