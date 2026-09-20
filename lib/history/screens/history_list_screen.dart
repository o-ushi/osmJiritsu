import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../project_navigation.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../help/screens/jiritsu_about_screen.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/widgets/language_flag_button.dart';
import '../../models/project.dart';
import '../../models/project_status.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/app_dialog.dart';
import '../../theme/widgets/edit_field_dialogs.dart';
import '../../wizard/screens/swot_matrix_screen.dart';
import '../../wizard/screens/wizard_flow_screen.dart';
import '../../wizard/state/wizard_notifier.dart';
import '../history_toolbar_actions.dart';
import '../state/analysis_history_notifier.dart';
import '../state/start_screen_settings_notifier.dart';
import '../widgets/history_bottom_toolbar.dart';
import '../widgets/history_session_card.dart';
import 'usage_screen.dart';

/// osmJiritsu's home screen: 登録案件リスト — every saved 案件 (project),
/// in the user's own manually-reordered order, plus a fixed bottom toolbar
/// for the entry points that don't belong to any one row (start a new
/// project, export/import the whole list as JSON, settings, help).
class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(analysisHistoryProvider);
    final lang = ref.watch(appLanguageProvider);
    final actions = HistoryToolbarActions(ref, lang);
    final alwaysShowStartScreen = ref.watch(startScreenAlwaysShowProvider);
    final alwaysShowUsageScreen = ref.watch(usageScreenAlwaysShowProvider);
    final startScreenDismissed = ref.watch(startScreenDismissedProvider);
    final showingUsageScreen = ref.watch(usageScreenSessionShowProvider);

    // Same gate as osmGradus: the start screen is driven only by the
    // persisted「起動時にスタート画面を表示」flag (default on), not by an
    // empty project list — so「次回から表示しない」actually sticks.
    // 使い方 never shows on top of a still-showing スタート — see
    // `usageScreenSessionShowProvider`'s doc for why 使い方 is its own
    // session flag rather than derived from the persisted setting here.
    final showingStartScreen =
        alwaysShowStartScreen && !startScreenDismissed;
    final showingUsage = !showingStartScreen && showingUsageScreen;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: historyState.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AppPalette.mintDark),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '履歴の読み込みに失敗しました\n%@'.trFmt(lang, ['$error']),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.sceneTextMuted,
                ),
              ),
            ),
          ),
          data: (projects) {
            /// Landing on ホーム (list) with no projects yet goes straight
            /// into the new-project wizard instead of a blank list —
            /// shared by every path that can land on home (Step B's
            /// 「はじめる」when 使い方 is skipped, and 使い方's
            /// 「ホーム画面へ」below).
            void landOnHome() {
              if (projects.isEmpty) actions.startNew(context);
            }

            if (showingStartScreen) {
              // Layout/UX ported from osmGradus's StartupScreen: icon,
              // title, copy, 「次回から表示しない」, and「はじめる」.
              return _StartScreen(
                lang: lang,
                onContinue: (dontShowAgain) {
                  // 仕様 B: 保存の前に読む — `dontShowAgain` を確定して
                  // スタートを false にする setter は使い方も一緒に false
                  // へ揃える（不変条件）ので、この一手の行き先は保存前の
                  // 値で決める。
                  final showUsageNow = ref.read(
                    usageScreenAlwaysShowProvider,
                  );
                  if (dontShowAgain) {
                    ref
                        .read(startScreenAlwaysShowProvider.notifier)
                        .set(false);
                  }
                  ref.read(startScreenDismissedProvider.notifier).dismiss();
                  ref
                      .read(usageScreenSessionShowProvider.notifier)
                      .set(showUsageNow);
                  if (!showUsageNow) landOnHome();
                },
              );
            }
            if (showingUsage) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) > 200) {
                    // 使い方画面からの戻り: スタートへ。チェックの有無に
                    // 関わらずフラグは保存しない（「ホーム画面へ」を押して
                    // いないので dontShowAgain は確定しない）。
                    ref
                        .read(usageScreenSessionShowProvider.notifier)
                        .set(false);
                    ref.read(startScreenDismissedProvider.notifier).show();
                  }
                },
                child: UsageScreen(
                  lang: lang,
                  onContinue: (dontShowAgain) {
                    if (dontShowAgain) {
                      ref
                          .read(usageScreenAlwaysShowProvider.notifier)
                          .set(false);
                    }
                    ref
                        .read(usageScreenSessionShowProvider.notifier)
                        .set(false);
                    landOnHome();
                  },
                ),
              );
            }
            final list = _ProjectList(projects: projects, lang: lang);
            if (!alwaysShowStartScreen) return list;
            // 設定ON: 右スワイプでスタート画面（使い方もONなら使い方）に
            // 戻れるようにする。各行は削除用に endToStart (左) の
            // Dismissible なので、行の外（左右の余白・並べ替え矢印の列など）
            // から始まるスワイプで主に反応する — Dismissible が同じ横方向
            // ジェスチャーを行内で先取りするのは織り込み済みで、行の外
            // からのエッジスワイプが効けば十分という判断。
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 200) {
                  if (alwaysShowUsageScreen) {
                    ref
                        .read(usageScreenSessionShowProvider.notifier)
                        .set(true);
                  } else {
                    ref.read(startScreenDismissedProvider.notifier).show();
                  }
                }
              },
              child: list,
            );
          },
        ),
      ),
      // osmGradus's StartupScreen/UsageScreen are chrome-free; hide the
      // history toolbar while either is up so their own CTA owns the
      // bottom of the layout.
      bottomNavigationBar: (showingStartScreen || showingUsage)
          ? null
          : HistoryBottomToolbar(
              lang: lang,
              onExport: () => actions.export(context),
              onImport: () => actions.import(context),
              onAddNew: () => actions.startNew(context),
              onSettings: () => actions.openSettings(context),
              onHelp: () => actions.openHelp(context),
              guideMessageKey: '操作方法_ダッシュボード',
            ),
    );
  }
}

