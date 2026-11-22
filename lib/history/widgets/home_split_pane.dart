import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Marks the subtree of home's split layout (iPad landscape) and gives it
/// the right pane's own [Navigator]. The dashboard is that navigator's
/// first route, so everything it opens (振り返り, SWOT, 方策, 最初の一歩,
/// 宣言文, …) stays on the right while the project list stays on the left.
///
/// Outside the split (iPhone, portrait, any full-screen route) there is no
/// scope, and callers fall back to the ordinary [Navigator.of].
class HomeSplitScope extends InheritedWidget {
  const HomeSplitScope({
    super.key,
    required this.navigatorKey,
    required super.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  static NavigatorState? _paneOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<HomeSplitScope>()
      ?.navigatorKey
      .currentState;

  /// Where a screen opened from the split's left column (設定 / ヘルプ from
  /// home's …) should be pushed: the right pane when [context] is inside the
  /// split, otherwise the nearest navigator as before.
  static NavigatorState paneOrNavigatorOf(BuildContext context) =>
      _paneOf(context) ?? Navigator.of(context);

  static GlobalKey<NavigatorState>? _activeKey;

  /// The right-pane navigator of the split home that is currently built, if
  /// any — reachable from routes above home (which aren't inside the scope),
  /// so a full-screen screen can move itself into the split.
  static NavigatorState? get activePane => _activeKey?.currentState;

  /// Called by the split home while it is built; see [activePane].
  static void registerActivePane(GlobalKey<NavigatorState> key) =>
      _activeKey = key;

  static void unregisterActivePane(GlobalKey<NavigatorState> key) {
    if (_activeKey == key) _activeKey = null;
  }

  /// The right pane to open a screen in from [context]: the pane [context]
  /// is inside, or — from home's own route, which sits above the scope —
  /// the split that home is currently showing. Null when not split.
  static NavigatorState? paneFor(BuildContext context) =>
      _paneOf(context) ??
      (ModalRoute.of(context)?.isFirst == true ? activePane : null);

  /// Whether [context] sits inside home's split.
  static bool isActive(BuildContext context) => _paneOf(context) != null;

  /// Pops everything opened in the right pane, back to the dashboard (or
  /// the empty state). No-op outside the split.
  static void closePane(BuildContext context) {
    _paneOf(context)?.popUntil((route) => route.isFirst);
  }

  @override
  bool updateShouldNotify(HomeSplitScope oldWidget) =>
      navigatorKey != oldWidget.navigatorKey;
}

/// The split's right pane: a navigator whose first route is [base] (the
/// dashboard or the empty state). [base] must pick up selection changes on
/// its own — the route is built once and isn't rebuilt by this widget.
class HomeSplitPane extends StatefulWidget {
  const HomeSplitPane({
    super.key,
    required this.navigatorKey,
    required this.base,
    required this.hasOpenScreens,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget base;

  /// Set to true while anything is pushed above [base].
  final ValueNotifier<bool> hasOpenScreens;

  @override
  State<HomeSplitPane> createState() => _HomeSplitPaneState();
}

class _HomeSplitPaneState extends State<HomeSplitPane> {
  late final _observer = _DepthObserver((depth) {
    void apply() => widget.hasOpenScreens.value = depth > 1;
    // Route changes can be reported mid-build; listeners may rebuild.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  });

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    return Navigator(
      key: widget.navigatorKey,
      observers: [_observer],
      onGenerateInitialRoutes: (_, _) => [
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => base,
        ),
      ],
    );
  }
}

class _DepthObserver extends NavigatorObserver {
  _DepthObserver(this.onChanged);

  final ValueChanged<int> onChanged;
  int _depth = 0;

  void _set(int depth) {
    _depth = depth;
    onChanged(depth);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(_depth + 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(_depth - 1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(_depth - 1);
}
