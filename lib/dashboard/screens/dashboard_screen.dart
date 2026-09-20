import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'declaration_edit_screen.dart';
import '../../history/project_navigation.dart';
import '../../history/state/analysis_history_notifier.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../history/widgets/project_status_chip.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../models/project_status.dart';
import '../../models/reflection_entry.dart';
import '../../models/situation_note.dart';
import '../../models/swot_item.dart';
import '../../reflection/screens/reflection_screen.dart';
import '../../first_step/screens/first_step_flow_screen.dart';
import '../../strategy/screens/strategy_flow_screen.dart';
import '../../wizard/screens/swot_matrix_screen.dart';
import '../../wizard/state/wizard_notifier.dart';
import '../../theme/app_theme.dart';
import '../../theme/subpage_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/app_dialog.dart';
import '../../theme/widgets/decided_items_text.dart';
import '../../theme/widgets/edit_field_dialogs.dart';

/// 案件ダッシュボード — Stage2（実施）のライブ状況画面。作成完了後の
/// [Project] を開き、期限/現況/備考や決定済み方策・一歩を更新する。
/// 作成中 (Stage1) の案件は `HistoryListScreen` がウィザードへ戻す。
class DashboardScreen extends ConsumerWidget {
  final Project project;

  const DashboardScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    // Re-read the live copy from history so edits made on this screen (or
    // anywhere else) are reflected immediately, falling back to the
    // constructor's snapshot if it's ever not found (e.g. mid-navigation).
    final projects = ref.watch(analysisHistoryProvider).value ?? const [];
    final current = projects.firstWhere(
      (p) => p.id == project.id,
      orElse: () => project,
    );
    final matrix = current.matrix;

