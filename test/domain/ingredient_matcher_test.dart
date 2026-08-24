import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/domain/entities/ingredient_matcher.dart';

/// تست‌های IngredientMatcher (PHASE 1.2 — راند رفع مشکلات)
///
/// این تست‌ها دو گروه دارند:
///
/// 1. **Unit tests** روی منطق pure matcher با داده‌های synthetic کوچک
///    تا هر استراتژی تطبیق به‌طور جداگانه آزمایش شود.
///
/// 2. **Integration test** که فایل‌های واقعی `bergamot_recipes.json` و
///    `bergamot_foods.json` را load می‌کند و نسبت تطبیق کلی را محاسبه
///    می‌کند. اگر نسبت زیر ۸۰٪ شود، تست fail می‌شود. این جلوی regression
///    در آینده را می‌گیرد — اگر کسی فایل‌های recipe/food را تغییر داد و
///    باعث شد تطبیق خراب شود، این تست آن را گزارش می‌کند.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────────────────────────
  // Group 1: Unit tests on synthetic data
  // ────────────────────────────────────────────────────────────────────
  group('IngredientMatcher — Unit', () {
    const matcher = IngredientMatcher();

    test('Strategy 1: exact match wins over everything', () {
      final foods = [
        const FoodCandidate(
            id: 1,
            normalizedNameEn: 'onion raw',
            source: 'USDA_SR_LEGACY'),
        const FoodCandidate(
            id: 2,
            normalizedNameEn: 'onions raw',
            source: 'USDA_FOUNDATION'),
        const FoodCandidate(
            id: 3,
            normalizedNameEn: 'onion',
            source: 'IRANIAN_REFERENCE'),
      ];
      final result = matcher.findBestMatch(
          ingredientKey: 'onion raw', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1);
      expect(result.strategy, IngredientMatchStrategy.exact);
    });

    test('Strategy 1: prefers IRANIAN_REFERENCE on duplicate names', () {
      final foods = [
        const FoodCandidate(
            id: 10,
            normalizedNameEn: 'rice white long-grain raw',
            source: 'USDA_SR_LEGACY'),
        const FoodCandidate(
            id: 20,
            normalizedNameEn: 'rice white long-grain raw',
            source: 'IRANIAN_REFERENCE'),
      ];
      final result = matcher.findBestMatch(
          ingredientKey: 'rice white long-grain raw', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 20); // IRANIAN_REFERENCE wins
      expect(result.strategy, IngredientMatchStrategy.exact);
    });

    test('Strategy 2: plural/singular adjustment', () {
      final foods = [
        const FoodCandidate(
            id: 1, normalizedNameEn: 'onions raw', source: 'USDA_SR_LEGACY'),
        const FoodCandidate(
            id: 2,
            normalizedNameEn: 'onion powder',
            source: 'USDA_SR_LEGACY'),
      ];
      // Recipe key "onion raw" (singular) should match "onions raw" (plural)
      final result = matcher.findBestMatch(
          ingredientKey: 'onion raw', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1);
      expect(result.strategy, IngredientMatchStrategy.pluralSingular);
    });

    test('Strategy 2: plural → singular direction', () {
      final foods = [
        const FoodCandidate(
            id: 1, normalizedNameEn: 'onion', source: 'IRANIAN_REFERENCE'),
      ];
      // Recipe key "onions" (plural) should match "onion" (singular)
      final result =
          matcher.findBestMatch(ingredientKey: 'onions', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1);
      expect(result.strategy, IngredientMatchStrategy.pluralSingular);
    });

    test('Strategy 3: token-superset (food ⊆ recipe)', () {
      final foods = [
        // Food "cilantro" — tokens {cilantro} ⊆ {cilantro, fresh} of recipe key
        const FoodCandidate(
            id: 1, normalizedNameEn: 'cilantro', source: 'IRANIAN_REFERENCE'),
        // Food "coriander cilantro leaves raw" — has extra tokens
        const FoodCandidate(
            id: 2,
            normalizedNameEn: 'coriander cilantro leaves raw',
            source: 'USDA_SR_LEGACY'),
      ];
      final result = matcher.findBestMatch(
          ingredientKey: 'cilantro fresh', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1); // Shorter IRANIAN_REFERENCE wins
      expect(result.strategy, IngredientMatchStrategy.tokenSuperset);
    });

    test('Strategy 3: prefers shorter name + IRANIAN_REFERENCE', () {
      final foods = [
        const FoodCandidate(
            id: 1, normalizedNameEn: 'mint', source: 'IRANIAN_REFERENCE'),
        const FoodCandidate(
            id: 2,
            normalizedNameEn: 'mint fresh',
            source: 'USDA_SR_LEGACY'),
      ];
      // Recipe "mint dried" → food "mint" (superset match, IRANIAN_REFERENCE wins)
      final result = matcher.findBestMatch(
          ingredientKey: 'mint dried', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1);
      expect(result.strategy, IngredientMatchStrategy.tokenSuperset);
    });

    test('Strategy 4: token-subset penalizes bad extras (organ meats)', () {
      final foods = [
        const FoodCandidate(
            id: 1,
            normalizedNameEn: 'lamb new zealand imported liver raw',
            source: 'USDA_SR_LEGACY'),
        const FoodCandidate(
            id: 2,
            normalizedNameEn: 'lamb new zealand imported shoulder raw',
            source: 'USDA_SR_LEGACY'),
      ];
      // Recipe "lamb raw" → both have lamb+raw, but liver has bad_extra
      final result =
          matcher.findBestMatch(ingredientKey: 'lamb raw', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 2); // shoulder wins, no bad_extra
      expect(result.strategy, IngredientMatchStrategy.tokenSubset);
    });

    test('Strategy 4: penalizes sweet potato vs potato', () {
      final foods = [
        const FoodCandidate(
            id: 1,
            normalizedNameEn: 'sweet potato leaves raw',
            source: 'USDA_SR_LEGACY'),
        const FoodCandidate(
            id: 2,
            normalizedNameEn: 'potatoes raw skin',
            source: 'USDA_SR_LEGACY'),
      ];
      // Recipe "potato raw" → "sweet potato leaves raw" has 2 bad extras (sweet+leaves)
      // "potatoes raw skin" has 1 bad extra (skin) — wins
      final result =
          matcher.findBestMatch(ingredientKey: 'potato raw', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 2);
      expect(result.strategy, IngredientMatchStrategy.tokenSubset);
    });

    test('Strategy 5: token overlap catches "lamb raw" → "lamb meat"', () {
      final foods = [
        // "lamb meat" doesn't have "raw" — Strategies 1-4 fail.
        // Strategy 5: "lamb" is non-qualifier token, matches "lamb" in food.
        const FoodCandidate(
            id: 1, normalizedNameEn: 'lamb meat', source: 'IRANIAN_REFERENCE'),
      ];
      final result =
          matcher.findBestMatch(ingredientKey: 'lamb raw', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1);
      expect(result.strategy, IngredientMatchStrategy.tokenOverlap);
    });

    test('Strategy 5: rejects pure-qualifier matches (no false positives)', () {
      final foods = [
        const FoodCandidate(
            id: 1, normalizedNameEn: 'basil fresh', source: 'USDA_SR_LEGACY'),
      ];
      // Recipe "fenugreek fresh" — "fresh" is qualifier, "fenugreek" is non-qualifier.
      // "fenugreek" not in "basil fresh" → no match.
      final result = matcher.findBestMatch(
          ingredientKey: 'fenugreek fresh', foods: foods);
      expect(result, isNull);
    });

    test('returns null on empty key', () {
      const foods = [
        FoodCandidate(id: 1, normalizedNameEn: 'onion', source: 'IRANIAN_REFERENCE'),
      ];
      expect(matcher.findBestMatch(ingredientKey: '', foods: foods), isNull);
    });

    test('returns null on empty food list', () {
      expect(
          matcher.findBestMatch(
              ingredientKey: 'onion raw', foods: const []),
          isNull);
    });

    test('handles special recipe key with multiple words', () {
      final foods = [
        const FoodCandidate(
            id: 1,
            normalizedNameEn: 'egg whole raw fresh',
            source: 'USDA_SR_LEGACY'),
      ];
      final result = matcher.findBestMatch(
          ingredientKey: 'egg raw whole', foods: foods);
      expect(result, isNotNull);
      expect(result!.food.id, 1);
      // Recipe tokens {egg, raw, whole} ⊆ food tokens {egg, whole, raw, fresh}
      expect(result.strategy, IngredientMatchStrategy.tokenSubset);
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // Group 2: Integration tests against real JSON data files
  // ────────────────────────────────────────────────────────────────────
  group('IngredientMatcher — Integration (real JSON data)', () {
    const matcher = IngredientMatcher();
    late List<FoodCandidate> candidates;
    late List<dynamic> recipes;

    setUpAll(() async {
      // Load both JSON files
      final foodsJson = json.decode(
        await rootBundle.loadString('assets/data/bergamot_foods.json'),
      ) as Map<String, dynamic>;
      final recipesJson = json.decode(
        await rootBundle.loadString('assets/data/bergamot_recipes.json'),
      ) as Map<String, dynamic>;

      candidates = (foodsJson['foods'] as List<dynamic>)
          .asMap()
          .entries
          .map((e) => FoodCandidate(
                // Use the index as id (we don't need the real DB id for testing)
                id: e.key + 1,
                normalizedNameEn:
                    (e.value as Map)['normalizedNameEn'] as String? ?? '',
                source: (e.value as Map)['source'] as String?,
                nameFa: (e.value as Map)['nameFa'] as String?,
              ))
          .toList();

      recipes = recipesJson['recipes'] as List<dynamic>;
    });

    test('every recipe has ≥ 70% ingredients matched (regression guard)', () {
      final below70 = <String>[];
      for (final r in recipes) {
        final ings = (r as Map)['ingredients'] as List<dynamic>;
        if (ings.isEmpty) continue;
        int matched = 0;
        for (final ing in ings) {
          final key = (ing as Map)['ingredientKey'] as String;
          final result = matcher.findBestMatch(
              ingredientKey: key, foods: candidates);
          if (result != null) matched++;
        }
        final ratio = matched / ings.length;
        if (ratio < 0.7) {
          below70.add(
              '${r['nameFa']} (${(ratio * 100).round()}% = $matched/${ings.length})');
        }
      }
      expect(
        below70,
        isEmpty,
        reason:
            'Recipes below 70% ingredient match: ${below70.join(', ')}. '
            'Either the IngredientMatcher regressed, or the food database '
            'is missing common ingredients used by these recipes.',
      );
    });

    test('overall ingredient match ratio ≥ 80% (regression guard)', () {
      int totalIngredients = 0;
      int totalMatched = 0;
      for (final r in recipes) {
        final ings = (r as Map)['ingredients'] as List<dynamic>;
        for (final ing in ings) {
          final key = (ing as Map)['ingredientKey'] as String;
          final result = matcher.findBestMatch(
              ingredientKey: key, foods: candidates);
          totalIngredients++;
          if (result != null) totalMatched++;
        }
      }
      final ratio = totalMatched / totalIngredients;
      // Report per-recipe breakdown in case of failure
      final breakdown = StringBuffer();
      for (final r in recipes) {
        final ings = (r as Map)['ingredients'] as List<dynamic>;
        int matched = 0;
        for (final ing in ings) {
          final key = (ing as Map)['ingredientKey'] as String;
          final result = matcher.findBestMatch(
              ingredientKey: key, foods: candidates);
          if (result != null) matched++;
        }
        breakdown.writeln(
            '  - ${r['nameFa']}: $matched/${ings.length} '
            '(${(matched / ings.length * 100).round()}%)');
      }
      expect(
        ratio,
        greaterThanOrEqualTo(0.80),
        reason:
            'Overall ingredient match ratio is ${(ratio * 100).round()}%, '
            'below the 80% threshold.\n'
            'Per-recipe breakdown:\n$breakdown',
      );
    });

    test('each recipe returns a recipe-level breakdown for the worklog', () {
      // This test doesn't fail; it's a reporting utility.
      // It logs per-recipe match ratios for transparency.
      final lines = <String>[];
      int totalIngredients = 0;
      int totalMatched = 0;
      for (final r in recipes) {
        final ings = (r as Map)['ingredients'] as List<dynamic>;
        if (ings.isEmpty) continue;
        int matched = 0;
        final unmatched = <String>[];
        for (final ing in ings) {
          final key = (ing as Map)['ingredientKey'] as String;
          final result = matcher.findBestMatch(
              ingredientKey: key, foods: candidates);
          if (result != null) {
            matched++;
          } else {
            unmatched.add(key);
          }
          totalIngredients++;
        }
        totalMatched += matched;
        final ratio = matched / ings.length;
        final status = ratio < 0.7 ? '⚠️' : '✓';
        final unmatchedStr =
            unmatched.isEmpty ? '' : ' | unmatched: $unmatched';
        lines.add(
            '$status ${r['nameFa']}: $matched/${ings.length} '
            '(${(ratio * 100).round()}%)$unmatchedStr');
      }
      final overall =
          (totalMatched * 100 / totalIngredients).round();
      // ignore: avoid_print
      print('━━━ IngredientMatcher — Recipe Match Breakdown ━━━');
      for (final line in lines) {
        // ignore: avoid_print
        print(line);
      }
      // ignore: avoid_print
      print('━━━ Overall: $totalMatched/$totalIngredients ($overall%) ━━━');
      expect(totalMatched, greaterThan(0));
    });
  });
}
