import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language_notifier.dart';
import 'history_toolbar_actions.dart';

/// Longest テーマ accepted from a link (grapheme clusters) — the same cap
/// osmNichinichi puts on its Someday-list titles.
const incomingThemeMaxLength = 80;

/// Reads the テーマ out of an `osmjiritsu://new?theme=<title>` link.
///
/// Returns null — open nothing, stay on the usual home — when the scheme
/// is not `osmjiritsu`, the host is not `new`, or `theme` is missing or
/// blank. The theme is trimmed and cut to [incomingThemeMaxLength].
String? themeFromIncomingUrl(String url) {
  final Uri uri;
  try {
    uri = Uri.parse(url);
  } on FormatException {
    return null;
  }
  if (uri.scheme != 'osmjiritsu' || uri.host != 'new') return null;
  final String? raw;
  try {
    raw = uri.queryParameters['theme'];
  } on FormatException {
    return null;
  }
  final theme = raw?.trim() ?? '';
  if (theme.isEmpty) return null;
  final chars = theme.characters;
  return chars.length <= incomingThemeMaxLength
      ? theme
      : chars.take(incomingThemeMaxLength).toString().trimRight();
}

/// Listens on `com.osamushikubo.osmjiritsu/incoming_url` for links that
/// opened the app (cold start: `takeInitialUrl`; already running: the
/// native side calls `onUrl`) and starts a new 案件 with that テーマ through
/// [HistoryToolbarActions.startNew] — the same 簡易 / フル choice as the
/// toolbar ＋.
class IncomingUrlHandler extends ConsumerStatefulWidget {
  const IncomingUrlHandler({super.key, required this.child});

  final Widget child;

  static const channel = MethodChannel(
    'com.osamushikubo.osmjiritsu/incoming_url',
  );

  @override
  ConsumerState<IncomingUrlHandler> createState() =>
      _IncomingUrlHandlerState();
}

class _IncomingUrlHandlerState extends ConsumerState<IncomingUrlHandler> {
  @override
  void initState() {
    super.initState();
    IncomingUrlHandler.channel.setMethodCallHandler((call) async {
      if (call.method == 'onUrl' && call.arguments is String) {
        _handle(call.arguments as String);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeInitial());
  }

  @override
  void dispose() {
    IncomingUrlHandler.channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _takeInitial() async {
    try {
      // The native side forgets the link once handed over, so a rebuild
      // or hot restart never opens it twice.
      final url = await IncomingUrlHandler.channel.invokeMethod<String>(
        'takeInitialUrl',
      );
      if (url != null) _handle(url);
    } on MissingPluginException {
      // macOS / tests: no channel.
    } on PlatformException {
      // Nothing to open.
    }
  }

  void _handle(String url) {
    final theme = themeFromIncomingUrl(url);
    if (theme == null || !mounted) return;
    final lang = ref.read(appLanguageProvider);
    HistoryToolbarActions(ref, lang).startNew(context, theme: theme);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
