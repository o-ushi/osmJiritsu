# 07 — iPad 横の2画面

このファイルは Claude Code 向けの実装指示書です。

## Claude への指示テンプレ

まとめて:

```
docs/prompts/07-ipad-landscape-split.md のステップに沿って進めて
```

1 Step だけ:

```
docs/prompts/07-ipad-landscape-split.md の Step N をやって
```

各 Step の受け入れを満たし、`flutter analyze` と当該テストが通ってから次へ。  
途中で赤ならそこで止めて直す。スコープ外のリファクタ・ドキュメント追加はしない。  
l10n を足すなら ja / en / vi を揃える。コミットはしない。

01〜06 とは独立。先にやっていなくてもこのファイルだけで完結する。

Step 1 の回転許可を飛ばして Step 2 に進まない。`Info.plist` だけ変えて `main.dart` のロックを残す、またはその逆、も未完了。

---

## 検討メモ（なぜこの切り方か）

ホームは「案件一覧 → 1件のダッシュボード」なので、横幅があるときだけそれを左右に並べる。

- 左: 案件リスト。幅 340 で固定。一覧の下部ツールバーも左だけ。
- 右: 選んだ案件の `DashboardScreen`。残り幅。未選択は「案件を選んでください」。
- ▶️ は今どおり、行全体のタップでは開かない。

作成ウィザード、SWOT、方策、最初の一歩、見直し、簡易モードは手順の画面なので、リストを残さず今どおり全面に push する。右ペイン用の別 `Navigator` は置かない。設定とヘルプも今の push のまま。列にはしない。

iPhone、iPad の縦、Slide Over や分割表示で細くなったウィンドウは、今の1画面のまま。

---

## 機能概要

分割になる条件は次の関数だけ。デバイス名では判定しない。

```dart
bool homeSplitActive(Size size) =>
    size.width >= 900 && size.width > size.height;
```

論理ピクセル。iPad を横いっぱいにした幅（1024 以上）で true。iPad の縦、iPhone、幅 900 未満の Slide Over / 1/2 分割は false。

分割中の ▶️:

| 案件 | 動き |
|------|------|
| フルで `status != preparing` | 右にダッシュボードを出す。route は push しない |
| 簡易モード | 今どおり `SimpleModeScreen` を全面 push。選択は変えない |
| 作成中（`preparing`） | 今どおりウィザード（分類済みならその上に SWOT）を全面 push。選択は変えない |

分割していないときの ▶️ は、今の `_openProject` の push のまま。

選択中の行だけ、分割がオンのとき枠 2px `AppPalette.mintDark`。それ以外のカード色は変えない。

選択 id が一覧に無い（削除された、まだ選んでいない）ときは右を空状態にする。`DashboardScreen` の `orElse` で消した案件を残さない。

ダッシュボードを右に埋め込むとき:

- `DashboardScreen` に `embedded`（既定 `false`）を足す。分割の右だけ `true`。
- `embedded` で削除に成功したあとは `Navigator.pop` しない。選択 id が履歴から消えるので、シェルが空状態にする。
- 埋め込み側に `project-dashboard` の route 名は付けない。
- 振り返り・SWOT・方策・最初の一歩・宣言文の編集は、今どおりルート `Navigator` に push してリストごと覆う。
- 子画面のリターン（`ProjectNavigation.popToDashboard`）は変えない。名前付きダッシュボード route が無いときはホームまで戻り、右ペインのダッシュボードが残る。

スタート画面と使い方画面が出ているあいだは分割しない。今の全画面のまま。

向きを変えても、すでに push されている route は剥がさない。分割はホームが最前面で、幅条件を満たすときだけ。縦に戻すと一覧だけになり、選択 id はメモリに残す。また横にすると同じ案件が右に出る。縦でダッシュボードを見るには、今どおり ▶️ の push。

`project_export_screen.dart` の `dashboardRoute` は変えない。書き出し後は今どおり全面のダッシュボード。

---

## 現状の地図

