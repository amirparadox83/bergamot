import 'package:drift/drift.dart';

/// جدول مواد غذایی Bergamot — schema v5
///
/// مقادیر غذایی canonical بر اساس 100 گرم هستند (per-100g).
/// مقادیر per-serving (در صورتی که موجود باشد) صرفاً برای نمایش پیش‌فرض
/// serving size به کاربر استفاده می‌شود و محاسبات همیشه از per-100g × گرم
/// انجام می‌شود.
///
/// منبع داده‌ها (source):
///   - USDA_FOUNDATION     : USDA Foundation Foods 2026-04-30
///   - USDA_SR_LEGACY      : USDA SR Legacy 2018-04
///   - USDA_FNDDS          : USDA FNDDS / Survey 2024-10-31
///   - IRANIAN_REFERENCE   : منابع ایرانی مورد اعتماد (دست‌ساز Bergamot)
///   - CUSTOM              : غذای سفارشی کاربر
///   - IRANIAN_RECIPE      : (مربوط به جدول Recipes — در این جدول نیست)
///
/// وضعیت تأیید (verificationStatus):
///   - VERIFIED              : منبع معتبر، مقادیر تغذیه‌ای قابل اعتماد
///   - NEEDS_VERIFICATION   : رکورد موجود ولی مقدار فارسی/تغذیه‌ای نهایی نشده
///   - COMMUNITY_RECIPE      : (فقط در جدول Recipes) دستور خانگی، تقریبی
class Foods extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  // ── نام ────────────────────────────────────────────────────────────
  /// نام فارسی غذا (در صورت نبود، از nameEn استفاده می‌شود)
  TextColumn get nameFa => text().nullable()();

  /// نام انگلیسی (USDA description یا معادل)
  TextColumn get nameEn => text()();

  /// نسخه نرمالایز شده فارسی (ي→ی، ك→ک، ZWNJ→space، lowercase) — برای search
  TextColumn get normalizedNameFa =>
      text().nullable().withDefault(const Constant(''))();

  /// نسخه نرمالایز شده انگلیسی — برای search
  TextColumn get normalizedNameEn =>
      text().withDefault(const Constant(''))();

  // ── دسته‌بندی ─────────────────────────────────────────────────────
  /// کد دسته‌بندی Bergamot (FK به جدول FoodCategories.code)
  /// مقادیر: fruits, vegetables, legumes, grains, rice, bread, dairy, meat,
  ///         poultry, fish_seafood, eggs, nuts, seeds, oils_fats, breakfast,
  ///         beverages, snacks, sweets, spices_herbs, sauces, iranian_foods, other
  TextColumn get categoryId => text().withDefault(const Constant('other'))();

  // ── مقادیر تغذیه‌ای canonical (per 100g) ───────────────────────────
  /// کالری (kcal) در 100 گرم — NULL یعنی داده موجود نیست (هرگز صفر جعلی)
  RealColumn get caloriesPer100g => real().nullable()();

  /// پروتئین (g) در 100 گرم
  RealColumn get proteinPer100g => real().nullable()();

  /// چربی (g) در 100 گرم
  RealColumn get fatPer100g => real().nullable()();

  /// کربوهیدرات (g) در 100 گرم
  RealColumn get carbsPer100g => real().nullable()();

  /// فیبر (g) در 100 گرم
  RealColumn get fiberPer100g => real().nullable()();

  /// شکر (g) در 100 گرم
  RealColumn get sugarPer100g => real().nullable()();

  /// سدیم (mg) در 100 گرم
  RealColumn get sodiumPer100g => real().nullable()();

  /// پتاسیم (mg) در 100 گرم
  RealColumn get potassiumPer100g => real().nullable()();

  /// کلسیم (mg) در 100 گرم
  RealColumn get calciumPer100g => real().nullable()();

  /// آهن (mg) در 100 گرم
  RealColumn get ironPer100g => real().nullable()();

  // ── Serving ───────────────────────────────────────────────────────
  /// اندازه سروینگ پیش‌فرض به گرم (در صورت وجود از USDA food_portion)
  /// در صورت نبود، NULL — کاربر می‌تواند ۱۰۰ گرم فرض کند
  RealColumn get servingSize => real().nullable()();

  /// واحد سروینگ: gram / piece / spoon / glass / palm / plate / serving
  TextColumn get servingUnit =>
      text().withDefault(const Constant('gram'))();

  /// توضیح فارسی سروینگ (مثلاً "۱ لیوان" یا "۱ عدد متوسط")
  TextColumn get servingDescriptionFa => text().nullable()();

  /// توضیح انگلیسی سروینگ (USDA portion_description)
  TextColumn get servingDescriptionEn => text().nullable()();

  // ── Provenance ─────────────────────────────────────────────────────
  /// منبع داده (USDA_FOUNDATION / USDA_SR_LEGACY / USDA_FNDDS /
  /// IRANIAN_REFERENCE / CUSTOM)
  TextColumn get source =>
      text().withDefault(const Constant('CUSTOM'))();

  /// شناسه خارجی (مثلاً "USDA_FOUNDATION:321358" یا "IRANIAN_REF:EGG")
  TextColumn get externalId => text().nullable()();

  /// بارکد محصول (در صورت وجود — برای آینده برای Open Food Facts)
  TextColumn get barcode => text().nullable()();

  /// نام برند (در صورت وجود)
  TextColumn get brand => text().nullable()();

  // ── Verification ───────────────────────────────────────────────────
  /// آیا غذا سفارشی کاربر است؟
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// آیا منبع تأیید شده است؟
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();

  /// وضعیت تأیید: VERIFIED / NEEDS_VERIFICATION
  TextColumn get verificationStatus =>
      text().withDefault(const Constant('NEEDS_VERIFICATION'))();

  /// وضعیت آماده‌سازی: raw / cooked / boiled / fried / baked / ...
  TextColumn get preparationState => text().nullable()();

  // ── Timestamps ─────────────────────────────────────────────────────
  /// زمان ایجاد رکورد (epoch ms)
  IntColumn get createdAt => integer()();

  /// زمان آخرین به‌روزرسانی رکورد (epoch ms)
  IntColumn get updatedAt => integer().nullable()();

  // ── Legacy compatibility (deprecated — do NOT use in new code) ─────
  /// @deprecated — برای سازگاری با MealEntries قدیمی که این فیلدها را می‌خوانند.
  /// از per-100g × servingSize/100 استفاده کنید.
  RealColumn get caloriesPerServing =>
      real().nullable().withDefault(const Constant(0))();
  RealColumn get proteinPerServing =>
      real().nullable().withDefault(const Constant(0))();
  RealColumn get fatPerServing =>
      real().nullable().withDefault(const Constant(0))();
  RealColumn get carbPerServing =>
      real().nullable().withDefault(const Constant(0))();
  /// @deprecated — از fiberPer100g استفاده کنید
  RealColumn get fiberPerServing =>
      real().nullable().withDefault(const Constant(0))();

  // NOTE: SQLite treats NULL != NULL, so the unique constraint on (externalId, source)
  // won't prevent duplicate rows when externalId is NULL. Application code must
  // enforce uniqueness for custom foods (where externalId is null).
  @override
  List<Set<Column>> get uniqueKeys => [
        // External ID + source یکتا (برای updateهای آینده USDA)
        {externalId, source},
      ];
}
