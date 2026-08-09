import 'package:uuid/uuid.dart';

import '../../models/first_step_suggestion.dart';
import '../../models/jiritsu_check.dart';
import '../../models/project.dart';
import '../../models/project_status.dart';
import '../../models/situation_note.dart';
import '../../models/strategy_suggestion.dart';
import '../../models/swot_item.dart';
import '../../models/swot_matrix.dart';
import '../models/classification_axes.dart';
import '../models/wizard_idea.dart';

const _uuid = Uuid();

/// The four input steps hosted by the wizard's [PageView] (see
/// `WizardFlowScreen`). The matrix-preview screen that follows
/// classification is a separate pushed route, not a step of this enum.
///
/// `theme` and `goal` used to be one combined step — split per Step 0's
/// domain definition, since a single "goal" field collapses 在りたい姿 and
/// 在りたくない姿 into one wish instead of asking both directions.
enum WizardStep { theme, goal, ideaDump, classification }

/// Which of the two classification questions the current idea still needs
/// answered. The classification screen asks these one at a time — never
/// as a single combined 4-way SWOT choice — so users are never asked to
/// think in "strength/weakness/opportunity/threat" terms.
enum ClassificationQuestion { evaluation, locus }

/// Immutable snapshot of the input wizard's progress: the theme from step
/// 1, the two-sided goal from step 2, the raw brainstorm ("壁打ち") from
/// step 3, and each idea's classification from step 4.
class WizardState {
  /// Stable identity for whatever's persisted to history about this
  /// analysis (see [toProject]) — minted fresh each time a new wizard run
  /// starts (`WizardNotifier.build`/`reset`) so repeated saves during one
  /// run (matrix edits, a later action plan) update the same history
  /// record instead of creating duplicates.
  final String sessionId;
  final WizardStep step;
  final String theme;

  /// 在りたい姿 — the state that alone would count as success (充分条件).
  final String desiredGoal;

  /// 在りたくない姿 — the state that must be avoided regardless (必要条件).
  final String undesiredGoal;

  final List<WizardIdea> ideas;

  /// 方策 — Stage1 Step 6/8's decided wording. Stored here (not just kept
  /// transient inside the strategy screen's own flow notifier) so any
  /// later [toProject] save — even one triggered from a different screen,
  /// like a SWOT matrix edit — never clobbers it back to blank.
  final String decidedStrategy;

  /// AI提案方策一覧（参照用） — Stage1 Step 5's 5 Chrome-AI-Mode suggestions,
  /// kept alongside [decidedStrategy] for the same reason.
  final List<StrategySuggestion> aiStrategySuggestions;

  /// Stage1 Step 7's latest self-assessment of [decidedStrategy].
  final JiritsuCheck jiritsuCheck;

  /// 最初の一歩 — Stage1 Step 10's decided wording (adopted, edited, or
  /// written from scratch). Stored here for the same reason
  /// [decidedStrategy] is: a later save from any other screen must never
  /// clobber it back to blank.
  final String decidedFirstStep;

  /// AI提案の最初の一歩一覧（参照用） — Stage1 Step 9's suggestions, kept
  /// for dashboard re-review.
  final List<FirstStepSuggestion> aiFirstStepSuggestions;

  /// 宣言文 — Stage1 Step 10's declaration, seeded from
  /// `Project.suggestedDeclaration` but freely editable before being fixed.
  final String declaration;

  WizardState({
    String? sessionId,
    this.step = WizardStep.theme,
    this.theme = '',
    this.desiredGoal = '',
    this.undesiredGoal = '',
    this.ideas = const [],
    this.decidedStrategy = '',
    this.aiStrategySuggestions = const [],
    this.jiritsuCheck = JiritsuCheck.none,
    this.decidedFirstStep = '',
    this.aiFirstStepSuggestions = const [],
    this.declaration = '',
  }) : sessionId = sessionId ?? _uuid.v4();

  WizardState copyWith({
    WizardStep? step,
    String? theme,
    String? desiredGoal,
    String? undesiredGoal,
    List<WizardIdea>? ideas,
    String? decidedStrategy,
    List<StrategySuggestion>? aiStrategySuggestions,
    JiritsuCheck? jiritsuCheck,
    String? decidedFirstStep,
    List<FirstStepSuggestion>? aiFirstStepSuggestions,
    String? declaration,
  }) {
    return WizardState(
      sessionId: sessionId,
      step: step ?? this.step,
      theme: theme ?? this.theme,
      desiredGoal: desiredGoal ?? this.desiredGoal,
      undesiredGoal: undesiredGoal ?? this.undesiredGoal,
      ideas: ideas ?? this.ideas,
      decidedStrategy: decidedStrategy ?? this.decidedStrategy,
      aiStrategySuggestions:
          aiStrategySuggestions ?? this.aiStrategySuggestions,
      jiritsuCheck: jiritsuCheck ?? this.jiritsuCheck,
      decidedFirstStep: decidedFirstStep ?? this.decidedFirstStep,
      aiFirstStepSuggestions:
          aiFirstStepSuggestions ?? this.aiFirstStepSuggestions,
      declaration: declaration ?? this.declaration,
    );
  }

