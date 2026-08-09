import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../state/wizard_notifier.dart';
import '../widgets/idea_bubble_card.dart';
import '../widgets/primary_cta_button.dart';

/// Step 3: a judgment-free brainstorm — the "現状の壁打ち" step. Ideas are
/// typed one at a time into a chat-style input and pile up as bubbles
/// above — no category picker, no "correctness" to worry about here, just
/// capture. This same list doubles as `WizardState.toSituationNotes()`'s
/// source, so there's no separate free-text entry step for that.
class IdeaDumpScreen extends ConsumerStatefulWidget {
  const IdeaDumpScreen({super.key});

  @override
  ConsumerState<IdeaDumpScreen> createState() => _IdeaDumpScreenState();
}

class _IdeaDumpScreenState extends ConsumerState<IdeaDumpScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit(WizardNotifier notifier) {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    notifier.addIdea(text);
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(wizardProvider.notifier);
    final theme = ref.watch(wizardProvider.select((s) => s.theme));
    final ideas = ref.watch(wizardProvider.select((s) => s.ideas));
    final canProceed = ref.watch(
      wizardProvider.select((s) => s.canProceedFromIdeaDump),
    );
    final lang = ref.watch(appLanguageProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'テーマ: %@'.trFmt(lang, [theme]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppPalette.sceneTextMuted),
                ),
                Text(
                  '思いつくままに、どんどん追加しよう'.tr(lang),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppPalette.sceneText),
                ),
              ],
            ),
          ),
          Expanded(
            child: ideas.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: _EmptyHint(theme: theme, lang: lang),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: ideas.length,
                    itemBuilder: (context, index) {
                      final idea = ideas[index];
                      return IdeaBubbleCard(
                        key: ValueKey(idea.id),
                        text: idea.text,
                        onDelete: () => notifier.removeIdea(idea.id),
                      );
                    },
                  ),
          ),
          if (canProceed && !keyboardOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PrimaryCtaButton(
                label: '%lld件を分類する'.trFmt(lang, ['${ideas.length}']),
                icon: Icons.auto_awesome_rounded,
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  notifier.advanceFromIdeaDump();
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, keyboardOpen ? 8 : 16),
            child: _ChatInputBar(
              controller: _inputController,
              onSubmit: () => _submit(notifier),
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final AppLanguage lang;

  const _ChatInputBar({
    required this.controller,
    required this.onSubmit,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppPalette.cardFill,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: '思いついたことを入力…'.tr(lang),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Material(
            color: AppPalette.mintDark,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSubmit,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: AppPalette.onAccent,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String theme;
  final AppLanguage lang;
  const _EmptyHint({required this.theme, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '「%@」について\n思いつくことを何でも入力してみましょう'.trFmt(lang, [theme]),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
          ),
        ],
      ),
    );
  }
}
