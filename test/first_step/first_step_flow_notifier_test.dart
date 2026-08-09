// Unit tests for the Stage1 Steps 9-10 decide/declare flow —
// FirstStepFlowNotifier's pure state transitions, with no Chrome/clipboard
// involved (that round trip is covered by the widget test instead). A
// `build()` override seeds the notifier straight into
// `FirstStepFlowDeciding` so these tests don't need to go through Step 9's
// launch/paste first.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/first_step/state/first_step_flow_notifier.dart';
import 'package:osm_jiritsu/first_step/state/first_step_flow_state.dart';
import 'package:osm_jiritsu/models/first_step_suggestion.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';
import 'package:osm_jiritsu/wizard/state/wizard_state.dart';

final _suggestions = [
  FirstStepSuggestion(text: '行動A'),
  FirstStepSuggestion(text: '行動B'),
];

class _PreloadedFirstStepFlowNotifier extends FirstStepFlowNotifier {
  @override
  FirstStepFlowState build() =>
      FirstStepFlowDeciding(suggestions: _suggestions);
}

/// Preloads the wizard with a 在りたい姿, so `showDeclaration`'s
/// `Project.suggestedDeclaration` seed has something to work with.
class _PreloadedWizardNotifier extends WizardNotifier {
  @override
  WizardState build() =>
      WizardState(theme: 'テーマ', desiredGoal: '納得感のある転職をしている');
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        firstStepFlowProvider.overrideWith(
          _PreloadedFirstStepFlowNotifier.new,
        ),
        wizardProvider.overrideWith(_PreloadedWizardNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    // firstStepFlowProvider is `.autoDispose`; keep it alive for the whole
    // test via a standing listener, same as a watching widget would.
    container.listen(firstStepFlowProvider, (_, _) {}, fireImmediately: true);
  });

  FirstStepFlowDeciding readDeciding() =>
      container.read(firstStepFlowProvider) as FirstStepFlowDeciding;

  group('Step 10: composing 最初の一歩', () {
    test('setOwnFirstStepText overwrites the free-text field', () {
      container
          .read(firstStepFlowProvider.notifier)
          .setOwnFirstStepText('自分で書いた一歩');
      expect(readDeciding().decidedFirstStep, '自分で書いた一歩');
    });

    test('toggleSuggestion combines several toggled-on suggestions', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.toggleSuggestion(_suggestions[0]);
      notifier.toggleSuggestion(_suggestions[1]);
      expect(readDeciding().decidedFirstStep, '行動A\n行動B');
    });

    test('toggleSuggestion records the suggestion as adopted', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.toggleSuggestion(_suggestions[0]);
      expect(readDeciding().adoptedSuggestionIds, {_suggestions[0].id});
    });

    test(
      'toggleSuggestion is a real toggle: tapping the same suggestion twice '
      '"選んでみたもののやっぱりやめた" turns it back off',
      () {
        final notifier = container.read(firstStepFlowProvider.notifier);
        notifier.toggleSuggestion(_suggestions[0]);
        notifier.toggleSuggestion(_suggestions[0]);
        expect(readDeciding().decidedFirstStep, isEmpty);
        expect(readDeciding().adoptedSuggestionIds, isEmpty);
      },
    );

    test(
      'the decided first step combines toggled-on suggestions with ownFirstStepText',
      () {
        final notifier = container.read(firstStepFlowProvider.notifier);
        notifier.toggleSuggestion(_suggestions[0]);
        notifier.setOwnFirstStepText('自分だけの一歩');
        expect(readDeciding().decidedFirstStep, '行動A\n自分だけの一歩');
      },
    );

    test('editSuggestionText rewords a suggestion in place, keeping its id', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.editSuggestionText(_suggestions[0], '行動Aの修正版');
      final edited = readDeciding().suggestions[0];
      expect(edited.id, _suggestions[0].id);
      expect(edited.text, '行動Aの修正版');
    });

    test('editSuggestionText no-ops on blank text', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.editSuggestionText(_suggestions[0], '   ');
      expect(readDeciding().suggestions[0].text, '行動A');
    });

    test(
      'canProceedToDeclaration/canConfirm are false until something is decided',
      () {
        final state = readDeciding();
        expect(state.canProceedToDeclaration, isFalse);
        expect(state.canConfirm, isFalse);
      },
    );
  });

  group('Step 10: 宣言文', () {
    test('showDeclaration no-ops while decidedFirstStep is blank', () {
      container.read(firstStepFlowProvider.notifier).showDeclaration();
      expect(readDeciding().showingDeclaration, isFalse);
    });

    test(
      'showDeclaration seeds the declaration from Project.suggestedDeclaration',
      () {
        final notifier = container.read(firstStepFlowProvider.notifier);
        notifier.setOwnFirstStepText('転職エージェントに登録する');
        notifier.showDeclaration();

        final state = readDeciding();
        expect(state.showingDeclaration, isTrue);
        expect(
          state.declaration,
          '私は納得感のある転職をしているを目指しています。まずは転職エージェントに登録するを実践します。',
        );
      },
    );

    test('showDeclaration never overwrites an already-typed declaration', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.setOwnFirstStepText('転職エージェントに登録する');
      notifier.showDeclaration();
      notifier.setDeclaration('自分で書き換えた宣言文');

      notifier.editFirstStep();
      notifier.showDeclaration();

      expect(readDeciding().declaration, '自分で書き換えた宣言文');
    });

    test('editFirstStep loops back without losing the declaration', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.setOwnFirstStepText('転職エージェントに登録する');
      notifier.showDeclaration();
      notifier.setDeclaration('私の宣言文');

      notifier.editFirstStep();

      final state = readDeciding();
      expect(state.showingDeclaration, isFalse);
      expect(state.decidedFirstStep, '転職エージェントに登録する');
      expect(state.declaration, '私の宣言文');
    });
  });

  group('Fix (決定)', () {
    test('confirm requires both decidedFirstStep and declaration', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.setOwnFirstStepText('転職エージェントに登録する');
      notifier.confirm(); // declaration still blank
      expect(container.read(firstStepFlowProvider), isA<FirstStepFlowDeciding>());
    });

    test('confirm trims and transitions to FirstStepFlowConfirmed', () {
      final notifier = container.read(firstStepFlowProvider.notifier);
      notifier.setOwnFirstStepText('  転職エージェントに登録する  ');
      notifier.showDeclaration();
      notifier.setDeclaration('  私の宣言文  ');

      notifier.confirm();

      final confirmed =
          container.read(firstStepFlowProvider) as FirstStepFlowConfirmed;
      expect(confirmed.decidedFirstStep, '転職エージェントに登録する');
      expect(confirmed.declaration, '私の宣言文');
    });
  });

  group('resumeFromCached', () {
    test(
      'restores 採用済 for suggestions whose text is still in decidedFirstStep',
      () {
        final fresh = ProviderContainer(
          overrides: [
            wizardProvider.overrideWith(_PreloadedWizardNotifier.new),
          ],
        );
        addTearDown(fresh.dispose);
        fresh.listen(firstStepFlowProvider, (_, _) {}, fireImmediately: true);

        fresh.read(firstStepFlowProvider.notifier).resumeFromCached(
          suggestions: _suggestions,
          decidedFirstStep: '行動A\n自分だけの一歩',
          declaration: '既存の宣言文',
        );

        final state =
            fresh.read(firstStepFlowProvider) as FirstStepFlowDeciding;
        expect(state.adoptedSuggestionIds, {_suggestions[0].id});
        expect(state.ownFirstStepText, '自分だけの一歩');
        expect(state.decidedFirstStep, '行動A\n自分だけの一歩');
        expect(state.declaration, '既存の宣言文');
      },
    );
  });
}
