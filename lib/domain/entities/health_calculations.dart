// Pure health calculation functions — no Flutter, no AI, no randomness.
// Uses Mifflin-St Jeor equation for BMR.
//
// **Audit notes (Stage 13):**
// - BMR: Standard Mifflin-St Jeor — Male: 10W+6.25H−5A+5, Female: +5→−161. ✓
// - BMI: weight/(height_m²) with guard for heightCm≤0. ✓
// - TDEE: BMR × activity multiplier (standard 5-tier). ✓
// - Calorie target: ±500/300 deficit/surplus with 1200 kcal safety floor. ✓
// - Macros: protein 1.6–2.2 g/kg by goal, fat 25%, carb remainder (4/9/4 kcal/g). ✓
// - 1RM Brzycki: weight×(36/(37−reps)), guarded for reps≤0, ==1, ≥36. ✓

// ── Helper ──────────────────────────────────────────────────────────────

/// ضریب فعالیت برای محاسبه TDEE
///
/// Levels:
/// - sedentary: کم‌تحرک
/// - light: فعالیت سبک
/// - moderate: فعالیت متوسط
/// - active: فعال
/// - very_active: بسیار فعال
double activityMultiplier(String activityLevel) => switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.2, // default: sedentary
    };

// ── BMI ─────────────────────────────────────────────────────────────────

/// شاخص توده بدنی (BMI)
///
/// [weightKg] وزن به کیلوگرم
/// [heightCm] قد به سانتی‌متر
///
/// Returns BMI (kg/m²).
double calculateBMI(double weightKg, double heightCm) {
  if (heightCm <= 0) return 0;
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

// ── BMR (Mifflin-St Jeor) ──────────────────────────────────────────────

/// نرخ متابولیسم پایه با فرمول میفلین-است‌جئور
///
/// Male:   10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161 + 166
///         = 10 × W + 6.25 × H − 5 × A + 5
///
/// Female: 10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161
///
/// [gender] must be 'male' or 'female'.
double calculateBMR(
  double weightKg,
  double heightCm,
  int age,
  String gender,
) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return gender == 'male' ? base + 5 : base - 161;
}

// ── TDEE ─────────────────────────────────────────────────────────────────

/// مصرف انرژی روزانه کل (TDEE)
///
/// [bmr] نرخ متابولیسم پایه
/// [activityLevel] سطح فعالیت
///
/// Returns TDEE in kcal.
double calculateTDEE(double bmr, String activityLevel) =>
    bmr * activityMultiplier(activityLevel);

// ── Calorie Target ──────────────────────────────────────────────────────

/// هدف کالری روزانه بر اساس TDEE و نوع هدف
///
/// - lose: ۵۰۰ کالری کمتر از TDEE
/// - maintain: همان TDEE
/// - gain: ۳۰۰ کالری بیشتر از TDEE
double calculateCalorieTarget(double tdee, String goalType) {
  const minCalories = 1200.0; // safe minimum for adults
  final target = switch (goalType) {
      'lose' => tdee - 500,
      'gain' => tdee + 300,
      _ => tdee, // maintain or unknown
    };
  return target < minCalories ? minCalories : target;
}

// ── Macro Targets ───────────────────────────────────────────────────────

/// اهداف ماکرو (پروتئین، چربی، کربوهیدرات) بر حسب کالری هدف
///
/// Returns a [MacroTargets] with grams for each macro.
///
/// Protein:
///   - lose: 2.2 g/kg
///   - gain: 2.0 g/kg
///   - maintain: 1.6 g/kg
///
/// Fat: 25% of calories
/// Carb: remainder of calories
///
/// 1g protein = 4 kcal, 1g fat = 9 kcal, 1g carb = 4 kcal
MacroTargets calculateMacroTargets(
  double calorieTarget,
  double weightKg,
  String goalType,
) {
  // Protein grams per kg
  final proteinPerKg = switch (goalType) {
        'lose' => 2.2,
        'gain' => 2.0,
        _ => 1.6, // maintain
      };

  final proteinG = weightKg * proteinPerKg;
  final proteinCal = proteinG * 4;

  // Fat: 25% of total calories
  final fatCal = calorieTarget * 0.25;
  final fatG = fatCal / 9;

  // Carb: remainder
  final carbCal = calorieTarget - proteinCal - fatCal;
  final carbG = (carbCal / 4).clamp(0.0, double.infinity);

  return MacroTargets(
    proteinG: proteinG,
    fatG: fatG,
    carbG: carbG,
  );
}

