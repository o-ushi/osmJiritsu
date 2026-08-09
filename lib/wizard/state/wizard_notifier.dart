import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/first_step_suggestion.dart';
import '../../models/jiritsu_check.dart';
import '../../models/project.dart';
import '../../models/strategy_suggestion.dart';
import '../../models/swot_category.dart';
import '../models/classification_axes.dart';
import '../models/wizard_idea.dart';
import 'wizard_state.dart';

final wizardProvider = NotifierProvider<WizardNotifier, WizardState>(
  WizardNotifier.new,
);

/// Owns the input wizard's state end to end: theme capture, the two-sided
/// goal (在りたい姿/在りたくない姿), the idea-dump list, per-idea
/// classification, and (Stage1 Steps 6-8) the decided 方策 and its jiritsu
/// check. UI screens only dispatch intents (`setTheme`, `addIdea`,
/// `answerEvaluation`, `confirmStrategy`, ...) — all validation/derivation
/// lives on [WizardState].
class WizardNotifier extends Notifier<WizardState> {
  @override
  WizardState build() => WizardState();

  // ── Step 1: theme ────────────────────────────────────────────────────

  void setTheme(String value) => state = state.copyWith(theme: value);

  // ── Step 2: goal (在りたい姿 / 在りたくない姿) ──────────────────────────

  void setDesiredGoal(String value) =>
      state = state.copyWith(desiredGoal: value);

  void setUndesiredGoal(String value) =>
      state = state.copyWith(undesiredGoal: value);

  // ── Step navigation ────────────────────────────────────────────────────

  void goToStep(WizardStep step) => state = state.copyWith(step: step);

  void advanceFromTheme() {
    if (!state.canProceedFromTheme) return;
    goToStep(WizardStep.goal);
  }

  void advanceFromGoal() {
    if (!state.canProceedFromGoal) return;
    goToStep(WizardStep.ideaDump);
  }

  void advanceFromIdeaDump() {
    if (!state.canProceedFromIdeaDump) return;
    goToStep(WizardStep.classification);
  }

  void goBackToTheme() => goToStep(WizardStep.theme);

  void goBackToGoal() => goToStep(WizardStep.goal);

  void goBackToIdeaDump() => goToStep(WizardStep.ideaDump);

  /// Goes back one wizard *screen* (theme ← goal ← idea dump ← classification).
  /// Classification undo within the same screen uses [goBackOneQuestion] via
  /// the "戻す" button instead.
  void goBackOneScreen() {
    switch (state.step) {
      case WizardStep.theme:
        return;
      case WizardStep.goal:
        goBackToTheme();
      case WizardStep.ideaDump:
        goBackToGoal();
      case WizardStep.classification:
        goBackToIdeaDump();
    }
  }

  /// Handles the system back gesture / back button while inside the wizard.
  /// Returns `true` when the route itself should pop; always `false` today
  /// because each step maps to a previous wizard screen instead of exiting.
  bool handleSystemBack() {
    if (state.step == WizardStep.theme) return false;
    goBackOneScreen();
    return false;
  }

  // ── Step 3: idea dump ("壁打ち") ─────────────────────────────────────

