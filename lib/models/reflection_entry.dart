import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One 振り返り (retrospective) entry: when it was recorded, how things
/// went, and what the next choice/action is.
///
/// [Project.reflectionHistory] is the running record of these — the app's
/// concrete evidence of a project being worked through step by step rather
/// than just declared and forgotten.
class ReflectionEntry {
  final String id;

  /// いつ
  final DateTime recordedAt;

  /// どうだった
  final String howItWent;

  /// 次の選択
  final String nextChoice;

  ReflectionEntry({
    String? id,
    DateTime? recordedAt,
    required this.howItWent,
    required this.nextChoice,
  }) : id = id ?? _uuid.v4(),
       recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'howItWent': howItWent,
    'nextChoice': nextChoice,
  };

  factory ReflectionEntry.fromJson(Map<String, dynamic> json) =>
      ReflectionEntry(
        id: json['id'] as String?,
        recordedAt: json['recordedAt'] is String
            ? DateTime.parse(json['recordedAt'] as String)
            : null,
        howItWent: json['howItWent'] as String? ?? '',
        nextChoice: json['nextChoice'] as String? ?? '',
      );

  ReflectionEntry copyWith({
    DateTime? recordedAt,
    String? howItWent,
    String? nextChoice,
  }) {
    return ReflectionEntry(
      id: id,
      recordedAt: recordedAt ?? this.recordedAt,
      howItWent: howItWent ?? this.howItWent,
      nextChoice: nextChoice ?? this.nextChoice,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReflectionEntry &&
      other.id == id &&
      other.recordedAt == recordedAt &&
      other.howItWent == howItWent &&
      other.nextChoice == nextChoice;

  @override
  int get hashCode => Object.hash(id, recordedAt, howItWent, nextChoice);
}
