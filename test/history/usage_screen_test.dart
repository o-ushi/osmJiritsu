import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/history/screens/usage_screen.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/l10n/app_strings.dart';

import '../support/in_memory_app_language_repository.dart';

Future<void> pumpScreen(
  WidgetTester tester, {
  AppLanguage lang = AppLanguage.japanese,
  required ValueChanged<bool> onContinue,
}) async {
  // Tall enough that every row (image, copy text, checkbox, CTA) renders
  // without scrolling.
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(lang),
        ),
      ],
      // UsageScreen has no Scaffold of its own — like `_StartScreen`, it's
      // meant to sit inside `HistoryListScreen`'s Scaffold.
      child: MaterialApp(
        home: Scaffold(body: UsageScreen(lang: lang, onContinue: onContinue)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the heading, copy instructions, ••• hint, checkbox, image, and CTA',
    (tester) async {
      await pumpScreen(tester, onContinue: (_) {});

      expect(find.text('使い方'), findsOneWidget);
      expect(find.textContaining('コピーボタンをタップしてください'), findsOneWidget);
      expect(find.textContaining('•••ボタンを長押しすると'), findsOneWidget);
      expect(find.text('次回から表示しない'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('ホーム画面へ'), findsOneWidget);

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/chrome_ai_copy_button.png',
      );
    },
  );

  testWidgets('"ホーム画面へ" reports the checkbox state via onContinue', (
    tester,
  ) async {
    bool? received;
    await pumpScreen(tester, onContinue: (value) => received = value);

    await tester.tap(find.text('ホーム画面へ'));
    await tester.pump();
    expect(received, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('ホーム画面へ'));
    await tester.pump();
    expect(received, isTrue);
  });

  for (final lang in AppLanguage.values) {
    testWidgets(
      '${lang.name}: copy instructions mention TAP! without any "red circle" wording',
      (tester) async {
        await pumpScreen(tester, lang: lang, onContinue: (_) {});

        final body = AppStrings.text('使い方_コピー本文', lang);
        expect(body, contains('TAP!'));
        expect(body, isNot(contains('赤丸')));
        expect(body, isNot(contains('red circle')));
        expect(body, isNot(contains('khoanh đỏ')));
      },
    );
  }
}
