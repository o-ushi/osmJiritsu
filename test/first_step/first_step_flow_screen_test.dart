// Widget tests for Stage1 Steps 9-10's FirstStepFlowScreen: open Chrome
// with the first-step-divergence prompt (via a fake launcher, no real
// browser launch) -> paste the answer back from the clipboard -> decide
// 最初の一歩 (adopt/merge/free-write) -> fix its 宣言文. Mirrors
// `strategy_flow_screen_test.dart`'s Chrome-AI-Mode test scaffolding.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/engine/chrome_ai_link.dart';
import 'package:osm_jiritsu/first_step/screens/first_step_flow_screen.dart';
import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';
import 'package:osm_jiritsu/wizard/state/wizard_state.dart';

import '../support/in_memory_analysis_history_repository.dart';
import '../support/in_memory_app_language_repository.dart';
import '../support/in_memory_project_order_repository.dart';

const _validFirstStepsJson = '''
{
  "steps": [
    {"text": "候補となる転職エージェントを3社リストアップする"},
    {"text": "職務経歴書のたたき台を書き始める"}
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

/// Preloads the wizard as if Stage1 Steps 1-8 already happened: theme,
/// goal, and a decided 方策 — this screen's own prerequisite.
class _PreloadedWizardNotifier extends WizardNotifier {
  @override
  WizardState build() => WizardState(
    theme: '新しいキャリアについて',
    desiredGoal: '自分の強みを活かして納得感のある転職をしたい',
    decidedStrategy: '強みを活かして転職エージェントに登録する',
  );
}

void main() {
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
        child: const MaterialApp(home: FirstStepFlowScreen()),
      ),
    );
    return launcher;
  }

  Future<void> pumpUntilConsentDialog(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    expect(find.text('最初の一歩の提案のためGoogleに送信しますか？'), findsOneWidget);
  }

  Future<void> acceptConsentDialog(WidgetTester tester) async {
    await tester.tap(find.text('同意してGoogleへ送信'));
    await tester.pump();
  }

  Future<void> reachEditor(WidgetTester tester) async {
    await pumpScreen(tester);
    await pumpUntilConsentDialog(tester);
    await acceptConsentDialog(tester);
    await tester.pumpAndSettle();

    await Clipboard.setData(const ClipboardData(text: _validFirstStepsJson));
    await tester.tap(find.text('貼り付けて確認する'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mounting sends theme/goal/decidedStrategy to Chrome after consent',
    (tester) async {
      final launcher = await pumpScreen(tester);
      await pumpUntilConsentDialog(tester);
      await acceptConsentDialog(tester);
      await tester.pumpAndSettle();

      expect(launcher.openedPrompts, hasLength(1));
      final prompt = launcher.openedPrompts.single;
      expect(prompt, contains('新しいキャリアについて'));
      expect(prompt, contains('自分の強みを活かして納得感のある転職をしたい'));
      expect(prompt, contains('強みを活かして転職エージェントに登録する'));
    },
  );

  testWidgets('pasting valid first steps shows the suggestion cards', (
    tester,
  ) async {
    await reachEditor(tester);

    expect(find.textContaining('転職エージェント'), findsWidgets);
    expect(find.text('あなたの最初の一歩'), findsOneWidget);
  });

  testWidgets(
    '"未採用／採用済" toggles a suggestion on/off without touching "あなたの最初の一歩"',
    (tester) async {
      await reachEditor(tester);

      expect(find.text('宣言文を確認する').hitTestable(), findsNothing);

      await tester.tap(find.text('未採用').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('転職エージェント'), findsOneWidget);
      expect(find.text('採用済'), findsOneWidget);
      expect(find.text('宣言文を確認する').hitTestable(), findsOneWidget);

      // Tapping the same card again turns it back off.
      await tester.tap(find.text('採用済'));
      await tester.pumpAndSettle();

      expect(find.text('宣言文を確認する').hitTestable(), findsNothing);
    },
  );

  testWidgets(
    '長押しで最初の一歩 opens an editor that rewords the suggestion in place',
    (tester) async {
      await reachEditor(tester);

      await tester.longPress(find.textContaining('転職エージェント'));
      await tester.pumpAndSettle();

      expect(find.text('最初の一歩を編集'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        '転職エージェントに3社応募する',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('転職エージェントに3社応募する'), findsOneWidget);
    },
  );

  testWidgets(
    '"AIに再度相談する" in the editor reopens the consent dialog for a fresh round trip',
    (tester) async {
      final launcher = await pumpScreen(tester);
      await pumpUntilConsentDialog(tester);
      await acceptConsentDialog(tester);
      await tester.pumpAndSettle();
      await Clipboard.setData(
        const ClipboardData(text: _validFirstStepsJson),
      );
      await tester.tap(find.text('貼り付けて確認する'));
      await tester.pumpAndSettle();

      expect(launcher.openedPrompts, hasLength(1));

      await tester.tap(find.text('AIに再度相談する'));
      await tester.pumpAndSettle();

      expect(find.text('最初の一歩の提案のためGoogleに送信しますか？'), findsOneWidget);
      await acceptConsentDialog(tester);
      await tester.pumpAndSettle();

      expect(launcher.openedPrompts, hasLength(2));
    },
  );

  testWidgets(
    'Step 10 end to end: decide, fix declaration, confirm saves to history '
    'and flips status to inProgress',
    (tester) async {
      await reachEditor(tester);

      await tester.enterText(find.byType(TextField), '転職エージェントに登録する');
      await tester.pumpAndSettle();

      await tester.tap(find.text('宣言文を確認する'));
      await tester.pumpAndSettle();

      // Auto-filled from Project.suggestedDeclaration.
      expect(
        find.text(
          '私は自分の強みを活かして納得感のある転職をしたいを目指しています。'
          'まずは転職エージェントに登録するを実践します。',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      expect(find.text('自律計画ができました'), findsOneWidget);

      final saved = await historyRepository.loadAll();
      expect(saved.single.decidedFirstStep, '転職エージェントに登録する');
      expect(saved.single.status, ProjectStatus.inProgress);
    },
  );
}
