# 01 — 使い方画面（Chrome AI のコピー案内）

このファイルは Claude Code 向けの実装指示書です。

## Claude への指示テンプレ

```
docs/prompts/01-usage-screen.md のステップに沿って進めて
```

1 Step ずつ:

```
docs/prompts/01-usage-screen.md の Step N をやって
```

各 Step の受け入れを満たし、`flutter analyze` と当該テストが通ってから次へ。  
スコープ外のリファクタ・ドキュメント追加はしない。l10n を足すなら ja/en/vi を揃える。コミットはしない。

---

## 検討メモ（なぜこの切り方か）

osmGradus では使い方画面を 2 本の指示書に分けて後からスワイプと不変条件を足した。osmJiritsu は **完成形を最初から載せる**。途中仕様を再現しない。

移植するのは画面見た目だけではなく、**表示フラグと画面スタックの動線**である。ただし osmJiritsu のルートは `AppRootShell` ではなく `HistoryListScreen` 内の表示切替なので、Gradus のクラス構成はコピーしない。

スタート画面の `•••` ヒントは Gradus が `起動_操作ヒント` をスタートアップから外したのと同じく、**使い方画面へ移す**。スタート画面はブランド＋定義＋チェック＋「はじめる」に戻す。

---

## 機能概要

Chrome AI モードにジャンプして戻ってもペーストできない問い合わせ対策。  
画面下の **コピーボタン（重なった2つの四角）** をタップしていないことが原因。

```
スタート画面（ブランド案内）
  →「はじめる」
  → 使い方画面（コピーボタン＋•••長押し）
  →「ホーム画面へ」
  → 案件一覧（案件0件なら従来どおり新規作成ウィザードへ）
```

参照実装（完成形）:

| 役割 | osmGradus |
|------|-----------|
| 画面 | `lib/views/usage_screen.dart` |
| ルート切替 | `lib/views/app_root_shell.dart` |
| 設定トグル | `lib/views/settings/tts_settings_screen.dart` の「案内」 |
| フラグと不変条件 | `lib/notifiers/app_settings.dart` |
| 画像 | `assets/images/chrome_ai_copy_button.png` |
| テスト | `test/usage_screen_test.dart` / `test/startup_screen_test.dart` / `test/tts_settings_screen_test.dart` |

osmGradus ルート: `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus`

---

## 動線（これが仕様の正本。推測で変えない）

用語:

| 画面上のチェック | 内部フラグ | 意味 |
|------------------|------------|------|
| 「次回から表示しない」OFF | 対応フラグ `== true` | まだ出す |
| 「次回から表示しない」ON（確定後） | 対応フラグ `== false` | 出さない |

チェックはボタンを押したときに初めて保存する。チェックした瞬間にフラグを書き換えない。

osmJiritsu の永続フラグ名は既存スタイルに合わせてよい。意味は Gradus の `showStartupScreen` / `showUsageScreen` と同じ。

推奨:

- 既存 `startScreenAlwaysShow`（起動時にスタート画面を出す）
- 新規 `usageScreenAlwaysShow`（スタートの「はじめる」後に使い方を出す）既定 `true`

セッション用（プロセス内のみ）:

- スタートをこの起動で閉じたか
- 使い方をこの起動で閉じたか

Gradus の `_showingStartup` / `_showingUsage` と同じ。設定で再 ON しても **同じ起動セッションでは重ね表示を出し直さない**。

### A. コールドスタート

| `startScreenAlwaysShow` | 表示 |
|-------------------------|------|
| true（既定） | スタート画面。使い方はまだ出さない |
| false | **案件一覧のみ**。使い方フラグが true でも出さない |

### B. スタートで「はじめる」

今この場でスタートのチェックを ON にしても、**このタップの行き先は使い方フラグだけを見る**。  
保存の前に使い方フラグを読む（スタート OFF の setter が使い方も false にするため）。

| `usageScreenAlwaysShow` | 「はじめる」の着地 |
|-------------------------|-------------------|
| true（既定） | 使い方画面 |
| false | ホーム（案件一覧。0件なら新規ウィザード） |

スタートのチェック ON で「はじめる」→ 今セッションは使い方（usage が true なら）を出す。  
**次回**コールドスタートは A により一覧直通。

### C. 使い方で「ホーム画面へ」

チェック ON なら `usageScreenAlwaysShow = false` を保存してからホームへ。  
OFF ならフラグは true のままホームへ。  
ホームの定義は従来どおり: 案件があれば一覧、0件なら新規作成ウィザード。

### D. 案件一覧で右スワイプ

既存の一覧右スワイプを拡張する。スタート設定が OFF ならラッパー自体を付けない（今どおり動かない）。

