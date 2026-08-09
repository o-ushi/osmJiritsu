import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../history/project_navigation.dart';
import '../../history/widgets/flow_scaffold.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../models/project.dart';
import '../../wizard/state/wizard_notifier.dart';
import '../../wizard/widgets/primary_cta_button.dart';

/// Stage1 Step 11: the last step of "自律計画作成" — a plain-text summary
/// (テーマ/ゴール1/ゴール2/方策/最初の一歩/宣言文, [Project.shareSummary]'s
/// fixed shape) meant to be sent to a boss or teammate as-is.
///
/// Shares via `share_plus`'s plain-text share sheet — which already lets
/// the user pick Mail among its targets (and fills [ShareParams.subject]
/// as the email subject where supported). PDF export is intentionally not
/// offered (no CJK-capable PDF font is bundled).
///
/// The in-body "共有する" button below is itself only shown when
/// [fromProjectDashboard] is false: reached that way (fresh from Stage1,
/// wrapped in [FlowScaffold]) there's no other share entry point yet, but
/// reached from an existing project ([ProjectScaffold]'s toolbar wraps this
/// screen too) the bottom toolbar's own 共有 button already covers it —
/// and with more choice (要報/詳報), so a second "共有する" button here
/// would just be the same action twice.
class ProjectExportScreen extends ConsumerWidget {
  const ProjectExportScreen({super.key, this.fromProjectDashboard = false});

  final bool fromProjectDashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(wizardProvider.select((s) => s.toProject()));
    final lang = ref.watch(appLanguageProvider);
    final summary = project.shareSummary;

    final appBar = OsmAppBar(title: Text('まとめを共有'.tr(lang)));
    final body = SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            '上司や仲間にそのまま送れます。'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
          ),
          const SizedBox(height: 8),
          Text(
            '共有_テキスト説明'.tr(lang),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.sceneTextMuted),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.cardFill,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SelectableText(
              summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (!fromProjectDashboard) ...[
            const SizedBox(height: 24),
            PrimaryCtaButton(
              label: '共有する'.tr(lang),
              icon: Icons.ios_share_rounded,
              onPressed: () => _share(summary),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _finish(context, ref, project),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text('完了'.tr(lang)),
          ),
        ],
      ),
    );

    if (fromProjectDashboard) {
      return ProjectScaffold(
        projectId: project.id,
        mode: ProjectToolbarMode.child,
        appBar: appBar,
        body: body,
      );
    }

    return FlowScaffold(
      appBar: appBar,
      body: body,
    );
  }

  Future<void> _share(String summary) {
    return SharePlus.instance.share(
      ShareParams(text: summary, subject: 'osmJiritsu 自律計画'),
    );
  }

  /// Stage1's very last step: clear the whole wizard→strategy→first-step
  /// navigation stack back down to history root, then push the saved
  /// project's dashboard — by this point `decidedFirstStep` is set, so
  /// `toProject().status` is already 実施中, exactly what the dashboard
  /// expects to show.
  void _finish(BuildContext context, WidgetRef ref, Project project) {
    if (fromProjectDashboard) {
      ProjectNavigation.popToDashboard(context);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      ProjectNavigation.dashboardRoute(DashboardScreen(project: project)),
      (route) => route.isFirst,
    );
  }
}
