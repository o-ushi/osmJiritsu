import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/state/analysis_history_notifier.dart';
import '../../history/widgets/flow_scaffold.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../models/project_status.dart';
import '../../models/simple_line.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/app_dialog.dart';

/// 簡易モード — ゴール / 現状 / 方策 / 最初の一歩 の4枠だけの画面。
///
/// The full wizard ([WizardFlowScreen]) stays exactly as it was; this is a
/// second entry flow onto the same [Project], marked by
/// [Project.modeSimple]. Nothing here writes the wizard's fields (SWOT,
/// `decidedStrategy`, 宣言文) — see 06-simple-mode.md's 検討メモ.
///
/// The four boxes are laid out as a *board*, not a form: ゴール top-right,
/// 方策 in the middle, 現状 bottom-left, and 最初の一歩 spanning the full
/// width underneath. The relative arrangement is the point — it puts the
/// gap between「いま」and「なりたい」on screen — so it is preserved even
/// when the keyboard squeezes the board (it scrolls rather than reflowing
/// into a single column).
class SimpleModeScreen extends ConsumerStatefulWidget {
  const SimpleModeScreen({super.key, required this.project});

  final Project project;

  /// Widget keys — the board is positioned by ratio rather than by widget
  /// order, so tests (and anything else reaching in) need a stable handle
  /// on each box instead of「the first TextField」.
  static const goalCardKey = Key('simple-goal-card');
  static const goalFieldKey = Key('simple-goal-field');
  static const goalCheckKey = Key('simple-goal-check');
  static const situationCardKey = Key('simple-situation-card');
  static const strategyCardKey = Key('simple-strategy-card');
  static const firstStepCardKey = Key('simple-first-step-card');
  static const firstStepFieldKey = Key('simple-first-step-field');
  static const firstStepCheckKey = Key('simple-first-step-check');
  static const situationAddKey = Key('simple-situation-add');
  static const strategyAddKey = Key('simple-strategy-add');

  static Key situationFieldKey(int index) => Key('simple-situation-$index');
  static Key strategyFieldKey(int index) => Key('simple-strategy-$index');
  static Key strategyCheckKey(int index) =>
      Key('simple-strategy-check-$index');
  static Key situationHandleKey(int index) =>
      Key('simple-situation-handle-$index');
  static Key strategyHandleKey(int index) =>
      Key('simple-strategy-handle-$index');

  @override
  ConsumerState<SimpleModeScreen> createState() => _SimpleModeScreenState();
}

/// One editable row: the persisted [SimpleLine] plus the controller the
/// [TextField] for it is driving. Keeping [line]'s id alongside the
/// controller is what lets a re-save reuse the same ids instead of
/// re-generating them on every keystroke.
class _EditableLine {
  _EditableLine(this.line, {VoidCallback? onCommit})
    : controller = TextEditingController(text: line.text),
      focusNode = FocusNode() {
    if (onCommit != null) {
      // 文字の確定 = losing focus. Saving per keystroke would rewrite the
      // whole 案件 on every character; saving on commit gives the same
      // result without the churn.
      focusNode.addListener(() {
        if (!focusNode.hasFocus) onCommit();
      });
    }
  }

  SimpleLine line;
  final TextEditingController controller;
  final FocusNode focusNode;

  bool get isBlank => controller.text.trim().isEmpty;