| `startScreenAlwaysShow` | `usageScreenAlwaysShow` | 着地 |
|-------------------------|-------------------------|------|
| false | （不問） | **動かない** |
| true | true | **使い方画面**（スタートではない） |
| true | false | **スタート画面** |

### 使い方画面からの戻り

- 「ホーム画面へ」→ ホーム（C）
- 左端からの右スワイプ → **スタート画面**。チェックは保存しない（「ホーム画面へ」を押していないので `dontShowAgain` は確定しない）
- スワイプでスタートに戻ったあと「はじめる」を押したら、usage が ON ならまた使い方へ（往復してよい）

### 設定トグル

- セクション名は Gradus に合わせて「案内」でも、既存「スタートアップ画面」を拡張しても可。スイッチは2つ。
- スタートアップと同じく、ON にしても今のコールドスタート重ね表示は出し直さない。
- スワイプ可否・スワイプ先は **現在の保存値** を見る。

**不変条件:** `usageScreenAlwaysShow == true` は `startScreenAlwaysShow == true` のときだけ許す。

| 操作 | 結果 |
|------|------|
| 設定でスタートを OFF | 使い方も **false に保存**。スイッチは OFF 表示 |
| 設定でスタートを ON に戻す | 使い方は **自動では戻さない** |
| 設定で使い方だけ OFF | スタートは ON のまま（許可） |
| スタートが OFF のとき、使い方スイッチ | **操作不可**。ON にできない |
| スタートの「次回から表示しない」でスタートを false | 同じ不変条件で使い方も false |

連動は **スタートを false にする setter / notifier** に置く。設定 UI だけだと「はじめる」チェックが不整合を残す。

実装例（意味を守る。API 名は既存に合わせる）:

```dart
final showUsageNow = usageAlwaysShow; // 保存の前
if (dontShowAgain) {
  setStartupAlwaysShow(false); // setter が usage も false にする
}
showingStartup = false;
showingUsage = showUsageNow;
```

---

## 共通ルール

1. **Navigator で使い方を push しない。** スタート画面と同じく `HistoryListScreen` 内の表示切替。
2. 既存の `startScreenAlwaysShow` / `startScreenDismissed` の意味を壊さない（既定 true、チェック確定時だけ false、同プロセスでは初期重ねを出し直さない）。
3. 使い方・スタート表示中はボトムツールバーを出さない（今のスタート画面と同じ）。
4. osmGradus の `SwipeToCloseWrapper` を必要ならコピーしてよい。新規ジェスチャライブラリは作らない。一覧側は既存の右スワイプを壊さない（行の削除 Dismissible との共存も維持）。
5. 工場出荷リセット（`AppReset`）は両方のフラグを既定 true に戻す。

### 現状の地図（osmJiritsu）

| 領域 | パス |
|------|------|
| スタート＋一覧 | `lib/history/screens/history_list_screen.dart` |
| 永続化 | `lib/history/data/start_screen_settings_repository.dart` |
| フラグ | `lib/history/state/start_screen_settings_notifier.dart` |
| 設定 | `lib/settings/screens/settings_screen.dart` |
| リセット | `lib/settings/app_reset.dart` |
| l10n | `lib/l10n/app_strings.dart` |
| テスト | `test/history/history_list_screen_test.dart` / `test/settings/settings_screen_test.dart` / `test/settings/app_reset_test.dart` |
| in-memory fake | `test/support/in_memory_start_screen_settings_repository.dart` |
| 資産 | `pubspec.yaml` の `flutter.assets` |

---

## UX 仕様

### スタート画面から移すもの

`_StartScreenHint`（各画面の `•••` 長押し）をスタート画面から外し、使い方画面へ移す。  
アプリアイコン・「osmJiritsu」・自律の定義・チェック・「はじめる」・右上国旗はそのまま。アイコンタップで「自律とは」へ行く動線も残す。

### 使い方画面の中身（上から）

スタートと同じ横パディング 32、右上 `LanguageFlagButton`、縦スクロール。  
アプリアイコンと「osmJiritsu」タイトルは **出さない**（ブランド画面と役割を分ける）。

1. 見出し「使い方」
2. 案内画像 `assets/images/chrome_ai_copy_button.png`（操作バー＋赤い矢印＋ TAP!。横幅はパディング内いっぱい、`BoxFit.contain`、白地＋角丸）。`semanticLabel` を付ける
3. コピー手順（素人向け。**赤い矢印と TAP! が指す、左端の重なった2つの四角**。赤丸には触れない。戻る先は **osmJiritsu**）
4. `•••` 長押しの説明（スタート画面から移したヒント。Gradus の＋長押し／ダブルタップは書かない）
5. 「次回から表示しない」チェック（見た目はスタート踏襲）
6. 「ホーム画面へ」ボタン（スタートの「はじめる」と同型 `FilledButton`）