  bool get canProceedFromTheme => theme.trim().isNotEmpty;

  /// Only [desiredGoal] gates advancing — [undesiredGoal] enriches the
  /// necessary-condition side but isn't every user's starting point, and
  /// requiring two long-form answers back to back risks losing people who
  /// don't yet have a clear "what I want to avoid" picture.
  bool get canProceedFromGoal => desiredGoal.trim().isNotEmpty;

  bool get canProceedFromIdeaDump => ideas.isNotEmpty;

  List<WizardIdea> get unclassifiedIdeas =>
      ideas.where((idea) => !idea.isClassified).toList();

  int get classifiedCount => ideas.length - unclassifiedIdeas.length;

  bool get isClassificationComplete =>
      ideas.isNotEmpty && unclassifiedIdeas.isEmpty;

  /// The idea currently awaiting classification on the quick-classification
  /// screen (first not-yet-classified entry, in the order they were added).
  WizardIdea? get currentUnclassifiedIdea =>
      unclassifiedIdeas.isEmpty ? null : unclassifiedIdeas.first;

  /// Which single question should be shown right now for
  /// [currentUnclassifiedIdea] — `null` once classification is complete.
  ClassificationQuestion? get currentQuestion {
    final current = currentUnclassifiedIdea;
    if (current == null) return null;
    return current.evaluation == null
        ? ClassificationQuestion.evaluation
        : ClassificationQuestion.locus;
  }

  /// Whether the "戻す" affordance has anything to undo: either the
  /// in-progress idea's first answer, or a previously completed idea.
  bool get canGoBackInClassification =>
      currentUnclassifiedIdea?.evaluation != null || classifiedCount > 0;

  /// Builds Step 4's [SwotMatrix] domain model from every classified idea.
  /// Ideas left unclassified are excluded — callers should gate navigation
  /// on [isClassificationComplete] first.
  ///
  /// Preserves each [WizardIdea.id] as the resulting [SwotItem.id] (rather
  /// than letting [SwotItem] mint a new random one) so the matrix screen
  /// can drag a card and trace it back to the [WizardIdea] to update.
  SwotMatrix toSwotMatrix() {
    final items = ideas
        .where((idea) => idea.isClassified)
        .map(
          (idea) => SwotItem(
            id: idea.id,
            category: idea.category!,
            content: idea.text,
          ),
        )
        .toList();
    return SwotMatrix.fromItems(items);
  }

  /// Builds Step 3's "現状メモ（壁打ちテキスト群）" from every idea dumped so
  /// far, classified or not. There's no separate free-text capture step for
  /// this — the idea dump *is* the 壁打ち, just later organized into SWOT —
  /// so this simply re-views the same [ideas] list as [SituationNote]s,
  /// preserving each [WizardIdea.id] for a stable identity.
  ///
  /// [WizardIdea] doesn't track when an idea was added, so [createdAt] is
  /// stamped at conversion time rather than carried over — acceptable for
  /// now since ordering/history of these notes isn't surfaced anywhere yet.
  List<SituationNote> toSituationNotes() => ideas
      .map((idea) => SituationNote(id: idea.id, content: idea.text))
      .toList();

  /// Builds a history-record snapshot of this wizard run, keyed by
  /// [sessionId] so repeated calls across matrix edits / the strategy and
  /// first-step flows all update the same history record (see
  /// `AnalysisHistoryNotifier.saveOrUpdate`, which decides whether the
  /// `createdAt` stamped here is honored or an existing one is kept).
  ///
  /// [status] derives from [decidedFirstStep] rather than [decidedStrategy]
  /// alone: a decided 方策 with no concrete next action isn't yet something
  /// to call "実施中" (in progress) — that transition happens once Stage1
  /// Step 10's "Fix" gives the project an actual action to *do*, per
  /// Stage1's "Fix完了時に現況を「実施中」へ更新" requirement.
  Project toProject() {
    final now = DateTime.now();
    return Project(
      id: sessionId,
      theme: theme,
      desiredGoal: desiredGoal,
      undesiredGoal: undesiredGoal,
      situationNotes: toSituationNotes(),
      matrix: toSwotMatrix(),
      decidedStrategy: decidedStrategy,
      aiStrategySuggestions: aiStrategySuggestions,
      jiritsuCheck: jiritsuCheck,
      decidedFirstStep: decidedFirstStep,
      aiFirstStepSuggestions: aiFirstStepSuggestions,
      declaration: declaration,
      createdAt: now,
      updatedAt: now,
      status: decidedFirstStep.trim().isNotEmpty
          ? ProjectStatus.inProgress
          : ProjectStatus.preparing,
    );
  }

