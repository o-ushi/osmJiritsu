import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/wizard/models/classification_axes.dart';
import 'package:osm_jiritsu/wizard/state/wizard_notifier.dart';
import 'package:osm_jiritsu/wizard/state/wizard_state.dart';

void main() {
  group('WizardNotifier.handleSystemBack', () {
    late ProviderContainer container;
    late WizardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(wizardProvider.notifier);
    });

    test('from classification with answered questions goes to idea dump', () {
      notifier
        ..setTheme('theme')
        ..setDesiredGoal('goal')
        ..addIdea('idea')
        ..goToStep(WizardStep.classification)
        ..answerEvaluation(EvaluationAxis.positive);

      expect(
        container.read(wizardProvider).currentQuestion,
        ClassificationQuestion.locus,
      );

      notifier.handleSystemBack();

      expect(container.read(wizardProvider).step, WizardStep.ideaDump);
    });

    test('from idea dump goes to goal', () {
      notifier
        ..setTheme('theme')
        ..setDesiredGoal('goal')
        ..goToStep(WizardStep.ideaDump);

      notifier.handleSystemBack();

      expect(container.read(wizardProvider).step, WizardStep.goal);
    });

    test('from goal goes to theme', () {
      notifier
        ..setTheme('theme')
        ..setDesiredGoal('goal')
        ..goToStep(WizardStep.goal);

      notifier.handleSystemBack();

      expect(container.read(wizardProvider).step, WizardStep.theme);
    });

    test('from theme is a no-op', () {
      notifier.setTheme('theme');

      final popped = notifier.handleSystemBack();

      expect(popped, isFalse);
      expect(container.read(wizardProvider).step, WizardStep.theme);
    });
  });

  group('WizardNotifier.goBackOneQuestion', () {
    late ProviderContainer container;
    late WizardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(wizardProvider.notifier);
    });

    test('still undoes one classification answer via the 戻す affordance', () {
      notifier
        ..setTheme('theme')
        ..setDesiredGoal('goal')
        ..addIdea('idea')
        ..goToStep(WizardStep.classification)
        ..answerEvaluation(EvaluationAxis.positive);

      notifier.goBackOneQuestion();

      final state = container.read(wizardProvider);
      expect(state.step, WizardStep.classification);
      expect(state.currentQuestion, ClassificationQuestion.evaluation);
      expect(state.ideas.single.evaluation, isNull);
    });
  });

  group('WizardNotifier.updateIdeaText', () {
    late ProviderContainer container;
    late WizardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(wizardProvider.notifier);
    });

    test('changes the idea wording', () {
      notifier
        ..setTheme('theme')
        ..addIdea('before')
        ..answerEvaluation(EvaluationAxis.positive)
        ..answerLocus(LocusAxis.internal);

      notifier.updateIdeaText(
        container.read(wizardProvider).ideas.single.id,
        'after',
      );

      expect(container.read(wizardProvider).ideas.single.text, 'after');
    });

    test('ignores blank text', () {
      notifier
        ..setTheme('theme')
        ..addIdea('keep me');

      final id = container.read(wizardProvider).ideas.single.id;
      notifier.updateIdeaText(id, '   ');

      expect(container.read(wizardProvider).ideas.single.text, 'keep me');
    });
  });

  group('WizardNotifier.addClassifiedIdea', () {
    late ProviderContainer container;
    late WizardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(wizardProvider.notifier);
    });

    test('adds a classified idea to the chosen quadrant', () {
      notifier.addClassifiedIdea('new strength', SwotCategory.strength);

      final idea = container.read(wizardProvider).ideas.single;
      expect(idea.text, 'new strength');
      expect(idea.category, SwotCategory.strength);
    });
  });

  group('WizardNotifier.restoreIdeas', () {
    late ProviderContainer container;
    late WizardNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(wizardProvider.notifier);
    });

    test('replaces the ideas list wholesale', () {
      notifier
        ..addIdea('first')
        ..addIdea('second');

      final snapshot = container.read(wizardProvider).ideas;
      notifier.removeIdea(snapshot.last.id);
      notifier.restoreIdeas(snapshot);

      expect(container.read(wizardProvider).ideas, snapshot);
    });
  });
}
