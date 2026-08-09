import 'dart:convert';

import '../models/first_step_suggestion.dart';
import '../models/strategy_suggestion.dart';
import 'json_extractor.dart';

/// Parses Stage1 Chrome-AI-Mode paste responses into typed suggestions.
///
/// Network/prompt construction lives in the flow notifiers + [PromptLibrary];
/// this class only owns the JSON → model decode shared by
/// `StrategyFlowNotifier.pasteAndParse` and
/// `FirstStepFlowNotifier.pasteAndParse`.
class AnalysisEngine {
  const AnalysisEngine();

  /// Parses a raw Chrome-AI-Mode (or any JSON) response into
  /// [StrategySuggestion]s for Stage1 Step 5/6.
  List<StrategySuggestion> parseStrategyResponse(String rawText) {
    final decoded = _decodeJsonObject(rawText);
    final strategies = decoded['strategies'];
    if (strategies is! List) return const [];
    return strategies
        .whereType<Map<String, dynamic>>()
        .map(StrategySuggestion.fromJson)
        .toList();
  }

  /// Parses a raw Chrome-AI-Mode (or any JSON) response into
  /// [FirstStepSuggestion]s for Stage1 Step 9/10.
  List<FirstStepSuggestion> parseFirstStepResponse(String rawText) {
    final decoded = _decodeJsonObject(rawText);
    final steps = decoded['steps'];
    if (steps is! List) return const [];
    return steps
        .whereType<Map<String, dynamic>>()
        .map(FirstStepSuggestion.fromJson)
        .toList();
  }

  Map<String, dynamic> _decodeJsonObject(String rawText) {
    final extracted = JsonExtractor.extractJsonObject(rawText);
    try {
      return jsonDecode(extracted) as Map<String, dynamic>;
    } on FormatException {
      final repaired = JsonExtractor.balanceTruncatedJsonBrackets(extracted);
      return jsonDecode(repaired) as Map<String, dynamic>;
    }
  }
}
