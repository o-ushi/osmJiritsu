import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// 「次回から表示しない」と確定ボタン。スタート画面と使い方画面の下に固定し、
/// 余白を揃えて両画面で同じ位置に置く。
class StartupBottomBar extends StatelessWidget {
  const StartupBottomBar({
    super.key,
    required this.lang,
    required this.dontShowAgain,
    required this.onDontShowAgainChanged,
    required this.label,
    required this.onPressed,
  });

  final AppLanguage lang;
  final bool dontShowAgain;
  final ValueChanged<bool> onDontShowAgainChanged;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 親の SafeArea は下端を空けない（一覧のツールバー側で扱う）ので、
    // ホームインジケータ分はここで足す。
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final short = MediaQuery.sizeOf(context).height <= 700;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        short ? 4 : 8,
        0,
        (short ? 12 : 16) + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DontShowAgainCheckbox(
            lang: lang,
            value: dontShowAgain,
            onChanged: onDontShowAgainChanged,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.mintDark,
                foregroundColor: AppPalette.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DontShowAgainCheckbox extends StatelessWidget {
  const _DontShowAgainCheckbox({
    required this.lang,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage lang;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
                side: const BorderSide(color: AppPalette.sceneText, width: 1.5),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppPalette.mintDark;
                  }
                  return Colors.transparent;
                }),
                checkColor: AppPalette.onAccent,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '次回から表示しない'.tr(lang),
                style: const TextStyle(fontSize: 15, color: AppPalette.sceneText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
