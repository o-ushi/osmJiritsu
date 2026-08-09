import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/jiritsu.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/subpage_scaffold.dart';
import '../widgets/help_cards.dart';

/// Body content for one [JiritsuAboutScreen._keywords] entry — takes the
/// card's own accent color rather than picking a new one, so richer
/// entries (like 唱って躍れる's kanji breakdown) can still use it for a
/// highlight without growing the screen's text-color palette.
typedef _KeywordBody = Widget Function(AppLanguage lang, Color accentColor);

/// Thin neutral rule used to break up long prose into skimmable chunks —
/// the same border color already used for card outlines and table lines
/// on this screen, not a new color.
Widget _sectionDivider() => Padding(
  padding: const EdgeInsets.symmetric(vertical: 14),
  child: Container(height: 1, color: const Color(0xFFE1F0EA)),
);

/// Dedicated「自律とは」screen, linked from [HelpScreen]'s lead card.
/// Covers the full picture in one place: the definition, 自律の3要素, a
/// 動機づけマトリクス (3要素 × 内発的/外発的動機づけ) for turning them
/// into concrete strategies, and an explanation of each onboarding
/// キーワード.
class JiritsuAboutScreen extends ConsumerWidget {
  const JiritsuAboutScreen({super.key});

  static const _numerals = ['Ⅰ', 'Ⅱ', 'Ⅲ'];

  /// Behaviors typical of someone who isn't 自律的 — rendered as a plain
  /// bullet list right below the reference note on 自立, so the screen
  /// moves from "what 自律/自立 mean" straight into "what it looks like
  /// when they're missing" before getting to the actionable 3要素 below.
  static const _nonJiritsuBehaviors = [
    '言われたことだけやる',
    '不平、不満ばっかり',
    '無感動、無関心',
    'できない理由だけで、どうすればできるか？がない',
  ];

  /// Concrete tips for putting each of [JiritsuElement] into practice —
  /// indexed the same as `JiritsuElement.values`/[_numerals]/[_accentFor].
  static const _elementTips = [
    ['他人から言われる前に動く', '主導権は自分にあるのだと意識すること'],
    ['方策の粒度を細かくすること', '結果を見える化して視覚的に成果を実感すること'],
    ['周囲からサポートを得る', '言語化することで思いが現実性を持つ'],
  ];

  /// Cross-references from a 3要素 card down to its matching キーワード
  /// card below — same indexing as [_elementTips]; `null` where an
  /// element has no matching keyword. Rendered in the card's own
  /// [_accentFor] color rather than a color of its own, to keep the
  /// screen's text palette small.
  static const List<String?> _elementKeywords = [
    null,
    '小さなくるくる',
    '唱って躍れる',
  ];

  static const List<({String title, Color accentColor, _KeywordBody body})>
  _keywords = [
    (
      title: '小さなくるくる',
      accentColor: AppPalette.strength,
      body: _simpleKeywordBody,
    ),
    (
      title: '唱って躍れる',
      accentColor: AppPalette.opportunity,
      body: _utatteOdoreruBody,
    ),
  ];