| 領域 | パス |
|------|------|
| 起動時の回転ロック | `lib/main.dart` の `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` |
| iOS の回転許可 | `ios/Runner/Info.plist` の `UISupportedInterfaceOrientations`（いま縦のみ。`~ipad` キーは無い） |
| Android の縦固定 | `android/app/src/main/AndroidManifest.xml` の `android:screenOrientation="portrait"`。**触らない** |
| ホーム | `lib/history/screens/history_list_screen.dart` の `_openProject` |
| ▶️ | `lib/history/widgets/history_session_card.dart`。tooltip は「ダッシュボードへ」 |
| ダッシュボード | `lib/dashboard/screens/dashboard_screen.dart`。削除成功で `Navigator.pop` |
| 子画面の戻り | `lib/history/project_navigation.dart` の `popToDashboard` |
| 文言 | `lib/l10n/app_strings.dart`（ja / en / vi） |
| 一覧テスト | `test/history/history_list_screen_test.dart`。表面は 1080×2400（縦）なので、このままだと分割はオフ |

---

## Step 1 — iPad の回転を設定ファイルで許可する

### 目的

iPad だけ横にできるようにする。iPhone と Android は縦のまま。

`main.dart` の `setPreferredOrientations([portraitUp])` は Info.plist より強い。plist に横を足しても、この呼び出しが残っていると iPad は横にならない。両方直す。

### 指示

1. `ios/Runner/Info.plist`

   - 既存の `UISupportedInterfaceOrientations` は `UIInterfaceOrientationPortrait` だけ。iPhone 用なので、横を足さない。
   - 直後に iPad 用キーを足す。中身はこの4つ。

   ```xml
   <key>UISupportedInterfaceOrientations~ipad</key>
   <array>
       <string>UIInterfaceOrientationPortrait</string>
       <string>UIInterfaceOrientationPortraitUpsideDown</string>
       <string>UIInterfaceOrientationLandscapeLeft</string>
       <string>UIInterfaceOrientationLandscapeRight</string>
   </array>
   ```

2. `lib/main.dart`

   - iOS では `SystemChrome.setPreferredOrientations` を呼ばない。回転は Info.plist に任せる。
   - iOS 以外は今どおり `DeviceOrientation.portraitUp` だけ。Android の縦固定を外さない。
   - 起動時の画面サイズや `shortestSide` で向きを決めない。その時点のサイズは信頼できない。
   - 判定は `defaultTargetPlatform != TargetPlatform.iOS`。`dart:io` の `Platform` は使わない。

   形:

   ```dart
   if (defaultTargetPlatform != TargetPlatform.iOS) {
     await SystemChrome.setPreferredOrientations([
       DeviceOrientation.portraitUp,
     ]);
   }
   ```

3. 他のファイルに `setPreferredOrientations` を足さない。`android/` と `macos/` の設定ファイルは変えない。

### 受け入れ

- iPhone 用キーは縦だけ。iPad 用キーに縦・逆さ・左右の横がある。
- iOS の起動経路に `portraitUp` のロックが残っていない。
- Android の `screenOrientation="portrait"` と、iOS 以外の `portraitUp` ロックはそのまま。
- `flutter analyze` が通る。

### 触らない

画面レイアウト、ナビ、l10n、テストの表面サイズ。

---

## Step 2 — 横で幅が足りるときだけ一覧とダッシュボードを左右に置く

### 目的

ホームが最前面で `homeSplitActive` が true のとき、左 340 に一覧、右にダッシュボード。それ以外の見た目と遷移は今のまま。

### 指示

1. 文言を `app_strings.dart` の ja / en / vi に足す。キーは日本語。

   | キー | ja | en | vi |
   |----|----|----|----|
   | 案件を選んでください | 案件を選んでください | Select a project | Hãy chọn dự án |

2. 選択 id は `String?` の Notifier を `lib/history/state/` に置く。案件 JSON には書かない。初期値は null。一覧からその id が消えたら、読む側は未選択として扱う（Notifier を必ず null に戻さなくてもよい。シェルが「一覧に無い id は未選択」とすること）。

3. `homeSplitActive` は `lib/history/` の公開関数にする。条件は検討メモの1行だけ。

