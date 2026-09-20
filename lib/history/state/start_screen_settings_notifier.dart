import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/start_screen_settings_repository.dart';

/// The persisted「起動時にスタート画面を表示」toggle (Settings screen).
///
/// When true (the default, matching osmGradus), [HistoryListScreen] shows
/// the スタート画面 at launch;「はじめる」then reveals the project list
/// (see [startScreenDismissedProvider]). When false — including via the
/// start screen's「次回から表示しない」checkbox — launch goes straight to
/// the list.
final startScreenAlwaysShowProvider =
    NotifierProvider<StartScreenAlwaysShowNotifier, bool>(
      StartScreenAlwaysShowNotifier.new,
    );

class StartScreenAlwaysShowNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(startScreenSettingsRepositoryProvider).load();

  /// 不変条件: `usageScreenAlwaysShow == true` は `startScreenAlwaysShow ==
  /// true` のときだけ許す。設定 UI からだけでなく「はじめる」の
  /// 「次回から表示しない」からもここを通るので、連動をこの setter に置く
  /// ことで両方の経路が同じ不変条件を守る。
  void set(bool value) {
    state = value;
    ref.read(startScreenSettingsRepositoryProvider).save(value);
    if (!value) {
      ref.read(usageScreenAlwaysShowProvider.notifier).set(false);
    }
  }

  /// After a factory reset: in-memory flag matches the cleared store
  /// (default `true`) without writing the key back.
  void applyDefault() => state = true;
}

/// The persisted「はじめるの後に使い方画面を表示」toggle (Settings screen).
///
/// See [StartScreenAlwaysShowNotifier.set] for the invariant that keeps
/// this `false` whenever `startScreenAlwaysShowProvider` is `false`.
final usageScreenAlwaysShowProvider =
    NotifierProvider<UsageScreenAlwaysShowNotifier, bool>(
      UsageScreenAlwaysShowNotifier.new,
    );

class UsageScreenAlwaysShowNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(startScreenSettingsRepositoryProvider).loadUsageAlwaysShow();

  /// Turning this ON while スタート is OFF would violate the invariant
  /// above with no setter left to fix it (unlike the other direction,
  /// which `StartScreenAlwaysShowNotifier.set` handles) — so it's rejected
  /// here directly. The 設定画面 also disables this switch in that case;
  /// this guard is the second line of defense (e.g. against a stray tap
  /// racing a settings change).
  void set(bool value) {
    if (value && !ref.read(startScreenAlwaysShowProvider)) return;
    state = value;
    ref.read(startScreenSettingsRepositoryProvider).saveUsageAlwaysShow(value);
  }

  /// After a factory reset: in-memory flag matches the cleared store
  /// (default `true`) without writing the key back.
  void applyDefault() => state = true;
}

/// Whether `HistoryListScreen` should currently show the 使い方画面 —
/// in-memory only, and deliberately *not* re-derived from
/// [usageScreenAlwaysShowProvider] on every read.
///
/// This has to be a plain session flag, not `alwaysShowUsage && !dismissed`:
/// スタートの「次回から表示しない」can flip `usageScreenAlwaysShow` to
/// `false` (the invariant in [StartScreenAlwaysShowNotifier.set]) in the
/// very same tap that should still land on 使い方 *this* session — so the
/// decision has to be captured from the flag's value before that save, not
/// recomputed from the now-mutated flag. Each `HistoryListScreen`
/// transition (スタートの「はじめる」/ 使い方の「ホーム画面へ」/ 一覧の
/// スワイプ) sets this directly.
final usageScreenSessionShowProvider =
    NotifierProvider<UsageScreenSessionShowNotifier, bool>(
      UsageScreenSessionShowNotifier.new,
    );

class UsageScreenSessionShowNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Whether the user has already tapped「はじめる」past the forced スタート
/// 画面 this launch. Deliberately in-memory only (not persisted) —
/// "起動時に" (at launch) means once per process, not once ever, so a
/// fresh app process (this provider's default) is exactly when it should
/// show again.
final startScreenDismissedProvider =
    NotifierProvider<StartScreenDismissedNotifier, bool>(
      StartScreenDismissedNotifier.new,
    );

class StartScreenDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;

  /// Swiping right on the project list (when 「起動時にスタート画面を
  /// 表示」is on) goes back the other way — undoes [dismiss] so the
  /// スタート画面 shows again without waiting for the next launch.
  void show() => state = false;
}
