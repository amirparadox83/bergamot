import 'package:drift/drift.dart' hide Column;
import 'bergamot_database.dart';

/// دیتابیس دیتابیس قالب‌های غذایی
/// ذخیره، بازیابی و استفاده مجدد از ترکیب غذاها
class MealTemplateDao {
  final BergamotDatabase db;
  MealTemplateDao(this.db);

  /// همه قالب‌ها به ترتیب زمان ایجاد نزولی
  Future<List<MealTemplate>> getAllTemplates() {
    return (db.select(db.mealTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// آیتم‌های یک قالب
  Future<List<MealTemplateItem>> getItems(int templateId) {
    return (db.select(db.mealTemplateItems)
          ..where((t) => t.templateId.equals(templateId)))
        .get();
  }

  /// ذخیره قالب جدید از لیست وعده‌های غذایی
  Future<int> saveTemplate(
    String name,
    int mealType,
    List<MealEntry> items,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    double totalCal = 0, totalPro = 0, totalFat = 0, totalCarb = 0;
    for (final item in items) {
      totalCal += item.calories;
      totalPro += item.protein;
      totalFat += item.fat;
      totalCarb += item.carb;
    }

    final templateId = await db.into(db.mealTemplates).insert(
      MealTemplatesCompanion.insert(
        name: name,
        mealType: mealType,
        totalCalories: totalCal,
        totalProtein: totalPro,
        totalFat: totalFat,
        totalCarb: totalCarb,
        createdAt: now,
      ),
    );

    await db.transaction(() async {
      for (final item in items) {
        await db.into(db.mealTemplateItems).insert(
          MealTemplateItemsCompanion.insert(
            templateId: templateId,
            foodId: item.foodId ?? 0, // 0 = orphaned (food deleted)
            foodName: item.foodName,
            servingCount: item.servingCount,
            calories: item.calories,
            protein: item.protein,
            fat: item.fat,
            carb: item.carb,
          ),
        );
      }
    });

    return templateId;
  }

  /// حذف قالب و آیتم‌های آن
  Future<void> deleteTemplate(int id) async {
    await (db.delete(db.mealTemplateItems)
          ..where((t) => t.templateId.equals(id)))
        .go();
    await (db.delete(db.mealTemplates)..where((t) => t.id.equals(id))).go();
  }

  /// استفاده از قالب: ثبت آیتم‌ها به‌عنوان وعده غذایی در تاریخ مشخص
  Future<void> useTemplate(int templateId, int dateMs) async {
    final items = await getItems(templateId);
    final template = await (db.select(db.mealTemplates)
          ..where((t) => t.id.equals(templateId)))
        .getSingleOrNull();
    if (template == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction(() async {
      for (final item in items) {
        await db.into(db.mealEntries).insert(
          MealEntriesCompanion.insert(
            date: dateMs,
            mealType: template.mealType,
            foodId: Value(item.foodId),
            foodName: item.foodName,
            servingCount: Value(item.servingCount),
            calories: item.calories,
            protein: item.protein,
            fat: item.fat,
            carb: item.carb,
            createdAt: now,
          ),
        );
      }
    });
  }
}