  /// Like [toProject], but keeps dashboard-only fields from [existing]
  /// (期限/備考/振り返り/現況, etc.) when updating a project the user
  /// reopened from the 案件ダッシュボード.
  ///
  /// 現況 is preserved only once the project has left 作成中 — otherwise
  /// [toProject]'s derivation wins, so confirming 最初の一歩 can still
  /// promote 作成中 → 実施中. Blindly keeping [Project.status] here used
  /// to leave drafts stuck in 作成中 after Fix完了, so ▶️ kept opening
  /// the SWOT matrix instead of the dashboard.
  ///
  /// Matrix / situation notes: if the wizard draft has none but [existing]
  /// still does, keep the stored ones — a theme-only `toProject()` must
  /// never wipe a finished SWOT when saving over the same id.
  Project toProjectPreserving(Project existing) {
    final draft = toProject();
    return draft.copyWith(
      createdAt: existing.createdAt,
      deadline: existing.deadline,
      note: existing.note,
      status: existing.status == ProjectStatus.preparing
          ? draft.status
          : existing.status,
      reflectionHistory: existing.reflectionHistory,
      matrix: draft.matrix.isEmpty && existing.matrix.isNotEmpty
          ? existing.matrix
          : draft.matrix,
      situationNotes:
          draft.situationNotes.isEmpty && existing.situationNotes.isNotEmpty
          ? existing.situationNotes
          : draft.situationNotes,
      isFavorite: existing.isFavorite,
    );
  }

  /// Rebuilds a resumable [WizardState] from a 作成中 (preparing) [Project]
  /// — the inverse of [toProject]/[toSwotMatrix]/[toSituationNotes], used
  /// when the user reopens a project that never reached 実施中 so they land
  /// back where they left off instead of starting over.
  ///
  /// [ideas] is reconstructed by walking [Project.situationNotes] (every
  /// idea ever dumped, classified or not, in original order) and looking
  /// each one up in [Project.matrix] by id: a match means it was already
  /// classified (its quadrant tells us the two axes via [axesForCategory]);
  /// no match means it's still awaiting classification. Any matrix item
  /// that isn't in [situationNotes] — only possible for a project migrated
  /// from the pre-Stage1 shape, whose matrix predates situation notes
  /// existing at all — is appended afterwards so that data isn't dropped.
  factory WizardState.fromProject(Project project) {
    final matrixById = {
      for (final item in project.matrix.allItems) item.id: item,
    };
    final seenIds = <String>{};
    final ideas = <WizardIdea>[];

    for (final note in project.situationNotes) {
      seenIds.add(note.id);
      final matrixItem = matrixById[note.id];
      if (matrixItem == null) {
        ideas.add(WizardIdea(id: note.id, text: note.content));
      } else {
        final axes = axesForCategory(matrixItem.category);
        ideas.add(
          WizardIdea(
            id: note.id,
            text: note.content,
            evaluation: axes.evaluation,
            locus: axes.locus,
          ),
        );
      }
    }
    for (final item in project.matrix.allItems) {
      if (seenIds.contains(item.id)) continue;
      final axes = axesForCategory(item.category);
      ideas.add(
        WizardIdea(
          id: item.id,
          text: item.content,
          evaluation: axes.evaluation,
          locus: axes.locus,
        ),
      );
    }

    return WizardState(
      sessionId: project.id,
      step: _resumeStepFor(
        theme: project.theme,
        desiredGoal: project.desiredGoal,
        ideas: ideas,
      ),
      theme: project.theme,
      desiredGoal: project.desiredGoal,
      undesiredGoal: project.undesiredGoal,
      ideas: ideas,
      decidedStrategy: project.decidedStrategy,
      aiStrategySuggestions: project.aiStrategySuggestions,
      jiritsuCheck: project.jiritsuCheck,
      decidedFirstStep: project.decidedFirstStep,
      aiFirstStepSuggestions: project.aiFirstStepSuggestions,
      declaration: project.declaration,
    );
  }

  static WizardStep _resumeStepFor({
    required String theme,
    required String desiredGoal,
    required List<WizardIdea> ideas,
  }) {
    if (theme.trim().isEmpty) return WizardStep.theme;
    if (desiredGoal.trim().isEmpty) return WizardStep.goal;
    if (ideas.isEmpty) return WizardStep.ideaDump;
    return WizardStep.classification;
  }
}
