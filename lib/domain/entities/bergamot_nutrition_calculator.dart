import '../../data/database/bergamot_database.dart';

/// محاسبه‌گر مرکزی تغذیه Bergamot
///
/// تمام محاسبات کالری و ماکرو بر اساس per-100g canonical است.
/// تبدیل به per-serving یا per-grams از طریق [scaleByGrams] انجام می‌شود.
///
/// Recipe‌ها از مجموع مواد اولیه (با gram weight) محاسبه می‌شوند.
///
/// این کلاس stateless است — برای استفاده نیازی به instance ندارد.
///
/// **Audit notes (Stage 13):**
/// - [_addNullAware] correctly preserves null semantics (null+null→null,
///   null+val→val). No false zeros are ever introduced.
/// - [scaleByGrams] guards against `grams <= 0` returning an all-null result.
/// - Overflow risk: none. Dart 64-bit doubles handle up to ~1.8×10^308.
/// - Calorie estimation from macros (4×protein + 4×carbs + 9×fat) is
///   intentionally NOT implemented here — calories come directly from the
///   source data (USDA/Iranian). Add an `estimateCalories` static method
///   only if a fallback for missing calorie data is needed.
class BergamotNutritionCalculator {
  BergamotNutritionCalculator._();

  /// مقادیر تغذیه‌ای یک Food را برای مقدار مشخصی گرم محاسبه می‌کند.
  ///
  /// فرمول: per100g × grams / 100
  ///
  /// مثال: غذا با 250 kcal/100g → برای 50g → 125 kcal
  static BergamotNutrition scaleByGrams(Food food, double grams) {
    if (grams <= 0) {
      return const BergamotNutrition();
    }
    final factor = grams / 100.0;
    return BergamotNutrition(
      calories: food.caloriesPer100g != null
          ? food.caloriesPer100g! * factor
          : null,
      protein: food.proteinPer100g != null
          ? food.proteinPer100g! * factor
          : null,
      fat: food.fatPer100g != null
          ? food.fatPer100g! * factor
          : null,
      carbs: food.carbsPer100g != null
          ? food.carbsPer100g! * factor
          : null,
      fiber: food.fiberPer100g != null
          ? food.fiberPer100g! * factor
          : null,
      sugar: food.sugarPer100g != null
          ? food.sugarPer100g! * factor
          : null,
      sodium: food.sodiumPer100g != null
          ? food.sodiumPer100g! * factor
          : null,
      potassium: food.potassiumPer100g != null
          ? food.potassiumPer100g! * factor
          : null,
      calcium: food.calciumPer100g != null
          ? food.calciumPer100g! * factor
          : null,
      iron: food.ironPer100g != null
          ? food.ironPer100g! * factor
          : null,
    );
  }

  /// مقادیر تغذیه‌ای را برای تعداد serving از یک Food محاسبه می‌کند.
  ///
  /// servingSize غذا باید مقدار داشته باشد. اگر نداشته باشد،
  /// 100g فرض می‌شود (در این صورت نتیجه همان per100g × servingCount است).
  static BergamotNutrition scaleByServings(Food food, double servingCount) {
    final gramsPerServing = food.servingSize ?? 100.0;
    return scaleByGrams(food, gramsPerServing * servingCount);
  }

  /// مجموع مقادیر تغذیه‌ای چند Food (با gram weights متفاوت).
  ///
  /// استفاده: محاسبه Nutrition یک وعده یا Recipe.
  static BergamotNutrition sumByGrams(List<({Food food, double grams})> items) {
    if (items.isEmpty) return const BergamotNutrition();
    bool anyCal = false, anyP = false, anyF = false, anyC = false;
    bool anyFib = false, anyS = false, anyNa = false, anyK = false;
    bool anyCa = false, anyFe = false;
    double calSum = 0, pSum = 0, fSum = 0, cSum = 0, fibSum = 0;
    double sSum = 0, naSum = 0, kSum = 0, caSum = 0, feSum = 0;
    for (final item in items) {
      final n = scaleByGrams(item.food, item.grams);
      if (n.calories != null) { calSum += n.calories!; anyCal = true; }
      if (n.protein   != null) { pSum    += n.protein!;    anyP  = true; }
      if (n.fat       != null) { fSum    += n.fat!;        anyF  = true; }
      if (n.carbs     != null) { cSum    += n.carbs!;      anyC  = true; }
      if (n.fiber     != null) { fibSum  += n.fiber!;      anyFib= true; }
      if (n.sugar     != null) { sSum    += n.sugar!;      anyS  = true; }
      if (n.sodium    != null) { naSum   += n.sodium!;     anyNa = true; }
      if (n.potassium != null) { kSum    += n.potassium!;  anyK  = true; }
      if (n.calcium   != null) { caSum   += n.calcium!;    anyCa = true; }
      if (n.iron      != null) { feSum   += n.iron!;       anyFe = true; }
    }
    return BergamotNutrition(
      calories: anyCal ? calSum : null,
      protein:  anyP  ? pSum   : null,
      fat:      anyF  ? fSum   : null,
      carbs:    anyC  ? cSum   : null,
      fiber:    anyFib? fibSum : null,
      sugar:    anyS  ? sSum   : null,
      sodium:   anyNa ? naSum  : null,
      potassium:anyK  ? kSum   : null,
      calcium:  anyCa ? caSum  : null,
      iron:     anyFe ? feSum  : null,
    );
  }

