import '../../data/database/bergamot_database.dart';

/// محاسبه‌گر Streak و Progress Bergamot (PHASE 15/19)
///
/// تمام محاسبات rule-based هستند — نه AI.
///
/// Streak:
///   - زنجیره روزهای متوالی که کاربر تمرین کرده (یا rest day برنامه بوده)
///   - اگر کاربر یک روز کاری انجام داده و بعدی rest است، streak خراب نمی‌شود
///   - اگر کاربر یک روز کاری انجام نداده و rest نبوده، streak = 0
class BergamotStreakCalculator {
  BergamotStreakCalculator._();

  /// محاسبه current streak
  ///
  /// workouts: لیست جلسات تمرین تکمیل‌شده (مرتب بر اساس date DESC)
  /// programDays: لیست روزهای program فعلی (در صورت وجود)
  /// programStartDate: تاریخ شروع program فعلی (برای محاسبه day number)
  ///
  /// منطق:
  ///   - از امروز به عقب می‌رویم
  ///   - هر روز که یا تمرین داشته یا rest day باشد → streak++
  ///   - اگر یک روز نه تمرین و نه rest → break
  ///   - اگر programDays موجود باشد و روز جاری در برنامه rest day باشد → streak++
  ///   - اگر programDays خالی باشد یا programStartDate NULL → فقط workouts را بررسی می‌کنیم
  static int calculateCurrentStreak({
    required List<Workout> workouts,
    List<WorkoutProgramDay>? programDays,
    DateTime? programStartDate,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final todayMs = todayDate.millisecondsSinceEpoch;

    // Pre-build a Set of workout dates for O(1) lookup instead of O(n) .any() per day
    final workoutDates = <int>{};
    for (final w in workouts) {
      if (w.isCompleted) {
        // Normalize to midnight for day-level comparison
        final dt = DateTime.fromMillisecondsSinceEpoch(w.date);
        workoutDates.add(DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch);
      }
    }

    final hasWorkoutToday = workoutDates.contains(todayMs);
    var streak = 0;
    var currentDay = hasWorkoutToday ? todayDate : todayDate.subtract(const Duration(days: 1));

    // Maximum 365 days lookback to avoid infinite loop
    for (int i = 0; i < 365; i++) {
      final dayMs = DateTime(currentDay.year, currentDay.month, currentDay.day).millisecondsSinceEpoch;
      final hasWorkout = workoutDates.contains(dayMs);

      // بررسی rest day در program (در صورت وجود)
      bool isRestDay = false;
      if (programDays != null && programDays.isNotEmpty && programStartDate != null) {
        final dayDiff = currentDay.difference(programStartDate).inDays + 1;
        if (dayDiff >= 1 && dayDiff <= programDays.length) {
          final programDay = programDays[dayDiff - 1];
          isRestDay = programDay.isRestDay;
        }
      }

      if (hasWorkout || isRestDay) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// محاسبه longest streak از تاریخچه
  ///
  /// workouts: لیست جلسات تمرین تکمیل‌شده
  static int calculateLongestStreak({
    required List<Workout> workouts,
  }) {
    if (workouts.isEmpty) return 0;

    // استخراج تاریخ‌های یکتای تمرین (مرتب)
    final dates = workouts
        .where((w) => w.isCompleted)
        .map((w) {
          final dt = DateTime.fromMillisecondsSinceEpoch(w.date);
          return DateTime(dt.year, dt.month, dt.day);
        })
        .toSet()
        .toList()
      ..sort();

    if (dates.isEmpty) return 0;

    int longest = 1;
    int current = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        // متوالی
        current++;
        if (current > longest) longest = current;
      } else if (diff == 2) {
        // یک روز gap — احتمالاً rest day
        // streak خراب نمی‌شود (طبق spec کاربر)
        current++;
        if (current > longest) longest = current;
      } else {
        // gap بزرگ → reset
        current = 1;
      }
    }

    return longest;
  }

  /// محاسبه آمار هفتگی
  ///
  /// برمی‌گرداند: (workoutsCount, totalMinutes, totalCalories)
  static ({int workouts, int minutes, int calories}) calculateWeeklyStats(
      List<Workout> workouts) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    final weekWorkouts = workouts.where((w) =>
        w.date >= weekAgo && w.isCompleted).toList();

    final minutes = weekWorkouts.fold<int>(0, (sum, w) => sum + (w.durationMinutes ?? 0));
    final calories = weekWorkouts.fold<int>(0, (sum, w) => sum + (w.estimatedCalories ?? 0));

    return (workouts: weekWorkouts.length, minutes: minutes, calories: calories);
  }