画像は Gradus からコピーする。新規撮影しない。

```bash
cp "/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus/assets/images/chrome_ai_copy_button.png" \
   "assets/images/chrome_ai_copy_button.png"
```

`pubspec.yaml` の `flutter.assets` に追加する。

### 推奨 l10n（キー名は既存スタイルで可。意味は変えない）

**ja**

| キー | 文言 |
|------|------|
| `使い方_タイトル` | `使い方` |
| `使い方_コピー本文` | `ChromeのAIモードで答えが出たら、画面の下のほうにあるコピーボタンをタップしてください。下の画像の赤い矢印と TAP! が指している、左端の重なった2つの四角です。\n\nこのボタンを押さずにアプリへ戻ると、貼り付けできません。コピーできたら、osmJiritsuに戻ってください。` |
| `使い方_操作ヒント` | `各画面の•••ボタンを長押しすると、その画面の操作方法が表示されます。`（UI では `•••` を `Icons.more_horiz_rounded` にしてよい。スタート画面の `_StartScreenHint` と同じ） |
| `使い方_コピー画像_説明` | `Chrome AIモードのコピーボタン（赤い矢印と TAP!）` |
| `ホーム画面へ` | `ホーム画面へ` |
| `使い方画面` | `使い方画面` |
| `使い方画面_説明` | `Chrome AIのコピー方法と、•••の長押しなどの基本操作を表示します` |
| `スタートアップ画面_説明` | 既存「案件があっても、起動時はスタート画面から始めます。」を使ってよい。無ければ `アプリ起動時に案内画面を表示します` |

**en**

| キー | 文言 |
|------|------|
| `使い方_タイトル` | `How to use` |
| `使い方_コピー本文` | `When Chrome’s AI Mode shows an answer, tap the Copy button near the bottom of the screen — the leftmost icon of two overlapping squares, marked TAP! with a red arrow.\n\nIf you skip this and return to the app, you won’t be able to paste. After copying, come back to osmJiritsu.` |
| `使い方_操作ヒント` | `Long-press the ••• button on each screen to see how to use it.` |
| `使い方_コピー画像_説明` | `Copy button in Chrome AI Mode (red arrow and TAP!)` |
| `ホーム画面へ` | `Go to Home` |
| `使い方画面` | `How-to screen` |
| `使い方画面_説明` | `Show how to copy from Chrome AI and long-press ••• for operation hints` |

**vi**

| キー | 文言 |
|------|------|
| `使い方_タイトル` | `Cách dùng` |
| `使い方_コピー本文` | `Khi AI Mode của Chrome hiện câu trả lời, hãy chạm nút Sao chép ở phía dưới màn hình — biểu tượng ngoài cùng bên trái gồm hai hình vuông chồng lên nhau, có mũi tên đỏ và chữ TAP!.\n\nNếu quay lại ứng dụng mà chưa chạm nút này, bạn sẽ không dán được. Sau khi sao chép, hãy quay lại osmJiritsu.` |
| `使い方_操作ヒント` | `Nhấn giữ nút ••• trên mỗi màn hình để xem cách sử dụng.` |
| `使い方_コピー画像_説明` | `Nút sao chép trong Chrome AI Mode (mũi tên đỏ và TAP!)` |
| `ホーム画面へ` | `Về màn hình chính` |
| `使い方画面` | `Màn hình hướng dẫn` |
| `使い方画面_説明` | `Hiện cách sao chép từ Chrome AI và nhấn giữ ••• để xem cách thao tác` |

本文・`semanticLabel` に「赤丸」「red circle」「khoanh đỏ」を残さない。TAP! と赤い矢印に言及する。

プライバシーの端末保存説明（`プライバシー_保存詳細`）にスタート画面設定と並べて使い方画面設定を足す。

---

## Step 1 — 永続フラグと不変条件

### 目的

使い方画面の ON/OFF を保存し、スタート OFF のとき使い方だけ残らないようにする。

### 指示

1. Hive `app_settings` にキーを足す（例: `usageScreenAlwaysShowAtLaunch`）。既定 true
2. `StartScreenSettingsRepository`（または同等）に load/save を足す。`clear()` で両方消す
3. Riverpod notifier。スタートを false にする経路で usage も false
4. `InMemoryStartScreenSettingsRepository` と `AppReset` を追従。リセット後は両方 true、スタート画面を出し直す
5. 設定画面に使い方スイッチ。`enabled` はスタートが ON のときだけ
6. テスト
   - 両方 true のときスタートを OFF → usage も false
   - スタート OFF のとき使い方スイッチは無効。タップしても usage は false
   - スタートを再び ON → usage は false のまま
   - スタート ON のまま使い方だけ OFF → startup は true
   - 未設定なら usage は true。保存後も保持

### 受け入れ

