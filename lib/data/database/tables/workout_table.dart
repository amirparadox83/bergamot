import 'package:drift/drift.dart';

/// جدول جلسات تمرین — schema v7
///
/// هر جلسه یک اجرای واقعی یک Workout Template (یا custom) توسط کاربر است.
/// این جدول session history است و از WorkoutTemplates جدا می‌باشد.
///
/// در v7 فیلدهای جدید اضافه شد:
///   - templateId: اگر جلسه از یک template آماده آمده باشد
///   - totalReps, totalSets: snapshot آمار جلسه
///   - estimatedCalories: snapshot کالری (rule-based, no AI)
///   - isRestDay: اگر این روز rest day برنامه بوده
class Workouts extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// نام جلسه تمرین
  TextColumn get name => text()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// زمان شروع تمرین به میلی‌ثانیه Epoch
  IntColumn get startTime => integer()();

  /// زمان پایان تمرین (اختیاری، تا زمانی که تمام نشده null است)
  IntColumn get endTime => integer().nullable()();

  /// مدت تمرین به دقیقه (اختیاری)
  IntColumn get durationMinutes => integer().nullable()();

  /// یادداشت اختیاری کاربر
  TextColumn get notes => text().nullable()();

  /// آیا جلسه تمرین تکمیل شده است؟
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  // ── فیلدهای جدید v7 ────────────────────────────────────────────────────

  /// شناسه WorkoutTemplate که این جلسه از آن ایجاد شده
  /// NULL = جلسه custom بدون template
  IntColumn get templateId =>
      integer().nullable().customConstraint('REFERENCES workout_templates(id) ON DELETE SET NULL')();

  /// مجموع تکرارهای جلسه (snapshot)
  IntColumn get totalReps => integer().nullable()();

  /// مجموع ست‌های جلسه (snapshot)
  IntColumn get totalSets => integer().nullable()();

  /// تخمین کالری جلسه (rule-based, no AI)
  /// محاسبه از sum(reps × caloriesEstimatePerRep) برای هر exercise
  IntColumn get estimatedCalories => integer().nullable()();

  /// آیا این روز rest day برنامه بوده؟
  /// اگر true باشد، streak نباید خراب شود.
  BoolColumn get isRestDay => boolean().withDefault(const Constant(false))();

  // ── Legacy ─────────────────────────────────────────────────────────────

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
