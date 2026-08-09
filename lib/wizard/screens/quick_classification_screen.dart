import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../models/classification_axes.dart';
import '../models/wizard_idea.dart';
import '../state/wizard_notifier.dart';
import '../state/wizard_state.dart';
import '../widgets/choice_card_button.dart';
import '../widgets/primary_cta_button.dart';
import 'swot_matrix_screen.dart';

/// Step 4: classify each idea by answering two small yes/no questions in
/// sequence — never a single combined 4-way SWOT choice. A tap answers
/// "is this good or a concern?", then a second tap answers "is that up to
/// me, or the situation?"; the SWOT quadrant (strength/weakness/
/// opportunity/threat) falls out of those two answers afterwards and is
/// never named while the user is deciding.
class QuickClassificationScreen extends ConsumerStatefulWidget {
  const QuickClassificationScreen({super.key});

  @override
  ConsumerState<QuickClassificationScreen> createState() =>
      _QuickClassificationScreenState();
}

class _QuickClassificationScreenState
    extends ConsumerState<QuickClassificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(wizardProvider.notifier);
    final total = ref.watch(wizardProvider.select((s) => s.ideas.length));
    final classifiedCount = ref.watch(
      wizardProvider.select((s) => s.classifiedCount),
    );
    final current = ref.watch(
      wizardProvider.select((s) => s.currentUnclassifiedIdea),
    );
    final question = ref.watch(wizardProvider.select((s) => s.currentQuestion));
    final canGoBack = ref.watch(
      wizardProvider.select((s) => s.canGoBackInClassification),
    );
    final isComplete = current == null;
    final lang = ref.watch(appLanguageProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    total == 0
                        ? ''
                        : '%lld / %lld 個 完了'.trFmt(lang, [
                            '$classifiedCount',
                            '$total',
                          ]),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
                  ),
                ),
                TextButton(
                  onPressed: canGoBack ? notifier.goBackOneQuestion : null,
                  child: Text('戻す'.tr(lang)),
                ),
              ],
            ),
          ),
          Expanded(
            child: isComplete
                ? _CompletionState(lang: lang)
                : _ClassificationBody(
                    idea: current,
                    question: question!,
                    lang: lang,
                    onChooseEvaluation: notifier.answerEvaluation,
                    onChooseLocus: notifier.answerLocus,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClassificationBody extends StatelessWidget {
  final WizardIdea idea;
  final ClassificationQuestion question;
  final AppLanguage lang;
  final void Function(EvaluationAxis) onChooseEvaluation;
  final void Function(LocusAxis) onChooseLocus;

  const _ClassificationBody({
    required this.idea,
    required this.question,
    required this.lang,
    required this.onChooseEvaluation,
    required this.onChooseLocus,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        keyboardOpen ? 8 : 16,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            ),
            child: _IdeaSpotlightCard(
              key: ValueKey(idea.id),
              text: idea.text,
              compact: keyboardOpen,
            ),
          ),
          SizedBox(height: keyboardOpen ? 12 : 20),
          _QuestionStepDots(question: question),
          SizedBox(height: keyboardOpen ? 12 : 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              (question == ClassificationQuestion.evaluation
                      ? 'これって、良いこと？ 気になること？'
                      : 'それって、自分次第で変えられる？')
                  .tr(lang),
              key: ValueKey(question),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPalette.sceneText),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: question == ClassificationQuestion.evaluation
                ? _EvaluationChoices(
                    key: const ValueKey('evaluation'),
                    lang: lang,
                    compact: keyboardOpen,
                    onChoose: onChooseEvaluation,
                  )
                : _LocusChoices(
                    key: const ValueKey('locus'),
                    lang: lang,
                    compact: keyboardOpen,
                    onChoose: onChooseLocus,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationChoices extends StatelessWidget {
  final AppLanguage lang;
  final bool compact;
  final void Function(EvaluationAxis) onChoose;
  const _EvaluationChoices({
    super.key,
    required this.lang,
    this.compact = false,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChoiceCardButton(
              emoji: '😊',
              title: '良いこと'.tr(lang),
              subtitle: compact ? null : '自信がある・嬉しい'.tr(lang),
              color: AppPalette.mint,
              onTap: () => onChoose(EvaluationAxis.positive),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChoiceCardButton(
              emoji: '😕',
              title: '気になること'.tr(lang),
              subtitle: compact ? null : '不安・課題に感じる'.tr(lang),
              color: AppPalette.coral,
              onTap: () => onChoose(EvaluationAxis.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocusChoices extends StatelessWidget {
  final AppLanguage lang;
  final bool compact;
  final void Function(LocusAxis) onChoose;
  const _LocusChoices({
    super.key,
    required this.lang,
    this.compact = false,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChoiceCardButton(
              emoji: '🧠',
              title: '自分次第'.tr(lang),
              subtitle: compact ? null : '頑張れば変えられる'.tr(lang),
              color: AppPalette.softBlue,
              onTap: () => onChoose(LocusAxis.internal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChoiceCardButton(
              emoji: '🌍',
              title: 'まわりの状況'.tr(lang),
              subtitle: compact ? null : '環境や他人に左右される'.tr(lang),
              color: AppPalette.amber,
              onTap: () => onChoose(LocusAxis.external),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two small dots showing progress through *this idea's* two questions —
/// intentionally not labeled "SWOT axis" anything, just "question 1 of 2".
class _QuestionStepDots extends StatelessWidget {
  final ClassificationQuestion question;
  const _QuestionStepDots({required this.question});

  @override
  Widget build(BuildContext context) {
    Widget dot(bool active) => AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? AppPalette.mintDark
            : AppPalette.mintDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(question == ClassificationQuestion.evaluation),
        const SizedBox(width: 6),
        dot(question == ClassificationQuestion.locus),
      ],
    );
  }
}

class _IdeaSpotlightCard extends StatelessWidget {
  final String text;
  final bool compact;

  const _IdeaSpotlightCard({
    super.key,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 88 : 140),
      padding: EdgeInsets.all(compact ? 20 : 28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.cardFill,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontSize: 20, height: 1.4),
      ),
    );
  }
}

class _CompletionState extends StatelessWidget {
  final AppLanguage lang;
  const _CompletionState({required this.lang});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '全部答えられました！'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppPalette.sceneText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '実はこれ、SWOT分析になっています。\n出来上がったマトリクスを見てみましょう。'.tr(lang),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.sceneTextMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryCtaButton(
              label: 'マトリクスを確認する'.tr(lang),
              icon: Icons.grid_view_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 380),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SwotMatrixScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                  ),
                );
              },
            ),
          ],
        ),
    );
  }
}
