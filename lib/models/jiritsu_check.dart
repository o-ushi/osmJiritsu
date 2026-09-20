import 'jiritsu.dart';

/// A yes/no evaluation of the [JiritsuElement] 内発的動機づけの3要素 for
/// one 案件 (project) at a point in time — the domain model behind
/// 内発度チェック (formerly「自律度チェック」; see
/// docs/prompts/04-intrinsic-check.md).
///
/// Kept as three plain booleans (mirrors the yes/no phrasing of each
/// [JiritsuElement.question]) rather than a `Map<JiritsuElement, bool>` so
/// JSON encode/decode stays trivial and the shape matches how
/// `AnalysisTone` exposes its own scalar knobs as named fields.
class JiritsuCheck {
  /// 自分で決められるか？
  final bool selfDetermined;

  /// 成果が分かりやすいか？ — JSON field name (`clearOutcome`) kept stable
  /// for compatibility; only the user-facing question text changed.
  final bool clearOutcome;

  /// 周りと繋がっているか？ — JSON field name (`sharedGoal`) kept stable
  /// for compatibility; only the user-facing question text changed.
  final bool sharedGoal;

  const JiritsuCheck({
    this.selfDetermined = false,
    this.clearOutcome = false,
    this.sharedGoal = false,
  });

  /// All three elements unanswered/unmet.
  static const none = JiritsuCheck();

  /// How many of the three elements are currently satisfied (0–3).
  int get satisfiedCount =>
      [selfDetermined, clearOutcome, sharedGoal].where((v) => v).length;

  /// Fraction of the three elements satisfied, as 0.0–1.0.
  double get score => satisfiedCount / JiritsuElement.values.length;

  /// True only when every element is satisfied — i.e. the action/案件
  /// meets osmJiritsu's definition of 自律的 in full.
  bool get isFullyAutonomous => satisfiedCount == JiritsuElement.values.length;

  bool answerFor(JiritsuElement element) {
    switch (element) {
      case JiritsuElement.selfDetermined:
        return selfDetermined;
      case JiritsuElement.clearOutcome:
        return clearOutcome;
      case JiritsuElement.sharedGoal:
        return sharedGoal;
    }
  }

  JiritsuCheck copyWith({
    bool? selfDetermined,
    bool? clearOutcome,
    bool? sharedGoal,
  }) {
    return JiritsuCheck(
      selfDetermined: selfDetermined ?? this.selfDetermined,
      clearOutcome: clearOutcome ?? this.clearOutcome,
      sharedGoal: sharedGoal ?? this.sharedGoal,
    );
  }

  Map<String, dynamic> toJson() => {
    'selfDetermined': selfDetermined,
    'clearOutcome': clearOutcome,
    'sharedGoal': sharedGoal,
  };

  /// Tolerant decoder: any missing/malformed field defaults to `false`
  /// (i.e. "not yet satisfied") rather than throwing.
  factory JiritsuCheck.fromJson(Map<String, dynamic> json) {
    return JiritsuCheck(
      selfDetermined: json['selfDetermined'] as bool? ?? false,
      clearOutcome: json['clearOutcome'] as bool? ?? false,
      sharedGoal: json['sharedGoal'] as bool? ?? false,
    );
  }
}