  static Widget _simpleKeywordBody(AppLanguage lang, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            'assets/images/chiisana_kurukuru.jpg',
            height: 130,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '実行のステップを細かくして達成感を感じやすくすること。'.tr(lang),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppPalette.subpageTextMuted,
          ),
        ),
      ],
    );
  }

  /// 唱/躍 each get their own reading, a short etymology, and a one-line
  /// 義 (gloss) — broken into their own text blocks (rather than one long
  /// paragraph) so the kanji/reading reads as a heading, the etymology as
  /// supporting detail, and the 義 line stands out as the takeaway for
  /// that character. A divider separates 唱 from 躍, and the closing
  /// "つまり…" sentence gets a soft accent-tinted box so it reads as the
  /// payoff of the whole card without introducing a new text color.
  static Widget _utatteOdoreruBody(AppLanguage lang, Color accentColor) {
    final headingStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: AppPalette.subpageText,
    );
    final bodyStyle = TextStyle(
      fontSize: 13,
      height: 1.55,
      color: AppPalette.subpageTextMuted,
    );
    final glossStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppPalette.subpageText,
    );
    final conclusionStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      height: 1.5,
      color: AppPalette.subpageText,
    );

    Widget kanjiBlock(String heading, String body, String gloss) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading.tr(lang), style: headingStyle),
          const SizedBox(height: 6),
          Text(body.tr(lang), style: bodyStyle),
          const SizedBox(height: 8),
          Text(gloss.tr(lang), style: glossStyle),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kanjiBlock(
          '唱（ショウ）',
          '昌には、盛んで明るいとか、美しいことばという意味があり、それと口にすることから、唱は、うたう、となえるの意味を表す。また、昌の音は、高く上げるという意味を含むから、唱は、声を高くあげること、あるいは、「人より先に大声を上げてリードする」ことである。',
          '唱義：人に先立って正しい道をとなえる',
        ),
        _sectionDivider(),
        kanjiBlock(
          '躍（ヤク）',
          '翟には高く抜き出る意味がある。躍は「すばやくおどりあがる」ことである。',
          '躍動：おどりうごく、いきいきと活動する',
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'つまり「唱って躍れる」とは「周りを引っ張って、元気に前に進める」「自分の考えを話して、みんなと共有できる」ことである。'
                  .tr(lang),
              style: conclusionStyle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    return SubpageScaffold(
      appBar: OsmAppBar(title: Text('自律とは'.tr(lang))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            HelpLeadCard(
              title: '自律の定義'.tr(lang),
              summary: jiritsuDefinition.tr(lang),
              tips: const [],
              accentColor: AppPalette.mintDark,
            ),
            const SizedBox(height: 20),
            Text(
              '（参考）自立とは'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppPalette.subpageTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            HelpSectionCardShell(
              accentColor: AppPalette.softBlueDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自分以外の何ものにも依存しない状態。'.tr(lang),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: AppPalette.subpageText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '自立できていない、依存している人は、自分のうまく行かない状態の責任や自分の感情、思考の原因すら周りの人や環境のせいにする。'
                        .tr(lang),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppPalette.subpageTextMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '自立には経済的自立、行動的自立、精神的自立があり、いずれも自律と密接に関係している（自律している人は自立できる）。'
                        .tr(lang),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppPalette.subpageTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '自律できていない人にありがちな行動'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppPalette.subpageTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            HelpSectionCardShell(
              accentColor: AppPalette.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HelpBulletList(
                    tips: [
                      for (final behavior in _nonJiritsuBehaviors)
                        behavior.tr(lang),
                    ],
                    bulletColor: AppPalette.coral,
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppPalette.coral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '一見クールでカッコよく見えたりする。的を射てるし。周囲を白けさせるパワー大。口癖は「でもさ...」'
                            .tr(lang),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          color: AppPalette.subpageText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '自律の3要素'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppPalette.subpageTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            for (final (index, element) in JiritsuElement.values.indexed)
              HelpSectionCard(
                badgeLabel: _numerals[index],
                title: element.question.tr(lang),
                tips: [for (final tip in _elementTips[index]) tip.tr(lang)],
                // Only the first line of the keyword's translation — some
                // (like 唱って躍れる) are two lines (Japanese term, then a
                // romaji aid) in their キーワード card, which doesn't fit
                // this compact single-line cross-reference.
                keyword: switch (_elementKeywords[index]) {
                  null => null,
                  final title =>
                    '${'キーワード'.tr(lang)}：'
                        '${title.tr(lang).split('\n').first}',
                },
                accentColor: _accentFor(index),
              ),
            const SizedBox(height: 20),
            Text(
              '動機づけマトリクス'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppPalette.subpageTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            HelpSectionCardShell(
              accentColor: AppPalette.softBlueDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '方策を考える際、動機づけマトリクスを意識すると良い。'.tr(lang),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppPalette.subpageText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MotivationMatrix(lang: lang),
                  const SizedBox(height: 18),
                  _MotivationExplanation(lang: lang),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'キーワード'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppPalette.subpageTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            for (final keyword in _keywords)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HelpSectionCardShell(
                  accentColor: keyword.accentColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        keyword.title.tr(lang),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.subpageText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      keyword.body(lang, keyword.accentColor),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            HelpSectionCardShell(
              accentColor: AppPalette.mintDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '誰かに話すことによって自分の中で漠然としていた夢が、どんどんリアリティを持ち、少しずつ形になり、ビジョンになっていく。これを繰り返す内にビジョンはより明確になり、とうとう的確な言葉で表現できるようになったとき、初めて明快な物語として、リアリティのある戦略として、それを人に伝達し、実際に行動に移していく事ができる。'
                        .tr(lang),
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: AppPalette.subpageText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '― 伊藤守「リーダーになる人ならない人」'.tr(lang),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.subpageTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟦🟧🟩 — Ⅰ=blue, Ⅱ=orange, Ⅲ=green. Fixed [AppPalette] identity
  // colors so the 3要素 always read the same on this subpage screen.
  static Color _accentFor(int index) {
    switch (index) {
      case 0:
        return AppPalette.opportunity;
      case 1:
        return AppPalette.amber;
      default:
        return AppPalette.strength;
    }
  }
}

/// 横に自律の3要素、縦に内発的／外発的動機づけを並べた空欄マトリクス —
/// ユーザー自身が埋めるための思考ツールなので、セルの中身は空のまま描く。
/// Column headers are the same Ⅰ/Ⅱ/Ⅲ badges (and colors, via
/// [JiritsuAboutScreen._accentFor]) as the 3要素 cards above, rather than
/// repeating their long labels — keeps every column narrow enough that no
/// cell needs to wrap across several lines.
class _MotivationMatrix extends StatelessWidget {
  const _MotivationMatrix({required this.lang});

  final AppLanguage lang;

  static const _rowLabels = ['内発的動機づけ', '外発的動機づけ'];

  @override
  Widget build(BuildContext context) {
    // Every cell in a row shares the same `minHeight` below and holds only
    // a small badge or a short 1-2 word label, so plain top alignment
    // already paints each cell's background flush to the row's actual
    // height with no gap — `TableCellVerticalAlignment.fill` was tried
    // here for the same effect, but it collapses this Table to nothing
    // when laid out inside the card shell's `IntrinsicHeight`, so it's
    // deliberately not used.
    Widget cell(
      Widget child, {
      Color? background,
      double minHeight = 56,
    }) => Container(
      color: background ?? Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      constraints: BoxConstraints(minHeight: minHeight),
      child: child,
    );

    Widget numberBadge(int index) => Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: JiritsuAboutScreen._accentFor(index),
        shape: BoxShape.circle,
      ),
      child: Text(
        JiritsuAboutScreen._numerals[index],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE1F0EA)),
        ),
        child: Table(
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Color(0xFFE1F0EA)),
          ),
          columnWidths: const {0: FractionColumnWidth(0.34)},
          children: [
            TableRow(
              children: [
                cell(const SizedBox.shrink()),
                for (final index in [0, 1, 2])
                  cell(
                    numberBadge(index),
                    background: JiritsuAboutScreen._accentFor(
                      index,
                    ).withValues(alpha: 0.10),
                  ),
              ],
            ),
            for (final rowLabel in _rowLabels)
              TableRow(
                children: [
                  cell(
                    Text(
                      // JP: break right before 動機づけ so this narrow
                      // column always gets a clean 2-line "内発的\n動機づけ"
                      // rather than an arbitrary mid-word wrap — only
                      // affects this cell's own rendering, not the shared
                      // translation key used elsewhere (キーワード
                      // cross-reference, `_MotivationExplanation`
                      // headings, ...).
                      lang == AppLanguage.japanese
                          ? rowLabel.tr(lang).replaceFirst('動機づけ', '\n動機づけ')
                          : rowLabel.tr(lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        // EN: "Intrinsic/Extrinsic motivation" wraps
                        // "motivation" onto its own line at fontSize 12 in
                        // this narrow column — a smaller size keeps each
                        // label on one line instead.
                        fontSize: lang == AppLanguage.english ? 10.5 : 12,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.subpageText,
                      ),
                    ),
                    background: AppPalette.subpageBackground,
                  ),
                  for (final _ in [0, 1, 2]) cell(const SizedBox.shrink()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Prose that follows [_MotivationMatrix] inside the same card: what
/// 内発的/外発的動機づけ each mean, then how they relate to each other.
class _MotivationExplanation extends StatelessWidget {
  const _MotivationExplanation({required this.lang});

  final AppLanguage lang;

  static const _intrinsicExamples = [
    '興味のある分野について自主的に深く調べる。',
    '純粋に人を喜ばせたくて仕事に取り組む。',
  ];

  static const _intrinsicProsCons = [
    '⭕️ モチベーションが長持ちする',
    '❌ 本人の興味に依存するため即効性がない',
    '❌ 誰にでも同じように適用することは困難',
  ];

  @override
  Widget build(BuildContext context) {
    // Headings carry the weight/size, body text stays muted — the
    // dark/bold-vs-light/regular contrast is what creates the skimmable
    // rhythm here, not extra colors.
    final headingStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppPalette.subpageText,
    );
    final subheadingStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
      color: AppPalette.subpageTextMuted,
    );
    final paragraphStyle = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: AppPalette.subpageTextMuted,
    );

    Widget heading(String text) => Text(text.tr(lang), style: headingStyle);
    Widget subheading(String text) =>
        Text(text.tr(lang), style: subheadingStyle);
    Widget paragraph(String text) =>
        Text(text.tr(lang), style: paragraphStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('内発的動機づけ'),
        const SizedBox(height: 6),
        paragraph('自分の内面的な興味・関心、探究心、楽しさなどが原動力となる状態。'),
        const SizedBox(height: 12),
        subheading('＜特徴＞'),
        const SizedBox(height: 4),
        paragraph('行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。'),
        const SizedBox(height: 12),
        subheading('＜具体例＞'),
        const SizedBox(height: 6),
        HelpBulletList(tips: [for (final e in _intrinsicExamples) e.tr(lang)]),
        const SizedBox(height: 12),
        subheading('＜メリット・デメリット＞'),
        const SizedBox(height: 6),
        for (final line in _intrinsicProsCons)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: paragraph(line),
          ),
        _sectionDivider(),
        heading('外発的動機づけ'),
        const SizedBox(height: 6),
        paragraph('報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」をきっかけとして行動を促すこと。'),
        _sectionDivider(),
        heading('内発か？外発か？'),
        const SizedBox(height: 6),
        paragraph(
          '内発と外発は対立するものではなく組み合わせもの。外発をきっかけに始めて、その内、それ自体が楽しくなる...（エンハンシング効果）。',
        ),
      ],
    );
  }
}
