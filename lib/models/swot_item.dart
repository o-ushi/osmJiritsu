import 'package:uuid/uuid.dart';

import 'swot_category.dart';

const _uuid = Uuid();

/// A single SWOT entry, e.g. "強固な技術力" filed under [SwotCategory.strength].
///
/// Mirrors `SWOTItem` from osmSWOT/Models/SWOTItem.swift.
class SwotItem {
  final String id;
  final SwotCategory category;
  final String content;
  final DateTime createdAt;

  SwotItem({
    String? id,
    required this.category,
    required this.content,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  SwotItem copyWith({SwotCategory? category, String? content}) {
    return SwotItem(
      id: id,
      category: category ?? this.category,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.rawValue,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SwotItem.fromJson(Map<String, dynamic> json) {
    final category = SwotCategory.fromRawValue(json['category'] as String);
    if (category == null) {
      throw FormatException('Unknown SWOT category: ${json['category']}');
    }
    return SwotItem(
      id: json['id'] as String?,
      category: category,
      content: json['content'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SwotItem &&
      other.id == id &&
      other.category == category &&
      other.content == content &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, category, content, createdAt);
}
