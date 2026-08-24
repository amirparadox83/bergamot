import 'package:drift/drift.dart';

/// جدول ثبت وزن
/// هر رکورد یک بار وزن‌کشی کاربر را ثبت می‌کند
/// برای نمودار پیشرفت وزن و محاسبه BMI استفاده می‌شود
class WeightEntries extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// وزن به کیلوگرم
  RealColumn get weightKg => real()();

  /// یادداشت اختیاری کاربر
  TextColumn get note => text().nullable()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
