import 'package:drift/drift.dart';

/// جدول ثبت آب
/// هر رکورد نشان‌دهنده یک بار نوشیدن آب است
/// مقدار پیش‌فرض ۲۵۰ میلی‌لیتر (یک لیوان استاندارد)
class WaterEntries extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// مقدار آب به میلی‌لیتر - پیش‌فرض ۲۵۰
  IntColumn get amountMl => integer().withDefault(const Constant(250))();

  /// زمان دقیق نوشیدن به میلی‌ثانیه Epoch
  IntColumn get time => integer()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}