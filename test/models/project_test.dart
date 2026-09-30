import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/jiritsu_check.dart';
import 'package:osm_jiritsu/models/project.dart';
import 'package:osm_jiritsu/models/project_status.dart';
import 'package:osm_jiritsu/models/reflection_entry.dart';
import 'package:osm_jiritsu/models/simple_line.dart';
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
      // 簡易モード fields left at their constructor defaults: a project
      // built without them is a full-mode one with an empty board.
      expect(decoded.entryMode, Project.modeFull);
      expect(decoded.simpleSituations, isEmpty);
      expect(decoded.simpleStrategies, isEmpty);
      expect(decoded.simpleFirstStep.text, '');
      expect(decoded.simpleFirstStep.done, isFalse);
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

  group('Project 簡易モード JSON', () {
    test('preserves all four boxes and their done flags', () {
      final project = Project(
        theme: '朝の習慣',
        desiredGoal: '朝の習慣',
        entryMode: Project.modeSimple,
        simpleGoalDone: true,
        simpleSituations: [
          SimpleLine(text: '夜ふかししている'),
          SimpleLine(text: '起きる時間がばらばら'),
        ],
        simpleStrategies: [
          SimpleLine(text: '寝る前にスマホを置く', done: true),
          SimpleLine(text: 'カーテンを開けて寝る'),
        ],
        simpleFirstStep: SimpleLine(text: '今夜23時に充電器へ置く', done: true),
      );

      final decoded = Project.fromJson(project.toJson());

      expect(decoded.entryMode, Project.modeSimple);
      expect(decoded.isSimpleMode, isTrue);
      expect(decoded.simpleGoalDone, isTrue);
      expect(
        decoded.simpleSituations.map((l) => l.text),
        ['夜ふかししている', '起きる時間がばらばら'],
      );
      expect(decoded.simpleStrategies.first.done, isTrue);
      expect(decoded.simpleStrategies.last.done, isFalse);
      expect(
        decoded.simpleStrategies.map((l) => l.id),
        project.simpleStrategies.map((l) => l.id),
      );
      expect(decoded.simpleFirstStep.text, '今夜23時に充電器へ置く');
      expect(decoded.simpleFirstStep.done, isTrue);
    });

    test('older JSON without entryMode reads back as full mode', () {
      final decoded = Project.fromJson({
        'id': 'abc',
        'theme': '昔からある案件',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(decoded.entryMode, Project.modeFull);
      expect(decoded.isSimpleMode, isFalse);
      expect(decoded.simpleGoalDone, isFalse);
      expect(decoded.simpleSituations, isEmpty);
      expect(decoded.simpleStrategies, isEmpty);
      expect(decoded.simpleFirstStep.text, '');
    });

    test('an unknown entryMode also reads back as full mode', () {
      final decoded = Project.fromJson({
        'id': 'abc',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'entryMode': 'someFutureMode',
      });

      expect(decoded.entryMode, Project.modeFull);
    });

    test('keeps only the first three 現状 / 方策 lines', () {
      final decoded = Project.fromJson({
        'id': 'abc',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'entryMode': 'simple',
        'simpleSituations': [
          {'text': '1'},
          {'text': '2'},
          {'text': '3'},
          {'text': '4'},
        ],
        'simpleStrategies': [
          {'text': 'A'},
          {'text': 'B'},
          {'text': 'C'},
          {'text': 'D'},
        ],
      });

      expect(decoded.simpleSituations.map((l) => l.text), ['1', '2', '3']);
      expect(decoded.simpleStrategies.map((l) => l.text), ['A', 'B', 'C']);
    });

    test('drops malformed list entries instead of throwing', () {
      final decoded = Project.fromJson({
        'id': 'abc',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'entryMode': 'simple',
        'simpleSituations': 'not a list',
        'simpleStrategies': [
          'not a map',
          {'text': '残る', 'done': 'not a bool'},
        ],
        'simpleFirstStep': 'not a map',
      });

      expect(decoded.simpleSituations, isEmpty);
      expect(decoded.simpleStrategies.single.text, '残る');
      expect(decoded.simpleStrategies.single.done, isFalse);
      expect(decoded.simpleFirstStep.text, '');
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
      expect(summary, contains('内発度チェック: 2 / 3'));
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

    test('簡易モード climbs its own eight-step ladder', () {
      Project simple({
        String desiredGoal = '',
        bool goalDone = false,
        List<SimpleLine> situations = const [],
        List<SimpleLine> strategies = const [],
        SimpleLine? firstStep,
      }) => Project(
        theme: desiredGoal,
        desiredGoal: desiredGoal,
        entryMode: Project.modeSimple,
        simpleGoalDone: goalDone,
        simpleSituations: situations,
        simpleStrategies: strategies,
        simpleFirstStep: firstStep,
      );

      expect(simple().progressRatio, 0.0);
      expect(simple(desiredGoal: 'ゴール').progressRatio, 0.1);
      expect(
        simple(
          desiredGoal: 'ゴール',
          situations: [SimpleLine(text: '現状')],
        ).progressRatio,
        0.2,
      );
      expect(
        simple(
          desiredGoal: 'ゴール',
          situations: [SimpleLine(text: '現状')],
          strategies: [SimpleLine(text: '方策')],
        ).progressRatio,
        0.4,
      );
      expect(
        simple(
          desiredGoal: 'ゴール',
          situations: [SimpleLine(text: '現状')],
          strategies: [SimpleLine(text: '方策')],
          firstStep: SimpleLine(text: '一歩'),
        ).progressRatio,
        0.5,
      );
      expect(
        simple(
          desiredGoal: 'ゴール',
          situations: [SimpleLine(text: '現状')],
          strategies: [SimpleLine(text: '方策')],
          firstStep: SimpleLine(text: '一歩', done: true),
        ).progressRatio,
        0.6,
      );
      expect(
        simple(
          desiredGoal: 'ゴール',
          strategies: [
            SimpleLine(text: '方策A', done: true),
            SimpleLine(text: '方策B'),
          ],
        ).progressRatio,
        0.7,
      );
      expect(
        simple(
          desiredGoal: 'ゴール',
          strategies: [
            SimpleLine(text: '方策A', done: true),
            SimpleLine(text: '方策B', done: true),
          ],
        ).progressRatio,
        0.9,
      );
      expect(
        simple(desiredGoal: 'ゴール', goalDone: true).progressRatio,
        1.0,
      );
      // Blank rows don't count as a filled box, whatever their checkbox says.
      expect(
        simple(
          desiredGoal: 'ゴール',
          situations: [SimpleLine(text: '  ')],
        ).progressRatio,
        0.1,
      );
    });

    test('a checked but empty 方策 row doesn\'t count as 実施済み', () {
      final project = Project(
        theme: 'ゴール',
        desiredGoal: 'ゴール',
        entryMode: Project.modeSimple,
        simpleStrategies: [SimpleLine(text: '', done: true)],
      );
      // No filled 方策 at all, so this reads as ゴールのみ (10%), not 90%.
      expect(project.progressRatio, 0.1);
    });

    test('ゴール達成済み wins over every other checked box', () {
      final project = Project(
        theme: 'ゴール',
        desiredGoal: 'ゴール',
        entryMode: Project.modeSimple,
        simpleGoalDone: true,
        simpleStrategies: [SimpleLine(text: '方策')], // unticked
        simpleFirstStep: SimpleLine(text: '一歩'), // unticked
      );
      expect(project.progressRatio, 1.0);
    });

    test('a completed 簡易 project reads 100% even without simpleGoalDone', () {
      final project = Project(
        theme: 'ゴール',
        entryMode: Project.modeSimple,
        status: ProjectStatus.completed,
      );
      expect(project.progressRatio, 1.0);
    });

    test('a full-mode project keeps the milestone ladder', () {
      final full = Project(theme: 'T', desiredGoal: 'G1', undesiredGoal: 'G2');
      expect(full.entryMode, Project.modeFull);
      expect(full.progressRatio, 0.2);
    });
  });

  group('Project.shareSummary 簡易モード', () {
    test('prints the four boxes with （済） on ticked lines', () {
      final project = Project(
        theme: '朝の習慣を整える',
        desiredGoal: '朝の習慣を整える',
        entryMode: Project.modeSimple,
        simpleSituations: [SimpleLine(text: '夜ふかししている')],
        simpleStrategies: [
          SimpleLine(text: '寝る前にスマホを置く', done: true),
          SimpleLine(text: 'カーテンを開けて寝る'),
        ],
        simpleFirstStep: SimpleLine(text: '今夜23時に充電器へ置く', done: true),
      );

      expect(project.shareSummary, '''
ゴール: 朝の習慣を整える
現状: 夜ふかししている
方策:
  ・寝る前にスマホを置く（済）
  ・カーテンを開けて寝る
最初の一歩: 今夜23時に充電器へ置く（済）''');
      // The dashboard share of a 簡易 project is the same four boxes — no
      // SWOT block, no 内発度チェック line.
      expect(project.dashboardShareSummary, project.shareSummary);
      expect(project.shareSummary, isNot(contains('SWOT')));
      expect(project.shareSummary, isNot(contains('内発度チェック')));
    });

    test('empty boxes print （なし）', () {
      final project = Project(theme: '', entryMode: Project.modeSimple);

      expect(project.shareSummary, '''
ゴール: （なし）
現状: （なし）
方策: （なし）
最初の一歩: （なし）''');
    });

    test('a checked ゴール gets its own （済）', () {
      final project = Project(
        theme: '朝の習慣を整える',
        desiredGoal: '朝の習慣を整える',
        entryMode: Project.modeSimple,
        simpleGoalDone: true,
      );

      expect(
        project.shareSummary,
        startsWith('ゴール: 朝の習慣を整える（済）'),
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
