import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/engine/chrome_ai_link.dart';

void main() {
  group('ChromeAiLink.webSearchUrl', () {
    test('puts the prompt in the "q" query param with AI Mode enabled', () {
      final uri = ChromeAiLink.webSearchUrl(prompt: 'SWOTを分析して');

      expect(uri.host, 'www.google.co.jp');
      expect(uri.path, '/search');
      expect(uri.queryParameters['q'], 'SWOTを分析して');
      expect(uri.queryParameters['udm'], '50');
      expect(uri.queryParameters['hl'], 'ja');
    });

    test('trims the prompt before placing it in the query', () {
      final uri = ChromeAiLink.webSearchUrl(prompt: '  hello  ');
      expect(uri.queryParameters['q'], 'hello');
    });

    test('respects the hl override', () {
      final uri = ChromeAiLink.webSearchUrl(prompt: 'test', hl: 'en');
      expect(uri.queryParameters['hl'], 'en');
    });

    test('falls back to a bare AI-Mode URL when the prompt is too long', () {
      final longPrompt = 'あ' * 8000;
      final uri = ChromeAiLink.webSearchUrl(prompt: longPrompt);

      expect(uri.queryParameters.containsKey('q'), isFalse);
      expect(uri.queryParameters['udm'], '50');
      expect(uri.toString().length, lessThan(1000));
    });
  });
}
