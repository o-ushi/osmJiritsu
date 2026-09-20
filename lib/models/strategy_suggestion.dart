import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One AI-proposed 方策 (strategy) from Stage1 Step 5's "Chrome AIモードで
/// 方策発散" — the model is asked for 5 of these directly from the user's
/// テーマ/ゴール/SWOT, each meant to satisfy 内発的動機づけの3要素 as much
/// as possible (自分で決められるか？/成果が分かりやすいか？/周りと繋がって
/// いるか？).
///
/// Deliberately simpler than the old pre-Stage1 `StrategyProposal` (title +
/// structured `ActionDetail` breakdown + priority, since removed as dead
/// code — see `AnalysisEngine`'s doc comment): these 5 suggestions are
/// meant to be freely read, combined, and edited by the user in Step 6, not
/// treated as a structured plan in their own right — see [Project.aiStrategySuggestions]
/// (kept for reference only) and [Project.decidedStrategy] (the user's own
/// final wording, which is what actually matters going forward).
class StrategySuggestion {
  final String id;

  /// The 方策 itself: a concrete, actionable strategy statement.
  final String text;

  /// Why this strategy would close the gap to the goal, referencing the
  /// SWOT evidence it was drawn from.
  final String rationale;

  StrategySuggestion({String? id, required this.text, this.rationale = ''})
    : id = id ?? _uuid.v4();

  /// Rewords this suggestion in place (see Step 6's 長押しで編集) — keeps
  /// [id] so `StrategyFlowDeciding.adoptedSuggestionIds` still matches it
  /// after editing.
  StrategySuggestion copyWith({String? text, String? rationale}) =>
      StrategySuggestion(
        id: id,
        text: text ?? this.text,
        rationale: rationale ?? this.rationale,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'rationale': rationale,
  };

  factory StrategySuggestion.fromJson(Map<String, dynamic> json) =>
      StrategySuggestion(
        id: json['id'] as String?,
        text: (json['text'] as String? ?? '').trim(),
        rationale: (json['rationale'] as String? ?? '').trim(),
      );

  @override
  bool operator ==(Object other) =>
      other is StrategySuggestion &&
      other.id == id &&
      other.text == text &&
      other.rationale == rationale;

  @override
  int get hashCode => Object.hash(id, text, rationale);
}
