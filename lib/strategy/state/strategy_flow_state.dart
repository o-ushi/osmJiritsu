import '../../models/jiritsu_check.dart';
import '../../models/strategy_suggestion.dart';

/// Stage1 Steps 5-8's round trip: open Chrome AI Mode with the
/// strategy-divergence prompt, parse whatever the user pastes back into 5
/// [StrategySuggestion]s, then loop the user through deciding a 方策
/// (Step 6), checking it against 自律の3要素 (Step 7), and redefining it
/// (Step 8) — as many times as they like — until they explicitly confirm.
sealed class StrategyFlowState {
  const StrategyFlowState();
}

/// Momentary state before Chrome AI Mode has finished launching.
/// `StrategyFlowScreen` triggers the launch itself as soon as it mounts, so
/// this is only ever visible for the instant the clipboard copy +
/// `launchUrl` call take to resolve.
class StrategyFlowLaunching extends StrategyFlowState {
  const StrategyFlowLaunching();
}

/// Chrome AI Mode has been opened (and the prompt copied to the
/// clipboard); waiting for the user to copy the answer and tap "paste".
class StrategyFlowAwaitingPaste extends StrategyFlowState {
  const StrategyFlowAwaitingPaste();
}

/// Opening Chrome AI Mode itself failed (e.g. no browser available to
/// handle the URL).
class StrategyFlowLaunchFailed extends StrategyFlowState {
  final String message;
  const StrategyFlowLaunchFailed(this.message);
}

/// The clipboard was empty, or its contents didn't parse into any
/// strategies — asks the user to copy the answer again.
class StrategyFlowPasteFailed extends StrategyFlowState {
  final String message;
  const StrategyFlowPasteFailed(this.message);
}

/// Stage1 Steps 6-8: the user is composing/checking/redefining their
/// decided 方策 in a loop. [showingCheck] toggles which of the two screens
/// (方策を決める／内発度チェック) is currently shown; everything else
/// (`decidedStrategy`, `jiritsuCheck`) persists across that toggle so
/// looping back and forth never loses anything already entered.
class StrategyFlowDeciding extends StrategyFlowState {
  /// Step 5's 5 AI suggestions — reference material throughout the loop.
  /// Each one's own `text` can be reworded in place (Step 6's 長押しで編集,
  /// e.g. "週1"→"週2") via `StrategyFlowNotifier.editSuggestionText`.
  final List<StrategySuggestion> suggestions;

  /// Step 6/8's free-text field: wording that's entirely the user's own,
  /// independent of anything toggled on from [suggestions] — see
  /// [decidedStrategy] for how the two combine.
  final String ownStrategyText;

  /// Step 7's latest self-assessment of [decidedStrategy].
  final JiritsuCheck jiritsuCheck;

  /// false: showing the Step 6/8 strategy editor. true: showing the Step 7
  /// jiritsu-check screen.
  final bool showingCheck;

  /// [StrategySuggestion.id]s currently toggled on via "採用する" — a
  /// toggle, not a one-way adoption, so "選んでみたもののやっぱりやめた"
  /// (picked it, then changed my mind) is just tapping it again. See
  /// `StrategyFlowNotifier.toggleSuggestion`.
  final Set<String> adoptedSuggestionIds;

  const StrategyFlowDeciding({
    required this.suggestions,
    this.ownStrategyText = '',
    this.jiritsuCheck = JiritsuCheck.none,
    this.showingCheck = false,
    this.adoptedSuggestionIds = const {},
  });

  /// The actual decided 方策: every currently-toggled-on suggestion (in
  /// their original order, using each one's latest edited wording),
  /// followed by [ownStrategyText] — recomputed live, so toggling a
  /// suggestion on/off or editing its text is reflected immediately with
  /// no separate "sync" step.
  String get decidedStrategy => [
    for (final suggestion in suggestions)
      if (adoptedSuggestionIds.contains(suggestion.id)) suggestion.text,
    if (ownStrategyText.trim().isNotEmpty) ownStrategyText.trim(),
  ].join('\n');

  /// Whether the Step 6→7 "内発度をチェックする" CTA can be tapped.
  bool get canProceedToCheck => decidedStrategy.trim().isNotEmpty;

  /// Whether "納得した" (Step 8's explicit confirm) can be tapped —
  /// requires *some* decided wording, but deliberately does not require
  /// [jiritsuCheck] to be fully satisfied: the checklist is a reflection
  /// aid, not a gate the app enforces over the user's own judgment call.
  bool get canConfirm => decidedStrategy.trim().isNotEmpty;

  StrategyFlowDeciding copyWith({
    List<StrategySuggestion>? suggestions,
    String? ownStrategyText,
    JiritsuCheck? jiritsuCheck,
    bool? showingCheck,
    Set<String>? adoptedSuggestionIds,
  }) {
    return StrategyFlowDeciding(
      suggestions: suggestions ?? this.suggestions,
      ownStrategyText: ownStrategyText ?? this.ownStrategyText,
      jiritsuCheck: jiritsuCheck ?? this.jiritsuCheck,
      showingCheck: showingCheck ?? this.showingCheck,
      adoptedSuggestionIds: adoptedSuggestionIds ?? this.adoptedSuggestionIds,
    );
  }
}

/// Step 8's "納得した": the loop is done. `StrategyFlowScreen` persists
/// this into `WizardState`/history as a side effect of reaching this state
/// (see its `ref.listen`), not this notifier itself.
class StrategyFlowConfirmed extends StrategyFlowState {
  final List<StrategySuggestion> suggestions;
  final String decidedStrategy;
  final JiritsuCheck jiritsuCheck;

  const StrategyFlowConfirmed({
    required this.suggestions,
    required this.decidedStrategy,
    required this.jiritsuCheck,
  });
}