/// The project list itself, plus the per-row 並べ替え/edit/delete actions —
/// factored out of [HistoryListScreen] since these need [WidgetRef] beyond
/// just `build`'s scope (dialogs, provider mutations).
class _ProjectList extends ConsumerWidget {
  final List<Project> projects;
  final AppLanguage lang;

  const _ProjectList({required this.projects, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ReorderableProjectRow(
          key: ValueKey(project.id),
          index: index,
          project: project,
          lang: lang,
          onReorder: (fromIndex) => _move(ref, projects, fromIndex, index),
          onPlay: () => _openProject(context, ref, project),
          onEdit: () => _editTheme(context, ref, project, lang),
          onConfirmDelete: () => _confirmDelete(context, ref, project, lang),
          onToggleFavorite: () => _toggleFavorite(ref, project),
        );
      },
    );
  }

  /// ▶️'s destination depends on 現況: 作成中 means the project never
  /// finished the input wizard, so reopening it should resume that wizard
  /// (landing on the matrix screen if classification is already done,
  /// otherwise wherever `WizardState.fromProject` says input left off)
  /// rather than showing a dashboard for a project with nothing to
  /// dashboard yet. Anything past 作成中 opens the dashboard directly.
  void _openProject(BuildContext context, WidgetRef ref, Project project) {
    if (project.status != ProjectStatus.preparing) {
      Navigator.of(context).push(
        ProjectNavigation.dashboardRoute(
          DashboardScreen(project: project),
        ),
      );
      return;
    }

    ref.read(wizardProvider.notifier).resumeFrom(project);
    final resumed = ref.read(wizardProvider);
    // Always push the wizard first so a back swipe from the matrix lands on
    // the classification screen — not the start screen. Home on the flow
    // toolbar jumps straight to the project list.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WizardFlowScreen()),
    );
    if (resumed.isClassificationComplete) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SwotMatrixScreen()),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('作成中_ホームで一覧'.tr(lang))),
        );
      });
    }
  }

  void _move(
    WidgetRef ref,
    List<Project> projects,
    int fromIndex,
    int toIndex,
  ) {
    final reordered = [...projects];
    final moved = reordered.removeAt(fromIndex);
    reordered.insert(toIndex, moved);
    ref
        .read(analysisHistoryProvider.notifier)
        .reorder(reordered.map((p) => p.id).toList());
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

  /// Toggles ⭐️ without touching `updatedAt` — starring a project is a
  /// purely visual marker and shouldn't reshuffle a newest-first list or
  /// look like a real edit.
  Future<void> _toggleFavorite(WidgetRef ref, Project project) {
    return ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(project.copyWith(isFavorite: !project.isFavorite));
  }

  Future<bool> _confirmDelete(
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
    if (confirmed != true) return false;
    await ref.read(analysisHistoryProvider.notifier).delete(project.id);
    return true;
  }
}

