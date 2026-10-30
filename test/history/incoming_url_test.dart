import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/history/incoming_url.dart';

void main() {
  group('themeFromIncomingUrl', () {
    test('osmjiritsu://new?theme= に入れた題がテーマになる', () {
      final url = Uri(
        scheme: 'osmjiritsu',
        host: 'new',
        queryParameters: {'theme': '京都に行く'},
      ).toString();
      expect(themeFromIncomingUrl(url), '京都に行く');
      expect(
        themeFromIncomingUrl(
          'osmjiritsu://new?theme=%E4%BA%AC%E9%83%BD%E3%81%AB%E8%A1%8C%E3%81%8F',
        ),
        '京都に行く',
      );
    });

    test('前後の空白は除く', () {
      expect(themeFromIncomingUrl('osmjiritsu://new?theme=%20%20a%20b%20'), 'a b');
    });

    test('theme が無い・空白・host が違う・scheme が違うときは null', () {
      expect(themeFromIncomingUrl('osmjiritsu://new'), isNull);
      expect(themeFromIncomingUrl('osmjiritsu://new?other=x'), isNull);
      expect(themeFromIncomingUrl('osmjiritsu://new?theme='), isNull);
      expect(themeFromIncomingUrl('osmjiritsu://new?theme=%20%20'), isNull);
      expect(themeFromIncomingUrl('osmjiritsu://open?theme=x'), isNull);
      expect(themeFromIncomingUrl('https://new?theme=x'), isNull);
      expect(themeFromIncomingUrl('osmstroll://new?theme=x'), isNull);
    });

    test('81 グラフェム以上は 80 で切れる', () {
      final long = '👨‍👩‍👧' * 81;
      final url = Uri(
        scheme: 'osmjiritsu',
        host: 'new',
        queryParameters: {'theme': long},
      ).toString();
      final theme = themeFromIncomingUrl(url)!;
      expect(theme.characters.length, 80);
      expect(theme, '👨‍👩‍👧' * 80);
    });
  });
}
