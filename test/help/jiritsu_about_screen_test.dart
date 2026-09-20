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

      // 「自律の3要素」の見出しと「動機づけマトリクス」は消え、代わりに
      // 動機づけ→外発的動機づけ→内発的動機づけ（3要素を含む）という
      // 動機づけの説明の流れになる。
      expect(find.text('自律の3要素'), findsNothing);
      expect(find.text('動機づけマトリクス'), findsNothing);
      expect(find.byType(Table), findsNothing);
      expect(find.text('内発か？外発か？'), findsNothing);
      expect(find.text('＜メリット・デメリット＞'), findsNothing);
      expect(find.text('他人から言われる前に動く'), findsNothing);
      expect(find.text('ゴールを共有できているか？'), findsNothing);
      expect(find.text('結果が分かりやすいか？'), findsNothing);

      expect(find.text('動機づけ'), findsOneWidget);
      expect(
        find.text(
          '自分で考えて行動するきっかけを動機づけという。動機づけには外発的動機づけと内発的動機づけがある。両者は対立するものではなく組み合わせるもの。外発的動機づけをきっかけに始めて、その内、それ自体が楽しくなる（エンハンシング効果）を狙うと良い。',
        ),
        findsOneWidget,
      );

      expect(find.text('外発的動機づけ'), findsOneWidget);
      expect(
        find.text('報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」による動機づけ。'),
        findsOneWidget,
      );

      expect(find.text('内発的動機づけ'), findsOneWidget);
      expect(
        find.text('自分の内面的な興味・関心、探究心、楽しさなどが原動力となる動機づけ。下記の３要素で構成される。'),
        findsOneWidget,
      );

      // 新しい3つの問い（内発的動機づけの構成要素として表示される）。この
      // 画面はコンテンツが増えたので、Ⅰだけがデフォルトのビューポートに
      // 収まる — Ⅱ/Ⅲ以降は都度スクロールして確認する。
      expect(find.text('自分で決められるか？'), findsOneWidget);
      expect(find.text('Ⅰ'), findsOneWidget);
      expect(find.text('やり方を自分で決めている感覚があるか？'), findsOneWidget);
      expect(find.text('主導権は自分にあるのだと意識できているか？'), findsOneWidget);
      expect(find.text('他人から言われる前に動いているか？'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('成果が分かりやすいか？'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ⅱ'), findsOneWidget);
      expect(
        find.text('自分の能力を発揮できている、自分の成長を実感できているという有能感があるか？'),
        findsOneWidget,
      );
      expect(
        find.text('方策の粒度が細かく、結果を見える化されていて、視覚的に成果を実感できるか？'),
        findsOneWidget,
      );
      expect(find.text('キーワード：小さなくるくる'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('周りと繋がっているか？'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ⅲ'), findsOneWidget);
      expect(find.text('ビジョン、ゴール、日々の進捗状況を周囲と共有できているか？'), findsOneWidget);
      expect(find.text('周囲からサポートが得られるようになっているか？'), findsOneWidget);
      expect(
        find.text('「お役に立ちたい」「当てにされたい」などの承認欲求を満たしているか？'),
        findsOneWidget,
      );
      expect(find.text('言語化されることで思いが現実性をもつ'), findsOneWidget);
      // Cross-reference from the 周り 3要素 card down to its matching
      // キーワード card further below.
      expect(find.text('キーワード：唱って躍れる'), findsOneWidget);

      // 特徴・具体例は内発的動機づけに属する（外発カードの下には出ない）。
      await tester.scrollUntilVisible(
        find.text('＜特徴＞'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。'),
        findsOneWidget,
      );
      // Each ⭕️❌ line splits into its own mark + sentence Text so a
      // wrapped second line indents under the sentence (not the mark).
      expect(find.text('⭕️'), findsOneWidget);
      expect(find.text('モチベーションが長持ちする'), findsOneWidget);
      expect(find.text('❌'), findsNWidgets(2));
      expect(find.text('本人の興味に依存するため即効性がない'), findsOneWidget);
      expect(find.text('誰にでも同じように適用することは困難'), findsOneWidget);
      expect(find.text('＜具体例＞'), findsOneWidget);
      expect(find.text('興味のある分野について自主的に深く調べる。'), findsOneWidget);
      expect(find.text('純粋に人を喜ばせたくて仕事に取り組む。'), findsOneWidget);

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
