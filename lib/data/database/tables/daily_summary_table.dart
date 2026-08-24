import 'package:drift/drift.dart';

/// جدول خلاصه روزانه (متریالیزه)
/// هر رکورد خلاصه‌ای از تمام فعالیت‌های یک روز را در بر می‌گیرد
/// این جدول برای نمایش سریع صفحه Home و نمودارها استفاده می‌شود
/// date یکتاست یعنی برای هر روز فقط یک رکورد خلاصه وجود دارد
class DailySummaries extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز) - یکتا
  IntColumn get date => integer().unique()();

  /// مجموع کالری دریافتی - پیش‌فرض صفر
  RealColumn get totalCalories => real().withDefault(const Constant(0))();

  /// مجموع پروتئین (گرم) - پیش‌فرض صفر
  RealColumn get totalProtein => real().withDefault(const Constant(0))();

  /// مجموع چربی (گرم) - پیش‌فرض صفر
  RealColumn get totalFat => real().withDefault(const Constant(0))();

  /// مجموع کربوهیدرات (گرم) - پیش‌فرض صفر
  RealColumn get totalCarb => real().withDefault(const Constant(0))();

  /// مجموع آب (میلی‌لیتر) - پیش‌فرض صفر
  IntColumn get totalWaterMl => integer().withDefault(const Constant(0))();

  /// مدت خواب به دقیقه
  IntColumn get sleepDurationMinutes => integer().nullable()();

  /// کیفیت خواب
  IntColumn get sleepQuality => integer().nullable()();

  /// مدت تمرین به دقیقه
  IntColumn get workoutMinutes => integer().nullable()();

  /// حجم تمرین (وزن × تکرار)
  RealColumn get workoutVolume => real().nullable()();

  /// امتیاز سبک زندگی (محاسبه‌شده توسط Rule Engine)
  RealColumn get lifestyleScore => real().nullable()();

  /// زمان ایجاد یا بروزرسانی رکورد
  IntColumn get createdAt => integer()();
}
