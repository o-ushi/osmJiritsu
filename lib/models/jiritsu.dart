/// Core domain definition of "自律" (autonomy) for osmJiritsu.
///
/// This file intentionally holds no UI code — it exists so every screen,
/// prompt, and model in the app can refer back to one shared definition
/// instead of re-describing "自律" in its own words.
library;

/// osmJiritsu's working definition of 自律 (autonomy):
///
/// > ゴールと今の状況の差を無くすために、自分で考えて行動すること。
/// > (Acting on your own judgment to close the gap between a goal and the
/// > current situation.)
const jiritsuDefinition =
    'ゴールと今の状況の差を無くすために、自分で考えて行動すること';

/// The three elements of 内発的動機づけ (intrinsic motivation) — 内発度
/// チェック evaluates a decided 方策/行動 against them. Historically
/// introduced as "自律の3要素"; see docs/prompts/02-jiritsu-about-motivation.md
/// for why they're now framed as intrinsic motivation's own components
/// instead.
///
/// Each element is phrased as the yes/no question used to evaluate it —
/// see [JiritsuCheck], which records an answer/score per element.
enum JiritsuElement {
  /// 自分で決められるか？ — Can it be decided by the person themselves,
  /// without waiting on someone else's judgment?
  selfDetermined,

  /// 成果が分かりやすいか？ — Can the person feel their own growth and
  /// ability, with fine-grained, visible progress?
  clearOutcome,

  /// 周りと繋がっているか？ — Can vision/goals/progress be shared with,
  /// and support received from, whoever else is involved (team, client,
  /// mentor, ...)?
  sharedGoal;

  /// Persistence key. Kept stable across app versions.
  String get rawValue {
    switch (this) {
      case JiritsuElement.selfDetermined:
        return 'selfDetermined';
      case JiritsuElement.clearOutcome:
        return 'clearOutcome';
      case JiritsuElement.sharedGoal:
        return 'sharedGoal';
    }
  }

  /// The evaluation question in Japanese, as posed to the user.
  String get question {
    switch (this) {
      case JiritsuElement.selfDetermined:
        return '自分で決められるか？';
      case JiritsuElement.clearOutcome:
        return '成果が分かりやすいか？';
      case JiritsuElement.sharedGoal:
        return '周りと繋がっているか？';
    }
  }

  static JiritsuElement? fromRawValue(String rawValue) {
    switch (rawValue) {
      case 'selfDetermined':
        return JiritsuElement.selfDetermined;
      case 'clearOutcome':
        return JiritsuElement.clearOutcome;
      case 'sharedGoal':
        return JiritsuElement.sharedGoal;
      default:
        return null;
    }
  }
}
