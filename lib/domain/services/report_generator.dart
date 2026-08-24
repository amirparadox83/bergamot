import '../../data/database/bergamot_database.dart';
import '../../data/database/sleep_dao.dart';
import '../../data/database/hydration_dao.dart';
import '../../data/database/exercise_dao.dart';
import '../../data/database/weight_dao.dart';
import '../../data/database/summary_dao.dart';
import '../rule_engine/rule_engine.dart';
import '../rule_engine/rule_base.dart';
import 'report_data.dart';

/// تولیدکننده گزارش سلامت برگاموت
///
/// داده‌های دوره هفتگی یا ماهانه را جمع‌آوری کرده و
/// [ReportData] آماده برای PDF برمی‌گرداند
class ReportGenerator {
  final BergamotDatabase db;

  ReportGenerator(this.db);

  /// تولید گزارش هفتگی
  Future<ReportData> generateWeeklyReport() async {
    final now = DateTime.now();
    // پیدا کردن ابتدای هفته (شنبه در تقویم شمسی)
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _generateReport(weekStart, weekEnd);
  }

  /// تولید گزارش ماهانه
  Future<ReportData> generateMonthlyReport() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return _generateReport(monthStart, monthEnd);
  }

  /// تولید گزارش برای بازه مشخص
  Future<ReportData> _generateReport(
      DateTime startDate, DateTime endDate) async {
    final startMs = startDate.millisecondsSinceEpoch;
    final endMs = endDate.millisecondsSinceEpoch;

    // ── خواندن داده‌ها ──
    final sleepDao = SleepDao(db);
    final hydrationDao = HydrationDao(db);
    final exerciseDao = ExerciseDao(db);
    final weightDao = WeightDao(db);
    final summaryDao = SummaryDao(db);

    // خواب
    final sleepEntries = await sleepDao.getSleepByDateRange(startMs, endMs);

    // تمرینات
    final workouts = await exerciseDao.getWorkoutsByDateRange(startMs, endMs);
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();

    // آب
    final waterEntries = await hydrationDao.getWaterByDateRange(startMs, endMs);

    // وزن
    final weightEntries = await weightDao.getWeightByDateRange(startMs, endMs);

    // خلاصه‌های روزانه
    final summaries = await summaryDao.getSummariesByDateRange(startMs, endMs);

    // ── محاسبه آمار ──

    // خواب
    SleepStats? sleepStats;
    if (sleepEntries.isNotEmpty) {
      final totalDuration =
          sleepEntries.fold<int>(0, (s, e) => s + e.durationMinutes);
      final totalQuality =
          sleepEntries.fold<int>(0, (s, e) => s + e.quality);
      final durations =
          sleepEntries.map((e) => e.durationMinutes).toList()..sort();
      sleepStats = SleepStats(
        avgDurationMinutes: totalDuration / sleepEntries.length,
        avgQuality: totalQuality / sleepEntries.length,
        bestDuration: durations.isNotEmpty ? durations.last : null,
        worstDuration: durations.isNotEmpty ? durations.first : null,
      );
    }

    // تغذیه
    NutritionStats? nutritionStats;
    int nutritionDaysOnTarget = 0;
    if (summaries.isNotEmpty) {
      double totalCal = 0;
      double totalPro = 0;
      double totalFat = 0;
      double totalCarb = 0;

      // خواندن هدف کالری از تنظیمات
      final calTargetSetting = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('calorie_target')))
          .getSingleOrNull();
      final calorieTarget =
          int.tryParse(calTargetSetting?.value ?? '') ?? 2000;

      for (final s in summaries) {
        totalCal += s.totalCalories;
        totalPro += s.totalProtein;
        totalFat += s.totalFat;
        totalCarb += s.totalCarb;
        if (s.totalCalories >= calorieTarget * 0.9 &&
            s.totalCalories <= calorieTarget * 1.1) {
          nutritionDaysOnTarget++;
        }
      }

      nutritionStats = NutritionStats(
        avgCalories: totalCal / summaries.length,
        avgProtein: totalPro / summaries.length,
        avgFat: totalFat / summaries.length,
        avgCarb: totalCarb / summaries.length,
        daysOnTarget: nutritionDaysOnTarget,
      );
    }

    // تمرین
    WorkoutStats? workoutStats;
    if (completedWorkouts.isNotEmpty) {
      double totalVol = 0;
      int totalDur = 0;
      for (final w in completedWorkouts) {
        totalDur += w.durationMinutes ?? 0;
        final exercises = await (db.select(db.workoutExercises)
              ..where((t) => t.workoutId.equals(w.id)))
            .get();
        for (final ex in exercises) {
          if (ex.weightKg != null && ex.reps != null && ex.isCompleted) {
            totalVol += ex.weightKg! * ex.reps! * ex.sets;
          }
        }
      }
      workoutStats = WorkoutStats(
        count: completedWorkouts.length,
        totalVolume: totalVol,
        totalDurationMinutes: totalDur,
      );
    }

    // آب - محاسبه بر اساس روز
    HydrationStats? hydrationStats;
    if (waterEntries.isNotEmpty) {
      // هدف آب از تنظیمات
      final waterTargetSetting = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('water_target')))
          .getSingleOrNull();
      final waterTarget =
          int.tryParse(waterTargetSetting?.value ?? '') ?? 2500;

      // جمع آب بر اساس روز
      final waterByDay = <int, int>{};
      for (final w in waterEntries) {
        final dayStart = DateTime.fromMillisecondsSinceEpoch(w.date);
        final dayKey =
            DateTime(dayStart.year, dayStart.month, dayStart.day)
                .millisecondsSinceEpoch;
        waterByDay[dayKey] = (waterByDay[dayKey] ?? 0) + w.amountMl;
      }

      final totalMl = waterByDay.values.fold<int>(0, (s, v) => s + v);
      final daysOnTarget =
          waterByDay.values.where((ml) => ml >= waterTarget).length;

      hydrationStats = HydrationStats(
        avgMl: waterByDay.isNotEmpty ? totalMl / waterByDay.length : 0,
        daysOnTarget: daysOnTarget,
      );
    }

    // وزن
    WeightChange? weightChange;
    if (weightEntries.length >= 2) {
      final sorted = weightEntries
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final startW = sorted.first.weightKg;
      final endW = sorted.last.weightKg;
      weightChange = WeightChange(
        startWeight: startW,
        endWeight: endW,
        diffKg: endW - startW,
      );
    }

    // ── امتیاز سبک زندگی ──
    double overallScore = 0;
    Map<String, double> categoryScores = {};
    if (summaries.isNotEmpty) {
      final scoredSummaries =
          summaries.where((s) => s.lifestyleScore != null).toList();
      if (scoredSummaries.isNotEmpty) {
        overallScore = scoredSummaries
                .fold<double>(0, (s, sum) => s + (sum.lifestyleScore ?? 0)) /
            scoredSummaries.length;
      }
    }

    // ── Rule Engine برای توصیه‌ها ──
    final recommendations = <String>[];
    if (summaries.isNotEmpty) {
      // آخرین خلاصه به‌عنوان نماینده
      final lastSummary = summaries.last;
      final engine = BergamotRuleEngine.defaultRules();
      final ctx = RuleContext(
        sleepDurationMinutes: lastSummary.sleepDurationMinutes,
        sleepQuality: lastSummary.sleepQuality,
        totalWaterMl: lastSummary.totalWaterMl.toDouble(),
        totalCalories: lastSummary.totalCalories,
        totalProtein: lastSummary.totalProtein,
        totalFat: lastSummary.totalFat,
        totalCarb: lastSummary.totalCarb,
        hasWorkout: lastSummary.workoutMinutes != null &&
            (lastSummary.workoutMinutes ?? 0) > 0,
        workoutVolumeKg: lastSummary.workoutVolume,
      );
      final evals = engine.evaluateAll(ctx);
      for (final e in evals) {
        if (e.recommendation != null && e.recommendation!.isNotEmpty) {
          recommendations.add(e.recommendation!);
        }
        if (e.severity == RuleSeverity.error ||
            e.severity == RuleSeverity.warning) {
          recommendations.add(e.messageFa);
        }
      }
    }
    if (recommendations.isEmpty) {
      recommendations.add('عملکرد شما در این دوره خوب بوده است. ادامه دهید!');
    }

    // ── عنوان دوره فارسی ──
    final dateRange = _persianDateRange(startDate, endDate.subtract(const Duration(days: 1)));
    final periodTitle = 'گزارش $dateRange';

    // ── بزرگ‌ترین موفقیت و تمرکز هفته آینده ──
    final biggestWin = await _computeBiggestWin(
      startDate: startDate,
      endDate: endDate,
      sleepStats: sleepStats,
      nutritionStats: nutritionStats,
      workoutStats: workoutStats,
      hydrationStats: hydrationStats,
    );
    final nextWeekFocus = await _computeNextWeekFocus(
      startDate: startDate,
      endDate: endDate,
      sleepStats: sleepStats,
      nutritionStats: nutritionStats,
      workoutStats: workoutStats,
      hydrationStats: hydrationStats,
    );

    return ReportData(
      periodTitle: periodTitle,
      dateRange: dateRange,
      startDate: startMs,
      endDate: endMs,
      overallScore: overallScore,
      categoryScores: categoryScores,
      sleepStats: sleepStats,
      nutritionStats: nutritionStats,
      workoutStats: workoutStats,
      hydrationStats: hydrationStats,
      weightChange: weightChange,
      recommendations: recommendations,
      biggestWin: biggestWin,
      nextWeekFocus: nextWeekFocus,
    );
  }

  /// پیدا کردن ابتدای هفته (شنبه)
  DateTime _getWeekStart(DateTime now) {
    // روز هفته: ۱=دوشنبه تا ۷=یکشنبه
    final weekday = now.weekday;
    // شنبه = روز ۶ در این سیستم → ابتدای هفته شمسی
    // Adjust so Saturday is start (weekday 6)
    final daysSinceSaturday = (weekday + 1) % 7;
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysSinceSaturday));
  }

  /// ساخت عنوان بازه تاریخی فارسی
  String _persianDateRange(DateTime start, DateTime end) {
    final faNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String toFaNum(int n) => n.toString().split('').map((c) {
          final idx = int.tryParse(c);
          return idx != null ? faNumbers[idx] : c;
        }).join();

    return '${toFaNum(start.day)}/${toFaNum(start.month)} تا ${toFaNum(end.day)}/${toFaNum(end.month)}';
  }

  /// محاسبه بزرگ‌ترین بهبود نسبت به هفته قبل
  Future<String?> _computeBiggestWin({
    required DateTime startDate,
    required DateTime endDate,
    required SleepStats? sleepStats,
    required NutritionStats? nutritionStats,
    required WorkoutStats? workoutStats,
    required HydrationStats? hydrationStats,
  }) async {
    final periodDays = endDate.difference(startDate).inDays;
    final prevStartMs = startDate.subtract(Duration(days: periodDays)).millisecondsSinceEpoch;
    final prevEndMs = startDate.millisecondsSinceEpoch;

    // خواندن داده‌های هفته قبل
    final prevSleep = await SleepDao(db).getSleepByDateRange(prevStartMs, prevEndMs);
    final prevWater = await HydrationDao(db).getWaterByDateRange(prevStartMs, prevEndMs);
    final prevWorkouts = await ExerciseDao(db).getWorkoutsByDateRange(prevStartMs, prevEndMs);
    final prevSummaries = await SummaryDao(db).getSummariesByDateRange(prevStartMs, prevEndMs);

    // اگر هیچ داده‌ای در هفته قبل نبود
    if (prevSleep.isEmpty && prevWater.isEmpty && prevWorkouts.isEmpty && prevSummaries.isEmpty) {
      return null;
    }

    final faNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String toFaNum(int n) => n.toString().split('').map((c) {
          final idx = int.tryParse(c);
          return idx != null ? faNumbers[idx] : c;
        }).join();

    String? bestName;
    double bestPct = 0;

    // خواب: میانگین مدت
    if (sleepStats != null && prevSleep.isNotEmpty) {
      final prevAvg = prevSleep.fold<int>(0, (s, e) => s + e.durationMinutes) / prevSleep.length;
      if (prevAvg > 0) {
        final pct = ((sleepStats.avgDurationMinutes - prevAvg) / prevAvg) * 100;
        if (pct > bestPct) {
          bestPct = pct;
          bestName = 'خواب: ${toFaNum(pct.round())}٪ بهبود نسبت به هفته قبل';
        }
      }
    }

    // آب: میانگین
    if (hydrationStats != null && prevWater.isNotEmpty) {
      final prevWaterByDay = <int, int>{};
      for (final w in prevWater) {
        final dayStart = DateTime.fromMillisecondsSinceEpoch(w.date);
        final dayKey = DateTime(dayStart.year, dayStart.month, dayStart.day).millisecondsSinceEpoch;
        prevWaterByDay[dayKey] = (prevWaterByDay[dayKey] ?? 0) + w.amountMl;
      }
      if (prevWaterByDay.isNotEmpty) {
        final prevAvg = prevWaterByDay.values.fold<int>(0, (s, v) => s + v) / prevWaterByDay.length;
        if (prevAvg > 0) {
          final pct = ((hydrationStats.avgMl - prevAvg) / prevAvg) * 100;
          if (pct > bestPct) {
            bestPct = pct;
            bestName = 'آب: ${toFaNum(pct.round())}٪ بهبود نسبت به هفته قبل';
          }
        }
      }
    }

    // تمرین: تعداد
    if (workoutStats != null && prevWorkouts.isNotEmpty) {
      final prevCount = prevWorkouts.where((w) => w.isCompleted).length;
      if (prevCount > 0) {
        final pct = ((workoutStats.count - prevCount) / prevCount) * 100;
        if (pct > bestPct) {
          bestPct = pct;
          bestName = 'تمرین: ${toFaNum(pct.round())}٪ بهبود نسبت به هفته قبل';
        }
      } else if (workoutStats.count > 0) {
        // قبلاً صفر بوده، حالا داره تمرین می‌کنه
        bestName = 'تمرین: شروع تمرینات نسبت به هفته قبل';
        bestPct = double.infinity;
      }
    }

    // کالری: روزهای در محدوده هدف
    if (nutritionStats != null && prevSummaries.isNotEmpty) {
      final calTargetSetting = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('calorie_target')))
          .getSingleOrNull();
      final calorieTarget = int.tryParse(calTargetSetting?.value ?? '') ?? 2000;
      int prevDaysOnTarget = 0;
      for (final s in prevSummaries) {
        if (s.totalCalories >= calorieTarget * 0.9 &&
            s.totalCalories <= calorieTarget * 1.1) {
          prevDaysOnTarget++;
        }
      }
      if (prevDaysOnTarget > 0) {
        final pct = ((nutritionStats.daysOnTarget - prevDaysOnTarget) / prevDaysOnTarget) * 100;
        if (pct > bestPct) {
          bestPct = pct;
          bestName = 'تغذیه: ${toFaNum(pct.round())}٪ بهبود نسبت به هفته قبل';
        }
      } else if (nutritionStats.daysOnTarget > 0) {
        bestName = 'تغذیه: رسیدن به محدوده هدف کالری';
        bestPct = double.infinity;
      }
    }

    return bestName;
  }

  /// محاسبه تمرکز هفته آینده — ضعیف‌ترین متریک
  Future<String?> _computeNextWeekFocus({
    required DateTime startDate,
    required DateTime endDate,
    required SleepStats? sleepStats,
    required NutritionStats? nutritionStats,
    required WorkoutStats? workoutStats,
    required HydrationStats? hydrationStats,
  }) async {
    final periodDays = endDate.difference(startDate).inDays;
    final faNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String toFaNum(int n) => n.toString().split('').map((c) {
          final idx = int.tryParse(c);
          return idx != null ? faNumbers[idx] : c;
        }).join();

    // هدف خواب: ۸ ساعت = ۴۸۰ دقیقه
    const sleepTargetMinutes = 480;
    final sleepPct = sleepStats != null
        ? (sleepStats.avgDurationMinutes / sleepTargetMinutes * 100).clamp(0.0, 200.0)
        : null;

    // هدف تمرین: ۳ روز در هفته
    final workoutTarget = (periodDays / 7 * 3).round();
    final workoutPct = workoutStats != null
        ? (workoutStats.count / workoutTarget * 100).clamp(0.0, 200.0)
        : 0.0;

    // هدف آب
    final waterTargetSetting = await (db.select(db.appSettings)
          ..where((t) => t.key.equals('water_target')))
        .getSingleOrNull();
    final waterTarget = int.tryParse(waterTargetSetting?.value ?? '') ?? 2500;
    final waterPct = hydrationStats != null
        ? (hydrationStats.avgMl / waterTarget * 100).clamp(0.0, 200.0)
        : 0.0;

    // هدف کالری: درصد روزهای در محدوده هدف
    final calPct = nutritionStats != null
        ? (nutritionStats.daysOnTarget / periodDays * 100).clamp(0.0, 200.0)
        : 0.0;

    // خواندن goalType
    int goalType = 0;
    final profile = await (db.select(db.userProfiles)).getSingleOrNull();
    if (profile != null) {
      goalType = profile.goalType;
    }

    // تعیین لیست متریک‌ها بر اساس نوع هدف
    List<MapEntry<String, double>> metrics;
    if (goalType == 1) {
      // کاهش وزن
      metrics = [
        MapEntry('تغذیه', calPct),
        MapEntry('تمرین', workoutPct),
      ];
    } else if (goalType == 2) {
      // افزایش وزن
      metrics = [
        MapEntry('تغذیه', calPct),
        MapEntry('پروتئین', nutritionStats != null ? (nutritionStats.avgProtein / 150 * 100).clamp(0.0, 200.0) : 0.0),
        MapEntry('تمرین', workoutPct),
      ];
    } else {
      metrics = [
        MapEntry('خواب', sleepPct ?? 0.0),
        MapEntry('آب', waterPct),
        MapEntry('تغذیه', calPct),
        MapEntry('تمرین', workoutPct),
      ];
    }

    // اگر هیچ داده‌ای نیست
    if (sleepStats == null && hydrationStats == null &&
        nutritionStats == null && workoutStats == null) {
      return null;
    }

    // مرتب‌سازی: ضعیف‌ترین اول
    metrics.sort((a, b) => a.value.compareTo(b.value));
    final weakest = metrics.first;

    return '${weakest.key}: فقط ${toFaNum(weakest.value.round())}٪ هدف هفتگی را محقق کردی';
  }
}