// ── Water Target ────────────────────────────────────────────────────────

/// هدف آب روزانه به میلی‌لیتر
///
/// Base: 35 ml per kg body weight
/// Activity bonus:
///   - moderate+: +500 ml
double calculateWaterTarget(double weightKg, String activityLevel) {
  final base = weightKg * 35;
  final bonus = (activityLevel == 'moderate' ||
          activityLevel == 'active' ||
          activityLevel == 'very_active')
      ? 500.0
      : 0.0;
  return base + bonus;
}

// ── 1RM (Brzycki) ───────────────────────────────────────────────────────

/// تخمین حداکثر وزن یک‌تکراری (1RM) با فرمول برزیکی
///
/// 1RM = weight × (36 / (37 − reps))
///
/// Only valid for reps > 0. Returns weight if reps == 1.
double calculate1RM(double weight, int reps) {
  if (reps <= 0 || weight <= 0) return 0;
  if (reps == 1) return weight;
  // Brzycki formula is only valid for reps < 36.
  // At reps >= 36 the denominator becomes zero or negative.
  if (reps >= 36) return weight * 1.0; // conservative floor: no meaningful estimation
  return weight * (36 / (37 - reps));
}

// ── HealthMetrics ───────────────────────────────────────────────────────

/// تمام محاسبات سلامت در یک ساختار
///
/// Generated by the pure functions above.
class HealthMetrics {
  /// شاخص توده بدنی
  final double bmi;

  /// نرخ متابولیسم پایه
  final double bmr;

  /// مصرف انرژی روزانه کل
  final double tdee;

  /// هدف کالری
  final double calorieTarget;

  /// هدف پروتئین (گرم)
  final double proteinTargetG;

  /// هدف چربی (گرم)
  final double fatTargetG;

  /// هدف کربوهیدرات (گرم)
  final double carbTargetG;

  /// هدف آب (میلی‌لیتر)
  final double waterTargetMl;

  const HealthMetrics({
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.proteinTargetG,
    required this.fatTargetG,
    required this.carbTargetG,
    required this.waterTargetMl,
  });

  /// محاسبه تمام معیارها از ورودی‌های پایه
  factory HealthMetrics.calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required String goalType,
  }) {
    final bmi = calculateBMI(weightKg, heightCm);
    final bmr = calculateBMR(weightKg, heightCm, age, gender);
    final tdee = calculateTDEE(bmr, activityLevel);
    final calorieTarget = calculateCalorieTarget(tdee, goalType);
    final macros = calculateMacroTargets(calorieTarget, weightKg, goalType);
    final waterTarget = calculateWaterTarget(weightKg, activityLevel);

    return HealthMetrics(
      bmi: bmi,
      bmr: bmr,
      tdee: tdee,
      calorieTarget: calorieTarget,
      proteinTargetG: macros.proteinG,
      fatTargetG: macros.fatG,
      carbTargetG: macros.carbG,
      waterTargetMl: waterTarget,
    );
  }

  @override
  String toString() =>
      'HealthMetrics(BMI: ${bmi.toStringAsFixed(1)}, BMR: ${bmr.toStringAsFixed(0)}, '
      'TDEE: ${tdee.toStringAsFixed(0)}, Cal: ${calorieTarget.toStringAsFixed(0)}, '
      'P: ${proteinTargetG.toStringAsFixed(0)}g, F: ${fatTargetG.toStringAsFixed(0)}g, '
      'C: ${carbTargetG.toStringAsFixed(0)}g, Water: ${waterTargetMl.toStringAsFixed(0)}ml)';
}

// ── MacroTargets ────────────────────────────────────────────────────────

/// اهداف ماکرو营养物质
class MacroTargets {
  final double proteinG;
  final double fatG;
  final double carbG;

  const MacroTargets({
    required this.proteinG,
    required this.fatG,
    required this.carbG,
  });
}
