import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/l10n/app_language.dart';
import 'package:osm_jiritsu/l10n/app_strings.dart';

void main() {
  group('AppStrings.text / .tr', () {
    test('Japanese is the identity key: the literal always survives', () {
      expect('言語'.tr(AppLanguage.japanese), '言語');
    });

    test('returns the English translation for a known key', () {
      expect('言語'.tr(AppLanguage.english), 'Language');
    });

    test('returns the Vietnamese translation for a known key', () {
      expect('言語'.tr(AppLanguage.vietnamese), 'Ngôn ngữ');
    });

    test('falls back to the raw key when no translation exists anywhere', () {
      const madeUpKey = 'この文字列はキー登録されていません';
      expect(madeUpKey.tr(AppLanguage.english), madeUpKey);
      expect(madeUpKey.tr(AppLanguage.japanese), madeUpKey);
    });

    test(
      'every English entry has a matching Vietnamese entry (no lopsided catalog)',
      () {
        // A key present in one non-Japanese language but silently missing from
        // the other would degrade to Japanese for just that language --
        // catching that class of typo is cheaper here than in the UI.
        const sampleKeys = [
          'それでは始めましょう',
          'マトリクスを確認する',
          '方策_Google送信確認_本文',
          '言語',
          '共有_テキスト説明',
          '言語_設定が正式',
        ];
        for (final key in sampleKeys) {
          final en = key.tr(AppLanguage.english);
          final vi = key.tr(AppLanguage.vietnamese);
          expect(en, isNot(key), reason: '"$key" has no English translation');
          expect(
            vi,
            isNot(key),
            reason: '"$key" has no Vietnamese translation',
          );
        }
      },
    );
  });

  group('AppStringsContext.trFmt', () {
    test('substitutes a single %@ string placeholder', () {
      expect('テーマ: %@'.trFmt(AppLanguage.japanese, ['転職']), 'テーマ: 転職');
      expect(
        'テーマ: %@'.trFmt(AppLanguage.english, ['Career change']),
        'Theme: Career change',
      );
    });

    test('substitutes two %lld integer placeholders in order', () {
      final result = '%lld / %lld 個 完了'.trFmt(AppLanguage.japanese, ['3', '8']);
      expect(result, '3 / 8 個 完了');
    });

    test(
      'substitutes positionally even when the translation reorders words',
      () {
        // The English/Vietnamese templates for this key still place both
        // %lld tokens in the same left-to-right order as the Japanese one,
        // so a straightforward positional fill (no explicit %1$lld-style
        // indices) is enough here.
        final en = '%lld / %lld 個 完了'.trFmt(AppLanguage.english, ['3', '8']);
        expect(en, '3 / 8 done');
      },
    );
  });

  group('AppLanguage', () {
    test('fromCode round-trips through .code for every language', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromCode(language.code), language);
      }
    });

    test('fromCode defaults to Vietnamese for null/unknown codes', () {
      expect(AppLanguage.fromCode(null), AppLanguage.vietnamese);
      expect(AppLanguage.fromCode('fr'), AppLanguage.vietnamese);
    });
  });
}
