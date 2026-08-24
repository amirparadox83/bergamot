import 'package:drift/drift.dart';
import 'food_table.dart';

/// جدول آیتم‌های غذایی ثبت‌شده در وعده‌ها
///
/// هر رکورد یک "snapshot" از غذای مصرف‌شده در یک وعده است.
///
/// **NO FOOD FK JOIN FOR NUTRITION** — مقادیر کالری/پروتئین/چربی/کربوهیدرات/فیبر
/// به‌صورت denormalized در همین جدول ذخیره می‌شوند تا اگر غذای Foods در آینده
/// (مثلاً با update بعدی USDA) تغییر کند، تاریخچه مصرف کاربر دست‌نخورده باقی بماند.
///
/// مثال:
///   امروز کاربر 100g برنج می‌خورد → 130 kcal در meal_entry ذخیره می‌شود
///   یک سال بعد USDA مقدار را به 135 kcal به‌روزرسانی می‌کند
///   → meal_entry امروز همچنان 130 kcal نشان می‌دهد
///
/// فیلد foodId فقط برای "jump to food" در UI استفاده می‌شود — نه برای محاسبه nutrition.
class MealEntries extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// نوع وعده: ۰=صبحانه، ۱=ناهار، ۲=شام، ۳=میان‌وعده
  IntColumn get mealType => integer()();

  /// شناسه غذای مرجع (FK به Foods.id) — فقط برای UI navigation
  /// در صورت حذف غذا از Foods، این فیلد NULL می‌شود اما مقادیر nutrition باقی می‌مانند.
  IntColumn get foodId => integer().nullable().references(Foods, #id)();

  /// نام غذا (snapshot — denormalized برای خواندن سریع و حفظ تاریخچه)
  TextColumn get foodName => text()();

  /// منبع داده غذا در زمان ثبت (snapshot — برای audit trail)
  /// مثلاً USDA_FOUNDATION / IRANIAN_REFERENCE / CUSTOM
  TextColumn get foodSource => text().nullable()();

  /// شناسه خارجی غذا در زمان ثبت (snapshot)
  /// مثلاً USDA_FOUNDATION:321358
  TextColumn get foodExternalId => text().nullable()();

  /// تعداد سروینگ - پیش‌فرض ۱
  RealColumn get servingCount => real().withDefault(const Constant(1))();

  /// مقدار گرم مصرف‌شده (snapshot — برای reproducibility)
  /// این مقدار با food.servingSize × servingCount در زمان ثبت محاسبه می‌شود.
  RealColumn get grams => real().nullable()();

  // ─── Nutrition snapshot (denormalized) ───────────────────────────────
  // UNIT CONVENTION: These are ABSOLUTE values for the consumed amount
  // (e.g., 150 kcal for 120g eaten), NOT per-100g. They are computed as:
  //   Food.per100gValue × (consumedGrams / 100)
  // This convention matches BergamotNutritionCalculator.scaleByGrams.

  /// کالری کل (snapshot — بر اساس گرم × per-100g در زمان ثبت)
  RealColumn get calories => real()();

  /// پروتئین کل (گرم) — snapshot
  RealColumn get protein => real()();

  /// چربی کل (گرم) — snapshot
  RealColumn get fat => real()();

  /// کربوهیدرات کل (گرم) — snapshot
  RealColumn get carb => real()();

  /// فیبر کل (گرم) — snapshot (v6)
  RealColumn get fiber => real().nullable()();

  // TODO: [Migration] The following 5 nutrition fields from Foods are NOT
  // TODO: snapshotted here. Add them in a future schema migration (v7+):
  // TODO:   1. sugar   (g)   — sugarPer100g from Foods
  // TODO:   2. sodium  (mg)  — sodiumPer100g from Foods
  // TODO:   3. potassium (mg) — potassiumPer100g from Foods
  // TODO:   4. calcium (mg)  — calciumPer100g from Foods
  // TODO:   5. iron    (mg)  — ironPer100g from Foods
  // TODO: The BergamotNutrition entity already computes all 10 fields; only
  // TODO: the MealEntries table schema and the addMeal() call need updating.
  // TODO: This means daily-summary aggregation (TodayNutrition) also cannot
  // TODO: show these 5 micronutrients until MealEntries is extended.

  // ─── Metadata ────────────────────────────────────────────────────────

  /// یادداشت اختیاری کاربر
  TextColumn get notes => text().nullable()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
