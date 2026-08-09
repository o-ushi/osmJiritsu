import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../state/wizard_notifier.dart';
import '../widgets/primary_cta_button.dart';

/// Step 2: two goal questions rather than the old single "goal" field —
/// 在りたい姿 (the state that alone would count as success — the
/// "sufficient condition" side of the goal) and 在りたくない姿 (the state
/// that must be avoided regardless — the "necessary condition" side).
///
/// Keeping them separate is the point: a single "goal" field tends to
/// collapse the two into one wish, which is exactly what Step 0's ゴール1/
/// ゴール2 split is meant to prevent. Only 在りたい姿 is required to
/// proceed — see `WizardState.canProceedFromGoal`.
class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  late final _desiredController = TextEditingController(
    text: ref.read(wizardProvider).desiredGoal,
  );
  late final _undesiredController = TextEditingController(
    text: ref.read(wizardProvider).undesiredGoal,
  );

  @override
  void dispose() {
    _desiredController.dispose();
    _undesiredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(wizardProvider.notifier);
    final canProceed = ref.watch(
      wizardProvider.select((s) => s.canProceedFromGoal),
    );
    final lang = ref.watch(appLanguageProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // These sit directly on the scene background, not a card, so
            // they need AppPalette.sceneText/sceneTextMuted explicitly —
            // the theme's own default textTheme color is resolved against
            // cardFill instead, for the common (card) case.
            Text(
              'ゴールを教えてください'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
            ),
            const SizedBox(height: 8),
            Text(
              '「在りたい姿」と「在りたくない姿」、両方の向きから考えてみましょう。'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 32),
            Text(
              '在りたい姿'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
            ),
            const SizedBox(height: 4),
            Text(
              'これが実現すれば十分、と言える理想の姿（充分条件）'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desiredController,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.next,
              onChanged: notifier.setDesiredGoal,
              decoration: InputDecoration(
                hintText: '例）自分の強みを活かして、納得感のある転職をしたい'.tr(lang),
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '在りたくない姿'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
            ),
            const SizedBox(height: 4),
            Text(
              'これだけは避けたい、という最低ライン（必要条件）'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _undesiredController,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onChanged: notifier.setUndesiredGoal,
              decoration: InputDecoration(
                hintText: '例）妥協して、納得感のないまま転職すること'.tr(lang),
                prefixIcon: const Icon(Icons.block_outlined),
              ),
            ),
            const SizedBox(height: 36),
            PrimaryCtaButton(
              label: 'アイデアを出してみる'.tr(lang),
              visible: canProceed,
              onPressed: notifier.advanceFromGoal,
            ),
          ],
        ),
      ),
    );
  }
}
