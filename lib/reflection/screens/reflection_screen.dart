import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../first_step/screens/first_step_flow_screen.dart';
import '../../history/project_navigation.dart';
import '../../history/state/analysis_history_notifier.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../models/project_status.dart';
import '../../models/reflection_entry.dart';
import '../../strategy/screens/strategy_flow_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../wizard/screens/wizard_flow_screen.dart';
import '../../wizard/state/wizard_notifier.dart';
import '../../wizard/widgets/primary_cta_button.dart';

/// Stage3: 振り返り — Stage2（ダッシュボード実施）から「振り返り」で到達。
///
/// Two phases in one screen (not two pushed routes) — the same
/// "single screen, internal phase toggle" shape as
/// `StrategyFlowDeciding.showingCheck` / `FirstStepFlowDeciding.
/// showingDeclaration`:
/// 1. "どうだった？" — free-text [ReflectionEntry.howItWent].
/// 2. "次はどうする？" — one of 5 choices, each recorded as
///    [ReflectionEntry.nextChoice] using the Japanese label itself (this
///    app's l10n keys already *are* the Japanese text, so reusing that as
///    the persisted value avoids inventing a parallel raw-identifier enum
///    for a single field) and each routing onward differently.
///
/// Every choice appends to [Project.reflectionHistory] and saves — this is
/// the first flow in the app that actually populates that list, which also
/// feeds into [Project.progressRatio]'s reflection milestones (60% at 1,
/// 70% at 2, 80% at 3, 90% at 5+); marking the project 完了 reaches 100%.
class ReflectionScreen extends ConsumerStatefulWidget {
  final Project project;
  final bool fromProjectDashboard;

  const ReflectionScreen({
    super.key,
    required this.project,
    this.fromProjectDashboard = false,
  });

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

enum _Phase { howItWent, nextChoice }

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  _Phase _phase = _Phase.howItWent;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceedToChoice() {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _phase = _Phase.nextChoice);
  }

  Future<void> _choose(String choice) async {
    final project = widget.project;
    final history = [
      ...project.reflectionHistory,
      ReflectionEntry(howItWent: _controller.text.trim(), nextChoice: choice),
    ];
    final historyNotifier = ref.read(analysisHistoryProvider.notifier);

    switch (choice) {
      case '続ける':
        final updated = project.copyWith(
          reflectionHistory: history,
          status: ProjectStatus.inProgress,
          updatedAt: DateTime.now(),
        );
        await historyNotifier.saveOrUpdate(updated);
        ref.read(wizardProvider.notifier).resumeFrom(updated);
        if (!mounted) return;
        final firstStepScreen = FirstStepFlowScreen(
          fromProjectDashboard: widget.fromProjectDashboard,
          startFromCachedSuggestions:
              updated.aiFirstStepSuggestions.isNotEmpty,
        );
        Navigator.of(context).push(
          widget.fromProjectDashboard
              ? ProjectNavigation.childRoute(firstStepScreen)
              : MaterialPageRoute(builder: (_) => firstStepScreen),
        );

      case '方策を変更する':
        final updated = project.copyWith(
          reflectionHistory: history,
          status: ProjectStatus.inProgress,
          updatedAt: DateTime.now(),
        );
        await historyNotifier.saveOrUpdate(updated);
        ref.read(wizardProvider.notifier).resumeFrom(updated);
        if (!mounted) return;
        final strategyScreen = StrategyFlowScreen(
          fromProjectDashboard: widget.fromProjectDashboard,
          startFromCachedSuggestions:
              updated.aiStrategySuggestions.isNotEmpty,
        );
        Navigator.of(context).push(
          widget.fromProjectDashboard
              ? ProjectNavigation.childRoute(strategyScreen)
              : MaterialPageRoute(builder: (_) => strategyScreen),
        );

      case '新しいテーマに取り組む':
        // 現況 is deliberately left as-is (実施中のまま) rather than
        // auto-completing or pausing this project — those are already
        // their own explicit choices ("完了"/"一旦休む" below). Picking a
        // new theme just branches off to start something else; it says
        // nothing about whether *this* project is done or paused.
        final updated = project.copyWith(
          reflectionHistory: history,
          updatedAt: DateTime.now(),
        );
        await historyNotifier.saveOrUpdate(updated);
        ref.read(wizardProvider.notifier).reset();
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WizardFlowScreen()));

      case '一旦休む':
        final updated = project.copyWith(
          reflectionHistory: history,
          status: ProjectStatus.onBreak,
          updatedAt: DateTime.now(),
        );
        await historyNotifier.saveOrUpdate(updated);
        if (!mounted) return;
        Navigator.of(context).pop();

      case '完了':
        final updated = project.copyWith(
          reflectionHistory: history,
          status: ProjectStatus.completed,
          updatedAt: DateTime.now(),
        );
        await historyNotifier.saveOrUpdate(updated);
        if (!mounted) return;
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final appBar = OsmAppBar(title: Text('振り返り'.tr(lang)));
    final body = SafeArea(
      bottom: false,
      child: switch (_phase) {
        _Phase.howItWent => _HowItWentView(
          controller: _controller,
          lang: lang,
          onSave: _proceedToChoice,
        ),
        _Phase.nextChoice => _NextChoiceView(lang: lang, onChoose: _choose),
      },
    );

    if (widget.fromProjectDashboard) {
      return ProjectScaffold(
        projectId: widget.project.id,
        mode: ProjectToolbarMode.child,
        appBar: appBar,
        body: body,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBar,
      body: body,
    );
  }
}

class _HowItWentView extends StatelessWidget {
  final TextEditingController controller;
  final AppLanguage lang;
  final VoidCallback onSave;

  const _HowItWentView({
    required this.controller,
    required this.lang,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboardOpen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'どうだった？'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: keyboardOpen ? 3 : 5,
            maxLines: 10,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (controller.text.trim().isNotEmpty) onSave();
            },
            decoration: InputDecoration(
              hintText: '感じたこと、気づいたことを自由に書いてみましょう'.tr(lang),
            ),
          ),
          if (!keyboardOpen) ...[
            const SizedBox(height: 24),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) => PrimaryCtaButton(
                label: '保存'.tr(lang),
                icon: Icons.check_rounded,
                visible: value.text.trim().isNotEmpty,
                onPressed: onSave,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextChoiceView extends StatelessWidget {
  final AppLanguage lang;
  final void Function(String choice) onChoose;

  const _NextChoiceView({required this.lang, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          '次はどうする？'.tr(lang),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
        ),
        const SizedBox(height: 20),
        _ChoiceCard(
          icon: Icons.arrow_forward_rounded,
          label: '続ける'.tr(lang),
          onTap: () => onChoose('続ける'),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          icon: Icons.autorenew_rounded,
          label: '方策を変更する'.tr(lang),
          onTap: () => onChoose('方策を変更する'),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          icon: Icons.add_circle_outline_rounded,
          label: '新しいテーマに取り組む'.tr(lang),
          onTap: () => onChoose('新しいテーマに取り組む'),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          icon: Icons.pause_circle_outline_rounded,
          label: '一旦休む'.tr(lang),
          onTap: () => onChoose('一旦休む'),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          icon: Icons.flag_rounded,
          label: '完了'.tr(lang),
          onTap: () => onChoose('完了'),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.cardFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppPalette.mintDark),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppPalette.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
