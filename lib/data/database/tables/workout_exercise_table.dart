import 'package:drift/drift.dart';
import 'exercise_table.dart';
import 'workout_table.dart';

/// جدول تمرینات داخل یک جلسه — schema v7
///
/// هر رکورد یک تمرین خاص در یک جلسه خاص را نشان می‌دهد.
/// فیلدهای exerciseName غیرنرمال شده‌اند تا بدون join خوانده شوند.
/// فیلدهای lastWeightKg و lastReps برای Progressive Overload استفاده می‌شوند.
///
/// در v7 فیلدهای جدید:
///   - durationSeconds: برای time-based exercises (مثل Plank)
///   - isTimed: آیا این تمرین زمان‌محور است؟
class WorkoutExercises extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه جلسه تمرین (FK به Workouts)
  IntColumn get workoutId =>
      integer().references(Workouts, #id)();

  /// شناسه تمرین مرجع (FK به Exercises)
  IntColumn get exerciseId =>
      integer().nullable().references(Exercises, #id)();

  /// نام تمرین (snapshot — غیرنرمال‌سازی برای نمایش سریع و حفظ تاریخچه)
  TextColumn get exerciseName => text()();

  /// ترتیب نمایش تمرین در جلسه
  IntColumn get orderIndex => integer()();

  /// تعداد ست‌ها
  IntColumn get sets => integer()();

  /// تعداد تکرار هر ست (اختیاری)
  /// برای time-based exercises این NULL می‌شود
  IntColumn get reps => integer().nullable()();

  /// وزن هر ست به کیلوگرم (اختیاری)
  RealColumn get weightKg => real().nullable()();

  /// زمان استراحت بین ست‌ها به ثانیه - پیش‌فرض ۹۰ ثانیه
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();

  /// آیا این تمرین تکمیل شده است؟
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// آخرین وزن استفاده‌شده (برای Progressive Overload)
  RealColumn get lastWeightKg => real().nullable()();

  /// آخرین تعداد تکرار (برای Progressive Overload)
  IntColumn get lastReps => integer().nullable()();

  // ── فیلدهای جدید v7 ────────────────────────────────────────────────────

  /// مدت زمان هر ست به ثانیه (برای time-based exercises مثل Plank)
  /// NULL برای rep-based exercises
  IntColumn get durationSeconds => integer().nullable()();

  /// آیا این تمرین زمان‌محور است؟
  /// true برای Plank, Wall Sit و ...
  /// false برای Push-up, Squat و ...
  BoolColumn get isTimed => boolean().withDefault(const Constant(false))();
}
