import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/operation_guide_sheet.dart';
import 'history_icon_actions_menu.dart';

enum ProjectToolbarMode {
  /// 共有 · 振り返り · …
  dashboard,

  /// 共有 · リターン · …
  child,
}

/// Icon-only bottom toolbar for the project dashboard and its child screens.
class ProjectBottomToolbar extends StatefulWidget {
  const ProjectBottomToolbar({
    super.key,
    required this.lang,
    required this.mode,
    required this.onShare,
    required this.onSettings,
    required this.onHelp,
    this.onReflection,
    this.onReturn,
    this.guideMessageKey,
  });

  final AppLanguage lang;
  final ProjectToolbarMode mode;
  final VoidCallback onShare;
  final VoidCallback onSettings;
  final VoidCallback onHelp;
  final VoidCallback? onReflection;
  final VoidCallback? onReturn;

  /// Translation key for this screen's 操作方法 sheet content — see
  /// [OperationGuideSheet.bodyKey]. Null falls back to the generic guide.
  final String? guideMessageKey;

  @override
  State<ProjectBottomToolbar> createState() => _ProjectBottomToolbarState();
}

class _ProjectBottomToolbarState extends State<ProjectBottomToolbar> {
  final _moreButtonKey = GlobalKey();

  void _showMoreMenu() {
    showHistoryIconActionsMenu(
      context: context,
      anchorKey: _moreButtonKey,
      alignRight: true,
      menu: HistoryIconActionsMenu(
        actions: [
          HistoryIconAction(
            icon: Icons.settings_outlined,
            label: '設定'.tr(widget.lang),
            onTap: () {
              Navigator.pop(context);
              widget.onSettings();
            },
          ),
          HistoryIconAction(
            icon: Icons.help_outline_rounded,
            label: 'ヘルプ'.tr(widget.lang),
            onTap: () {
              Navigator.pop(context);
              widget.onHelp();
            },
          ),
        ],
      ),
    );
  }

  void _showOperationGuide() {
    OperationGuideSheet.show(
      context,
      lang: widget.lang,
      bodyKey: widget.guideMessageKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    const hPad = 24.0;
    const iconSize = 34.0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.cardFill,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: switch (widget.mode) {
            ProjectToolbarMode.dashboard => [
              _ProjectToolbarButton(
                icon: Icons.ios_share_rounded,
                label: '共有'.tr(widget.lang),
                onTap: widget.onShare,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ProjectToolbarButton(
                icon: Icons.edit_note_rounded,
                label: '振り返り'.tr(widget.lang),
                onTap: widget.onReflection ?? () {},
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ProjectToolbarButton(
                key: _moreButtonKey,
                icon: Icons.more_horiz_rounded,
                label: 'その他'.tr(widget.lang),
                onTap: _showMoreMenu,
                onLongPress: _showOperationGuide,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
            ],
            ProjectToolbarMode.child => [
              _ProjectToolbarButton(
                icon: Icons.ios_share_rounded,
                label: '共有'.tr(widget.lang),
                onTap: widget.onShare,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ProjectToolbarButton(
                icon: Icons.dashboard_rounded,
                label: 'リターン'.tr(widget.lang),
                onTap: widget.onReturn ?? () {},
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ProjectToolbarButton(
                key: _moreButtonKey,
                icon: Icons.more_horiz_rounded,
                label: 'その他'.tr(widget.lang),
                onTap: _showMoreMenu,
                onLongPress: _showOperationGuide,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
            ],
          },
        ),
      ),
    );
  }
}

class _ProjectToolbarButton extends StatelessWidget {
  const _ProjectToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.horizontalPadding = 24,
    this.iconSize = 34,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double horizontalPadding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Icon(icon, color: AppPalette.inkMuted, size: iconSize),
          ),
        ),
      ),
    );
  }
}
