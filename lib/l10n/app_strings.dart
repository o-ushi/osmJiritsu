import 'app_language.dart';

/// osmJiritsu's UI string catalog.
///
/// Ports the mechanism from osmWashabe's `lib/l10n/app_strings.dart`
/// almost unchanged: keys are the Japanese text itself (so callers just
/// wrap an existing literal in `.tr(lang)` instead of inventing a
/// separate symbolic key), each language is a flat `Map<String, String>`,
/// and lookup falls back to Japanese and finally to the raw key if a
/// translation is ever missing — a UI can never show a blank string.
abstract final class AppStrings {
  static String text(String key, AppLanguage language) {
    return _data[language]?[key] ?? _data[AppLanguage.japanese]?[key] ?? key;
  }

  static const _data = <AppLanguage, Map<String, String>>{
    AppLanguage.japanese: _ja,
    AppLanguage.english: _en,
    AppLanguage.vietnamese: _vi,
  };

  static const _ja = <String, String>{
    // ── Step 1: theme ────────────────────────────────────────────────
    'それでは始めましょう': 'それでは始めましょう',
    'まずテーマを決めよう': 'まずテーマを決めよう',
    'テーマ': 'テーマ',
    '例）新しいキャリアについて': '例）新しいキャリアについて',
    'ゴールを考える': 'ゴールを考える',

    // ── Step 2: goal (在りたい姿 / 在りたくない姿) ──────────────────────
    'ゴールを教えてください': 'ゴールを教えてください',
    '「在りたい姿」と「在りたくない姿」、両方の向きから考えてみましょう。':
        '「在りたい姿」と「在りたくない姿」、両方の向きから考えてみましょう。',
    '在りたい姿': '在りたい姿',
    'これが実現すれば十分、と言える理想の姿（充分条件）': 'これが実現すれば十分、と言える理想の姿（充分条件）',
    '例）自分の強みを活かして、納得感のある転職をしたい': '例）自分の強みを活かして、納得感のある転職をしたい',
    '在りたくない姿': '在りたくない姿',
    'これだけは避けたい、という最低ライン（必要条件）': 'これだけは避けたい、という最低ライン（必要条件）',
    '例）妥協して、納得感のないまま転職すること': '例）妥協して、納得感のないまま転職すること',
    'アイデアを出してみる': 'アイデアを出してみる',

    // ── Step 3: idea dump ────────────────────────────────────────────
    'テーマ: %@': 'テーマ: %@',
    '思いつくままに、どんどん追加しよう': '思いつくままに、どんどん追加しよう',
    '%lld件を分類する': '%lld件を分類する',
    '思いついたことを入力…': '思いついたことを入力…',
    '「%@」について\n思いつくことを何でも入力してみましょう': '「%@」について\n思いつくことを何でも入力してみましょう',

    // ── Step 4: quick classification ─────────────────────────────────
    '%lld / %lld 個 完了': '%lld / %lld 個 完了',
    '戻す': '戻す',
    '戻る': '戻る',
    'これって、良いこと？ 気になること？': 'これって、良いこと？ 気になること？',
    'それって、自分次第で変えられる？': 'それって、自分次第で変えられる？',
    '良いこと': '良いこと',
    '自信がある・嬉しい': '自信がある・嬉しい',
    '気になること': '気になること',
    '不安・課題に感じる': '不安・課題に感じる',
    '自分次第': '自分次第',
    '頑張れば変えられる': '頑張れば変えられる',
    'まわりの状況': 'まわりの状況',
    '環境や他人に左右される': '環境や他人に左右される',
    '全部答えられました！': '全部答えられました！',
    '実はこれ、SWOT分析になっています。\n出来上がったマトリクスを見てみましょう。':
        '実はこれ、SWOT分析になっています。\n出来上がったマトリクスを見てみましょう。',
    'マトリクスを確認する': 'マトリクスを確認する',

    // ── Step 4: SWOT matrix ───────────────────────────────────────────
    '履歴に戻る': '履歴に戻る',
    'SWOTマトリクス': 'SWOTマトリクス',
    '今の状況': '今の状況',
    'はじめからやり直す': 'はじめからやり直す',
    '強み': '強み',
    '機会': '機会',
    '弱み': '弱み',
    '脅威': '脅威',
    'AIに方策を相談する': 'AIに方策を相談する',
    '違うと感じたら、カードを長押しして別の枠にドラッグしてみてください': '違うと感じたら、カードを長押しして別の枠にドラッグしてみてください',
    '内容を編集': '内容を編集',
    '項目を追加': '項目を追加',
    'どの枠に入れますか？': 'どの枠に入れますか？',
    '追加': '追加',
    'ここに置く': 'ここに置く',
    'なし': 'なし',

    // ── Step 5-8: strategy decision (自律の中心) ─────────────────────────
    '方策を決める': '方策を決める',
    '方策_Google送信確認_タイトル': '方策提案のためGoogleに送信しますか？',
    '方策_Google送信確認_本文':
        '方策の参考提案を得るため、テーマ、在りたい姿、在りたくない姿、SWOT全文（強み・弱み・機会・脅威）をGoogle LLCのGoogle検索（AIモード）へ送信します。内容には個人情報や機微な情報が含まれる可能性があります。検索内容はブラウザやGoogleアカウントの履歴に残る場合があります。',
    '最初の一歩_Google送信確認_タイトル': '最初の一歩の提案のためGoogleに送信しますか？',
    '最初の一歩_Google送信確認_本文':
        '最初の一歩の参考提案を得るため、テーマ、在りたい姿、決めた方策をGoogle LLCのGoogle検索（AIモード）へ送信します。内容には個人情報や機微な情報が含まれる可能性があります。検索内容はブラウザやGoogleアカウントの履歴に残る場合があります。',
    '同意してGoogleへ送信': '同意してGoogleへ送信',
    'Chromeを開いています…': 'Chromeを開いています…',
    'Chromeを開けませんでした': 'Chromeを開けませんでした',
    'Chromeを開けませんでした: %@': 'Chromeを開けませんでした: %@',
    'もう一度試す': 'もう一度試す',
    'Chromeでの回答を確認してください': 'Chromeでの回答を確認してください',
    'AIの回答をコピーしたら、この画面に戻って\n下のボタンをタップしてください。':
        'AIの回答をコピーしたら、この画面に戻って\n下のボタンをタップしてください。',
    '貼り付けて確認する': '貼り付けて確認する',
    'もう一度Chromeを開く': 'もう一度Chromeを開く',
    '読み取れませんでした': '読み取れませんでした',
    'もう一度貼り付ける': 'もう一度貼り付ける',
    'Chromeを開き直す': 'Chromeを開き直す',
    'クリップボードが空でした。Chromeで回答をコピーしてから、もう一度貼り付けてみてください。':
        'クリップボードが空でした。Chromeで回答をコピーしてから、もう一度貼り付けてみてください。',
    '方策を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。':
        '方策を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。',
    'AIが考えた5つの方策': 'AIが考えた5つの方策',
    '「採用済／未採用」はタップで切り替えられます。文言を直したいときは案を長押しで編集できます。':
        '「採用済／未採用」はタップで切り替えられます。文言を直したいときは案を長押しで編集できます。',
    '採用済': '採用済',
    '未採用': '未採用',
    '方策を編集': '方策を編集',
    'あなたの方策': 'あなたの方策',
    'AIの提案にない、独自の方策があれば書く': 'AIの提案にない、独自の方策があれば書く',
    '自律度をチェックする': '自律度をチェックする',
    '自律度チェック': '自律度チェック',
    '決めた方策を、3つの要素から見直してみましょう。': '決めた方策を、3つの要素から見直してみましょう。',
    '自分で決められるか？': '自分で決められるか？',
    '結果が分かりやすいか？': '結果が分かりやすいか？',
    'ゴールを共有できているか？': 'ゴールを共有できているか？',
    '%lld / 3 満たしている': '%lld / 3 満たしている',
    '納得した': '納得した',
    '方策を編集する': '方策を編集する',
    'AIに再度相談する': 'AIに再度相談する',
    '長押しで今の状況を編集': '長押しで今の状況を編集',
    '長押しでテーマを編集': '長押しでテーマを編集',
    '長押しでゴールを編集': '長押しでゴールを編集',
    '長押しで方策を見直す': '長押しで方策を見直す',
    '長押しで最初の一歩を見直す': '長押しで最初の一歩を見直す',
    '方策を見直す': '方策を見直す',
    '最初の一歩を見直す': '最初の一歩を見直す',
    '長押しで宣言文を編集': '長押しで宣言文を編集',
    '長押しで振り返りを編集': '長押しで振り返りを編集',
    '振り返りを編集': '振り返りを編集',
    'この振り返りを削除しますか？': 'この振り返りを削除しますか？',
    '宣言文を編集': '宣言文を編集',
    '方策を決めた': '方策を決めた',
    '自律度チェック: %lld / 3': '自律度チェック: %lld / 3',

    // ── Step 9-10: first step + declaration (自律計画作成の完了) ─────────
    '最初の一歩を決める': '最初の一歩を決める',
    '最初の一歩を決めた': '最初の一歩を決めた',
    'AIが考えた10個の最初の一歩': 'AIが考えた10個の最初の一歩',
    'あなたの最初の一歩': 'あなたの最初の一歩',
    '最初の一歩を編集': '最初の一歩を編集',
    'AIの提案にない、独自の最初の一歩があれば書く': 'AIの提案にない、独自の最初の一歩があれば書く',
    '宣言文を確認する': '宣言文を確認する',
    '最初の一歩を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。':
        '最初の一歩を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。',
    '宣言文': '宣言文',
    '上司や仲間にそのまま送れる、ひとことにしましょう。': '上司や仲間にそのまま送れる、ひとことにしましょう。',
    '最初の一歩: %@': '最初の一歩: %@',
    '最初の一歩を編集する': '最初の一歩を編集する',
    '決定': '決定',
    '自律計画ができました': '自律計画ができました',
    'あとで（履歴に戻る）': 'あとで（履歴に戻る）',

    // ── Step 11: export ────────────────────────────────────────────────
    'エクスポート': 'エクスポート',
    'エクスポートする': 'エクスポートする',
    'JSONバックアップ': 'JSONバックアップ',
    'JSONを取り込む': 'JSONを取り込む',
    'まとめを共有': 'まとめを共有',
    '上司や仲間にそのまま送れます。': '上司や仲間にそのまま送れます。',
    '共有_テキスト説明':
        'テキストで共有します（メールやメッセージアプリなど）。要報は計画の要約、詳報はダッシュボードの全項目です。JSONバックアップはホーム画面の「データ」から行えます。',
    '共有する': '共有する',
    '共有': '共有',
    '要報': '要報',
    '詳報': '詳報',
    '共有形式を選んでください': '共有形式を選んでください',
    '共有_要報説明': '短い形式（テーマ・ゴール・方策・最初の一歩・宣言文）。完了直後のまとめ共有と同じ内容です。',
    '共有_詳報説明': 'ダッシュボードの全項目（SWOT・振り返り・期限など）。日々の進捗共有向けです。',
    '短い形式（テーマ・ゴール・方策・最初の一歩・宣言文）':
        '短い形式（テーマ・ゴール・方策・最初の一歩・宣言文）',
    'ダッシュボードの全項目': 'ダッシュボードの全項目',
    'リターン': 'リターン',
    '完了': '完了',
    '方策': '方策',
    '最初の一歩': '最初の一歩',
    '作成中': '作成中',
    '実施中': '実施中',
    '休憩中': '休憩中',

    // ── Step 6: history ────────────────────────────────────────────────
    '履歴の読み込みに失敗しました\n%@': '履歴の読み込みに失敗しました\n%@',
    'エクスポートできる分析がまだありません': 'エクスポートできる分析がまだありません',
    '%lld件の分析を読み込みました': '%lld件の分析を読み込みました',
    '読み込みに失敗しました: %@': '読み込みに失敗しました: %@',
    '自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。':
        '自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。',
    '各画面の': '各画面の',
    'ボタン長押しで\n操作方法を確認できます': 'ボタン長押しで\n操作方法を確認できます',
    '操作方法': '操作方法',
    '案内に従って操作': '案内に従って操作',
    '操作方法_ダッシュボード':
        '1️⃣ 閲覧/更新：▶︎をタップ\n2️⃣ 案件削除：🗑️をタップするか左スワイプ\n3️⃣ テーマ編集：🖊️をタップ\n4️⃣ お気に入り登録：☆をタップ\n5️⃣ 新規追加：＋をタップ',
    '操作方法_SWOT':
        '1️⃣ 分類を変更：項目をドラッグ\n2️⃣ 項目を編集：項目をタップ\n3️⃣ 項目を削除：項目をSWOT枠外にドラッグ\n4️⃣ 項目を追加：＋をタップ',
    '操作方法_方策最初の一歩': '1️⃣ 編集：項目を長押し',
    '操作方法_宣言': '1️⃣ 編集：項目をタップ',
    '次回から表示しない': '次回から表示しない',
    'はじめる': 'はじめる',
    'キーワード': 'キーワード',
    '小さなくるくる': '小さなくるくる',
    '唱って躍れる': '唱って躍れる',
    '分析結果': '分析結果',
    '削除': '削除',
    'この分析を削除しますか？': 'この分析を削除しますか？',
    '元に戻すことはできません。': '元に戻すことはできません。',
    'キャンセル': 'キャンセル',
    '削除する': '削除する',
    'やっぱりやらない': 'やっぱりやらない',
    '方策を取り消しますか？': '方策を取り消しますか？',
    '最初の一歩を取り消しますか？': '最初の一歩を取り消しますか？',
    '文言を編集': '文言を編集',
    '見直す方法を選んでください': '見直す方法を選んでください',
    '見直す_文言編集説明': 'いまの文言だけ直します（AIは使いません）',
    '見直す_AI再相談説明': 'Chrome AI Modeで候補を見直し／再生成します',
    '壁打ちメモ': '壁打ちメモ',
    '作成中_ホームで一覧': 'ホームボタンで案件一覧に戻れます',
    'タップまたは長押しで編集': 'タップまたは長押しで編集',
    'タップで今の状況を編集': 'タップで今の状況を編集',
    '(テーマ未設定)': '(テーマ未設定)',

    // ── Home: 登録案件リスト ───────────────────────────────────────────
    '編集': '編集',
    'お気に入りに追加': 'お気に入りに追加',
    'お気に入り解除': 'お気に入り解除',
    'テーマを編集': 'テーマを編集',
    '保存': '保存',
    'ダッシュボードへ': 'ダッシュボードへ',
    '新規追加': '新規追加',
    'データ': 'データ',
    'その他': 'その他',
    'ヘルプ': 'ヘルプ',
    'ホーム': 'ホーム',
    'インポート': 'インポート',

    // ── Settings ───────────────────────────────────────────────────────
    '設定': '設定',
    'プライバシー': 'プライバシー',
    'プライバシーとデータ': 'プライバシーとデータ',
    '言語': '言語',
    'アプリの表示言語を変更できます。': 'アプリの表示言語を変更できます。',
    '言語_設定が正式': '表示言語の正式な設定場所です。スタート画面の旗ボタンでも同じ言語を切り替えられます。',
    '言語_スタートショートカット': '設定画面でも変更できます',
    '設定_削除はプライバシーへ': 'プライバシーとデータ画面で削除できます',
    'スタートアップ画面': 'スタートアップ画面',
    '起動時にスタート画面を表示': '起動時にスタート画面を表示',
    '案件があっても、起動時はスタート画面から始めます。': '案件があっても、起動時はスタート画面から始めます。',
    'すべてのデータを初期化': 'すべてのデータを初期化',
    '本当に初期化しますか？': '本当に初期化しますか？',
    '初期化の説明':
        '端末内のすべてのデータと設定を削除し、初めてインストールした状態に戻します。この操作は取り消せません。',
    '初期化': '初期化',
    '初期化しました': '初期化しました',

    // ── Privacy & data (Gradus-equivalent disclosure) ─────────────────
    'プライバシー_外部送信': '送信先・項目・目的',
    'Google AIによる方策提案': 'Google AIによる方策提案',
    'プライバシー_方策説明':
        '方策提案を希望した場合、Google LLCが提供するGoogle検索（AIモード）へ、テーマ、在りたい姿、在りたくない姿、SWOT全文（強み・弱み・機会・脅威）を送信します。目的は方策の参考提案を得ることです。送信のたびに同意を確認します。Googleの規約・プライバシーポリシーが適用されます。',
    'Google AIによる最初の一歩提案': 'Google AIによる最初の一歩提案',
    'プライバシー_最初の一歩説明':
        '最初の一歩の提案を希望した場合、Google LLCが提供するGoogle検索（AIモード）へ、テーマ、在りたい姿、決めた方策を送信します。目的は最初の一歩の参考提案を得ることです。送信のたびに同意を確認します。Googleの規約・プライバシーポリシーが適用されます。',
    'プライバシーポリシー': 'プライバシーポリシー',
    'プライバシー_ポリシー本文_詳細': '外部送信、保存期間、削除方法などの詳細を記載しています。',
    '関連ポリシー': '関連ポリシー',
    'Google プライバシーポリシー': 'Google プライバシーポリシー',
    'Apple プライバシーポリシー': 'Apple プライバシーポリシー',
    'プライバシー_関連ポリシー_詳細':
        'Google検索（AIモード）への送信にはGoogleのポリシーが適用されます。App Store経由の配信・端末バックアップ等にはAppleの規約が適用される場合があります。',
    'プライバシー_端末保存': '端末での保存',
    'プライバシー_保存詳細':
        'テーマ、ゴール、SWOT分析、方策、最初の一歩、宣言文、振り返り、案件の並び順、表示言語、スタート画面設定は端末内のHiveデータベースに保存します。クラウド同期は行いません。',
    'プライバシー_保持削除詳細':
        '保存データは、ユーザーが個別に削除するか、「すべてのデータを削除」を行うまで保持します。すでにGoogleへ送信済みのデータの保持・削除はGoogleのポリシーに従い、本アプリから削除できません。JSONバックアップで共有先に保存したコピーも、本アプリからは削除できません。',
    'プライバシー_JSONバックアップ案内':
        '案件のJSONバックアップ／取り込みは、ホームや作成フロー下部の「データ」メニューから行えます。',
    'すべてのデータを削除': 'すべてのデータを削除',
    'プライバシー_削除確認':
        'Hiveの分析履歴・設定と、一時バックアップファイルを削除します。元に戻せません。',
    '端末内のアプリデータを削除しました': '端末内のアプリデータを削除しました',

    // ── Help ───────────────────────────────────────────────────────────
    'HELP': 'HELP',
    'osmJiritsu': 'osmJiritsu',
    'バージョン %@ (%@)': 'バージョン %@ (%@)',
    '自律とは': '自律とは',
    'ゴールと今の状況の差を無くすために、自分で考えて行動すること':
        'ゴールと今の状況の差を無くすために、自分で考えて行動すること',
    'テーマとゴール（在りたい姿／在りたくない姿）を決める':
        'テーマとゴール（在りたい姿／在りたくない姿）を決める',
    '現状を整理し、SWOTから方策を自分で決める': '現状を整理し、SWOTから方策を自分で決める',
    '最初の一歩を宣言し、振り返りながら進める': '最初の一歩を宣言し、振り返りながら進める',
    '自律の3要素': '自律の3要素',
    '方策や行動を決めるとき、この3つを満たしているか振り返ってみましょう。':
        '方策や行動を決めるとき、この3つを満たしているか振り返ってみましょう。',
    '自律の定義': '自律の定義',
    '（参考）自立とは': '（参考）自立とは',
    '自分以外の何ものにも依存しない状態。': '自分以外の何ものにも依存しない状態。',
    '自立できていない、依存している人は、自分のうまく行かない状態の責任や自分の感情、思考の原因すら周りの人や環境のせいにする。':
        '自立できていない、依存している人は、自分のうまく行かない状態の責任や自分の感情、思考の原因すら周りの人や環境のせいにする。',
    '自立には経済的自立、行動的自立、精神的自立があり、いずれも自律と密接に関係している（自律している人は自立できる）。':
        '自立には経済的自立、行動的自立、精神的自立があり、いずれも自律と密接に関係している（自律している人は自立できる）。',
    '自律できていない人にありがちな行動': '自律できていない人にありがちな行動',
    '言われたことだけやる': '言われたことだけやる',
    '不平、不満ばっかり': '不平、不満ばっかり',
    '無感動、無関心': '無感動、無関心',
    'できない理由だけで、どうすればできるか？がない': 'できない理由だけで、どうすればできるか？がない',
    '一見クールでカッコよく見えたりする。的を射てるし。周囲を白けさせるパワー大。口癖は「でもさ...」':
        '一見クールでカッコよく見えたりする。的を射てるし。周囲を白けさせるパワー大。口癖は「でもさ...」',
    '他人から言われる前に動く': '他人から言われる前に動く',
    '主導権は自分にあるのだと意識すること': '主導権は自分にあるのだと意識すること',
    '方策の粒度を細かくすること': '方策の粒度を細かくすること',
    '結果を見える化して視覚的に成果を実感すること': '結果を見える化して視覚的に成果を実感すること',
    '周囲からサポートを得る': '周囲からサポートを得る',
    '言語化することで思いが現実性を持つ': '言語化することで思いが現実性を持つ',
    '動機づけマトリクス': '動機づけマトリクス',
    '方策を考える際、動機づけマトリクスを意識すると良い。': '方策を考える際、動機づけマトリクスを意識すると良い。',
    '内発的動機づけ': '内発的動機づけ',
    '外発的動機づけ': '外発的動機づけ',
    '自分の内面的な興味・関心、探究心、楽しさなどが原動力となる状態。':
        '自分の内面的な興味・関心、探究心、楽しさなどが原動力となる状態。',
    '＜特徴＞': '＜特徴＞',
    '行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。':
        '行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。',
    '＜具体例＞': '＜具体例＞',
    '興味のある分野について自主的に深く調べる。': '興味のある分野について自主的に深く調べる。',
    '純粋に人を喜ばせたくて仕事に取り組む。': '純粋に人を喜ばせたくて仕事に取り組む。',
    '＜メリット・デメリット＞': '＜メリット・デメリット＞',
    '⭕️ モチベーションが長持ちする': '⭕️ モチベーションが長持ちする',
    '❌ 本人の興味に依存するため即効性がない': '❌ 本人の興味に依存するため即効性がない',
    '❌ 誰にでも同じように適用することは困難': '❌ 誰にでも同じように適用することは困難',
    '報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」をきっかけとして行動を促すこと。':
        '報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」をきっかけとして行動を促すこと。',
    '内発か？外発か？': '内発か？外発か？',
    '内発と外発は対立するものではなく組み合わせもの。外発をきっかけに始めて、その内、それ自体が楽しくなる...（エンハンシング効果）。':
        '内発と外発は対立するものではなく組み合わせもの。外発をきっかけに始めて、その内、それ自体が楽しくなる...（エンハンシング効果）。',
    '実行のステップを細かくして達成感を感じやすくすること。':
        '実行のステップを細かくして達成感を感じやすくすること。',
    '唱（ショウ）': '唱（ショウ）',
    '昌には、盛んで明るいとか、美しいことばという意味があり、それと口にすることから、唱は、うたう、となえるの意味を表す。また、昌の音は、高く上げるという意味を含むから、唱は、声を高くあげること、あるいは、「人より先に大声を上げてリードする」ことである。':
        '昌には、盛んで明るいとか、美しいことばという意味があり、それと口にすることから、唱は、うたう、となえるの意味を表す。また、昌の音は、高く上げるという意味を含むから、唱は、声を高くあげること、あるいは、「人より先に大声を上げてリードする」ことである。',
    '唱義：人に先立って正しい道をとなえる': '唱義：人に先立って正しい道をとなえる',
    '躍（ヤク）': '躍（ヤク）',
    '翟には高く抜き出る意味がある。躍は「すばやくおどりあがる」ことである。':
        '翟には高く抜き出る意味がある。躍は「すばやくおどりあがる」ことである。',
    '躍動：おどりうごく、いきいきと活動する': '躍動：おどりうごく、いきいきと活動する',
    'つまり「唱って躍れる」とは「周りを引っ張って、元気に前に進める」「自分の考えを話して、みんなと共有できる」ことである。':
        'つまり「唱って躍れる」とは「周りを引っ張って、元気に前に進める」「自分の考えを話して、みんなと共有できる」ことである。',
    '誰かに話すことによって自分の中で漠然としていた夢が、どんどんリアリティを持ち、少しずつ形になり、ビジョンになっていく。これを繰り返す内にビジョンはより明確になり、とうとう的確な言葉で表現できるようになったとき、初めて明快な物語として、リアリティのある戦略として、それを人に伝達し、実際に行動に移していく事ができる。':
        '誰かに話すことによって自分の中で漠然としていた夢が、どんどんリアリティを持ち、少しずつ形になり、ビジョンになっていく。これを繰り返す内にビジョンはより明確になり、とうとう的確な言葉で表現できるようになったとき、初めて明快な物語として、リアリティのある戦略として、それを人に伝達し、実際に行動に移していく事ができる。',
    '― 伊藤守「リーダーになる人ならない人」': '― 伊藤守「リーダーになる人ならない人」',

    // ── Dashboard ──────────────────────────────────────────────────────
    '登録日': '登録日',
    '最終更新日': '最終更新日',
    '期限': '期限',
    '未設定': '未設定',
    '期限を設定': '期限を設定',
    '備考': '備考',
    '備考を入力…': '備考を入力…',
    '現況を変更': '現況を変更',
    '振り返り': '振り返り',
    '振り返り履歴': '振り返り履歴',
    '進捗度': '進捗度',
    '振り返り回数': '振り返り回数',
    '振り返り %lld回': '振り返り %lld回',
    '進捗度の見方': '進捗度の見方',
    '進捗度は、案件の進み具合を示す指標です。次の段階に達するたびに上がります。':
        '進捗度は、案件の進み具合を示す指標です。次の段階に達するたびに上がります。',
    '10%　テーマ設定済み': '10%　テーマ設定済み',
    '20%　ゴール設定済み': '20%　ゴール設定済み',
    '30%　今の状況設定（SWOTマトリクス完成）': '30%　今の状況設定（SWOTマトリクス完成）',
    '40%　方策決定済み': '40%　方策決定済み',
    '50%　最初の一歩設定済み': '50%　最初の一歩設定済み',
    '60%　宣言終了': '60%　宣言終了',
    '70%　振り返り　1回実施': '70%　振り返り　1回実施',
    '80%　振り返り　2回実施': '80%　振り返り　2回実施',
    '90%　振り返り　3回以上実施': '90%　振り返り　3回以上実施',
    '100%　完了': '100%　完了',

    // ── Stage3: 振り返り ───────────────────────────────────────────────
    'どうだった？': 'どうだった？',
    '感じたこと、気づいたことを自由に書いてみましょう': '感じたこと、気づいたことを自由に書いてみましょう',
    '次はどうする？': '次はどうする？',
    '続ける': '続ける',
    '方策を変更する': '方策を変更する',
    '新しいテーマに取り組む': '新しいテーマに取り組む',
    '一旦休む': '一旦休む',

    // ── iCloud同期 ────────────────────────────────────────────────────
    'iCloud同期': 'iCloud同期',
    'iCloud同期_有効化フッター':
        'オンにすると、同じiCloudアカウントでサインインした端末間で案件データを同期します。',
    'iCloud同期_利用不可': 'iCloudが利用できません。設定でiCloudにサインインしてください。',
    'iCloud同期_最終同期': '最終同期',
    'iCloud同期_未同期': '未同期',
    'iCloud同期_今すぐ同期': '今すぐ同期',
    'iCloud同期_フッター':
        '案件のテーマ、ゴール、SWOT、方策、最初の一歩、宣言文、振り返りなどをiCloud Key-Value Storageに保存し、同じiCloudアカウントの端末間で共有します。',
    'iCloud同期_相対時刻_日': '%lld日前',
    'iCloud同期_相対時刻_時間': '%lld時間前',
    'iCloud同期_相対時刻_分': '%lld分前',
    'iCloud同期_相対時刻_今': 'たった今',
    'iCloud同期_アップロード完了': 'iCloudにアップロードしました',
    'iCloud同期_ダウンロード完了': 'iCloudからダウンロードしました',
    'iCloud同期_エラー': '同期に失敗しました',
    'iCloud同期_エラー_未検出': 'iCloud同期の機能が見つかりませんでした。アプリを再起動してください。',
    'iCloud同期_エラー_案件未読込': '案件データの読み込みが完了していません。',
    'iCloud同期_エラー_容量超過': 'データ量（%@ MB）がiCloud同期の上限（1MB）を超えています。',
    'iCloud同期_エラー_マージ失敗': 'ダウンロードしたデータの反映に失敗しました。',
    'iCloud同期_エラー_不正な応答': 'iCloudから予期しない応答がありました。',
    'iCloud同期_クラウドコピーを削除': 'iCloud上のクラウドコピーを削除',
    'iCloud同期_クラウドコピーを削除しますか？': 'iCloudコピーを削除しますか？',
    'iCloud同期_クラウドコピー削除確認':
        'iCloud KVS上のosmJiritsuの案件データと同期日時を削除します。端末内の案件は削除しません。',
    'iCloud同期_クラウドコピー削除完了': 'iCloudコピーを削除しました。',
    'iCloud同期_クラウドコピー削除失敗': '削除できませんでした。iCloudの状態を確認して再試行してください。',
    'プライバシー_iCloud保存': 'iCloudでの保存',
    'プライバシー_iCloud保存詳細':
        'iCloud同期を有効にすると、案件のテーマ、ゴール、SWOT、方策、最初の一歩、宣言文、振り返りなどがAppleのiCloud Key-Value Storageに保存され、同じiCloudアカウントの端末間で共有されます。',
  };

