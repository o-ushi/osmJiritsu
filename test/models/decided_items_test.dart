import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/decided_items.dart';

void main() {
  group('splitDecidedItems', () {
    test('drops blank lines and trims', () {
      expect(
        splitDecidedItems('  方策A  \n\n方策B\n'),
        ['方策A', '方策B'],
      );
    });

    test('returns empty for blank input', () {
      expect(splitDecidedItems('  \n  '), isEmpty);
    });
  });

  group('formatDecidedItemsPlain', () {
    test('leaves a single item unnumbered', () {
      expect(formatDecidedItemsPlain('一つの方策', '方策'), '一つの方策');
    });

    test('numbers and separates multiple items', () {
      expect(
        formatDecidedItemsPlain('方策A\n方策B', '方策'),
        '方策 1\n方策A\n\n方策 2\n方策B',
      );
    });
  });
}
