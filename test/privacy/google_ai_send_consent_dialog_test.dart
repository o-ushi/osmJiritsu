import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/privacy/google_ai_send_consent_dialog.dart';
import 'package:osm_jiritsu/privacy/screens/privacy_screen.dart';
import 'package:osm_jiritsu/theme/app_theme.dart';

class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launched = [];

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, dynamic> headers,
    String? webOnlyWindowName,
  }) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late _FakeUrlLauncher launcher;

  setUp(() {
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  testWidgets(
    'shows disclosure, Google policy link, and Gradus-equivalent CTA',
    (tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  result = GoogleAiSendConsentDialog.confirm(
                    context,
                    lang: AppLanguage.japanese,
                    titleKey: '方策_Google送信確認_タイトル',
                    bodyKey: '方策_Google送信確認_本文',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('方策提案のためGoogleに送信しますか？'), findsOneWidget);
      expect(find.text('同意してGoogleへ送信'), findsOneWidget);
      expect(find.text('Google プライバシーポリシー'), findsOneWidget);

      await tester.tap(find.text('Google プライバシーポリシー'));
      await tester.pumpAndSettle();
      expect(launcher.launched, [PrivacyScreen.googlePrivacyUrl]);

      await tester.tap(find.text('同意してGoogleへ送信'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    },
  );

  testWidgets('cancel returns false without sending', (tester) async {
    late Future<bool> result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                result = GoogleAiSendConsentDialog.confirm(
                  context,
                  lang: AppLanguage.japanese,
                  titleKey: '最初の一歩_Google送信確認_タイトル',
                  bodyKey: '最初の一歩_Google送信確認_本文',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });
}
