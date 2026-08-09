import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/first_step_suggestion.dart';
import '../../theme/app_theme.dart';

/// One AI-suggested 最初の一歩 from Stage1 Step 9. "採用済／未採用" is a
/// toggle — see [FirstStepFlowNotifier.toggleSuggestion] — that
/// includes/excludes this suggestion from the user's decided 最初の一歩
/// (Step 10); long-pressing the suggestion itself opens an editor to
/// reword it in place via [FirstStepFlowNotifier.editSuggestionText].
class FirstStepSuggestionCard extends StatelessWidget {
  final int index;
  final FirstStepSuggestion suggestion;
  final AppLanguage lang;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  /// Whether this suggestion is currently in
  /// `FirstStepFlowDeciding.adoptedSuggestionIds` — fills the button as
  /// 採用済 so its on/off state is visible at a glance.
  final bool adopted;

  const FirstStepSuggestionCard({
    super.key,
    required this.index,
    required this.suggestion,
    required this.lang,
    required this.onToggle,
    required this.onLongPress,
    this.adopted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.cardFill,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onLongPress,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppPalette.softBlueDark,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onToggle,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              backgroundColor: adopted ? AppPalette.softBlueDark : null,
              // Explicit even in the not-adopted case — this card sits on
              // AppPalette.cardFill, not AppPalette.scene, so it needs
              // linkOnCard rather than falling through to the app-wide
              // outlinedButtonTheme (tuned for scene).
              foregroundColor: adopted ? Colors.white : AppPalette.linkOnCard,
              side: adopted
                  ? BorderSide(color: AppPalette.softBlueDark)
                  : BorderSide(color: AppPalette.linkOnCard.withValues(alpha: 0.65)),
            ),
            child: Text((adopted ? '採用済' : '未採用').tr(lang)),
          ),
        ],
      ),
    );
  }
}
