import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/swot_category.dart';
import 'package:osm_jiritsu/models/swot_item.dart';
import 'package:osm_jiritsu/models/swot_matrix.dart';

void main() {
  group('SwotMatrix.fromJson', () {
    test('round-trips typed toJson maps', () {
      final original = SwotMatrix(
        strengths: [
          SwotItem(category: SwotCategory.strength, content: '高い技術力'),
        ],
        threats: [
          SwotItem(category: SwotCategory.threat, content: '競合が増えている'),
        ],
      );

      final decoded = SwotMatrix.fromJson(original.toJson());
      expect(decoded.strengths.single.content, '高い技術力');
      expect(decoded.threats.single.content, '競合が増えている');
    });

    test(
      'keeps Hive-shaped nested Map<dynamic, dynamic> items '
      '(the cold-start wipe that left dashboards showing なし)',
      () {
        // Hive only retypes the top-level map in loadAll; nested SWOT
        // item maps stay Map<dynamic, dynamic>. The old
        // whereType<Map<String, dynamic>>() filter dropped every item.
        final hiveShaped = <dynamic, dynamic>{
          'strengths': [
            <dynamic, dynamic>{
              'id': 's1',
              'category': 'strength',
              'content': 'バス乗り放題パス',
              'createdAt': '2026-01-01T00:00:00.000',
            },
          ],
          'weaknesses': [
            <dynamic, dynamic>{
              'id': 'w1',
              'category': 'weakness',
              'content': 'やや肥満気味',
              'createdAt': '2026-01-01T00:00:00.000',
            },
          ],
          'opportunities': <dynamic>[],
          'threats': <dynamic>[],
        };

        final decoded = SwotMatrix.fromJson(
          Map<String, dynamic>.from(hiveShaped),
        );

        expect(decoded.strengths, hasLength(1));
        expect(decoded.strengths.single.content, 'バス乗り放題パス');
        expect(decoded.weaknesses, hasLength(1));
        expect(decoded.weaknesses.single.content, 'やや肥満気味');
        expect(decoded.isEmpty, isFalse);
      },
    );
  });
}
