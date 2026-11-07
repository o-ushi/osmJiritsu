# 06 — 簡易モード

このファイルは Claude Code 向けの実装指示書です。

## Claude への指示テンプレ

まとめて:

```
docs/prompts/06-simple-mode.md のステップに沿って進めて
```

1 Step だけ:

```
docs/prompts/06-simple-mode.md の Step N をやって
```

各 Step の受け入れを満たし、`flutter analyze` と当該テストが通ってから次へ。  
途中で赤ならそこで止めて直す。スコープ外のリファクタ・ドキュメント追加はしない。  
l10n を足すなら ja / en / vi を揃える。コミットはしない。

01〜05 とは独立。先にやっていなくてもこのファイルだけで完結する。

---

## 検討メモ（なぜこの切り方か）

フルモード（既存ウィザード: テーマ → ゴール2つ → 壁打ち → SWOT → 方策 → 最初の一歩）はそのまま残す。  
簡易モードは別画面で、案件としては同じ `Project` に載せる。一覧・書き出し・お気に入り・削除を二系統にしない。

区別は新しいフィールド `entryMode`（`"full"` / `"simple"`）。JSON に無ければ `"full"`。  
古い案件はそのままウィザード／ダッシュボードに開く。

簡易モードの中身はフルの SWOT や `decidedStrategy` に流し込まない。  
進捗の見方が違うので、簡易用のフィールドを別に持つ。

一覧カードの見出しは既存の `theme` を表示している。簡易ではゴール文を `theme` と `desiredGoal` の両方に書く。別のタイトル欄は作らない。

---

## 機能概要

案件一覧（トップ）の **＋（新規追加）** で、簡易モードかフルモードかを選ぶ。アイコン付きの2択。

案件が0件のときも同じ2択にする。スタート画面の「はじめる」、使い方画面の「ホーム画面へ」は、0件だと `HistoryListScreen` の `landOnHome` が `startNew` を呼ぶ。いまはそこでウィザードに直行している。シートは `startNew` の中に置くので、この着地もウィザードに直行させない。

- **フルモード** — 今の `WizardFlowScreen`。挙動は変えない。
- **簡易モード** — 次の4枠だけの画面。
  - ゴール: 1つ。大きい文字。右上。
  - 現状: 最大3つ。小さい文字。左下。チェックなし。
  - 方策: 最大3つ。ゴールと現状の間（中央）。チェックあり。
  - 最初の一歩: 1つ。大きい文字。一番下、横幅いっぱい。チェックあり。

方策と最初の一歩は、チェックするとカードも文字も灰色になる。外すと元の色に戻る。打ち消し線は付けない。

空の新規（何も書いていない）は一覧に残さない。中身があればホームに戻った時点で保存され、▶️で同じ簡易画面が開く。

---

## レイアウト正本（推測で縦一列のフォームにしない）

背景は `AppPalette.scene`。カードは既存パレットだけを使う。新しいブランド色は足さない。

本体は `Column`。

1. 上側 `Expanded` — `LayoutBuilder` + `Stack`（ボード）
2. 下側 — 最初の一歩（ボードの外。横幅いっぱい。高さおおよそ 96）

ボード内の比率（`h` = ボードの高さ、`w` = 幅）:

| 枠 | 位置 | サイズ | 文字 | 未チェックの色 |
|----|------|--------|------|----------------|
| ゴール | `top: h * 0.02`, `right: 16` | 幅 `w * 0.58`, 高さ `h * 0.28` | 本文 26 / w600。ラベル 11 | 塗り `AppPalette.amber`、文字は `AppPalette.primaryTextOn` |
| 方策 | `top: h * 0.32`, `left: w * 0.16` | 幅 `w * 0.72`, 高さ `h * 0.32` | 本文 16。ラベル 11 | 塗り `AppPalette.cardFill`、枠 `AppPalette.cardAccent` |
| 現状 | `left: 16`, `bottom: 8` | 幅 `w * 0.46`, 高さ `h * 0.30` | 本文 14。ラベル 11 | 塗り `AppPalette.cardFill`、文字 `AppPalette.inkMuted`（ゴールより静か） |

最初の一歩: 左右 16、塗り `AppPalette.mint`、本文 26 / w600、文字は白。ラベル「最初の一歩」を左上に小さく。

