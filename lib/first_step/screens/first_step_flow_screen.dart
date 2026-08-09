import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/prompt_library.dart';
import '../../engine/widgets/chrome_ai_flow_shell.dart';
import '../../export/screens/project_export_screen.dart';
import '../../history/state/analysis_history_notifier.dart';
import '../../history/project_navigation.dart';
import '../../history/widgets/flow_scaffold.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/first_step_suggestion.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/app_dialog.dart';
import '../../theme/widgets/decided_items_text.dart';
import '../../theme/widgets/edit_field_dialogs.dart';
import '../../wizard/state/wizard_notifier.dart';
import '../../wizard/widgets/primary_cta_button.dart';
import '../state/first_step_flow_notifier.dart';
import '../state/first_step_flow_state.dart';
import '../widgets/first_step_suggestion_card.dart';

/// Stage1 Steps 9-10: diverge 10 最初の一歩 candidates via Chrome AI Mode
/// once 方策 is fixed (Step 9), then let the user decide one (adopt/merge/
/// write their own) and fix its 宣言文 (Step 10) — "Fix完了" once both are
/// set, which also flips `Project.status` to 実施中 (see
/// `WizardState.toProject`).
///
/// Chrome AI launch/paste UI is shared via [chrome_ai_flow_shell]; this
/// screen owns decide → 宣言文 → [ProjectExportScreen] after paste.
class FirstStepFlowScreen extends ConsumerStatefulWidget {
  const FirstStepFlowScreen({
    super.key,
    this.startFromCachedSuggestions = false,
    this.popOnConfirm = false,
    this.fromProjectDashboard = false,
  });

  final bool startFromCachedSuggestions;
  final bool popOnConfirm;
  final bool fromProjectDashboard;

  @override
  ConsumerState<FirstStepFlowScreen> createState() =>
      _FirstStepFlowScreenState();
}

