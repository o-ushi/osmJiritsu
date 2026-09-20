# 04 — 自律度チェックを内発度チェックに変更

このファイルは Claude Code 向けの実装指示書です。

## Claude への指示テンプレ

```
docs/prompts/04-intrinsic-check.md のステップに沿って進めて
```

1 Step ずつ:

```
docs/prompts/04-intrinsic-check.md の Step N をやって
```

各 Step の受け入れを満たし、`flutter analyze` と当該テストが通ってから次へ。  
スコープ外のリファクタはしない。l10n は ja/en/vi。コミットはしない。

02 の要素名が正本。クラス名の大規模リネームはこのファイルの目的ではない。

---

## 検討メモ

ユーザー向け名称だけを変える。保存データは既存案件を壊さない。

| 層 | 方針 |
|----|------|
| 画面・l10n | 「内発度チェック」に変える。3つの問いも新名称 |
| `JiritsuElement.question` | ここがチェック行の表示源。必ず更新 |
| JSON / `rawValue` | `selfDetermined` / `clearOutcome` / `sharedGoal` は **変えない** |
| Dart 型名 `JiritsuCheck` / `JiritsuElement` | リネームしない（差分が爆発する。コメントだけ新用語へ） |

「内発度をチェックする」は CTA。「内発度チェック」は画面見出しとダッシュボード行。

---

## 文言対照

| 旧 | 新 |
|----|----|
| 自律度をチェックする | 内発度をチェックする |
| 自律度チェック | 内発度チェック |
| 自律度チェック: %lld / 3 | 内発度チェック: %lld / 3 |
| 自分で決められるか？ | 自分で決められるか？（同じ） |
| 結果が分かりやすいか？ | 成果が分かりやすいか？ |
| ゴールを共有できているか？ | 周りと繋がっているか？ |

サブコピー「決めた方策を、3つの要素から見直してみましょう。」は残してよい。変えるなら「内発的動機づけの3要素から見直してみましょう。」

**en 推奨**

| ja | en |
|----|----|
| 内発度をチェックする | Check intrinsic motivation |
| 内発度チェック | Intrinsic check |
| 内発度チェック: %lld / 3 | Intrinsic check: %lld / 3 |
| 成果が分かりやすいか？ | Can you see your results clearly? |
| 周りと繋がっているか？ | Are you connected with others? |

**vi 推奨**

| ja | vi |
|----|----|
| 内発度をチェックする | Kiểm tra động lực nội tại |
| 内発度チェック | Kiểm tra động lực nội tại |
| 内発度チェック: %lld / 3 | Kiểm tra động lực nội tại: %lld / 3 |
| 成果が分かりやすいか？ | Bạn có thấy rõ thành quả không? |
| 周りと繋がっているか？ | Bạn có kết nối với mọi người không? |

旧キーを画面から消したら `app_strings.dart` からも消す。キーをリテラルのまま置換するのが既存スタイル。

---

## 現状の地図

| 領域 | パス |
|------|------|
| 問い | `lib/models/jiritsu.dart` の `JiritsuElement.question` |
| モデル | `lib/models/jiritsu_check.dart` |
| パネル | `lib/strategy/widgets/jiritsu_check_panel.dart` |
| フロー | `lib/strategy/screens/strategy_flow_screen.dart` / `strategy_flow_state.dart` |
| ダッシュボード | `lib/dashboard/screens/dashboard_screen.dart` |
| 共有テキスト | `lib/models/project.dart` の summary（`自律度チェック: ${…} / 3`） |
| テスト | `test/strategy/strategy_flow_screen_test.dart` / `test/dashboard/dashboard_screen_test.dart` / `test/models/project_test.dart` / `test/models/jiritsu_test.dart` |
| 用語集 | `docs/user-manual-gas/Glossary.gs` |

`JiritsuCheckPanel` は `element.question.tr(lang)` を出しているので、question を変えればパネルは追従する。

---

## Step 1 — ドメインの問いと画面ラベル

### 目的

チェック UI と summary が新しい名前になる。

### 指示

1. `JiritsuElement.question` とコメントを更新。`rawValue` は維持
2. `jiritsu_check.dart` / `project.dart` のフィールド説明コメントを新用語へ
3. l10n の CTA・見出し・`内発度チェック: %lld / 3` を ja/en/vi で置換
4. `project.dart` の共有用 summary 文字列が l10n キーに依存しているならそこも。ハードコードなら新しい日本語キーに合わせ、テストも更新
5. 画面見出し・ボタン（`strategy_flow_screen.dart`）
6. ダッシュボードのスコア行
7. コメントの「自律度チェック」をユーザー向け説明から「内発度チェック」へ。内部型名はそのまま

### 受け入れ

- [ ] 画面に「自律度チェック」「自律度をチェックする」が残っていない
- [ ] 3行の問いが新名称
- [ ] 既存 JSON を読んでも3つの bool が同じフィールドに載る
- [ ] `flutter analyze` が通る

---

## Step 2 — テストと用語集

### 目的

テストとマニュアル用語集が旧称に固定されたまま残らない。

### 指示

1. 次を新文言に更新（ヒットしたら全部）
   - `test/strategy/strategy_flow_screen_test.dart`
   - `test/dashboard/dashboard_screen_test.dart`
   - `test/models/project_test.dart`
   - その他 `rg '自律度'` のテスト
2. `JiritsuElement.question` の値を `test/models/jiritsu_test.dart` で固定してもよい
3. `docs/user-manual-gas/Glossary.gs` の ja/en/vi。旧キーを新キーに置き換える。`結果が分かりやすいか？` / `ゴールを共有できているか？` も
4. 操作ガイドや HELP 本文に旧称があれば直す。Google スライド本体は対象外

### 受け入れ

- [ ] `rg '自律度'` がユーザー向け文字列（l10n・テスト expect・Glossary）に残っていない。コードコメントの歴史的言及は最小限
- [ ] `rg '結果が分かりやすいか'` `rg 'ゴールを共有できているか'` が UI キーとして残っていない
- [ ] `flutter test` の関連テストが通る
- [ ] 可能なら `flutter test` 全体

### 手動確認

1. 方策フローで「内発度をチェックする」→ 3つの新問い
2. ダッシュボードに「内発度チェック: n / 3」
3. 英語 UI で Intrinsic check が見える
4. 保存済み案件を開き、以前のチェック状態が消えていない
