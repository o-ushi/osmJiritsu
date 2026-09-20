import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/widgets/language_flag_button.dart';
import '../../theme/app_theme.dart';

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

    // Structure mirrors `_StartScreen`: language flag top-right, then a
    // vertically-centered scroll column with the same horizontal padding.
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
                        const SizedBox(height: 28),
                        InkWell(
                          onTap: () => setState(
                            () => _dontShowAgain = !_dontShowAgain,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _dontShowAgain,
                                    onChanged: (value) {
                                      setState(
                                        () =>
                                            _dontShowAgain = value ?? false,
                                      );
                                    },
                                    side: const BorderSide(
                                      color: AppPalette.sceneText,
                                      width: 1.5,
                                    ),
                                    fillColor:
                                        WidgetStateProperty.resolveWith((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return AppPalette.mintDark;
                                      }
                                      return Colors.transparent;
                                    }),
                                    checkColor: AppPalette.onAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    '次回から表示しない'.tr(lang),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppPalette.sceneText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              widget.onContinue(_dontShowAgain),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPalette.mintDark,
                            foregroundColor: AppPalette.onAccent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'ホーム画面へ'.tr(lang),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
