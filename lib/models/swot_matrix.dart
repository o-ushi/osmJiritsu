import 'swot_category.dart';
import 'swot_item.dart';

/// The main SWOT model: the four quadrants of strengths, weaknesses,
/// opportunities and threats.
///
/// Roughly corresponds to `SWOTSession.items` (osmSWOT/Models/SWOTItem.swift)
/// but pre-partitioned by category for convenient use by [AnalysisEngine].
class SwotMatrix {
  final List<SwotItem> strengths;
  final List<SwotItem> weaknesses;
  final List<SwotItem> opportunities;
  final List<SwotItem> threats;

  const SwotMatrix({
    this.strengths = const [],
    this.weaknesses = const [],
    this.opportunities = const [],
    this.threats = const [],
  });

  /// Buckets a flat list of items (e.g. as loaded from storage) into a
  /// [SwotMatrix], mirroring `SWOTSession.items(for:)`.
  factory SwotMatrix.fromItems(List<SwotItem> items) {
    return SwotMatrix(
      strengths: items
          .where((item) => item.category == SwotCategory.strength)
          .toList(),
      weaknesses: items
          .where((item) => item.category == SwotCategory.weakness)
          .toList(),
      opportunities: items
          .where((item) => item.category == SwotCategory.opportunity)
          .toList(),
      threats: items
          .where((item) => item.category == SwotCategory.threat)
          .toList(),
    );
  }

  List<SwotItem> get allItems => [
    ...strengths,
    ...weaknesses,
    ...opportunities,
    ...threats,
  ];

  List<SwotItem> itemsFor(SwotCategory category) {
    switch (category) {
      case SwotCategory.strength:
        return strengths;
      case SwotCategory.weakness:
        return weaknesses;
      case SwotCategory.opportunity:
        return opportunities;
      case SwotCategory.threat:
        return threats;
    }
  }

  /// Plain-text content only, in category order — the shape most prompts
  /// to the LLM need (cf. `AIAnalysisService.performCrossAnalysis`).
  List<String> contentFor(SwotCategory category) => itemsFor(category)
      .map((item) => item.content.trim())
      .where((content) => content.isNotEmpty)
      .toList();

  bool get isEmpty => allItems.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get totalCount => allItems.length;

  SwotMatrix addItem(SwotItem item) {
    switch (item.category) {
      case SwotCategory.strength:
        return SwotMatrix(
          strengths: [...strengths, item],
          weaknesses: weaknesses,
          opportunities: opportunities,
          threats: threats,
        );
      case SwotCategory.weakness:
        return SwotMatrix(
          strengths: strengths,
          weaknesses: [...weaknesses, item],
          opportunities: opportunities,
          threats: threats,
        );
      case SwotCategory.opportunity:
        return SwotMatrix(
          strengths: strengths,
          weaknesses: weaknesses,
          opportunities: [...opportunities, item],
          threats: threats,
        );
      case SwotCategory.threat:
        return SwotMatrix(
          strengths: strengths,
          weaknesses: weaknesses,
          opportunities: opportunities,
          threats: [...threats, item],
        );
    }
  }

  SwotMatrix merge(SwotMatrix other) => SwotMatrix(
    strengths: [...strengths, ...other.strengths],
    weaknesses: [...weaknesses, ...other.weaknesses],
    opportunities: [...opportunities, ...other.opportunities],
    threats: [...threats, ...other.threats],
  );

  Map<String, dynamic> toJson() => {
    'strengths': strengths.map((item) => item.toJson()).toList(),
    'weaknesses': weaknesses.map((item) => item.toJson()).toList(),
    'opportunities': opportunities.map((item) => item.toJson()).toList(),
    'threats': threats.map((item) => item.toJson()).toList(),
  };

  /// Tolerant decoder: each quadrant independently falls back to `[]` if
  /// missing or malformed, so a partially-corrupt saved/imported file still
  /// recovers whatever quadrants are intact rather than failing outright.
  ///
  /// Nested maps from Hive arrive as `Map<dynamic, dynamic>` (only the
  /// top-level `Map.from` in [HiveAnalysisHistoryRepository.loadAll]
  /// retypes keys). Filtering with `whereType<Map<String, dynamic>>()`
  /// silently dropped every SWOT item on cold start — theme/goal (plain
  /// strings) survived, so the dashboard showed「なし」across all four
  /// quadrants. Match [Project.fromJson]'s `whereType<Map>()` +
  /// `Map<String, dynamic>.from` pattern.
  factory SwotMatrix.fromJson(Map<String, dynamic> json) {
    List<SwotItem> parseQuadrant(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      final items = <SwotItem>[];
      for (final entry in raw.whereType<Map>()) {
        try {
          items.add(
            SwotItem.fromJson(Map<String, dynamic>.from(entry)),
          );
        } on FormatException {
          // Skip one bad item rather than emptying the whole quadrant.
        }
      }
      return items;
    }

    return SwotMatrix(
      strengths: parseQuadrant('strengths'),
      weaknesses: parseQuadrant('weaknesses'),
      opportunities: parseQuadrant('opportunities'),
      threats: parseQuadrant('threats'),
    );
  }
}
