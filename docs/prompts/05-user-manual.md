# 05 — ユーザーマニュアル（GAS を osmGradus 最新に揃える）

このファイルは Claude Code 向けの実装指示書です。

## Claude への指示テンプレ

```
docs/prompts/05-user-manual.md のステップに沿って進めて
```

1 Step ずつ:

```
docs/prompts/05-user-manual.md の Step N をやって
```

各 Step の受け入れを満たしてから次へ。コミットはしない。  
Google スライドの中身を API やスクショから書き換えない。リポジトリ側（GAS・辞書・README）だけ直す。

01〜04 の画面文言が終わってから Step 3（Glossary）をやる。Step 1–2 は独立なので先にやってよい。

---

## 検討メモ

osmJiritsu の `docs/user-manual-gas/` は Gradus から移植したあと、**文字飾りを保つ `getRuns()` 翻訳**がまだ入っていない。枠ごと `setText` すると太字・背景色・リンクが潰れ、索引の色付き見出しがずれる。これが osmGradus で直した最新仕様。

参照（完成形）:

| 役割 | osmGradus |
|------|-----------|
| 翻訳本体 | `docs/user-manual-gas/Code.gs` |
| 手順 | `docs/user-manual-gas/README.md` |
| 用語辞書 | `docs/user-manual-gas/Glossary.gs`（中身は Gradus 固有。構造とヘッダだけ参考） |

osmGradus ルート: `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus`

同じ追従の実例: osmCogito の `docs/user-manual-gas/`（スライド ID は Cogito のまま、`getRuns()` と README の「文字飾り」節は Gradus と同じ）。

移植してよいもの / してはいけないもの:

| する | しない |
|------|--------|
| `translateTextRange_` を run 単位にする（`translateRun_` を足す） | `MASTER_ID` / `TARGET_EN_ID` / `TARGET_VI_ID` を Gradus のものに変える |
| README に「文字飾り」節を足す | 英語・ベトナム語スライドを消す・コピーし直す |
| Glossary を `app_strings.dart` の ja/en/vi に揃える | スライドファイルそのものをリポジトリから編集する |
| アプリ名は osmJiritsu のまま | Gradus のレイヤー用語を辞書に混ぜる |

スライド ID（変えない。`HelpScreen` と同じ）:

| 言語 | ID |
|------|-----|
| 日本語マスター | `1C3BGFdWm6UneFcPQC0d7ftQ46n65hsN4uB8KAdXHObU` |
| 英語 | `14pVMbXOI4YSaV-PpC02N1r6IYFNTYUFiqcdiIA5uLos` |
| ベトナム語 | `1ALuMLxX3wRoySWb6mWdY8i59eLeP7gy-O7Ut5q8elFc` |

---

## 現状の差分（osmJiritsu が古い点）

`translateTextRange_` がテキスト枠全体を `setText` している。

```javascript
// osmJiritsu 現状（古い）
function translateTextRange_(textRange, lang, stats, inTable) {
  var original = textRange.asString();
  // ...
  textRange.setText(translated);
}
```

osmGradus 最新は `getRuns()` で飾りごとの断片に分け、**末尾の run から**訳す（先頭を書くと後続 run の範囲がずれる）。

```javascript
function translateTextRange_(textRange, lang, stats, inTable) {
  var runs = null;
  try {
    runs = textRange.getRuns();
  } catch (e) {
    runs = null;
  }
  if (!runs || runs.length === 0) {
    translateRun_(textRange, lang, stats, inTable);
    return;
  }
  for (var i = runs.length - 1; i >= 0; i--) {
    translateRun_(runs[i], lang, stats, inTable);
  }
}

function translateRun_(run, lang, stats, inTable) {
  var original = run.asString();
  if (!original || !original.replace(/\s/g, '')) {
    return;
  }
  stats.boxes++;
  var translated = translatePreservingBreaks_(original, lang, stats);
  if (inTable) {
    translated = flattenSpuriousBreaks_(original, translated);
  }
  if (translated !== original) {
    run.setText(translated);
  }
}
```

リンク復元・表セル・改行潰し・辞書優先は既に Gradus と同じなので触らない。`copyMasterSlides_` もそのまま。

README に osmGradus にある「文字飾り（太字・背景色など）」節が無い。表の余分な改行の説明は既にある。

---

## Step 1 — Code.gs を Gradus の run 単位翻訳に揃える

### 目的

