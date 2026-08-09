/// Splits a previously-saved decided string (方策 / 最初の一歩) back into
/// toggled-on AI suggestion ids + leftover free text.
///
/// Decided wording is persisted as one already-combined string
/// (`suggestions-on` then `ownText`, joined by `\n` — see
/// `StrategyFlowDeciding.decidedStrategy` /
/// `FirstStepFlowDeciding.decidedFirstStep`). Dashboard re-review needs to
/// turn "採用済" back on for suggestions the user had adopted, without
/// also leaving those same lines in the free-text field (which would
/// duplicate them once the getter recombines).
class SuggestionAdoptionSplit {
  final Set<String> adoptedIds;
  final String ownText;

  const SuggestionAdoptionSplit({
    required this.adoptedIds,
    required this.ownText,
  });
}

/// Matches [decidedText] against [suggestions] by exact text (whole string
/// or whole `\n`-separated line). Longer suggestion texts are tried first
/// so a short suggestion can't eat a prefix of a longer one.
SuggestionAdoptionSplit splitDecidedIntoAdoptions({
  required List<({String id, String text})> suggestions,
  required String decidedText,
}) {
  var leftover = decidedText.trim();
  if (leftover.isEmpty || suggestions.isEmpty) {
    return SuggestionAdoptionSplit(adoptedIds: const {}, ownText: leftover);
  }

  final ordered = [...suggestions]
    ..sort((a, b) => b.text.trim().length.compareTo(a.text.trim().length));

  final adopted = <String>{};
  for (final suggestion in ordered) {
    final text = suggestion.text.trim();
    if (text.isEmpty || adopted.contains(suggestion.id)) continue;

    if (leftover == text) {
      adopted.add(suggestion.id);
      leftover = '';
      break;
    }

    final lines = leftover.split('\n');
    final index = lines.indexWhere((line) => line.trim() == text);
    if (index < 0) continue;
    adopted.add(suggestion.id);
    lines.removeAt(index);
    leftover = lines.join('\n').trim();
    if (leftover.isEmpty) break;
  }

  return SuggestionAdoptionSplit(adoptedIds: adopted, ownText: leftover);
}
