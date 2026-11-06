import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/help/screens/help_screen.dart';
import 'package:osm_jiritsu/privacy/screens/privacy_screen.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';
import 'package:osm_jiritsu/l10n/app_strings.dart';

import '../support/in_memory_app_language_repository.dart';

Future<void> pumpScreen(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.japanese,
}) async {
  tester.view.physicalSize = const Size(1200, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
  testWidgets('renders hero with app icon and title', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('osmJiritsu'), findsOneWidget);
  });

  testWidgets('「自律とは」 is just a link — no definition or 3要素 duplicated here', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('自律とは'), findsOneWidget);
    expect(find.text('ゴールと今の状況の差を無くすために、自分で考えて行動すること'), findsNothing);
    expect(find.text('自律の3要素'), findsNothing);
    expect(find.text('自分で決められるか？'), findsNothing);
  });

  testWidgets('進捗度の一覧は、カードを開くと出る', (tester) async {
    await pumpScreen(tester);
    expect(find.text('20%　ゴール設定済み'), findsNothing);

    await tester.tap(find.text('簡易モードの進捗度を見る'));
    await tester.pumpAndSettle();
    expect(find.text('20%　ゴール設定済み'), findsOneWidget);
    expect(find.text('100%　ゴール達成済み'), findsOneWidget);

    await tester.tap(find.text('フルモードの進捗度を見る'));
    await tester.pumpAndSettle();
    expect(find.text('10%　テーマ設定済み'), findsOneWidget);
    expect(find.text('100%　完了'), findsOneWidget);
  });

  testWidgets('マニュアルは無く、節を開くと番号順の手順が出て、プライバシーを開ける', (tester) async {
    await pumpScreen(tester);
    expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
    expect(find.text('help.start.1'.tr(AppLanguage.japanese)), findsNothing);

    await tester.tap(find.text('案件を始める'));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('help-section-start'));
    for (var i = 1; i <= 2; i++) {
      expect(
        find.descendant(of: card, matching: find.text('$i')),
        findsOneWidget,
      );
    }
    expect(find.text('help.start.1'.tr(AppLanguage.japanese)), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('help-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help-privacy')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  for (final language in AppLanguage.values) {
    test('${language.name}: 手順の文言があり短い', () {
      const counts = {
        'start': 2,
        'lines': 2,
        'goal': 1,
        'reflect': 2,
        'share': 2,
        'howto': 1,
        'copy': 2,
        'backup': 2,
        'icloud': 1,
      };
      for (final MapEntry(key: id, value: count) in counts.entries) {
        for (final key in [
          'help.$id.title',
          for (var i = 1; i <= count; i++) 'help.$id.$i',
        ]) {
          final text = key.tr(language);
          expect(text, isNot(key), reason: key);
          expect(text.length, lessThanOrEqualTo(80), reason: key);
        }
      }
    });
  }
}
