import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/help/screens/help_screen.dart';
import 'package:osm_jiritsu/help/screens/jiritsu_about_screen.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_language_repository.dart';

import '../support/in_memory_app_language_repository.dart';

Future<void> pumpScreen(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLanguageRepositoryProvider.overrideWithValue(
          InMemoryAppLanguageRepository(AppLanguage.japanese),
        ),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping the 自律とは lead card on HELP opens the dedicated screen', (
    tester,
  ) async {
    await pumpScreen(tester, const HelpScreen());

    await tester.tap(find.text('自律とは'));
    await tester.pumpAndSettle();

    expect(find.byType(JiritsuAboutScreen), findsOneWidget);
    expect(find.text('自律の定義'), findsOneWidget);
  });

  testWidgets(
    'renders the definition, 3要素, motivation matrix, and keyword explanations',
    (tester) async {
      await pumpScreen(tester, const JiritsuAboutScreen());

      expect(find.text('自律の定義'), findsOneWidget);
      expect(
        find.text('ゴールと今の状況の差を無くすために、自分で考えて行動すること'),
        findsOneWidget,
      );

      expect(find.text('（参考）自立とは'), findsOneWidget);
      expect(find.text('自分以外の何ものにも依存しない状態。'), findsOneWidget);
      expect(
        find.text('自律できていない人にありがちな行動'),
        findsOneWidget,
      );
      expect(find.text('言われたことだけやる'), findsOneWidget);
      expect(find.text('不平、不満ばっかり'), findsOneWidget);
      expect(find.text('無感動、無関心'), findsOneWidget);
      expect(
        find.text('できない理由だけで、どうすればできるか？がない'),
        findsOneWidget,
      );
      expect(
        find.text('一見クールでカッコよく見えたりする。的を射てるし。周囲を白けさせるパワー大。口癖は「でもさ...」'),
        findsOneWidget,
      );

      expect(find.text('自律の3要素'), findsOneWidget);
      expect(find.text('自分で決められるか？'), findsOneWidget);
      // The one-line summary that used to repeat right below the question
      // ("自分の意思で決められる" etc.) is gone — only the question and the
      // new concrete tips remain.
      expect(find.text('自分の意思で決められる'), findsNothing);
      expect(find.text('結果が見えやすい'), findsNothing);
      expect(find.text('ゴールを共有できる'), findsNothing);
      expect(
        find.text('誰かの判断を待たず、自分の意思で決められること。'),
        findsNothing,
      );
      expect(find.text('他人から言われる前に動く'), findsOneWidget);
      expect(find.text('主導権は自分にあるのだと意識すること'), findsOneWidget);
      expect(find.text('方策の粒度を細かくすること'), findsOneWidget);
      expect(find.text('結果を見える化して視覚的に成果を実感すること'), findsOneWidget);
      expect(find.text('周囲からサポートを得る'), findsOneWidget);
      expect(find.text('言語化することで思いが現実性を持つ'), findsOneWidget);
      // Cross-references from the clearOutcome/sharedGoal 3要素 cards down
      // to their matching キーワード card further below.
      expect(find.text('キーワード：小さなくるくる'), findsOneWidget);
      expect(find.text('キーワード：唱って躍れる'), findsOneWidget);

      expect(find.text('動機づけマトリクス'), findsOneWidget);
      expect(
        find.text('方策を考える際、動機づけマトリクスを意識すると良い。'),
        findsOneWidget,
      );
      // '内発的動機づけ'/'外発的動機づけ' appear both as the explanation's
      // section headings below the matrix (unbroken) and as the matrix's
      // own row labels — the latter wrap onto their own line right before
      // 動機づけ so this narrow column never breaks mid-word.
      expect(find.text('内発的動機づけ'), findsOneWidget);
      expect(find.text('外発的動機づけ'), findsOneWidget);
      expect(find.text('内発的\n動機づけ'), findsOneWidget);
      expect(find.text('外発的\n動機づけ'), findsOneWidget);
      expect(find.text('内発か？外発か？'), findsOneWidget);
      expect(
        find.text('自分の内面的な興味・関心、探究心、楽しさなどが原動力となる状態。'),
        findsOneWidget,
      );
      expect(find.text('興味のある分野について自主的に深く調べる。'), findsOneWidget);
      expect(find.text('⭕️ モチベーションが長持ちする'), findsOneWidget);
      // Ⅰ/Ⅱ/Ⅲ appear as both the 3要素 cards' badges and the matrix's
      // column headers, so there are 2 of each.
      expect(find.text('Ⅰ'), findsNWidgets(2));
      expect(find.text('Ⅱ'), findsNWidgets(2));
      expect(find.text('Ⅲ'), findsNWidgets(2));
      // Regression check for the matrix rendering as a blank area: the
      // Table must actually take up real vertical space, not collapse to
      // (near) zero — see the `TableCellVerticalAlignment.fill` +
      // `IntrinsicHeight` conflict this once broke.
      expect(tester.getSize(find.byType(Table)).height, greaterThan(100));

      await tester.scrollUntilVisible(
        find.text('キーワード'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('キーワード'), findsOneWidget);
      expect(find.text('小さなくるくる'), findsOneWidget);
      expect(find.text('実行のステップを細かくして達成感を感じやすくすること。'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('唱って躍れる'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('唱って躍れる'), findsOneWidget);
      expect(
        find.textContaining('つまり「唱って躍れる」とは'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('― 伊藤守「リーダーになる人ならない人」'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('― 伊藤守「リーダーになる人ならない人」'), findsOneWidget);
      expect(
        find.textContaining('誰かに話すことによって自分の中で漠然としていた夢が'),
        findsOneWidget,
      );
    },
  );
}
