import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../privacy/google_ai_send_consent_dialog.dart';
import '../../theme/app_theme.dart';
import '../../wizard/widgets/primary_cta_button.dart';

/// Shared Chrome-AI-Mode round-trip UI used by Stage1 方策 and 最初の一歩.
///
/// Domain-specific decide / jiritsu / declaration screens stay in their
/// own modules; only the launch → paste → fail states are shared here so
/// copy and chrome chrome stay in sync.

Future<void> requestGoogleAiConsentAndOpen({
  required BuildContext context,
  required AppLanguage lang,
  required String titleKey,
  required String bodyKey,
  required Future<void> Function() openChrome,
  bool leaveOnDecline = false,
}) async {
  final confirmed = await GoogleAiSendConsentDialog.confirm(
    context,
    lang: lang,
    titleKey: titleKey,
    bodyKey: bodyKey,
  );
  if (!context.mounted) return;
  if (!confirmed) {
    if (leaveOnDecline) Navigator.of(context).pop();
    return;
  }
  await openChrome();
}

class ChromeAiLaunchingView extends StatelessWidget {
  final AppLanguage lang;

  const ChromeAiLaunchingView({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppPalette.mintDark),
            const SizedBox(height: 24),
            Text(
              'Chromeを開いています…'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
            ),
          ],
        ),
      ),
    );
  }
}

class ChromeAiLaunchFailedView extends StatelessWidget {
  final String message;
  final AppLanguage lang;
  final VoidCallback onRetry;

  const ChromeAiLaunchFailedView({
    super.key,
    required this.message,
    required this.lang,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppPalette.coral,
            ),
            const SizedBox(height: 16),
            Text(
              'Chromeを開けませんでした'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 24),
            PrimaryCtaButton(
              label: 'もう一度試す'.tr(lang),
              icon: Icons.open_in_new_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class ChromeAiAwaitingPasteView extends StatelessWidget {
  final AppLanguage lang;
  final VoidCallback onPaste;
  final VoidCallback onReopenChrome;

  const ChromeAiAwaitingPasteView({
    super.key,
    required this.lang,
    required this.onPaste,
    required this.onReopenChrome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              'Chromeでの回答を確認してください'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'AIの回答をコピーしたら、この画面に戻って\n下のボタンをタップしてください。'.tr(lang),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 24),
            PrimaryCtaButton(
              label: '貼り付けて確認する'.tr(lang),
              icon: Icons.content_paste_go_rounded,
              onPressed: onPaste,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReopenChrome,
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.ensureReadableOnScene(
                  AppPalette.sceneText,
                ),
              ),
              child: Text('もう一度Chromeを開く'.tr(lang)),
            ),
          ],
        ),
      ),
    );
  }
}

class ChromeAiPasteFailedView extends StatelessWidget {
  final String message;
  final AppLanguage lang;
  final VoidCallback onRetryPaste;
  final VoidCallback onReopenChrome;

  const ChromeAiPasteFailedView({
    super.key,
    required this.message,
    required this.lang,
    required this.onRetryPaste,
    required this.onReopenChrome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppPalette.coral,
            ),
            const SizedBox(height: 16),
            Text(
              '読み取れませんでした'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
            ),
            const SizedBox(height: 24),
            PrimaryCtaButton(
              label: 'もう一度貼り付ける'.tr(lang),
              icon: Icons.content_paste_go_rounded,
              onPressed: onRetryPaste,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReopenChrome,
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.ensureReadableOnScene(
                  AppPalette.sceneText,
                ),
              ),
              child: Text('Chromeを開き直す'.tr(lang)),
            ),
          ],
        ),
      ),
    );
  }
}
