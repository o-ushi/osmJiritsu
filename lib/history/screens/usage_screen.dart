import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/widgets/language_flag_button.dart';
import '../../theme/app_theme.dart';
import '../widgets/startup_bottom_bar.dart';

/// 使い方画面 — Chrome AIモードのコピーボタンの押し方と、「•••」長押しで
/// 各画面の操作ヒントが見られることを教える。
///
/// スタート画面の「はじめる」の後（設定 ON のとき）に、`HistoryListScreen`
/// 内の表示切替の一つとして出す — `_StartScreen`と同じく、専用の
/// `Navigator` ルートは持たない。レイアウト/文言は osmGradus の
/// `UsageScreen` を踏襲するが、`AppSettings`（`ChangeNotifier`）ではなく
/// 呼び出し側から渡された [lang] を使う。
class UsageScreen extends StatefulWidget {
  const UsageScreen({
    super.key,
    required this.lang,
    required this.onContinue,
  });

  final AppLanguage lang;

  /// 「次回から表示しない」がチェックされていれば `true`。保存するかどうかは
  /// 呼び出し側の責務（このウィジェット自身は何も永続化しない）。
  final ValueChanged<bool> onContinue;

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    // Same frame as `_StartScreen`: the copy scrolls, and the checkbox
    // plus「ホーム画面へ」stay pinned at the bottom.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: LanguageFlagButton(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '使い方_タイトル'.tr(lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.sceneText,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ColoredBox(
                            color: Colors.white,
                            child: Image.asset(
                              'assets/images/chrome_ai_copy_button.png',
                              width: double.infinity,
                              fit: BoxFit.contain,
                              semanticLabel: '使い方_コピー画像_説明'.tr(lang),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '使い方_コピー本文'.tr(lang),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppPalette.sceneTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '使い方_操作ヒント'.tr(lang),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppPalette.sceneTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          StartupBottomBar(
            lang: lang,
            dontShowAgain: _dontShowAgain,
            onDontShowAgainChanged: (value) =>
                setState(() => _dontShowAgain = value),
            label: 'ホーム画面へ'.tr(lang),
            onPressed: () => widget.onContinue(_dontShowAgain),
          ),
        ],
      ),
    );
  }
}
