# 02 — 「自律とは」画面の動機づけ再構成

このファイルは Claude Code 向けの実装指示書です。

## Claude への指示テンプレ

```
docs/prompts/02-jiritsu-about-motivation.md のステップに沿って進めて
```

1 Step ずつ:

```
docs/prompts/02-jiritsu-about-motivation.md の Step N をやって
```

各 Step の受け入れを満たし、`flutter analyze` と当該テストが通ってから次へ。  
スコープ外のリファクタはしない。l10n は ja/en/vi。コミットはしない。

01（使い方画面）とは独立。並行してよい。03 / 04 はこのファイルの **要素名と本文** を正本にする。

---

## 検討メモ

現状は「自律の3要素」を先に出し、そのあと空の動機づけマトリクス（3要素 × 内発/外発）を置いている。ユーザーの指摘どおり、**動機づけとのつながりが弱い**。

狙い:

- 3要素は「自律の定義の隣」ではなく、**内発的動機づけの中身**
- 外発と内発は対立ではなく組み合わせ。エンハンシング効果を先に説明する
- マトリクス表は削除する（空欄ワークシートの役割が、新しい説明と食い違う）
- キーワードカード（小さなくるくる／唱って躍れる）と引用は残す。3要素側からのクロスリファレンスも残す

画面の上（定義・自立・ありがちな行動）は触らない。

---

## 変更範囲

対象: `lib/help/screens/jiritsu_about_screen.dart`  
テスト: `test/help/jiritsu_about_screen_test.dart`  
文言: `lib/l10n/app_strings.dart`  
必要ならコメント: `lib/models/jiritsu.dart`（**question 文字列の変更は 04 で行う。** このファイルでは UI が新しい見出しを直接描いてよい）

残すセクション:

1. 自律の定義
2. （参考）自立とは
3. 自律できていない人にありがちな行動
4. キーワード（小さなくるくる／唱って躍れる）
5. 伊藤守の引用

消す:

- 見出し「自律の3要素」（トップレベル）
- 見出し「動機づけマトリクス」
- `_MotivationMatrix` の表
- `_MotivationExplanation` の旧構成（「内発か？外発か？」を独立見出しにしている並び）
- 「＜メリット・デメリット＞」見出し。⭕️❌ は「＜特徴＞」の下へ移す

---

## 新しい本文（正本。要約しない）

既存の `HelpSectionCard` / `HelpSectionCardShell` / `HelpBulletList` / `_sectionDivider` を使う。新しいデザインシステムは作らない。ⅠⅡⅢ バッジと色（`_accentFor`）は3要素カードに流用してよい。

### セクション: 動機づけ

自分で考えて行動するきっかけを動機づけという。動機づけには外発的動機づけと内発的動機づけがある。両者は対立するものではなく組み合わせるもの。外発的動機づけをきっかけに始めて、その内、それ自体が楽しくなる（エンハンシング効果）を狙うと良い。

### セクション: 外発的動機づけ

報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」による動機づけ。

### セクション: 内発的動機づけ

自分の内面的な興味・関心、探究心、楽しさなどが原動力となる動機づけ。下記の３要素で構成される。

その下に3枚のカード:

**Ⅰ 自分で決められるか？**

- やり方を自分で決めている感覚があるか？
- 主導権は自分にあるのだと意識できているか？
- 他人から言われる前に動いているか？

**Ⅱ 成果が分かりやすいか？**

- 自分の能力を発揮できている、自分の成長を実感できているという有能感があるか？
- 方策の粒度が細かく、結果を見える化されていて、視覚的に成果を実感できるか？
- キーワード：小さなくるくる

**Ⅲ 周りと繋がっているか？**

- ビジョン、ゴール、日々の進捗状況を周囲と共有できているか？
- 周囲からサポートが得られるようになっているか？
- 「お役に立ちたい」「当てにされたい」などの承認欲求を満たしているか？
- キーワード：唱って躍れる
- 言語化されることで思いが現実性をもつ

（キーワード行は今と同じくカード下部の accent 太字でよい。「言語化されることで…」は箇条書きでも、キーワードの直後の一文でも可。意味を落とさない。）

続けて内発的動機づけの補足（同じカード内でも、内発セクションの続きでも可）:

**＜特徴＞**

行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。

⭕️ モチベーションが長持ちする  
❌ 本人の興味に依存するため即効性がない  
❌ 誰にでも同じように適用することは困難

**＜具体例＞**

- 興味のある分野について自主的に深く調べる。
- 純粋に人を喜ばせたくて仕事に取り組む。

特徴・具体例は **内発的動機づけに属する**。外発カードの下に置かない。

---

## 推奨 l10n

新しいキーは日本語リテラルをキーにする（既存どおり）。en/vi も必ず足す。

**en 例**