  static const _en = <String, String>{
    'それでは始めましょう': "Let's get started",
    'まずテーマを決めよう': "First, let's decide on a theme.",
    'テーマ': 'Theme',
    '例）新しいキャリアについて': 'e.g. About a new career',
    'ゴールを考える': 'Think about your goal',

    'ゴールを教えてください': 'Tell us your goal',
    '「在りたい姿」と「在りたくない姿」、両方の向きから考えてみましょう。':
        "Let's think about it from both directions: the future you want, and the future you want to avoid.",
    '在りたい姿': 'Desired outcome',
    'これが実現すれば十分、と言える理想の姿（充分条件）':
        'The ideal state that alone would be enough (a "sufficient condition")',
    '例）自分の強みを活かして、納得感のある転職をしたい':
        'e.g. I want a career change that makes use of my strengths',
    '在りたくない姿': 'The future you want to avoid',
    'これだけは避けたい、という最低ライン（必要条件）':
        'The baseline you want to avoid no matter what (a "necessary condition")',
    '例）妥協して、納得感のないまま転職すること':
        "e.g. Settling for a career change I'm not really satisfied with",
    'アイデアを出してみる': 'Start brainstorming',

    'テーマ: %@': 'Theme: %@',
    '思いつくままに、どんどん追加しよう': 'Add whatever comes to mind, one after another',
    '%lld件を分類する': 'Classify %lld items',
    '思いついたことを入力…': 'Type what comes to mind…',
    '「%@」について\n思いつくことを何でも入力してみましょう':
        'About "%@"\nTry typing anything that comes to mind',

    '%lld / %lld 個 完了': '%lld / %lld done',
    '戻す': 'Undo',
    '戻る': 'Back',
    'これって、良いこと？ 気になること？':
        'Is this a good thing, or something that concerns you?',
    'それって、自分次第で変えられる？': 'Is that something you can change yourself?',
    '良いこと': 'Good thing',
    '自信がある・嬉しい': 'Confident / glad',
    '気になること': 'A concern',
    '不安・課題に感じる': 'Feels uneasy / like an issue',
    '自分次第': 'Up to me',
    '頑張れば変えられる': 'Can change it if I try',
    'まわりの状況': 'The situation around me',
    '環境や他人に左右される': 'Affected by circumstances or others',
    '全部答えられました！': "You've answered everything!",
    '実はこれ、SWOT分析になっています。\n出来上がったマトリクスを見てみましょう。':
        "This has actually become a SWOT analysis.\nLet's take a look at the finished matrix.",
    'マトリクスを確認する': 'View the matrix',

    '履歴に戻る': 'Back to history',
    'SWOTマトリクス': 'SWOT Matrix',
    '今の状況': 'Current situation',
    'はじめからやり直す': 'Start over',
    '強み': 'Strength',
    '機会': 'Opportunity',
    '弱み': 'Weakness',
    '脅威': 'Threat',
    'AIに方策を相談する': 'Ask AI for strategies',
    '違うと感じたら、カードを長押しして別の枠にドラッグしてみてください':
        'If something feels off, long-press a card and drag it to a different box',
    '内容を編集': 'Edit item',
    '項目を追加': 'Add item',
    'どの枠に入れますか？': 'Which box does this go in?',
    '追加': 'Add',
    'ここに置く': 'Drop here',
    'なし': 'None',

    '方策を決める': 'Decide your strategy',
    '方策_Google送信確認_タイトル': 'Send data to Google for strategy suggestions?',
    '方策_Google送信確認_本文':
        'To provide reference strategy suggestions, your theme, desired outcome, the state you want to avoid, and complete SWOT text (strengths, weaknesses, opportunities, and threats) will be sent to Google Search (AI Mode), provided by Google LLC. The content may include personal or sensitive information. The search may remain in your browser or Google Account history.',
    '最初の一歩_Google送信確認_タイトル':
        'Send data to Google for first-step suggestions?',
    '最初の一歩_Google送信確認_本文':
        'To provide reference first-step suggestions, your theme, desired outcome, and decided strategy will be sent to Google Search (AI Mode), provided by Google LLC. The content may include personal or sensitive information. The search may remain in your browser or Google Account history.',
    '同意してGoogleへ送信': 'Agree and send to Google',
    'Chromeを開いています…': 'Opening Chrome…',
    'Chromeを開けませんでした': "Couldn't open Chrome",
    'Chromeを開けませんでした: %@': "Couldn't open Chrome: %@",
    'もう一度試す': 'Try again',
    'Chromeでの回答を確認してください': 'Please check the answer in Chrome',
    'AIの回答をコピーしたら、この画面に戻って\n下のボタンをタップしてください。':
        "Once you've copied the AI's answer, come back to this screen\nand tap the button below.",
    '貼り付けて確認する': 'Paste and check',
    'もう一度Chromeを開く': 'Open Chrome again',
    '読み取れませんでした': "Couldn't read it",
    'もう一度貼り付ける': 'Paste again',
    'Chromeを開き直す': 'Reopen Chrome',
    'クリップボードが空でした。Chromeで回答をコピーしてから、もう一度貼り付けてみてください。':
        'The clipboard was empty. Copy the answer in Chrome, then try pasting again.',
    '方策を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。':
        "Couldn't read the strategies. Copy the whole answer from Chrome, then try pasting again.",
    'AIが考えた5つの方策': '5 strategies from AI',
    '「採用済／未採用」はタップで切り替えられます。文言を直したいときは案を長押しで編集できます。':
        'Tap to switch between Adopted and Not adopted. Long-press a suggestion to reword it.',
    '採用済': 'Adopted',
    '未採用': 'Not adopted',
    '方策を編集': 'Edit strategy',
    'あなたの方策': 'Your strategy',
    'AIの提案にない、独自の方策があれば書く':
        "Write your own strategy here if it's not among the AI's suggestions",
    '自律度をチェックする': 'Check your Jiritsu',
    '自律度チェック': 'Jiritsu check',
    '決めた方策を、3つの要素から見直してみましょう。':
        "Let's review your decided strategy against the three elements.",
    '自分で決められるか？': 'Can you decide it yourself?',
    '結果が分かりやすいか？': 'Is the outcome easy to see?',
    'ゴールを共有できているか？': 'Can the goal be shared?',
    '%lld / 3 満たしている': '%lld / 3 satisfied',
    '納得した': "I'm satisfied",
    '方策を編集する': 'Edit the strategy',
    'AIに再度相談する': 'Ask AI again',
    '長押しで今の状況を編集': 'Long-press to edit current situation',
    '長押しでテーマを編集': 'Long-press to edit the theme',
    '長押しでゴールを編集': 'Long-press to edit the goals',
    '長押しで方策を見直す': 'Long-press to review strategy',
    '長押しで最初の一歩を見直す': 'Long-press to review first step',
    '方策を見直す': 'Review strategy',
    '最初の一歩を見直す': 'Review first step',
    '長押しで宣言文を編集': 'Long-press to edit declaration',
    '長押しで振り返りを編集': 'Long-press to edit reflection',
    '振り返りを編集': 'Edit reflection',
    'この振り返りを削除しますか？': 'Delete this reflection?',
    '宣言文を編集': 'Edit declaration',
    '方策を決めた': 'Strategy decided',
    '自律度チェック: %lld / 3': 'Jiritsu check: %lld / 3',

    '最初の一歩を決める': 'Decide your first step',
    '最初の一歩を決めた': 'First step decided',
    'AIが考えた10個の最初の一歩': '10 first steps from AI',
    'あなたの最初の一歩': 'Your first step',
    '最初の一歩を編集': 'Edit first step',
    'AIの提案にない、独自の最初の一歩があれば書く':
        "Write your own first step here if it's not among the AI's suggestions",
    '宣言文を確認する': 'Review your declaration',
    '最初の一歩を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。':
        "Couldn't read the first steps. Copy the whole answer from Chrome, then try pasting again.",
    '宣言文': 'Declaration',
    '上司や仲間にそのまま送れる、ひとことにしましょう。':
        "Make it a line you could send to a boss or teammate as-is.",
    '最初の一歩: %@': 'First step: %@',
    '最初の一歩を編集する': 'Edit the first step',
    '決定': 'Fix it',
    '自律計画ができました': 'Your Jiritsu plan is ready',
    'あとで（履歴に戻る）': 'Later (back to history)',

    'エクスポート': 'Export',
    'エクスポートする': 'Export',
    'JSONバックアップ': 'JSON backup',
    'JSONを取り込む': 'Import JSON',
    'まとめを共有': 'Share summary',
    '上司や仲間にそのまま送れます。': 'Ready to send to a boss or teammate as-is.',
    '共有_テキスト説明':
        'Shares as plain text (email, messaging apps, etc.). Brief is the plan summary; Full is everything on the dashboard. JSON backup is under Data on the home screen.',
    '共有する': 'Share',
    '共有': 'Share',
    '要報': 'Brief summary',
    '詳報': 'Full report',
    '共有形式を選んでください': 'Choose a share format',
    '共有_要報説明': 'Short form (theme, goals, strategy, first step, declaration). Same as the post-Stage1 share summary.',
    '共有_詳報説明': 'All dashboard fields (SWOT, reflections, deadline, etc.). Better for day-to-day progress sharing.',
    '短い形式（テーマ・ゴール・方策・最初の一歩・宣言文）':
        'Short format (theme, goals, strategy, first step, declaration)',
    'ダッシュボードの全項目': 'All dashboard fields',
    'リターン': 'Return',
    '完了': 'Done',
    '方策': 'Strategy',
    '最初の一歩': 'First step',
    '作成中': 'Preparing',
    '実施中': 'In progress',
    '休憩中': 'On break',

    '履歴の読み込みに失敗しました\n%@': 'Failed to load history\n%@',
    'エクスポートできる分析がまだありません': "There's nothing to export yet",
    '%lld件の分析を読み込みました': 'Imported %lld analyses',
    '読み込みに失敗しました: %@': 'Import failed: %@',
    '自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。':
        'Jiritsu means acting on your own judgment to close the gap between your goal and your current situation.',
    '各画面の': 'On each screen, long-press the ',
    'ボタン長押しで\n操作方法を確認できます':
        ' button to see how to use it',
    '操作方法': 'How to use',
    '案内に従って操作': 'Follow the on-screen guidance',
    '操作方法_ダッシュボード':
        '1️⃣ View / open: tap ▶︎\n2️⃣ Delete a project: tap 🗑️ or swipe left\n3️⃣ Edit the theme: tap 🖊️\n4️⃣ Add to favorites: tap ☆\n5️⃣ Add new: tap ＋',
    '操作方法_SWOT':
        '1️⃣ Change the category: drag the item\n2️⃣ Edit an item: tap the item\n3️⃣ Delete an item: drag it out of the SWOT boxes\n4️⃣ Add an item: tap ＋',
    '操作方法_方策最初の一歩': '1️⃣ Edit: long-press the item',
    '操作方法_宣言': '1️⃣ Edit: tap the item',
    '次回から表示しない': "Don't show again",
    'はじめる': 'Get started',
    'キーワード': 'Keywords',
    '小さなくるくる': '小さなくるくる\nchiisana kurukuru',
    '唱って躍れる': '唱って躍れる\nutatte odoreru',
    '分析結果': 'Analysis result',
    '削除': 'Delete',
    'この分析を削除しますか？': 'Delete this analysis?',
    '元に戻すことはできません。': 'This cannot be undone.',
    'キャンセル': 'Cancel',
    '削除する': 'Delete',
    'やっぱりやらない': "Actually, skip it",
    '方策を取り消しますか？': 'Discard this strategy?',
    '最初の一歩を取り消しますか？': 'Discard this first step?',
    '文言を編集': 'Edit wording',
    '見直す方法を選んでください': 'How do you want to revise?',
    '見直す_文言編集説明': 'Edit the current text only (no AI)',
    '見直す_AI再相談説明': 'Review or regenerate candidates with Chrome AI Mode',
    '壁打ちメモ': 'Brainstorm notes',
    '作成中_ホームで一覧': 'Use Home to return to the project list',
    'タップまたは長押しで編集': 'Tap or long-press to edit',
    'タップで今の状況を編集': 'Tap to edit the current situation',
    '(テーマ未設定)': '(No theme set)',

    '編集': 'Edit',
    'お気に入りに追加': 'Add to favorites',
    'お気に入り解除': 'Remove from favorites',
    'テーマを編集': 'Edit theme',
    '保存': 'Save',
    'ダッシュボードへ': 'Open dashboard',
    '新規追加': 'New',
    'データ': 'Data',
    'その他': 'More',
    'ヘルプ': 'Help',
    'ホーム': 'Home',
    'インポート': 'Import',

    '設定': 'Settings',
    'プライバシー': 'Privacy',
    'プライバシーとデータ': 'Privacy & Data',
    '言語': 'Language',
    'アプリの表示言語を変更できます。': "You can change the app's display language.",
    '言語_設定が正式': 'This is the canonical place to set the display language. The flag on the start screen switches the same setting.',
    '言語_スタートショートカット': 'You can also change this in Settings',
    '設定_削除はプライバシーへ': 'Delete from the Privacy & Data screen',
    'スタートアップ画面': 'Startup Screen',
    '起動時にスタート画面を表示': 'Show start screen at launch',
    '案件があっても、起動時はスタート画面から始めます。':
        'Always start from the start screen at launch, even if you have projects.',
    'すべてのデータを初期化': 'Reset all data',
    '本当に初期化しますか？': 'Reset everything?',
    '初期化の説明':
        'This deletes all local data and settings and restores the app to its initial state. This cannot be undone.',
    '初期化': 'Reset',
    '初期化しました': 'Reset complete',

    'プライバシー_外部送信': 'Recipients, data, and purposes',
    'Google AIによる方策提案': 'Strategy suggestions via Google AI',
    'プライバシー_方策説明':
        'If you request strategy suggestions, your theme, desired outcome, the state you want to avoid, and complete SWOT text (strengths, weaknesses, opportunities, and threats) are sent to Google Search (AI Mode), provided by Google LLC. The purpose is to obtain reference strategy suggestions. Consent is requested for every submission. Google’s terms and privacy policy apply.',
    'Google AIによる最初の一歩提案': 'First-step suggestions via Google AI',
    'プライバシー_最初の一歩説明':
        'If you request first-step suggestions, your theme, desired outcome, and decided strategy are sent to Google Search (AI Mode), provided by Google LLC. The purpose is to obtain reference first-step suggestions. Consent is requested for every submission. Google’s terms and privacy policy apply.',
    'プライバシーポリシー': 'Privacy Policy',
    'プライバシー_ポリシー本文_詳細':
        'Full details on external transmissions, retention, and deletion.',
    '関連ポリシー': 'Related Policies',
    'Google プライバシーポリシー': 'Google Privacy Policy',
    'Apple プライバシーポリシー': 'Apple Privacy Policy',
    'プライバシー_関連ポリシー_詳細':
        'Google’s policy applies to submissions to Google Search (AI Mode). Apple’s terms may apply to App Store distribution and device backups.',
    'プライバシー_端末保存': 'Storage on your device',
    'プライバシー_保存詳細':
        'Theme, goals, SWOT analysis, strategy, first step, declaration, reflections, project order, display language, and start-screen settings are stored in a local Hive database on this device. There is no cloud sync.',
    'プライバシー_保持削除詳細':
        'Stored data is retained until you delete an item or choose Delete all data. Data already sent to Google is retained and deleted under Google’s own policy and cannot be deleted from this app. Copies saved via JSON backup to other apps also cannot be deleted by this app.',
    'プライバシー_JSONバックアップ案内':
        'JSON backup / import of projects is available from the Data menu on the home screen and creation flow toolbar.',
    'すべてのデータを削除': 'Delete all data',
    'プライバシー_削除確認':
        'Delete Hive analysis history and settings, plus temporary backup files? This cannot be undone.',
    '端末内のアプリデータを削除しました': 'On-device app data deleted',

    'HELP': 'HELP',
    'osmJiritsu': 'osmJiritsu',
    'バージョン %@ (%@)': 'Version %@ (%@)',
    '自律とは': 'What is Jiritsu?',
    'ゴールと今の状況の差を無くすために、自分で考えて行動すること':
        'Acting on your own judgment to close the gap between a goal and the current situation',
    'テーマとゴール（在りたい姿／在りたくない姿）を決める':
        'Set a theme and goals (desired / undesired state)',
    '現状を整理し、SWOTから方策を自分で決める':
        'Organize the present, then decide your own strategy from SWOT',
    '最初の一歩を宣言し、振り返りながら進める':
        'Declare your first step, then keep going with reflection',
    '自律の3要素': 'The 3 elements of Jiritsu',
    '方策や行動を決めるとき、この3つを満たしているか振り返ってみましょう。':
        'When deciding on a strategy or action, check whether it satisfies all three of these.',
    '自律の定義': 'Definition of Jiritsu',
    '（参考）自立とは': '(Reference) What is self-reliance?',
    '自分以外の何ものにも依存しない状態。':
        'A state of depending on nothing and no one but yourself.',
    '自立できていない、依存している人は、自分のうまく行かない状態の責任や自分の感情、思考の原因すら周りの人や環境のせいにする。':
        'Someone who lacks self-reliance and depends on others blames the people and environment around them — even for their own setbacks, feelings, and thoughts.',
    '自立には経済的自立、行動的自立、精神的自立があり、いずれも自律と密接に関係している（自律している人は自立できる）。':
        'Self-reliance has three forms — financial, behavioral, and mental — and all three are closely tied to Jiritsu (autonomy): someone who is autonomous can become self-reliant.',
    '自律できていない人にありがちな行動': 'Behaviors common in people who lack autonomy',
    '言われたことだけやる': 'Only doing what they\'re told',
    '不平、不満ばっかり': 'Nothing but complaints and grievances',
    '無感動、無関心': 'Indifferent, uninterested',
    'できない理由だけで、どうすればできるか？がない':
        'Only reasons why it can\'t be done — never how it could be',
    '一見クールでカッコよく見えたりする。的を射てるし。周囲を白けさせるパワー大。口癖は「でもさ...」':
        'At a glance it can look cool and sharp — the point often lands. But it has a real power to drain the energy out of everyone around. The catchphrase: "Yeah, but..."',
    '他人から言われる前に動く': 'Act before someone else tells you to',
    '主導権は自分にあるのだと意識すること': 'Be aware that you hold the initiative',
    '方策の粒度を細かくすること': 'Break the strategy into smaller steps',
    '結果を見える化して視覚的に成果を実感すること':
        'Make the results visible so progress feels real',
    '周囲からサポートを得る': 'Get support from the people around you',
    '言語化することで思いが現実性を持つ':
        'Putting it into words makes it feel real',
    '動機づけマトリクス': 'Motivation matrix',
    '方策を考える際、動機づけマトリクスを意識すると良い。':
        'When thinking through a strategy, it helps to keep the motivation matrix in mind.',
    '内発的動機づけ': 'Intrinsic motivation',
    '外発的動機づけ': 'Extrinsic motivation',
    '自分の内面的な興味・関心、探究心、楽しさなどが原動力となる状態。':
        'A state driven by your own inner interest, curiosity, or enjoyment.',
    '＜特徴＞': '<Characteristics>',
    '行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。':
        'Because the action itself becomes the goal, it brings high concentration and quality, and self-driven behavior is easy to sustain.',
    '＜具体例＞': '<Examples>',
    '興味のある分野について自主的に深く調べる。':
        'Digging deep into a field you\'re interested in on your own initiative.',
    '純粋に人を喜ばせたくて仕事に取り組む。':
        'Taking on work purely because you want to make someone happy.',
    '＜メリット・デメリット＞': '<Pros and cons>',
    '⭕️ モチベーションが長持ちする': '⭕️ Motivation lasts a long time',
    '❌ 本人の興味に依存するため即効性がない':
        '❌ Depends on personal interest, so it has no immediate effect',
    '❌ 誰にでも同じように適用することは困難':
        '❌ Difficult to apply the same way to everyone',
    '報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」をきっかけとして行動を促すこと。':
        'Prompting action through "external stimuli" such as rewards, evaluation, promotion, or penalties and reprimands.',
    '内発か？外発か？': 'Intrinsic or extrinsic?',
    '内発と外発は対立するものではなく組み合わせもの。外発をきっかけに始めて、その内、それ自体が楽しくなる...（エンハンシング効果）。':
        'Intrinsic and extrinsic motivation aren\'t opposites — they combine. You can start out triggered by something external, and over time the activity itself becomes enjoyable... (the enhancing effect).',
    '実行のステップを細かくして達成感を感じやすくすること。':
        'Breaking execution into small steps so a sense of accomplishment is easy to feel.',
    '唱（ショウ）': 'Shō (唱, "sing / proclaim")',
    '昌には、盛んで明るいとか、美しいことばという意味があり、それと口にすることから、唱は、うたう、となえるの意味を表す。また、昌の音は、高く上げるという意味を含むから、唱は、声を高くあげること、あるいは、「人より先に大声を上げてリードする」ことである。':
        '昌 carries the sense of "thriving and bright" or "beautiful words," and combined with 口 ("mouth," to speak), 唱 comes to mean "to sing" or "to proclaim." The sound 昌 also carries the nuance of "raising something high," so 唱 means "to raise one\'s voice" — or "to lead by being the first to speak up loudly."',
    '唱義：人に先立って正しい道をとなえる':
        '唱義: to proclaim the right path ahead of others',
    '躍（ヤク）': 'Yaku (躍, "leap")',
    '翟には高く抜き出る意味がある。躍は「すばやくおどりあがる」ことである。':
        '翟 carries the sense of "standing out, rising high." 躍 means "to leap up quickly."',
    '躍動：おどりうごく、いきいきと活動する':
        '躍動: to move dynamically, to be vibrantly active',
    'つまり「唱って躍れる」とは「周りを引っ張って、元気に前に進める」「自分の考えを話して、みんなと共有できる」ことである。':
        'In other words, "唱って躍れる" (sing and leap) means "to pull others along and move forward with energy," and "to voice your own thinking and share it with everyone."',
    '誰かに話すことによって自分の中で漠然としていた夢が、どんどんリアリティを持ち、少しずつ形になり、ビジョンになっていく。これを繰り返す内にビジョンはより明確になり、とうとう的確な言葉で表現できるようになったとき、初めて明快な物語として、リアリティのある戦略として、それを人に伝達し、実際に行動に移していく事ができる。':
        'By telling someone else, a dream that was once vague inside you steadily gains reality, gradually takes shape, and becomes a vision. Repeat this enough times and the vision grows clearer, until at last you can put it into precise words — only then can you convey it to others as a clear story, as a strategy with real substance, and actually put it into action.',
    '― 伊藤守「リーダーになる人ならない人」':
        '― Mamoru Itō, "Rīdā ni Naru Hito, Naranai Hito" (People Who Become Leaders, People Who Don\'t)',
    '登録日': 'Registered',
    '最終更新日': 'Last updated',
    '期限': 'Deadline',
    '未設定': 'Not set',
    '期限を設定': 'Set deadline',
    '備考': 'Notes',
    '備考を入力…': 'Enter notes…',
    '現況を変更': 'Change status',
    '振り返り': 'Reflection',
    '振り返り履歴': 'Reflection history',
    '進捗度': 'Progress',
    '振り返り回数': 'Reflection count',
    '振り返り %lld回': '%lld reflection(s)',
    '進捗度の見方': 'How progress is calculated',
    '進捗度は、案件の進み具合を示す指標です。次の段階に達するたびに上がります。':
        'Progress shows how far a project has advanced. It increases each time you reach the next stage.',
    '10%　テーマ設定済み': '10% — Theme set',
    '20%　ゴール設定済み': '20% — Goals set',
    '30%　今の状況設定（SWOTマトリクス完成）':
        '30% — Current situation set (SWOT matrix complete)',
    '40%　方策決定済み': '40% — Strategy decided',
    '50%　最初の一歩設定済み': '50% — First step set',
    '60%　宣言終了': '60% — Declaration written',
    '70%　振り返り　1回実施': '70% — 1 reflection done',
    '80%　振り返り　2回実施': '80% — 2 reflections done',
    '90%　振り返り　3回以上実施': '90% — 3 or more reflections done',
    '100%　完了': '100% — Completed',

    'どうだった？': 'How did it go?',
    '感じたこと、気づいたことを自由に書いてみましょう':
        'Write freely about what you felt or noticed',
    '次はどうする？': 'What next?',
    '続ける': 'Continue',
    '方策を変更する': 'Change strategy',
    '新しいテーマに取り組む': 'Work on a new theme',
    '一旦休む': 'Take a break',

    'iCloud同期': 'iCloud Sync',
    'iCloud同期_有効化フッター':
        'When on, project data syncs between devices signed into the same iCloud account.',
    'iCloud同期_利用不可': 'iCloud is not available. Please sign in to iCloud in Settings.',
    'iCloud同期_最終同期': 'Last synced',
    'iCloud同期_未同期': 'Never synced',
    'iCloud同期_今すぐ同期': 'Sync now',
    'iCloud同期_フッター':
        "A project's theme, goals, SWOT, strategy, first step, declaration, and reflections are stored in iCloud Key-Value Storage and shared between devices signed into the same iCloud account.",
    'iCloud同期_相対時刻_日': '%lld day(s) ago',
    'iCloud同期_相対時刻_時間': '%lld hour(s) ago',
    'iCloud同期_相対時刻_分': '%lld minute(s) ago',
    'iCloud同期_相対時刻_今': 'Just now',
    'iCloud同期_アップロード完了': 'Uploaded to iCloud',
    'iCloud同期_ダウンロード完了': 'Downloaded from iCloud',
    'iCloud同期_エラー': 'Sync failed',
    'iCloud同期_エラー_未検出':
        "Couldn't find the iCloud sync feature. Please restart the app.",
    'iCloud同期_エラー_案件未読込': 'Project data has not finished loading yet.',
    'iCloud同期_エラー_容量超過':
        'Your data (%@ MB) exceeds the iCloud sync limit (1 MB).',
    'iCloud同期_エラー_マージ失敗': 'Failed to apply the downloaded data.',
    'iCloud同期_エラー_不正な応答': 'Received an unexpected response from iCloud.',
    'iCloud同期_クラウドコピーを削除': 'Delete iCloud Cloud Copy',
    'iCloud同期_クラウドコピーを削除しますか？': 'Delete the iCloud copy?',
    'iCloud同期_クラウドコピー削除確認':
        'This removes osmJiritsu project data and its sync timestamp from iCloud KVS. It does not delete local projects.',
    'iCloud同期_クラウドコピー削除完了': 'The iCloud copy was deleted.',
    'iCloud同期_クラウドコピー削除失敗':
        'Deletion failed. Check iCloud availability and try again.',
    'プライバシー_iCloud保存': 'Storage in iCloud',
    'プライバシー_iCloud保存詳細':
        "When iCloud Sync is enabled, a project's theme, goals, SWOT, strategy, first step, declaration, and reflections are stored in Apple iCloud Key-Value Storage and shared with your devices signed into the same iCloud account.",
  };

