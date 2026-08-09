import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/project_status.dart';
import '../../theme/app_theme.dart';

/// 現況 badge — [ProjectStatus.displayName] given a bit of color so status
/// reads at a glance. Shared between `DashboardScreen` (the project
/// dashboard) and [HistorySessionCard] (a row in the 登録案件リスト), since
/// both show the same 現況 for the same [ProjectStatus] values.
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

  @override
  Widget build(BuildContext context) {
    final accent = _color;
    final background = Color.alphaBlend(
      accent.withValues(
        alpha: AppPalette.isLightSurface(AppPalette.scene) ? 0.12 : 0.28,
      ),
      AppPalette.scene,
    );
    final textColor = AppPalette.ensureReadableOn(
      background: background,
      preferred: AppPalette.readableAccent(accent, AppPalette.scene),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: textColor.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          status.displayName.tr(lang),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
