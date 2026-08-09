import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/help/screens/help_screen.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';

import '../support/in_memory_app_language_repository.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
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
}