チェック済み（方策の各行と、最初の一歩）:

- 塗り `Color(0xFFE4E4EA)`
- 文字 `AppPalette.inkMuted`
- 枠は塗りと同じか、ごく薄い灰色

ラベルは各カードの隅に置き、本文と競合させない。ゴールと最初の一歩は本文を主役にする。

キーボードが出ているあいだは、ボードが潰れても各カードに届くよう、ボードを `SingleChildScrollView` で包んでよい。スクロールしても上記の相対位置は維持する。縦に「ゴール→現状→方策→最初の一歩」と並べ替えない。

---

## 現状の地図

| 領域 | パス |
|------|------|
| 案件 | `lib/models/project.dart` |
| JSON テスト | `test/models/project_test.dart` |
| ＋の実装 | `lib/history/history_toolbar_actions.dart` の `startNew` |
| 一覧の＋ | `lib/history/screens/history_list_screen.dart` の `onAddNew` |
| フロー中の新規追加 | `lib/history/widgets/flow_scaffold.dart`（同じ `startNew`） |
| ▶️で開く | `HistoryListScreen` の `_openProject` |
| 保存 | `lib/history/state/analysis_history_notifier.dart` の `saveOrUpdate` |
| 一覧カード | `lib/history/widgets/history_session_card.dart`（見出しは `project.theme`） |
| 色 | `lib/theme/app_theme.dart` の `AppPalette` |
| 文言 | `lib/l10n/app_strings.dart`（ja / en / vi） |
| ＋の既存テスト | `test/history/history_list_screen_test.dart` の `"新規追加" in the bottom toolbar also starts the wizard` |

`startNew` はいま `wizardProvider` を reset して `WizardFlowScreen` を push している。フルモードを選んだときだけ、この動きにする。

---

## Step 1 — 簡易モードのデータを Project に載せる

### 目的

画面の前に、保存できる形を決める。古い JSON はフルモードとして読める。

### 指示

1. `lib/models/simple_line.dart` を追加する。

   - フィールド: `id`（無ければ uuid）、`text`、`done`（既定 `false`）
   - `copyWith` / `toJson` / `fromJson`
   - `fromJson` は `text` が無ければ `''`、`done` が bool でなければ `false`

2. `Project` に次を足す。コンストラクタ既定値はフル・空。

   | フィールド | 型 | JSON | 既定 |
   |------------|----|------|------|
   | `entryMode` | `String` | `entryMode` | `"full"` |
   | `simpleSituations` | `List<SimpleLine>` | `simpleSituations` | `[]` |
   | `simpleStrategies` | `List<SimpleLine>` | `simpleStrategies` | `[]` |
   | `simpleFirstStep` | `SimpleLine` | `simpleFirstStep` | 空文字・未チェック |

   定数でよい: `Project.modeFull = 'full'`、`Project.modeSimple = 'simple'`。  
   未知の `entryMode` は `"full"` として読む。

   `simpleFirstStep` は null にしない。空の1件を常に持つ（枠は1つだけ、という画面と揃える）。

3. `fromJson` はリストが壊れていても落とさない。Map 以外は捨てる。  
   現状・方策は **先頭3件まで**。4件目以降は読まない。  
   `simpleSituations` の `done` は保存してよいが、画面では使わない。

4. `copyWith` と `toJson` に同じフィールドを含める。  
   `schemaVersion` は上げない（足すだけなので、古い読み手は未知キーを無視できる。このアプリの `fromJson` は未知キーを読んでいない）。

5. `progressRatio` は `entryMode == modeSimple` のときだけ短い段階にする。フルは今の milestone のまま。

   - ゴール（`desiredGoal` の trim が空でない）: 0.25
   - 加えて現状が1件でも文字あり: 0.50
   - 加えて方策が1件でも文字あり: 0.75
   - 加えて最初の一歩が文字あり: 1.0
   - 全部空: 0.0
   - **チェックの on/off では進捗を変えない**
   - `ProjectStatus.completed` の 100% 特例は簡易でも残してよい（この機能では完了にはしない）

