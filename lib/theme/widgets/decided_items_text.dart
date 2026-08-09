import 'package:flutter/material.dart';

import '../../models/decided_items.dart';

/// Renders a `\n`-joined decided 方策 / 最初の一歩 string.
///
/// - 0–1 items: plain [Text] (no numbering noise).
/// - 2+ items: `方策 1` / `最初の一歩 1` headings plus a hairline between
///   blocks, so multiple adopted suggestions don't read as one wall.
class DecidedItemsText extends StatelessWidget {
  final String value;

  /// Base label used as `方策 1`, `Strategy 2`, etc. Required for numbering;
  /// ignored when there is only one item.
  final String itemLabel;

  final TextStyle? style;
  final TextStyle? itemLabelStyle;
  final Color? dividerColor;
  final TextAlign textAlign;

  const DecidedItemsText({
    super.key,
    required this.value,
    required this.itemLabel,
    this.style,
    this.itemLabelStyle,
    this.dividerColor,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final items = splitDecidedItems(value);
    if (items.length <= 1) {
      return Text(
        value,
        style: style,
        textAlign: textAlign,
      );
    }

    final labelStyle = itemLabelStyle ??
        style?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: (style?.fontSize ?? 16) * 0.85,
        ) ??
        const TextStyle(fontWeight: FontWeight.w700);

    final lineColor =
        dividerColor ?? (style?.color ?? Colors.black).withValues(alpha: 0.22);

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: lineColor),
            const SizedBox(height: 12),
          ],
          Text(
            '$itemLabel ${i + 1}',
            style: labelStyle,
            textAlign: textAlign,
          ),
          const SizedBox(height: 4),
          Text(
            items[i],
            style: style,
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
