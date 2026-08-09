import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/project_navigation.dart';
import '../../history/state/analysis_history_notifier.dart';
import '../../history/widgets/flow_scaffold.dart';
import '../../history/widgets/history_bottom_toolbar.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../models/swot_category.dart';
import '../../models/swot_item.dart';
import '../../strategy/screens/strategy_flow_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/subpage_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/app_dialog.dart';
import '../../theme/widgets/edit_field_dialogs.dart';
import '../models/wizard_idea.dart';
import '../state/wizard_notifier.dart';
import '../widgets/primary_cta_button.dart';

/// Step 3: the finished SWOT matrix, editable by dragging a card from one
/// quadrant into another.
///
/// Reached once every idea has been classified. Every quadrant is a
/// [DragTarget] and every card a [LongPressDraggable]; dropping a card on a
/// different quadrant calls `WizardNotifier.moveIdeaToCategory`, which
/// updates the single Riverpod [wizardProvider] state — the same state
/// `WizardState.toSwotMatrix()` will later hand to the analysis engine, so
/// a move here is immediately reflected in whatever reads the matrix next.
///
/// Step 5: reaching this screen means classification is complete, so it's
/// the natural point to persist the analysis to history for the first
/// time (see [initState]) — and every drag-drop edit re-saves the same
/// record (matched by `WizardState.sessionId`) so history never lags
/// behind what's on screen.
class SwotMatrixScreen extends ConsumerStatefulWidget {
  const SwotMatrixScreen({super.key, this.fromProjectDashboard = false});

  /// When true, uses the project dashboard toolbar (share / return / …)
  /// instead of the wizard flow toolbar.
  final bool fromProjectDashboard;

  @override
  ConsumerState<SwotMatrixScreen> createState() => _SwotMatrixScreenState();
}

class _SwotMatrixScreenState extends ConsumerState<SwotMatrixScreen> {
  bool _dragAccepted = false;
  String? _draggingId;
  final _undoStack = <List<WizardIdea>>[];

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  List<WizardIdea> _snapshotIdeas(List<WizardIdea> ideas) => [
    for (final idea in ideas)
      WizardIdea(
        id: idea.id,
        text: idea.text,
        evaluation: idea.evaluation,
        locus: idea.locus,
      ),
  ];

  void _recordUndoPoint() {
    final ideas = ref.read(wizardProvider).ideas;
    _undoStack.add(_snapshotIdeas(ideas));
  }

  void _mutate(void Function() action) {
    _recordUndoPoint();
    action();
    _saveToHistory();
    setState(() {});
  }

