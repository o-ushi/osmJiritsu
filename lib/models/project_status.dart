/// The lifecycle status of a 案件 (project/engagement) in osmJiritsu.
///
/// Distinct from any AI-analysis state — this tracks where the underlying
/// work itself stands, independent of whether a SWOT analysis has been run
/// for it.
enum ProjectStatus {
  /// 作成中 — being set up (goal/theme not finalized yet).
  preparing,

  /// 実施中 — actively being worked on.
  inProgress,

  /// 休憩中 — paused; work is not currently moving.
  onBreak,

  /// 完了 — done.
  completed;

  /// Persistence key. Kept stable across app versions.
  String get rawValue {
    switch (this) {
      case ProjectStatus.preparing:
        return 'preparing';
      case ProjectStatus.inProgress:
        return 'inProgress';
      case ProjectStatus.onBreak:
        return 'onBreak';
      case ProjectStatus.completed:
        return 'completed';
    }
  }

  /// Japanese label shown to the user.
  String get displayName {
    switch (this) {
      case ProjectStatus.preparing:
        return '作成中';
      case ProjectStatus.inProgress:
        return '実施中';
      case ProjectStatus.onBreak:
        return '休憩中';
      case ProjectStatus.completed:
        return '完了';
    }
  }

  static ProjectStatus? fromRawValue(String rawValue) {
    switch (rawValue) {
      case 'preparing':
        return ProjectStatus.preparing;
      case 'inProgress':
        return ProjectStatus.inProgress;
      case 'onBreak':
        return ProjectStatus.onBreak;
      case 'completed':
        return ProjectStatus.completed;
      default:
        return null;
    }
  }
}
