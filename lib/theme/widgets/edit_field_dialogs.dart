import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';

/// Result of [EditGoalsDialog] — a pair of 在りたい姿 / 在りたくない姿 strings.
class GoalPair {
  final String desiredGoal;
  final String undesiredGoal;

  const GoalPair({required this.desiredGoal, required this.undesiredGoal});
}

/// テーマを編集 dialog. A dedicated [StatefulWidget] — not a bare
/// [TextEditingController] created and manually `dispose()`d right after
/// `showDialog` returns — because that controller is still in use by the
/// [TextField] during the dialog route's closing transition.
class EditThemeDialog extends StatefulWidget {
  final String theme;
  final AppLanguage lang;

  const EditThemeDialog({super.key, required this.theme, required this.lang});

  @override
  State<EditThemeDialog> createState() => _EditThemeDialogState();
}

class _EditThemeDialogState extends State<EditThemeDialog> {
  late final _controller = TextEditingController(text: widget.theme);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return AlertDialog(
      title: Text('テーマを編集'.tr(lang)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: 'テーマ'.tr(lang)),
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
                : () => Navigator.of(context).pop(value.text.trim()),
            child: Text('保存'.tr(lang)),
          ),
        ),
      ],
    );
  }
}

/// Generic single-field text editor — used for suggestion polish, light
/// edit of decided 方策 / 最初の一歩, and similar one-string revisions.
class EditTextFieldDialog extends StatefulWidget {
  final AppLanguage lang;
  final String title;
  final String initialText;
  final int minLines;
  final int maxLines;
  final bool requireNonEmpty;

  const EditTextFieldDialog({
    super.key,
    required this.lang,
    required this.title,
    required this.initialText,
    this.minLines = 2,
    this.maxLines = 6,
    this.requireNonEmpty = false,
  });

  @override
  State<EditTextFieldDialog> createState() => _EditTextFieldDialogState();
}

class _EditTextFieldDialogState extends State<EditTextFieldDialog> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル'.tr(lang)),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) {
            final trimmed = value.text.trim();
            final disabled = widget.requireNonEmpty && trimmed.isEmpty;
            return TextButton(
              onPressed: disabled
                  ? null
                  : () => Navigator.of(context).pop(_controller.text),
              child: Text('保存'.tr(lang)),
            );
          },
        ),
      ],
    );
  }
}

/// Edits 在りたい姿 / 在りたくない姿 together. Same controller-ownership
/// pattern as [EditThemeDialog].
class EditGoalsDialog extends StatefulWidget {
  final String desiredGoal;
  final String undesiredGoal;
  final AppLanguage lang;

  const EditGoalsDialog({
    super.key,
    required this.desiredGoal,
    required this.undesiredGoal,
    required this.lang,
  });

  @override
  State<EditGoalsDialog> createState() => _EditGoalsDialogState();
}

class _EditGoalsDialogState extends State<EditGoalsDialog> {
  late final _desiredController = TextEditingController(
    text: widget.desiredGoal,
  );
  late final _undesiredController = TextEditingController(
    text: widget.undesiredGoal,
  );

  @override
  void dispose() {
    _desiredController.dispose();
    _undesiredController.dispose();
    super.dispose();
  }

  void _save() {
    final desired = _desiredController.text.trim();
    final undesired = _undesiredController.text.trim();
    if (desired.isEmpty) return;
    Navigator.of(
      context,
    ).pop(GoalPair(desiredGoal: desired, undesiredGoal: undesired));
  }

  @override
  Widget build(BuildContext context) {
    final fieldTextStyle = Theme.of(context).textTheme.bodyLarge;

    return AlertDialog(
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('在りたい姿'.tr(widget.lang), style: fieldTextStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _desiredController,
            autofocus: true,
            style: fieldTextStyle,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 12),
          Text('在りたくない姿'.tr(widget.lang), style: fieldTextStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _undesiredController,
            style: fieldTextStyle,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル'.tr(widget.lang)),
        ),
        TextButton(
          onPressed: _save,
          child: Text('保存'.tr(widget.lang)),
        ),
      ],
    );
  }
}
