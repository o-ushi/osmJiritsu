import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/prompt_library.dart';
import '../../engine/widgets/chrome_ai_flow_shell.dart';
import '../../first_step/screens/first_step_flow_screen.dart';
import '../../history/state/analysis_history_notifier.dart';
import '../../history/history_toolbar_actions.dart';
import '../../history/project_navigation.dart';
import '../../history/widgets/flow_scaffold.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/app_dialog.dart';
import '../../theme/widgets/decided_items_text.dart';
import '../../theme/widgets/edit_field_dialogs.dart';
import '../../models/project.dart';
import '../../models/strategy_suggestion.dart';
import '../../wizard/state/wizard_notifier.dart';
import '../../wizard/widgets/primary_cta_button.dart';
import '../state/strategy_flow_notifier.dart';
import '../state/strategy_flow_state.dart';
import '../widgets/jiritsu_check_panel.dart';
import '../widgets/strategy_suggestion_card.dart';

/// Stage1 Steps 5-8 — the heart of "自律": diverge 5 方策 candidates via
/// Chrome AI Mode (Step 5), then loop the user through deciding one in
/// their own words (Step 6), checking it against 自律の3要素 (Step 7), and
/// redefining it (Step 8) for as long as they like, until they explicitly
/// tap "納得した".
///
/// Chrome AI launch/paste UI is shared via [chrome_ai_flow_shell]; this
/// screen owns the decide → jiritsu check → confirm loop after paste.
class StrategyFlowScreen extends ConsumerStatefulWidget {
  const StrategyFlowScreen({
    super.key,
    this.startFromCachedSuggestions = false,
    this.popOnConfirm = false,
    this.fromProjectDashboard = false,
  });

  /// When true, skip Chrome and open the editor with saved AI suggestions.
  final bool startFromCachedSuggestions;

  /// When true (dashboard re-review), save and pop instead of continuing
  /// to the "最初の一歩" screen.
  final bool popOnConfirm;

  /// When true, uses the project dashboard toolbar instead of the wizard
  /// flow toolbar.
  final bool fromProjectDashboard;

  @override
  ConsumerState<StrategyFlowScreen> createState() =>
      _StrategyFlowScreenState();
}

