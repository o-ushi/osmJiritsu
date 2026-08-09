import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/operation_guide_sheet.dart';
import 'history_icon_actions_menu.dart';

/// Bottom-toolbar layout variants.
enum HistoryToolbarMode {
  /// データ · ＋ · …
  home,

  /// データ · ホーム · …
  flow,

  /// データ · ＋ · ホーム · 戻る · …
  matrix,
}

/// Fixed bottom toolbar shared by the home screen and Stage-1 flow screens.
///
/// Three primary affordances:
/// - **データ** → JSONバックアップ / JSONを取り込む (icon-only popup)
/// - **＋** → 新規追加 (home) or 項目を追加 (matrix [onAdd])
/// - **ホーム** → flow / matrix screens when applicable
/// - **戻る** → undo last edit on the matrix screen ([onUndo])
/// - **…** → 設定 / ヘルプ (+ 新規追加 on flow screens; icon-only popup)
class HistoryBottomToolbar extends StatefulWidget {
  const HistoryBottomToolbar({
    super.key,
    required this.lang,
    required this.onExport,
    required this.onImport,
    required this.onAddNew,
    required this.onSettings,
    required this.onHelp,
    this.mode = HistoryToolbarMode.home,
    this.onHome,
    this.onAdd,
    this.onUndo,
    this.canUndo = false,
    this.guideMessageKey,
  });

  final AppLanguage lang;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onAddNew;
  final VoidCallback onSettings;
  final VoidCallback onHelp;
  final HistoryToolbarMode mode;
  final VoidCallback? onHome;
  final VoidCallback? onAdd;
  final VoidCallback? onUndo;
  final bool canUndo;

  /// Translation key for this screen's 操作方法 sheet content — see
  /// [OperationGuideSheet.bodyKey]. Null falls back to the generic guide.
  final String? guideMessageKey;

  @override
  State<HistoryBottomToolbar> createState() => _HistoryBottomToolbarState();
}

class _HistoryBottomToolbarState extends State<HistoryBottomToolbar> {
  final _dataButtonKey = GlobalKey();
  final _moreButtonKey = GlobalKey();

  void _showDataMenu() {
    showHistoryIconActionsMenu(
      context: context,
      anchorKey: _dataButtonKey,
      menu: HistoryIconActionsMenu(
        actions: [
          HistoryIconAction(
            icon: Icons.file_upload_outlined,
            label: 'JSONバックアップ'.tr(widget.lang),
            onTap: () {
              Navigator.pop(context);
              widget.onExport();
            },
          ),
          HistoryIconAction(
            icon: Icons.file_download_outlined,
            label: 'JSONを取り込む'.tr(widget.lang),
            onTap: () {
              Navigator.pop(context);
              widget.onImport();
            },
          ),
        ],
      ),
    );
  }

  void _showMoreMenu() {
    final actions = <HistoryIconAction>[
      if (widget.mode == HistoryToolbarMode.flow)
        HistoryIconAction(
          icon: Icons.add_circle_outline,
          label: '新規追加'.tr(widget.lang),
          onTap: () {
            Navigator.pop(context);
            widget.onAddNew();
          },
        ),
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
    ];

    showHistoryIconActionsMenu(
      context: context,
      anchorKey: _moreButtonKey,
      alignRight: true,
      menu: HistoryIconActionsMenu(actions: actions),
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
    final compact = widget.mode == HistoryToolbarMode.matrix;
    final hPad = compact ? 10.0 : 24.0;
    final iconSize = compact ? 30.0 : 34.0;
    final emphasizedSize = compact ? 38.0 : 44.0;

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
            HistoryToolbarMode.home => [
              _ToolbarButton(
                key: _dataButtonKey,
                icon: Icons.storage_outlined,
                label: 'データ'.tr(widget.lang),
                onTap: _showDataMenu,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ToolbarButton(
                icon: Icons.add_circle_rounded,
                label: '新規追加'.tr(widget.lang),
                onTap: widget.onAddNew,
                emphasized: true,
                horizontalPadding: hPad,
                iconSize: iconSize,
                emphasizedSize: emphasizedSize,
              ),
              _ToolbarButton(
                key: _moreButtonKey,
                icon: Icons.more_horiz_rounded,
                label: 'その他'.tr(widget.lang),
                onTap: _showMoreMenu,
                onLongPress: _showOperationGuide,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
            ],
            HistoryToolbarMode.flow => [
              _ToolbarButton(
                key: _dataButtonKey,
                icon: Icons.storage_outlined,
                label: 'データ'.tr(widget.lang),
                onTap: _showDataMenu,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ToolbarButton(
                icon: Icons.home_rounded,
                label: 'ホーム'.tr(widget.lang),
                onTap: widget.onHome ?? () {},
                emphasized: true,
                horizontalPadding: hPad,
                iconSize: iconSize,
                emphasizedSize: emphasizedSize,
              ),
              _ToolbarButton(
                key: _moreButtonKey,
                icon: Icons.more_horiz_rounded,
                label: 'その他'.tr(widget.lang),
                onTap: _showMoreMenu,
                onLongPress: _showOperationGuide,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
            ],
            HistoryToolbarMode.matrix => [
              _ToolbarButton(
                key: _dataButtonKey,
                icon: Icons.storage_outlined,
                label: 'データ'.tr(widget.lang),
                onTap: _showDataMenu,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ToolbarButton(
                icon: Icons.add_circle_rounded,
                label: '項目を追加'.tr(widget.lang),
                onTap: widget.onAdd ?? () {},
                emphasized: true,
                horizontalPadding: hPad,
                iconSize: iconSize,
                emphasizedSize: emphasizedSize,
              ),
              _ToolbarButton(
                icon: Icons.home_rounded,
                label: 'ホーム'.tr(widget.lang),
                onTap: widget.onHome ?? () {},
                emphasized: true,
                horizontalPadding: hPad,
                iconSize: iconSize,
                emphasizedSize: emphasizedSize,
              ),
              _ToolbarButton(
                icon: Icons.undo_rounded,
                label: '戻る'.tr(widget.lang),
                onTap: widget.onUndo ?? () {},
                enabled: widget.canUndo,
                horizontalPadding: hPad,
                iconSize: iconSize,
              ),
              _ToolbarButton(
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

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.emphasized = false,
    this.enabled = true,
    this.horizontalPadding = 24,
    this.iconSize = 34,
    this.emphasizedSize = 44,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool emphasized;
  final bool enabled;
  final double horizontalPadding;
  final double iconSize;
  final double emphasizedSize;

  @override
  Widget build(BuildContext context) {
    final baseColor = emphasized ? AppPalette.mintDark : AppPalette.inkMuted;
    final color = enabled ? baseColor : baseColor.withValues(alpha: 0.35);
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Icon(
              icon,
              color: color,
              size: emphasized ? emphasizedSize : iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