  /// محاسبه Nutrition یک Recipe از مواد اولیه آن.
  ///
  /// ورودی: لیست (Food, grams) برای هر ماده اولیه.
  /// خروجی: Nutrition برای کل yield. برای per-serving، کل را در
  /// (servingSize / totalYieldGrams) ضرب کنید.
  static BergamotNutrition computeRecipeTotal(List<({Food food, double grams})> ingredients) {
    return sumByGrams(ingredients);
  }

  /// محاسبه Nutrition per-serving از total.
  ///
  /// total = Nutrition کل Recipe (مثلاً 1200g قرمه‌سبزی)
  /// servingSize = اندازه سروینگ به گرم (مثلاً 300g)
  /// totalYieldGrams = کل خروجی Recipe به گرم
  static BergamotNutrition computeRecipePerServing({
    required BergamotNutrition total,
    required double servingSize,
    required double totalYieldGrams,
  }) {
    if (totalYieldGrams <= 0) return const BergamotNutrition();
    final factor = servingSize / totalYieldGrams;
    return BergamotNutrition(
      calories: total.calories != null ? total.calories! * factor : null,
      protein:  total.protein  != null ? total.protein!  * factor : null,
      fat:      total.fat      != null ? total.fat!      * factor : null,
      carbs:    total.carbs    != null ? total.carbs!    * factor : null,
      fiber:    total.fiber    != null ? total.fiber!    * factor : null,
      sugar:    total.sugar    != null ? total.sugar!    * factor : null,
      sodium:   total.sodium   != null ? total.sodium!   * factor : null,
      potassium:total.potassium!= null ? total.potassium!* factor : null,
      calcium:  total.calcium  != null ? total.calcium!  * factor : null,
      iron:     total.iron     != null ? total.iron!     * factor : null,
    );
  }

  /// گرد کردن مقادیر برای نمایش (۲ رقم اعشار)
  static BergamotNutrition roundForDisplay(BergamotNutrition n) {
    double? r(double? v) => v == null ? null : double.parse(v.toStringAsFixed(2));
    return BergamotNutrition(
      calories: r(n.calories),
      protein:  r(n.protein),
      fat:      r(n.fat),
      carbs:    r(n.carbs),
      fiber:    r(n.fiber),
      sugar:    r(n.sugar),
      sodium:   r(n.sodium),
      potassium:r(n.potassium),
      calcium:  r(n.calcium),
      iron:     r(n.iron),
    );
  }
}

/// مدل داده‌ای مقادیر تغذیه‌ای — استفاده از nullable به‌معنای
/// "مقدار در منبع موجود نیست" (هرگز صفر جعلی).
class BergamotNutrition {
  final double? calories;       // kcal
  final double? protein;        // g
  final double? fat;            // g
  final double? carbs;          // g
  final double? fiber;           // g
  final double? sugar;          // g
  final double? sodium;         // mg
  final double? potassium;       // mg
  final double? calcium;         // mg
  final double? iron;            // mg

  const BergamotNutrition({
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.fiber,
    this.sugar,
    this.sodium,
    this.potassium,
    this.calcium,
    this.iron,
  });

  BergamotNutrition operator +(BergamotNutrition other) => BergamotNutrition(
        calories:  _addNullAware(calories, other.calories),
        protein:   _addNullAware(protein,  other.protein),
        fat:       _addNullAware(fat,      other.fat),
        carbs:     _addNullAware(carbs,    other.carbs),
        fiber:     _addNullAware(fiber,    other.fiber),
        sugar:     _addNullAware(sugar,    other.sugar),
        sodium:    _addNullAware(sodium,   other.sodium),
        potassium: _addNullAware(potassium,other.potassium),
        calcium:   _addNullAware(calcium,  other.calcium),
        iron:      _addNullAware(iron,     other.iron),
      );

  @override
  String toString() => 'BergamotNutrition(cal=$calories, p=$protein, f=$fat, c=$carbs)';
}

/// جمع null-aware: اگر هر دو مقدار وجود داشته باشد جمع می‌شود،
/// اگر یکی null باشد مقدار دیگری برمی‌گردد، اگر هر دو null باشند null.
/// این تابع از تبدیل null به صفر جلوگیری می‌کند.
double? _addNullAware(double? a, double? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a + b;
}