翻訳してもマスターの太字・色・背景が残るようにする。

### 指示

1. Gradus の `Code.gs` から `translateTextRange_` と `translateRun_` を持ってくる
2. osmJiritsu のスライド ID・ファイル先頭コメント（「osmJiritsu ユーザーズマニュアル翻訳」）は維持
3. 他の関数をリファクタしない。動作が同じなら Gradus と一字一句でなくてよいが、run 処理の意味は変えない
4. 先頭を書き換えると後続がずれる、というコメントは残す

### 受け入れ

- [ ] 枠全体 `setText` が残っていない（run 単位）
- [ ] `MASTER_ID` / `TARGET_EN_ID` / `TARGET_VI_ID` が上表のまま
- [ ] `onOpen` メニュー名は「マニュアル翻訳」のまま

---

## Step 2 — README を Gradus 最新の手順に揃える

### 目的

貼り直し手順と「なぜ run 単位か」が README だけで分かる。

### 指示

1. osmGradus の `docs/user-manual-gas/README.md` を正本にする
2. osmJiritsu 固有で残すもの
   - タイトルは「ユーザーズマニュアル」でも「操作マニュアル」でも、アプリの HELP 表記（`操作マニュアル`）と矛盾しないこと
   - 対象ファイル表に **スライド ID 3つ**を残す（Gradus README は ID 無し。Jiritsu/Cogito は有り。有りのまま）
   - スキップ例のアプリ名は osmJiritsu
3. 「文字飾り（太字・背景色など）」節を Gradus から入れる。索引の例は「レイヤー I」ではなく osmJiritsu の色付き見出し（あれば）に言い換えてよい。無ければ一般的に「色付き見出し」でよい
4. ハイパーリンク・表の改行・権限・翻訳の優先順位は Gradus と同じ意味を維持

### 受け入れ

- [ ] 文字飾り節がある
- [ ] スライド ID が 3 つ書いてある
- [ ] 「英語・ベトナム語ファイルは消さない」が残っている

---

## Step 3 — Glossary を画面文言に同期

### 目的

01〜04 で変わった画面語が、マニュアル翻訳で古い訳のまま残らない。

### 指示

1. `lib/l10n/app_strings.dart` の ja キー → en / vi を `Glossary.gs` の `GLOSSARY_EN` / `GLOSSARY_VI` に反映する
2. 少なくとも次を新語に合わせる（画面から消したものは辞書からも消す）
   - 使い方画面一式（`使い方_タイトル`、`使い方_コピー本文`、`ホーム画面へ`、`使い方画面` など）
   - 動機づけ / 外発的動機づけ / 内発的動機づけの新本文
   - `成果が分かりやすいか？` / `周りと繋がっているか？`
   - `内発度チェック` / `内発度をチェックする` / `内発度チェック: %lld / 3`
3. 消す旧キー例: `自律度チェック`、`自律度をチェックする`、`結果が分かりやすいか？`、`ゴールを共有できているか？`、`動機づけマトリクス`、`自律の3要素`（画面に残っていれば残す）
4. ヘッダコメント `アプリ用語の固定訳。完全一致を優先し、残りは機械翻訳。` は維持
5. キーはソート順を既存に合わせる（今はアルファベット／五十音混在のオブジェクトリテラル）
6. Google スライド本文はこの Step では触らない。辞書を直したあと、人間がマスターを直して GAS メニューを回す

### 受け入れ

- [ ] 新画面語が Glossary の en/vi にある
- [ ] 画面から消した旧称が Glossary に残っていない（または残す理由がコメントである）
- [ ] Gradus のレイヤー／JLPT 用語が混入していない

---

## 人間側（Claude Code の範囲外）

リポジトリを直したあと、日本語マスターの Apps Script に貼り直す。

1. 日本語マスターを開く
2. 拡張機能 → Apps Script
3. `Code` に `docs/user-manual-gas/Code.gs` を全部貼る
4. `Glossary` に `docs/user-manual-gas/Glossary.gs` を全部貼る
5. 保存 → スライドを再読み込み
6. 日本語マスターのスライドを 01〜04 の画面に合わせて直す（スタートの次に使い方、自律とはの動機づけ、内発度チェック）
7. **マニュアル翻訳 → 英語とベトナム語を両方更新**
8. 英・越を開き、はみ出しだけ直す。ファイルは消さない

HELP の preview URL は ID 固定のまま。共有は「リンクを知っている全員（閲覧可）」。
