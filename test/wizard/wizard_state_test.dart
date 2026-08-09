import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/jiritsu_check.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/strategy_suggestion.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';
import 'package:osm_jiritsu/wizard/models/classification_axes.dart';
import 'package:osm_jiritsu/wizard/models/wizard_idea.dart';
import 'package:osm_jiritsu/wizard/state/wizard_state.dart';

void main() {
  group('WizardState.canProceedFromTheme / canProceedFromGoal', () {
    test('theme gate requires only the theme', () {
      expect(WizardState().canProceedFromTheme, isFalse);
      expect(WizardState(theme: 'テーマ').canProceedFromTheme, isTrue);
      expect(WizardState(theme: '  ').canProceedFromTheme, isFalse);
    });

    test('goal gate requires only 在りたい姿 — 在りたくない姿 is optional', () {
      expect(WizardState().canProceedFromGoal, isFalse);
      expect(
        WizardState(undesiredGoal: '避けたい姿だけ入力').canProceedFromGoal,
        isFalse,
      );
      expect(
        WizardState(desiredGoal: '在りたい姿').canProceedFromGoal,
        isTrue,
      );
    });
  });

  group('WizardState.toSituationNotes', () {
    test('mirrors every dumped idea, classified or not', () {
      final state = WizardState(
        ideas: [
          WizardIdea(text: '未分類のアイデア'),
          WizardIdea(
            text: '分類済みのアイデア',
            evaluation: EvaluationAxis.positive,
            locus: LocusAxis.internal,
          ),
        ],
      );

      final notes = state.toSituationNotes();

      expect(notes, hasLength(2));
      expect(notes.map((n) => n.content), [
        '未分類のアイデア',
        '分類済みのアイデア',
      ]);
      // Stable identity: the idea's id carries over rather than being
      // re-minted, so a note can be traced back to its source idea.
      expect(notes[0].id, state.ideas[0].id);
      expect(notes[1].id, state.ideas[1].id);
    });
  });

  group('WizardState.toProject', () {
    test('carries theme/goal/matrix/situationNotes through', () {
      final state = WizardState(
        theme: '新しいキャリアについて',
        desiredGoal: '納得感のある転職をしている',
        undesiredGoal: '妥協して転職している',
        ideas: [
          WizardIdea(
            text: '高い技術力',
            evaluation: EvaluationAxis.positive,
            locus: LocusAxis.internal,
          ),
        ],
      );

      final project = state.toProject();

      expect(project.id, state.sessionId);
      expect(project.theme, '新しいキャリアについて');
      expect(project.desiredGoal, '納得感のある転職をしている');
      expect(project.undesiredGoal, '妥協して転職している');
      expect(project.matrix.strengths.single.content, '高い技術力');
      expect(project.situationNotes.single.content, '高い技術力');
      // This stage never decides a strategy/first step/declaration yet.
      expect(project.decidedStrategy, '');
      expect(project.decidedFirstStep, '');
      expect(project.declaration, '');
      expect(project.status, ProjectStatus.preparing);
    });

    test(
      'carries decidedStrategy/aiStrategySuggestions/jiritsuCheck through',
      () {
        final suggestions = [StrategySuggestion(text: '方策案')];
        const check = JiritsuCheck(selfDetermined: true);
        final state = WizardState(
          theme: 'テーマ',
          decidedStrategy: '決めた方策',
          aiStrategySuggestions: suggestions,
          jiritsuCheck: check,
        );

        final project = state.toProject();

        expect(project.decidedStrategy, '決めた方策');
        expect(project.aiStrategySuggestions, suggestions);
        expect(project.jiritsuCheck.selfDetermined, isTrue);
        // A decided strategy alone isn't yet "実施中" — see the next group.
        expect(project.status, ProjectStatus.preparing);
      },
    );

    test('carries decidedFirstStep/declaration through', () {
      final state = WizardState(
        theme: 'テーマ',
        decidedFirstStep: '決めた最初の一歩',
        declaration: '私は〇〇を目指しています。まずは△△を実践します。',
      );

      final project = state.toProject();

      expect(project.decidedFirstStep, '決めた最初の一歩');
      expect(project.declaration, '私は〇〇を目指しています。まずは△△を実践します。');
    });

    group('status derivation', () {
      test('stays preparing when no first step has been decided yet', () {
        final state = WizardState(theme: 'テーマ');
        expect(state.toProject().status, ProjectStatus.preparing);
      });

      test(
        'stays preparing once a strategy is decided but no first step yet',
        () {
          final state = WizardState(
            theme: 'テーマ',
            decidedStrategy: '決めた方策',
          );
          expect(state.toProject().status, ProjectStatus.preparing);
        },
      );

      test(
        'becomes inProgress once a first step is decided ("Fix完了")',
        () {
          final state = WizardState(
            theme: 'テーマ',
            decidedStrategy: '決めた方策',
            decidedFirstStep: '決めた最初の一歩',
          );
          expect(state.toProject().status, ProjectStatus.inProgress);
        },
      );
    });

    group('toProjectPreserving status', () {
      test(
        'promotes a 作成中 draft to 実施中 when 最初の一歩 is decided',
        () {
          final existing = Project(
            theme: 'テーマ',
            status: ProjectStatus.preparing,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          );
          final state = WizardState(
            sessionId: existing.id,
            theme: 'テーマ',
            decidedStrategy: '決めた方策',
            decidedFirstStep: '決めた最初の一歩',
          );
          expect(
            state.toProjectPreserving(existing).status,
            ProjectStatus.inProgress,
          );
        },
      );

      test(
        'keeps a dashboard 現況 (休憩中 / 完了) instead of resetting it',
        () {
          final existing = Project(
            theme: 'テーマ',
            status: ProjectStatus.onBreak,
            decidedFirstStep: '既存の一歩',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          );
          final state = WizardState(
            sessionId: existing.id,
            theme: 'テーマ',
            decidedFirstStep: '書き直した一歩',
          );
          expect(
            state.toProjectPreserving(existing).status,
            ProjectStatus.onBreak,
          );
        },
      );

      test(
        'keeps an existing SWOT when the wizard draft has an empty matrix',
        () {
          final existing = Project(
            theme: 'テーマ',
            desiredGoal: 'ゴール',
            matrix: SwotMatrix(
              strengths: [
                SwotItem(
                  category: SwotCategory.strength,
                  content: '残すべき強み',
                ),
              ],
            ),
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          );
          // Theme+goal only — toSwotMatrix() would be empty.
          final state = WizardState(
            sessionId: existing.id,
            theme: 'テーマ',
            desiredGoal: 'ゴール',
          );
          final preserved = state.toProjectPreserving(existing);
          expect(preserved.matrix.strengths.single.content, '残すべき強み');
        },
      );
    });

    test('reuses the same sessionId across repeated calls', () {
      final state = WizardState(theme: 'テーマ');
      expect(state.toProject().id, state.toProject().id);
    });
  });

  group('WizardState.fromProject', () {
    test('round-trips a fully classified project via toProject/fromProject', () {
      final original = WizardState(
        theme: 'テーマ',
        desiredGoal: '在りたい姿',
        undesiredGoal: '在りたくない姿',
        ideas: [
          WizardIdea(
            text: '強みのアイデア',
            evaluation: EvaluationAxis.positive,
            locus: LocusAxis.internal,
          ),
          WizardIdea(
            text: '脅威のアイデア',
            evaluation: EvaluationAxis.negative,
            locus: LocusAxis.external,
          ),
        ],
        decidedStrategy: '決めた方策',
        decidedFirstStep: '決めた最初の一歩',
        declaration: '宣言文',
      );
      final project = original.toProject();

      final resumed = WizardState.fromProject(project);

      expect(resumed.sessionId, project.id);
      expect(resumed.theme, 'テーマ');
      expect(resumed.desiredGoal, '在りたい姿');
      expect(resumed.undesiredGoal, '在りたくない姿');
      expect(resumed.decidedStrategy, '決めた方策');
      expect(resumed.decidedFirstStep, '決めた最初の一歩');
      expect(resumed.declaration, '宣言文');
      expect(resumed.isClassificationComplete, isTrue);
      expect(resumed.step, WizardStep.classification);
      expect(resumed.ideas.map((i) => i.text), [
        '強みのアイデア',
        '脅威のアイデア',
      ]);
      expect(resumed.ideas[0].evaluation, EvaluationAxis.positive);
      expect(resumed.ideas[0].locus, LocusAxis.internal);
      expect(resumed.ideas[1].evaluation, EvaluationAxis.negative);
      expect(resumed.ideas[1].locus, LocusAxis.external);
    });

    test('reconstructs a still-unclassified idea alongside a classified one', () {
      final original = WizardState(
        theme: 'テーマ',
        desiredGoal: '在りたい姿',
        ideas: [
          WizardIdea(
            text: '分類済み',
            evaluation: EvaluationAxis.positive,
            locus: LocusAxis.internal,
          ),
          WizardIdea(text: '未分類のまま'),
        ],
      );
      final project = original.toProject();

      final resumed = WizardState.fromProject(project);

      expect(resumed.isClassificationComplete, isFalse);
      expect(resumed.ideas.map((i) => i.text), ['分類済み', '未分類のまま']);
      expect(resumed.ideas[1].isClassified, isFalse);
      expect(resumed.step, WizardStep.classification);
    });

    test(
      'falls back to the matrix when situationNotes is empty (legacy data)',
      () {
        final now = DateTime.utc(2026, 1, 1);
        final project = Project(
          createdAt: now,
          updatedAt: now,
          theme: 'テーマ',
          desiredGoal: '在りたい姿',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: '強み1'),
            ],
          ),
        );

        final resumed = WizardState.fromProject(project);

        expect(resumed.ideas.single.text, '強み1');
        expect(resumed.ideas.single.evaluation, EvaluationAxis.positive);
        expect(resumed.ideas.single.locus, LocusAxis.internal);
        expect(resumed.isClassificationComplete, isTrue);
      },
    );

    test('lands on the theme step when theme is blank', () {
      final now = DateTime.utc(2026, 1, 1);
      final project = Project(createdAt: now, updatedAt: now, theme: '');
      expect(WizardState.fromProject(project).step, WizardStep.theme);
    });

    test('lands on the goal step when only theme is set', () {
      final now = DateTime.utc(2026, 1, 1);
      final project = Project(createdAt: now, updatedAt: now, theme: 'テーマ');
      expect(WizardState.fromProject(project).step, WizardStep.goal);
    });

    test('lands on the idea-dump step when theme and goal are set but no ideas', () {
      final now = DateTime.utc(2026, 1, 1);
      final project = Project(
        createdAt: now,
        updatedAt: now,
        theme: 'テーマ',
        desiredGoal: '在りたい姿',
      );
      expect(WizardState.fromProject(project).step, WizardStep.ideaDump);
    });
  });
}