6. フル用の `shareSummary` / `dashboardShareSummary` は、`entryMode` が simple の案件では簡易の4枠を出す。  
   SWOT 節や内発度チェックは出さない。ラベルは「ゴール」「現状」「方策」「最初の一歩」。方策と最初の一歩は、チェック済みなら行末に `（済）`。  
   フル案件の summary 文言は変えない。

7. `test/models/project_test.dart`

   - 既存の round trip に、既定が full・簡易リスト空・最初の一歩空、であることを足す（既存アサーションは壊さない）。
   - 簡易案件を `toJson` → `fromJson` して4枠と `done` が残ること。
   - `entryMode` も簡易リストも無い古い JSON が `modeFull`・空リストになること。
   - 現状4件の JSON は3件になること。
   - 簡易の `progressRatio` が上の段階になること。チェックを付けても比率が変わらないこと。
   - フル案件の `progressRatio` が今までどおりであること（既存テストがあればそれを通す。無ければゴールだけ埋めた full が 0.2 であることだけ見る）。

### 受け入れ

- 既存の full 案件 JSON が今までどおり読める。
- 簡易の3件上限と進捗段階がテストで固定されている。
- `flutter analyze` が通る。`flutter test test/models/project_test.dart` が通る。

### 触らない

画面、ナビ、l10n、ウィザード、ダッシュボードのレイアウト。

---

## Step 2 — ＋で簡易かフルかを選ぶ

### 目的

新規作成の入口が、いきなりウィザードに入らない。入口は次の3つで、全部同じシート。

- 一覧の＋
- フロー画面の「新規追加」（同じ `startNew`）
- 案件0件でホームに着地したとき（`landOnHome` → `startNew`）。スタートの「はじめる」で使い方を飛ばした場合と、使い方の「ホーム画面へ」の両方

### 指示

1. 文言を `app_strings.dart` の ja / en / vi に足す。キーは日本語（既存スタイル）。

   | キー | ja | en | vi |
   |----|----|----|----|
   | モードを選ぶ | モードを選ぶ | Choose a mode | Chọn chế độ |
   | 簡易モード | 簡易モード | Simple | Đơn giản |
   | フルモード | フルモード | Full | Đầy đủ |
   | 簡易モード説明 | ゴール・現状・方策・最初の一歩だけ | Goal, situation, strategies, and a first step | Chỉ mục tiêu, hiện trạng, cách làm và bước đầu |
   | フルモード説明 | いまの作成の流れ | The current full flow | Luồng tạo đầy đủ hiện tại |

2. 選択 UI はモーダルボトムシート。`startNew` の先頭で、Navigator のルートとして出す（`landOnHome` の直後に親が rebuild してもシートが消えないこと）。  
   閉じただけ（選択なし）なら何もしない。ウィザードは開かない。0件なら空の一覧が残る。ツールバーの＋からもう一度開ける。シートを自動で開き直さない。

   横並び2枚の大きなカード。各カードはアイコン・名前・1行説明。

   - 簡易: `Icons.bolt_rounded`、地は `AppPalette.amber`、文字は `AppPalette.primaryTextOn`
   - フル: `Icons.account_tree_rounded`、地は `AppPalette.mint`、文字は白

3. フルを選んだときだけ、今の `startNew` 本体（`wizardProvider` reset → ルートまで pop → `WizardFlowScreen` を push）を実行する。

4. 簡易を選んだときは `wizardProvider` を触らない。  
   `SimpleModeScreen` を push する。引数は新規の `Project(entryMode: Project.modeSimple)`。  
   この Step の画面は骨格でよい。次の Step で中身を入れる。  
   骨格の条件: `FlowScaffold`（`persistWizardOnHome: false`）、背景 `AppPalette.scene`、どこかに「簡易モード」の文字。データはまだ保存しない。

   置き場所: `lib/simple/screens/simple_mode_screen.dart`。

5. 呼び出し元は `HistoryToolbarActions.startNew` だけを変える。  
   一覧の `onAddNew`、フローの「新規追加」、0件の `landOnHome` は同じメソッドなので、全部このシートになる。  
   0件だけウィザードに直行する分岐は足さない。

