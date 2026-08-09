import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/state/analysis_history_notifier.dart';
import '../../history/widgets/project_scaffold.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';
import '../../theme/osm_app_bar.dart';
import '../../wizard/widgets/primary_cta_button.dart';

/// Dedicated 宣言文 editor, reached by long-pressing 宣言文 on the
/// dashboard — lets that one field be revised on its own, without going
/// through the full 最初の一歩 decide flow (`FirstStepFlowScreen`'s own
/// 宣言文 step) just to touch it. Uses `ProjectScaffold` like every other
/// dashboard child screen, so the bottom toolbar stays visible.
class DeclarationEditScreen extends ConsumerStatefulWidget {
  final Project project;

  const DeclarationEditScreen({super.key, required this.project});

  @override
  ConsumerState<DeclarationEditScreen> createState() =>
      _DeclarationEditScreenState();
}

class _DeclarationEditScreenState
    extends ConsumerState<DeclarationEditScreen> {
  late final _controller = TextEditingController(
    text: widget.project.declaration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(analysisHistoryProvider.notifier)
        .saveOrUpdate(
          widget.project.copyWith(
            declaration: _controller.text.trim(),
            updatedAt: DateTime.now(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return ProjectScaffold(
      projectId: widget.project.id,
      mode: ProjectToolbarMode.child,
      guideMessageKey: '操作方法_宣言',
      appBar: OsmAppBar(title: Text('宣言文を編集'.tr(lang))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '上司や仲間にそのまま送れる、ひとことにしましょう。'.tr(lang),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.sceneTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(hintText: '宣言文'.tr(lang)),
              ),
              const SizedBox(height: 24),
              PrimaryCtaButton(
                label: '保存'.tr(lang),
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
