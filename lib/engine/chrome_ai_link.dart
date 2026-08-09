import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds a link to Google Search's "AI Mode" (`udm=50`) with a prompt
/// pre-filled as the query.
///
/// This is the same "throw the prompt at Chrome's AI mode instead of
/// calling a paid API" pattern used by osmGenki's `GoogleAiLink` /
/// `ChromeAiPrompts`: no API key, no quota, no per-request billing — the
/// trade-off is that the answer comes back via the user copying it out of
/// the browser and pasting it into the app, rather than a programmatic
/// response (see `AnalysisEngine.parseStrategyResponse` /
/// `parseFirstStepResponse`, which already tolerate prose/code-fence-wrapped
/// JSON for exactly this reason).
abstract final class ChromeAiLink {
  /// Google's URL length limits mean extremely long prompts (a huge SWOT
  /// matrix) can't always fit in the query string; past this length we
  /// fall back to opening bare AI Mode and let the user paste the prompt
  /// in themselves (it's already been copied to the clipboard by the
  /// caller — see `StrategyFlowNotifier.openInChromeAiMode`).
  static const _maxUrlLength = 7500;

  static Uri webSearchUrl({required String prompt, String hl = 'ja'}) {
    final uri = Uri.https('www.google.co.jp', '/search', {
      'q': prompt.trim(),
      'udm': '50',
      'hl': hl,
      'gl': 'jp',
      'ie': 'UTF-8',
    });
    if (uri.toString().length <= _maxUrlLength) return uri;
    return Uri.https('www.google.co.jp', '/search', {
      'udm': '50',
      'hl': hl,
      'gl': 'jp',
    });
  }

  /// Opens [prompt] in Google AI Mode via a plain `https://` link, in
  /// whatever the OS's default browser is (Safari, Chrome, or otherwise).
  ///
  /// An earlier version tried the `googlechromes://` custom scheme first
  /// to force Chrome specifically, but that requires declaring the scheme
  /// in `LSApplicationQueriesSchemes` (iOS `Info.plist`) — without it,
  /// `canLaunchUrl` can throw rather than just returning `false`, which is
  /// exactly what surfaced as "Chromeを開けませんでした" on a simulator
  /// with no Chrome installed. AI Mode is a regular webpage; it works the
  /// same in any browser, so there's nothing Chrome-specific to insist on.
  static Future<bool> openWithPrompt(String prompt, {String hl = 'ja'}) async {
    final web = webSearchUrl(prompt: prompt, hl: hl);
    return launchUrl(web, mode: LaunchMode.externalApplication);
  }
}

/// Seam between `StrategyFlowNotifier` and [ChromeAiLink], so tests can
/// swap in a fake that records calls instead of actually launching a
/// browser.
abstract class ChromeAiLauncher {
  Future<void> openWithPrompt(String prompt);
}

class UrlLauncherChromeAiLauncher implements ChromeAiLauncher {
  const UrlLauncherChromeAiLauncher();

  @override
  Future<void> openWithPrompt(String prompt) =>
      ChromeAiLink.openWithPrompt(prompt);
}

final chromeAiLauncherProvider = Provider<ChromeAiLauncher>((ref) {
  return const UrlLauncherChromeAiLauncher();
});
