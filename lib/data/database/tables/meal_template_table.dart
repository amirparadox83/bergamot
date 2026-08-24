import 'package:drift/drift.dart';
import 'food_table.dart';

/// جدول قالب‌های غذایی
///
/// ترکیبی از غذاها که کاربر می‌تواند با یک بار ثبت مجدداً استفاده کند
/// مثال: «صبحانه همیشگی» شامل نان، پنیر، چای
class MealTemplates extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// نام قالب (مثلاً «صبحانه همیشگی»)
  TextColumn get name => text()();

  /// نوع وعده: ۰=صبحانه، ۱=ناهار، ۲=شام، ۳=میان‌وعده
  IntColumn get mealType => integer()();

  /// مجموع کالری قالب
  RealColumn get totalCalories => real()();

  /// مجموع پروتئین قالب
  RealColumn get totalProtein => real()();

  /// مجموع چربی قالب
  RealColumn get totalFat => real()();

  /// مجموع کربوهیدرات قالب
  RealColumn get totalCarb => real()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}

/// جدول آیتم‌های قالب غذایی
///
/// هر رکورد یک غذای جزو یک قالب را نشان می‌دهد
class MealTemplateItems extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه قالب مرجع
  IntColumn get templateId =>
      integer().references(MealTemplates, #id)();

  /// شناسه غذای مرجع
  IntColumn get foodId => integer().references(Foods, #id)();

  /// نام غذا
  TextColumn get foodName => text()();

  /// تعداد سروینگ
  RealColumn get servingCount => real()();

  /// کالری
  RealColumn get calories => real()();

  /// پروتئین
  RealColumn get protein => real()();

  /// چربی
  RealColumn get fat => real()();

  /// کربوهیدرات
  RealColumn get carb => real()();
}
