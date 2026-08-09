import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../app_theme.dart';

/// 各画面の「•••」ボタンを長押ししたときに表示する操作方法シート。
/// osmGradusの `LayerHelpSheet` と同じ、つまみ付きの角丸ボトムシートで統一する
/// （背景・文字色も「•••」タップ時の [HistoryIconActionsMenu] と同じ
/// [AppPalette.cardFill] 系の役割分担に合わせている）。
class OperationGuideSheet extends StatelessWidget {
  const OperationGuideSheet({super.key, required this.lang, this.bodyKey});

  final AppLanguage lang;

  /// Translation key for this screen's own operation guide — falls back to
  /// the generic '案内に従って操作' when a screen hasn't defined one yet.
  final String? bodyKey;

  static Future<void> show(
    BuildContext context, {
    required AppLanguage lang,
    String? bodyKey,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.cardFill,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OperationGuideSheet(lang: lang, bodyKey: bodyKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '操作方法'.tr(lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(height: 12),
              _GuideBody(text: (bodyKey ?? '案内に従って操作').tr(lang)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [text] line-by-line (split on `\n`), each line with a hanging
/// indent: the leading "1️⃣ " numeral stays in a fixed-width column so a
/// wrapped second line aligns under the label text instead of falling back
/// to the sheet's left edge under the numeral.
class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.text});

  final String text;

  static const _style = TextStyle(
    fontSize: 14,
    height: 1.6,
    color: AppPalette.inkMuted,
  );

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          _GuideLine(text: line),
          if (line != lines.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spaceIndex = text.indexOf(' ');
    if (spaceIndex <= 0) {
      return Text(text, style: _GuideBody._style);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(text.substring(0, spaceIndex), style: _GuideBody._style),
        ),
        Expanded(
          child: Text(
            text.substring(spaceIndex + 1),
            style: _GuideBody._style,
          ),
        ),
      ],
    );
  }
}
