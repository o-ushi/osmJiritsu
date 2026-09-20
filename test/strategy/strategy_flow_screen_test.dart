// Widget tests for Stage1 Steps 5-8's StrategyFlowScreen: open Chrome with
// the strategy-divergence prompt (via a fake launcher, no real browser
// launch) -> paste the answer back from the clipboard -> decide a
// strategy (adopt/merge/free-write) -> jiritsu check -> confirm. Mirrors
// the deleted `action_plan_screen_test.dart`'s Chrome-AI-Mode test
// scaffolding.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/engine/chrome_ai_link.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/strategy/screens/strategy_flow_screen.dart';
import 'package:osm_jiritsu/wizard/models/classification_axes.dart';
import 'package:osm_jiritsu/wizard/models/wizard_idea.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';
import 'package:osm_jiritsu/wizard/state/wizard_state.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_project_order_repository.dart';

const _validStrategiesJson = '''
{
  "strategies": [
    {
      "text": "技術ブログを3本公開して認知を広げる",
      "rationale": "高い技術力(強み)を市場拡大(機会)に結びつけるため"
    },
    {
      "text": "資金調達の相談先を3社に絞る",
      "rationale": "資金不足(弱み)を解消しないと機会を活かせないため"
    }
  ]
}
''';

class FakeChromeAiLauncher implements ChromeAiLauncher {
  final List<String> openedPrompts = [];

  @override
  Future<void> openWithPrompt(String prompt) async {
    openedPrompts.add(prompt);
  }
}

/// Preloads the wizard with a theme, both goals, and one classified idea
/// per quadrant, so the screen has a non-empty matrix to build a prompt
/// from.
class _PreloadedWizardNotifier extends WizardNotifier {
  @override
  WizardState build() => WizardState(
    theme: '新しいキャリアについて',
    desiredGoal: '自分の強みを活かして納得感のある転職をしたい',
    undesiredGoal: '妥協して転職すること',
    ideas: [
      WizardIdea(
        text: '高い技術力',
        evaluation: EvaluationAxis.positive,
        locus: LocusAxis.internal,
      ),
      WizardIdea(
        text: '知名度不足',
        evaluation: EvaluationAxis.negative,
        locus: LocusAxis.internal,
      ),
      WizardIdea(
        text: '市場が拡大している',
        evaluation: EvaluationAxis.positive,
        locus: LocusAxis.external,
      ),
      WizardIdea(
        text: '競合が増えている',
        evaluation: EvaluationAxis.negative,
        locus: LocusAxis.external,
      ),
    ],
  );
}