| ja | en |
|----|----|
| 動機づけ | Motivation |
| 自分で考えて行動するきっかけを動機づけという。動機づけには外発的動機づけと内発的動機づけがある。両者は対立するものではなく組み合わせるもの。外発的動機づけをきっかけに始めて、その内、それ自体が楽しくなる（エンハンシング効果）を狙うと良い。 | The spark that makes you think and act on your own is called motivation. There is extrinsic and intrinsic motivation. They are not opposites; they work together. Start with extrinsic motivation, then aim for the enhancing effect — the work itself becoming enjoyable. |
| 報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」による動機づけ。 | Motivation from outside stimulation such as rewards, evaluation, promotion, or penalties and scolding. |
| 自分の内面的な興味・関心、探究心、楽しさなどが原動力となる動機づけ。下記の３要素で構成される。 | Motivation driven by inner interest, curiosity, and enjoyment. It is made of the three elements below. |
| 成果が分かりやすいか？ | Can you see your results clearly? |
| 周りと繋がっているか？ | Are you connected with others? |
| やり方を自分で決めている感覚があるか？ | Do you feel you decide how to do it? |
| 主導権は自分にあるのだと意識できているか？ | Are you aware that you hold the initiative? |
| 他人から言われる前に動いているか？ | Do you act before someone else tells you to? |
| 自分の能力を発揮できている、自分の成長を実感できているという有能感があるか？ | Do you feel competent — using your abilities and seeing your own growth? |
| 方策の粒度が細かく、結果を見える化されていて、視覚的に成果を実感できるか？ | Are the steps small enough, and results visible enough, that you can feel progress? |
| ビジョン、ゴール、日々の進捗状況を周囲と共有できているか？ | Are vision, goals, and daily progress shared with the people around you? |
| 周囲からサポートが得られるようになっているか？ | Can you get support from the people around you? |
| 「お役に立ちたい」「当てにされたい」などの承認欲求を満たしているか？ | Are needs like “I want to be useful” and “I want to be counted on” being met? |

**vi 例**

| ja | vi |
|----|----|
| 動機づけ | Động lực |
| 成果が分かりやすいか？ | Bạn có thấy rõ thành quả không? |
| 周りと繋がっているか？ | Bạn có kết nối với mọi người không? |

長い本文の vi は意味を落とさず自然に訳す。機械訳のまま不自然なら直す。

旧キー（`動機づけマトリクス`、`方策を考える際、動機づけマトリクスを意識すると良い。`、`内発か？外発か？`、`＜メリット・デメリット＞`、旧チップ「他人から言われる前に動く」など）は画面から消したら l10n からも消す。他ファイルで使っていれば残す。

`docs/user-manual-gas/Glossary.gs` に旧見出しがある。この Step で画面キーを変えたら Glossary も同じキーを更新または削除する（マニュアル本文の書き換えまではしない）。

---

## Step 1 — 画面構造の差し替え

### 目的

「自律とは」の中盤を新しい3セクションにする。

### 指示

1. `JiritsuAboutScreen` の ListView 中盤を正本どおりに組み直す
2. `_MotivationMatrix` を削除
3. `_elementTips` / `_elementKeywords` を新しい箇条書きに更新。カードの title は新しい3つの問い
4. 定義・自立・ありがちな行動・キーワードカード・引用はレイアウトも文言も維持
5. 画面コメントを「3要素 × マトリクス」前提から直す
6. HELP は今どおりリンクのみ。3要素本文を HELP に複製しない（`test/help/help_screen_test.dart` の「複製しない」は残す。見出し「自律の3要素」が HELP に無いことも残してよい）

### 受け入れ

- [ ] 見出し「動機づけ」「外発的動機づけ」「内発的動機づけ」がある
- [ ] 「自律の3要素」「動機づけマトリクス」の見出しが無い
- [ ] `Table` のマトリクスが無い
- [ ] 3つの問いが内発セクションの下に出る
- [ ] キーワードカードと引用が残っている
- [ ] `flutter analyze` が通る

---

## Step 2 — テストと l10n

### 目的

テストが新しい本文を固定し、3言語が欠けない。

### 指示

1. `test/help/jiritsu_about_screen_test.dart` を更新
   - 新しい導入文、外発の定義、内発の導入、新しい箇条書き、特徴、具体例、⭕️❌
   - 旧マトリクス見出し・旧「内発か？外発か？」・旧チップ（「他人から言われる前に動く」など、画面から消したもの）は `findsNothing`
   - 「キーワード：小さなくるくる」「キーワード：唱って躍れる」は残す
   - ⅠⅡⅢ は3要素カード分。マトリクスが無いので各 1 個になるはず（以前はカード＋表で 2）
2. `app_strings.dart` の ja/en/vi
3. 既存の「自分で決められるか？」キーは残してよい（04 でも使う）。「結果が分かりやすいか？」「ゴールを共有できているか？」は 04 で置き換えるので、**このファイルではチェック UI を変えない**

### 受け入れ

- [ ] 当該 widget テストが新しい画面を表している
- [ ] 新しいキーに en/vi がある
- [ ] `flutter test test/help/jiritsu_about_screen_test.dart test/help/help_screen_test.dart` が通る

### 手動確認

1. HELP → 自律とは を開き、定義のあとに動機づけ → 外発 → 内発（3カード）→ キーワード、の順で読める
2. 英語・ベトナム語でも見出しが日本語のまま残っていない