class _StrategyFlowScreenState extends ConsumerState<StrategyFlowScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startFromCachedSuggestions) {
        _loadCachedSuggestions();
      } else {
        _requestConsentAndOpen(leaveOnDecline: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-pastes Chrome's answer on return. Manual paste buttons in the
  /// shared Chrome AI shell stay as a fallback when the clipboard isn't ready.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final flowState = ref.read(strategyFlowProvider);
      if (flowState is StrategyFlowAwaitingPaste ||
          flowState is StrategyFlowPasteFailed) {
        ref.read(strategyFlowProvider.notifier).pasteAndParse();
      }
    });
  }

  void _loadCachedSuggestions() {
    final wizard = ref.read(wizardProvider);
    if (wizard.aiStrategySuggestions.isEmpty) {
      _requestConsentAndOpen(leaveOnDecline: widget.popOnConfirm);
      return;
    }
    ref.read(strategyFlowProvider.notifier).resumeFromCached(
      suggestions: wizard.aiStrategySuggestions,
      decidedStrategy: wizard.decidedStrategy,
      jiritsuCheck: wizard.jiritsuCheck,
    );
  }

  Future<void> _requestConsentAndOpen({bool leaveOnDecline = false}) {
    final lang = ref.read(appLanguageProvider);
    return requestGoogleAiConsentAndOpen(
      context: context,
      lang: lang,
      titleKey: '方策_Google送信確認_タイトル',
      bodyKey: '方策_Google送信確認_本文',
      leaveOnDecline: leaveOnDecline,
      openChrome: _openChrome,
    );
  }

  Future<void> _openChrome() {
    final notifier = ref.read(strategyFlowProvider.notifier);
    final wizard = ref.read(wizardProvider);
    final lang = ref.read(appLanguageProvider);
    final prompt = PromptLibrary.strategyChromeAiPrompt(
      theme: wizard.theme,
      desiredGoal: wizard.desiredGoal,
      undesiredGoal: wizard.undesiredGoal,
      matrix: wizard.toSwotMatrix(),
      language: PromptLanguage.fromAppLanguage(lang),
    );
    return notifier.openInChromeAiMode(prompt);
  }

  /// Step 8's "納得した": fold the decided strategy + jiritsu check into
  /// the same history record the matrix screen already saved (matched by
  /// `WizardState.sessionId`) — done via `ref.listen` (a post-build side
  /// effect), not inline in `build`, since mutating another provider
  /// during a build is unsafe.
  void _onConfirmed(StrategyFlowConfirmed confirmed) {
    ref
        .read(wizardProvider.notifier)
        .confirmStrategy(
          decidedStrategy: confirmed.decidedStrategy,
          aiStrategySuggestions: confirmed.suggestions,
          jiritsuCheck: confirmed.jiritsuCheck,
        );
    final wizard = ref.read(wizardProvider);
    final history = ref.read(analysisHistoryProvider).value ?? const [];
    Project? existing;
    for (final project in history) {
      if (project.id == wizard.sessionId) {
        existing = project;
        break;
      }
    }
    final project = existing != null
        ? wizard.toProjectPreserving(existing)
        : wizard.toProject();
    ref.read(analysisHistoryProvider.notifier).saveOrUpdate(project);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(strategyFlowProvider, (previous, next) {
      if (next is StrategyFlowConfirmed) {
        _onConfirmed(next);
        if (widget.popOnConfirm && context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      }
    });
    final flowState = ref.watch(strategyFlowProvider);
    final notifier = ref.read(strategyFlowProvider.notifier);
    final lang = ref.watch(appLanguageProvider);

    final appBar = OsmAppBar(title: Text('方策を決める'.tr(lang)));
    final body = SafeArea(
      child: switch (flowState) {
        StrategyFlowLaunching() => ChromeAiLaunchingView(lang: lang),
        StrategyFlowLaunchFailed(:final message) => ChromeAiLaunchFailedView(
          message: message,
          lang: lang,
          onRetry: () => _requestConsentAndOpen(),
        ),
        StrategyFlowAwaitingPaste() => ChromeAiAwaitingPasteView(
          lang: lang,
          onPaste: notifier.pasteAndParse,
          onReopenChrome: () => _requestConsentAndOpen(),
        ),
        StrategyFlowPasteFailed(:final message) => ChromeAiPasteFailedView(
          message: message,
          lang: lang,
          onRetryPaste: notifier.pasteAndParse,
          onReopenChrome: () => _requestConsentAndOpen(),
        ),
        StrategyFlowDeciding(showingCheck: true) => _JiritsuCheckView(
          state: flowState,
          lang: lang,
          notifier: notifier,
        ),
        StrategyFlowDeciding() => _StrategyEditorView(
          state: flowState,
          lang: lang,
          notifier: notifier,
          onRequestFresh: () => _requestConsentAndOpen(),
        ),
        StrategyFlowConfirmed() => _ConfirmedView(
          state: flowState,
          lang: lang,
          onGoHome: widget.fromProjectDashboard
              ? () => ProjectNavigation.popToDashboard(context)
              : () => HistoryToolbarActions(ref, lang).goHome(
                    context,
                    persistWizard: true,
                  ),
          fromProjectDashboard: widget.fromProjectDashboard,
        ),
      },
    );

    if (widget.fromProjectDashboard) {
      return ProjectScaffold(
        projectId: ref.read(wizardProvider).sessionId,
        mode: ProjectToolbarMode.child,
        appBar: appBar,
        body: body,
        guideMessageKey: '操作方法_方策最初の一歩',
      );
    }

    return FlowScaffold(
      appBar: appBar,
      body: body,
      guideMessageKey: '操作方法_方策最初の一歩',
    );
  }
}


class _StrategyEditorView extends StatefulWidget {
  final StrategyFlowDeciding state;
  final AppLanguage lang;
  final StrategyFlowNotifier notifier;

  /// Re-opens the consent dialog → Chrome AI Mode round trip from scratch,
  /// replacing [state.suggestions] once the user pastes a new answer.
  /// Previously only reachable by picking "AIに再度相談する" from a
  /// bottom sheet shown *before* landing here (see
  /// `DashboardScreen._pickAiReviewChoice`, since removed) — folding it
  /// into this screen means re-reviewing 方策 always lands directly on
  /// whatever's cached (or a fresh dive if there's nothing cached yet),
  /// with this as the one explicit way to ask for new suggestions instead.
  final VoidCallback onRequestFresh;

  const _StrategyEditorView({
    required this.state,
    required this.lang,
    required this.notifier,
    required this.onRequestFresh,
  });

  @override
  State<_StrategyEditorView> createState() => _StrategyEditorViewState();
}

