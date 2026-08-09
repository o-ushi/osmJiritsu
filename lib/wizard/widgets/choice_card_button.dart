import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One large, friendly answer card for a single yes/no-style question.
///
/// Used two at a time (side by side) rather than four at once — deliberately
/// generic (an emoji + a short label), not a "SWOT quadrant" widget, so the
/// classification screen never has to look like a matrix.
class ChoiceCardButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const ChoiceCardButton({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          // Top-anchored (not centered) so the emoji lands at the same
          // height on both cards regardless of how many lines the *other*
          // card's title/subtitle wrap to — centering the whole block would
          // shift the emoji up/down by however much extra text follows it.
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 21,
                  color: color.withValues(alpha: 0.95),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  // This card sits directly on [AppPalette.scene] (behind
                  // its translucent [color] tint), not on [cardFill], so it
                  // needs scene-contrast text rather than the theme's
                  // default (card-contrast) bodyMedium color.
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: AppPalette.sceneTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
