import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../theme/widgets/app_dialog.dart';
import 'screens/privacy_screen.dart';

/// Google検索（AIモード）へプロンプトを送る直前の同意ダイアログ。
/// osmGradusの`GoogleAiSendConsentDialog`と同等 — 方策・最初の一歩など
/// 送信元は分かれたまま、確認UIだけ共通化する。
abstract final class GoogleAiSendConsentDialog {
  /// [titleKey]・[bodyKey]は画面ごとの文言を差し替えるための翻訳キー。
  /// true = 同意して送信、false/ダイアログ却下 = キャンセル。
  static Future<bool> confirm(
    BuildContext context, {
    required AppLanguage lang,
    required String titleKey,
    required String bodyKey,
  }) async {
    final confirmed = await showAppAlertDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(titleKey.tr(lang)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bodyKey.tr(lang)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(PrivacyScreen.googlePrivacyUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text('Google プライバシーポリシー'.tr(lang)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('キャンセル'.tr(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('同意してGoogleへ送信'.tr(lang)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
