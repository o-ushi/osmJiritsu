import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One freeform note captured while "壁打ち"ing (thinking out loud through)
/// the current situation.
///
/// [Project.situationNotes] is the persistence form of the wizard's idea-dump
/// list (`WizardState.ideas` ↔ [WizardState.toSituationNotes]). Shown
/// read-only on the dashboard as「壁打ちメモ」; free-form 備考 (`Project.note`)
/// is a separate field for ongoing implementation notes.
class SituationNote {
  final String id;
  final String content;
  final DateTime createdAt;

  SituationNote({String? id, required this.content, DateTime? createdAt})
    : id = id ?? _uuid.v4(),
      createdAt = createdAt ?? DateTime.now();

  SituationNote copyWith({String? content}) {
    return SituationNote(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SituationNote.fromJson(Map<String, dynamic> json) => SituationNote(
    id: json['id'] as String?,
    content: json['content'] as String? ?? '',
    createdAt: json['createdAt'] is String
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );

  @override
  bool operator ==(Object other) =>
      other is SituationNote &&
      other.id == id &&
      other.content == content &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, content, createdAt);
}
