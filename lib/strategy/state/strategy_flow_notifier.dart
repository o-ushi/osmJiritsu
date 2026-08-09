import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/analysis_engine.dart';
import '../../engine/chrome_ai_link.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/jiritsu.dart';
import '../../models/jiritsu_check.dart';
import '../../models/strategy_suggestion.dart';
import '../../models/suggestion_adoption.dart';
import '../../wizard/state/wizard_notifier.dart';
import 'strategy_flow_state.dart';

final strategyFlowProvider =
    NotifierProvider.autoDispose<StrategyFlowNotifier, StrategyFlowState>(
      StrategyFlowNotifier.new,
    );

/// Drives Stage1 Steps 5-8: the Chrome-AI-Mode round trip for 方策
/// divergence, then the decide/check/redefine loop (see
/// [StrategyFlowDeciding]).
///
/// Deliberately doesn't write into `WizardState` or history itself —
/// `StrategyFlowScreen` does that (via `ref.listen`) once
/// [StrategyFlowConfirmed] is reached, keeping this notifier's own
/// responsibility limited to the flow/loop itself.
class StrategyFlowNotifier extends Notifier<StrategyFlowState> {
  static const _engine = AnalysisEngine();

  @override
  StrategyFlowState build() => const StrategyFlowLaunching();

  // ── Step 5: Chrome AI Mode round trip ─────────────────────────────────

  /// Copies [prompt] to the clipboard (manual-paste fallback) and opens it
  /// in Chrome AI Mode. Called as soon as `StrategyFlowScreen` mounts.
  Future<void> openInChromeAiMode(String prompt) async {
    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      await ref.read(chromeAiLauncherProvider).openWithPrompt(prompt);
      state = const StrategyFlowAwaitingPaste();
    } catch (error) {
      final lang = ref.read(appLanguageProvider);
      state = StrategyFlowLaunchFailed(
        'Chromeを開けませんでした: %@'.trFmt(lang, ['$error']),
      );
    }
  }

  /// Reads the clipboard (where the user should have just copied Chrome's
  /// answer) and parses it into 5 [StrategySuggestion]s.
  Future<void> pasteAndParse() async {
    final lang = ref.read(appLanguageProvider);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text?.trim() ?? '';
    if (text.isEmpty) {
      state = StrategyFlowPasteFailed(
        'クリップボードが空でした。Chromeで回答をコピーしてから、もう一度貼り付けてみてください。'.tr(lang),
      );
      return;
    }

    try {
      final suggestions = _engine.parseStrategyResponse(text);
      if (suggestions.isEmpty) {
        state = StrategyFlowPasteFailed(
          '方策を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。'.tr(lang),
        );
        return;
      }
      // Seed the editor with whatever was already decided in an earlier
      // pass at this project, so re-diverging (re-running Step 5) never
      // throws away previous work — see `WizardState.decidedStrategy`. It
      // was saved as one already-combined string, so there's no way to
      // know which parts (if any) came from these newly-parsed suggestions
      // — it all starts as `ownStrategyText`, with nothing toggled on.
      final wizard = ref.read(wizardProvider);
      state = StrategyFlowDeciding(
        suggestions: suggestions,
        ownStrategyText: wizard.decidedStrategy,
        jiritsuCheck: wizard.jiritsuCheck,
      );
    } on FormatException {
      state = StrategyFlowPasteFailed(
        '方策を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。'.tr(lang),
      );
    }
  }

  // ── Step 6/8: deciding / redefining the strategy ──────────────────────

  /// "あなたの方策"'s free-text field — wording that's entirely the
  /// user's own, kept separate from whatever's toggled on from
  /// [StrategyFlowDeciding.suggestions] (see `decidedStrategy`).
  void setOwnStrategyText(String value) {
    final current = state;
    if (current is! StrategyFlowDeciding) return;
    state = current.copyWith(ownStrategyText: value);
  }

  /// "採用済／未採用": toggles [suggestion] in/out of
  /// [StrategyFlowDeciding.adoptedSuggestionIds]. A toggle rather than a
  /// one-way adoption, so picking a suggestion and then changing your mind
  /// ("選んでみたもののやっぱりやめた") is just tapping it again.
  void toggleSuggestion(StrategySuggestion suggestion) {
    final current = state;
    if (current is! StrategyFlowDeciding) return;
    final ids = {...current.adoptedSuggestionIds};
    if (!ids.remove(suggestion.id)) {
      ids.add(suggestion.id);
    }
    state = current.copyWith(adoptedSuggestionIds: ids);
  }

  /// Step 6's 長押しで編集: rewords [suggestion] in place (e.g. "週1"→
  /// "週2") rather than requiring the user to abandon the AI's structure
  /// and retype it from scratch in "あなたの方策". No-ops on blank text —
  /// use [toggleSuggestion] to remove a suggestion from the decision
  /// instead of blanking it out.
  void editSuggestionText(StrategySuggestion suggestion, String newText) {
    final current = state;
    if (current is! StrategyFlowDeciding) return;
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    state = current.copyWith(
      suggestions: [
        for (final s in current.suggestions)
          if (s.id == suggestion.id) s.copyWith(text: trimmed) else s,
      ],
    );
  }

  // ── Step 7: jiritsu check ──────────────────────────────────────────────

  void showJiritsuCheck() {
    final current = state;
    if (current is! StrategyFlowDeciding) return;
    if (!current.canProceedToCheck) return;
    state = current.copyWith(showingCheck: true);
  }

  /// Step 8's "方策を編集する": back to the editor without losing the
  /// check answers already given.
  void editStrategy() {
    final current = state;
    if (current is! StrategyFlowDeciding) return;
    state = current.copyWith(showingCheck: false);
  }

  void setJiritsuAnswer(JiritsuElement element, bool value) {
    final current = state;
    if (current is! StrategyFlowDeciding) return;
    final check = switch (element) {
      JiritsuElement.selfDetermined => current.jiritsuCheck.copyWith(
        selfDetermined: value,
      ),
      JiritsuElement.clearOutcome => current.jiritsuCheck.copyWith(
        clearOutcome: value,
      ),
      JiritsuElement.sharedGoal => current.jiritsuCheck.copyWith(
        sharedGoal: value,
      ),
    };
    state = current.copyWith(jiritsuCheck: check);
  }

  // ── Step 8: confirm ────────────────────────────────────────────────────

  /// "納得した" — ends the Step 6-8 loop.
  void confirm() {
    final current = state;
    if (current is! StrategyFlowDeciding || !current.canConfirm) return;
    state = StrategyFlowConfirmed(
      suggestions: current.suggestions,
      decidedStrategy: current.decidedStrategy.trim(),
      jiritsuCheck: current.jiritsuCheck,
    );
  }

  void reset() => state = const StrategyFlowLaunching();

  /// Opens the decide/check loop with suggestions already saved on the
  /// project — used when re-reviewing 方策 from the dashboard. Suggestions
  /// whose text still appears in [decidedStrategy] are restored as
  /// 採用済; any leftover wording stays in `ownStrategyText`.
  void resumeFromCached({
    required List<StrategySuggestion> suggestions,
    required String decidedStrategy,
    required JiritsuCheck jiritsuCheck,
  }) {
    final split = splitDecidedIntoAdoptions(
      suggestions: [
        for (final s in suggestions) (id: s.id, text: s.text),
      ],
      decidedText: decidedStrategy,
    );
    state = StrategyFlowDeciding(
      suggestions: suggestions,
      ownStrategyText: split.ownText,
      adoptedSuggestionIds: split.adoptedIds,
      jiritsuCheck: jiritsuCheck,
    );
  }
}
