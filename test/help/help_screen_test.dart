import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:osm_jiritsu/help/screens/help_screen.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/l10n/app_strings.dart';

import '../support/in_memory_app_language_repository.dart';

Future<void> pumpScreen(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.japanese,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(language),
        ),
      ],
      child: const MaterialApp(home: HelpScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('操作マニュアルURLは言語ごとに固定のpreview先を返す', () {
    expect(
      HelpScreen.userManualUrlFor(AppLanguage.japanese),
      'https://docs.google.com/presentation/d/'
      '${HelpScreen.userManualPresentationIdJa}/preview',
    );
    expect(
      HelpScreen.userManualUrlFor(AppLanguage.english),
      'https://docs.google.com/presentation/d/'
      '${HelpScreen.userManualPresentationIdEn}/preview',
    );
    expect(
      HelpScreen.userManualUrlFor(AppLanguage.vietnamese),
      'https://docs.google.com/presentation/d/'
      '${HelpScreen.userManualPresentationIdVi}/preview',
    );
  });

  testWidgets('renders hero with app icon and title', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('osmJiritsu'), findsOneWidget);
  });

  testWidgets(
    '「自律とは」 is just a link — no definition or 3要素 duplicated here',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('自律とは'), findsOneWidget);
      expect(
        find.text('ゴールと今の状況の差を無くすために、自分で考えて行動すること'),
        findsNothing,
      );
      expect(find.text('自律の3要素'), findsNothing);
      expect(find.text('自分で決められるか？'), findsNothing);
    },
  );

  testWidgets('renders progress milestone guide', (tester) async {
    await pumpScreen(tester);

    await tester.scrollUntilVisible(
      find.text('進捗度の見方'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('10%　テーマ設定済み'), findsOneWidget);
    expect(find.text('100%　完了'), findsOneWidget);
  });

  testWidgets('操作マニュアルをタップすると表示言語のGoogleスライドが開く', (tester) async {
    final original = UrlLauncherPlatform.instance;
    final fake = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fake;
    addTearDown(() => UrlLauncherPlatform.instance = original);

    await pumpScreen(tester, language: AppLanguage.english);

    expect(
      find.text('操作マニュアル'.tr(AppLanguage.english)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('help_user_manual')));
    await tester.pumpAndSettle();

    expect(fake.launched, [HelpScreen.userManualUrlFor(AppLanguage.english)]);
    expect(
      HelpScreen.userManualUrlFor(AppLanguage.english),
      endsWith('/preview'),
    );
  });
}

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
