import 'package:uuid/uuid.dart';

import '../../models/swot_category.dart';
import 'classification_axes.dart';

const _uuid = Uuid();

/// One raw idea captured during the brainstorm (idea-dump) step, which may
/// or may not have been classified onto the SWOT quadrants yet.
///
/// Kept distinct from [SwotItem] because during the dump step an idea
/// intentionally has no category — [SwotItem] requires one.
class WizardIdea {
  final String id;
  final String text;
  final EvaluationAxis? evaluation;
  final LocusAxis? locus;

  WizardIdea({String? id, required this.text, this.evaluation, this.locus})
    : id = id ?? _uuid.v4();

  bool get isClassified => evaluation != null && locus != null;

  SwotCategory? get category =>
      isClassified ? categoryFor(evaluation!, locus!) : null;

  /// Answers this idea's first question (good vs. concerning), leaving the
  /// second question's answer untouched. Classification is asked one
  /// question at a time — see `WizardNotifier.answerEvaluation` — rather
  /// than as a single combined 4-way choice.
  WizardIdea withEvaluation(EvaluationAxis? evaluation) =>
      WizardIdea(id: id, text: text, evaluation: evaluation, locus: locus);

  /// Answers this idea's second question (self vs. environment), leaving
  /// the first question's answer untouched.
  WizardIdea withLocus(LocusAxis? locus) =>
      WizardIdea(id: id, text: text, evaluation: evaluation, locus: locus);

  WizardIdea unclassified() => WizardIdea(id: id, text: text);

  @override
  bool operator ==(Object other) =>
      other is WizardIdea &&
      other.id == id &&
      other.text == text &&
      other.evaluation == evaluation &&
      other.locus == locus;

  @override
  int get hashCode => Object.hash(id, text, evaluation, locus);
}
