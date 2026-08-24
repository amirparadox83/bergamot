import 'package:drift/drift.dart';

/// جدول دستور پخت‌ها (Recipes) — غذاهای ایرانی و ترکیبی
///
/// هر Recipe مجموعه‌ای از Food (مواد اولیه) با مقدار گرم مشخص است.
/// کالری و ماکروهای Recipe از مجموع مواد اولیه محاسبه می‌شود،
/// نه از یک عدد ثابت جعلی.
///
/// نمونه:
///   Ghormeh Sabzi:
///     - Lamb raw 500g
///     - Kidney beans raw 200g
///     - ...
///     yield = 1200g, serving = 300g
///     calories per serving = (sum of ingredient calories) × serving / yield
class Recipes extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// نام فارسی
  TextColumn get nameFa => text()();

  /// نام انگلیسی
  TextColumn get nameEn => text()();

  /// نسخه نرمالایز شده فارسی
  TextColumn get normalizedNameFa => text().withDefault(const Constant(''))();

  /// نسخه نرمالایز شده انگلیسی
  TextColumn get normalizedNameEn => text().withDefault(const Constant(''))();

  /// کد دسته‌بندی (FK به FoodCategories.code)
  TextColumn get categoryId =>
      text().withDefault(const Constant('iranian_foods'))();

  /// مجموع وزن خروجی Recipe به گرم
  /// (مثلاً 1200g قرمه‌سبزی)
  RealColumn get totalYieldGrams => real()();

  /// اندازه سروینگ پیش‌فرض به گرم
  RealColumn get servingSize => real()();

  /// واحد سروینگ: gram / plate / bowl / piece
  TextColumn get servingUnit =>
      text().withDefault(const Constant('plate'))();

  /// توضیح فارسی سروینگ (مثلاً "یک بشقاب")
  TextColumn get servingDescriptionFa => text().nullable()();

  /// منبع: IRANIAN_RECIPE / COMMUNITY / CUSTOM
  TextColumn get source =>
      text().withDefault(const Constant('IRANIAN_RECIPE'))();

  /// وضعیت تأیید: COMMUNITY_RECIPE / VERIFIED / NEEDS_VERIFICATION
  TextColumn get verificationStatus =>
      text().withDefault(const Constant('COMMUNITY_RECIPE'))();

  /// آیا Recipe سفارشی کاربر است؟
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// یادداشت اختیاری (مثلاً "غذای خانگی، مقادیر تقریبی")
  TextColumn get notes => text().nullable()();

  /// زمان ایجاد
  IntColumn get createdAt => integer()();

  /// زمان آخرین به‌روزرسانی
  IntColumn get updatedAt => integer().nullable()();
}

/// جدول مواد اولیه هر Recipe (junction table)
///
/// هر رکورد یک ماده اولیه با مقدار گرم در Recipe مشخص است.
/// Food با FK به Foods — برای محاسبه nutrition از per-100g × grams/100.
class RecipeIngredients extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه Recipe (FK به Recipes.id)
  IntColumn get recipeId => integer()();

  /// شناسه Food (FK به Foods.id) — ماده اولیه
  IntColumn get foodId => integer()();

  /// مقدار گرم این ماده اولیه در Recipe
  RealColumn get grams => real()();

  /// ترتیب نمایش ماده اولیه (اختیاری)
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
