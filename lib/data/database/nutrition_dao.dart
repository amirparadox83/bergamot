import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// DAO دیتابیس تغذیه
/// مدیریت وعده‌های غذایی، جستجوی غذا، آمار کالری و ماکرو
///
/// تمام جستجوها روی normalizedNameFa / normalizedNameEn انجام می‌شود
/// (نه nameFa مستقیم) تا از ی/ی، ک/ک، ZWNJ، فاصله‌های اضافی و lowercase
/// به‌درستی handle شوند.
class NutritionDao {
  final BergamotDatabase db;
  NutritionDao(this.db);

  // ────────────────────────────────────────────────────────────────────
  // Meal queries (unchanged — kept for backward compat)
  // ────────────────────────────────────────────────────────────────────
  /// واچ وعده‌های غذایی امروز
  Stream<List<MealEntry>> watchTodayMeals() {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 24 * 60 * 60 * 1000 - 1;  // انتهای روز شامل
    return (db.select(db.mealEntries)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.mealType)]))
        .watch();
  }

  /// وعده‌های غذایی یک تاریخ خاص
  Future<List<MealEntry>> getMealsByDate(int date) {
    final endOfDay = date + 24 * 60 * 60 * 1000 - 1;  // انتهای روز شامل
    return (db.select(db.mealEntries)
          ..where((t) => t.date.isBetweenValues(date, endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.mealType)]))
        .get();
  }

  /// ثبت وعده غذایی جدید
  Future<int> insertMeal(MealEntriesCompanion entry) {
    return db.into(db.mealEntries).insert(entry);
  }

  /// حذف وعده غذایی
  Future<int> deleteMeal(int id) {
    return (db.delete(db.mealEntries)..where((t) => t.id.equals(id))).go();
  }

  /// مجموع کالری دریافتی در یک تاریخ
  Future<double> getDailyCalories(int date) {
    final endOfDay = date + 24 * 60 * 60 * 1000 - 1;  // انتهای روز شامل
    final query = db.selectOnly(db.mealEntries)
      ..addColumns([db.mealEntries.calories.sum()])
      ..where(db.mealEntries.date.isBetweenValues(date, endOfDay));
    return query
        .getSingleOrNull()
        .then((row) => row?.read(db.mealEntries.calories.sum()) ?? 0);
  }

  /// مجموع ماکروهای غذایی در یک تاریخ
  Future<({double protein, double fat, double carb})> getDailyMacros(
      int date) {
    final endOfDay = date + 24 * 60 * 60 * 1000 - 1;  // انتهای روز شامل
    final query = db.selectOnly(db.mealEntries)
      ..addColumns([
        db.mealEntries.protein.sum(),
        db.mealEntries.fat.sum(),
        db.mealEntries.carb.sum(),
      ])
      ..where(db.mealEntries.date.isBetweenValues(date, endOfDay));
    return query.getSingleOrNull().then((row) => (
          protein: row?.read(db.mealEntries.protein.sum()) ?? 0,
          fat: row?.read(db.mealEntries.fat.sum()) ?? 0,
          carb: row?.read(db.mealEntries.carb.sum()) ?? 0,
        ));
  }

  // ────────────────────────────────────────────────────────────────────
  // Food search (PHASE 14 — updated to use normalized fields)
  // ────────────────────────────────────────────────────────────────────
  /// جستجوی غذا بر اساس نام نرمالایز شده (فارسی یا انگلیسی)
  ///
  /// query باید از طریق [BergamotTextNormalizer.normalizeFa] یا
  /// [BergamotTextNormalizer.normalizeEn] عبور کرده باشد تا ی/ی،
  /// ک/ک، ZWNJ و lowercase به‌درستی handle شوند.
  Future<List<Food>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      // بدون عبارت — ۲۰ مورد اول بر اساس نام فارسی
      return (db.select(db.foods)
            ..orderBy([
              (t) => OrderingTerm.asc(t.nameFa),
              (t) => OrderingTerm.asc(t.nameEn),
            ])
            ..limit(20))
          .get();
    }

    // فرار کاراکترهای خاص LIKE (%, _) برای جلوگیری از تزریق
    final escaped = q.replaceAll('%', '\\%').replaceAll('_', '\\_');
    final pattern = '%$escaped%';
    return (db.select(db.foods)
          ..where((t) =>
              t.normalizedNameFa.like(pattern, escape: '\\') |
              t.normalizedNameEn.like(pattern, escape: '\\') |
              t.nameFa.like(pattern, escape: '\\') |
              t.nameEn.like(pattern, escape: '\\'))
          ..orderBy([
            // اول رکوردهای تأییدشده
            (t) => OrderingTerm.desc(t.isVerified),
            // اول رکوردهای با نام فارسی (None → آخر)
            (t) => OrderingTerm(
                  expression: const CustomExpression<int>(
                    "CASE WHEN nameFa IS NULL OR nameFa = '' THEN 1 ELSE 0 END",
                  ),
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm.asc(t.nameFa),
          ])
          ..limit(50))
        .get();
  }

  /// فیلتر غذاها بر اساس دسته‌بندی
  Future<List<Food>> getFoodsByCategory(String categoryId) {
    return (db.select(db.foods)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isVerified),
            (t) => OrderingTerm.asc(t.nameFa),
            (t) => OrderingTerm.asc(t.nameEn),
          ])
          ..limit(200))
        .get();
  }

  /// افزودن غذای سفارشی کاربر
  Future<int> insertFood(FoodsCompanion entry) {
    return db.into(db.foods).insert(entry);
  }

  /// لیست تمام دسته‌بندی‌های غذایی
  Future<List<FoodCategory>> getAllCategories() {
    return (db.select(db.foodCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// گرفتن یک Food با id
  Future<Food?> getFoodById(int id) {
    return (db.select(db.foods)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ────────────────────────────────────────────────────────────────────
  // Recipe queries (PHASE 17)
  // ────────────────────────────────────────────────────────────────────
  /// جستجوی Recipe بر اساس نام نرمالایز شده
  Future<List<Recipe>> searchRecipes(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return (db.select(db.recipes)
            ..orderBy([(t) => OrderingTerm.asc(t.nameFa)])
            ..limit(20))
          .get();
    }
    final pattern = '%$q%';
    // TODO(Stage-29): Add regression test for SQL injection in recipe search — escape % and _ characters like searchFoods does. See https://github.com/.../issues/SQL-ESCAPE-RECIPES
    // TODO: Escape LIKE special characters (%, _) in recipe search
    // like searchFoods does, for consistency and security.
    return (db.select(db.recipes)
          ..where((t) =>
              t.normalizedNameFa.like(pattern) |
              t.normalizedNameEn.like(pattern) |
              t.nameFa.like(pattern) |
              t.nameEn.like(pattern))
          ..orderBy([(t) => OrderingTerm.asc(t.nameFa)])
          ..limit(20))
        .get();
  }

  /// مواد اولیه یک Recipe به همراه Food هر کدام
  Future<List<({RecipeIngredient ingredient, Food food})>>
      getRecipeIngredients(int recipeId) async {
    final query = db.select(db.recipeIngredients).join([
      innerJoin(db.foods, db.foods.id.equalsExp(db.recipeIngredients.foodId)),
    ])
      ..where(db.recipeIngredients.recipeId.equals(recipeId))
      ..orderBy([OrderingTerm.asc(db.recipeIngredients.orderIndex)]);
    final rows = await query.get();
    return rows.map((row) {
      final ing = row.readTable(db.recipeIngredients);
      final food = row.readTable(db.foods);
      return (ingredient: ing, food: food);
    }).toList();
  }

  /// یک Recipe با id
  Future<Recipe?> getRecipeById(int id) {
    return (db.select(db.recipes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
