import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/domain/entities/bergamot_text_normalizer.dart';

void main() {
  group('BergamotTextNormalizer', () {
    // ---------- normalizeFa ----------
    group('normalizeFa', () {
      test('identity for plain Persian', () {
        expect(BergamotTextNormalizer.normalizeFa('ماست'), 'ماست');
        expect(BergamotTextNormalizer.normalizeFa('سیب'), 'سیب');
      });

      test('Arabic ی → Persian ی', () {
        expect(BergamotTextNormalizer.normalizeFa('سيب'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('كيوي'), 'کیوی');
      });

      test('Arabic ك → Persian ک', () {
        expect(BergamotTextNormalizer.normalizeFa('كلم'), 'کلم');
        expect(BergamotTextNormalizer.normalizeFa('كبsorting'), 'کبsorting');
      });

      test('ZWNJ (نیم‌فاصله) → space', () {
        // "ماست\u200cپرچرب" → "ماست پرچرب"
        expect(
          BergamotTextNormalizer.normalizeFa('ماست\u200cپرچرب'),
          'ماست پرچرب',
        );
      });

      test('multiple spaces collapsed', () {
        expect(BergamotTextNormalizer.normalizeFa('ماست   پرچرب'), 'ماست پرچرب');
        expect(BergamotTextNormalizer.normalizeFa('  سیب   '), 'سیب');
      });

      test('punctuation stripped', () {
        expect(BergamotTextNormalizer.normalizeFa('سیب!؟،'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('گوشت (گاو)'), 'گوشت گاو');
      });

      test('lowercased (no-op for Persian, but mixed text)', () {
        expect(BergamotTextNormalizer.normalizeFa('Apple'), 'apple');
      });

      test('equivalent variants produce same output (PHASE 22 spec)', () {
        // The user spec requires:
        //   ماست / ماست پرچرب / ماست\u200cپرچرب / ي/ي variants
        //   should produce consistent search results
        final a = BergamotTextNormalizer.normalizeFa('ماست');
        final b = BergamotTextNormalizer.normalizeFa('ماست');
        final c = BergamotTextNormalizer.normalizeFa('ماست‌پرچرب');
        final d = BergamotTextNormalizer.normalizeFa('ماست پرچرب');
        final e = BergamotTextNormalizer.normalizeFa('ماست  پرچرب');
        expect(a, equals(b));
        expect(c, equals(d));
        expect(d, equals(e));
      });
    });

    // ---------- normalizeEn ----------
    group('normalizeEn', () {
      test('lowercase', () {
        expect(BergamotTextNormalizer.normalizeEn('APPLE'), 'apple');
        expect(BergamotTextNormalizer.normalizeEn('Apple, RAW'), 'apple raw');
      });

      test('punctuation stripped', () {
        expect(BergamotTextNormalizer.normalizeEn('apple, raw!'), 'apple raw');
        expect(BergamotTextNormalizer.normalizeEn('chicken (boneless)'),
            'chicken boneless');
      });

      test('whitespace collapsed', () {
        expect(BergamotTextNormalizer.normalizeEn('apple   raw'), 'apple raw');
        expect(BergamotTextNormalizer.normalizeEn('  apple '), 'apple');
      });
    });

    // ---------- normalize (auto-detect) ----------
    group('normalize (auto-detect)', () {
      test('Persian input → normalizeFa', () {
        expect(BergamotTextNormalizer.normalize('سيب'), 'سیب');
      });
      test('English input → normalizeEn', () {
        expect(BergamotTextNormalizer.normalize('APPLE, RAW'), 'apple raw');
      });
      test('mixed input treated as Persian if any Persian char present', () {
        // 'apple سیب' has Persian → uses normalizeFa
        final r = BergamotTextNormalizer.normalize('apple سيب');
        expect(r, contains('سیب'));
      });
    });

    // ---------- PHASE 22.4 — User-spec scenarios ----------
    // The user spec requires:
    //   ماست / ماست پرچرب / ماست‌پرچرب / ي/ي variants
    //   should produce consistent search results
    group('PHASE 22.4 user-spec scenarios', () {
      test('"ماست" → "ماست"', () {
        expect(BergamotTextNormalizer.normalizeFa('ماست'), 'ماست');
      });

      test('"ماست پرچرب" → "ماست پرچرب"', () {
        expect(BergamotTextNormalizer.normalizeFa('ماست پرچرب'), 'ماست پرچرب');
      });

      test('"ماست‌پرچرب" (ZWNJ) → "ماست پرچرب" (regular space)', () {
        expect(
          BergamotTextNormalizer.normalizeFa('ماست\u200cپرچرب'),
          'ماست پرچرب',
        );
      });

      test('"ماست  پرچرب" (double space) → "ماست پرچرب" (single space)', () {
        expect(BergamotTextNormalizer.normalizeFa('ماست  پرچرب'), 'ماست پرچرب');
      });

      test('all four "ماست" variants produce same normalized form', () {
        final a = BergamotTextNormalizer.normalizeFa('ماست پرچرب');
        final b = BergamotTextNormalizer.normalizeFa('ماست‌پرچرب');
        final c = BergamotTextNormalizer.normalizeFa('ماست  پرچرب');
        final d = BergamotTextNormalizer.normalizeFa('ماست   پرچرب');
        expect(a, equals(b));
        expect(b, equals(c));
        expect(c, equals(d));
      });

      test('Arabic ي → Persian ی (full word)', () {
        // "سيب" with Arabic ي → "سیب" with Persian ی
        expect(BergamotTextNormalizer.normalizeFa('سيب'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('كيوي'), 'کیوی');
        expect(BergamotTextNormalizer.normalizeFa('ماست'), 'ماست');
      });

      test('Arabic ك → Persian ک (full word)', () {
        // "كلم" with Arabic ك → "کلم" with Persian ک
        expect(BergamotTextNormalizer.normalizeFa('كلم'), 'کلم');
        expect(BergamotTextNormalizer.normalizeFa('كبابی'), 'کبابی');
      });

      test('mixed Arabic/Persian characters → all Persian', () {
        // "كیوي" with Arabic ك and ي → "کیوی"
        expect(BergamotTextNormalizer.normalizeFa('كیوي'), 'کیوی');
        // "سيب كلم" → "سیب کلم"
        expect(BergamotTextNormalizer.normalizeFa('سيب كلم'), 'سیب کلم');
      });

      test('punctuation including Persian punctuation stripped', () {
        expect(BergamotTextNormalizer.normalizeFa('سیب!'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('سیب؟'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('سیب،'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('سیب؛'), 'سیب');
        expect(BergamotTextNormalizer.normalizeFa('گوشت (گاو)'), 'گوشت گاو');
      });

      test('English search term → normalizeEn', () {
        expect(BergamotTextNormalizer.normalizeEn('Apple'), 'apple');
        expect(BergamotTextNormalizer.normalizeEn('APPLE'), 'apple');
        expect(BergamotTextNormalizer.normalizeEn('Chicken, RAW'), 'chicken raw');
        expect(BergamotTextNormalizer.normalizeEn('Chicken  RAW'), 'chicken raw');
      });

      test('English with punctuation stripped', () {
        expect(BergamotTextNormalizer.normalizeEn('Apple, raw!'), 'apple raw');
        expect(BergamotTextNormalizer.normalizeEn('chicken (boneless)'),
            'chicken boneless');
        expect(BergamotTextNormalizer.normalizeEn('milk, whole [2%]'),
            'milk whole 2');
      });

      test('auto-detect: empty string → empty', () {
        expect(BergamotTextNormalizer.normalize(''), '');
      });

      test('auto-detect: whitespace-only → empty', () {
        expect(BergamotTextNormalizer.normalize('   '), '');
        expect(BergamotTextNormalizer.normalize('\t\n'), '');
      });
    });
  });
}
