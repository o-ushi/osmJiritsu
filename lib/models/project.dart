import 'package:uuid/uuid.dart';

import 'decided_items.dart';
import 'first_step_suggestion.dart';
import 'jiritsu_check.dart';
import 'project_status.dart';
import 'reflection_entry.dart';
import 'simple_line.dart';
import 'situation_note.dart';
import 'strategy_suggestion.dart';
import 'swot_item.dart';
import 'swot_matrix.dart';

const _uuid = Uuid();

/// One 案件 (project/engagement): everything from the theme that framed it
/// through to its 振り返り (retrospective) history.
///
/// ## Field-to-要素 mapping (why these fields, not others)
/// Every field here exists to make one of 内発的動機づけの3要素 concretely
/// checkable, rather than being free-floating data:
/// - `decidedStrategy` / `decidedFirstStep` are the user's *own* final
///   wording (never the raw AI suggestion) — "自分で決められるか？".
/// - `status` / `progressRatio` / `reflectionHistory` give a plain,
///   glanceable read on where things stand — "成果が分かりやすいか？".
/// - `declaration` is the one sentence meant to be shared with whoever
///   else is involved — "周りと繋がっているか？".
/// - `jiritsuCheck` is the user's own self-assessment against all three,
///   recorded directly (see Stage1 Steps 7-8's redefine loop) rather than
///   inferred from the other fields.
class Project {
  /// Bumped whenever [toJson]'s shape changes in a way old readers can't
  /// tolerate. [fromJson] doesn't currently gate on it (every field is
  /// read tolerantly) — captured up front for the same reason
  /// `AnalysisExportService.projectFormatVersion` is, so the very first
  /// version doesn't have to retrofit one in later.
  static const int schemaVersion = 1;

  /// [entryMode] values. Anything else read from JSON degrades to
  /// [modeFull], so a record written by a newer build can still be opened.
  static const String modeFull = 'full';
  static const String modeSimple = 'simple';

  /// 最大3件 — 現状 / 方策 both cap here, matching 簡易モード's board.
  static const int simpleLineLimit = 3;

  final String id;

  /// テーマ
  final String theme;

  /// ゴール1: 在りたい姿 — the "sufficient condition" case for the goal:
  /// reaching this state is, by itself, enough to call it achieved.
  final String desiredGoal;

  /// ゴール2: 在りたくない姿 — the "necessary condition" case: avoiding
  /// this state is a precondition the goal must satisfy, even if it's not
  /// sufficient on its own.
  final String undesiredGoal;

  /// 現状メモ（壁打ちテキスト群）
  final List<SituationNote> situationNotes;

  /// SWOT
  final SwotMatrix matrix;

  /// 方策 — the user's own final wording, distinct from anything AI
  /// suggested (see [aiStrategySuggestions]). Composed in Stage1 Steps 6/8's
  /// decide/redefine loop: adopted from one AI suggestion, merged from
  /// several, or written from scratch — this is whichever the user ends up
  /// settling on.
  final String decidedStrategy;

  /// AI提案方策一覧（参照用、任意） — the 5 [StrategySuggestion]s Stage1
  /// Step 5's Chrome-AI-Mode divergence produced, kept only for reference
  /// once [decidedStrategy] is chosen.
  final List<StrategySuggestion> aiStrategySuggestions;

  /// Stage1 Step 7's self-assessment of [decidedStrategy] against
  /// 内発的動機づけの3要素（内発度チェック） — re-evaluated every time
  /// Step 8 redefines the strategy,
  /// so this always reflects the *current* [decidedStrategy], not
  /// necessarily the one it was first checked against.
  final JiritsuCheck jiritsuCheck;

  /// 最初の一歩 — the user's own final wording of the first concrete step.
  final String decidedFirstStep;

  /// AI提案の最初の一歩一覧（参照用） — Stage1 Step 9's Chrome-AI-Mode
  /// suggestions, kept for later re-review from the dashboard.
  final List<FirstStepSuggestion> aiFirstStepSuggestions;

  /// 宣言文, e.g. "私は〇〇を目指しています。まずは△△を実践します".
  /// See [suggestedDeclaration] for the auto-filled starting point.
  final String declaration;

  /// 登録日
  final DateTime createdAt;

  /// 最終更新日
  final DateTime updatedAt;

