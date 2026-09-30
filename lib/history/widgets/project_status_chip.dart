import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/project_status.dart';
import '../../theme/app_theme.dart';

/// 現況 badge — a colored, fixed-size icon rather than [ProjectStatus.
/// displayName] as text: EN/VI translations of that label ("Đang chuẩn bị"
/// etc.) were long enough to ellipsize inside the history card's tight row,
/// and an icon can't truncate. The label itself isn't lost — it's the
/// [Tooltip] message, so a long-press/hover still says it in words.
/// Shared between `DashboardScreen` (the project dashboard) and
/// [HistorySessionCard] (a row in the 登録案件リスト), since both show the
/// same 現況 for the same [ProjectStatus] values.
class ProjectStatusChip extends StatelessWidget {
  final ProjectStatus status;
  final AppLanguage lang;

  const ProjectStatusChip({super.key, required this.status, required this.lang});

  Color get _color => switch (status) {
    ProjectStatus.preparing => AppPalette.inkMuted,
    ProjectStatus.inProgress => AppPalette.mintDark,
    ProjectStatus.onBreak => AppPalette.amber,
    ProjectStatus.completed => AppPalette.softBlueDark,
  };

  /// 作成中=まだ編集中, 実施中=進行, 休憩中=一時停止, 完了=済み — each reads
  /// on its own without the label, which is the point.
  IconData get _icon => switch (status) {
    ProjectStatus.preparing => Icons.edit_note_rounded,
    ProjectStatus.inProgress => Icons.play_arrow_rounded,
    ProjectStatus.onBreak => Icons.pause_rounded,
    ProjectStatus.completed => Icons.check_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _color;
    final background = Color.alphaBlend(
      accent.withValues(
        alpha: AppPalette.isLightSurface(AppPalette.scene) ? 0.12 : 0.28,
      ),
      AppPalette.scene,
    );
    final iconColor = AppPalette.ensureReadableOn(
      background: background,
      preferred: AppPalette.readableAccent(accent, AppPalette.scene),
    );
    final label = status.displayName.tr(lang);

    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.35)),
            ),
            child: Icon(_icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}