  /// محاسبه آمار ماهانه
  static ({int workouts, int minutes, int calories}) calculateMonthlyStats(
      List<Workout> workouts) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    final monthWorkouts = workouts.where((w) =>
        w.date >= monthAgo && w.isCompleted).toList();

    final minutes = monthWorkouts.fold<int>(0, (sum, w) => sum + (w.durationMinutes ?? 0));
    final calories = monthWorkouts.fold<int>(0, (sum, w) => sum + (w.estimatedCalories ?? 0));

    return (workouts: monthWorkouts.length, minutes: minutes, calories: calories);
  }

  /// داده سری ۷ روز اخیر برای نمودار
  ///
  /// برمی‌گرداند: لیستی از (date, workoutCount, calories)
  static List<({DateTime date, int workouts, int calories})> last7DaysSeries(
      List<Workout> workouts) {
    final now = DateTime.now();
    final result = <({DateTime date, int workouts, int calories})>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayStart = day.millisecondsSinceEpoch;
      final dayEnd = dayStart + 24 * 60 * 60 * 1000;
      final dayWorkouts = workouts.where((w) =>
          w.date >= dayStart && w.date < dayEnd && w.isCompleted).toList();
      final calories = dayWorkouts.fold<int>(0, (sum, w) => sum + (w.estimatedCalories ?? 0));
      result.add((date: day, workouts: dayWorkouts.length, calories: calories));
    }
    return result;
  }

  /// داده سری ۳۰ روز اخیر برای نمودار
  static List<({DateTime date, int workouts, int calories})> last30DaysSeries(
      List<Workout> workouts) {
    final now = DateTime.now();
    final result = <({DateTime date, int workouts, int calories})>[];

    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayStart = day.millisecondsSinceEpoch;
      final dayEnd = dayStart + 24 * 60 * 60 * 1000;
      final dayWorkouts = workouts.where((w) =>
          w.date >= dayStart && w.date < dayEnd && w.isCompleted).toList();
      final calories = dayWorkouts.fold<int>(0, (sum, w) => sum + (w.estimatedCalories ?? 0));
      result.add((date: day, workouts: dayWorkouts.length, calories: calories));
    }
    return result;
  }

  /// داده سری ۹۰ روز اخیر — هفتگی aggregation
  static List<({DateTime weekStart, int workouts, int calories})> last90DaysSeries(
      List<Workout> workouts) {
    final now = DateTime.now();
    final result = <({DateTime weekStart, int workouts, int calories})>[];

    // ۱۳ هفته اخیر
    for (int week = 12; week >= 0; week--) {
      final weekEnd = DateTime(now.year, now.month, now.day).subtract(Duration(days: week * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));
      final weekStartMs = weekStart.millisecondsSinceEpoch;
      final weekEndMs = weekEnd.millisecondsSinceEpoch;
      final weekWorkouts = workouts.where((w) =>
          w.date >= weekStartMs && w.date < weekEndMs && w.isCompleted).toList();
      final calories = weekWorkouts.fold<int>(0, (sum, w) => sum + (w.estimatedCalories ?? 0));
      result.add((weekStart: weekStart, workouts: weekWorkouts.length, calories: calories));
    }
    return result;
  }
}
