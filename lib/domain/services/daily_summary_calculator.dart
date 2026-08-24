import 'package:drift/drift.dart';

import '../../data/database/bergamot_database.dart';
import '../../data/database/sleep_dao.dart';
import '../../data/database/nutrition_dao.dart';
import '../../data/database/hydration_dao.dart';
import '../../data/database/exercise_dao.dart';
import '../rule_engine/rule_engine.dart';
import '../rule_engine/rule_base.dart';

/// ماشین حساب خلاصه روزانه برگاموت
///
/// تمام داده‌های امروز را از دیتابیس جمع‌آوری کرده،
/// امتیاز سبک زندگی را محاسبه کرده و
/// یک [DailySummariesCompanion] آماده برای upsert برمی‌گرداند
class DailySummaryCalculator {
  final BergamotDatabase db;

  DailySummaryCalculator(this.db);

  /// محاسبه خلاصه امروز و بازگرداندن Companion آماده upsert
  ///
  /// اگر داده‌ای وجود نداشته باشد، مقادیر پیش‌فرض/Null استفاده می‌شود
  static Future<DailySummariesCompanion> calculateTodaySummary(
      BergamotDatabase db) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 24 * 60 * 60 * 1000;

    final sleepDao = SleepDao(db);
    final nutritionDao = NutritionDao(db);
    final hydrationDao = HydrationDao(db);
    final exerciseDao = ExerciseDao(db);

    // ── خواب ──
    final sleepEntries =
        await sleepDao.getSleepByDateRange(startOfDay, endOfDay);
    int? sleepDuration;
    int? sleepQuality;
    if (sleepEntries.isNotEmpty) {
      sleepDuration =
          sleepEntries.fold<int>(0, (sum, e) => sum + e.durationMinutes);
      final qualitySum =
          sleepEntries.fold<int>(0, (sum, e) => sum + e.quality);
      sleepQuality = (qualitySum / sleepEntries.length).round();
    }

    // ── تغذیه ──
    final totalCalories = await nutritionDao.getDailyCalories(startOfDay);
    final macros = await nutritionDao.getDailyMacros(startOfDay);

    // ── آب ──
    final waterEntries =
        await hydrationDao.getWaterByDateRange(startOfDay, endOfDay);
    final totalWaterMl =
        waterEntries.fold<int>(0, (sum, e) => sum + e.amountMl);

    // ── تمرین ──
    final workouts =
        await exerciseDao.getWorkoutsByDateRange(startOfDay, endOfDay);
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    int? workoutMinutes;
    double? workoutVolume;

    if (completedWorkouts.isNotEmpty) {
      workoutMinutes = completedWorkouts.fold<int>(
          0, (sum, w) => sum + (w.durationMinutes ?? 0));

      // Batch-load all workout exercises in a single query (fixes N+1)
      final workoutIds = completedWorkouts.map((w) => w.id).toList();
      final allExercises = await (db.select(db.workoutExercises)
            ..where((t) => t.workoutId.isIn(workoutIds)))
          .get();

      // Group by workoutId for volume calculation
      final exercisesByWorkout = <int, List<WorkoutExercise>>{};
      for (final ex in allExercises) {
        exercisesByWorkout.putIfAbsent(ex.workoutId, () => []).add(ex);
      }

      double volume = 0;
      for (final w in completedWorkouts) {
        final exercises = exercisesByWorkout[w.id] ?? const [];
        for (final ex in exercises) {
          if (ex.weightKg != null && ex.reps != null && ex.isCompleted) {
            volume += ex.weightKg! * ex.reps! * ex.sets;
          }
        }
      }
      workoutVolume = volume;
    }

    // ── محاسبه امتیاز سبک زندگی ──
    final engine = BergamotRuleEngine.defaultRules();
    final context = RuleContext(
      sleepDurationMinutes: sleepDuration,
      sleepQuality: sleepQuality,
      totalWaterMl: totalWaterMl.toDouble(),
      totalCalories: totalCalories,
      totalProtein: macros.protein,
      totalFat: macros.fat,
      totalCarb: macros.carb,
      hasWorkout: completedWorkouts.isNotEmpty,
      workoutVolumeKg: workoutVolume,
    );
    final evaluations = engine.evaluateAll(context);
    final lifestyleScore = engine.calculateLifestyleScore(evaluations);

    return DailySummariesCompanion(
      date: Value(startOfDay),
      totalCalories: Value(totalCalories),
      totalProtein: Value(macros.protein),
      totalFat: Value(macros.fat),
      totalCarb: Value(macros.carb),
      totalWaterMl: Value(totalWaterMl),
      sleepDurationMinutes: Value(sleepDuration),
      sleepQuality: Value(sleepQuality),
      workoutMinutes: Value(workoutMinutes),
      workoutVolume: Value(workoutVolume),
      lifestyleScore: Value(lifestyleScore),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
  }
}