  static const _vi = <String, String>{
    'それでは始めましょう': 'Vậy thì, hãy bắt đầu',
    'まずテーマを決めよう': 'Trước tiên, hãy chọn chủ đề.',
    'テーマ': 'Chủ đề',
    '例）新しいキャリアについて': 'VD: Về sự nghiệp mới',
    'ゴールを考える': 'Nghĩ về mục tiêu',

    'ゴールを教えてください': 'Hãy cho chúng tôi biết mục tiêu của bạn',
    '「在りたい姿」と「在りたくない姿」、両方の向きから考えてみましょう。':
        'Hãy cùng suy nghĩ theo cả hai hướng: "hình ảnh bạn muốn trở thành" và "hình ảnh bạn không muốn trở thành".',
    '在りたい姿': 'Hình ảnh mong muốn',
    'これが実現すれば十分、と言える理想の姿（充分条件）':
        'Trạng thái lý tưởng mà nếu đạt được thì coi như đủ (điều kiện đủ)',
    '例）自分の強みを活かして、納得感のある転職をしたい':
        'VD: Tôi muốn chuyển việc theo cách phát huy thế mạnh của mình',
    '在りたくない姿': 'Hình ảnh bạn không muốn trở thành',
    'これだけは避けたい、という最低ライン（必要条件）':
        'Ranh giới tối thiểu bạn muốn tránh (điều kiện cần)',
    '例）妥協して、納得感のないまま転職すること':
        'VD: Thỏa hiệp và chuyển việc mà không thấy thỏa mãn',
    'アイデアを出してみる': 'Bắt đầu đưa ra ý tưởng',

    'テーマ: %@': 'Chủ đề: %@',
    '思いつくままに、どんどん追加しよう': 'Hãy thêm bất cứ điều gì nghĩ đến, liên tục',
    '%lld件を分類する': 'Phân loại %lld mục',
    '思いついたことを入力…': 'Nhập điều bạn nghĩ đến…',
    '「%@」について\n思いつくことを何でも入力してみましょう':
        'Về "%@"\nHãy thử nhập bất cứ điều gì bạn nghĩ đến',

    '%lld / %lld 個 完了': 'Hoàn thành %lld / %lld',
    '戻す': 'Hoàn tác',
    '戻る': 'Quay lại',
    'これって、良いこと？ 気になること？': 'Đây là điều tốt, hay điều khiến bạn lo lắng?',
    'それって、自分次第で変えられる？': 'Điều đó bạn có thể tự thay đổi được không?',
    '良いこと': 'Điều tốt',
    '自信がある・嬉しい': 'Tự tin / vui mừng',
    '気になること': 'Điều lo lắng',
    '不安・課題に感じる': 'Cảm thấy bất an / là vấn đề',
    '自分次第': 'Tùy vào bản thân',
    '頑張れば変えられる': 'Có thể thay đổi nếu cố gắng',
    'まわりの状況': 'Hoàn cảnh xung quanh',
    '環境や他人に左右される': 'Bị ảnh hưởng bởi môi trường hoặc người khác',
    '全部答えられました！': 'Bạn đã trả lời hết!',
    '実はこれ、SWOT分析になっています。\n出来上がったマトリクスを見てみましょう。':
        'Thực ra đây chính là một phân tích SWOT.\nHãy cùng xem ma trận đã hoàn thành.',
    'マトリクスを確認する': 'Xem ma trận',

    '履歴に戻る': 'Quay lại lịch sử',
    'SWOTマトリクス': 'Ma trận SWOT',
    '今の状況': 'Tình hình hiện tại',
    'はじめからやり直す': 'Bắt đầu lại từ đầu',
    '強み': 'Điểm mạnh',
    '機会': 'Cơ hội',
    '弱み': 'Điểm yếu',
    '脅威': 'Nguy cơ',
    'AIに方策を相談する': 'Hỏi AI về phương án',
    '違うと感じたら、カードを長押しして別の枠にドラッグしてみてください':
        'Nếu thấy không đúng, hãy nhấn giữ thẻ và kéo sang ô khác',
    '内容を編集': 'Sửa nội dung',
    '項目を追加': 'Thêm mục',
    'どの枠に入れますか？': 'Cho vào ô nào?',
    '追加': 'Thêm',
    'ここに置く': 'Thả vào đây',
    'なし': 'Không có',

    '方策を決める': 'Quyết định phương án',
    '方策_Google送信確認_タイトル': 'Gửi dữ liệu đến Google để đề xuất phương án?',
    '方策_Google送信確認_本文':
        'Để nhận đề xuất phương án tham khảo, chủ đề, trạng thái mong muốn, trạng thái không mong muốn và toàn bộ SWOT (điểm mạnh, điểm yếu, cơ hội, mối đe dọa) sẽ được gửi đến Google Search (chế độ AI) do Google LLC cung cấp. Nội dung có thể gồm thông tin cá nhân hoặc nhạy cảm. Nội dung tìm kiếm có thể lưu trong lịch sử trình duyệt hoặc Tài khoản Google.',
    '最初の一歩_Google送信確認_タイトル':
        'Gửi dữ liệu đến Google để đề xuất bước đầu tiên?',
    '最初の一歩_Google送信確認_本文':
        'Để nhận đề xuất bước đầu tiên tham khảo, chủ đề, trạng thái mong muốn và phương án đã chọn sẽ được gửi đến Google Search (chế độ AI) do Google LLC cung cấp. Nội dung có thể gồm thông tin cá nhân hoặc nhạy cảm. Nội dung tìm kiếm có thể lưu trong lịch sử trình duyệt hoặc Tài khoản Google.',
    '同意してGoogleへ送信': 'Đồng ý và gửi đến Google',
    'Chromeを開いています…': 'Đang mở Chrome…',
    'Chromeを開けませんでした': 'Không thể mở Chrome',
    'Chromeを開けませんでした: %@': 'Không thể mở Chrome: %@',
    'もう一度試す': 'Thử lại',
    'Chromeでの回答を確認してください': 'Vui lòng kiểm tra câu trả lời trên Chrome',
    'AIの回答をコピーしたら、この画面に戻って\n下のボタンをタップしてください。':
        'Sau khi sao chép câu trả lời của AI, hãy quay lại màn hình này\nvà nhấn nút bên dưới.',
    '貼り付けて確認する': 'Dán và kiểm tra',
    'もう一度Chromeを開く': 'Mở lại Chrome',
    '読み取れませんでした': 'Không thể đọc được',
    'もう一度貼り付ける': 'Dán lại',
    'Chromeを開き直す': 'Mở lại Chrome',
    'クリップボードが空でした。Chromeで回答をコピーしてから、もう一度貼り付けてみてください。':
        'Bảng nhớ tạm trống. Hãy sao chép câu trả lời trên Chrome rồi thử dán lại.',
    '方策を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。':
        'Không thể đọc được phương án. Hãy sao chép toàn bộ câu trả lời từ Chrome rồi thử dán lại.',
    'AIが考えた5つの方策': '5 phương án từ AI',
    '「採用済／未採用」はタップで切り替えられます。文言を直したいときは案を長押しで編集できます。':
        'Chạm để chuyển giữa Đã áp dụng và Chưa áp dụng. Nhấn giữ một phương án để sửa nội dung.',
    '採用済': 'Đã áp dụng',
    '未採用': 'Chưa áp dụng',
    '方策を編集': 'Sửa phương án',
    'あなたの方策': 'Phương án của bạn',
    'AIの提案にない、独自の方策があれば書く':
        'Nếu bạn có phương án riêng không nằm trong gợi ý của AI, hãy viết ở đây',
    '自律度をチェックする': 'Kiểm tra Jiritsu',
    '自律度チェック': 'Kiểm tra Jiritsu',
    '決めた方策を、3つの要素から見直してみましょう。':
        'Hãy cùng xem lại phương án đã quyết định theo 3 yếu tố.',
    '自分で決められるか？': 'Bạn có thể tự quyết định không?',
    '結果が分かりやすいか？': 'Kết quả có dễ nhận biết không?',
    'ゴールを共有できているか？': 'Bạn có thể chia sẻ mục tiêu không?',
    '%lld / 3 満たしている': 'Đạt %lld / 3',
    '納得した': 'Tôi đã hài lòng',
    '方策を編集する': 'Chỉnh sửa phương án',
    'AIに再度相談する': 'Hỏi AI lại',
    '長押しで今の状況を編集': 'Nhấn giữ để sửa tình hình hiện tại',
    '長押しでテーマを編集': 'Nhấn giữ để sửa chủ đề',
    '長押しでゴールを編集': 'Nhấn giữ để sửa mục tiêu',
    '長押しで方策を見直す': 'Nhấn giữ để xem lại phương án',
    '長押しで最初の一歩を見直す': 'Nhấn giữ để xem lại bước đầu tiên',
    '方策を見直す': 'Xem lại phương án',
    '最初の一歩を見直す': 'Xem lại bước đầu tiên',
    '長押しで宣言文を編集': 'Nhấn giữ để sửa tuyên bố',
    '長押しで振り返りを編集': 'Nhấn giữ để sửa nhìn lại',
    '振り返りを編集': 'Sửa nhìn lại',
    'この振り返りを削除しますか？': 'Xóa lần nhìn lại này?',
    '宣言文を編集': 'Sửa tuyên bố',
    '方策を決めた': 'Đã quyết định phương án',
    '自律度チェック: %lld / 3': 'Kiểm tra Jiritsu: %lld / 3',

    '最初の一歩を決める': 'Quyết định bước đầu tiên',
    '最初の一歩を決めた': 'Đã quyết định bước đầu tiên',
    'AIが考えた10個の最初の一歩': '10 bước đầu tiên từ AI',
    'あなたの最初の一歩': 'Bước đầu tiên của bạn',
    '最初の一歩を編集': 'Sửa bước đầu tiên',
    'AIの提案にない、独自の最初の一歩があれば書く':
        'Nếu bạn có bước đầu tiên riêng không nằm trong gợi ý của AI, hãy viết ở đây',
    '宣言文を確認する': 'Xem lại tuyên bố',
    '最初の一歩を読み取れませんでした。Chromeの回答全体をコピーしてから、もう一度貼り付けてみてください。':
        'Không thể đọc được bước đầu tiên. Hãy sao chép toàn bộ câu trả lời từ Chrome rồi thử dán lại.',
    '宣言文': 'Tuyên bố',
    '上司や仲間にそのまま送れる、ひとことにしましょう。':
        'Hãy viết thành một câu có thể gửi ngay cho cấp trên hoặc đồng nghiệp.',
    '最初の一歩: %@': 'Bước đầu tiên: %@',
    '最初の一歩を編集する': 'Chỉnh sửa bước đầu tiên',
    '決定': 'Xác nhận',
    '自律計画ができました': 'Kế hoạch Jiritsu của bạn đã sẵn sàng',
    'あとで（履歴に戻る）': 'Để sau (quay lại lịch sử)',

    'エクスポート': 'Xuất',
    'エクスポートする': 'Xuất',
    'JSONバックアップ': 'Sao lưu JSON',
    'JSONを取り込む': 'Nhập JSON',
    'まとめを共有': 'Chia sẻ tóm tắt',
    '上司や仲間にそのまま送れます。': 'Sẵn sàng gửi cho cấp trên hoặc đồng nghiệp.',
    '共有_テキスト説明':
        'Chia sẻ dạng văn bản (email, ứng dụng nhắn tin, v.v.). Tóm tắt là kế hoạch ngắn; báo cáo đầy đủ là mọi mục trên bảng điều khiển. Sao lưu JSON nằm trong menu Dữ liệu ở màn hình chính.',
    '共有する': 'Chia sẻ',
    '共有': 'Chia sẻ',
    '要報': 'Tóm tắt',
    '詳報': 'Báo cáo đầy đủ',
    '共有形式を選んでください': 'Chọn định dạng chia sẻ',
    '共有_要報説明': 'Dạng ngắn (chủ đề, mục tiêu, phương sách, bước đầu, tuyên bố). Giống bản tóm tắt sau Stage1.',
    '共有_詳報説明': 'Mọi mục trên bảng điều khiển (SWOT, nhìn lại, hạn, v.v.). Phù hợp chia sẻ tiến độ hàng ngày.',
    '短い形式（テーマ・ゴール・方策・最初の一歩・宣言文）':
        'Dạng ngắn (chủ đề, mục tiêu, phương án, bước đầu, tuyên bố)',
    'ダッシュボードの全項目': 'Toàn bộ mục trên bảng điều khiển',
    'リターン': 'Quay lại',
    '完了': 'Hoàn tất',
    '方策': 'Phương án',
    '最初の一歩': 'Bước đầu tiên',
    '作成中': 'Đang chuẩn bị',
    '実施中': 'Đang thực hiện',
    '休憩中': 'Đang tạm nghỉ',

    '履歴の読み込みに失敗しました\n%@': 'Không tải được lịch sử\n%@',
    'エクスポートできる分析がまだありません': 'Chưa có gì để xuất',
    '%lld件の分析を読み込みました': 'Đã nhập %lld phân tích',
    '読み込みに失敗しました: %@': 'Nhập thất bại: %@',
    '自律とは、ゴールと今の状況の差を無くすために、自分で考えて行動することです。':
        'Jiritsu là tự suy nghĩ và hành động để thu hẹp khoảng cách giữa mục tiêu và tình trạng hiện tại.',
    '各画面の': 'Trên mỗi màn hình, nhấn giữ nút ',
    'ボタン長押しで\n操作方法を確認できます':
        ' để xem cách sử dụng',
    '操作方法': 'Cách sử dụng',
    '案内に従って操作': 'Làm theo hướng dẫn trên màn hình',
    '操作方法_ダッシュボード':
        '1️⃣ Xem/mở: chạm ▶︎\n2️⃣ Xóa án: chạm 🗑️ hoặc vuốt sang trái\n3️⃣ Sửa chủ đề: chạm 🖊️\n4️⃣ Thêm vào yêu thích: chạm ☆\n5️⃣ Thêm mới: chạm ＋',
    '操作方法_SWOT':
        '1️⃣ Đổi phân loại: kéo mục\n2️⃣ Sửa mục: chạm vào mục\n3️⃣ Xóa mục: kéo mục ra ngoài khung SWOT\n4️⃣ Thêm mục: chạm ＋',
    '操作方法_方策最初の一歩': '1️⃣ Sửa: nhấn giữ mục',
    '操作方法_宣言': '1️⃣ Sửa: chạm vào mục',
    '次回から表示しない': 'Không hiện lại',
    'はじめる': 'Bắt đầu',
    'キーワード': 'Từ khóa',
    '小さなくるくる': '小さなくるくる\nchiisana kurukuru',
    '唱って躍れる': '唱って躍れる\nutatte odoreru',
    '分析結果': 'Kết quả phân tích',
    '削除': 'Xóa',
    'この分析を削除しますか？': 'Xóa phân tích này?',
    '元に戻すことはできません。': 'Không thể hoàn tác.',
    'キャンセル': 'Hủy',
    '削除する': 'Xóa',
    'やっぱりやらない': 'Thôi, không làm nữa',
    '方策を取り消しますか？': 'Hủy bỏ phương án này?',
    '最初の一歩を取り消しますか？': 'Hủy bỏ bước đầu tiên này?',
    '文言を編集': 'Sửa nội dung',
    '見直す方法を選んでください': 'Bạn muốn chỉnh theo cách nào?',
    '見直す_文言編集説明': 'Chỉ sửa nội dung hiện tại (không dùng AI)',
    '見直す_AI再相談説明': 'Xem lại / tạo lại ứng viên bằng Chrome AI Mode',
    '壁打ちメモ': 'Ghi chú brainstorm',
    '作成中_ホームで一覧': 'Dùng nút Home để về danh sách dự án',
    'タップまたは長押しで編集': 'Chạm hoặc nhấn giữ để sửa',
    'タップで今の状況を編集': 'Chạm để sửa tình hình hiện tại',
    '(テーマ未設定)': '(Chưa đặt chủ đề)',

    '編集': 'Chỉnh sửa',
    'お気に入りに追加': 'Thêm vào yêu thích',
    'お気に入り解除': 'Bỏ khỏi yêu thích',
    'テーマを編集': 'Chỉnh sửa chủ đề',
    '保存': 'Lưu',
    'ダッシュボードへ': 'Mở bảng điều khiển',
    '新規追加': 'Thêm mới',
    'データ': 'Dữ liệu',
    'その他': 'Khác',
    'ヘルプ': 'Trợ giúp',
    'ホーム': 'Trang chủ',
    'インポート': 'Nhập',

    '設定': 'Cài đặt',
    'プライバシー': 'Quyền riêng tư',
    'プライバシーとデータ': 'Quyền riêng tư & Dữ liệu',
    '言語': 'Ngôn ngữ',
    'アプリの表示言語を変更できます。': 'Bạn có thể thay đổi ngôn ngữ hiển thị của ứng dụng.',
    '言語_設定が正式': 'Đây là nơi chính thức để đặt ngôn ngữ hiển thị. Nút cờ ở màn hình bắt đầu cũng đổi cùng một cài đặt.',
    '言語_スタートショートカット': 'Bạn cũng có thể đổi trong Cài đặt',
    '設定_削除はプライバシーへ': 'Xóa trong màn hình Quyền riêng tư & dữ liệu',
    'スタートアップ画面': 'Màn hình khởi động',
    '起動時にスタート画面を表示': 'Hiện màn hình bắt đầu khi khởi động',
    '案件があっても、起動時はスタート画面から始めます。':
        'Luôn bắt đầu từ màn hình bắt đầu khi khởi động, kể cả khi đã có dự án.',
    'すべてのデータを初期化': 'Đặt lại toàn bộ dữ liệu',
    '本当に初期化しますか？': 'Đặt lại toàn bộ?',
    '初期化の説明':
        'Xóa mọi dữ liệu và cài đặt cục bộ, khôi phục trạng thái ban đầu. Không thể hoàn tác.',
    '初期化': 'Đặt lại',
    '初期化しました': 'Đã đặt lại',

    'プライバシー_外部送信': 'Bên nhận, dữ liệu và mục đích',
    'Google AIによる方策提案': 'Đề xuất phương án qua Google AI',
    'プライバシー_方策説明':
        'Nếu bạn yêu cầu đề xuất phương án, chủ đề, trạng thái mong muốn, trạng thái không mong muốn và toàn bộ SWOT (điểm mạnh, điểm yếu, cơ hội, mối đe dọa) sẽ được gửi đến Google Search (chế độ AI) do Google LLC cung cấp. Mục đích là nhận đề xuất phương án tham khảo. Ứng dụng hỏi sự đồng ý cho mỗi lần gửi. Áp dụng điều khoản và chính sách quyền riêng tư của Google.',
    'Google AIによる最初の一歩提案': 'Đề xuất bước đầu tiên qua Google AI',
    'プライバシー_最初の一歩説明':
        'Nếu bạn yêu cầu đề xuất bước đầu tiên, chủ đề, trạng thái mong muốn và phương án đã chọn sẽ được gửi đến Google Search (chế độ AI) do Google LLC cung cấp. Mục đích là nhận đề xuất bước đầu tiên tham khảo. Ứng dụng hỏi sự đồng ý cho mỗi lần gửi. Áp dụng điều khoản và chính sách quyền riêng tư của Google.',
    'プライバシーポリシー': 'Chính sách quyền riêng tư',
    'プライバシー_ポリシー本文_詳細':
        'Chi tiết về gửi dữ liệu ra ngoài, thời gian lưu giữ và cách xóa.',
    '関連ポリシー': 'Chính sách liên quan',
    'Google プライバシーポリシー': 'Chính sách quyền riêng tư của Google',
    'Apple プライバシーポリシー': 'Chính sách quyền riêng tư của Apple',
    'プライバシー_関連ポリシー_詳細':
        'Chính sách của Google áp dụng cho nội dung gửi đến Google Search (chế độ AI). Điều khoản của Apple có thể áp dụng cho phân phối App Store và sao lưu thiết bị.',
    'プライバシー_端末保存': 'Lưu trữ trên thiết bị',
    'プライバシー_保存詳細':
        'Chủ đề, mục tiêu, phân tích SWOT, phương án, bước đầu tiên, tuyên bố, nhìn lại, thứ tự dự án, ngôn ngữ hiển thị và cài đặt màn hình bắt đầu được lưu trong cơ sở dữ liệu Hive cục bộ trên thiết bị. Không đồng bộ đám mây.',
    'プライバシー_保持削除詳細':
        'Dữ liệu đã lưu được giữ đến khi bạn xóa từng mục hoặc chọn Xóa toàn bộ dữ liệu. Dữ liệu đã gửi đến Google được lưu giữ và xóa theo chính sách của Google, và không thể xóa từ ứng dụng này. Bản sao lưu JSON đã lưu ở ứng dụng khác cũng không thể xóa bởi ứng dụng này.',
    'プライバシー_JSONバックアップ案内':
        'Sao lưu / nhập JSON các dự án nằm trong menu Dữ liệu ở màn hình chính và thanh công cụ tạo kế hoạch.',
    'すべてのデータを削除': 'Xóa toàn bộ dữ liệu',
    'プライバシー_削除確認':
        'Xóa lịch sử phân tích và cài đặt Hive cùng các tệp sao lưu tạm thời? Không thể hoàn tác.',
    '端末内のアプリデータを削除しました': 'Đã xóa dữ liệu ứng dụng trên thiết bị',

    'HELP': 'HELP',
    'osmJiritsu': 'osmJiritsu',
    'バージョン %@ (%@)': 'Phiên bản %@ (%@)',
    '自律とは': 'Jiritsu là gì?',
    'ゴールと今の状況の差を無くすために、自分で考えて行動すること':
        'Tự suy nghĩ và hành động để thu hẹp khoảng cách giữa mục tiêu và tình trạng hiện tại',
    'テーマとゴール（在りたい姿／在りたくない姿）を決める':
        'Đặt chủ đề và mục tiêu (trạng thái mong muốn / không mong muốn)',
    '現状を整理し、SWOTから方策を自分で決める':
        'Sắp xếp hiện trạng, rồi tự quyết định phương án từ SWOT',
    '最初の一歩を宣言し、振り返りながら進める':
        'Tuyên bố bước đầu tiên, rồi tiến lên kèm nhìn lại',
    '自律の3要素': '3 yếu tố của Jiritsu',
    '方策や行動を決めるとき、この3つを満たしているか振り返ってみましょう。':
        'Khi quyết định phương án hoặc hành động, hãy kiểm tra xem đã đáp ứng cả 3 điều này chưa.',
    '自律の定義': 'Định nghĩa của Jiritsu',
    '（参考）自立とは': '(Tham khảo) Tự lập là gì?',
    '自分以外の何ものにも依存しない状態。':
        'Trạng thái không phụ thuộc vào bất cứ điều gì ngoài bản thân.',
    '自立できていない、依存している人は、自分のうまく行かない状態の責任や自分の感情、思考の原因すら周りの人や環境のせいにする。':
        'Người chưa tự lập, còn phụ thuộc, thường đổ lỗi cho người xung quanh hay hoàn cảnh — kể cả về những thất bại, cảm xúc và suy nghĩ của chính mình.',
    '自立には経済的自立、行動的自立、精神的自立があり、いずれも自律と密接に関係している（自律している人は自立できる）。':
        'Tự lập gồm ba mặt: tự lập về kinh tế, tự lập về hành động, và tự lập về tinh thần — cả ba đều liên quan mật thiết đến Jiritsu (người có Jiritsu thì có thể tự lập).',
    '自律できていない人にありがちな行動': 'Hành vi thường gặp ở người chưa có Jiritsu',
    '言われたことだけやる': 'Chỉ làm những gì được bảo',
    '不平、不満ばっかり': 'Toàn than phiền, bất mãn',
    '無感動、無関心': 'Thờ ơ, không quan tâm',
    'できない理由だけで、どうすればできるか？がない':
        'Chỉ nêu lý do không làm được, không nghĩ cách để làm được',
    '一見クールでカッコよく見えたりする。的を射てるし。周囲を白けさせるパワー大。口癖は「でもさ...」':
        'Thoạt nhìn có vẻ ngầu và có lý. Nhưng lại rất dễ làm nguội lạnh không khí xung quanh. Câu cửa miệng là "nhưng mà..."',
    '他人から言われる前に動く': 'Hành động trước khi người khác nhắc bạn',
    '主導権は自分にあるのだと意識すること': 'Ý thức rằng quyền chủ động nằm ở bạn',
    '方策の粒度を細かくすること': 'Chia nhỏ phương án thành các bước',
    '結果を見える化して視覚的に成果を実感すること':
        'Trực quan hóa kết quả để cảm nhận rõ thành quả',
    '周囲からサポートを得る': 'Nhận được sự hỗ trợ từ xung quanh',
    '言語化することで思いが現実性を持つ':
        'Diễn đạt thành lời giúp suy nghĩ trở nên hiện thực hơn',
    '動機づけマトリクス': 'Ma trận động lực',
    '方策を考える際、動機づけマトリクスを意識すると良い。':
        'Khi suy nghĩ về phương án, hãy để ý đến ma trận động lực.',
    '内発的動機づけ': 'Động lực nội tại',
    '外発的動機づけ': 'Động lực bên ngoài',
    '自分の内面的な興味・関心、探究心、楽しさなどが原動力となる状態。':
        'Trạng thái được thúc đẩy bởi sự quan tâm, tò mò, hay niềm vui nội tại của chính bản thân.',
    '＜特徴＞': '<Đặc điểm>',
    '行動すること自体が目的となるため、高い集中力が発揮され、質が高く、自発的な行動を長く続けやすい。':
        'Vì bản thân hành động đã là mục đích, nên dễ đạt được sự tập trung cao, chất lượng tốt, và hành động tự phát có thể duy trì lâu dài.',
    '＜具体例＞': '<Ví dụ>',
    '興味のある分野について自主的に深く調べる。':
        'Tự mình tìm hiểu sâu về một lĩnh vực mà bạn quan tâm.',
    '純粋に人を喜ばせたくて仕事に取り組む。':
        'Bắt tay vào công việc chỉ vì muốn làm người khác vui.',
    '＜メリット・デメリット＞': '<Ưu và nhược điểm>',
    '⭕️ モチベーションが長持ちする': '⭕️ Động lực kéo dài lâu',
    '❌ 本人の興味に依存するため即効性がない':
        '❌ Phụ thuộc vào sở thích cá nhân nên không có hiệu quả tức thì',
    '❌ 誰にでも同じように適用することは困難':
        '❌ Khó áp dụng giống nhau cho mọi người',
    '報酬、評価、昇進、あるいは罰則や叱責といった「外部からの刺激」をきっかけとして行動を促すこと。':
        'Thúc đẩy hành động thông qua các "kích thích từ bên ngoài" như phần thưởng, đánh giá, thăng chức, hoặc hình phạt và khiển trách.',
    '内発か？外発か？': 'Nội tại hay bên ngoài?',
    '内発と外発は対立するものではなく組み合わせもの。外発をきっかけに始めて、その内、それ自体が楽しくなる...（エンハンシング効果）。':
        'Động lực nội tại và bên ngoài không đối lập mà có thể kết hợp với nhau. Có thể bắt đầu nhờ một tác nhân bên ngoài, rồi dần dần chính hoạt động đó trở nên thú vị... (hiệu ứng khuếch đại).',
    '実行のステップを細かくして達成感を感じやすくすること。':
        'Chia nhỏ các bước thực hiện để dễ cảm nhận thành tựu.',
    '唱（ショウ）': 'Xướng (唱)',
    '昌には、盛んで明るいとか、美しいことばという意味があり、それと口にすることから、唱は、うたう、となえるの意味を表す。また、昌の音は、高く上げるという意味を含むから、唱は、声を高くあげること、あるいは、「人より先に大声を上げてリードする」ことである。':
        '昌 mang ý nghĩa "hưng thịnh, tươi sáng" hay "lời nói đẹp"; kết hợp với 口 (miệng, cất tiếng), 唱 mang nghĩa "hát", "xướng lên". Âm của 昌 còn hàm ý "nâng cao lên", nên 唱 còn có nghĩa "cất cao giọng nói", hay "dẫn đầu bằng cách lên tiếng lớn trước người khác".',
    '唱義：人に先立って正しい道をとなえる':
        '唱義: đi trước người khác để xướng lên con đường đúng đắn',
    '躍（ヤク）': 'Dược (躍)',
    '翟には高く抜き出る意味がある。躍は「すばやくおどりあがる」ことである。':
        '翟 mang ý nghĩa "vươn cao, nổi bật". 躍 là "nhảy vọt lên nhanh chóng".',
    '躍動：おどりうごく、いきいきと活動する':
        '躍動: chuyển động sôi nổi, hoạt động đầy sức sống',
    'つまり「唱って躍れる」とは「周りを引っ張って、元気に前に進める」「自分の考えを話して、みんなと共有できる」ことである。':
        'Nói cách khác, "唱って躍れる" (xướng lên và nhảy múa) nghĩa là "dẫn dắt mọi người xung quanh, tiến về phía trước một cách đầy nhiệt huyết" và "nói lên suy nghĩ của bản thân, chia sẻ cùng mọi người".',
    '誰かに話すことによって自分の中で漠然としていた夢が、どんどんリアリティを持ち、少しずつ形になり、ビジョンになっていく。これを繰り返す内にビジョンはより明確になり、とうとう的確な言葉で表現できるようになったとき、初めて明快な物語として、リアリティのある戦略として、それを人に伝達し、実際に行動に移していく事ができる。':
        'Khi kể cho ai đó nghe, giấc mơ vốn còn mơ hồ trong lòng bạn dần trở nên hiện thực hơn, từng chút một hình thành và trở thành một tầm nhìn. Lặp lại điều này nhiều lần, tầm nhìn ấy càng rõ ràng hơn, và khi cuối cùng bạn có thể diễn đạt nó bằng những lời chính xác, lúc đó bạn mới có thể truyền đạt nó cho người khác như một câu chuyện rõ ràng, như một chiến lược có tính thực tế, và thực sự bắt tay vào hành động.',
    '― 伊藤守「リーダーになる人ならない人」':
        '― Itō Mamoru, "Rīdā ni Naru Hito, Naranai Hito" (Người trở thành lãnh đạo, người thì không)',
    '登録日': 'Ngày đăng ký',
    '最終更新日': 'Cập nhật lần cuối',
    '期限': 'Hạn chót',
    '未設定': 'Chưa đặt',
    '期限を設定': 'Đặt hạn chót',
    '備考': 'Ghi chú',
    '備考を入力…': 'Nhập ghi chú…',
    '現況を変更': 'Thay đổi tình trạng',
    '振り返り': 'Nhìn lại',
    '振り返り履歴': 'Lịch sử nhìn lại',
    '進捗度': 'Tiến độ',
    '振り返り回数': 'Số lần nhìn lại',
    '振り返り %lld回': 'Nhìn lại %lld lần',
    '進捗度の見方': 'Cách tính tiến độ',
    '進捗度は、案件の進み具合を示す指標です。次の段階に達するたびに上がります。':
        'Tiến độ cho biết dự án đã tiến xa đến đâu. Mỗi khi đạt giai đoạn tiếp theo, tiến độ sẽ tăng.',
    '10%　テーマ設定済み': '10% — Đã đặt chủ đề',
    '20%　ゴール設定済み': '20% — Đã đặt mục tiêu',
    '30%　今の状況設定（SWOTマトリクス完成）':
        '30% — Đã thiết lập tình hình hiện tại (hoàn thành ma trận SWOT)',
    '40%　方策決定済み': '40% — Đã quyết định phương án',
    '50%　最初の一歩設定済み': '50% — Đã thiết lập bước đầu tiên',
    '60%　宣言終了': '60% — Đã hoàn tất tuyên bố',
    '70%　振り返り　1回実施': '70% — Đã nhìn lại 1 lần',
    '80%　振り返り　2回実施': '80% — Đã nhìn lại 2 lần',
    '90%　振り返り　3回以上実施': '90% — Đã nhìn lại từ 3 lần trở lên',
    '100%　完了': '100% — Hoàn tất',

    'どうだった？': 'Mọi việc thế nào?',
    '感じたこと、気づいたことを自由に書いてみましょう':
        'Hãy viết tự do về điều bạn cảm nhận hoặc nhận ra',
    '次はどうする？': 'Tiếp theo bạn muốn làm gì?',
    '続ける': 'Tiếp tục',
    '方策を変更する': 'Thay đổi phương án',
    '新しいテーマに取り組む': 'Bắt đầu chủ đề mới',
    '一旦休む': 'Tạm nghỉ',

    'iCloud同期': 'Đồng bộ iCloud',
    'iCloud同期_有効化フッター':
        'Khi bật, dữ liệu án được đồng bộ giữa các thiết bị đăng nhập cùng tài khoản iCloud.',
    'iCloud同期_利用不可': 'iCloud hiện không khả dụng. Vui lòng đăng nhập iCloud trong Cài đặt.',
    'iCloud同期_最終同期': 'Đồng bộ lần cuối',
    'iCloud同期_未同期': 'Chưa đồng bộ',
    'iCloud同期_今すぐ同期': 'Đồng bộ ngay',
    'iCloud同期_フッター':
        'Chủ đề, mục tiêu, SWOT, phương án, bước đầu tiên, tuyên bố và các lần nhìn lại của án được lưu trong iCloud Key-Value Storage và chia sẻ giữa các thiết bị cùng tài khoản iCloud.',
    'iCloud同期_相対時刻_日': '%lld ngày trước',
    'iCloud同期_相対時刻_時間': '%lld giờ trước',
    'iCloud同期_相対時刻_分': '%lld phút trước',
    'iCloud同期_相対時刻_今': 'Vừa xong',
    'iCloud同期_アップロード完了': 'Đã tải lên iCloud',
    'iCloud同期_ダウンロード完了': 'Đã tải xuống từ iCloud',
    'iCloud同期_エラー': 'Đồng bộ thất bại',
    'iCloud同期_エラー_未検出':
        'Không tìm thấy tính năng đồng bộ iCloud. Vui lòng khởi động lại ứng dụng.',
    'iCloud同期_エラー_案件未読込': 'Dữ liệu án chưa tải xong.',
    'iCloud同期_エラー_容量超過':
        'Dữ liệu của bạn (%@ MB) vượt quá giới hạn đồng bộ iCloud (1 MB).',
    'iCloud同期_エラー_マージ失敗': 'Không thể áp dụng dữ liệu đã tải xuống.',
    'iCloud同期_エラー_不正な応答': 'Nhận được phản hồi không mong muốn từ iCloud.',
    'iCloud同期_クラウドコピーを削除': 'Xóa bản sao đám mây iCloud',
    'iCloud同期_クラウドコピーを削除しますか？': 'Xóa bản sao iCloud?',
    'iCloud同期_クラウドコピー削除確認':
        'Thao tác này xóa dữ liệu án osmJiritsu và thời điểm đồng bộ khỏi iCloud KVS, nhưng không xóa án trên thiết bị.',
    'iCloud同期_クラウドコピー削除完了': 'Đã xóa bản sao iCloud.',
    'iCloud同期_クラウドコピー削除失敗': 'Không thể xóa. Hãy kiểm tra iCloud và thử lại.',
    'プライバシー_iCloud保存': 'Lưu trữ trên iCloud',
    'プライバシー_iCloud保存詳細':
        'Khi bật đồng bộ iCloud, chủ đề, mục tiêu, SWOT, phương án, bước đầu tiên, tuyên bố và các lần nhìn lại của án được lưu trong Apple iCloud Key-Value Storage và chia sẻ giữa các thiết bị cùng tài khoản iCloud.',
  };
}

extension AppStringsContext on String {
  String tr(AppLanguage language) => AppStrings.text(this, language);

  /// Fills `%@` (string) / `%lld` (integer) placeholders positionally, left
  /// to right. Mirrors osmWashabe's `trFmt`, which additionally supported
  /// explicit `%1$@`/`%1$lld` positional specifiers (needed there because
  /// EN/VI word order sometimes reorders arguments); osmJiritsu's templates
  /// so far never need reordering, so this ports the simpler positional
  /// pass without that extra iOS-format-string machinery.
  String trFmt(AppLanguage language, List<String> args) {
    var result = tr(language);
    for (final arg in args) {
      if (result.contains('%lld')) {
        result = result.replaceFirst('%lld', arg);
      } else {
        result = result.replaceFirst('%@', arg);
      }
    }
    return result;
  }
}
