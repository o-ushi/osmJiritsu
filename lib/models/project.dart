import 'package:uuid/uuid.dart';

import 'decided_items.dart';
import 'first_step_suggestion.dart';
import 'jiritsu_check.dart';
import 'project_status.dart';
import 'reflection_entry.dart';
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
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Milestone-based 進捗率, 0.0–1.0 (a computed getter rather than a
  /// stored field, precisely so it can't drift out of sync with the data
  /// it's derived from).
  ///
  /// Rule (v3 — milestone ladder):
  /// - [ProjectStatus.completed] → 100%
  /// - Otherwise the highest achieved stage wins:
  ///   10% テーマ, 20% ゴール, 30% 今の状況（SWOTマトリクス）, 40% 方策,
  ///   50% 最初の一歩, 60% 宣言文, 70–90% by 振り返り count (1/2/3+).
  ///   See HELP →「進捗度の見方」for the full table.
  double get progressRatio {
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
    );
  }
}