    return ProjectScaffold(
      projectId: current.id,
      mode: ProjectToolbarMode.dashboard,
      onReflection: () => Navigator.of(context).push(
        ProjectNavigation.childRoute(
          ReflectionScreen(
            project: current,
            fromProjectDashboard: true,
          ),
        ),
      ),
      appBar: OsmAppBar(
        title: Tooltip(
          message: 'タップまたは長押しで編集'.tr(lang),
          child: GestureDetector(
            onTap: () => _editTheme(context, ref, current, lang),
            onLongPress: () => _editTheme(context, ref, current, lang),
            behavior: HitTestBehavior.opaque,
            child: Text(
              current.theme.isEmpty ? '分析結果'.tr(lang) : current.theme,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '削除'.tr(lang),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, ref, current, lang),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Tooltip(
              message: '現況を変更'.tr(lang),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _changeStatus(context, ref, current, lang),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProjectStatusChip(status: current.status, lang: lang),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppPalette.sceneTextMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ProgressOverview(project: current, lang: lang),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledSection(
                    label: '登録日'.tr(lang),
                    value: _formatDateTime(current.createdAt),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledSection(
                    label: '最終更新日'.tr(lang),
                    value: _formatDateTime(current.updatedAt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (current.desiredGoal.trim().isNotEmpty)
              _LabeledSection(
                label: '在りたい姿'.tr(lang),
                value: current.desiredGoal,
                longPressHint: 'タップまたは長押しで編集'.tr(lang),
                onTap: () => _editGoals(context, ref, current, lang),
                onLongPress: () => _editGoals(context, ref, current, lang),
              ),
            if (current.undesiredGoal.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _LabeledSection(
                label: '在りたくない姿'.tr(lang),
                value: current.undesiredGoal,
                longPressHint: 'タップまたは長押しで編集'.tr(lang),
                onTap: () => _editGoals(context, ref, current, lang),
                onLongPress: () => _editGoals(context, ref, current, lang),
              ),
            ],
            const SizedBox(height: 16),
            Tooltip(
              message: 'タップで今の状況を編集'.tr(lang),
              child: GestureDetector(
                onTap: () => _openSwotMatrix(context, ref, current),
                onLongPress: () => _openSwotMatrix(context, ref, current),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
              height: 420,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _ReadOnlyQuadrantPanel(
                    label: '強み'.tr(lang),
                    icon: Icons.bolt_rounded,
                    color: AppPalette.strength,
                    items: matrix.strengths,
                    lang: lang,
                  ),
                  _ReadOnlyQuadrantPanel(
                    label: '機会'.tr(lang),
                    icon: Icons.trending_up_rounded,
                    color: AppPalette.opportunity,
                    items: matrix.opportunities,
                    lang: lang,
                  ),
                  _ReadOnlyQuadrantPanel(
                    label: '弱み'.tr(lang),
                    icon: Icons.shield_outlined,
                    color: AppPalette.weakness,
                    items: matrix.weaknesses,
                    lang: lang,
                  ),
                  _ReadOnlyQuadrantPanel(
                    label: '脅威'.tr(lang),
                    icon: Icons.warning_amber_rounded,
                    color: AppPalette.threat,
                    items: matrix.threats,
                    lang: lang,
                  ),
                ],
              ),
            ),
              ),
            ),
            if (current.decidedStrategy.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              _LabeledSection(
                label: '方策'.tr(lang),
                value: current.decidedStrategy,
                itemNumberLabel: '方策'.tr(lang),
                longPressHint: '見直す方法を選んでください'.tr(lang),
                onTap: () => _reviseStrategy(context, ref, current, lang),
                onLongPress: () => _reviseStrategy(context, ref, current, lang),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '文言を編集'.tr(lang),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppPalette.sceneTextMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _editDecidedStrategy(context, ref, current, lang),
                    ),
                    IconButton(
                      tooltip: 'AIに再度相談する'.tr(lang),
                      icon: Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: AppPalette.sceneTextMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _reviewStrategy(context, ref, current),
                    ),
                    IconButton(
                      tooltip: 'やっぱりやらない'.tr(lang),
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                        color: AppPalette.sceneTextMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _discardDecidedStrategy(
                        context,
                        ref,
                        current,
                        lang,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              _DecidePlaceholder(
                label: '方策'.tr(lang),
                actionLabel: '方策を決める'.tr(lang),
                lang: lang,
                onDecide: () => _reviewStrategy(context, ref, current),
              ),
            ],
            if (current.decidedFirstStep.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _LabeledSection(
                label: '最初の一歩'.tr(lang),
                value: current.decidedFirstStep,
                itemNumberLabel: '最初の一歩'.tr(lang),
                longPressHint: '見直す方法を選んでください'.tr(lang),
                onTap: () => _reviseFirstStep(context, ref, current, lang),
                onLongPress: () => _reviseFirstStep(context, ref, current, lang),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '文言を編集'.tr(lang),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppPalette.sceneTextMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _editDecidedFirstStep(context, ref, current, lang),
                    ),
                    IconButton(
                      tooltip: 'AIに再度相談する'.tr(lang),
                      icon: Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: AppPalette.sceneTextMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _reviewFirstStep(context, ref, current),
                    ),
                    IconButton(
                      tooltip: 'やっぱりやらない'.tr(lang),
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                        color: AppPalette.sceneTextMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _discardDecidedFirstStep(
                        context,
                        ref,
                        current,
                        lang,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (current.decidedStrategy.trim().isNotEmpty) ...[
              // Only offer 最初の一歩 once a 方策 exists — otherwise the CTA
              // would open a first-step flow that requires decidedStrategy.
              const SizedBox(height: 16),
              _DecidePlaceholder(
                label: '最初の一歩'.tr(lang),
                actionLabel: '最初の一歩を決める'.tr(lang),
                lang: lang,
                onDecide: () => _reviewFirstStep(context, ref, current),
              ),
            ],
            if (current.declaration.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _LabeledSection(
                label: '宣言文'.tr(lang),
                value: '「${current.declaration}」',
                longPressHint: 'タップまたは長押しで編集'.tr(lang),
                onTap: () => _editDeclaration(context, current),
                onLongPress: () => _editDeclaration(context, current),
                trailing: IconButton(
                  tooltip: '宣言文を編集'.tr(lang),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppPalette.sceneTextMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editDeclaration(context, current),
                ),
              ),
            ],
            if (current.decidedStrategy.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '内発度チェック: %lld / 3'.trFmt(lang, [
                  '${current.jiritsuCheck.satisfiedCount}',
                ]),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
              ),
            ],
            if (current.situationNotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SituationNotesSection(notes: current.situationNotes, lang: lang),
            ],
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledSection(
                    label: '期限'.tr(lang),
                    value: current.deadline == null
                        ? '未設定'.tr(lang)
                        : _formatDate(current.deadline!),
                  ),
                ),
                IconButton(
                  tooltip: '期限を設定'.tr(lang),
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    size: 20,
                    color: AppPalette.sceneTextMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editDeadline(context, ref, current),
                ),
                if (current.deadline != null)
                  IconButton(
                    tooltip: '削除'.tr(lang),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppPalette.sceneTextMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _clearDeadline(ref, current),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _NoteEditor(project: current, lang: lang),
            if (current.reflectionHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '振り返り履歴'.tr(lang),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
              ),
              const SizedBox(height: 12),
              for (final entry in current.reflectionHistory.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey('reflection-${entry.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppPalette.coral.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: AppPalette.onAccent,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDeleteReflection(
                      context,
                      ref,
                      current,
                      entry,
                      lang,
                    ),
                    child: Tooltip(
                      message: '長押しで振り返りを編集'.tr(lang),
                      child: _ReflectionHistoryCard(
                        entry: entry,
                        lang: lang,
                        onLongPress: () => _editReflection(
                          context,
                          ref,
                          current,
                          entry,
                          lang,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final selected = await showReadableBottomSheet<ProjectStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final status in ProjectStatus.values)
              ListTile(
                title: Text(status.displayName.tr(lang)),
                trailing: status == project.status
                    ? Icon(Icons.check_rounded, color: AppPalette.mintDark)
                    : null,
                onTap: () => Navigator.of(context).pop(status),
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected == project.status) return;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(status: selected, updatedAt: DateTime.now()),
        );
  }

  Future<void> _editTheme(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final newTheme = await showAppAlertDialog<String>(
      context: context,
      builder: (context) => EditThemeDialog(theme: project.theme, lang: lang),
    );
    if (newTheme == null || newTheme == project.theme) return;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(theme: newTheme, updatedAt: DateTime.now()),
        );
  }

  Future<void> _editGoals(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final updated = await showAppAlertDialog<GoalPair>(
      context: context,
      builder: (context) => EditGoalsDialog(
        desiredGoal: project.desiredGoal,
        undesiredGoal: project.undesiredGoal,
        lang: lang,
      ),
    );
    if (updated == null) return;
    if (updated.desiredGoal == project.desiredGoal &&
        updated.undesiredGoal == project.undesiredGoal) {
      return;
    }
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(
            desiredGoal: updated.desiredGoal,
            undesiredGoal: updated.undesiredGoal,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> _editDeadline(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: project.deadline ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(deadline: picked, updatedAt: DateTime.now()),
        );
  }

  Future<void> _editReflection(
    BuildContext context,
    WidgetRef ref,
    Project project,
    ReflectionEntry entry,
    AppLanguage lang,
  ) async {
    final updated = await showAppAlertDialog<ReflectionEntry>(
      context: context,
      builder: (context) =>
          _EditReflectionDialog(entry: entry, lang: lang),
    );
    if (updated == null) return;
    if (updated.howItWent == entry.howItWent &&
        updated.nextChoice == entry.nextChoice) {
      return;
    }
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(
            reflectionHistory: [
              for (final item in project.reflectionHistory)
                if (item.id == entry.id) updated else item,
            ],
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<bool> _confirmDeleteReflection(
    BuildContext context,
    WidgetRef ref,
    Project project,
    ReflectionEntry entry,
    AppLanguage lang,
  ) async {
    final confirmed = await showAppAlertDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('この振り返りを削除しますか？'.tr(lang)),
        content: Text('元に戻すことはできません。'.tr(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('削除する'.tr(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(
            reflectionHistory: [
              for (final item in project.reflectionHistory)
                if (item.id != entry.id) item,
            ],
            updatedAt: DateTime.now(),
          ),
        );
    return true;
  }

  Future<void> _clearDeadline(WidgetRef ref, Project project) async {
    if (project.deadline == null) return;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(clearDeadline: true, updatedAt: DateTime.now()),
        );
  }

  /// "やっぱりやらない": lets a decided 方策 be discarded after the fact,
  /// distinct from "見直す" (which re-opens the AI decide/redefine loop) —
  /// this just clears it back to undecided. `aiStrategySuggestions` is
  /// deliberately left untouched so "見直す" can still resume from the
  /// same cached suggestions afterward if the user changes their mind
  /// again. `decidedFirstStep` is likewise left alone — discarding a
  /// strategy doesn't force a decision on whatever first step was already
  /// recorded for it.
  Future<void> _discardDecidedStrategy(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final confirmed = await _confirmDiscard(
      context,
      lang,
      title: '方策を取り消しますか？'.tr(lang),
    );
    if (confirmed != true) return;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(
            clearDecidedStrategy: true,
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// "やっぱりやらない" for 最初の一歩 — see [_discardDecidedStrategy].
  Future<void> _discardDecidedFirstStep(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final confirmed = await _confirmDiscard(
      context,
      lang,
      title: '最初の一歩を取り消しますか？'.tr(lang),
    );
    if (confirmed != true) return;
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          project.copyWith(
            clearDecidedFirstStep: true,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<bool?> _confirmDiscard(
    BuildContext context,
    AppLanguage lang, {
    required String title,
  }) {
    return showAppAlertDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('元に戻すことはできません。'.tr(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('やっぱりやらない'.tr(lang)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final confirmed = await showAppAlertDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('この分析を削除しますか？'.tr(lang)),
        content: Text('元に戻すことはできません。'.tr(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('削除する'.tr(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(analysisHistoryProvider.notifier).delete(project.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  static Future<void> _editDeclaration(
    BuildContext context,
    Project project,
  ) async {
    await Navigator.of(context).push(
      ProjectNavigation.childRoute(
        DeclarationEditScreen(project: project),
      ),
    );
  }

  static Future<void> _openSwotMatrix(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    ref.read(wizardProvider.notifier).resumeFrom(project);
    await Navigator.of(context).push(
      ProjectNavigation.childRoute(
        const SwotMatrixScreen(fromProjectDashboard: true),
      ),
    );
  }

  /// Light edit of decided 方策 text without reopening the AI flow.
  static Future<void> _editDecidedStrategy(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final updated = await showAppAlertDialog<String>(
      context: context,
      builder: (context) => EditTextFieldDialog(
        lang: lang,
        title: '方策を編集'.tr(lang),
        initialText: project.decidedStrategy,
        requireNonEmpty: true,
      ),
    );
    if (updated == null) return;
    final trimmed = updated.trim();
    if (trimmed.isEmpty || trimmed == project.decidedStrategy) return;
    await ref.read(analysisHistoryProvider.notifier).saveOrUpdate(
      project.copyWith(decidedStrategy: trimmed, updatedAt: DateTime.now()),
    );
  }

  static Future<void> _editDecidedFirstStep(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final updated = await showAppAlertDialog<String>(
      context: context,
      builder: (context) => EditTextFieldDialog(
        lang: lang,
        title: '最初の一歩を編集'.tr(lang),
        initialText: project.decidedFirstStep,
        requireNonEmpty: true,
      ),
    );
    if (updated == null) return;
    final trimmed = updated.trim();
    if (trimmed.isEmpty || trimmed == project.decidedFirstStep) return;
    await ref.read(analysisHistoryProvider.notifier).saveOrUpdate(
      project.copyWith(decidedFirstStep: trimmed, updatedAt: DateTime.now()),
    );
  }

  /// Chooser: light wording edit vs AI reconsult.
  static Future<void> _reviseStrategy(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final choice = await showReadableBottomSheet<_ReviseChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '見直す方法を選んでください'.tr(lang),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('文言を編集'.tr(lang)),
              subtitle: Text('見直す_文言編集説明'.tr(lang)),
              onTap: () => Navigator.of(context).pop(_ReviseChoice.editWording),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text('AIに再度相談する'.tr(lang)),
              subtitle: Text('見直す_AI再相談説明'.tr(lang)),
              onTap: () => Navigator.of(context).pop(_ReviseChoice.aiReview),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ReviseChoice.editWording:
        await _editDecidedStrategy(context, ref, project, lang);
      case _ReviseChoice.aiReview:
        await _reviewStrategy(context, ref, project);
    }
  }

  static Future<void> _reviseFirstStep(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AppLanguage lang,
  ) async {
    final choice = await showReadableBottomSheet<_ReviseChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '見直す方法を選んでください'.tr(lang),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('文言を編集'.tr(lang)),
              subtitle: Text('見直す_文言編集説明'.tr(lang)),
              onTap: () => Navigator.of(context).pop(_ReviseChoice.editWording),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text('AIに再度相談する'.tr(lang)),
              subtitle: Text('見直す_AI再相談説明'.tr(lang)),
              onTap: () => Navigator.of(context).pop(_ReviseChoice.aiReview),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ReviseChoice.editWording:
        await _editDecidedFirstStep(context, ref, project, lang);
      case _ReviseChoice.aiReview:
        await _reviewFirstStep(context, ref, project);
    }
  }

  /// AI flow re-entry (cached suggestions when present).
  static Future<void> _reviewStrategy(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    ref.read(wizardProvider.notifier).resumeFrom(project);
    await Navigator.of(context).push(
      ProjectNavigation.childRoute(
        const StrategyFlowScreen(
          startFromCachedSuggestions: true,
          popOnConfirm: true,
          fromProjectDashboard: true,
        ),
      ),
    );
  }

  static Future<void> _reviewFirstStep(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    ref.read(wizardProvider.notifier).resumeFrom(project);
    await Navigator.of(context).push(
      ProjectNavigation.childRoute(
        const FirstStepFlowScreen(
          startFromCachedSuggestions: true,
          popOnConfirm: true,
          fromProjectDashboard: true,
        ),
      ),
    );
  }
}

enum _ReviseChoice { editWording, aiReview }

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${_formatDate(dt)} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _SituationNotesSection extends StatelessWidget {
  final List<SituationNote> notes;
  final AppLanguage lang;

  const _SituationNotesSection({required this.notes, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '壁打ちメモ'.tr(lang),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppPalette.sceneTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        for (final note in notes)
          if (note.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppPalette.cardFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.ink,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}


class _ProgressOverview extends StatelessWidget {
  final Project project;
  final AppLanguage lang;

  const _ProgressOverview({required this.project, required this.lang});

  @override
  Widget build(BuildContext context) {
    final reflectionCount = project.reflectionHistory.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '進捗度'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
            ),
            const Spacer(),
            Text(
              '${(project.progressRatio * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.sceneText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: project.progressRatio,
            minHeight: 8,
            backgroundColor: AppPalette.mint.withValues(alpha: 0.15),
            color: AppPalette.mintDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '振り返り回数'.tr(lang),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppPalette.sceneTextMuted),
        ),
        const SizedBox(height: 2),
        Text(
          '振り返り %lld回'.trFmt(lang, ['$reflectionCount']),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppPalette.sceneText),
        ),
      ],
    );
  }
}

/// 備考's inline editor: a plain (non-dialog) `TextField` whose `State`
/// persists across the parent's rebuilds (same widget position each time),
/// so typing survives whatever else on the dashboard triggers a rebuild.
/// Auto-saves 600ms after the user stops typing, and immediately on focus
/// loss so tapping away never drops the last few characters.
class _NoteEditor extends ConsumerStatefulWidget {
  final Project project;
  final AppLanguage lang;

  const _NoteEditor({required this.project, required this.lang});

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final _controller = TextEditingController(text: widget.project.note);
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() {
    _debounce?.cancel();
    final value = _controller.text;
    if (value == widget.project.note) return;
    ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          widget.project.copyWith(note: value, updatedAt: DateTime.now()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '備考'.tr(lang),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          minLines: 2,
          maxLines: 4,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: '備考を入力…'.tr(lang),
            filled: true,
            fillColor: AppPalette.cardFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// One [ReflectionEntry] from [Project.reflectionHistory] — the どうだった？
/// comment plus when it was recorded and what was chosen next, so past
/// reflections stay visible on the dashboard instead of only existing
/// inside the (write-only) ReflectionScreen flow. Long-press edits;
/// swipe left (via the surrounding [Dismissible]) deletes.
class _ReflectionHistoryCard extends StatelessWidget {
  final ReflectionEntry entry;
  final AppLanguage lang;
  final VoidCallback onLongPress;

  const _ReflectionHistoryCard({
    required this.entry,
    required this.lang,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.cardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: onLongPress,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPalette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateTime(entry.recordedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkMuted,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.nextChoice.tr(lang),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.mintDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.howItWent,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPalette.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyQuadrantPanel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<SwotItem> items;
  final AppLanguage lang;

  const _ReadOnlyQuadrantPanel({
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    // Same as swot_matrix_screen.dart's `_QuadrantPanel`: the painted
    // background is a translucent category color over AppPalette.scene,
    // not cardFill.
    const quadrantFillAlpha = 0.10;
    final quadrantBackground = Color.alphaBlend(
      color.withValues(alpha: quadrantFillAlpha),
      AppPalette.scene,
    );
    final onQuadrant = AppPalette.ensureReadableOn(
      background: quadrantBackground,
      preferred: color,
      minContrast: 4.5,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: quadrantFillAlpha),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    color: onQuadrant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'なし'.tr(lang),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onQuadrant,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.cardFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        items[index].content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          color: AppPalette.ink,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state row for a missing 方策 / 最初の一歩 — shown after
/// 「やっぱりやらない」 (or when never decided) so the user has a short
/// path back to decide without long-pressing a vanished section.
class _DecidePlaceholder extends StatelessWidget {
  final String label;
  final String actionLabel;
  final AppLanguage lang;
  final VoidCallback onDecide;

  const _DecidePlaceholder({
    required this.label,
    required this.actionLabel,
    required this.lang,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.sceneTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '未設定'.tr(lang),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.sceneText,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onDecide,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Repeated label-above-value block used for goals/方策/最初の一歩/宣言文/期限.
class _LabeledSection extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? longPressHint;

  /// When set (方策 / 最初の一歩), multiple `\n`-joined items are numbered
  /// and separated — see [DecidedItemsText]. Goals and 宣言文 leave this
  /// null so a single block of prose stays unnumbered.
  final String? itemNumberLabel;

  /// Icon button(s) shown beside the label (e.g. edit/discard). Kept out
  /// of the value's long-press area below — see [build] — so that e.g.
  /// holding the 削除 icon can't be captured by a same-action long press
  /// meant for the value text, and so the value can wrap at the section's
  /// full width instead of the narrower width left over once [trailing]
  /// is subtracted from a shared row.
  final Widget? trailing;

  const _LabeledSection({
    required this.label,
    required this.value,
    this.onTap,
    this.onLongPress,
    this.longPressHint,
    this.itemNumberLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Sits directly on the scene background, not a card, so it needs
    // AppPalette.sceneText/sceneTextMuted explicitly — the theme's own
    // default textTheme color is resolved against cardFill instead, for
    // the common (card) case.
    final labelText = Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText);
    Widget valueText = itemNumberLabel == null
        ? Text(value, style: valueStyle)
        : DecidedItemsText(
            value: value,
            itemLabel: itemNumberLabel!,
            style: valueStyle,
            itemLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.sceneTextMuted,
              fontWeight: FontWeight.w700,
            ),
            dividerColor: AppPalette.sceneText.withValues(alpha: 0.28),
          );

    if (onTap != null || onLongPress != null) {
      valueText = Tooltip(
        message: longPressHint ?? '',
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque,
          child: valueText,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trailing == null)
          labelText
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: labelText),
              trailing!,
            ],
          ),
        const SizedBox(height: 4),
        valueText,
      ],
    );
  }
}

/// Edits one [ReflectionEntry]'s どうだった？ / 次の選択. Same StatefulWidget
/// controller-ownership pattern as [EditThemeDialog].
class _EditReflectionDialog extends StatefulWidget {
  final ReflectionEntry entry;
  final AppLanguage lang;

  const _EditReflectionDialog({required this.entry, required this.lang});

  @override
  State<_EditReflectionDialog> createState() => _EditReflectionDialogState();
}

class _EditReflectionDialogState extends State<_EditReflectionDialog> {
  static const _nextChoices = [
    '続ける',
    '方策を変更する',
    '新しいテーマに取り組む',
    '一旦休む',
    '完了',
  ];

  late final _controller = TextEditingController(text: widget.entry.howItWent);
  late String _nextChoice = _nextChoices.contains(widget.entry.nextChoice)
      ? widget.entry.nextChoice
      : _nextChoices.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final fieldTextStyle = Theme.of(context).textTheme.bodyLarge;

    return AlertDialog(
      scrollable: true,
      title: Text('振り返りを編集'.tr(lang)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('どうだった？'.tr(lang), style: fieldTextStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            style: fieldTextStyle,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '感じたこと、気づいたことを自由に書いてみましょう'.tr(lang),
            ),
          ),
          const SizedBox(height: 16),
          Text('次はどうする？'.tr(lang), style: fieldTextStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _nextChoice,
            items: [
              for (final choice in _nextChoices)
                DropdownMenuItem(
                  value: choice,
                  child: Text(choice.tr(lang)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _nextChoice = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル'.tr(lang)),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => TextButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    widget.entry.copyWith(
                      howItWent: value.text.trim(),
                      nextChoice: _nextChoice,
                    ),
                  ),
            child: Text('保存'.tr(lang)),
          ),
        ),
      ],
    );
  }
}
