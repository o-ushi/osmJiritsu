import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../state/wizard_notifier.dart';
import '../widgets/emoji_badge.dart';
import '../widgets/primary_cta_button.dart';

/// Step 1: capture just the analysis theme — nothing else.
///
/// Split out of the old combined theme+goal screen (see [GoalScreen] for
/// Step 2) so goal capture can ask its two questions (在りたい姿/
/// 在りたくない姿) without crowding this one, and so the theme stands on
/// its own as the thing everything else in the analysis is "about".
class ThemeScreen extends ConsumerStatefulWidget {
  const ThemeScreen({super.key});

  @override
  ConsumerState<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends ConsumerState<ThemeScreen> {
  late final _themeController = TextEditingController(
    text: ref.read(wizardProvider).theme,
  );

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(wizardProvider.notifier);
    final canProceed = ref.watch(
      wizardProvider.select((s) => s.canProceedFromTheme),
    );
    final lang = ref.watch(appLanguageProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIconBadge(),
            const SizedBox(height: 20),
            // These sit directly on the scene background, not a card, so
            // they need AppPalette.sceneText/sceneTextMuted explicitly —
            // the theme's own default textTheme color is resolved against
            // cardFill instead, for the common (card) case.
            Text(
              'それでは始めましょう'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
            ),
            const SizedBox(height: 8),
            Text(
              'まずテーマを決めよう'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 36),
            Text(
              'テーマ'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _themeController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: notifier.setTheme,
              decoration: InputDecoration(
                hintText: '例）新しいキャリアについて'.tr(lang),
                prefixIcon: const Icon(Icons.explore_outlined),
              ),
            ),
            const SizedBox(height: 36),
            PrimaryCtaButton(
              label: 'ゴールを考える'.tr(lang),
              visible: canProceed,
              onPressed: notifier.advanceFromTheme,
            ),
          ],
        ),
      ),
    );
  }
}
