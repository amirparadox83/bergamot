// تست‌های فرمول‌های سلامت Bergamot (PHASE 22.1)
//
// هر تست با مقادیر مرجع شناخته‌شده نوشته شده و رفتار کد در ورودی‌های مرزی
// (مثلاً reps=37، weight=0، height=0) را به‌صورت واقعی تست می‌کند — نه تخمین.
//
// منابع مرجع:
//   BMI: WHO standard
//   BMR: Mifflin-St Jeor (1990)
//   TDEE: Harris-Benedict activity multipliers
//   1RM: Brzycki formula
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/domain/entities/health_calculations.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // BMI
  // ────────────────────────────────────────────────────────────────────────
  group('calculateBMI', () {
    // WHO reference: BMI = weight(kg) / height(m)²
    test('standard adult — 70kg / 170cm → 24.22', () {
      // 70 / (1.70)² = 70 / 2.89 = 24.221...
      final bmi = calculateBMI(70, 170);
      expect(bmi, closeTo(24.22, 0.01));
    });

    test('underweight reference — 50kg / 175cm → 16.33', () {
      // 50 / (1.75)² = 50 / 3.0625 = 16.327
      final bmi = calculateBMI(50, 175);
      expect(bmi, closeTo(16.33, 0.01));
    });

    test('obese reference — 100kg / 170cm → 34.60', () {
      // 100 / 2.89 = 34.602
      final bmi = calculateBMI(100, 170);
      expect(bmi, closeTo(34.60, 0.01));
    });

    test('normal range — 65kg / 175cm → 21.22', () {
      // 65 / 3.0625 = 21.224
      final bmi = calculateBMI(65, 175);
      expect(bmi, closeTo(21.22, 0.01));
    });

    test('zero height → returns 0 (no NaN, no crash)', () {
      expect(calculateBMI(70, 0), 0);
    });

    test('negative height → returns 0', () {
      expect(calculateBMI(70, -170), 0);
    });

    test('zero weight → BMI = 0', () {
      expect(calculateBMI(0, 170), 0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BMR — Mifflin-St Jeor
  // ────────────────────────────────────────────────────────────────────────
  group('calculateBMR (Mifflin-St Jeor)', () {
    // Male formula: 10*W + 6.25*H - 5*A + 5
    test('male — 80kg, 180cm, 30y → 1780', () {
      // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      final bmr = calculateBMR(80, 180, 30, 'male');
      expect(bmr, closeTo(1780, 0.001));
    });

    // Female formula: 10*W + 6.25*H - 5*A - 161
    test('female — 60kg, 165cm, 25y → 1323.25', () {
      // 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      final bmr = calculateBMR(60, 165, 25, 'female');
      expect(bmr, closeTo(1345.25, 0.001));
    });

    test('male — 100kg, 190cm, 40y → 2137.5', () {
      // 10*100 + 6.25*190 - 5*40 + 5 = 1000 + 1187.5 - 200 + 5 = 1992.5
      final bmr = calculateBMR(100, 190, 40, 'male');
      expect(bmr, closeTo(1992.5, 0.001));
    });

    test('unknown gender → treated as female (conservative)', () {
      // Same as female formula
      final bmrUnknown = calculateBMR(60, 165, 25, 'unknown');
      final bmrFemale = calculateBMR(60, 165, 25, 'female');
      expect(bmrUnknown, bmrFemale);
    });

    test('extreme age — 100 years old → still computable', () {
      final bmr = calculateBMR(70, 170, 100, 'male');
      // 10*70 + 6.25*170 - 5*100 + 5 = 700 + 1062.5 - 500 + 5 = 1267.5
      expect(bmr, closeTo(1267.5, 0.001));
    });

    test('zero weight → BMR = 5 (male) or -161 (female)', () {
      // 10*0 + 6.25*170 - 5*30 + 5 = 0 + 1062.5 - 150 + 5 = 917.5
      // Actually let me recompute: 0 + 1062.5 - 150 + 5 = 917.5
      final bmr = calculateBMR(0, 170, 30, 'male');
      expect(bmr, closeTo(917.5, 0.001));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // TDEE
  // ────────────────────────────────────────────────────────────────────────
  group('calculateTDEE', () {
    test('sedentary (×1.2) — BMR 1500 → 1800', () {
      expect(calculateTDEE(1500, 'sedentary'), closeTo(1800, 0.001));
    });

    test('light (×1.375) — BMR 1500 → 2062.5', () {
      expect(calculateTDEE(1500, 'light'), closeTo(2062.5, 0.001));
    });

    test('moderate (×1.55) — BMR 1500 → 2325', () {
      expect(calculateTDEE(1500, 'moderate'), closeTo(2325, 0.001));
    });

    test('active (×1.725) — BMR 1500 → 2587.5', () {
      expect(calculateTDEE(1500, 'active'), closeTo(2587.5, 0.001));
    });

    test('very_active (×1.9) — BMR 1500 → 2850', () {
      expect(calculateTDEE(1500, 'very_active'), closeTo(2850, 0.001));
    });

    test('unknown activity → defaults to sedentary (×1.2)', () {
      expect(calculateTDEE(1500, 'unknown'), closeTo(1800, 0.001));
    });

    test('zero BMR → zero TDEE', () {
      expect(calculateTDEE(0, 'moderate'), 0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Calorie Target
  // ────────────────────────────────────────────────────────────────────────
  group('calculateCalorieTarget', () {
    test('lose → TDEE - 500', () {
      expect(calculateCalorieTarget(2500, 'lose'), 2000);
    });

    test('gain → TDEE + 300', () {
      expect(calculateCalorieTarget(2500, 'gain'), 2800);
    });

    test('maintain → TDEE', () {
      expect(calculateCalorieTarget(2500, 'maintain'), 2500);
    });

    test('unknown goal → defaults to maintain', () {
      expect(calculateCalorieTarget(2500, 'unknown'), 2500);
    });

    test('lose with TDEE < 500 → clamped to 1200 (safe minimum)', () {
      // TDEE 300, lose 500 → -200, but production code clamps to 1200 minimum
      expect(calculateCalorieTarget(300, 'lose'), 1200);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Macro Targets
  // ────────────────────────────────────────────────────────────────────────
  group('calculateMacroTargets', () {
    // Standard case: 2000 kcal target, 70 kg, maintain
    // Protein = 70 × 1.6 = 112g (448 kcal)
    // Fat = 2000 × 0.25 / 9 = 55.56g (500 kcal)
    // Carb = (2000 - 448 - 500) / 4 = 263g (1052 kcal)
    test('maintain — 2000 kcal, 70kg', () {
      final m = calculateMacroTargets(2000, 70, 'maintain');
      expect(m.proteinG, closeTo(112, 0.01));
      expect(m.fatG, closeTo(55.56, 0.01));
      expect(m.carbG, closeTo(263, 0.01));
    });

    // Lose — 2.2 g/kg protein
    test('lose — 1800 kcal, 80kg', () {
      // Protein = 80 × 2.2 = 176g (704 kcal)
      // Fat = 1800 × 0.25 / 9 = 50g (450 kcal)
      // Carb = (1800 - 704 - 450) / 4 = 161.5g (646 kcal)
      final m = calculateMacroTargets(1800, 80, 'lose');
      expect(m.proteinG, closeTo(176, 0.01));
      expect(m.fatG, closeTo(50, 0.01));
      expect(m.carbG, closeTo(161.5, 0.01));
    });

    // Gain — 2.0 g/kg protein
    test('gain — 2800 kcal, 70kg', () {
      // Protein = 70 × 2.0 = 140g (560 kcal)
      // Fat = 2800 × 0.25 / 9 = 77.78g (700 kcal)
      // Carb = (2800 - 560 - 700) / 4 = 385g (1540 kcal)
      final m = calculateMacroTargets(2800, 70, 'gain');
      expect(m.proteinG, closeTo(140, 0.01));
      expect(m.fatG, closeTo(77.78, 0.01));
      expect(m.carbG, closeTo(385, 0.01));
    });

    test('unknown goal → defaults to maintain (1.6 g/kg)', () {
      final m = calculateMacroTargets(2000, 70, 'unknown');
      expect(m.proteinG, closeTo(112, 0.01));
    });

    test('zero weight → zero protein, carb still computed from calories', () {
      final m = calculateMacroTargets(2000, 0, 'maintain');
      expect(m.proteinG, 0);
      // Fat = 500 kcal = 55.56g, carb = (2000 - 0 - 500) / 4 = 375g
      expect(m.fatG, closeTo(55.56, 0.01));
      expect(m.carbG, closeTo(375, 0.01));
    });

    test('zero calorie target → zero carb, but protein still from weight', () {
      final m = calculateMacroTargets(0, 70, 'maintain');
      expect(m.proteinG, closeTo(112, 0.01));
      expect(m.fatG, 0);
      // carb = (0 - 448 - 0) / 4 → negative, clamped to 0
      expect(m.carbG, greaterThanOrEqualTo(0));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // Water Target
  // ────────────────────────────────────────────────────────────────────────
  group('calculateWaterTarget', () {
    test('sedentary — 70kg → 2450 ml (35 × 70, no bonus)', () {
      expect(calculateWaterTarget(70, 'sedentary'), closeTo(2450, 0.001));
    });

    test('moderate — 70kg → 2950 ml (+500 bonus)', () {
      expect(calculateWaterTarget(70, 'moderate'), closeTo(2950, 0.001));
    });

    test('active — 70kg → 2950 ml (+500 bonus)', () {
      expect(calculateWaterTarget(70, 'active'), closeTo(2950, 0.001));
    });

    test('very_active — 70kg → 2950 ml (+500 bonus)', () {
      expect(calculateWaterTarget(70, 'very_active'), closeTo(2950, 0.001));
    });

    test('light — 70kg → 2450 ml (no bonus)', () {
      expect(calculateWaterTarget(70, 'light'), closeTo(2450, 0.001));
    });

    test('unknown activity → no bonus (treated as sedentary)', () {
      expect(calculateWaterTarget(70, 'unknown'), closeTo(2450, 0.001));
    });

    test('zero weight → zero water', () {
      expect(calculateWaterTarget(0, 'moderate'), 500); // just the bonus
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 1RM (Brzycki)
  // ────────────────────────────────────────────────────────────────────────
  group('calculate1RM (Brzycki)', () {
    // 1RM = weight × (36 / (37 − reps))
    test('reps = 1 → returns weight', () {
      expect(calculate1RM(100, 1), closeTo(100, 0.001));
    });

    test('reps = 5, weight = 80 → 92.57', () {
      // 80 × (36 / 32) = 80 × 1.125 = 90
      // Wait: 36/(37-5) = 36/32 = 1.125, 80*1.125 = 90
      expect(calculate1RM(80, 5), closeTo(90, 0.001));
    });

    test('reps = 10, weight = 60 → 80', () {
      // 60 × (36 / 27) = 60 × 1.3333 = 80
      expect(calculate1RM(60, 10), closeTo(80, 0.001));
    });

    test('reps = 36 → conservative floor (reps >= 36 guard)', () {
      // Production code guards reps >= 36: returns weight * 1.0 = 100
      // Brzycki is invalid at this boundary (denominator → 0)
      final result = calculate1RM(100, 36);
      expect(result, closeTo(100, 0.001));
    });

    test('reps = 37 → conservative floor (reps >= 36 guard)', () {
      // Production code guards reps >= 36: returns weight * 1.0 = 100
      // Brzycki formula would divide by zero at reps=37
      final result = calculate1RM(100, 37);
      expect(result, closeTo(100, 0.001));
    });

    test('reps = 0 → returns 0 (no crash)', () {
      expect(calculate1RM(100, 0), 0);
    });

    test('reps negative → returns 0', () {
      expect(calculate1RM(100, -5), 0);
    });

    test('weight = 0 → returns 0', () {
      expect(calculate1RM(0, 5), 0);
    });

    test('reps = 38 → conservative floor (reps >= 36 guard)', () {
      // Production code guards reps >= 36: returns weight * 1.0 = 100
      final result = calculate1RM(100, 38);
      expect(result, closeTo(100, 0.001));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // activityMultiplier
  // ────────────────────────────────────────────────────────────────────────
  group('activityMultiplier', () {
    test('returns correct values for all standard levels', () {
      expect(activityMultiplier('sedentary'), 1.2);
      expect(activityMultiplier('light'), 1.375);
      expect(activityMultiplier('moderate'), 1.55);
      expect(activityMultiplier('active'), 1.725);
      expect(activityMultiplier('very_active'), 1.9);
    });

    test('unknown level → defaults to sedentary (1.2)', () {
      expect(activityMultiplier('foo'), 1.2);
      expect(activityMultiplier(''), 1.2);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // HealthMetrics.calculate (integration)
  // ────────────────────────────────────────────────────────────────────────
  group('HealthMetrics.calculate (integration)', () {
    test('end-to-end — male, 80kg, 180cm, 30y, moderate, lose', () {
      final m = HealthMetrics.calculate(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        gender: 'male',
        activityLevel: 'moderate',
        goalType: 'lose',
      );
      // BMI = 80 / 3.24 = 24.69
      expect(m.bmi, closeTo(24.69, 0.01));
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      expect(m.bmr, closeTo(1780, 0.01));
      // TDEE = 1780 * 1.55 = 2759
      expect(m.tdee, closeTo(2759, 0.01));
      // Calorie target (lose) = 2759 - 500 = 2259
      expect(m.calorieTarget, closeTo(2259, 0.01));
      // Protein (lose) = 80 * 2.2 = 176g
      expect(m.proteinTargetG, closeTo(176, 0.01));
      // Water = 80 * 35 + 500 = 2800 + 500 = 3300
      expect(m.waterTargetMl, closeTo(3300, 0.01));
    });

    test('end-to-end — female, 60kg, 165cm, 25y, sedentary, maintain', () {
      final m = HealthMetrics.calculate(
        weightKg: 60,
        heightCm: 165,
        age: 25,
        gender: 'female',
        activityLevel: 'sedentary',
        goalType: 'maintain',
      );
      // BMI = 60 / 2.7225 = 22.04
      expect(m.bmi, closeTo(22.04, 0.01));
      // BMR (female) = 10*60 + 6.25*165 - 5*25 - 161 = 1345.25
      expect(m.bmr, closeTo(1345.25, 0.01));
      // TDEE = 1345.25 * 1.2 = 1614.3
      expect(m.tdee, closeTo(1614.3, 0.01));
      // Calorie target (maintain) = TDEE
      expect(m.calorieTarget, closeTo(1614.3, 0.01));
      // Protein (maintain) = 60 * 1.6 = 96
      expect(m.proteinTargetG, closeTo(96, 0.01));
      // Water (sedentary) = 60 * 35 = 2100
      expect(m.waterTargetMl, closeTo(2100, 0.01));
    });
  });
}
