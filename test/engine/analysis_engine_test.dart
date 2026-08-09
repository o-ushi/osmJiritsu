import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/engine/analysis_engine.dart';

void main() {
  const engine = AnalysisEngine();

  group('AnalysisEngine.parseStrategyResponse', () {
    const validStrategyJson = '''
    {
      "strategies": [
        {
          "text": "技術ブログを3本公開して認知を広げる",
          "rationale": "高い技術力(強み)を市場拡大(機会)に結びつけるため"
        },
        {
          "text": "資金調達の相談先を3社に絞る",
          "rationale": "資金不足(弱み)を解消しないと機会を活かせないため"
        }
      ]
    }
    ''';

    test('parses a strategies array into StrategySuggestions', () {
      final strategies = engine.parseStrategyResponse(validStrategyJson);
      expect(strategies, hasLength(2));
      expect(strategies[0].text, contains('技術ブログ'));
      expect(strategies[1].rationale, contains('資金不足'));
    });

    test('recovers a strategies array wrapped in prose and code fences', () {
      final wrapped = '結果はこちらです。\n```json\n$validStrategyJson\n```';
      expect(engine.parseStrategyResponse(wrapped), hasLength(2));
    });

    test('returns an empty list if "strategies" is missing or malformed', () {
      expect(engine.parseStrategyResponse('{"unexpected": true}'), isEmpty);
    });
  });

  group('AnalysisEngine.parseFirstStepResponse', () {
    const validFirstStepJson = '''
    {
      "steps": [
        {"text": "候補となる転職エージェントを3社リストアップする"},
        {"text": "職務経歴書のたたき台を書き始める"}
      ]
    }
    ''';

    test('parses a steps array into FirstStepSuggestions', () {
      final steps = engine.parseFirstStepResponse(validFirstStepJson);
      expect(steps, hasLength(2));
      expect(steps[0].text, contains('転職エージェント'));
    });

    test('returns an empty list if "steps" is missing or malformed', () {
      expect(engine.parseFirstStepResponse('{"unexpected": true}'), isEmpty);
    });
  });
}
