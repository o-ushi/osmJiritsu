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

  void set(bool value) {
    state = value;
    ref.read(startScreenSettingsRepositoryProvider).save(value);
  }

  /// After a factory reset: in-memory flag matches the cleared store
  /// (default `true`) without writing the key back.
  void applyDefault() => state = true;
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
