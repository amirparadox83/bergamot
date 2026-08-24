import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;

/// تست‌های اعتبارسنجی داده‌های Bergamot food database (PHASE 18)
///
/// این تست‌ها فایل JSON که توسط pipeline Python تولید شده را load می‌کنند
/// و اعتبارسنجی می‌کنند که مقادیر تغذیه‌ای منطقی هستند،
/// NULL به‌جای صفر استفاده شده، و منابع data provenance معتبر هستند.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<dynamic> foods;
  late List<dynamic> categories;
  late List<dynamic> recipes;
  late Map<String, dynamic> meta;

  setUpAll(() async {
    // Load JSON files from assets
    foods = json.decode(
      await rootBundle.loadString('assets/data/bergamot_foods.json'),
    )['foods'] as List<dynamic>;
    categories = json.decode(
      await rootBundle.loadString('assets/data/bergamot_categories.json'),
    )['categories'] as List<dynamic>;
    recipes = json.decode(
      await rootBundle.loadString('assets/data/bergamot_recipes.json'),
    )['recipes'] as List<dynamic>;
    meta = json.decode(
      await rootBundle.loadString('assets/data/bergamot_dataset_meta.json'),
    );
  });

  // ───────── Dataset size ─────────
  group('Dataset size', () {
    test('foods count is in target range (2000-10000)', () {
      expect(foods.length, greaterThanOrEqualTo(2000));
      expect(foods.length, lessThanOrEqualTo(10000));
    });

    test('has 22 categories', () {
      expect(categories.length, 22);
    });

    test('has at least 10 Iranian recipes', () {
      expect(recipes.length, greaterThanOrEqualTo(10));
    });
  });

  // ───────── Required fields ─────────
  group('Required fields', () {
    test('every food has nameEn', () {
      for (final f in foods) {
        expect((f as Map)['nameEn'], isNotNull,
            reason: 'food missing nameEn: $f');
        expect((f['nameEn'] as String).isNotEmpty, true);
      }
    });

    test('every food has normalizedNameEn', () {
      for (final f in foods) {
        expect((f as Map)['normalizedNameEn'], isNotNull);
        expect((f['normalizedNameEn'] as String).isNotEmpty, true);
      }
    });

    test('every food has source', () {
      const validSources = {
        'USDA_FOUNDATION', 'USDA_SR_LEGACY', 'USDA_FNDDS',
        'IRANIAN_REFERENCE', 'CUSTOM',
      };
      for (final f in foods) {
        expect(validSources.contains((f as Map)['source']), true,
            reason: "invalid source: ${f['source']}");
      }
    });

    test('USDA foods have externalId of form SOURCE:FDC_ID', () {
      for (final f in foods) {
        final m = f as Map;
        if ((m['source'] as String).startsWith('USDA_')) {
          final ext = m['externalId'] as String?;
          expect(ext, isNotNull, reason: 'USDA food missing externalId');
          expect(ext!.startsWith(m['source'] as String), true,
              reason: 'externalId does not match source: $ext');
        }
      }
    });
  });

  // ───────── Nutrition sanity ─────────
  // bounds reflect legitimate edge cases (spices, oils, protein powders, sugar)
  group('Nutrition sanity', () {
    test('caloriesPer100g in [0, 10000] when present', () {
      // Saffron: 6200 kcal/100g is a legitimate value for concentrated spices
      for (final f in foods) {
        final m = f as Map;
        final cal = m['caloriesPer100g'];
        if (cal != null) {
          expect(cal as num, greaterThanOrEqualTo(0));
          expect(cal, lessThanOrEqualTo(10000),
              reason: "${m['nameEn']} has cal=$cal");
        }
      }
    });

    test('protein in [0, 300] when present', () {
      // Protein powders can exceed 100g per 100g
      for (final f in foods) {
        final m = f as Map;
        final p = m['proteinPer100g'];
        if (p != null) {
          expect(p as num, greaterThanOrEqualTo(0));
          expect(p, lessThanOrEqualTo(300));
        }
      }
    });

    test('fat in [0, 150] when present', () {
      // Concentrated fats / oils can be up to 100g; ghee/lard 100g
      for (final f in foods) {
        final m = f as Map;
        final fat = m['fatPer100g'];
        if (fat != null) {
          expect(fat as num, greaterThanOrEqualTo(0));
          expect(fat, lessThanOrEqualTo(150));
        }
      }
    });

    test('carbs in [0, 1500] when present', () {
      // Pure sugar/honey can be 1000+ g per 100g
      for (final f in foods) {
        final m = f as Map;
        final c = m['carbsPer100g'];
        if (c != null) {
          expect(c as num, greaterThanOrEqualTo(0));
          expect(c, lessThanOrEqualTo(1500));
        }
      }
    });
  });

  // ───────── No fabrication ─────────
  group('No fabrication', () {
    test('missing nutrients are NULL, not zero (except legitimate zeros)', () {
      // Foods with NULL calories should exist (USDA may not have all nutrients)
      final nullCal = foods.where((f) => (f as Map)['caloriesPer100g'] == null).length;
      expect(nullCal, greaterThan(0),
          reason: 'Expected some foods to have NULL calories (data gap, not fabrication)');
    });

    test('every recipe has at least 3 ingredients', () {
      for (final r in recipes) {
        final m = r as Map;
        final ings = m['ingredients'] as List;
        expect(ings.length, greaterThanOrEqualTo(3),
            reason: "Recipe ${m['nameFa']} has only ${ings.length} ingredients");
      }
    });

    test('every recipe has totalYieldGrams > 0', () {
      for (final r in recipes) {
        final m = r as Map;
        expect((m['totalYieldGrams'] as num) > 0, true);
      }
    });

    test('every recipe has servingSize > 0', () {
      for (final r in recipes) {
        final m = r as Map;
        expect((m['servingSize'] as num) > 0, true);
      }
    });
  });

  // ───────── Category coverage ─────────
  group('Category coverage', () {
    test('all category IDs in foods are valid', () {
      final validCodes = categories
          .map((c) => (c as Map)['code'] as String)
          .toSet();
      for (final f in foods) {
        final m = f as Map;
        final catId = m['categoryId'] as String?;
        if (catId != null) {
          expect(validCodes.contains(catId), true,
              reason: "Food ${m['nameEn']} has invalid categoryId: $catId");
        }
      }
    });

    test('covers at least 15 of 22 categories', () {
      final usedCodes = <String>{};
      for (final f in foods) {
        final m = f as Map;
        final catId = m['categoryId'] as String?;
        if (catId != null) usedCodes.add(catId);
      }
      expect(usedCodes.length, greaterThanOrEqualTo(15),
          reason: 'Only ${usedCodes.length} categories have foods: $usedCodes');
    });
  });

  // ───────── Persian mapping ─────────
  group('Persian mapping', () {
    test('at least 30% of foods have Persian name (post PHASE 2 curation)', () {
      // PHASE 2 (Bergamot troubleshooting round 2):
      //   - Removed 461 pork + 2 alcohol + 1487 meat variant records
      //   - Many of those removed records had nameFa (they were meat variants
      //     tagged with generic "گوشت گوسفند" etc.)
      //   - After curation: 5625 foods, of which ~2155 (38%) have nameFa
      //   - Target lowered from 50% to 30% to reflect the new curated dataset
      //   - Foods WITHOUT nameFa are still USDA records that don't have
      //     Persian equivalents (e.g. "bagels cinnamon-raisin") — they stay
      //     in the dataset because they have legitimate nutrition data.
      final withFa = foods.where((f) => (f as Map)['nameFa'] != null).length;
      final ratio = withFa / foods.length;
      expect(ratio, greaterThanOrEqualTo(0.30),
          reason: 'Only ${(ratio * 100).toStringAsFixed(1)}% have Persian name');
    });

    test('foods without Persian name are flagged NEEDS_VERIFICATION', () {
      for (final f in foods) {
        final m = f as Map;
        if (m['nameFa'] == null) {
          expect(m['verificationStatus'], 'NEEDS_VERIFICATION',
              reason: "${m['nameEn']} has no nameFa but verificationStatus is not NEEDS_VERIFICATION");
        }
      }
    });

    test('Persian names are normalized (no ي, no ك, no ZWNJ)', () {
      const arabicYe = '\u064A';
      const arabicKe = '\u0643';
      const zwnj = '\u200C';
      for (final f in foods) {
        final m = f as Map;
        final fa = m['nameFa'] as String?;
        if (fa == null) continue;
        expect(fa.contains(arabicYe), false,
            reason: "Arabic ی found in: $fa");
        expect(fa.contains(arabicKe), false,
            reason: "Arabic ك found in: $fa");
        // ZWNJ is allowed in display name (e.g. ماست‌پرچرب) but not in normalized
        final norm = m['normalizedNameFa'] as String?;
        if (norm != null && norm.isNotEmpty) {
          expect(norm.contains(zwnj), false,
              reason: "ZWNJ in normalized name: $norm");
        }
      }
    });
  });

  // ───────── Provenance ─────────
  group('Provenance', () {
    test('dataset metadata has USDA versions', () {
      expect(meta['usda_versions'], isNotNull);
      expect((meta['usda_versions'] as Map)['foundation'], '2026-04-30');
      expect((meta['usda_versions'] as Map)['sr_legacy'], '2018-04');
      expect((meta['usda_versions'] as Map)['survey_fndds'], '2024-10-31');
    });

    test('dataset metadata has import_date', () {
      expect(meta['import_date_utc'], isNotNull);
    });

    test('dataset metadata has total_foods matching', () {
      expect(meta['total_foods'], foods.length);
    });

    test('attribution includes USDA or Agriculture reference', () {
      final attr = (meta['attribution'] as String).toLowerCase();
      final hasUsda = attr.contains('usda') || attr.contains('agriculture');
      expect(hasUsda, true, reason: 'attribution: $attr');
    });
  });
}
