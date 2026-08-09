import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/first_step_suggestion.dart';

void main() {
  group('FirstStepSuggestion JSON round trip', () {
    test('preserves text', () {
      final suggestion = FirstStepSuggestion(text: '候補先を3社リストアップする');

      final decoded = FirstStepSuggestion.fromJson(suggestion.toJson());

      expect(decoded.id, suggestion.id);
      expect(decoded.text, suggestion.text);
    });

    test('trims whitespace and defaults to empty when text is missing', () {
      expect(
        FirstStepSuggestion.fromJson({'text': '  行動  '}).text,
        '行動',
      );
      expect(FirstStepSuggestion.fromJson({}).text, '');
    });
  });
}
