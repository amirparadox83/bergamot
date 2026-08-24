import 'package:drift/drift.dart';

/// جدول برنامه روزانه
/// آیتم‌های برنامه روزانه شامل بیداری، وعده‌های غذایی، تمرین و آب
class DailyPlans extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه از Epoch (شروع روز)
  IntColumn get date => integer()();

  /// عنوان آیتم — مثلاً 'بیداری', 'صبحانه'
  TextColumn get itemTitle => text()();

  /// زمان پیشنهادی به میلی‌ثانیه از Epoch
  IntColumn get scheduledTime => integer()();

  /// مدت به دقیقه (اختیاری)
  IntColumn get durationMinutes => integer().nullable()();

  /// دسته‌بندی: 'sleep', 'meal', 'workout', 'water', 'habit', 'other'
  TextColumn get category => text()();

  /// آیا انجام شده
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// زمان تکمیل به میلی‌ثانیه (اختیاری)
  IntColumn get completedAt => integer().nullable()();

  /// آیا کاربر زمان را تغییر داده
  BoolColumn get isUserModified => boolean().withDefault(const Constant(false))();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
