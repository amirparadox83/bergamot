import 'package:drift/drift.dart';
import 'habit_table.dart';

/// جدول ثبت عادت‌ها
/// هر رکورد نشان‌دهنده انجام یا عدم انجام یک عادت در یک روز خاص است
/// برای محاسبه Streak و آمار عادت‌ها استفاده می‌شود
class HabitLogs extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه عادت (کلید خارجی به Habits)
  IntColumn get habitId => integer().references(Habits, #id)();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// آیا عادت در این روز انجام شده است؟ - پیش‌فرض خیر
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// زمان انجام عادت (اختیاری)
  IntColumn get completedAt => integer().nullable()();
}