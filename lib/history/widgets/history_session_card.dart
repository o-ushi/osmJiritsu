import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';
import 'project_status_chip.dart';

/// One row in the 登録案件リスト (`HistoryListScreen`): テーマ / 現況 /
/// 期限 / 進捗率 / ▶️ — plus 編集/削除 affordances. 並べ替え itself is the
/// list's job (long-press-drag wraps this card from outside, see
/// `HistoryListScreen`), not this card's.
class HistorySessionCard extends StatelessWidget {
  final Project project;
  final AppLanguage lang;

  /// ▶️ — the only tap target that opens the project (its dashboard once
  /// past 作成中, otherwise back into the wizard — see
  /// `HistoryListScreen._openProject`); nothing else on this row does.
  final VoidCallback onPlay;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// ⭐️ — toggles [Project.isFavorite] so this row can be picked out from
  /// the rest of the list; purely a visual marker, doesn't affect sort
  /// order.
  final VoidCallback onToggleFavorite;

  const HistorySessionCard({
    super.key,
    required this.project,
    required this.lang,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    // Overdue wins over the ⭐️ amber tint — a missed deadline is the more
    // urgent signal. Favorite tint is otherwise blended (not a flat overlay).
    final Color background;
    if (project.isDeadlineOverdue) {
      background = AppPalette.overdueYellow;
    } else if (project.isFavorite) {
      background = Color.alphaBlend(
        AppPalette.amber.withValues(alpha: 0.16),
        AppPalette.cardFill,
      );
    } else {
      background = AppPalette.cardFill;
    }

    final deadline = project.deadline;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        // Always a 1px border, transparent when not favorited — a border
        // that only appears on ⭐️ would make `Container` inflate this
        // card's implicit padding by the border width only in that state
        // (see `BoxDecoration.padding`), nudging every row's height and
        // content position by a pixel or two depending on ⭐️. Keeping the
        // border always present at the same width avoids that shift.
        border: Border.all(
          color: project.isFavorite && !project.isDeadlineOverdue
              ? AppPalette.amber.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // テーマ gets the card's full width to itself — sharing a
                // row with ⭐️/編集 (as it used to) squeezed it down to a
                // couple of characters before ellipsizing.
                Text(
                  project.theme.isEmpty
                      ? '(テーマ未設定)'.tr(lang)
                      : project.theme,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Flexible so a long translated status label (e.g. the
                    // Vietnamese '作成中' → "Đang chuẩn bị") can shrink
                    // (and ellipsize, see ProjectStatusChip) instead of
                    // overflowing past the ⭐️/✏️ buttons. It's the Row's
                    // *only* flexible child — paired with a Spacer (also
                    // flex:1) the two would split the leftover width
                    // 50/50, ellipsizing the label even when there's
                    // plenty of room; this way it only shrinks once the
                    // trailing icons actually need the space.
                    Flexible(
                      child: ProjectStatusChip(
                        status: project.status,
                        lang: lang,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                              (project.isFavorite ? 'お気に入り解除' : 'お気に入りに追加')
                                  .tr(lang),
                          icon: Icon(
                            project.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 22,
                            color: project.isFavorite
                                ? AppPalette.amber
                                : null,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: onToggleFavorite,
                        ),
                        IconButton(
                          tooltip: '編集'.tr(lang),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          visualDensity: VisualDensity.compact,
                          onPressed: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
                if (deadline != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'期限'.tr(lang)}: ${_formatDeadline(deadline)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: project.isDeadlineOverdue
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: project.isDeadlineOverdue
                          ? const Color(0xFF203A34)
                          : AppPalette.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: project.progressRatio,
                          minHeight: 6,
                          backgroundColor: AppPalette.mint.withValues(
                            alpha: 0.15,
                          ),
                          color: AppPalette.mintDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(project.progressRatio * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '削除'.tr(lang),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
          IconButton(
            tooltip: 'ダッシュボードへ'.tr(lang),
            icon: const Icon(Icons.play_circle_fill_rounded),
            color: AppPalette.mintDark,
            iconSize: 32,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

String _formatDeadline(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')}';
}