class _StrategyEditorViewState extends State<_StrategyEditorView> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.ownStrategyText,
  );

  @override
  void didUpdateWidget(covariant _StrategyEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keeps the field in sync when `ownStrategyText` changes for a reason
    // other than typing in it directly (e.g. Step 5 re-diverging reseeds
    // it) — setting `.text` doesn't fire `onChanged`, so this can't loop
    // back into the notifier. Toggling/editing a suggestion no longer
    // touches this field at all, so it's never overwritten by that.
    if (widget.state.ownStrategyText != _controller.text) {
      _controller.text = widget.state.ownStrategyText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editSuggestion(StrategySuggestion suggestion) async {
    final newText = await showAppAlertDialog<String>(
      context: context,
      builder: (context) =>
          EditTextFieldDialog(
            lang: widget.lang,
            title: '方策を編集'.tr(widget.lang),
            initialText: suggestion.text,
          ),
    );
    if (newText == null) return;
    widget.notifier.editSuggestionText(suggestion, newText);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final state = widget.state;
    final notifier = widget.notifier;
    final onRequestFresh = widget.onRequestFresh;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'AIが考えた5つの方策'.tr(lang),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppPalette.sceneText,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRequestFresh,
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppPalette.ensureReadableOnScene(AppPalette.sceneText),
                ),
                label: Text(
                  'AIに再度相談する'.tr(lang),
                  style: TextStyle(
                    color: AppPalette.ensureReadableOnScene(
                      AppPalette.sceneText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '「採用済／未採用」はタップで切り替えられます。文言を直したいときは案を長押しで編集できます。'
                .tr(lang),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
          ),
          const SizedBox(height: 14),
          for (final (index, suggestion) in state.suggestions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StrategySuggestionCard(
                index: index + 1,
                suggestion: suggestion,
                lang: lang,
                onToggle: () => notifier.toggleSuggestion(suggestion),
                onLongPress: () => _editSuggestion(suggestion),
                adopted: state.adoptedSuggestionIds.contains(suggestion.id),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'あなたの方策'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 8,
            onChanged: notifier.setOwnStrategyText,
            decoration: InputDecoration(
              hintText: 'AIの提案にない、独自の方策があれば書く'.tr(lang),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryCtaButton(
            label: '自律度をチェックする'.tr(lang),
            icon: Icons.checklist_rounded,
            visible: state.canProceedToCheck,
            onPressed: notifier.showJiritsuCheck,
          ),
        ],
      ),
    );
  }
}


/// Step 7: the 自律度チェック screen for whatever's currently in
/// `decidedStrategy`. "方策を編集する" loops back to Step 6/8's editor
/// (see [StrategyFlowNotifier.editStrategy]); "納得した" ends the loop.
class _JiritsuCheckView extends StatelessWidget {
  final StrategyFlowDeciding state;
  final AppLanguage lang;
  final StrategyFlowNotifier notifier;

  const _JiritsuCheckView({
    required this.state,
    required this.lang,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自律度チェック'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
          ),
          const SizedBox(height: 8),
          Text(
            '決めた方策を、3つの要素から見直してみましょう。'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // cardFill, not canvas — a highlight box needs to visually
              // stand out from (not blend into) the scene, and this way
              // its text can safely use the default card-oriented style.
              color: AppPalette.cardFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DecidedItemsText(
              value: state.decidedStrategy,
              itemLabel: '方策'.tr(lang),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 20),
          JiritsuCheckPanel(
            check: state.jiritsuCheck,
            lang: lang,
            onAnswer: notifier.setJiritsuAnswer,
          ),
          const SizedBox(height: 8),
          Text(
            '%lld / 3 満たしている'.trFmt(lang, [
              '${state.jiritsuCheck.satisfiedCount}',
            ]),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.ensureReadableOnScene(AppPalette.sceneText),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryCtaButton(
            label: '納得した'.tr(lang),
            icon: Icons.check_circle_outline_rounded,
            onPressed: notifier.confirm,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: notifier.editStrategy,
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.ensureReadableOnScene(
                  AppPalette.sceneText,
                ),
              ),
              child: Text('方策を編集する'.tr(lang)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 8's terminal state: 納得した方策の要約。Stage1 の次（最初の一歩）
/// へ進むのが主導線、「あとで」で履歴に戻ることもできる。
class _ConfirmedView extends StatelessWidget {
  final StrategyFlowConfirmed state;
  final AppLanguage lang;
  final VoidCallback onGoHome;
  final bool fromProjectDashboard;

  const _ConfirmedView({
    required this.state,
    required this.lang,
    required this.onGoHome,
    this.fromProjectDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    // A scroll view, not `Center`: `decidedStrategy` can be several
    // combined suggestions long (Step 6's "複数案を組み合わせてよい"), so
    // this content's height isn't bounded — a non-scrolling `Column` here
    // overflowed the screen once that text got long enough.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          // FittedBox rather than a bare Text: the en/vi translations run
          // longer than the ja original and would otherwise wrap to 2 lines.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '方策を決めた'.tr(lang),
              maxLines: 1,
              softWrap: false,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.cardFill,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: DecidedItemsText(
              value: state.decidedStrategy,
              itemLabel: '方策'.tr(lang),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '自律度チェック: %lld / 3'.trFmt(lang, [
              '${state.jiritsuCheck.satisfiedCount}',
            ]),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: AppPalette.ensureReadableOnScene(
                AppPalette.sceneTextMuted,
                minContrast: 3,
              ),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryCtaButton(
            label: '最初の一歩を決める'.tr(lang),
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              final firstStepScreen = FirstStepFlowScreen(
                fromProjectDashboard: fromProjectDashboard,
              );
              Navigator.of(context).push(
                fromProjectDashboard
                    ? ProjectNavigation.childRoute(firstStepScreen)
                    : MaterialPageRoute(builder: (_) => firstStepScreen),
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onGoHome,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.ensureReadableOnScene(
                AppPalette.sceneText,
              ),
            ),
            child: Text('あとで（履歴に戻る）'.tr(lang)),
          ),
        ],
      ),
    );
  }
}