- [ ] 保存値に「startup false かつ usage true」が残らない
- [ ] 設定 UI で使い方だけ ON にできない
- [ ] スタート再 ON で使い方が勝手に ON に戻らない
- [ ] 工場出荷リセットで両方 true
- [ ] `flutter analyze` 当該テストが通る

---

## Step 2 — 使い方画面ウィジェットと資産

### 目的

説明画面そのものを出す。動線は次 Step。

### 指示

1. 画像をコピーし `pubspec.yaml` に登録
2. `UsageScreen`（名前は既存スタイルで可）を追加。上の UX 仕様どおり
3. l10n を ja/en/vi で追加
4. 単体テスト（`MaterialApp(home: UsageScreen(onContinue: …))`）
   - 見出し・本文・操作ヒント・チェック・「ホーム画面へ」・画像パス
   - チェックしてボタン → `onContinue(true)`、未チェック → `false`
   - ja/en/vi の本文に TAP! があり、赤丸表現が無い
5. この Step では `HistoryListScreen` にまだ組み込まなくてよい（組み込むなら次 Step の受け入れも同時に満たす）

### 受け入れ

- [ ] 画面上は TAP! と赤い矢印付きの操作バー
- [ ] 戻る先のアプリ名は osmJiritsu
- [ ] ＋長押し／ダブルタップの Gradus 文言が無い
- [ ] `flutter analyze` 当該テストが通る

---

## Step 3 — HistoryListScreen の動線

### 目的

A〜D と使い方スワイプを実装する。

### 指示

1. `HistoryListScreen` の表示をスタート／使い方／一覧の3状態にする。Navigator push は使わない
2. `_StartScreen` の `onContinue` を仕様 B にする（保存前に usage を読む）
3. スタートから `_StartScreenHint` を外す
4. 一覧の右スワイプを仕様 D にする
5. 使い方に左端右スワイプ → スタート（フラグ非保存）
6. 既存の「0件ではじめるとウィザード」は、**ホームに着地するとき**に行う（使い方を挟む場合は「ホーム画面へ」側）
7. テスト（`test/history/history_list_screen_test.dart` を拡張。Gradus `test/usage_screen_test.dart` のケースを osmJiritsu に翻訳）
   - 既定: 起動はスタート。使い方はまだ出ない
   - はじめる（usage ON）→ 使い方。「osmJiritsu」タイトルは消える
   - 使い方で「ホーム画面へ」（案件あり）→ 一覧
   - 使い方でチェック ON → usage が false。次回はじめるは一覧（スタートは ON のままならスタートは出る）
   - スタートでチェック ON ＋ usage 元が true → **今セッションは使い方に着地**。保存値は両方 false
   - 案件0件: ホーム着地でウィザード
   - 一覧を右スワイプ（両方 ON）→ 使い方
   - 一覧を右スワイプ（usage OFF, startup ON）→ スタート
   - スタート OFF → 一覧スワイプで動かない
   - 使い方を左端右スワイプ → スタート。フラグは変わらない。はじめるでまた使い方
   - 既存: スタート OFF なら案件ありで一覧直通、アイコンタップで自律とは、はじめるチェックでスタート OFF

### 受け入れ

- [ ] コールドスタートで使い方だけが出ない
- [ ] はじめる（チェック ON）でも、チェック前に usage が true なら今セッションは使い方
- [ ] 使い方スワイプは「次回から表示しない」を保存しない
- [ ] 0件の新規作成動線が残っている
- [ ] `flutter analyze` 当該テストが通る

---

## Step 4 — 設定 UI とレビュー

### 目的

設定から2画面を切り替えられ、文言が動線と矛盾しない。

### 指示

1. 設定にスタート／使い方のスイッチ。使い方はスタート OFF なら disabled
2. `test/settings/settings_screen_test.dart` を更新
3. ヘルプ・プライバシー・操作ガイドに Gradus の＋／ダブルタップが混入していないか確認。安全な修正だけ入れる
4. ゾンビ（スタートに残った `•••` ヒント、使われない l10n）を消す

### 受け入れ

- [ ] 設定で使い方を OFF にすると、一覧スワイプ先がスタートになる
- [ ] スタート OFF で使い方スイッチが押せない
- [ ] `flutter analyze` と関連テストが通る

### 手動確認

1. 初回相当: スタート → はじめる → 使い方 → ホーム画面へ → 一覧
2. 使い方を右スワイプ → スタート → はじめる → また使い方
3. 使い方で「次回から表示しない」→ 次回はじめるは一覧（スタートはまだ出る）
4. スタートで「次回から表示しない」→ 次回起動は一覧。使い方も出ない
5. 設定でスタート OFF → 使い方も OFF。再 ON しても使い方は OFF のまま
6. Chrome AI のコピー図が TAP! 付きで読める
