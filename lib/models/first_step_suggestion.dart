import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One AI-proposed 最初の一歩 from Stage1 Step 9 — a single action small
/// enough to start tomorrow and finish within 30 minutes, meant to kick
/// off the user's already-decided 方策.
///
/// Deliberately just a bare `text` (no `rationale` like [StrategySuggestion]
/// carries): the essence prompt asks for 10 concrete actions, not 10
/// justified ones — Step 10's decision is about picking/combining/rewriting
/// one of these, not evaluating each against the SWOT again.
class FirstStepSuggestion {
  final String id;
  final String text;

  FirstStepSuggestion({String? id, required this.text}) : id = id ?? _uuid.v4();

  /// Rewords this suggestion in place (see Step 10's 長押しで編集) — keeps
  /// [id] so `FirstStepFlowDeciding.adoptedSuggestionIds` still matches it
  /// after editing.
  FirstStepSuggestion copyWith({String? text}) =>
      FirstStepSuggestion(id: id, text: text ?? this.text);

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory FirstStepSuggestion.fromJson(Map<String, dynamic> json) =>
      FirstStepSuggestion(
        id: json['id'] as String?,
        text: (json['text'] as String? ?? '').trim(),
      );

  @override
  bool operator ==(Object other) =>
      other is FirstStepSuggestion && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(id, text);
}
