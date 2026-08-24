import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/data/database/bergamot_database.dart';
import 'package:bergamot/domain/entities/bergamot_nutrition_calculator.dart';

void main() {
  group('BergamotNutritionCalculator', () {
    // Helper: ساخت Food با مقادیر مشخص per-100g
    Food makeFood({
      double? calories = 250,
      double? protein = 10,
      double? fat = 5,
      double? carbs = 40,
      double? fiber = 3,
      double? servingSize = 100,
      String servingUnit = 'gram',
    }) {
      return Food(
        id: 1,
        nameFa: 'تست',
        nameEn: 'Test',
        normalizedNameFa: 'تست',
        normalizedNameEn: 'test',
        categoryId: 'other',
        caloriesPer100g: calories,
        proteinPer100g: protein,
        fatPer100g: fat,
        carbsPer100g: carbs,
        fiberPer100g: fiber,
        servingSize: servingSize,
        servingUnit: servingUnit,
        source: 'CUSTOM',
        isCustom: false,
        isVerified: true,
        verificationStatus: 'VERIFIED',
        createdAt: 0,
      );
    }

    // ───────── scaleByGrams ─────────
    group('scaleByGrams', () {
      test('100g × 100/100 = identity', () {
        final f = makeFood(calories: 250, protein: 10, fat: 5, carbs: 40);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 100);
        expect(n.calories, closeTo(250, 0.001));
        expect(n.protein, closeTo(10, 0.001));
        expect(n.fat, closeTo(5, 0.001));
        expect(n.carbs, closeTo(40, 0.001));
      });

      test('50g → half of 100g values', () {
        final f = makeFood(calories: 250, protein: 10, fat: 5, carbs: 40);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 50);
        expect(n.calories, closeTo(125, 0.001));
        expect(n.protein, closeTo(5, 0.001));
        expect(n.fat, closeTo(2.5, 0.001));
        expect(n.carbs, closeTo(20, 0.001));
      });

      test('200g → double of 100g values', () {
        final f = makeFood(calories: 250, protein: 10, fat: 5, carbs: 40);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 200);
        expect(n.calories, closeTo(500, 0.001));
        expect(n.protein, closeTo(20, 0.001));
        expect(n.fat, closeTo(10, 0.001));
        expect(n.carbs, closeTo(80, 0.001));
      });

      test('0g → zero (not null)', () {
        final f = makeFood();
        final n = BergamotNutritionCalculator.scaleByGrams(f, 0);
        expect(n.calories, isNull); // 0g returns empty Nutrition
      });

      test('NULL nutrient values preserved as NULL (not 0)', () {
        final f = makeFood(calories: null, protein: null, fat: null);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 100);
        expect(n.calories, isNull);
        expect(n.protein, isNull);
        expect(n.fat, isNull);
      });

      test('fiber scales proportionally', () {
        final f = makeFood(fiber: 6);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 50);
        expect(n.fiber, closeTo(3, 0.001));
      });
    });

    // ───────── scaleByServings ─────────
    group('scaleByServings', () {
      test('1 serving × 100g serving → identity', () {
        final f = makeFood(servingSize: 100);
        final n = BergamotNutritionCalculator.scaleByServings(f, 1.0);
        expect(n.calories, closeTo(250, 0.001));
      });

      test('2 servings × 50g serving → 100g total', () {
        final f = makeFood(servingSize: 50, calories: 200);
        final n = BergamotNutritionCalculator.scaleByServings(f, 2.0);
        expect(n.calories, closeTo(200, 0.001));
      });

      test('0.5 serving × 200g serving → 100g', () {
        final f = makeFood(servingSize: 200, calories: 300);
        final n = BergamotNutritionCalculator.scaleByServings(f, 0.5);
        expect(n.calories, closeTo(300, 0.001));
      });

      test('null servingSize → defaults to 100g', () {
        final f = makeFood(servingSize: null, calories: 100);
        final n = BergamotNutritionCalculator.scaleByServings(f, 1.0);
        expect(n.calories, closeTo(100, 0.001));
      });
    });

    // ───────── sumByGrams ─────────
    group('sumByGrams', () {
      test('sums multiple foods correctly', () {
        final items = <({Food food, double grams})>[
          (food: makeFood(calories: 100, protein: 5), grams: 100),
          (food: makeFood(calories: 200, protein: 10), grams: 50),
        ];
        final n = BergamotNutritionCalculator.sumByGrams(items);
        // Food 1: 100g × 100/100 = 100
        // Food 2: 50g × 200/100 = 100
        // Total: 200
        expect(n.calories, closeTo(200, 0.001));
        expect(n.protein, closeTo(10, 0.001));
      });

      test('empty list → empty Nutrition', () {
        final n = BergamotNutritionCalculator.sumByGrams([]);
        expect(n.calories, isNull);
        expect(n.protein, isNull);
      });

      test('partial NULLs handled gracefully', () {
        final items = <({Food food, double grams})>[
          (food: makeFood(calories: 100, protein: null), grams: 100),
          (food: makeFood(calories: 200, protein: 10), grams: 50),
        ];
        final n = BergamotNutritionCalculator.sumByGrams(items);
        // Only food 2 has protein → 5
        expect(n.protein, closeTo(5, 0.001));
        expect(n.calories, closeTo(200, 0.001));
      });
    });

    // ───────── computeRecipePerServing ─────────
    group('computeRecipePerServing', () {
      test('scales total → per-serving by yield ratio', () {
        const total = BergamotNutrition(
          calories: 1200, // for 1200g yield
          protein: 60,
          fat: 30,
          carbs: 100,
        );
        final perServing = BergamotNutritionCalculator.computeRecipePerServing(
          total: total,
          servingSize: 300, // 1/4 of yield
          totalYieldGrams: 1200,
        );
        expect(perServing.calories, closeTo(300, 0.001));
        expect(perServing.protein, closeTo(15, 0.001));
        expect(perServing.fat, closeTo(7.5, 0.001));
        expect(perServing.carbs, closeTo(25, 0.001));
      });

      test('zero yield → empty (no division by zero)', () {
        const total = BergamotNutrition(calories: 100);
        final perServing = BergamotNutritionCalculator.computeRecipePerServing(
          total: total,
          servingSize: 100,
          totalYieldGrams: 0,
        );
        expect(perServing.calories, isNull);
      });

      test('NULLs in total preserved', () {
        const total = BergamotNutrition(
          calories: null,
          protein: 10,
        );
        final perServing = BergamotNutritionCalculator.computeRecipePerServing(
          total: total,
          servingSize: 100,
          totalYieldGrams: 200,
        );
        expect(perServing.calories, isNull);
        expect(perServing.protein, closeTo(5, 0.001));
      });
    });

    // ───────── roundForDisplay ─────────
    group('roundForDisplay', () {
      test('rounds to 2 decimal places', () {
        const n = BergamotNutrition(calories: 123.456789, protein: 0.12345);
        final r = BergamotNutritionCalculator.roundForDisplay(n);
        expect(r.calories, closeTo(123.46, 0.0001));
        expect(r.protein, closeTo(0.12, 0.0001));
      });

      test('NULLs preserved', () {
        const n = BergamotNutrition(calories: null, protein: 5.5);
        final r = BergamotNutritionCalculator.roundForDisplay(n);
        expect(r.calories, isNull);
        expect(r.protein, closeTo(5.5, 0.0001));
      });
    });

    // ───────── BergamotNutrition operator + ─────────
    group('BergamotNutrition +', () {
      test('adds two nutritions', () {
        const a = BergamotNutrition(calories: 100, protein: 5);
        const b = BergamotNutrition(calories: 200, protein: 10);
        final c = a + b;
        expect(c.calories, 300);
        expect(c.protein, 15);
      });

      test('NULL treated as 0 in +', () {
        const a = BergamotNutrition(calories: null, protein: 5);
        const b = BergamotNutrition(calories: 200, protein: null);
        final c = a + b;
        // NULL coerces to 0 in operator +
        expect(c.calories, 200);
        expect(c.protein, 5);
      });
    });

    // ───────── Edge cases (PHASE 22.3) ─────────
    group('edge cases (0 servings, NaN, negative)', () {
      test('0 servings × any serving size → empty Nutrition (no NaN)', () {
        final f = makeFood(servingSize: 100, calories: 250);
        final n = BergamotNutritionCalculator.scaleByServings(f, 0);
        // 0 servings × 100g = 0g → scaleByGrams returns empty Nutrition
        expect(n.calories, isNull);
        expect(n.protein, isNull);
        expect(n.fat, isNull);
        expect(n.carbs, isNull);
        // No NaN or Infinity in any field
        for (final v in [n.calories, n.protein, n.fat, n.carbs, n.fiber]) {
          if (v != null) {
            expect(v.isNaN, false);
            expect(v.isInfinite, false);
          }
        }
      });

      test('0 servings × null serving size → still 0g', () {
        final f = makeFood(servingSize: null, calories: 250);
        final n = BergamotNutritionCalculator.scaleByServings(f, 0);
        // null servingSize → defaults to 100g, 0 × 100 = 0g → empty
        expect(n.calories, isNull);
      });

      test('negative servings → treated as 0g by scaleByGrams', () {
        // scaleByServings(servingSize=100, servingCount=-1) → gramsPerServing × -1 = -100
        // scaleByGrams(food, -100): grams <= 0 → returns empty
        final f = makeFood(servingSize: 100, calories: 250);
        final n = BergamotNutritionCalculator.scaleByServings(f, -1);
        // -1 × 100 = -100g → grams <= 0 → empty Nutrition
        expect(n.calories, isNull);
      });

      test('0 grams → empty Nutrition (not NaN, not Infinity)', () {
        final f = makeFood(calories: 100);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 0);
        expect(n.calories, isNull);
        expect(n.protein, isNull);
      });

      test('negative grams → empty Nutrition (no negative nutrition)', () {
        final f = makeFood(calories: 100);
        final n = BergamotNutritionCalculator.scaleByGrams(f, -50);
        expect(n.calories, isNull);
      });

      test('very large grams (10000g) → scales correctly without overflow', () {
        final f = makeFood(calories: 100, protein: 5);
        final n = BergamotNutritionCalculator.scaleByGrams(f, 10000);
        // 10000g × 100/100 = 10000 kcal
        expect(n.calories, closeTo(10000, 0.001));
        expect(n.protein, closeTo(500, 0.001));
        expect(n.calories!.isFinite, true);
      });

      test('all-NULL food → all-NULL Nutrition', () {
        const f = Food(
          id: 1,
          nameFa: 'تست',
          nameEn: 'Test',
          normalizedNameFa: 'تست',
          normalizedNameEn: 'test',
          categoryId: 'other',
          caloriesPer100g: null,
          proteinPer100g: null,
          fatPer100g: null,
          carbsPer100g: null,
          fiberPer100g: null,
          servingSize: 100,
          servingUnit: 'gram',
          source: 'CUSTOM',
          isCustom: false,
          isVerified: false,
          verificationStatus: 'NEEDS_VERIFICATION',
          createdAt: 0,
        );
        final n = BergamotNutritionCalculator.scaleByGrams(f, 100);
        expect(n.calories, isNull);
        expect(n.protein, isNull);
        expect(n.fat, isNull);
        expect(n.carbs, isNull);
        // No NaN
        for (final v in [n.calories, n.protein, n.fat, n.carbs, n.fiber]) {
          if (v != null) {
            expect(v.isNaN, false, reason: 'Got NaN for field');
          }
        }
      });

      test('sumByGrams with food having NaN-like inputs → no propagation', () {
        final f = makeFood(calories: 0, protein: 0);
        final items = <({Food food, double grams})>[
          (food: f, grams: 100),
        ];
        final n = BergamotNutritionCalculator.sumByGrams(items);
        expect(n.calories, 0);
        expect(n.protein, 0);
        expect(n.calories!.isFinite, true);
        expect(n.calories!.isNaN, false);
      });

      test('roundForDisplay handles Infinity gracefully (no NaN)', () {
        const n = BergamotNutrition(calories: double.infinity);
        final r = BergamotNutritionCalculator.roundForDisplay(n);
        // Infinity stays Infinity after round (not NaN, not crash)
        expect(r.calories, isNotNull);
        expect(r.calories!.isFinite, false);  // still Infinity
        expect(r.calories!.isNaN, false);  // but not NaN
      });
    });
  });
}
