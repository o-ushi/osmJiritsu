import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/suggestion_adoption.dart';

void main() {
  group('splitDecidedIntoAdoptions', () {
    test('marks a single matching suggestion as adopted and clears ownText', () {
      final split = splitDecidedIntoAdoptions(
        suggestions: const [
          (id: 'a', text: '方策A'),
          (id: 'b', text: '方策B'),
        ],
        decidedText: '方策A',
      );
      expect(split.adoptedIds, {'a'});
      expect(split.ownText, isEmpty);
    });

    test('marks every matching line and leaves unmatched wording as ownText', () {
      final split = splitDecidedIntoAdoptions(
        suggestions: const [
          (id: 'a', text: '方策A'),
          (id: 'b', text: '方策B'),
        ],
        decidedText: '方策A\n方策B\n自分だけの方策',
      );
      expect(split.adoptedIds, {'a', 'b'});
      expect(split.ownText, '自分だけの方策');
    });

    test('leaves everything as ownText when nothing matches', () {
      final split = splitDecidedIntoAdoptions(
        suggestions: const [
          (id: 'a', text: '方策A'),
        ],
        decidedText: '完全に独自の方策',
      );
      expect(split.adoptedIds, isEmpty);
      expect(split.ownText, '完全に独自の方策');
    });

    test('prefers longer suggestion texts when one is a prefix of another', () {
      final split = splitDecidedIntoAdoptions(
        suggestions: const [
          (id: 'short', text: '方策'),
          (id: 'long', text: '方策を深掘りする'),
        ],
        decidedText: '方策を深掘りする',
      );
      expect(split.adoptedIds, {'long'});
      expect(split.ownText, isEmpty);
    });

    test('returns empty adoption for blank decided text', () {
      final split = splitDecidedIntoAdoptions(
        suggestions: const [(id: 'a', text: '方策A')],
        decidedText: '   ',
      );
      expect(split.adoptedIds, isEmpty);
      expect(split.ownText, isEmpty);
    });
  });
}