4. `HistoryListScreen` で、スタート画面でも使い方画面でもなく、`homeSplitActive` が true のときだけ `Row` にする。

   - 左: 幅 340。今の一覧と `HistoryBottomToolbar`。ツールバーを画面全幅に伸ばさない。
   - 境界: 幅 1。色は既存の `AppPalette` から薄いもの（新しい色は足さない）。
   - 右: 残り。選択中のフル案件（簡易でなく、`preparing` でない）なら `DashboardScreen(embedded: true)`。そうでなければ中央に「案件を選んでください」（`AppPalette.inkMuted`）。

5. `_openProject` は、`homeSplitActive(MediaQuery.sizeOf(context))` が true かつフルかつ `preparing` でないときだけ、選択 id をその案件にして return する。簡易と作成中、および分割オフのときは今の push をそのまま実行する。

6. 選択中のカードは、分割オンのときだけ枠 2px `AppPalette.mintDark`。`HistorySessionCard` に bool を1つ足してよい。既定 false。

7. `DashboardScreen.embedded` の既定は false。true のとき、削除成功後の `Navigator.pop` を呼ばない。false のときの pop は残す。

8. 右ペインに `Navigator` を新設しない。子画面・設定・ヘルプ・簡易・ウィザードの push 先は今のルートのまま。

### 受け入れ

- 幅 900 未満、または縦のときは、▶️ が今どおり route を push する。
- 幅 900 以上かつ横のとき、実施中のフル案件の ▶️ は route を増やさず、右にそのテーマのダッシュボードが出る。左の一覧と左の下部ツールバーが残る。
- 同じ条件で、簡易と作成中の ▶️ は全面の画面を push する。
- 未選択の右ペインに「案件を選んでください」が出る。
- 埋め込み中に削除した案件が右に残らない。
- `flutter analyze` が通る。`flutter test test/history/history_list_screen_test.dart` が通る。既存テストの表面は 1080×2400 の縦なので、分割オフの経路のまま通す。表面サイズを変えて既存アサーションを合わせない。

### 触らない

ダッシュボードの中身の並べ方、ウィザード、Android / macOS の回転設定、`project_export_screen.dart` の `dashboardRoute`。

---

## Step 3 — 分割のウィジェットテスト

### 目的

横の広い表面と、今の縦の表面で、▶️ の行き先が分かれることを固定する。

### 指示

`test/history/history_list_screen_test.dart` に足す。既存の `pumpScreen`（1080×2400）は変えない。広い表面は、そのテストの中だけ `tester.view.physicalSize` と `devicePixelRatio = 1` を変える。`addTearDown` で `tester.view.resetPhysicalSize()` と `resetDevicePixelRatio()` する。

表面:

- 分割オン: `Size(1194, 834)`
- 分割オフの確認が要るとき: 既存の 1080×2400 のまま

ケース:

1. 実施中（`ProjectStatus.inProgress`）のフル案件を1件置く。1194×834 で ▶️（tooltip「ダッシュボードへ」）を押す。`DashboardScreen` がいて、テーマ文字が見える。`Navigator` の route はホームの1枚のまま（その上にダッシュボード route が乗っていない）。右の空状態文言は無い。
2. 同じ表面で、作成中（`preparing`）の ▶️ はウィザードに入る（既存の縦テストと同じ到達点。分類前ならテーマ画面）。
3. 同じ表面で、簡易案件の ▶️ は `SimpleModeScreen`。
4. 1194×834、案件は実施中が1件、まだ ▶️ していない。`案件を選んでください` が見える。一覧のテーマも見える。
5. 1080×2400 で実施中の ▶️ は、今どおりダッシュボードが別 route になる（一覧のツールバーが、ダッシュボードの下に同時に出ていない）。

既存テストが赤くなったら、分割の実装側を直す。縦の表面で右ペインや空状態文言が出ているのが原因なら、条件が縦でも true になっている。

### 受け入れ

- 上の5つが通る。
- `flutter analyze` が通る。
- `flutter test test/history/history_list_screen_test.dart` が通る。

### 触らない

Step 1 の plist と `main.dart`。テストから回転 API は呼ばない。

---

## 完了報告に書くこと

- 変えたファイル
- iPad 用の plist キーと、iOS で `setPreferredOrientations` を呼ばないこと
- 実機確認: iPad 横で一覧とダッシュボードが左右に出ること。iPhone を横にしても縦のままであること。ウィザード中は全面のままであること