/// One row: long-press anywhere on the card, drag it up or down over
/// another row, and release to swap places there — replaces the previous
/// ▲▼ tap-to-move pair with a direct drag gesture.
///
/// Built on [LongPressDraggable]/[DragTarget] rather than
/// `ReorderableListView`: that widget's internal `SliverReorderableList`
/// machinery, combined with this list's own dialogs (edit/delete) and
/// Riverpod-driven rebuilds, used to trigger a framework-level Focus
/// assertion crash ("Tried to build dirty widget in the wrong build
/// scope" / `_FocusInheritedScope`). `Draggable`/`DragTarget` don't share
/// that internal state, so this sidesteps the bug entirely rather than
/// working around it.
///
/// [index] doubles as the drag payload (which row is being picked up) and
/// this row's own position (where a drop lands) — [onReorder] is called
/// with the payload's original index once something is dropped here.
class _ReorderableProjectRow extends StatelessWidget {
  final int index;
  final Project project;
  final AppLanguage lang;
  final ValueChanged<int> onReorder;
  final VoidCallback onPlay;
  final VoidCallback onEdit;

  /// Shows the delete confirmation dialog and, if confirmed, deletes —
  /// shared as-is between the trash icon (fire-and-forget) and
  /// [Dismissible.confirmDismiss] (awaited, so a cancel snaps the tile
  /// back instead of leaving it swiped away).
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onToggleFavorite;

  const _ReorderableProjectRow({
    super.key,
    required this.index,
    required this.project,
    required this.lang,
    required this.onReorder,
    required this.onPlay,
    required this.onEdit,
    required this.onConfirmDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final card = Dismissible(
      key: ValueKey('dismissible-${project.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppPalette.coral.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppPalette.onAccent),
      ),
      confirmDismiss: (_) => onConfirmDelete(),
      child: HistorySessionCard(
        project: project,
        lang: lang,
        onPlay: onPlay,
        onEdit: onEdit,
        onDelete: () => onConfirmDelete(),
        onToggleFavorite: onToggleFavorite,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowWidth = constraints.maxWidth;
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) => onReorder(details.data),
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDropTarget
                      ? AppPalette.mintDark
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: LongPressDraggable<int>(
                data: index,
                axis: Axis.vertical,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: rowWidth,
                    child: Transform.scale(
                      scale: 1.03,
                      child: HistorySessionCard(
                        project: project,
                        lang: lang,
                        onPlay: () {},
                        onEdit: () {},
                        onDelete: () {},
                        onToggleFavorite: () {},
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: card),
                child: card,
              ),
            );
          },
        );
      },
    );
  }
}

/// スタート画面 — layout/metrics ported from osmGradus's `StartupScreen`
/// (icon 140×140 / radius 28 / same vertical rhythm). Shown at launch when
/// 「起動時にスタート画面を表示」is on. [onContinue] receives the
/// 「次回から表示しない」checkbox.
class _StartScreen extends StatefulWidget {
  final AppLanguage lang;
  final ValueChanged<bool> onContinue;
  const _StartScreen({required this.lang, required this.onContinue});

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    // Structure mirrors osmGradus `StartupScreen` exactly: language flag
    // top-right, then a vertically-centered scroll column.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: LanguageFlagButton(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const JiritsuAboutScreen(),
                              ),
                            );
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Keep the title on one line regardless of system
                        // text scaling — same FittedBox trick as Gradus.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'osmJiritsu',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppPalette.sceneText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。'
                              .tr(lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            color: AppPalette.sceneTextMuted,
                          ),
                        ),
                        const SizedBox(height: 36),
                        InkWell(
                          onTap: () => setState(
                            () => _dontShowAgain = !_dontShowAgain,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _dontShowAgain,
                                    onChanged: (value) {
                                      setState(
                                        () =>
                                            _dontShowAgain = value ?? false,
                                      );
                                    },
                                    side: const BorderSide(
                                      color: AppPalette.sceneText,
                                      width: 1.5,
                                    ),
                                    fillColor:
                                        WidgetStateProperty.resolveWith((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return AppPalette.mintDark;
                                      }
                                      return Colors.transparent;
                                    }),
                                    checkColor: AppPalette.onAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    '次回から表示しない'.tr(lang),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppPalette.sceneText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () =>
                                widget.onContinue(_dontShowAgain),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.mintDark,
                              foregroundColor: AppPalette.onAccent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'はじめる'.tr(lang),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
