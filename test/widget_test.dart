import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/data/analysis_history_repository.dart';
import 'package:osm_jiritsu/history/data/project_order_repository.dart';
import 'package:osm_jiritsu/history/data/start_screen_settings_repository.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/main.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';

import 'support/in_memory_analysis_history_repository.dart';
import 'support/in_memory_app_language_repository.dart';
import 'support/in_memory_project_order_repository.dart';
import 'support/in_memory_start_screen_settings_repository.dart';

const _strengthIdea = '高い技術力がある';
const _opportunityIdea = '市場が拡大している';
const _weaknessIdea = '資金が不足している';
const _threatIdea = '競合が増えている';

void main() {
  /// Pumps the real app (home is now `HistoryListScreen` — Step 5) and
  /// taps through to a fresh wizard run, since these tests exercise the
  /// wizard/matrix flow itself, not the history screen.
  Future<void> pumpApp(WidgetTester tester) async {
    // A real phone-ish aspect ratio avoids the classification grid
    // overflowing the tiny default test surface.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analysisHistoryRepositoryProvider.overrideWithValue(
            InMemoryAnalysisHistoryRepository(),
          ),
          appLanguageRepositoryProvider.overrideWithValue(
            InMemoryAppLanguageRepository(AppLanguage.japanese),
          ),
          projectOrderRepositoryProvider.overrideWithValue(
            InMemoryProjectOrderRepository(),
          ),
          startScreenSettingsRepositoryProvider.overrideWithValue(
            InMemoryStartScreenSettingsRepository(),
          ),
        ],
        child: const OsmJiritsuApp(),
      ),
    );
    await tester
        .pumpAndSettle(); // let the history provider's initial load resolve

    // Default start-screen setting is on (Gradus-style). With no projects
    // seeded, tapping「はじめる」skips the (empty) history list and lands
    // directly in a fresh wizard run — see HistoryListScreen.
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
  }

  Future<void> addIdea(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
  }

  Future<void> answerQuestion(
    WidgetTester tester,
    String ideaText,
    String evaluationLabel,
    String locusLabel,
  ) async {
    expect(find.text(ideaText), findsOneWidget);
    await tester.tap(find.text(evaluationLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(locusLabel));
    await tester.pumpAndSettle();
  }

  /// Fills the theme screen and taps through to the goal screen.
  Future<void> completeTheme(WidgetTester tester, String theme) async {
    await tester.enterText(find.byType(TextField), theme);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ゴールを考える'));
    await tester.pumpAndSettle();
  }

  /// Fills the goal screen's 在りたい姿 (and, if given, 在りたくない姿) and
  /// taps through to the idea dump screen. Assumes the goal screen is
  /// already showing (see [completeTheme]).
  Future<void> completeGoal(
    WidgetTester tester,
    String desiredGoal, {
    String? undesiredGoal,
  }) async {
    await tester.enterText(find.byType(TextField).at(0), desiredGoal);
    if (undesiredGoal != null) {
      await tester.enterText(find.byType(TextField).at(1), undesiredGoal);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('アイデアを出してみる'));
    await tester.pumpAndSettle();
  }

  /// Drives steps 1-4 (theme → goal → idea dump → quick classification) and
  /// lands on the SWOT matrix screen with one idea classified into each of
  /// the four quadrants.
  Future<void> reachMatrixScreenWithFourIdeas(WidgetTester tester) async {
    await pumpApp(tester);

    await completeTheme(tester, '新しいキャリアについて');
    await completeGoal(
      tester,
      '自分の強みを活かして納得感のある転職をしたい',
      undesiredGoal: '妥協して、納得感のないまま転職すること',
    );

    await addIdea(tester, _strengthIdea);
    await addIdea(tester, _opportunityIdea);
    await addIdea(tester, _weaknessIdea);
    await addIdea(tester, _threatIdea);
    await tester.tap(find.text('4件を分類する'));
    await tester.pumpAndSettle();

    // Two yes/no taps per idea — never a single combined 4-way SWOT choice.
    await answerQuestion(tester, _strengthIdea, '良いこと', '自分次第');
    await answerQuestion(tester, _opportunityIdea, '良いこと', 'まわりの状況');
    await answerQuestion(tester, _weaknessIdea, '気になること', '自分次第');
    await answerQuestion(tester, _threatIdea, '気になること', 'まわりの状況');

    await tester.tap(find.text('マトリクスを確認する'));
    await tester.pumpAndSettle();
  }

  testWidgets('classification lands each idea in the correct SWOT quadrant', (
    tester,
  ) async {
    await reachMatrixScreenWithFourIdeas(tester);

    expect(find.text(_strengthIdea), findsOneWidget);
    expect(find.text(_opportunityIdea), findsOneWidget);
    expect(find.text(_weaknessIdea), findsOneWidget);
    expect(find.text(_threatIdea), findsOneWidget);
    expect(find.text('強み'), findsOneWidget);
    expect(find.text('機会'), findsOneWidget);
    expect(find.text('弱み'), findsOneWidget);
    expect(find.text('脅威'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final ideas = container.read(wizardProvider).ideas;
    expect(
      ideas.firstWhere((i) => i.text == _strengthIdea).category,
      SwotCategory.strength,
    );
    expect(
      ideas.firstWhere((i) => i.text == _opportunityIdea).category,
      SwotCategory.opportunity,
    );
    expect(
      ideas.firstWhere((i) => i.text == _weaknessIdea).category,
      SwotCategory.weakness,
    );
    expect(
      ideas.firstWhere((i) => i.text == _threatIdea).category,
      SwotCategory.threat,
    );
  });

  testWidgets(
    'dragging a card onto another quadrant reclassifies it in state',
    (tester) async {
      await reachMatrixScreenWithFourIdeas(tester);

      // Drag the strength card onto the weakness quadrant. LongPressDraggable
      // requires the pointer to stay down past the long-press threshold
      // before a move is recognized as a drag rather than a scroll/tap.
      final cardCenter = tester.getCenter(find.text(_strengthIdea));
      final weaknessQuadrant = find.byKey(const ValueKey('quadrant-weakness'));
      final weaknessCenter = tester.getCenter(weaknessQuadrant);

      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(weaknessCenter);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final movedIdea = container
          .read(wizardProvider)
          .ideas
          .firstWhere((i) => i.text == _strengthIdea);
      expect(movedIdea.category, SwotCategory.weakness);

      expect(
        find.descendant(
          of: weaknessQuadrant,
          matching: find.text(_strengthIdea),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quadrant-strength')),
          matching: find.text(_strengthIdea),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'the theme screen CTA stays untappable until the theme is filled',
    (tester) async {
      await pumpApp(tester);

      // PrimaryCtaButton stays in the tree and only fades/slides in (plus
      // toggles IgnorePointer), so "hidden" is checked via hit-testability
      // rather than tree presence.
      final cta = find.text('ゴールを考える');
      expect(cta.hitTestable(), findsNothing);

      await tester.enterText(find.byType(TextField), 'テーマだけ入力');
      await tester.pumpAndSettle();
      expect(cta.hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'the goal screen CTA is gated on 在りたい姿 only — 在りたくない姿 stays optional',
    (tester) async {
      await pumpApp(tester);
      await completeTheme(tester, 'テーマ');

      final cta = find.text('アイデアを出してみる');
      expect(cta.hitTestable(), findsNothing);

      // Filling only 在りたくない姿 (the second field) is not enough.
      await tester.enterText(find.byType(TextField).at(1), '在りたくない姿だけ入力');
      await tester.pumpAndSettle();
      expect(cta.hitTestable(), findsNothing);

      // 在りたい姿 (the first field) alone is enough to proceed.
      await tester.enterText(find.byType(TextField).at(0), '在りたい姿を入力');
      await tester.pumpAndSettle();
      expect(cta.hitTestable(), findsOneWidget);
    },
  );
}
