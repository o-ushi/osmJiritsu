import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/subpage_scaffold.dart';
import '../widgets/help_cards.dart';
import 'jiritsu_about_screen.dart';

/// osmJiritsu HELP — layout ported from osmGradus (hero icon + lead card +
/// accent-bar section cards). The「自律とは」row is just a link out to
/// [JiritsuAboutScreen] — the definition and 自律の3要素 explanation live
/// there, not duplicated here.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  /// Google スライド操作マニュアル（言語別・閲覧用 preview）。
  /// 共有は「リンクを知っている全員」。編集 URL ではなく preview を開く。
  /// 英語・ベトナム語は同じファイルを上書き更新する前提（ID は固定）。
  static const userManualPresentationIdJa =
      '1C3BGFdWm6UneFcPQC0d7ftQ46n65hsN4uB8KAdXHObU';
  static const userManualPresentationIdEn =
      '14pVMbXOI4YSaV-PpC02N1r6IYFNTYUFiqcdiIA5uLos';
  static const userManualPresentationIdVi =
      '1ALuMLxX3wRoySWb6mWdY8i59eLeP7gy-O7Ut5q8elFc';

  static String userManualUrlFor(AppLanguage language) {
    final id = switch (language) {
      AppLanguage.english => userManualPresentationIdEn,
      AppLanguage.japanese => userManualPresentationIdJa,
      AppLanguage.vietnamese => userManualPresentationIdVi,
    };
    return 'https://docs.google.com/presentation/d/$id/preview';
  }

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  String? _rawVersion;
  String? _rawBuildNumber;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _rawVersion = info.version;
        _rawBuildNumber = info.buildNumber;
      });
    } catch (_) {
      // Plugin missing (e.g. hot-reload without rebuild) — leave blank
      // rather than crash; a full restart after `pod install` fixes it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final versionLabel = (_rawVersion != null && _rawBuildNumber != null)
        ? 'バージョン %@ (%@)'.trFmt(lang, [_rawVersion!, _rawBuildNumber!])
        : null;

    return SubpageScaffold(
      appBar: OsmAppBar(title: Text('HELP'.tr(lang))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _HelpHero(
              title: 'osmJiritsu'.tr(lang),
              versionLabel: versionLabel,
            ),
            const SizedBox(height: 20),
            _HelpManualLink(
              lang: lang,
              accentColor: AppPalette.amber,
              onTap: () => launchUrl(
                Uri.parse(HelpScreen.userManualUrlFor(lang)),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: 20),
            HelpLeadCard(
              title: '自律とは'.tr(lang),
              accentColor: AppPalette.mintDark,
              trailing: Icon(
                Icons.chevron_right,
                color: AppPalette.subpageTextMuted,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const JiritsuAboutScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              '進捗度の見方'.tr(lang),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppPalette.subpageTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            HelpLeadCard(
              title: '進捗度'.tr(lang),
              summary: '進捗度は、案件の進み具合を示す指標です。次の段階に達するたびに上がります。'
                  .tr(lang),
              tips: [
                '10%　テーマ設定済み'.tr(lang),
                '20%　ゴール設定済み'.tr(lang),
                '30%　今の状況設定（SWOTマトリクス完成）'.tr(lang),
                '40%　方策決定済み'.tr(lang),
                '50%　最初の一歩設定済み'.tr(lang),
                '60%　宣言終了'.tr(lang),
                '70%　振り返り　1回実施'.tr(lang),
                '80%　振り返り　2回実施'.tr(lang),
                '90%　振り返り　3回以上実施'.tr(lang),
                '100%　完了'.tr(lang),
              ],
              accentColor: AppPalette.softBlueDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the Google スライド操作マニュアル for the current app language.
/// Layout ported from osmGradus's `_HelpManualLink` (icon circle + title +
/// accent-colored summary + external-link chevron), built on the same
/// [HelpSectionCardShell] the rest of this screen already uses.
class _HelpManualLink extends StatelessWidget {
  const _HelpManualLink({
    required this.lang,
    required this.accentColor,
    required this.onTap,
  });

  final AppLanguage lang;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HelpSectionCardShell(
      key: const Key('help_user_manual'),
      accentColor: accentColor,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '操作マニュアル'.tr(lang),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.subpageText,
                  ),
                ),
                Text(
                  '図解で画面ごとの使い方を見る'.tr(lang),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            size: 18,
            color: AppPalette.subpageTextMuted,
          ),
        ],
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero({
    required this.title,
    required this.versionLabel,
  });

  final String title;
  final String? versionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.subpageText,
          ),
        ),
        if (versionLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            versionLabel!,
            style: TextStyle(fontSize: 12, color: AppPalette.subpageTextMuted),
          ),
        ],
      ],
    );
  }
}
