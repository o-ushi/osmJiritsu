import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/widgets/flow_scaffold.dart';
import '../state/wizard_notifier.dart';
import '../state/wizard_state.dart';
import '../widgets/step_progress_bar.dart';
import 'goal_screen.dart';
import 'idea_dump_screen.dart';
import 'quick_classification_screen.dart';
import 'theme_screen.dart';

/// Hosts the 4-step input wizard (theme → goal → idea dump → quick
/// classification) inside a single [PageView], animating between steps as
/// [WizardState.step] changes.
///
/// Horizontal [PageView] swiping stays disabled — step changes only through
/// each screen's CTA/back affordances or the system back gesture, which
/// [WizardNotifier.handleSystemBack] maps to the previous wizard *screen*
/// rather than popping back to the home screen (use the bottom-toolbar
/// home button for that). Within classification, the "戻す" button still
/// undoes one question on the same screen.
class WizardFlowScreen extends ConsumerStatefulWidget {
  const WizardFlowScreen({super.key});

  @override
  ConsumerState<WizardFlowScreen> createState() => _WizardFlowScreenState();
}

class _WizardFlowScreenState extends ConsumerState<WizardFlowScreen> {
  // Starts on whatever step `wizardProvider` already holds — not always
  // page 0 — since resuming a 作成中 project (`WizardNotifier.resumeFrom`)
  // seeds the state with its step already past `theme` before this screen
  // ever mounts, and `ref.listen` below only reacts to *changes* to
  // `step`, not the value it started at.
  late final _pageController = PageController(
    initialPage: WizardStep.values.indexOf(ref.read(wizardProvider).step),
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wizardProvider.select((s) => s.step), (previous, next) {
      final index = WizardStep.values.indexOf(next);
      if (!_pageController.hasClients) return;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
    final currentStep = ref.watch(wizardProvider.select((s) => s.step));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(wizardProvider.notifier).handleSystemBack();
      },
      child: FlowScaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: StepProgressBar(currentStep: currentStep),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ThemeScreen(),
                  GoalScreen(),
                  IdeaDumpScreen(),
                  QuickClassificationScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
