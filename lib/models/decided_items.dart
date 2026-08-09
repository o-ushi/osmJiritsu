/// Helpers for `\n`-joined decided 方策 / 最初の一歩 strings.
///
/// Adoption still stores suggestions as plain lines joined by `\n` (see
/// `StrategyFlowDeciding.decidedStrategy` /
/// `FirstStepFlowDeciding.decidedFirstStep`); these helpers only shape
/// how that string is *shown* or exported when several items are combined.

/// Non-empty lines of a decided string, in order.
List<String> splitDecidedItems(String value) => value
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

/// Plain-text formatting for share/export. One item stays as-is; two or
/// more get `方策 1` / `最初の一歩 1` style headings with a blank line
/// between blocks so the wall of text is scannable.
String formatDecidedItemsPlain(String value, String itemLabel) {
  final items = splitDecidedItems(value);
  if (items.isEmpty) return '';
  if (items.length == 1) return items.single;

  final buffer = StringBuffer();
  for (var i = 0; i < items.length; i++) {
    if (i > 0) buffer.writeln();
    buffer.writeln('$itemLabel ${i + 1}');
    buffer.write(items[i]);
    if (i < items.length - 1) buffer.writeln();
  }
  return buffer.toString();
}
