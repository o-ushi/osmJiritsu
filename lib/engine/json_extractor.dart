/// Recovers a JSON object from a raw LLM text response that may be wrapped
/// in prose, Markdown code fences, or truncated mid-stream (e.g. hitting
/// `maxOutputTokens`).
///
/// Ports `GuideResponseRecovery` from
/// osmSWOT/Services/GuideResponseRecovery.swift — Gemini's `responseMimeType:
/// application/json` setting reduces but does not eliminate the chance of a
/// model wrapping its answer in commentary or code fences, so
/// [AnalysisEngine] runs every raw response through this before decoding.
class JsonExtractor {
  JsonExtractor._();

  /// Strips everything before the first `{`, removes ``` / ```json code
  /// fences, then returns just the first balanced `{...}` object (brace
  /// depth tracked outside string literals, so braces inside quoted text
  /// don't throw off the count).
  static String extractJsonObject(String raw) {
    var cleaned = raw.trim();
    cleaned = _stripLeadingNonJsonProse(cleaned).trim();
    cleaned = cleaned.replaceAll(RegExp(r'```(?:json)?\s*'), '');
    cleaned = cleaned.replaceAll('```', '');

    final startIndex = cleaned.indexOf('{');
    if (startIndex == -1) return cleaned.trim();

    var braceCount = 0;
    int? endIndex;
    for (var i = startIndex; i < cleaned.length; i++) {
      final char = cleaned[i];
      if (char == '{') {
        braceCount++;
      } else if (char == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i;
          break;
        }
      }
    }

    final slice = endIndex != null
        ? cleaned.substring(startIndex, endIndex + 1)
        : cleaned.substring(startIndex);
    return slice.trim();
  }

  static String _stripLeadingNonJsonProse(String raw) {
    final braceIndex = raw.indexOf('{');
    if (braceIndex == -1) return raw;
    return raw.substring(braceIndex);
  }

  /// Best-effort repair for JSON truncated mid-stream: walks the text
  /// (ignoring anything inside string literals) tracking open `{`/`[`
  /// brackets on a stack, then appends the matching closers. Not a full
  /// JSON grammar — just enough to recover a `finishReason: MAX_TOKENS`
  /// response with a dangling trailing comma or open object/array.
  static String balanceTruncatedJsonBrackets(String raw) {
    var inString = false;
    var escape = false;
    final stack = <String>[];

    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      if (escape) {
        escape = false;
        continue;
      }
      if (inString) {
        if (ch == '\\') {
          escape = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      switch (ch) {
        case '"':
          inString = true;
          break;
        case '{':
        case '[':
          stack.add(ch);
          break;
        case '}':
          if (stack.isNotEmpty && stack.last == '{') stack.removeLast();
          break;
        case ']':
          if (stack.isNotEmpty && stack.last == '[') stack.removeLast();
          break;
      }
    }

    final suffix = StringBuffer();
    while (stack.isNotEmpty) {
      final top = stack.removeLast();
      suffix.write(top == '{' ? '}' : ']');
    }
    return raw + suffix.toString();
  }
}