  /// The row as it should be persisted: the live controller text, trimmed,
  /// under the original id.
  SimpleLine get persisted =>
      SimpleLine(id: line.id, text: controller.text.trim(), done: line.done);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _SimpleModeScreenState extends ConsumerState<SimpleModeScreen> {
  /// Board metrics from 06-simple-mode.md's レイアウト正本. Positions and
  /// sizes are fractions of the board, so the arrangement survives every
  /// screen size; the literals live here rather than inline so the table in
  /// that doc and this code can be diffed against each other.
  static const _goalTopRatio = 0.02;
  static const _goalWidthRatio = 0.58;
  static const _goalHeightRatio = 0.28;
  static const _strategyTopRatio = 0.32;
  static const _strategyLeftRatio = 0.16;
  static const _strategyWidthRatio = 0.72;
  static const _strategyHeightRatio = 0.32;
  static const _situationWidthRatio = 0.46;
  static const _situationHeightRatio = 0.30;

  /// Floor for the board's height. Below this the cards' own contents stop
  /// fitting, so the board keeps this height and scrolls instead — which is
  /// what happens while the keyboard is up on a short screen.
  static const _minBoardHeight = 440.0;

  static const _firstStepHeight = 96.0;
  static const _labelFontSize = 11.0;

  /// チェック済み — one flat grey for both 方策 rows and the 最初の一歩 card,
  /// no strikethrough: a ticked line is still something you want to be able
  /// to read back.
  static const _doneFill = Color(0xFFE4E4EA);
  static const _doneBorder = Color(0xFFD5D5DC);

  late final TextEditingController _goalController;
  late final FocusNode _goalFocusNode;
  late List<_EditableLine> _situations;
  late List<_EditableLine> _strategies;
  late _EditableLine _firstStep;
  // Not `late`: a trivially-defaultable bool doesn't need the crash-if-
  // unset guarantee `late` buys the other fields, and this default is what
  // a hot-reloaded State instance predating this field falls back to
  // instead of throwing LateInitializationError.
  bool _goalDone = false;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _goalController = TextEditingController(text: project.desiredGoal);
    _goalFocusNode = FocusNode()
      ..addListener(() {
        if (!_goalFocusNode.hasFocus) _save();
      });
    _goalDone = project.simpleGoalDone;
    _situations = project.simpleSituations.map(_newLine).toList();
    _strategies = project.simpleStrategies.map(_newLine).toList();
    _firstStep = _newLine(project.simpleFirstStep);
  }

  _EditableLine _newLine(SimpleLine line) =>
      _EditableLine(line, onCommit: _save);