class _FirstStepFlowScreenState extends ConsumerState<FirstStepFlowScreen>
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
      final flowState = ref.read(firstStepFlowProvider);
      if (flowState is FirstStepFlowAwaitingPaste ||
          flowState is FirstStepFlowPasteFailed) {
        ref.read(firstStepFlowProvider.notifier).pasteAndParse();
      }
    });
  }

  void _loadCachedSuggestions() {
    final wizard = ref.read(wizardProvider);
    if (wizard.aiFirstStepSuggestions.isEmpty) {
      _requestConsentAndOpen(leaveOnDecline: widget.popOnConfirm);
      return;
    }
    ref.read(firstStepFlowProvider.notifier).resumeFromCached(
      suggestions: wizard.aiFirstStepSuggestions,
      decidedFirstStep: wizard.decidedFirstStep,
      declaration: wizard.declaration,
    );
  }

  Future<void> _requestConsentAndOpen({bool leaveOnDecline = false}) {
    final lang = ref.read(appLanguageProvider);
    return requestGoogleAiConsentAndOpen(
      context: context,
      lang: lang,
      titleKey: '最初の一歩_Google送信確認_タイトル',
      bodyKey: '最初の一歩_Google送信確認_本文',
      leaveOnDecline: leaveOnDecline,
      openChrome: _openChrome,
    );
  }

  Future<void> _openChrome() {
    final notifier = ref.read(firstStepFlowProvider.notifier);
    final wizard = ref.read(wizardProvider);
    final lang = ref.read(appLanguageProvider);
    final prompt = PromptLibrary.firstStepChromeAiPrompt(
      theme: wizard.theme,
      desiredGoal: wizard.desiredGoal,
      decidedStrategy: wizard.decidedStrategy,
      language: PromptLanguage.fromAppLanguage(lang),
    );
    return notifier.openInChromeAiMode(prompt);
  }

  /// "決定": fold 最初の一歩/宣言文 into the same history record the
  /// earlier screens already saved (matched by `WizardState.sessionId`).
  void _onConfirmed(FirstStepFlowConfirmed confirmed) {
    ref
        .read(wizardProvider.notifier)
        .confirmFirstStep(
          decidedFirstStep: confirmed.decidedFirstStep,
          declaration: confirmed.declaration,
          aiFirstStepSuggestions: confirmed.suggestions,
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
    ref.listen(firstStepFlowProvider, (previous, next) {
      if (next is FirstStepFlowConfirmed) {
        _onConfirmed(next);
        if (widget.popOnConfirm && context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
      }
    });
    final flowState = ref.watch(firstStepFlowProvider);
    final notifier = ref.read(firstStepFlowProvider.notifier);
    final lang = ref.watch(appLanguageProvider);

    // Present tense while still deciding, past tense once confirmed —
    // mirrors StrategyFlowScreen's confirmed-state heading. FittedBox keeps
    // it on one line: the en/vi translations run longer than the ja
    // original and would otherwise wrap within the app bar.
    final titleKey = flowState is FirstStepFlowConfirmed
        ? '最初の一歩を決めた'
        : '最初の一歩を決める';
    final appBar = OsmAppBar(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(titleKey.tr(lang), maxLines: 1, softWrap: false),
      ),
    );
    final body = SafeArea(
      child: switch (flowState) {
        FirstStepFlowLaunching() => ChromeAiLaunchingView(lang: lang),
        FirstStepFlowLaunchFailed(:final message) => ChromeAiLaunchFailedView(
          message: message,
          lang: lang,
          onRetry: () => _requestConsentAndOpen(),
        ),
        FirstStepFlowAwaitingPaste() => ChromeAiAwaitingPasteView(
          lang: lang,
          onPaste: notifier.pasteAndParse,
          onReopenChrome: () => _requestConsentAndOpen(),
        ),
        FirstStepFlowPasteFailed(:final message) => ChromeAiPasteFailedView(
          message: message,
          lang: lang,
          onRetryPaste: notifier.pasteAndParse,
          onReopenChrome: () => _requestConsentAndOpen(),
        ),
        FirstStepFlowDeciding(showingDeclaration: true) =>
          _DeclarationView(state: flowState, lang: lang, notifier: notifier),
        FirstStepFlowDeciding() => _FirstStepEditorView(
          state: flowState,
          lang: lang,
          notifier: notifier,
          onRequestFresh: () => _requestConsentAndOpen(),
        ),
        FirstStepFlowConfirmed() => _ConfirmedView(
          state: flowState,
          lang: lang,
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


class _FirstStepEditorView extends StatefulWidget {
  final FirstStepFlowDeciding state;
  final AppLanguage lang;
  final FirstStepFlowNotifier notifier;

  /// Re-opens the consent dialog → Chrome AI Mode round trip from scratch —
  /// see the identical doc comment on `StrategyFlowScreen`'s own
  /// `_StrategyEditorView.onRequestFresh`.
  final VoidCallback onRequestFresh;

  const _FirstStepEditorView({
    required this.state,
    required this.lang,
    required this.notifier,
    required this.onRequestFresh,
  });

  @override
  State<_FirstStepEditorView> createState() => _FirstStepEditorViewState();
}

class _FirstStepEditorViewState extends State<_FirstStepEditorView> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.ownFirstStepText,
  );

  @override
  void didUpdateWidget(covariant _FirstStepEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Toggling/editing a suggestion no longer touches this field — see the
    // identical comment in StrategyFlowScreen's `_StrategyEditorViewState`.
    if (widget.state.ownFirstStepText != _controller.text) {
      _controller.text = widget.state.ownFirstStepText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _editSuggestion(FirstStepSuggestion suggestion) async {
    final newText = await showAppAlertDialog<String>(
      context: context,
      builder: (context) => EditTextFieldDialog(
        lang: widget.lang,
        title: '最初の一歩を編集'.tr(widget.lang),
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
                  'AIが考えた10個の最初の一歩'.tr(lang),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: FirstStepSuggestionCard(
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
            'あなたの最初の一歩'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 6,
            onChanged: notifier.setOwnFirstStepText,
            decoration: InputDecoration(
              hintText: 'AIの提案にない、独自の最初の一歩があれば書く'.tr(lang),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryCtaButton(
            label: '宣言文を確認する'.tr(lang),
            icon: Icons.campaign_outlined,
            visible: state.canProceedToDeclaration,
            onPressed: notifier.showDeclaration,
          ),
        ],
      ),
    );
  }
}

/// 長押しで編集 dialog — see the identical comment on

class _DeclarationView extends StatefulWidget {
  final FirstStepFlowDeciding state;
  final AppLanguage lang;
  final FirstStepFlowNotifier notifier;

  const _DeclarationView({
    required this.state,
    required this.lang,
    required this.notifier,
  });

  @override
  State<_DeclarationView> createState() => _DeclarationViewState();
}

class _DeclarationViewState extends State<_DeclarationView> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.declaration,
  );

  @override
  void didUpdateWidget(covariant _DeclarationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.declaration != _controller.text) {
      _controller.text = widget.state.declaration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final state = widget.state;
    final notifier = widget.notifier;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '宣言文'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
          ),
          const SizedBox(height: 8),
          Text(
            '上司や仲間にそのまま送れる、ひとことにしましょう。'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // cardFill, not canvas — see the identical comment in
              // StrategyFlowScreen's _JiritsuCheckView.
              color: AppPalette.cardFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最初の一歩'.tr(lang),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                DecidedItemsText(
                  value: state.decidedFirstStep,
                  itemLabel: '最初の一歩'.tr(lang),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 6,
            onChanged: notifier.setDeclaration,
            decoration: InputDecoration(hintText: '宣言文'.tr(lang)),
          ),
          const SizedBox(height: 28),
          PrimaryCtaButton(
            label: '決定'.tr(lang),
            icon: Icons.check_circle_outline_rounded,
            visible: state.canConfirm,
            onPressed: notifier.confirm,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: notifier.editFirstStep,
              child: Text('最初の一歩を編集する'.tr(lang)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stage1's "Fix完了" terminal state: 決定した最初の一歩と宣言文の要約。
class _ConfirmedView extends StatelessWidget {
  final FirstStepFlowConfirmed state;
  final AppLanguage lang;
  final bool fromProjectDashboard;

  const _ConfirmedView({
    required this.state,
    required this.lang,
    this.fromProjectDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    // A scroll view, not `Center`: `decidedFirstStep`/`declaration` can be
    // long (combined suggestions, or a freely-edited 宣言文), so this
    // content's height isn't bounded — same overflow risk as
    // `StrategyFlowScreen`'s own confirmed view.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            '自律計画ができました'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
            textAlign: TextAlign.center,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecidedItemsText(
                  value: state.decidedFirstStep,
                  itemLabel: '最初の一歩'.tr(lang),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  '「${state.declaration}」',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PrimaryCtaButton(
            label: 'まとめを共有'.tr(lang),
            icon: Icons.ios_share_rounded,
            onPressed: () {
              final exportScreen = ProjectExportScreen(
                fromProjectDashboard: fromProjectDashboard,
              );
              Navigator.of(context).push(
                fromProjectDashboard
                    ? ProjectNavigation.childRoute(exportScreen)
                    : MaterialPageRoute(builder: (_) => exportScreen),
              );
            },
          ),
        ],
      ),
    );
  }
}