void main() {
  // `flutter_test`'s built-in Clipboard mock hangs indefinitely in this
  // environment, so install a minimal in-memory handler for the two
  // methods this flow actually needs (mirrors the deleted action-plan
  // screen test's workaround).
  String? mockClipboardText;

  setUp(() {
    mockClipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'Clipboard.setData':
              mockClipboardText =
                  (methodCall.arguments as Map)['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return {'text': mockClipboardText};
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  late InMemoryAnalysisHistoryRepository historyRepository;

  Future<FakeChromeAiLauncher> pumpScreen(WidgetTester tester) async {
    // A real phone-ish aspect ratio, tall enough that the strategy
    // editor's suggestion cards + CTA don't need scrolling to hit-test.
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final launcher = FakeChromeAiLauncher();
    historyRepository = InMemoryAnalysisHistoryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chromeAiLauncherProvider.overrideWithValue(launcher),
          wizardProvider.overrideWith(_PreloadedWizardNotifier.new),
          analysisHistoryRepositoryProvider.overrideWithValue(
            historyRepository,
          ),
          appLanguageRepositoryProvider.overrideWithValue(
            InMemoryAppLanguageRepository(AppLanguage.japanese),
          ),
          projectOrderRepositoryProvider.overrideWithValue(
            InMemoryProjectOrderRepository(),
          ),
        ],
        child: const MaterialApp(home: StrategyFlowScreen()),
      ),
    );
    return launcher;
  }

  Future<void> pumpUntilConsentDialog(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    expect(find.text('方策提案のためGoogleに送信しますか？'), findsOneWidget);
  }

  Future<void> acceptConsentDialog(WidgetTester tester) async {
    await tester.tap(find.text('同意してGoogleへ送信'));
    await tester.pump();
  }

  /// Drives all the way from mount through to the strategy editor
  /// (Step 6), with the two sample suggestions parsed and showing.
  Future<FakeChromeAiLauncher> reachEditor(WidgetTester tester) async {
    final launcher = await pumpScreen(tester);
    await pumpUntilConsentDialog(tester);
    await acceptConsentDialog(tester);
    await tester.pumpAndSettle();

    await Clipboard.setData(const ClipboardData(text: _validStrategiesJson));
    await tester.tap(find.text('貼り付けて確認する'));
    await tester.pumpAndSettle();
    return launcher;
  }

  testWidgets(
    'mounting shows a consent dialog, then sends theme/goals/SWOT to Chrome',
    (tester) async {
      final launcher = await pumpScreen(tester);
      await pumpUntilConsentDialog(tester);

      expect(launcher.openedPrompts, isEmpty);

      await acceptConsentDialog(tester);
      await tester.pumpAndSettle();

      expect(launcher.openedPrompts, hasLength(1));
      final prompt = launcher.openedPrompts.single;
      expect(prompt, contains('新しいキャリアについて'));
      expect(prompt, contains('自分の強みを活かして納得感のある転職をしたい'));
      expect(prompt, contains('妥協して転職すること'));
      expect(prompt, contains('高い技術力'));
      // 内発的動機づけの3つの正式な問いがすべてプロンプトに含まれる。
      expect(prompt, contains('自分で決められるか？'));
      expect(prompt, contains('成果が分かりやすいか？'));
      expect(prompt, contains('周りと繋がっているか？'));

      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipboard?.text, prompt);

      expect(find.text('Chromeでの回答を確認してください'), findsOneWidget);
    },
  );

  testWidgets('pasting valid strategies shows the suggestion cards and editor', (
    tester,
  ) async {
    await reachEditor(tester);

    expect(find.textContaining('技術ブログ'), findsOneWidget);
    expect(find.textContaining('資金調達'), findsOneWidget);
    expect(find.text('あなたの方策'), findsOneWidget);
  });

  testWidgets('an empty clipboard shows a retryable paste-failed state', (
    tester,
  ) async {
    await pumpScreen(tester);
    await pumpUntilConsentDialog(tester);
    await acceptConsentDialog(tester);
    await tester.pumpAndSettle();

    await Clipboard.setData(const ClipboardData(text: ''));
    await tester.tap(find.text('貼り付けて確認する'));
    await tester.pumpAndSettle();

    expect(find.text('読み取れませんでした'), findsOneWidget);
    expect(find.textContaining('クリップボードが空でした'), findsOneWidget);
  });

  testWidgets(
    '"未採用／採用済" toggles a suggestion on/off without touching "あなたの方策"',
    (tester) async {
      await reachEditor(tester);

      expect(find.byIcon(Icons.check_rounded), findsNothing);
      // Nothing decided yet, so the CTA isn't tappable.
      expect(find.text('内発度をチェックする').hitTestable(), findsNothing);

      await tester.tap(find.text('未採用').first);
      await tester.pumpAndSettle();

      // Toggling on shows the suggestion's text only once (in the card
      // itself) — it's no longer appended into the free-text field.
      expect(find.textContaining('技術ブログ'), findsOneWidget);
      // The toggled-on card's button swaps its icon so the selection reads
      // at a glance, in addition to its background color changing.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('採用済'), findsOneWidget);
      expect(find.text('内発度をチェックする').hitTestable(), findsOneWidget);

      // Tapping the same card again turns it back off
      // ("選んでみたもののやっぱりやめた").
      await tester.tap(find.text('採用済'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.text('内発度をチェックする').hitTestable(), findsNothing);
    },
  );

  testWidgets(
    '長押しで方策 opens an editor that rewords the suggestion in place',
    (tester) async {
      await reachEditor(tester);

      await tester.longPress(find.textContaining('技術ブログ'));
      await tester.pumpAndSettle();

      expect(find.text('方策を編集'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        '週2にブログを1本公開する',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('週2にブログを1本公開する'), findsOneWidget);
      expect(find.textContaining('技術ブログ'), findsNothing);
    },
  );

  testWidgets(
    'Step 6→7→8 loop: check, edit, re-check, then confirm saves to history',
    (tester) async {
      await reachEditor(tester);

      await tester.enterText(find.byType(TextField), '自分で決めた方策');
      await tester.pumpAndSettle();

      await tester.tap(find.text('内発度をチェックする'));
      await tester.pumpAndSettle();

      expect(find.text('内発度チェック'), findsOneWidget);
      expect(find.text('自分で決めた方策'), findsOneWidget);
      expect(find.text('0 / 3 満たしている'), findsOneWidget);

      // Answer one of the three yes/no switches.
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 満たしている'), findsOneWidget);

      // Step 8: loop back to the editor without losing that answer.
      await tester.tap(find.text('方策を編集する'));
      await tester.pumpAndSettle();
      expect(find.text('あなたの方策'), findsOneWidget);

      await tester.tap(find.text('内発度をチェックする'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 満たしている'), findsOneWidget);

      // "納得した" ends the loop.
      await tester.tap(find.text('納得した'));
      await tester.pumpAndSettle();

      expect(find.text('方策を決めた'), findsOneWidget);
      expect(find.text('自分で決めた方策'), findsOneWidget);

      final saved = await historyRepository.loadAll();
      expect(saved.single.decidedStrategy, '自分で決めた方策');
      expect(saved.single.jiritsuCheck.satisfiedCount, 1);
    },
  );

  testWidgets(
    '"AIに再度相談する" in the editor reopens the consent dialog for a fresh round trip',
    (tester) async {
      final launcher = await reachEditor(tester);
      expect(launcher.openedPrompts, hasLength(1));

      await tester.tap(find.text('AIに再度相談する'));
      await tester.pumpAndSettle();

      expect(find.text('方策提案のためGoogleに送信しますか？'), findsOneWidget);
      await acceptConsentDialog(tester);
      await tester.pumpAndSettle();

      expect(launcher.openedPrompts, hasLength(2));
    },
  );

  testWidgets(
    'a toggled-on suggestion combines with "あなたの方策" into the final saved strategy',
    (tester) async {
      await reachEditor(tester);

      await tester.tap(find.text('未採用').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '独自の方策も追加');
      await tester.pumpAndSettle();

      await tester.tap(find.text('内発度をチェックする'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('納得した'));
      await tester.pumpAndSettle();

      final saved = await historyRepository.loadAll();
      expect(
        saved.single.decidedStrategy,
        '技術ブログを3本公開して認知を広げる\n独自の方策も追加',
      );
    },
  );
}