6. テスト `test/history/history_list_screen_test.dart`

   - `"新規追加" in the bottom toolbar also starts the wizard` を更新する。  
     ＋のあとシートに「簡易モード」と「フルモード」が出る。ウィザードの「それでは始めましょう」はまだ出ない。  
     「フルモード」をタップすると「それでは始めましょう」が出る。
   - ＋ → 「簡易モード」で「簡易モード」画面が出る、というテストを1本足す。  
     シートを閉じただけではウィザードに進まないことも見る。
   - `案件が0件の状態で「はじめる」をタップすると、空の一覧ではなく新規作成画面（テーマ入力）に移る` を更新する。  
     「はじめる」の直後はテーマ入力（「まずテーマを決めよう」）ではなく2択。  
     「フルモード」で「まずテーマを決めよう」に進む。「簡易モード」で簡易画面に進む。  
     シートを閉じたらウィザードには進まず、空の一覧（＋から再度選べる）でよい。
   - `使い方経由でも案件0件ならホーム着地でウィザードへ` も同様に更新する。  
     「ホーム画面へ」の直後は2択。「フルモード」でウィザードへ。

### 受け入れ

- 一覧に案件がある状態で＋を押すと2択が出る。
- 案件0件で「はじめる」（使い方を出さない設定）したときも2択が出る。使い方の「ホーム画面へ」で0件のときも同じ。
- フルは従来のウィザード先頭。
- 簡易は簡易画面（骨格）。
- 選択せず閉じると、案件があるときは一覧のまま。0件のときは空の一覧のまま。どちらもウィザードには入らない。
- `flutter analyze` と `flutter test test/history/history_list_screen_test.dart` が通る。

### 触らない

`Project` のフル用フィールドの意味、ダッシュボード、SWOT。案件が1件以上あるときの「はじめる」→一覧、という既存の着地。

---

## Step 3 — 簡易画面の4枠とチェック

### 目的

骨格を、レイアウト正本どおりの入力画面にする。この Step ではまだ一覧への保存をしなくてよい（Step 4）。画面内の状態は持てる。

### 指示

`SimpleModeScreen` は渡された `Project` を初期値にする。編集中の状態は画面側に持つ。

枠のルール:

| 枠 | 個数 | チェック | 入力 |
|----|------|----------|------|
| ゴール | 常に1枠 | なし | カード内の `TextField`。複数行可。ヒントは「ゴール」 |
| 現状 | 0〜3 | なし | 入っている行＋、3件未満なら追加の行。空行の追加で4件目は出ない |
| 方策 | 0〜3 | 各行 | 現状と同じ。行の右に `Checkbox` |
| 最初の一歩 | 常に1枠 | あり | カード内の `TextField`。右に `Checkbox`。ヒントは「最初の一歩」 |

- 行の追加は、その枠の中の「＋」か空のプレースホルダをタップ。別画面にはしない。
- 行の削除は、その行を長押しして確認ダイアログ（既存の削除確認の調子でよい）。削除で3件の枠が空く。
- チェックを付けるとその行（方策）またはカード全体（最初の一歩）がレイアウト正本の灰色になる。本文は読める。外すとセクション色に戻る。
- ゴールと現状にチェックは付けない。
- 文字が空の行をチェックしても灰色になってよい。保存時に空行を捨てるのは Step 4。

セクションラベル（「ゴール」「現状」「方策」「最初の一歩」）は l10n。既存キーがあればそれを使う。無ければ Step 2 と同じく ja/en/vi を足す。

見た目はレイアウト正本に従う。`ListView` で4セクションを縦積みにしない。

テスト `test/simple/simple_mode_screen_test.dart`:

- 新規の簡易 `Project` で画面を開くと、ゴール枠・最初の一歩枠が見える。現状と方策は空でも枠（ラベル）が見える。
- 現状を3件入れると、4件目を足す操作が無い（または押しても増えない）。
- 方策も同様に3件で止まる。
- 方策のチェックで、その行の文字色が灰色系になる（`DefaultTextStyle` か文字の `color` を読んで `AppPalette.inkMuted` に近いこと）。外すと戻る。
- 最初の一歩のチェックでも同様。
- ゴールにチェックボックスが無い。

色の比較は `Color` の完全一致でなくてもよい。チェック後に `AppPalette.inkMuted` が使われていること、外すと使われないこと、が分かればよい。

### 受け入れ

