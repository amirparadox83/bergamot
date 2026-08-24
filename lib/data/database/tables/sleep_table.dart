import 'package:drift/drift.dart';

/// جدول ثبت خواب
/// هر رکورد مربوط به یک شب خواب کاربر است
/// فیلد date برای query بر اساس روز استفاده می‌شود
/// کیفیت خواب از ۱ (خیلی بد) تا ۵ (عالی) ارزیابی می‌شود
class SleepEntries extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// زمان خواب به میلی‌ثانیه Epoch
  IntColumn get sleepTime => integer()();

  /// زمان بیداری به میلی‌ثانیه Epoch
  IntColumn get wakeTime => integer()();

  /// مدت خواب به دقیقه
  IntColumn get durationMinutes => integer()();

  /// کیفیت خواب: ۱ تا ۵
  IntColumn get quality => integer()();

  /// یادداشت اختیاری کاربر
  TextColumn get notes => text().nullable()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