  void _undoLastAction() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    ref.read(wizardProvider.notifier).restoreIdeas(previous);
    _saveToHistory();
    setState(() {});
  }

  void _saveToHistory() {
    final wizard = ref.read(wizardProvider);
    final draft = wizard.toProject();
    final history = ref.read(analysisHistoryProvider).value ?? const [];
    Project? existing;
    for (final project in history) {
      if (project.id == draft.id) {
        existing = project;
        break;
      }
    }
    final project = existing != null
        ? wizard.toProjectPreserving(existing)
        : draft;
    ref.read(analysisHistoryProvider.notifier).saveOrUpdate(project);
  }

  void _onDragStarted(String ideaId) {
    setState(() {
      _dragAccepted = false;
      _draggingId = ideaId;
    });
  }

  void _onDragAccepted() {
    _dragAccepted = true;
  }

  void _onDragEnded(String ideaId) {
    if (_draggingId != ideaId) return;
    if (!_dragAccepted) {
      _mutate(() => ref.read(wizardProvider.notifier).removeIdea(ideaId));
    }
    setState(() {
      _draggingId = null;
      _dragAccepted = false;
    });
  }

  Future<void> _addItem(BuildContext context) async {
    final lang = ref.read(appLanguageProvider);
    final text = await showAppAlertDialog<String>(
      context: context,
      builder: (context) => _AddIdeaDialog(lang: lang),
    );
    if (text == null || !context.mounted) return;

    final category = await showReadableBottomSheet<SwotCategory>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PickQuadrantSheet(lang: lang),
    );
    if (category == null) return;

    _mutate(
      () => ref.read(wizardProvider.notifier).addClassifiedIdea(text, category),
    );
  }

  Future<void> _editItem(BuildContext context, SwotItem item) async {
    final lang = ref.read(appLanguageProvider);
    final updated = await showAppAlertDialog<String>(
      context: context,
      builder: (context) => _EditIdeaDialog(content: item.content, lang: lang),
    );
    if (updated == null || updated == item.content) return;
    _mutate(
      () => ref.read(wizardProvider.notifier).updateIdeaText(item.id, updated),
    );
  }

  Future<void> _editGoals(
    BuildContext context, {
    required String desiredGoal,
    required String undesiredGoal,
  }) async {
    final lang = ref.read(appLanguageProvider);
    final updated = await showAppAlertDialog<GoalPair>(
      context: context,
      builder: (context) => EditGoalsDialog(
        desiredGoal: desiredGoal,
        undesiredGoal: undesiredGoal,
        lang: lang,
      ),
    );
    if (updated == null) return;
    if (
      updated.desiredGoal == desiredGoal &&
      updated.undesiredGoal == undesiredGoal
    ) {
      return;
    }
    _mutate(() {
      final notifier = ref.read(wizardProvider.notifier);
      notifier.setDesiredGoal(updated.desiredGoal);
      notifier.setUndesiredGoal(updated.undesiredGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matrix = ref.watch(wizardProvider.select((s) => s.toSwotMatrix()));
    final notifier = ref.read(wizardProvider.notifier);
    final lang = ref.watch(appLanguageProvider);
    final goal = ref.watch(wizardProvider.select((s) => s.desiredGoal));
    final undesiredGoal = ref.watch(
      wizardProvider.select((s) => s.undesiredGoal),
    );

    void onDropped(String ideaId, SwotCategory category) {
      _onDragAccepted();
      _mutate(() => notifier.moveIdeaToCategory(ideaId, category));
    }

    final appBar = OsmAppBar(
      centerTitle: false,
      title: _GoalAppBarTitle(
        goal: goal,
        undesiredGoal: undesiredGoal,
        lang: lang,
        onLongPress: () => _editGoals(
          context,
          desiredGoal: goal,
          undesiredGoal: undesiredGoal,
        ),
      ),
    );
    final body = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuadrantPanel(
                            category: SwotCategory.strength,
                            label: '強み'.tr(lang),
                            icon: Icons.bolt_rounded,
                            color: AppPalette.strength,
                            items: matrix.strengths,
                            lang: lang,
                            onDropped: onDropped,
                            onEdit: (item) => _editItem(context, item),
                            onDragStarted: _onDragStarted,
                            onDragEnded: _onDragEnded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuadrantPanel(
                            category: SwotCategory.opportunity,
                            label: '機会'.tr(lang),
                            icon: Icons.trending_up_rounded,
                            color: AppPalette.opportunity,
                            items: matrix.opportunities,
                            lang: lang,
                            onDropped: onDropped,
                            onEdit: (item) => _editItem(context, item),
                            onDragStarted: _onDragStarted,
                            onDragEnded: _onDragEnded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuadrantPanel(
                            category: SwotCategory.weakness,
                            label: '弱み'.tr(lang),
                            icon: Icons.shield_outlined,
                            color: AppPalette.weakness,
                            items: matrix.weaknesses,
                            lang: lang,
                            onDropped: onDropped,
                            onEdit: (item) => _editItem(context, item),
                            onDragStarted: _onDragStarted,
                            onDragEnded: _onDragEnded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuadrantPanel(
                            category: SwotCategory.threat,
                            label: '脅威'.tr(lang),
                            icon: Icons.warning_amber_rounded,
                            color: AppPalette.threat,
                            items: matrix.threats,
                            lang: lang,
                            onDropped: onDropped,
                            onEdit: (item) => _editItem(context, item),
                            onDragStarted: _onDragStarted,
                            onDragEnded: _onDragEnded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryCtaButton(
              label: 'AIに方策を相談する'.tr(lang),
              icon: Icons.auto_awesome_rounded,
              onPressed: () {
                final wizard = ref.read(wizardProvider);
                final strategyScreen = StrategyFlowScreen(
                  fromProjectDashboard: widget.fromProjectDashboard,
                  // Reuse saved suggestions when present — same as dashboard
                  // 「見直す」— instead of forcing another Chrome round trip.
                  startFromCachedSuggestions:
                      wizard.aiStrategySuggestions.isNotEmpty,
                );
                Navigator.of(context).push(
                  widget.fromProjectDashboard
                      ? ProjectNavigation.childRoute(strategyScreen)
                      : MaterialPageRoute(builder: (_) => strategyScreen),
                );
              },
            ),
          ],
        ),
      ),
    );

    final projectId = ref.read(wizardProvider).sessionId;
    final scaffold = widget.fromProjectDashboard
        ? ProjectScaffold(
            projectId: projectId,
            mode: ProjectToolbarMode.child,
            appBar: appBar,
            body: body,
            guideMessageKey: '操作方法_SWOT',
          )
        : FlowScaffold(
            toolbarMode: HistoryToolbarMode.matrix,
            onToolbarAdd: () => _addItem(context),
            onToolbarUndo: _undoLastAction,
            canUndo: _undoStack.isNotEmpty,
            appBar: appBar,
            body: body,
            guideMessageKey: '操作方法_SWOT',
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: scaffold,
    );
  }
}

class _QuadrantPanel extends StatelessWidget {
  final SwotCategory category;
  final String label;
  final IconData icon;
  final Color color;
  final List<SwotItem> items;
  final AppLanguage lang;
  final void Function(String ideaId, SwotCategory category) onDropped;
  final void Function(SwotItem item) onEdit;
  final void Function(String ideaId) onDragStarted;
  final void Function(String ideaId) onDragEnded;

  const _QuadrantPanel({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.lang,
    required this.onDropped,
    required this.onEdit,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDropped(details.data, category),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final quadrantFillAlpha = isHovering ? 0.22 : 0.10;
        // This panel's actual painted background — the translucent
        // `color` above whatever sits behind it (AppPalette.scene, via
        // ProjectScaffold/FlowScaffold) — not `color` itself. Text drawn
        // on this panel needs contrast checked against *this*, since
        // AppPalette.scene can be dark enough that a merely-translucent
        // version of `color` (a fixed SWOT-quadrant identity color)
        // blends into it instead of standing out.
        final quadrantBackground = Color.alphaBlend(
          color.withValues(alpha: quadrantFillAlpha),
          AppPalette.scene,
        );
        return AnimatedContainer(
          key: ValueKey('quadrant-${category.rawValue}'),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: color.withValues(alpha: quadrantFillAlpha),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: isHovering ? 0.9 : 0.3),
              width: isHovering ? 3 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuadrantHeader(
                label: label,
                icon: icon,
                color: color,
                count: items.length,
                background: quadrantBackground,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          (isHovering ? 'ここに置く' : 'なし').tr(lang),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                // Fully opaque `color`, not a translucent
                                // version of it, as the *candidate* passed
                                // to ensureReadable: Color.r/.g/.b (which
                                // contrastRatio's luminance math reads)
                                // ignore alpha entirely, so checking
                                // contrast on a translucent color checks
                                // its *un-blended* RGB, not what it
                                // actually looks like once painted over
                                // quadrantBackground — that mismatch is
                                // exactly why "なし" stayed unreadable even
                                // after this contrast check was added.
                                //
                                // minContrast 4.5 (WCAG AA for normal-size
                                // text), not 3.0 — this text is small body
                                // text, not a large/bold label, and 3.0 let
                                // combinations like amber-on-navy through
                                // at ~3.46:1, which still reads as "melting
                                // into the background" at this size even
                                // though it numerically passed.
                                color: AppPalette.ensureReadableOn(
                                  background: quadrantBackground,
                                  preferred: color,
                                  minContrast: 4.5,
                                ),
                              ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) => _DraggableItemCard(
                          item: items[index],
                          color: color,
                          onTap: () => onEdit(items[index]),
                          onDragStarted: () => onDragStarted(items[index].id),
                          onDragEnded: () => onDragEnded(items[index].id),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalAppBarTitle extends StatelessWidget {
  final String goal;
  final String undesiredGoal;
  final AppLanguage lang;
  final VoidCallback onLongPress;

  const _GoalAppBarTitle({
    required this.goal,
    required this.undesiredGoal,
    required this.lang,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final desiredText = goal.trim().isEmpty ? '在りたい姿'.tr(lang) : goal;
    final undesiredText = undesiredGoal.trim().isEmpty
        ? '在りたくない姿'.tr(lang)
        : undesiredGoal;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'在りたい姿'.tr(lang)}；$desiredText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.sceneText,
            ),
          ),
          Text(
            '${'在りたくない姿'.tr(lang)}；$undesiredText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.sceneTextMuted),
          ),
        ],
      ),
    );
  }
}

class _QuadrantHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  /// This header's actual panel background — see `_QuadrantPanel.build`'s
  /// `quadrantBackground` — so [label]'s color can be contrast-checked
  /// against what it really sits on, not just [color] itself.
  final Color background;

  const _QuadrantHeader({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
              // Fully opaque `color` — see the matching comment in
              // _QuadrantPanel.build for why a translucent candidate here
              // would silently defeat this contrast check.
              color: AppPalette.ensureReadableOn(
                background: background,
                preferred: color,
                minContrast: 4.5,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppPalette.cardFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _DraggableItemCard extends StatelessWidget {
  final SwotItem item;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const _DraggableItemCard({
    required this.item,
    required this.color,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: item.id,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded(),
      feedback: _ItemCardChrome(
        color: color,
        elevated: true,
        width: 150,
        child: _ItemCardContent(text: item.content, showHandle: false),
      ),
      childWhenDragging: _ItemCardChrome(
        color: color,
        faded: true,
        child: _ItemCardContent(text: item.content, showHandle: false),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _ItemCardChrome(
          color: color,
          child: _ItemCardContent(text: item.content, showHandle: true),
        ),
      ),
    );
  }
}

class _ItemCardChrome extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool elevated;
  final bool faded;
  final double? width;

  const _ItemCardChrome({
    required this.child,
    required this.color,
    this.elevated = false,
    this.faded = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: faded
            ? AppPalette.cardFill.withValues(alpha: 0.4)
            : AppPalette.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: faded ? Border.all(color: color.withValues(alpha: 0.4)) : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (elevated) {
      return Material(color: Colors.transparent, child: card);
    }
    return card;
  }
}

class _ItemCardContent extends StatelessWidget {
  final String text;
  final bool showHandle;

  const _ItemCardContent({required this.text, required this.showHandle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12.5,
              color: AppPalette.ink,
            ),
          ),
        ),
        if (showHandle) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.drag_indicator_rounded,
            size: 16,
            color: Color(0xFFB8C7C1),
          ),
        ],
      ],
    );
  }
}