- 配置が右上ゴール / 中央方策 / 左下現状 / 最下部の最初の一歩になっている。
- 現状・方策は3つまで。最初の一歩は1つ。
- チェックで灰色、解除で復帰。
- `flutter analyze` と `flutter test test/simple/simple_mode_screen_test.dart` が通る。

### 触らない

一覧への保存、▶️の遷移、フルモードの画面。

---

## Step 4 — 保存して、一覧から簡易画面に戻る

### 目的

書いた内容が案件一覧に残り、▶️で同じ簡易画面が開く。フル案件の開き方は変えない。

### 指示

1. 保存タイミング

   - 文字の確定（フォーカスが外れたとき）と、行の追加・削除・チェック切り替えのたびに保存する。
   - ホーム（`FlowScaffold` のホーム）で戻る前にも、同じルールで保存する。  
     `persistWizardOnHome` は `false` のまま。ウィザードの下書き保存と混ぜない。
   - 保存 API は `analysisHistoryProvider.notifier.saveOrUpdate`。

2. 保存する中身

   - `entryMode` は `modeSimple`。
   - ゴール文を `desiredGoal` と `theme` の両方に入れる（trim）。一覧の見出しになる。
   - 現状・方策は trim して空の行を捨て、最大3件。`id` は編集前のものを保つ。
   - 最初の一歩は1件。文字が空でもオブジェクトは残す（`done` だけ残ることがある）。
   - `updatedAt` は `DateTime.now()`。`createdAt` は新規ならそのまま、既存なら `saveOrUpdate` が既存値を保つ（notifier の実装に任せる）。
   - ゴールが空でなければ `status` は `ProjectStatus.inProgress`。ゴールが空なら `preparing`。  
     完了・休憩にはしない。
   - フル用フィールド（`matrix`、`decidedStrategy`、`situationNotes`、`declaration` など）は、この画面から書き換えない。新規はコンストラクタ既定の空でよい。

3. 何も無い新規は保存しない。

   「何も無い」= ゴール空、現状0、方策0、最初の一歩が空。  
   チェックだけ付いて文字が空、も「何も無い」に含める。  
   すでに一覧にある案件を全部空にして戻ったら `delete` する（空行を残さない）。

4. 開き直し — `HistoryListScreen._openProject` の**先頭**で分岐する。

   - `entryMode == modeSimple` なら `SimpleModeScreen(project: project)` を push する。  
     `status` が `preparing` でもウィザードに入れない。ダッシュボードにも入れない。
   - それ以外は今のまま（`preparing` はウィザード、それ以外はダッシュボード）。

5. 一覧カードは作り替えない。`theme` にゴールが入るので見出しはゴールになる。進捗％は Step 1 の `progressRatio` がそのまま出る。

6. 簡易画面のホームで一覧に戻れること。戻ったあと一覧にゴール文の行があること。

7. テスト

   - `test/simple/simple_mode_screen_test.dart` に、ゴールを入れてホーム（または保存が走る操作）したあと `analysisHistoryProvider` に `modeSimple` で残り、`theme` がゴール文であること。全部空のまま戻ると履歴に増えないこと。
   - `test/history/history_list_screen_test.dart` に、簡易案件の▶️でウィザードの「それでは始めましょう」が出ず、簡易画面が出ること。  
     既存の「▶️ opens the dashboard for a project past 作成中」は full 案件のまま通し、壊さない。

### 受け入れ

- 簡易でゴールを書いてホームに戻ると、一覧にその文が出る。
- その行の▶️で簡易画面が開き、現状・方策・チェックが復元される。
- フル案件の▶️は今までどおり。
- 空の新規は一覧に残らない。
- `flutter analyze` が通る。  
  `flutter test test/models/project_test.dart test/simple/simple_mode_screen_test.dart test/history/history_list_screen_test.dart` が通る。

### 触らない

ウィザードのステップ構成、ダッシュボードの中身、操作マニュアル（`docs/user-manual-gas`）、01〜05 のファイル。

---

## 完了報告で書くこと

- 変更ファイル一覧
- 手動確認: ＋ → 簡易、4枠の位置、3件上限、チェックで灰色、ホームで一覧に戻る、▶️で復元、＋ → フルで従来ウィザード。案件0件で「はじめる」（と、使い方を挟む場合は「ホーム画面へ」）でも同じ2択になり、閉じると空の一覧に残る
- コミットはしていないこと
