import '../../models/swot_category.dart';

/// Axis A of the quick-classification screen: is this idea something good
/// (an asset to lean into) or something bad (a problem to manage)?
enum EvaluationAxis { positive, negative }

/// Axis B of the quick-classification screen: is this within the user's
/// own control (internal) or dictated by their environment (external)?
enum LocusAxis { internal, external }

/// Maps the two intuitive yes/no axes onto the four classic SWOT
/// quadrants, per Step 2's spec:
///
/// |            | internal (自分次第) | external (環境次第) |
/// |------------|---------------------|----------------------|
/// | positive   | Strength            | Opportunity          |
/// | negative   | Weakness            | Threat               |
SwotCategory categoryFor(EvaluationAxis evaluation, LocusAxis locus) {
  switch ((evaluation, locus)) {
    case (EvaluationAxis.positive, LocusAxis.internal):
      return SwotCategory.strength;
    case (EvaluationAxis.positive, LocusAxis.external):
      return SwotCategory.opportunity;
    case (EvaluationAxis.negative, LocusAxis.internal):
      return SwotCategory.weakness;
    case (EvaluationAxis.negative, LocusAxis.external):
      return SwotCategory.threat;
  }
}

/// The inverse of [categoryFor]: which (evaluation, locus) pair produces a
/// given quadrant. Used when the Step 3 matrix screen drags a card into a
/// different quadrant — there is no separate "category override" field, so
/// moving a card just rewrites the two axes that already determine it.
({EvaluationAxis evaluation, LocusAxis locus}) axesForCategory(
  SwotCategory category,
) {
  switch (category) {
    case SwotCategory.strength:
      return (evaluation: EvaluationAxis.positive, locus: LocusAxis.internal);
    case SwotCategory.opportunity:
      return (evaluation: EvaluationAxis.positive, locus: LocusAxis.external);
    case SwotCategory.weakness:
      return (evaluation: EvaluationAxis.negative, locus: LocusAxis.internal);
    case SwotCategory.threat:
      return (evaluation: EvaluationAxis.negative, locus: LocusAxis.external);
  }
}
