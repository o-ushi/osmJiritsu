import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/app_strings.dart';
import '../../models/jiritsu.dart';
import '../../models/jiritsu_check.dart';
import '../../theme/app_theme.dart';

/// Stage1 Step 7: one yes/no row per [JiritsuElement], backed by a
/// [JiritsuCheck] — osmJiritsu's core "内発度チェック" UI.
class JiritsuCheckPanel extends StatelessWidget {
  final JiritsuCheck check;
  final AppLanguage lang;
  final void Function(JiritsuElement element, bool value) onAnswer;

  const JiritsuCheckPanel({
    super.key,
    required this.check,
    required this.lang,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final element in JiritsuElement.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ElementRow(
              element: element,
              answer: check.answerFor(element),
              lang: lang,
              onAnswer: (value) => onAnswer(element, value),
            ),
          ),
      ],
    );
  }
}

class _ElementRow extends StatelessWidget {
  final JiritsuElement element;
  final bool answer;
  final AppLanguage lang;
  final void Function(bool value) onAnswer;

  const _ElementRow({
    required this.element,
    required this.answer,
    required this.lang,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: answer
              ? AppPalette.mintDark.withValues(alpha: 0.6)
              : const Color(0xFFE0E6E3),
          width: answer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              element.question.tr(lang),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: answer, onChanged: onAnswer),
        ],
      ),
    );
  }
}
