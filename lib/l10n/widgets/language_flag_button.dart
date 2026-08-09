import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../app_language.dart';
import '../app_language_notifier.dart';
import '../app_strings.dart';

/// Shows just the current display language's flag; tapping it opens a
/// quick language-picker sheet. Ported from osmGradus's
/// `LanguageFlagButton` (`lib/widgets/language_flag_button.dart`) for
/// places — like [HistoryListScreen]'s start screen — where switching
/// language shouldn't require a trip through Settings.
class LanguageFlagButton extends ConsumerWidget {
  const LanguageFlagButton({super.key});

  Future<void> _openPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.cardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Tooltip(
      message: '言語'.tr(lang),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _openPicker(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(lang.flag, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return SafeArea(
      top: false,
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
              '言語'.tr(lang),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '言語_スタートショートカット'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.sceneTextMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final language in AppLanguage.values)
              _LanguageOptionRow(language: language, selected: lang == language),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionRow extends ConsumerWidget {
  const _LanguageOptionRow({required this.language, required this.selected});

  final AppLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(appLanguageProvider.notifier).setLanguage(language);
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.displayName,
                style: const TextStyle(fontSize: 16, color: AppPalette.ink),
              ),
            ),
            if (selected) const Icon(Icons.check, color: AppPalette.mintDark),
          ],
        ),
      ),
    );
  }
}
