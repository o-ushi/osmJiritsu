import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/strategy_suggestion.dart';
import '../../theme/app_theme.dart';

/// One AI-suggested 方策 from Stage1 Step 5. "採用済／未採用" is a toggle — see
/// [StrategyFlowNotifier.toggleSuggestion] — that includes/excludes this
/// suggestion from the user's decided 方策 (Step 6); long-pressing the
/// suggestion itself opens an editor to reword it in place (e.g. "週1"→
/// "週2") via [StrategyFlowNotifier.editSuggestionText].
class StrategySuggestionCard extends StatelessWidget {
  final int index;
  final StrategySuggestion suggestion;
  final AppLanguage lang;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  /// Whether this suggestion is currently in
  /// `StrategyFlowDeciding.adoptedSuggestionIds` — fills the button as
  /// 採用済 so its on/off state is visible at a glance.
  final bool adopted;

  const StrategySuggestionCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardFill,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: onLongPress,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppPalette.mintDark,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.text,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (suggestion.rationale.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          suggestion.rationale,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onToggle,
              // Explicit even in the not-adopted (`null`-style-ish) case —
              // this card sits on AppPalette.cardFill, not
              // AppPalette.scene, so it needs linkOnCard rather than
              // falling through to the app-wide outlinedButtonTheme
              // (tuned for scene).
              style: adopted
                  ? OutlinedButton.styleFrom(
                      backgroundColor: AppPalette.mintDark,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: AppPalette.mintDark),
                    )
                  : OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.linkOnCard,
                      side: BorderSide(
                        color: AppPalette.linkOnCard.withValues(alpha: 0.65),
                      ),
                    ),
              icon: Icon(
                adopted ? Icons.check_rounded : Icons.add_rounded,
                size: 18,
              ),
              label: Text((adopted ? '採用済' : '未採用').tr(lang)),
            ),
          ),
        ],
      ),
    );
  }
}
