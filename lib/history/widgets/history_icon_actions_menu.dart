import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One icon-only action in [HistoryIconActionsMenu].
class HistoryIconAction {
  const HistoryIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// osmWashabe's [WashabeMoreActionsMenu] 相当 — icon-only buttons in a
/// compact horizontal row; labels live in [Tooltip]s only.
class HistoryIconActionsMenu extends StatelessWidget {
  const HistoryIconActionsMenu({
    super.key,
    required this.actions,
  });

  final List<HistoryIconAction> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.cardFill,
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, action) in actions.indexed) ...[
              if (index > 0) const SizedBox(width: 16),
              _MenuIconButton(action: action),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({required this.action});

  final HistoryIconAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: action.label,
      button: true,
      child: Tooltip(
        message: action.label,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppPalette.mint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1F0EA), width: 1.5),
            ),
            child: Icon(action.icon, color: AppPalette.ink, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Shows [menu] anchored just above [anchorKey], dismissible by tapping outside.
void showHistoryIconActionsMenu({
  required BuildContext context,
  required GlobalKey anchorKey,
  required Widget menu,
  bool alignRight = false,
}) {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return;

  final offset = box.localToGlobal(Offset.zero);
  final size = box.size;
  final screen = MediaQuery.sizeOf(context);

  showDialog<void>(
    context: context,
    barrierColor: Colors.black26,
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: alignRight ? null : offset.dx,
          right: alignRight ? screen.width - offset.dx - size.width : null,
          bottom: screen.height - offset.dy + 6,
          child: menu,
        ),
      ],
    ),
  );
}