  /// 期限 (optional — not every project has a hard deadline).
  final DateTime? deadline;

  /// 備考
  final String note;

  /// 現況
  final ProjectStatus status;

  /// 振り返り履歴
  final List<ReflectionEntry> reflectionHistory;

  /// 登録案件リストで⭐️をつけて目立たせるためのフラグ — 並び順には影響しない
  /// (見た目の強調のみ).
  final bool isFavorite;

  /// Which entry flow owns this 案件: [modeFull] (the wizard) or
  /// [modeSimple] (the four-box board). Projects saved before 簡易モード
  /// existed have no `entryMode` key at all and read back as [modeFull].
  final String entryMode;

  /// 簡易モード's ゴール checkbox — "ゴール達成済み" in [_simpleProgressRatio].
  /// The goal text itself still lives in [desiredGoal]/[theme] (shared with
  /// full mode); this is only the tick, so nothing about how full-mode
  /// projects read those two fields changes.
  final bool simpleGoalDone;

  /// 簡易モード's 現状 box — at most [simpleLineLimit] lines, no checkbox.
  /// Intentionally separate from [situationNotes]: the two are read at
  /// different places and merging them would make the full wizard's 壁打ち
  /// wall appear inside 簡易モード.
  final List<SimpleLine> simpleSituations;

  /// 簡易モード's 方策 box — at most [simpleLineLimit] lines, each tickable.
  /// Never flows into [decidedStrategy].
  final List<SimpleLine> simpleStrategies;

  /// 簡易モード's 最初の一歩 — always exactly one line (never null), so the
  /// model matches the single box the screen draws.
  final SimpleLine simpleFirstStep;

