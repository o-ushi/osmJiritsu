import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/analysis_engine.dart';
import '../../engine/chrome_ai_link.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/first_step_suggestion.dart';
import '../../models/project.dart';
import '../../models/suggestion_adoption.dart';
import '../../wizard/state/wizard_notifier.dart';
import 'first_step_flow_state.dart';

final firstStepFlowProvider =
    NotifierProvider.autoDispose<FirstStepFlowNotifier, FirstStepFlowState>(
      FirstStepFlowNotifier.new,
    );

/// Drives Stage1 Steps 9-10: the Chrome-AI-Mode round trip for 最初の一歩
/// divergence (mirrors `StrategyFlowNotifier`'s launch/paste pattern), then
/// deciding 最初の一歩 and fixing its 宣言文.
///
/// Deliberately doesn't write into `WizardState` or history itself —
/// `FirstStepFlowScreen` does that (via `ref.listen`) once
/// [FirstStepFlowConfirmed] is reached.
class FirstStepFlowNotifier extends Notifier<FirstStepFlowState> {
  static const _engine = AnalysisEngine();

  @override
  FirstStepFlowState build() => const FirstStepFlowLaunching();

  // ── Step 9: Chrome AI Mode round trip ─────────────────────────────────

  /// Copies [prompt] to the clipboard (manual-paste fallback) and opens it
  /// in Chrome AI Mode. Called as soon as `FirstStepFlowScreen` mounts.
  Future<void> openInChromeAiMode(String prompt) async {
    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      await ref.read(chromeAiLauncherProvider).openWithPrompt(prompt);
      state = const FirstStepFlowAwaitingPaste();
    } catch (error) {
      final lang = ref.read(appLanguageProvider);
      state = FirstStepFlowLaunchFailed(
        'Chromeを開けませんでした: %@'.trFmt(lang, ['$error']),
      );
    }
  }

  /// Reads the clipboard (where the user should have just copied Chrome's
  /// answer) and parses it into 10 [FirstStepSuggestion]s.
  Future<void> pasteAndParse() async {
    final lang = ref.read(appLanguageProvider);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text?.trim() ?? '';
    if (text.isEmpty) {
      state = FirstStepFlowPasteFailed(
        'クリップボードが空でした。Chromeで回答をコピーしてから、もう一度貼り付けてみてください。'.tr(lang),
      );
      return;
    }

    try {
      final suggestions = _engine.parseFirstStepResponse(text);
      if (suggestions.isEmpty) {
        state = FirstStepFlowPasteFailed(
          '最初の一歩を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。'.tr(lang),
        );
        return;
      }
      // Seed the editor with whatever was already decided in an earlier
      // pass at this project, so re-diverging never throws away previous
      // work — see `WizardState.decidedFirstStep`. It was saved as one
      // already-combined string, so — same as `StrategyFlowNotifier`'s
      // equivalent seeding — it all starts as `ownFirstStepText`, with
      // nothing toggled on.
      final wizard = ref.read(wizardProvider);
      state = FirstStepFlowDeciding(
        suggestions: suggestions,
        ownFirstStepText: wizard.decidedFirstStep,
        declaration: wizard.declaration,
      );
    } on FormatException {
      state = FirstStepFlowPasteFailed(
        '最初の一歩を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。'.tr(lang),
      );
    }
  }

  // ── Step 10: deciding 最初の一歩 ─────────────────────────────────────

  /// "あなたの最初の一歩"'s free-text field — wording that's entirely the
  /// user's own, kept separate from whatever's toggled on from
  /// [FirstStepFlowDeciding.suggestions] (see `decidedFirstStep`).
  void setOwnFirstStepText(String value) {
    final current = state;
    if (current is! FirstStepFlowDeciding) return;
    state = current.copyWith(ownFirstStepText: value);
  }

  /// "採用済／未採用": toggles [suggestion] in/out of
  /// [FirstStepFlowDeciding.adoptedSuggestionIds]. A toggle rather than a
  /// one-way adoption, so picking a suggestion and then changing your mind
  /// ("選んでみたもののやっぱりやめた") is just tapping it again.
  void toggleSuggestion(FirstStepSuggestion suggestion) {
    final current = state;
    if (current is! FirstStepFlowDeciding) return;
    final ids = {...current.adoptedSuggestionIds};
    if (!ids.remove(suggestion.id)) {
      ids.add(suggestion.id);
    }
    state = current.copyWith(adoptedSuggestionIds: ids);
  }

  /// 長押しで編集: rewords [suggestion] in place rather than requiring the
  /// user to abandon the AI's structure and retype it from scratch in
  /// "あなたの最初の一歩". No-ops on blank text — use [toggleSuggestion] to
  /// remove a suggestion from the decision instead of blanking it out.
  void editSuggestionText(FirstStepSuggestion suggestion, String newText) {
    final current = state;
    if (current is! FirstStepFlowDeciding) return;
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    state = current.copyWith(
      suggestions: [
        for (final s in current.suggestions)
          if (s.id == suggestion.id) s.copyWith(text: trimmed) else s,
      ],
    );
  }

  // ── Step 10: 宣言文 ────────────────────────────────────────────────────

  /// Moves to the 宣言文 screen, auto-filling it from
  /// `Project.suggestedDeclaration` the first time this is reached (an
  /// already-blank [FirstStepFlowDeciding.declaration] is the signal —
  /// once the user has typed anything, re-entering this screen never
  /// overwrites it).
  void showDeclaration() {
    final current = state;
    if (current is! FirstStepFlowDeciding) return;
    if (!current.canProceedToDeclaration) return;
    final seeded = current.declaration.trim().isNotEmpty
        ? current.declaration
        : Project(
            theme: '',
            desiredGoal: ref.read(wizardProvider).desiredGoal,
            decidedFirstStep: current.decidedFirstStep,
          ).suggestedDeclaration;
    state = current.copyWith(showingDeclaration: true, declaration: seeded);
  }

  void setDeclaration(String value) {
    final current = state;
    if (current is! FirstStepFlowDeciding) return;
    state = current.copyWith(declaration: value);
  }

  /// Back to the 最初の一歩 editor without losing the 宣言文 already typed.
  void editFirstStep() {
    final current = state;
    if (current is! FirstStepFlowDeciding) return;
    state = current.copyWith(showingDeclaration: false);
  }

  // ── Fix ────────────────────────────────────────────────────────────────

  /// "決定" — Stage1's "Fix完了".
  void confirm() {
    final current = state;
    if (current is! FirstStepFlowDeciding || !current.canConfirm) return;
    state = FirstStepFlowConfirmed(
      decidedFirstStep: current.decidedFirstStep.trim(),
      declaration: current.declaration.trim(),
      suggestions: current.suggestions,
    );
  }

  void reset() => state = const FirstStepFlowLaunching();

  /// Opens the decide/declare loop with suggestions already saved on the
  /// project — used when re-reviewing 最初の一歩 from the dashboard.
  /// Suggestions whose text still appears in [decidedFirstStep] are
  /// restored as 採用済; any leftover wording stays in `ownFirstStepText`.
  void resumeFromCached({
    required List<FirstStepSuggestion> suggestions,
    required String decidedFirstStep,
    required String declaration,
  }) {
    final split = splitDecidedIntoAdoptions(
      suggestions: [
        for (final s in suggestions) (id: s.id, text: s.text),
      ],
      decidedText: decidedFirstStep,
    );
    state = FirstStepFlowDeciding(
      suggestions: suggestions,
      ownFirstStepText: split.ownText,
      adoptedSuggestionIds: split.adoptedIds,
      declaration: declaration,
    );
  }
}
