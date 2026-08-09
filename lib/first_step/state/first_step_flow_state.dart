import '../../models/first_step_suggestion.dart';

/// Stage1 Steps 9-10's round trip: open Chrome AI Mode with the
/// first-step-divergence prompt, parse whatever the user pastes back into
/// 10 [FirstStepSuggestion]s, then let the user decide 最初の一歩 (adopt/
/// edit/write their own) and fix its 宣言文 before confirming.
sealed class FirstStepFlowState {
  const FirstStepFlowState();
}

/// Momentary state before Chrome AI Mode has finished launching.
/// `FirstStepFlowScreen` triggers the launch itself as soon as it mounts.
class FirstStepFlowLaunching extends FirstStepFlowState {
  const FirstStepFlowLaunching();
}

/// Chrome AI Mode has been opened (and the prompt copied to the
/// clipboard); waiting for the user to copy the answer and tap "paste".
class FirstStepFlowAwaitingPaste extends FirstStepFlowState {
  const FirstStepFlowAwaitingPaste();
}

/// Opening Chrome AI Mode itself failed (e.g. no browser available).
class FirstStepFlowLaunchFailed extends FirstStepFlowState {
  final String message;
  const FirstStepFlowLaunchFailed(this.message);
}

/// The clipboard was empty, or its contents didn't parse into any first
/// steps — asks the user to copy the answer again.
class FirstStepFlowPasteFailed extends FirstStepFlowState {
  final String message;
  const FirstStepFlowPasteFailed(this.message);
}

/// Stage1 Steps 10: deciding 最初の一歩, then fixing its 宣言文.
/// [showingDeclaration] toggles which of the two screens is shown;
/// [decidedFirstStep]/[declaration] persist across that toggle.
class FirstStepFlowDeciding extends FirstStepFlowState {
  /// Step 9's 10 AI suggestions — reference material for the editor. Each
  /// one's own `text` can be reworded in place (長押しで編集) via
  /// `FirstStepFlowNotifier.editSuggestionText`.
  final List<FirstStepSuggestion> suggestions;

  /// The free-text field: wording that's entirely the user's own,
  /// independent of anything toggled on from [suggestions] — see
  /// [decidedFirstStep] for how the two combine.
  final String ownFirstStepText;

  /// The 宣言文 — blank until [showingDeclaration] is first entered (see
  /// `FirstStepFlowNotifier.showDeclaration`, which seeds it from
  /// `Project.suggestedDeclaration`), then freely editable.
  final String declaration;

  /// false: showing the 最初の一歩 editor. true: showing the 宣言文 editor.
  final bool showingDeclaration;

  /// [FirstStepSuggestion.id]s currently toggled on via "採用する" — a
  /// toggle, not a one-way adoption, so "選んでみたもののやっぱりやめた"
  /// is just tapping it again. See
  /// `FirstStepFlowNotifier.toggleSuggestion`.
  final Set<String> adoptedSuggestionIds;

  const FirstStepFlowDeciding({
    required this.suggestions,
    this.ownFirstStepText = '',
    this.declaration = '',
    this.showingDeclaration = false,
    this.adoptedSuggestionIds = const {},
  });

  /// The actual decided 最初の一歩: every currently-toggled-on suggestion
  /// (in their original order, using each one's latest edited wording),
  /// followed by [ownFirstStepText] — recomputed live, so toggling a
  /// suggestion on/off or editing its text is reflected immediately.
  String get decidedFirstStep => [
    for (final suggestion in suggestions)
      if (adoptedSuggestionIds.contains(suggestion.id)) suggestion.text,
    if (ownFirstStepText.trim().isNotEmpty) ownFirstStepText.trim(),
  ].join('\n');

  /// Whether the editor→宣言文 CTA can be tapped.
  bool get canProceedToDeclaration => decidedFirstStep.trim().isNotEmpty;

  /// Whether the final "決定" (fix) CTA can be tapped.
  bool get canConfirm =>
      decidedFirstStep.trim().isNotEmpty && declaration.trim().isNotEmpty;

  FirstStepFlowDeciding copyWith({
    List<FirstStepSuggestion>? suggestions,
    String? ownFirstStepText,
    String? declaration,
    bool? showingDeclaration,
    Set<String>? adoptedSuggestionIds,
  }) {
    return FirstStepFlowDeciding(
      suggestions: suggestions ?? this.suggestions,
      ownFirstStepText: ownFirstStepText ?? this.ownFirstStepText,
      declaration: declaration ?? this.declaration,
      showingDeclaration: showingDeclaration ?? this.showingDeclaration,
      adoptedSuggestionIds: adoptedSuggestionIds ?? this.adoptedSuggestionIds,
    );
  }
}

/// Stage1's "Fix完了": both 最初の一歩 and 宣言文 are decided.
/// `FirstStepFlowScreen` persists this into `WizardState`/history (see its
/// `ref.listen`) and flips `Project.status` to 実施中 as a side effect of
/// reaching this state, not this notifier itself.
class FirstStepFlowConfirmed extends FirstStepFlowState {
  final String decidedFirstStep;
  final String declaration;
  final List<FirstStepSuggestion> suggestions;

  const FirstStepFlowConfirmed({
    required this.decidedFirstStep,
    required this.declaration,
    this.suggestions = const [],
  });
}