  @override
  void dispose() {
    _goalController.dispose();
    _goalFocusNode.dispose();
    for (final line in [..._situations, ..._strategies, _firstStep]) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine(List<_EditableLine> lines) {
    if (lines.length >= Project.simpleLineLimit) return;
    setState(() => lines.add(_newLine(SimpleLine())));
    _save();
  }

  Future<void> _confirmRemoveLine(
    List<_EditableLine> lines,
    int index,
    AppLanguage lang,
  ) async {
    final confirmed = await showAppAlertDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('この行を削除しますか？'.tr(lang)),
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
    if (confirmed != true || !mounted) return;
    // Guard the index: the dialog was awaited, so the list could in
    // principle have changed underneath it.
    if (index >= lines.length) return;
    setState(() => lines.removeAt(index).dispose());
    await _save();
  }

  void _toggleDone(_EditableLine line, bool done) {
    setState(() => line.line = line.line.copyWith(done: done));
    _save();
  }

  void _toggleGoalDone(bool done) {
    setState(() => _goalDone = done);
    _save();
  }

  // ── Persistence ─────────────────────────────────────────────────────

  /// True when nothing has actually been written on the board. A ticked but
  /// empty row counts as nothing — the checkbox alone isn't content, so it
  /// can't be what keeps an otherwise-blank 案件 in the list.
  bool get _isBlank =>
      _goalController.text.trim().isEmpty &&
      _situations.every((line) => line.isBlank) &&
      _strategies.every((line) => line.isBlank) &&
      _firstStep.isBlank;

  /// Serializes saves. Tapping a checkbox while a field is focused fires
  /// two of them in the same frame (the unfocus, then the toggle); running
  /// them concurrently could land the earlier snapshot last. Chaining also
  /// means [_persist] always reads the board as it is when it actually
  /// runs, so the final write is the final state either way.
  Future<void> _pendingSave = Future<void>.value();

  Future<void> _save() {
    _pendingSave = _pendingSave
        .then((_) => _persist())
        // One failed write must not wedge the chain for the rest of the
        // session.
        .catchError((_) {});
    return _pendingSave;
  }

  /// Upserts the board into 案件一覧 — or, when the board has been emptied,
  /// removes the 案件 instead of leaving a blank row behind. A brand-new
  /// blank board is simply never written.
  Future<void> _persist() async {
    // A focus listener can fire while the route is being torn down; the
    // ホーム path has already flushed by then, so there's nothing to lose
    // by skipping.
    if (!mounted) return;
    final notifier = ref.read(analysisHistoryProvider.notifier);
    if (_isBlank) {
      final history = await ref.read(analysisHistoryProvider.future);
      if (history.any((p) => p.id == widget.project.id)) {
        await notifier.delete(widget.project.id);
      }
      return;
    }
    await notifier.saveOrUpdate(_toProject());
  }

  /// [widget.project] is the base, so every full-mode field (SWOT, 方策,
  /// 宣言文, 備考, 期限, ⭐️, 振り返り) is carried through untouched — this
  /// screen only ever owns the four boxes plus the fields derived from them.
  Project _toProject() {
    final goal = _goalController.text.trim();
    return widget.project.copyWith(
      // ゴール doubles as the list row's heading, which reads `theme` —
      // rather than inventing a separate title field, 簡易モード writes the
      // one sentence it has into both.
      theme: goal,
      desiredGoal: goal,
      entryMode: Project.modeSimple,
      simpleGoalDone: _goalDone,
      simpleSituations: _persistedLines(_situations),
      simpleStrategies: _persistedLines(_strategies),
      // Kept even when blank: the box always exists, and its checkbox may
      // be the only thing set on it.
      simpleFirstStep: _firstStep.persisted,
      // ゴールのチェックは「完了」の宣言そのものなので 現況 にも反映する —
      // 進捗率が100%なのに 実施中 のままでは辻褄が合わない。休憩中はこの画面
      // からは設定しない（チェックの有無だけでは一時停止の意思は判断できない）。
      status: _goalDone
          ? ProjectStatus.completed
          : (goal.isEmpty
                ? ProjectStatus.preparing
                : ProjectStatus.inProgress),
      updatedAt: DateTime.now(),
    );
  }

  static List<SimpleLine> _persistedLines(List<_EditableLine> lines) => lines
      .where((line) => !line.isBlank)
      .take(Project.simpleLineLimit)
      .map((line) => line.persisted)
      .toList();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return FlowScaffold(
      // The wizard draft is a different document entirely — persisting it
      // from here would let a 簡易 案件's ホーム tap resurrect an unrelated
      // half-finished wizard session. This screen's own edits are flushed
      // by [onBeforeHome] instead.
      persistWizardOnHome: false,
      onBeforeHome: _save,
      body: Container(
        color: AppPalette.scene,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardHeight = math.max(
                      constraints.maxHeight,
                      _minBoardHeight,
                    );
                    final board = SizedBox(
                      height: boardHeight,
                      child: _buildBoard(
                        lang: lang,
                        width: constraints.maxWidth,
                        height: boardHeight,
                      ),
                    );
                    // Only scrolls when the board can't fit — the relative
                    // positions inside it never change.
                    return SingleChildScrollView(child: board);
                  },
                ),
              ),
              _buildFirstStep(lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoard({
    required AppLanguage lang,
    required double width,
    required double height,
  }) {
    return Stack(
      children: [
        // ゴール — top-right, the biggest type on the board.
        Positioned(
          top: height * _goalTopRatio,
          right: 16,
          width: width * _goalWidthRatio,
          height: height * _goalHeightRatio,
          child: _buildGoalCard(lang),
        ),
        // 方策 — between ゴール and 現状, which is the whole point of its
        // position: it's what closes the gap between the two.
        Positioned(
          top: height * _strategyTopRatio,
          left: width * _strategyLeftRatio,
          width: width * _strategyWidthRatio,
          height: height * _strategyHeightRatio,
          child: _buildStrategyCard(lang),
        ),
        // 現状 — bottom-left, deliberately the quietest box.
        Positioned(
          left: 16,
          bottom: 8,
          width: width * _situationWidthRatio,
          height: height * _situationHeightRatio,
          child: _buildSituationCard(lang),
        ),
      ],
    );
  }

  Widget _buildGoalCard(AppLanguage lang) {
    final fill = _goalDone ? _doneFill : AppPalette.amber;
    final textColor = _goalDone
        ? AppPalette.inkMuted
        : AppPalette.primaryTextOn(AppPalette.amber);
    return _BoardCard(
      key: SimpleModeScreen.goalCardKey,
      fill: fill,
      border: _goalDone ? _doneBorder : fill,
      label: 'ゴール'.tr(lang),
      labelColor: textColor.withValues(alpha: 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _LineField(
              fieldKey: SimpleModeScreen.goalFieldKey,
              controller: _goalController,
              focusNode: _goalFocusNode,
              hint: 'ゴール'.tr(lang),
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          _RowCheckbox(
            checkboxKey: SimpleModeScreen.goalCheckKey,
            value: _goalDone,
            activeColor: AppPalette.inkMuted,
            borderColor: textColor,
            onChanged: _toggleGoalDone,
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(AppLanguage lang) {
    return _BoardCard(
      key: SimpleModeScreen.strategyCardKey,
      fill: AppPalette.cardFill,
      border: AppPalette.cardAccent,
      label: '方策'.tr(lang),
      labelColor: AppPalette.inkMuted,
      child: _LineList(
        lines: _strategies,
        addKey: SimpleModeScreen.strategyAddKey,
        addLabelColor: AppPalette.cardAccent,
        lang: lang,
        onAdd: () => _addLine(_strategies),
        onRemove: (index) => _confirmRemoveLine(_strategies, index, lang),
        fieldKeyFor: SimpleModeScreen.strategyFieldKey,
        handleKeyFor: SimpleModeScreen.strategyHandleKey,
        rowBuilder: (index, line, field, handle) => _CheckableRow(
          checkboxKey: SimpleModeScreen.strategyCheckKey(index),
          done: line.line.done,
          onChanged: (value) => _toggleDone(line, value),
          fill: line.line.done ? _doneFill : Colors.transparent,
          border: line.line.done ? _doneBorder : Colors.transparent,
          handle: handle,
          child: field,
        ),
        fontSize: 16,
        colorFor: (line) => line.line.done ? AppPalette.inkMuted : AppPalette.ink,
      ),
    );
  }

  Widget _buildSituationCard(AppLanguage lang) {
    return _BoardCard(
      key: SimpleModeScreen.situationCardKey,
      fill: AppPalette.cardFill,
      border: AppPalette.cardBorder,
      label: '現状'.tr(lang),
      labelColor: AppPalette.inkMuted,
      child: _LineList(
        lines: _situations,
        addKey: SimpleModeScreen.situationAddKey,
        addLabelColor: AppPalette.inkMuted,
        lang: lang,
        onAdd: () => _addLine(_situations),
        onRemove: (index) => _confirmRemoveLine(_situations, index, lang),
        fieldKeyFor: SimpleModeScreen.situationFieldKey,
        handleKeyFor: SimpleModeScreen.situationHandleKey,
        // No checkbox here: 現状 is what *is*, so there's nothing to tick
        // off. Rows keep their `done` flag in JSON but never show it.
        rowBuilder: (index, line, field, handle) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [handle, Expanded(child: field)],
        ),
        fontSize: 14,
        // Muted regardless of any checkbox state — 現状 stays quieter than
        // ゴール on purpose.
        colorFor: (_) => AppPalette.inkMuted,
      ),
    );
  }

  Widget _buildFirstStep(AppLanguage lang) {
    final done = _firstStep.line.done;
    final fill = done ? _doneFill : AppPalette.mint;
    final textColor = done ? AppPalette.inkMuted : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        height: _firstStepHeight,
        child: _BoardCard(
          key: SimpleModeScreen.firstStepCardKey,
          fill: fill,
          border: done ? _doneBorder : fill,
          label: '最初の一歩'.tr(lang),
          labelColor: textColor.withValues(alpha: 0.85),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LineField(
                  fieldKey: SimpleModeScreen.firstStepFieldKey,
                  controller: _firstStep.controller,
                  focusNode: _firstStep.focusNode,
                  hint: '最初の一歩'.tr(lang),
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              _RowCheckbox(
                checkboxKey: SimpleModeScreen.firstStepCheckKey,
                value: done,
                activeColor: AppPalette.inkMuted,
                borderColor: textColor,
                onChanged: (value) => _toggleDone(_firstStep, value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One box on the board: a rounded fill, a small corner label, and whatever
/// the box holds. The label sits in the corner rather than above the content
/// so ゴール / 最初の一歩 can keep their body text as the主役.
class _BoardCard extends StatelessWidget {
  const _BoardCard({
    super.key,
    required this.fill,
    required this.border,
    required this.label,
    required this.labelColor,
    required this.child,
  });

  final Color fill;
  final Color border;
  final String label;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: _SimpleModeScreenState._labelFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// A borderless multi-line [TextField] that inherits the box's own fill —
/// the app-wide [InputDecorationTheme] paints a filled, 20px-padded pill,
/// which would draw a second card inside every box here.
class _LineField extends StatelessWidget {
  const _LineField({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.fontSize,
    required this.color,
    this.focusNode,
    this.fontWeight,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final double fontSize;
  final Color color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      maxLines: null,
      cursorColor: color,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.25,
        color: color,
      ),
      decoration: InputDecoration(
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

/// The 現状 / 方策 box contents: every row it already holds, then a「＋」
/// while it's still under [Project.simpleLineLimit]. The ＋ disappears at
/// the limit — that's what stops a fourth row existing at all, rather than
/// letting one be added and then rejected on save.
class _LineList extends StatelessWidget {
  const _LineList({
    required this.lines,
    required this.addKey,
    required this.addLabelColor,
    required this.lang,
    required this.onAdd,
    required this.onRemove,
    required this.fieldKeyFor,
    required this.handleKeyFor,
    required this.rowBuilder,
    required this.fontSize,
    required this.colorFor,
  });

  final List<_EditableLine> lines;
  final Key addKey;
  final Color addLabelColor;
  final AppLanguage lang;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final Key Function(int index) fieldKeyFor;
  final Key Function(int index) handleKeyFor;
  final Widget Function(
    int index,
    _EditableLine line,
    Widget field,
    Widget handle,
  )
  rowBuilder;
  final double fontSize;
  final Color Function(_EditableLine line) colorFor;

  @override
  Widget build(BuildContext context) {
    final atLimit = lines.length >= Project.simpleLineLimit;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < lines.length; index++)
            rowBuilder(
              index,
              lines[index],
              _LineField(
                fieldKey: fieldKeyFor(index),
                controller: lines[index].controller,
                focusNode: lines[index].focusNode,
                hint: '',
                fontSize: fontSize,
                color: colorFor(lines[index]),
              ),
              // A dedicated long-press target: the row's own TextField wins
              // the gesture arena for a long press (that's its selection
              // handle), so the delete gesture needs somewhere of its own
              // to live.
              _RowHandle(
                handleKey: handleKeyFor(index),
                color: colorFor(lines[index]),
                onLongPress: () => onRemove(index),
              ),
            ),
          if (!atLimit)
            InkWell(
              key: addKey,
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: addLabelColor),
                    const SizedBox(width: 4),
                    Text(
                      '追加'.tr(lang),
                      style: TextStyle(
                        fontSize: fontSize,
                        color: addLabelColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The leading bullet on a 現状 / 方策 row. Long-press to delete that row.
class _RowHandle extends StatelessWidget {
  const _RowHandle({
    required this.handleKey,
    required this.color,
    required this.onLongPress,
  });

  final Key handleKey;
  final Color color;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: handleKey,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
        child: Icon(Icons.circle, size: 5, color: color),
      ),
    );
  }
}

/// A 方策 row: handle, field, checkbox — and, once ticked, its own grey fill
/// so the tick reads at a glance without hiding the text.
class _CheckableRow extends StatelessWidget {
  const _CheckableRow({
    required this.checkboxKey,
    required this.done,
    required this.onChanged,
    required this.fill,
    required this.border,
    required this.handle,
    required this.child,
  });

  final Key checkboxKey;
  final bool done;
  final ValueChanged<bool> onChanged;
  final Color fill;
  final Color border;
  final Widget handle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          handle,
          Expanded(child: child),
          _RowCheckbox(
            checkboxKey: checkboxKey,
            value: done,
            activeColor: AppPalette.inkMuted,
            borderColor: AppPalette.inkMuted,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Compact [Checkbox] sized for a board row rather than a settings list.
class _RowCheckbox extends StatelessWidget {
  const _RowCheckbox({
    required this.checkboxKey,
    required this.value,
    required this.activeColor,
    required this.borderColor,
    required this.onChanged,
  });

  final Key checkboxKey;
  final bool value;
  final Color activeColor;
  final Color borderColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Checkbox(
        key: checkboxKey,
        value: value,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: borderColor, width: 1.5),
        activeColor: activeColor,
        checkColor: Colors.white,
        onChanged: (next) => onChanged(next ?? false),
      ),
    );
  }
}
