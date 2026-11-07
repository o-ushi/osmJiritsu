import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One line in 簡易モード's 現状 / 方策 / 最初の一歩 boxes.
///
/// Deliberately thinner than [SituationNote] / [SwotItem]: 簡易モード never
/// feeds the full wizard's SWOT or `decidedStrategy`, so its rows carry only
/// what its own board shows — the text, and whether it's been ticked off.
/// 現状 rows keep [done] in JSON (so nothing is lost if a row is ever moved
/// between boxes) but the 現状 box never renders a checkbox.
class SimpleLine {
  final String id;
  final String text;
  final bool done;

  SimpleLine({String? id, this.text = '', this.done = false})
    : id = id ?? _uuid.v4();

  SimpleLine copyWith({String? text, bool? done}) =>
      SimpleLine(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  /// Type-tested rather than cast: a row is the smallest unit here, so a
  /// `done` that arrived as `"true"` should cost that row its checkbox, not
  /// throw away the whole 案件 it belongs to.
  factory SimpleLine.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawText = json['text'];
    final rawDone = json['done'];
    return SimpleLine(
      id: rawId is String ? rawId : null,
      text: rawText is String ? rawText : '',
      done: rawDone is bool ? rawDone : false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SimpleLine &&
      other.id == id &&
      other.text == text &&
      other.done == done;

  @override
  int get hashCode => Object.hash(id, text, done);
}
