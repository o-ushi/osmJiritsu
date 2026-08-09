import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../state/wizard_state.dart';

/// One soft pill segment per [WizardStep], filling in across the top of the
/// wizard as the user moves through them — a lightweight "you're almost
/// there" cue without a heavy stepper widget.
class StepProgressBar extends StatelessWidget {
  final WizardStep currentStep;

  const StepProgressBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final currentIndex = WizardStep.values.indexOf(currentStep);
    return Row(
      children: [
        for (var i = 0; i < WizardStep.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              height: 6,
              decoration: BoxDecoration(
                color: i <= currentIndex
                    ? AppPalette.mintDark
                    : AppPalette.mintDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