  Project({
    String? id,
    required this.theme,
    this.desiredGoal = '',
    this.undesiredGoal = '',
    this.situationNotes = const [],
    this.matrix = const SwotMatrix(),
    this.decidedStrategy = '',
    this.aiStrategySuggestions = const [],
    this.jiritsuCheck = JiritsuCheck.none,
    this.decidedFirstStep = '',
    this.aiFirstStepSuggestions = const [],
    this.declaration = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deadline,
    this.note = '',
    this.status = ProjectStatus.preparing,
    this.reflectionHistory = const [],
    this.isFavorite = false,
    this.entryMode = modeFull,
    this.simpleGoalDone = false,
    this.simpleSituations = const [],
    this.simpleStrategies = const [],
    SimpleLine? simpleFirstStep,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       // Never null: the screen draws exactly one 最初の一歩 box whether or
       // not anything's been typed into it yet.
       simpleFirstStep = simpleFirstStep ?? SimpleLine();

  /// Milestone-based 進捗率, 0.0–1.0 (a computed getter rather than a
  /// stored field, precisely so it can't drift out of sync with the data
  /// it's derived from). [isSimpleMode] picks which ladder applies: full
  /// mode's own milestones, below, or [_simpleProgressRatio].
  ///
  /// Full-mode rule (v3 — milestone ladder):
  /// - [ProjectStatus.completed] → 100%
  /// - Otherwise the highest achieved stage wins:
  ///   10% テーマ, 20% ゴール, 30% 今の状況（SWOTマトリクス）, 40% 方策,
  ///   50% 最初の一歩, 60% 宣言文, 70–90% by 振り返り count (1/2/3+).
  ///   See HELP →「進捗度の見方」for the full table.
  /// True for a 簡易モード 案件 — [entryMode] is authoritative, so an older
  /// record that simply lacks the key is always read as full.
  bool get isSimpleMode => entryMode == modeSimple;

  double get progressRatio {
    if (isSimpleMode) return _simpleProgressRatio;
    if (status == ProjectStatus.completed) return 1.0;

    final reflectionCount = reflectionHistory.length;
    if (reflectionCount >= 3) return 0.9;
    if (reflectionCount >= 2) return 0.8;
    if (reflectionCount >= 1) return 0.7;
    if (declaration.trim().isNotEmpty) return 0.6;
    if (decidedFirstStep.trim().isNotEmpty) return 0.5;
    if (decidedStrategy.trim().isNotEmpty) return 0.4;
    if (matrix.isNotEmpty) return 0.3;
    if (desiredGoal.trim().isNotEmpty && undesiredGoal.trim().isNotEmpty) {
      return 0.2;
    }
    if (theme.trim().isNotEmpty) return 0.1;
    return 0.0;
  }

  /// 簡易モード's own ladder — every checkbox now counts (an earlier version
  /// of this getter ignored them entirely). The highest satisfied stage
  /// wins, checked top-down, so e.g. one ticked 方策 reads 70% even if
  /// 最初の一歩 was never filled in.
  ///
  ///   10% ゴールが記入済み       40% 方策が記入済み        70% 方策が1つ実施済み
  ///   20% 現状が記入済み         50% 最初の一歩が記入済み   90% 方策が全て実施済み
  ///                              60% 最初の一歩が実施済み  100% ゴール達成済み
  ///
  /// [status] == [ProjectStatus.completed] also reads 100% — this feature
  /// doesn't set that itself, but a project completed some other way
  /// should never show less than full.
  double get _simpleProgressRatio {
    if (simpleGoalDone || status == ProjectStatus.completed) return 1.0;

    final filledStrategies = simpleStrategies
        .where((line) => line.text.trim().isNotEmpty)
        .toList();
    final allStrategiesDone =
        filledStrategies.isNotEmpty &&
        filledStrategies.every((line) => line.done);
    final anyStrategyDone = filledStrategies.any((line) => line.done);
    final firstStepFilled = simpleFirstStep.text.trim().isNotEmpty;
    final firstStepDone = firstStepFilled && simpleFirstStep.done;

    if (allStrategiesDone) return 0.9;
    if (anyStrategyDone) return 0.7;
    if (firstStepDone) return 0.6;
    if (firstStepFilled) return 0.5;
    if (filledStrategies.isNotEmpty) return 0.4;
    if (_hasSimpleText(simpleSituations)) return 0.2;
    if (desiredGoal.trim().isNotEmpty) return 0.1;
    return 0.0;
  }

  static bool _hasSimpleText(List<SimpleLine> lines) =>
      lines.any((line) => line.text.trim().isNotEmpty);

  /// True when [deadline] is set and its calendar day (local) is strictly
  /// before today — i.e. the due date has already ended. Same-day deadlines
  /// are not overdue yet.
  bool get isDeadlineOverdue {
    final due = deadline;
    if (due == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  /// Auto-generated starting point for [declaration], in the fixed
  /// "私は〇〇を目指しています。まずは△△を実践します" shape. Returns an
  /// empty string until both [desiredGoal] and [decidedFirstStep] are
  /// filled in, since the sentence doesn't mean anything with either half
  /// missing.
  String get suggestedDeclaration {
    if (desiredGoal.trim().isEmpty || decidedFirstStep.trim().isEmpty) {
      return '';
    }
    return '私は${desiredGoal.trim()}を目指しています。'
        'まずは${decidedFirstStep.trim()}を実践します。';
  }

  /// Stage1 Step 11's plain-text export: a fixed label:value summary
  /// (theme/goals/strategy/first step, then the 宣言文) meant to be sent
  /// to a boss or teammate as-is — a lightweight "here's my plan" note,
  /// not prose, so nothing here needs the reader to already know
  /// osmJiritsu's vocabulary beyond the labels themselves.
  String get shareSummary {
    if (isSimpleMode) return _simpleShareSummary;
    final buffer = StringBuffer()
      ..writeln('テーマ: $theme')
      ..writeln('ゴール1️⃣（在りたい姿）: $desiredGoal')
      ..writeln('ゴール2️⃣（在りたくない姿）: $undesiredGoal');
    _writeShareDecided(buffer, '方策', decidedStrategy);
    _writeShareDecided(buffer, '最初の一歩', decidedFirstStep);
    buffer
      ..writeln()
      ..writeln('宣言文:')
      ..writeln('「$declaration」');
    return buffer.toString().trim();
  }

  /// Full plain-text dump of everything shown on the project dashboard —
  /// used when sharing from [ProjectBottomToolbar] (dashboard and its
  /// child screens). [shareSummary] stays the shorter Stage1 Step 11 shape
  /// for the dedicated export screen.
  String get dashboardShareSummary {
    if (isSimpleMode) return _simpleShareSummary;
    final buffer = StringBuffer()
      ..writeln('テーマ: $theme')
      ..writeln('現況: ${status.displayName}')
      ..writeln('進捗度: ${(progressRatio * 100).round()}%')
      ..writeln('振り返り回数: ${reflectionHistory.length}回')
      ..writeln('登録日: ${_shareDateTime(createdAt)}')
      ..writeln('最終更新日: ${_shareDateTime(updatedAt)}');

    if (desiredGoal.trim().isNotEmpty) {
      buffer.writeln('ゴール1️⃣（在りたい姿）: $desiredGoal');
    }
    if (undesiredGoal.trim().isNotEmpty) {
      buffer.writeln('ゴール2️⃣（在りたくない姿）: $undesiredGoal');
    }

    buffer.writeln();
    buffer.writeln('【今の状況（SWOT）】');
    _writeShareQuadrant(buffer, '強み', matrix.strengths);
    _writeShareQuadrant(buffer, '機会', matrix.opportunities);
    _writeShareQuadrant(buffer, '弱み', matrix.weaknesses);
    _writeShareQuadrant(buffer, '脅威', matrix.threats);

    if (decidedStrategy.trim().isNotEmpty) {
      buffer.writeln();
      _writeShareDecided(buffer, '方策', decidedStrategy);
    }
    if (decidedFirstStep.trim().isNotEmpty) {
      _writeShareDecided(buffer, '最初の一歩', decidedFirstStep);
    }
    if (declaration.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('宣言文:');
      buffer.writeln('「$declaration」');
    }
    if (decidedStrategy.trim().isNotEmpty) {
      buffer.writeln(
        '内発度チェック: ${jiritsuCheck.satisfiedCount} / 3',
      );
    }

    buffer
      ..writeln()
      ..writeln('期限: ${deadline == null ? '未設定' : _shareDate(deadline!)}')
      ..writeln('備考: ${note.trim().isEmpty ? '（なし）' : note.trim()}');

    if (reflectionHistory.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【振り返り履歴】');
      for (final entry in reflectionHistory.reversed) {
        buffer
          ..writeln('${_shareDateTime(entry.recordedAt)} — ${entry.nextChoice}')
          ..writeln(entry.howItWent)
          ..writeln();
      }
    }

    return buffer.toString().trim();
  }

  /// 簡易モード's share text — the same four boxes the board shows, nothing
  /// else. No SWOT block and no 内発度チェック line: neither is ever filled
  /// in from this mode, so printing them would only read as「（なし）」noise.
  String get _simpleShareSummary {
    final goal = desiredGoal.trim();
    final goalLine = goal.isEmpty
        ? '（なし）'
        : (simpleGoalDone ? '$goal（済）' : goal);
    final buffer = StringBuffer()..writeln('ゴール: $goalLine');
    _writeSimpleLines(buffer, '現状', simpleSituations, showDone: false);
    _writeSimpleLines(buffer, '方策', simpleStrategies, showDone: true);
    _writeSimpleLines(
      buffer,
      '最初の一歩',
      [simpleFirstStep],
      showDone: true,
    );
    return buffer.toString().trim();
  }

  /// One line stays `方策: …`; several become a bulleted block, matching
  /// [_writeShareQuadrant]'s shape. Empty text is skipped entirely so a
  /// never-filled box prints as「（なし）」rather than a blank bullet.
  static void _writeSimpleLines(
    StringBuffer buffer,
    String label,
    List<SimpleLine> lines, {
    required bool showDone,
  }) {
    String render(SimpleLine line) =>
        showDone && line.done ? '${line.text.trim()}（済）' : line.text.trim();

    final filled = lines
        .where((line) => line.text.trim().isNotEmpty)
        .toList();
    if (filled.isEmpty) {
      buffer.writeln('$label: （なし）');
      return;
    }
    if (filled.length == 1) {
      buffer.writeln('$label: ${render(filled.single)}');
      return;
    }
    buffer.writeln('$label:');
    for (final line in filled) {
      buffer.writeln('  ・${render(line)}');
    }
  }

  static String _shareDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _shareDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static void _writeShareQuadrant(
    StringBuffer buffer,
    String label,
    List<SwotItem> items,
  ) {
    buffer.writeln('$label:');
    if (items.isEmpty) {
      buffer.writeln('  （なし）');
      return;
    }
    for (final item in items) {
      buffer.writeln('  ・${item.content}');
    }
  }

  /// One item stays `方策: …`; multiple items get numbered blocks so a
  /// shared wall of adopted suggestions stays scannable.
  static void _writeShareDecided(
    StringBuffer buffer,
    String label,
    String value,
  ) {
    final items = splitDecidedItems(value);
    if (items.length <= 1) {
      buffer.writeln('$label: ${value.trim()}');
      return;
    }
    buffer.writeln('$label:');
    buffer.writeln(formatDecidedItemsPlain(value, label));
  }

  Project copyWith({
    String? theme,
    String? desiredGoal,
    String? undesiredGoal,
    List<SituationNote>? situationNotes,
    SwotMatrix? matrix,
    String? decidedStrategy,
    bool clearDecidedStrategy = false,
    List<StrategySuggestion>? aiStrategySuggestions,
    JiritsuCheck? jiritsuCheck,
    String? decidedFirstStep,
    bool clearDecidedFirstStep = false,
    List<FirstStepSuggestion>? aiFirstStepSuggestions,
    String? declaration,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    bool clearDeadline = false,
    String? note,
    ProjectStatus? status,
    List<ReflectionEntry>? reflectionHistory,
    bool? isFavorite,
    String? entryMode,
    bool? simpleGoalDone,
    List<SimpleLine>? simpleSituations,
    List<SimpleLine>? simpleStrategies,
    SimpleLine? simpleFirstStep,
  }) {
    return Project(
      id: id,
      theme: theme ?? this.theme,
      desiredGoal: desiredGoal ?? this.desiredGoal,
      undesiredGoal: undesiredGoal ?? this.undesiredGoal,
      situationNotes: situationNotes ?? this.situationNotes,
      matrix: matrix ?? this.matrix,
      // `?? this.decidedStrategy` alone could never clear an already-decided
      // strategy back to '' (`null ?? x` just evaluates to `x`), so
      // discarding it needs its own explicit flag — same shape as
      // `clearDeadline` below.
      decidedStrategy: clearDecidedStrategy
          ? ''
          : (decidedStrategy ?? this.decidedStrategy),
      aiStrategySuggestions:
          aiStrategySuggestions ?? this.aiStrategySuggestions,
      jiritsuCheck: jiritsuCheck ?? this.jiritsuCheck,
      decidedFirstStep: clearDecidedFirstStep
          ? ''
          : (decidedFirstStep ?? this.decidedFirstStep),
      aiFirstStepSuggestions:
          aiFirstStepSuggestions ?? this.aiFirstStepSuggestions,
      declaration: declaration ?? this.declaration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // `?? this.deadline` alone could never clear an already-set deadline
      // back to null (`null ?? x` just evaluates to `x`), so clearing it
      // needs its own explicit flag rather than overloading `deadline`.
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      note: note ?? this.note,
      status: status ?? this.status,
      reflectionHistory: reflectionHistory ?? this.reflectionHistory,
      isFavorite: isFavorite ?? this.isFavorite,
      entryMode: entryMode ?? this.entryMode,
      simpleGoalDone: simpleGoalDone ?? this.simpleGoalDone,
      simpleSituations: simpleSituations ?? this.simpleSituations,
      simpleStrategies: simpleStrategies ?? this.simpleStrategies,
      simpleFirstStep: simpleFirstStep ?? this.simpleFirstStep,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'theme': theme,
    'desiredGoal': desiredGoal,
    'undesiredGoal': undesiredGoal,
    'situationNotes': situationNotes.map((n) => n.toJson()).toList(),
    'matrix': matrix.toJson(),
    'decidedStrategy': decidedStrategy,
    'aiStrategySuggestions': aiStrategySuggestions
        .map((s) => s.toJson())
        .toList(),
    'jiritsuCheck': jiritsuCheck.toJson(),
    'decidedFirstStep': decidedFirstStep,
    'aiFirstStepSuggestions': aiFirstStepSuggestions
        .map((s) => s.toJson())
        .toList(),
    'declaration': declaration,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'note': note,
    'status': status.rawValue,
    'reflectionHistory': reflectionHistory.map((r) => r.toJson()).toList(),
    'isFavorite': isFavorite,
    'entryMode': entryMode,
    'simpleGoalDone': simpleGoalDone,
    'simpleSituations': simpleSituations.map((l) => l.toJson()).toList(),
    'simpleStrategies': simpleStrategies.map((l) => l.toJson()).toList(),
    'simpleFirstStep': simpleFirstStep.toJson(),
  };

  /// Tolerant decoder: `id`/`createdAt`/`updatedAt` are the only
  /// load-bearing fields (thrown
  /// on if missing/malformed) since without them there's no stable
  /// identity to save/merge on; everything else degrades to a safe
  /// default so one damaged field doesn't lose the whole record.
  factory Project.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'];
    final rawUpdatedAt = json['updatedAt'];
    if (rawCreatedAt is! String || rawUpdatedAt is! String) {
      throw const FormatException(
        'Invalid project: missing "createdAt"/"updatedAt".',
      );
    }

    final rawMatrix = json['matrix'];
    final rawSituationNotes = json['situationNotes'];
    final rawAiStrategySuggestions = json['aiStrategySuggestions'];
    final rawJiritsuCheck = json['jiritsuCheck'];
    final rawAiFirstStepSuggestions = json['aiFirstStepSuggestions'];
    final rawReflectionHistory = json['reflectionHistory'];
    final rawDeadline = json['deadline'];
    final rawEntryMode = json['entryMode'];
    final rawSimpleFirstStep = json['simpleFirstStep'];

    return Project(
      id: json['id'] as String?,
      theme: json['theme'] as String? ?? '',
      desiredGoal: json['desiredGoal'] as String? ?? '',
      undesiredGoal: json['undesiredGoal'] as String? ?? '',
      situationNotes: rawSituationNotes is List
          ? rawSituationNotes
                .whereType<Map>()
                .map(
                  (raw) =>
                      SituationNote.fromJson(Map<String, dynamic>.from(raw)),
                )
                .toList()
          : const [],
      matrix: rawMatrix is Map
          ? SwotMatrix.fromJson(Map<String, dynamic>.from(rawMatrix))
          : const SwotMatrix(),
      decidedStrategy: json['decidedStrategy'] as String? ?? '',
      aiStrategySuggestions: rawAiStrategySuggestions is List
          ? rawAiStrategySuggestions
                .whereType<Map>()
                .map(
                  (raw) => StrategySuggestion.fromJson(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList()
          : const [],
      jiritsuCheck: rawJiritsuCheck is Map
          ? JiritsuCheck.fromJson(Map<String, dynamic>.from(rawJiritsuCheck))
          : JiritsuCheck.none,
      decidedFirstStep: json['decidedFirstStep'] as String? ?? '',
      aiFirstStepSuggestions: rawAiFirstStepSuggestions is List
          ? rawAiFirstStepSuggestions
                .whereType<Map>()
                .map(
                  (raw) => FirstStepSuggestion.fromJson(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList()
          : const [],
      declaration: json['declaration'] as String? ?? '',
      createdAt: DateTime.parse(rawCreatedAt),
      updatedAt: DateTime.parse(rawUpdatedAt),
      deadline: rawDeadline is String ? DateTime.parse(rawDeadline) : null,
      note: json['note'] as String? ?? '',
      status:
          ProjectStatus.fromRawValue(json['status'] as String? ?? '') ??
          ProjectStatus.preparing,
      reflectionHistory: rawReflectionHistory is List
          ? rawReflectionHistory
                .whereType<Map>()
                .map(
                  (raw) => ReflectionEntry.fromJson(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList()
          : const [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      // Only the one known non-default value opts in; anything else —
      // missing, misspelled, or written by a future build — is full, which
      // is the mode every pre-簡易モード record was saved in.
      entryMode: rawEntryMode == modeSimple ? modeSimple : modeFull,
      simpleGoalDone: json['simpleGoalDone'] as bool? ?? false,
      simpleSituations: _simpleLinesFromJson(json['simpleSituations']),
      simpleStrategies: _simpleLinesFromJson(json['simpleStrategies']),
      simpleFirstStep: rawSimpleFirstStep is Map
          ? SimpleLine.fromJson(Map<String, dynamic>.from(rawSimpleFirstStep))
          : null,
    );
  }

  /// Non-list input, and non-Map entries inside a list, are dropped rather
  /// than thrown on — same tolerance as every other list field here. The
  /// [simpleLineLimit] cap is applied on read too, so a hand-edited or
  /// imported file can't put a fourth row on a three-row board.
  static List<SimpleLine> _simpleLinesFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .take(simpleLineLimit)
        .map((entry) => SimpleLine.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