class _AddIdeaDialog extends StatefulWidget {
  final AppLanguage lang;

  const _AddIdeaDialog({required this.lang});

  @override
  State<_AddIdeaDialog> createState() => _AddIdeaDialogState();
}

class _AddIdeaDialogState extends State<_AddIdeaDialog> {
  late final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('項目を追加'.tr(widget.lang)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: '思いついたことを入力…'.tr(widget.lang),
        ),
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル'.tr(widget.lang)),
        ),
        TextButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isEmpty) return;
            Navigator.of(context).pop(trimmed);
          },
          child: Text('追加'.tr(widget.lang)),
        ),
      ],
    );
  }
}

class _PickQuadrantSheet extends StatelessWidget {
  final AppLanguage lang;

  const _PickQuadrantSheet({required this.lang});

  static const _options = [
    (SwotCategory.strength, '強み', Icons.bolt_rounded, AppPalette.strength),
    (
      SwotCategory.opportunity,
      '機会',
      Icons.trending_up_rounded,
      AppPalette.opportunity,
    ),
    (SwotCategory.weakness, '弱み', Icons.shield_outlined, AppPalette.weakness),
    (
      SwotCategory.threat,
      '脅威',
      Icons.warning_amber_rounded,
      AppPalette.threat,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'どの枠に入れますか？'.tr(lang),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          for (final (category, labelKey, icon, color) in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.35)),
                ),
                tileColor: color.withValues(alpha: 0.12),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                title: Text(labelKey.tr(lang)),
                onTap: () => Navigator.of(context).pop(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditIdeaDialog extends StatefulWidget {
  final String content;
  final AppLanguage lang;

  const _EditIdeaDialog({required this.content, required this.lang});

  @override
  State<_EditIdeaDialog> createState() => _EditIdeaDialogState();
}

class _EditIdeaDialogState extends State<_EditIdeaDialog> {
  late final _controller = TextEditingController(text: widget.content);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('内容を編集'.tr(widget.lang)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル'.tr(widget.lang)),
        ),
        TextButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isEmpty) return;
            Navigator.of(context).pop(trimmed);
          },
          child: Text('保存'.tr(widget.lang)),
        ),
      ],
    );
  }
}
