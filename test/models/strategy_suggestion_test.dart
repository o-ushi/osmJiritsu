import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/strategy_suggestion.dart';

void main() {
  group('StrategySuggestion JSON round trip', () {
    test('preserves text and rationale', () {
      final suggestion = StrategySuggestion(
        text: '技術ブログを3本公開して認知を広げる',
        rationale: '高い技術力(強み)を市場拡大(機会)に結びつけるため',
      );

      final decoded = StrategySuggestion.fromJson(suggestion.toJson());

      expect(decoded.id, suggestion.id);
      expect(decoded.text, suggestion.text);
      expect(decoded.rationale, suggestion.rationale);
    });

    test('defaults rationale to empty and trims whitespace when absent/malformed', () {
      final decoded = StrategySuggestion.fromJson({
        'text': '  方策のみ  ',
      });

      expect(decoded.text, '方策のみ');
      expect(decoded.rationale, '');
    });
  });
}
