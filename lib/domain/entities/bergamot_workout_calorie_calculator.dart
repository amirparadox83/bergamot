import '../../data/database/bergamot_database.dart';

/// محاسبه‌گر کالری تمرین Bergamot (PHASE 13/29)
///
/// تمام محاسبات کالری تمرین rule-based هستند — نه AI.
///
/// فرمول:
///   caloriesPerRep × reps × sets  (برای rep-based)
///   caloriesPerMinute × durationMinutes  (برای time-based)
///
/// اگر caloriesEstimatePerRep در دیتابیس NULL باشد:
///   مقادیر پیش‌فرض بر اساس category و difficulty تخمین زده می‌شود.
///
/// این کلاس stateless است.
class BergamotWorkoutCalorieCalculator {
  BergamotWorkoutCalorieCalculator._();

  /// محاسبه کالری یک exercise در یک session
  ///
  /// [sets]: تعداد ست‌ها
  /// [reps]: تعداد تکرار هر ست (NULL برای time-based)
  /// [durationSeconds]: مدت زمان هر ست (NULL برای rep-based)
  /// [weightKg]: وزن استفاده‌شده (NULL برای bodyweight)
  static double calculateExerciseCalories({
    required Exercise exercise,
    required int sets,
    int? reps,
    int? durationSeconds,
    double? weightKg,
  }) {
    if (sets <= 0) return 0;

    // اگر caloriesEstimatePerRep موجود بود از آن استفاده کن
    if (exercise.caloriesEstimatePerRep != null && exercise.caloriesEstimatePerRep! > 0) {
      if (exercise.isTimed && durationSeconds != null && durationSeconds > 0) {
        // time-based: caloriesEstimatePerRep × (durationSeconds / 30)
        // هر 30 ثانیه یک "rep" حساب می‌شود (rule-based, نه AI)
        final effectiveReps = (durationSeconds / 30).ceil();
        return exercise.caloriesEstimatePerRep! * effectiveReps * sets;
      } else if (reps != null && reps > 0) {
        return exercise.caloriesEstimatePerRep! * reps * sets;
      }
    }

    // fallback بر اساس category و difficulty
    final fallbackPerRep = _fallbackCaloriesPerRep(exercise);
    if (exercise.isTimed && durationSeconds != null && durationSeconds > 0) {
      final effectiveReps = (durationSeconds / 30).ceil();
      return fallbackPerRep * effectiveReps * sets;
    } else if (reps != null && reps > 0) {
      return fallbackPerRep * reps * sets;
    }
    return 0;
  }

  /// تخمین کالری به‌ازای هر تکرار بر اساس category و difficulty
  /// (rule-based fallback وقتی caloriesEstimatePerRep NULL است)
  static double _fallbackCaloriesPerRep(Exercise ex) {
    // مقادیر استاندارد صنعت fitness (نه AI)
    switch (ex.category) {
      case 'cardio':
        return ex.difficulty == 3 ? 0.6 : (ex.difficulty == 2 ? 0.4 : 0.25);
      case 'leg':
      case 'glute':
        return ex.difficulty == 3 ? 0.5 : (ex.difficulty == 2 ? 0.35 : 0.25);
      case 'chest':
      case 'back':
        return ex.difficulty == 3 ? 0.45 : (ex.difficulty == 2 ? 0.3 : 0.2);
      case 'core':
        return ex.difficulty == 3 ? 0.35 : (ex.difficulty == 2 ? 0.25 : 0.18);
      case 'shoulder':
      case 'bicep':
      case 'tricep':
        return ex.difficulty == 3 ? 0.3 : (ex.difficulty == 2 ? 0.22 : 0.15);
      case 'stretch':
        return 0.08;
      default:
        return 0.2;
    }
  }

  /// محاسبه کالری کل یک جلسه تمرین
  ///
  /// items: لیستی از (exercise + sets + reps/duration)
  static double calculateWorkoutCalories(
    List<({Exercise exercise, int sets, int? reps, int? durationSeconds, double? weightKg})> items,
  ) {
    double total = 0;
    for (final item in items) {
      total += calculateExerciseCalories(
        exercise: item.exercise,
        sets: item.sets,
        reps: item.reps,
        durationSeconds: item.durationSeconds,
        weightKg: item.weightKg,
      );
    }
    return total;
  }

  /// محاسبه total reps و total sets یک جلسه
  static ({int totalReps, int totalSets}) calculateWorkoutStats(
    List<({int sets, int? reps})> items,
  ) {
    int totalReps = 0;
    int totalSets = 0;
    for (final item in items) {
      totalSets += item.sets;
      if (item.reps != null) {
        totalReps += item.sets * item.reps!;
      }
    }
    return (totalReps: totalReps, totalSets: totalSets);
  }
}
