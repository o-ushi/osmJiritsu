import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/jiritsu_check.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/reflection_entry.dart';
import 'package:osm_jiritsu/models/situation_note.dart';
import 'package:osm_jiritsu/models/strategy_suggestion.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';

void main() {
  group('Project JSON round trip', () {
    test('preserves every field through encode/decode', () {
      final createdAt = DateTime.utc(2026, 1, 1, 9, 0);
      final updatedAt = DateTime.utc(2026, 1, 2, 10, 30);
      final deadline = DateTime.utc(2026, 2, 1);

      final project = Project(
        theme: '新しいキャリアについて',
        desiredGoal: '納得感のある転職をしている',
        undesiredGoal: '妥協して転職している',
        situationNotes: [SituationNote(content: '今の職場について整理した')],
        matrix: SwotMatrix(
          strengths: [
            SwotItem(category: SwotCategory.strength, content: '高い技術力'),
          ],
        ),
        decidedStrategy: '強みを活かして転職エージェントに登録する',
        aiStrategySuggestions: [
          StrategySuggestion(
            text: 'AI提案の方策',
            rationale: '応募先をリストアップする',
          ),
        ],
        jiritsuCheck: const JiritsuCheck(
          selfDetermined: true,
          clearOutcome: true,
        ),
        decidedFirstStep: '転職エージェントに登録する',
        declaration: '私は納得感のある転職を目指しています。まずは転職エージェントに登録します。',
        createdAt: createdAt,
        updatedAt: updatedAt,
        deadline: deadline,
        note: '備考テキスト',
        status: ProjectStatus.inProgress,
        reflectionHistory: [
          ReflectionEntry(
            recordedAt: DateTime.utc(2026, 1, 10),
            howItWent: '順調だった',
            nextChoice: '次は面接対策をする',
          ),
        ],
        isFavorite: true,
      );

      final decoded = Project.fromJson(project.toJson());

      expect(decoded.id, project.id);
      expect(decoded.theme, project.theme);
      expect(decoded.desiredGoal, project.desiredGoal);
      expect(decoded.undesiredGoal, project.undesiredGoal);
      expect(decoded.situationNotes.single.content, '今の職場について整理した');
      expect(decoded.matrix.strengths.single.content, '高い技術力');
      expect(decoded.decidedStrategy, project.decidedStrategy);
      expect(decoded.aiStrategySuggestions.single.text, 'AI提案の方策');
      expect(decoded.jiritsuCheck.selfDetermined, isTrue);
      expect(decoded.jiritsuCheck.clearOutcome, isTrue);
      expect(decoded.jiritsuCheck.sharedGoal, isFalse);
      expect(decoded.decidedFirstStep, project.decidedFirstStep);
      expect(decoded.declaration, project.declaration);
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.deadline, deadline);
      expect(decoded.note, '備考テキスト');
      expect(decoded.status, ProjectStatus.inProgress);
      expect(decoded.reflectionHistory.single.howItWent, '順調だった');
      expect(decoded.isFavorite, isTrue);
    });

    test('defaults every optional field when absent', () {
      final decoded = Project.fromJson({
        'id': 'abc',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(decoded.theme, '');
      expect(decoded.desiredGoal, '');
      expect(decoded.undesiredGoal, '');
      expect(decoded.situationNotes, isEmpty);
      expect(decoded.matrix.isEmpty, isTrue);
      expect(decoded.decidedStrategy, '');
      expect(decoded.aiStrategySuggestions, isEmpty);
      expect(decoded.jiritsuCheck.satisfiedCount, 0);
      expect(decoded.decidedFirstStep, '');
      expect(decoded.declaration, '');
      expect(decoded.deadline, isNull);
      expect(decoded.note, '');
      expect(decoded.status, ProjectStatus.preparing);
      expect(decoded.reflectionHistory, isEmpty);
      expect(decoded.isFavorite, isFalse);
    });

    test('throws FormatException when createdAt/updatedAt are missing', () {
      expect(() => Project.fromJson({'id': 'abc'}), throwsFormatException);
    });
  });

  group('Project.shareSummary', () {
    test('formats the fixed Stage1 Step 11 label:value shape', () {
      final project = Project(
        theme: '新しいキャリアについて',
        desiredGoal: '納得感のある転職をしている',
        undesiredGoal: '妥協して転職している',
        decidedStrategy: '強みを活かして転職エージェントに登録する',
        decidedFirstStep: '転職エージェントに登録する',
        declaration: '私は納得感のある転職を目指しています。まずは転職エージェントに登録します。',
      );

      expect(project.shareSummary, '''
テーマ: 新しいキャリアについて
ゴール1️⃣（在りたい姿）: 納得感のある転職をしている
ゴール2️⃣（在りたくない姿）: 妥協して転職している
方策: 強みを活かして転職エージェントに登録する
最初の一歩: 転職エージェントに登録する

宣言文:
「私は納得感のある転職を目指しています。まずは転職エージェントに登録します。」'''
          .trim());
    });

    test('numbers multiple adopted 方策 / 最初の一歩 in the summary', () {
      final project = Project(
        theme: 'テーマ',
        desiredGoal: 'ゴール',
        decidedStrategy: '方策A\n方策B',
        decidedFirstStep: '一歩A\n一歩B',
        declaration: '宣言',
      );

      expect(
        project.shareSummary,
        contains('方策:\n方策 1\n方策A\n\n方策 2\n方策B'),
      );
      expect(
        project.shareSummary,
        contains('最初の一歩:\n最初の一歩 1\n一歩A\n\n最初の一歩 2\n一歩B'),
      );
    });
  });

  group('Project.dashboardShareSummary', () {
    test('includes every field visible on the dashboard', () {
      final createdAt = DateTime(2026, 1, 1, 9, 30);
      final updatedAt = DateTime(2026, 1, 2, 10, 15);
      final deadline = DateTime(2026, 2, 1);
      final recordedAt = DateTime(2026, 1, 5, 15, 45);

      final project = Project(
        theme: '新しいキャリアについて',
        desiredGoal: '納得感のある転職をしている',
        undesiredGoal: '妥協して転職している',
        decidedStrategy: '強みを活かして転職エージェントに登録する',
        decidedFirstStep: '転職エージェントに登録する',
        declaration: '私は納得感のある転職を目指しています。まずは転職エージェントに登録します。',
        createdAt: createdAt,
        updatedAt: updatedAt,
        deadline: deadline,
        note: 'メモの内容',
        status: ProjectStatus.inProgress,
        jiritsuCheck: const JiritsuCheck(
          selfDetermined: true,
          clearOutcome: true,
          sharedGoal: false,
        ),
        matrix: SwotMatrix(
          strengths: [
            SwotItem(category: SwotCategory.strength, content: '強みA'),
          ],
          opportunities: [
            SwotItem(category: SwotCategory.opportunity, content: '機会B'),
          ],
        ),
        reflectionHistory: [
          ReflectionEntry(
            recordedAt: recordedAt,
            howItWent: '思ったより進んだ',
            nextChoice: '続ける',
          ),
        ],
      );

      final summary = project.dashboardShareSummary;
      expect(summary, contains('テーマ: 新しいキャリアについて'));
      expect(summary, contains('現況: 実施中'));
      expect(summary, contains('進捗度: 70%'));
      expect(summary, contains('振り返り回数: 1回'));
      expect(summary, contains('登録日: 2026/01/01 09:30'));
      expect(summary, contains('最終更新日: 2026/01/02 10:15'));
      expect(summary, contains('ゴール1️⃣（在りたい姿）: 納得感のある転職をしている'));
      expect(summary, contains('【今の状況（SWOT）】'));
      expect(summary, contains('  ・強みA'));
      expect(summary, contains('  ・機会B'));
      expect(summary, contains('  （なし）'));
      expect(summary, contains('方策: 強みを活かして転職エージェントに登録する'));
      expect(summary, contains('最初の一歩: 転職エージェントに登録する'));
      expect(summary, contains('自律度チェック: 2 / 3'));
      expect(summary, contains('期限: 2026/02/01'));
      expect(summary, contains('備考: メモの内容'));
      expect(summary, contains('【振り返り履歴】'));
      expect(summary, contains('2026/01/05 15:45 — 続ける'));
      expect(summary, contains('思ったより進んだ'));
    });
  });

  group('Project.suggestedDeclaration', () {
    test('is empty until both desiredGoal and decidedFirstStep are set', () {
      final project = Project(theme: 'テーマ');
      expect(project.suggestedDeclaration, '');

      final withGoalOnly = project.copyWith(desiredGoal: '在りたい姿');
      expect(withGoalOnly.suggestedDeclaration, '');
    });

    test('fills the fixed template once both halves are present', () {
      final project = Project(
        theme: 'テーマ',
        desiredGoal: '納得感のある転職をしている',
        decidedFirstStep: '転職エージェントに登録する',
      );

      expect(
        project.suggestedDeclaration,
        '私は納得感のある転職をしているを目指しています。まずは転職エージェントに登録するを実践します。',
      );
    });
  });

  group('Project.progressRatio', () {
    test('is always 1.0 once status is completed', () {
      final project = Project(
        theme: 'テーマ',
        status: ProjectStatus.completed,
      );
      expect(project.progressRatio, 1.0);
    });

    test('follows the milestone ladder from theme through reflections', () {
      Project atStage({
        String theme = '',
        String desiredGoal = '',
        String undesiredGoal = '',
        SwotMatrix matrix = const SwotMatrix(),
        String decidedStrategy = '',
        String decidedFirstStep = '',
        String declaration = '',
        int reflectionCount = 0,
      }) => Project(
        theme: theme,
        desiredGoal: desiredGoal,
        undesiredGoal: undesiredGoal,
        matrix: matrix,
        decidedStrategy: decidedStrategy,
        decidedFirstStep: decidedFirstStep,
        declaration: declaration,
        reflectionHistory: List.generate(
          reflectionCount,
          (_) => ReflectionEntry(howItWent: '進んだ', nextChoice: '次'),
        ),
      );

      expect(atStage().progressRatio, 0.0);
      expect(atStage(theme: 'T').progressRatio, 0.1);
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
        ).progressRatio,
        0.2,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
        ).progressRatio,
        0.3,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
        ).progressRatio,
        0.4,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
          decidedFirstStep: '一歩',
        ).progressRatio,
        0.5,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
          decidedFirstStep: '一歩',
          declaration: '宣言',
        ).progressRatio,
        0.6,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
          decidedFirstStep: '一歩',
          declaration: '宣言',
          reflectionCount: 1,
        ).progressRatio,
        0.7,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
          decidedFirstStep: '一歩',
          declaration: '宣言',
          reflectionCount: 2,
        ).progressRatio,
        0.8,
      );
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
          decidedFirstStep: '一歩',
          declaration: '宣言',
          reflectionCount: 3,
        ).progressRatio,
        0.9,
      );
      // 3+ 振り返り all cap at 90% — only [ProjectStatus.completed] reaches
      // 100%.
      expect(
        atStage(
          theme: 'T',
          desiredGoal: 'G1',
          undesiredGoal: 'G2',
          matrix: SwotMatrix(
            strengths: [
              SwotItem(category: SwotCategory.strength, content: 'S'),
            ],
          ),
          decidedStrategy: '方策',
          decidedFirstStep: '一歩',
          declaration: '宣言',
          reflectionCount: 5,
        ).progressRatio,
        0.9,
      );
    });
  });

  group('Project.isDeadlineOverdue', () {
    test('false when deadline is unset', () {
      expect(Project(theme: 'T').isDeadlineOverdue, isFalse);
    });

    test('false when deadline is today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(
        Project(theme: 'T', deadline: today).isDeadlineOverdue,
        isFalse,
      );
    });

    test('false when deadline is in the future', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(
        const Duration(days: 1),
      );
      expect(
        Project(theme: 'T', deadline: tomorrow).isDeadlineOverdue,
        isFalse,
      );
    });

    test('true when deadline was yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 1),
      );
      expect(
        Project(theme: 'T', deadline: yesterday).isDeadlineOverdue,
        isTrue,
      );
    });
  });

  group('Project.copyWith discard flags', () {
    test(
      'clearDecidedStrategy resets it to empty without touching decidedFirstStep',
      () {
        final project = Project(
          theme: 'テーマ',
          decidedStrategy: '決めた方策',
          decidedFirstStep: '決めた最初の一歩',
        );

        final discarded = project.copyWith(clearDecidedStrategy: true);

        expect(discarded.decidedStrategy, '');
        expect(discarded.decidedFirstStep, '決めた最初の一歩');
      },
    );

    test(
      'clearDecidedFirstStep resets it to empty without touching decidedStrategy',
      () {
        final project = Project(
          theme: 'テーマ',
          decidedStrategy: '決めた方策',
          decidedFirstStep: '決めた最初の一歩',
        );

        final discarded = project.copyWith(clearDecidedFirstStep: true);

        expect(discarded.decidedFirstStep, '');
        expect(discarded.decidedStrategy, '決めた方策');
      },
    );
  });
}
