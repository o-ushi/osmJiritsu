// Unit tests for the Stage1 Steps 6-8 decide/check/redefine loop —
// StrategyFlowNotifier's pure state transitions, with no Chrome/clipboard
// involved (that round trip is covered by the widget test instead). A
// `build()` override seeds the notifier straight into `StrategyFlowDeciding`
// so these tests don't need to go through Step 5's launch/paste first.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/jiritsu.dart';
import 'package:osm_jiritsu/models/jiritsu_check.dart';
import 'package:osm_jiritsu/models/strategy_suggestion.dart';
import 'package:osm_jiritsu/strategy/state/strategy_flow_notifier.dart';
import 'package:osm_jiritsu/strategy/state/strategy_flow_state.dart';

final _suggestions = [
  StrategySuggestion(text: '方策A', rationale: '理由A'),
  StrategySuggestion(text: '方策B', rationale: '理由B'),
];

class _PreloadedStrategyFlowNotifier extends StrategyFlowNotifier {
  @override
  StrategyFlowState build() =>
      StrategyFlowDeciding(suggestions: _suggestions);
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        strategyFlowProvider.overrideWith(_PreloadedStrategyFlowNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    // strategyFlowProvider is `.autoDispose`; keep it alive for the whole
    // test via a standing listener, same as a watching widget would.
    container.listen(strategyFlowProvider, (_, _) {}, fireImmediately: true);
  });

  StrategyFlowDeciding readDeciding() =>
      container.read(strategyFlowProvider) as StrategyFlowDeciding;

  group('Step 6: composing the decided strategy', () {
    test('setOwnStrategyText overwrites the free-text field', () {
      container
          .read(strategyFlowProvider.notifier)
          .setOwnStrategyText('自分で書いた方策');
      expect(readDeciding().decidedStrategy, '自分で書いた方策');
    });

    test('toggleSuggestion turns a suggestion on, folding it into decidedStrategy', () {
      container.read(strategyFlowProvider.notifier).toggleSuggestion(_suggestions[0]);
      expect(readDeciding().decidedStrategy, '方策A');
    });

    test('toggleSuggestion combines several toggled-on suggestions', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.toggleSuggestion(_suggestions[0]);
      notifier.toggleSuggestion(_suggestions[1]);
      expect(readDeciding().decidedStrategy, '方策A\n方策B');
    });

    test('toggleSuggestion records the suggestion as adopted', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.toggleSuggestion(_suggestions[0]);
      expect(
        readDeciding().adoptedSuggestionIds,
        {_suggestions[0].id},
      );
    });

    test(
      'toggleSuggestion is a real toggle: tapping the same suggestion twice '
      '"選んでみたもののやっぱりやめた" turns it back off',
      () {
        final notifier = container.read(strategyFlowProvider.notifier);
        notifier.toggleSuggestion(_suggestions[0]);
        notifier.toggleSuggestion(_suggestions[0]);
        expect(readDeciding().decidedStrategy, isEmpty);
        expect(readDeciding().adoptedSuggestionIds, isEmpty);
      },
    );

    test(
      'the decided strategy combines toggled-on suggestions with ownStrategyText',
      () {
        final notifier = container.read(strategyFlowProvider.notifier);
        notifier.toggleSuggestion(_suggestions[0]);
        notifier.setOwnStrategyText('自分だけの方策');
        expect(readDeciding().decidedStrategy, '方策A\n自分だけの方策');
      },
    );

    test('editSuggestionText rewords a suggestion in place, keeping its id', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.editSuggestionText(_suggestions[0], '週2に変更');
      final edited = readDeciding().suggestions[0];
      expect(edited.id, _suggestions[0].id);
      expect(edited.text, '週2に変更');
    });

    test(
      'editing a toggled-on suggestion is reflected immediately in decidedStrategy',
      () {
        final notifier = container.read(strategyFlowProvider.notifier);
        notifier.toggleSuggestion(_suggestions[0]);
        notifier.editSuggestionText(_suggestions[0], '週2に変更');
        expect(readDeciding().decidedStrategy, '週2に変更');
      },
    );

    test('editSuggestionText no-ops on blank text', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.editSuggestionText(_suggestions[0], '   ');
      expect(readDeciding().suggestions[0].text, '方策A');
    });

    test('canProceedToCheck/canConfirm are false until something is decided', () {
      final state = readDeciding();
      expect(state.decidedStrategy, isEmpty);
      expect(state.canProceedToCheck, isFalse);
      expect(state.canConfirm, isFalse);
    });
  });

  group('Step 6→7: entering the jiritsu check', () {
    test('showJiritsuCheck no-ops while decidedStrategy is still blank', () {
      container.read(strategyFlowProvider.notifier).showJiritsuCheck();
      expect(readDeciding().showingCheck, isFalse);
    });

    test('showJiritsuCheck switches to the check screen once decided', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.setOwnStrategyText('決めた方策');
      notifier.showJiritsuCheck();
      expect(readDeciding().showingCheck, isTrue);
    });
  });

  group('Step 7: jiritsu check answers', () {
    test('setJiritsuAnswer updates only the targeted element', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.setOwnStrategyText('決めた方策');
      notifier.setJiritsuAnswer(JiritsuElement.selfDetermined, true);
      notifier.setJiritsuAnswer(JiritsuElement.sharedGoal, true);

      final check = readDeciding().jiritsuCheck;
      expect(check.selfDetermined, isTrue);
      expect(check.clearOutcome, isFalse);
      expect(check.sharedGoal, isTrue);
      expect(check.satisfiedCount, 2);
    });
  });

  group('Step 8: redefine loop + confirm', () {
    test('editStrategy loops back without losing the check answers', () {
      final notifier = container.read(strategyFlowProvider.notifier);
      notifier.setOwnStrategyText('決めた方策');
      notifier.showJiritsuCheck();
      notifier.setJiritsuAnswer(JiritsuElement.clearOutcome, true);

      notifier.editStrategy();

      final state = readDeciding();
      expect(state.showingCheck, isFalse);
      expect(state.decidedStrategy, '決めた方策');
      expect(state.jiritsuCheck.clearOutcome, isTrue);
    });

    test(
      'confirm can be tapped even when the jiritsu check is incomplete — '
      'the checklist is a reflection aid, not an enforced gate',
      () {
        final notifier = container.read(strategyFlowProvider.notifier);
        notifier.setOwnStrategyText('  決めた方策  ');
        notifier.showJiritsuCheck();
        notifier.setJiritsuAnswer(JiritsuElement.selfDetermined, true);
        // clearOutcome / sharedGoal left unanswered.

        notifier.confirm();

        final confirmed =
            container.read(strategyFlowProvider) as StrategyFlowConfirmed;
        expect(confirmed.decidedStrategy, '決めた方策'); // trimmed
        expect(confirmed.jiritsuCheck.satisfiedCount, 1);
        expect(confirmed.suggestions, _suggestions);
      },
    );

    test('confirm no-ops while decidedStrategy is blank', () {
      container.read(strategyFlowProvider.notifier).confirm();
      expect(container.read(strategyFlowProvider), isA<StrategyFlowDeciding>());
    });
  });

  group('resumeFromCached', () {
    test(
      'restores 採用済 for suggestions whose text is still in decidedStrategy',
      () {
        // Use a fresh notifier (not the preloaded deciding override) so
        // resumeFromCached starts from StrategyFlowLaunching the way the
        // dashboard re-review path does.
        final fresh = ProviderContainer();
        addTearDown(fresh.dispose);
        fresh.listen(strategyFlowProvider, (_, _) {}, fireImmediately: true);

        fresh.read(strategyFlowProvider.notifier).resumeFromCached(
          suggestions: _suggestions,
          decidedStrategy: '方策A\n自分だけの追記',
          jiritsuCheck: const JiritsuCheck(selfDetermined: true),
        );

        final state = fresh.read(strategyFlowProvider) as StrategyFlowDeciding;
        expect(state.adoptedSuggestionIds, {_suggestions[0].id});
        expect(state.ownStrategyText, '自分だけの追記');
        expect(state.decidedStrategy, '方策A\n自分だけの追記');
        expect(state.jiritsuCheck.selfDetermined, isTrue);
      },
    );
  });
}
