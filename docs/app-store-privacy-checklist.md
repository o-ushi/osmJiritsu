# App Store Privacy Checklist

## Guideline 5.1.1(i) / 5.1.2(i)

- [x] Google LLCを第三者受領者として明示
- [x] 送信項目を用途別に明示（方策: テーマ・在りたい姿・在りたくない姿・SWOT全文 / 最初の一歩: テーマ・在りたい姿・決めた方策）
- [x] 目的（参考提案を得る検索クエリ）を明示
- [x] 個人情報・機微情報を含み得ることを明示
- [x] ブラウザ／Googleアカウントの履歴に残る場合があることを明示
- [x] 初回・再試行・再オープンを同一の送信直前同意ゲート（`GoogleAiSendConsentDialog`）に統合
- [x] CTAを「同意してGoogleへ送信」にし、ダイアログ内にGoogleプライバシーポリシーリンクを表示
- [x] 拒否時にURL起動・クリップボード書き込みを行わない
- [x] 日本語・英語・ベトナム語で表示
- [x] 公開プライバシーポリシーにAI送信セクションを記載（ダイアログと同等の内容）

## アプリ内Privacy & Data

- [x] 設定 → プライバシーとデータへ常時アクセス可能
- [x] 送信先・項目・目的の開示カード（方策 / 最初の一歩）
- [x] 自アプリのプライバシーポリシーURL（Google Docs）への外部リンク
- [x] Google / Apple プライバシーポリシーへの外部リンク
- [x] Hiveによる端末内保存、非クラウド同期を説明
- [x] JSON共有Exportと共有先コピーの扱いを説明
- [x] 保持期間、個別削除、全削除／初期化を説明
- [x] Hive履歴・設定・一時Exportの全削除

## Privacy Policy URL

https://docs.google.com/document/d/1eyrLvDL245Z_eBaAI1vTKqbCjraTcJdOMzBUn0Orrrs/edit?usp=sharing

## App Store Connectで手動確認

- [ ] Privacy Policy URLへ上記HTTPS URLを登録（ログイン不要で世界から読めること）
- [ ] App Privacy回答を実装と整合させる（運営者が収集しないこと、Google Searchへのユーザー起動送信を審査メモで説明）
- [ ] Review Notesに、方策／最初の一歩のAI相談から毎回同意画面が出る再現手順を記載（キャンセル時は何も送られないこと）
- [ ] Review Notesに、設定 → プライバシーとデータで送信項目・ポリシーを確認できる経路を記載（発話なしで確認可能）
- [ ] Google Search（AIモード）の地域・アカウント依存挙動を審査アカウントで確認
- [ ] iPhone実機で縦向き固定、共有、全削除、ポリシーリンクを確認
