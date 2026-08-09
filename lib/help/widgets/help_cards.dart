import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared accent-bar card shell used across the HELP screen and the
/// dedicated「自律とは」screen, so both keep the same visual language.
class HelpSectionCardShell extends StatelessWidget {
  const HelpSectionCardShell({
    super.key,
    required this.accentColor,
    required this.child,
    this.onTap,
  });

  final Color accentColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Fixed white, not AppPalette.cardFill — HELP lives on a subpage
    // (see SubpageScaffold) and keeps a distinct card surface.
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 5, color: accentColor),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1F0EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class HelpBulletList extends StatelessWidget {
  const HelpBulletList({super.key, required this.tips, this.bulletColor});

  final List<String> tips;
  final Color? bulletColor;

  @override
  Widget build(BuildContext context) {
    final dotColor = bulletColor ?? AppPalette.mintDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in tips) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppPalette.subpageTextMuted,
                  ),
                ),
              ),
            ],
          ),
          if (tip != tips.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class HelpLeadCard extends StatelessWidget {
  const HelpLeadCard({
    super.key,
    required this.title,
    this.summary,
    this.tips = const [],
    required this.accentColor,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? summary;
  final List<String> tips;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return HelpSectionCardShell(
      accentColor: accentColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.subpageText,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 6),
            Text(
              summary!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppPalette.subpageText,
              ),
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            HelpBulletList(tips: tips, bulletColor: accentColor),
          ],
        ],
      ),
    );
  }
}

class HelpSectionCard extends StatelessWidget {
  const HelpSectionCard({
    super.key,
    required this.badgeLabel,
    required this.title,
    this.summary,
    this.tips = const [],
    this.keyword,
    required this.accentColor,
  });

  final String badgeLabel;
  final String title;
  final String? summary;
  final List<String> tips;

  /// Emphasized callout rendered below [tips] (e.g. a cross-reference to a
  /// term defined later on the same screen) — bold, in this card's own
  /// [accentColor] rather than a separate hue, so emphasis reads through
  /// weight/size and not through adding another color to the screen.
  final String? keyword;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HelpSectionCardShell(
        accentColor: accentColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.subpageText,
                        ),
                      ),
                      if (summary != null)
                        Text(
                          summary!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 12),
              HelpBulletList(tips: tips),
            ],
            if (keyword != null) ...[
              const SizedBox(height: 8),
              Text(
                keyword!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
