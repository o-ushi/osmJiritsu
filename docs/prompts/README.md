# osmJiritsu 実装指示書（Claude Code 用）

このフォルダは、Claude Code に「このファイルのステップに沿って進めて」と渡すための実装指示書です。  
実装そのものはここでは行いません。各ファイルが 1 つの依頼単位です。

## Claude Code への依頼テンプレ

まとめて全部:

```
docs/prompts/README.md の順で、01 → 02 → 03 → 04 の各ファイルのステップに沿って進めて
```

ファイル単位:

```
docs/prompts/01-usage-screen.md のステップに沿って進めて
```

```
docs/prompts/02-jiritsu-about-motivation.md のステップに沿って進めて
```

```
docs/prompts/03-ai-prompts-three-elements.md のステップに沿って進めて
```

```
docs/prompts/04-intrinsic-check.md のステップに沿って進めて
```

1 Step だけ:

```
docs/prompts/01-usage-screen.md の Step 2 をやって
```

「ステップに沿って進めて」と指示された場合は、そのファイルの Step 1 から最後まで順に実施する。  
各 Step の受け入れを満たし、`flutter analyze` と当該テストが通ってから次へ。途中で赤ならそこで止めて直す。  
大きな設計変更は提案のみ。スコープ外のリファクタ・ドキュメント追加はしない。コミットは指示があるまでしない。

## 順番と依存

| 順 | ファイル | 内容 | 依存 |
|----|----------|------|------|
| 1 | [`01-usage-screen.md`](01-usage-screen.md) | スタート画面の後ろに Chrome AI コピー説明画面。表示切替と動線は osmGradus 流用 | なし |
| 2 | [`02-jiritsu-about-motivation.md`](02-jiritsu-about-motivation.md) | 「自律とは」の動機づけ／3要素の再構成 | なし（01 と並行可） |
| 3 | [`03-ai-prompts-three-elements.md`](03-ai-prompts-three-elements.md) | 方策・最初の一歩の AI プロンプトに内発3要素を入れる | 02 の要素名に合わせる |
| 4 | [`04-intrinsic-check.md`](04-intrinsic-check.md) | 「自律度チェック」→「内発度チェック」。要素名も更新 | 02 の要素名に合わせる |

推奨は **01 → 02 → 03 → 04**。01 と 02 は独立なので並行してもよい。03 と 04 は 02 の文言が正本。

## 変更の狙い（全体）

1. Chrome AI モードからコピーせずに戻って貼り付けできない、という失敗を最初に教える。
2. 「自律の3要素」を動機づけマトリクスの横並びにせず、**内発的動機づけの構成要素**として説明する。
3. AI 提案と内発度チェックも、同じ3つの問い（自分で決められるか／成果が分かりやすいか／周りと繋がっているか）に揃える。

## 全ファイル共通ルール

1. ユーザー向け文言は `lib/l10n/app_strings.dart`。**ja / en / vi を揃える**。キーだけ書いて訳を空にしない。
2. 既存の Hive JSON キー（`selfDetermined` / `clearOutcome` / `sharedGoal` など）は互換のため変えない。
3. osmGradus は参照元。**コピーして osmJiritsu の Riverpod / HistoryListScreen 構造に載せ替える**。`AppRootShell` や `appSettings` を丸ごと移植しない。
4. osmGradus 固有の操作（＋長押し、ダブルタップ）は移植しない。osmJiritsu の操作ヒントは `•••` 長押し。
5. 完了報告は、変更ファイル一覧・手動確認手順・次ファイルへの前提を短く。
