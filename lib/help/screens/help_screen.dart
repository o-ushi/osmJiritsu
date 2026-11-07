import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../icloud_sync/services/icloud_sync_service.dart';
import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../privacy/screens/privacy_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../theme/widgets/subpage_scaffold.dart';
import '../widgets/expand_card.dart';
import '../widgets/help_cards.dart';
import 'jiritsu_about_screen.dart';

/// ヘルプ。上から 「自律とは」→ 登録 → 閲覧 → 困った時 → その他 の順。
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  String? _rawVersion;
  String? _rawBuildNumber;

  /// 開いている節。
  final Set<String> _open = {};

  /// 色はまとまりごとに揃える。
  List<_HelpSection> get _sections => [
    const _HelpSection('start', Icons.add_circle_outline, Colors.orange, 2),
    const _HelpSection('lines', Icons.format_list_bulleted, Colors.orange, 2),
    const _HelpSection('goal', Icons.flag_outlined, Colors.orange, 1),
    _HelpSection(
      'reflect',
      Icons.history_edu_outlined,
      AppPalette.softBlueDark,
      2,
    ),
    _HelpSection('share', Icons.ios_share_rounded, AppPalette.softBlueDark, 2),
    const _HelpSection('howto', Icons.more_horiz, Colors.purple, 1),
    const _HelpSection('copy', Icons.copy_rounded, Colors.purple, 2),
    const _HelpSection('backup', Icons.import_export, Colors.purple, 2),
    if (IcloudSyncService.isSupported)
      const _HelpSection('icloud', Icons.cloud_outlined, Colors.teal, 1),
  ];

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _rawVersion = info.version;
      _rawBuildNumber = info.buildNumber;
    });
  }

  Widget _card({
    required String id,
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Padding(
      key: ValueKey('help-section-$id'),
      padding: const EdgeInsets.only(bottom: 10),
      child: JiritsuExpandCard(
        title: title,
        icon: icon,
        accent: accent,
        open: _open.contains(id),
        onToggle: () => setState(() {
          if (!_open.remove(id)) _open.add(id);
        }),
        child: child,
      ),
    );
  }

  Widget _progress(
    String id,
    String titleKey,
    AppLanguage lang,
    List<String> tips,
  ) {
    return _card(
      id: id,
      title: titleKey.tr(lang),
      icon: Icons.trending_up_rounded,
      accent: AppPalette.softBlueDark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: HelpBulletList(tips: tips, bulletColor: AppPalette.softBlueDark),
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _HelpHero(title: 'osmJiritsu'.tr(lang), versionLabel: versionLabel),
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
                  MaterialPageRoute(builder: (_) => const JiritsuAboutScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            for (final section in _sections.take(3)) _stepCard(section, lang),
            _progress('progressSimple', 'help.progressSimple', lang, [
              '20%　ゴール設定済み'.tr(lang),
              '30%　現状設定済み'.tr(lang),
              '40%　方策決定済み'.tr(lang),
              '50%　最初の一歩設定済み'.tr(lang),
              '70%　最初の一歩実施済み'.tr(lang),
              '80%　方策1つ実施済み'.tr(lang),
              '90%　方策全て実施済み'.tr(lang),
              '100%　ゴール達成済み'.tr(lang),
            ]),
            _progress('progressFull', 'help.progressFull', lang, [
              '10%　テーマ設定済み'.tr(lang),
              '20%　ゴール設定済み'.tr(lang),
              '30%　現状設定済み'.tr(lang),
              '40%　方策決定済み'.tr(lang),
              '50%　最初の一歩設定済み'.tr(lang),
              '60%　宣言終了'.tr(lang),
              '70%　振り返り　1回実施'.tr(lang),
              '80%　振り返り　2回実施'.tr(lang),
              '90%　振り返り　3回以上実施'.tr(lang),
              '100%　完了'.tr(lang),
            ]),
            for (final section in _sections.skip(3)) _stepCard(section, lang),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE1F0EA)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: const ValueKey('help-privacy'),
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.teal,
                ),
                title: Text(
                  'プライバシーとデータ'.tr(lang),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.subpageText,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.subpageTextMuted,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(_HelpSection section, AppLanguage lang) => _card(
    id: section.id,
    title: 'help.${section.id}.title'.tr(lang),
    icon: section.icon,
    accent: section.accent,
    child: JiritsuStepList(
      color: section.accent,
      steps: [
        for (var i = 1; i <= section.stepCount; i++)
          'help.${section.id}.$i'.tr(lang),
      ],
    ),
  );
}

/// ヘルプの 1 節。文言は `help.<id>.title` と `help.<id>.1`〜。
class _HelpSection {
  const _HelpSection(this.id, this.icon, this.accent, this.stepCount);

  final String id;
  final IconData icon;
  final Color accent;
  final int stepCount;
}

class _HelpHero extends StatelessWidget {
  const _HelpHero({required this.title, required this.versionLabel});

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