  /// Adds a new idea if [text] is non-blank; no-ops otherwise so the chat
  /// input can call this unconditionally on submit.
  void addIdea(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      ideas: [
        ...state.ideas,
        WizardIdea(text: trimmed),
      ],
    );
  }

  void removeIdea(String id) {
    state = state.copyWith(
      ideas: state.ideas.where((idea) => idea.id != id).toList(),
    );
  }

  void updateIdeaText(String id, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      ideas: [
        for (final idea in state.ideas)
          if (idea.id == id)
            WizardIdea(
              id: idea.id,
              text: trimmed,
              evaluation: idea.evaluation,
              locus: idea.locus,
            )
          else
            idea,
      ],
    );
  }

  /// Adds a new idea already placed in [category] — used from the matrix
  /// screen's "+" affordance so the user can extend 今の状況 without
  /// re-entering the classification wizard.
  void addClassifiedIdea(String text, SwotCategory category) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final axes = axesForCategory(category);
    state = state.copyWith(
      ideas: [
        ...state.ideas,
        WizardIdea(
          text: trimmed,
          evaluation: axes.evaluation,
          locus: axes.locus,
        ),
      ],
    );
  }

  void restoreIdeas(List<WizardIdea> ideas) => state = state.copyWith(ideas: ideas);

  // ── Step 4: quick classification ────────────────────────────────────────
  //
  // Classification is asked as two small, sequential yes/no questions per
  // idea — never as one combined 4-way SWOT choice — so the flow never
  // requires the user to think in "strength/weakness/opportunity/threat"
  // terms. The SWOT category only falls out of the two answers afterwards
  // (see `WizardIdea.category`).

  /// Answers question 1 ("good vs. concerning") for
  /// [WizardState.currentUnclassifiedIdea].
  void answerEvaluation(EvaluationAxis evaluation) {
    final current = state.currentUnclassifiedIdea;
    if (current == null) return;
    state = state.copyWith(
      ideas: [
        for (final idea in state.ideas)
          if (idea.id == current.id) idea.withEvaluation(evaluation) else idea,
      ],
    );
  }

  /// Answers question 2 ("within my control vs. environment") for
  /// [WizardState.currentUnclassifiedIdea]. Answering this completes the
  /// idea's classification.
  void answerLocus(LocusAxis locus) {
    final current = state.currentUnclassifiedIdea;
    if (current == null) return;
    state = state.copyWith(
      ideas: [
        for (final idea in state.ideas)
          if (idea.id == current.id) idea.withLocus(locus) else idea,
      ],
    );
  }

  /// Lightweight "戻す": if the current idea already answered question 1,
  /// undoes just that answer (back to question 1 for the same idea);
  /// otherwise reverts the most recently *completed* idea so the user can
  /// revisit it. Never shows a confirmation dialog.
  void goBackOneQuestion() {
    final current = state.currentUnclassifiedIdea;
    if (current != null && current.evaluation != null) {
      state = state.copyWith(
        ideas: [
          for (final idea in state.ideas)
            if (idea.id == current.id) idea.withEvaluation(null) else idea,
        ],
      );
      return;
    }

    final classified = state.ideas.where((idea) => idea.isClassified).toList();
    if (classified.isEmpty) return;
    final last = classified.last;
    state = state.copyWith(
      ideas: [
        for (final idea in state.ideas)
          if (idea.id == last.id) idea.unclassified() else idea,
      ],
    );
  }

  // ── Step 4: SWOT matrix drag & drop ─────────────────────────────────────

  /// Moves an already-classified idea to a different quadrant, as invoked
  /// by dropping its card on another quadrant in the matrix screen.
  ///
  /// There is no separate "category" field to overwrite — a
  /// [WizardIdea]'s quadrant is always derived from its two answered axes
  /// (see `categoryFor`), so moving it means rewriting those axes to
  /// whichever pair produces [category] (see `axesForCategory`). No-ops if
  /// [ideaId] doesn't exist.
  void moveIdeaToCategory(String ideaId, SwotCategory category) {
    final axes = axesForCategory(category);
    state = state.copyWith(
      ideas: [
        for (final idea in state.ideas)
          if (idea.id == ideaId)
            idea.withEvaluation(axes.evaluation).withLocus(axes.locus)
          else
            idea,
      ],
    );
  }

  // ── Stage1 Steps 6-8: strategy decision + jiritsu check ─────────────────

  /// Records the outcome of `StrategyFlowNotifier`'s decide/check/redefine
  /// loop once the user taps "納得した". Kept centrally here (rather than
  /// solely inside that `autoDispose` flow notifier's own transient state)
  /// so a later save triggered from any other screen — e.g. a SWOT matrix
  /// edit — never clobbers it back to blank; see `WizardState.toProject`.
  void confirmStrategy({
    required String decidedStrategy,
    required List<StrategySuggestion> aiStrategySuggestions,
    required JiritsuCheck jiritsuCheck,
  }) {
    state = state.copyWith(
      decidedStrategy: decidedStrategy,
      aiStrategySuggestions: aiStrategySuggestions,
      jiritsuCheck: jiritsuCheck,
    );
  }

  // ── Stage1 Steps 9-10: first step + declaration ─────────────────────────

  /// Records the outcome of `FirstStepFlowNotifier`'s decide/declare loop
  /// once the user fixes both the 最初の一歩 and its 宣言文 — same
  /// centralize-it-here rationale as [confirmStrategy]. This is also what
  /// flips `WizardState.toProject().status` to 実施中 (see its own doc
  /// comment), since a concrete first action is what actually starts the
  /// project moving.
  void confirmFirstStep({
    required String decidedFirstStep,
    required String declaration,
    List<FirstStepSuggestion> aiFirstStepSuggestions = const [],
  }) {
    state = state.copyWith(
      decidedFirstStep: decidedFirstStep,
      declaration: declaration,
      aiFirstStepSuggestions: aiFirstStepSuggestions,
    );
  }

  void reset() => state = WizardState();

  /// Reloads a 作成中 (preparing) [project] back into wizard state so
  /// re-opening it from 登録案件リスト continues the wizard rather than
  /// restarting it — see [WizardState.fromProject] for how each field
  /// (including [WizardState.ideas]' classification) is rebuilt.
  void resumeFrom(Project project) {
    state = WizardState.fromProject(project);
  }
}
