import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_provider.dart';
import '../../../data/database/exercise_dao.dart';
import '../../../data/database/hydration_dao.dart';
import '../../../data/database/nutrition_dao.dart';
import '../../../data/database/sleep_dao.dart';
import '../../../domain/rule_engine/rule_base.dart';
import '../../../domain/rule_engine/rule_engine.dart';
import '../../../domain/services/achievement_checker.dart';

/// داده‌های صفحه اصلی
///
/// داده‌های واقعی از دیتابیس و موتور قوانین خوانده می‌شوند.
class HomeState {
  /// امتیاز سبک زندگی (۰ تا ۱۰۰)
  final double lifestyleScore;

  /// آب مصرفی امروز (میلی‌لیتر)
  final int todayWaterTotal;

  /// کالری مصرفی امروز
  final int todayCalories;

  /// وضعیت خواب
  final String sleepStatus;

  /// وضعیت تمرین
  final String workoutStatus;

  /// آیا در حال بارگذاری است
  final bool isLoading;

  const HomeState({
    this.lifestyleScore = 0,
    this.todayWaterTotal = 0,
    this.todayCalories = 0,
    this.sleepStatus = 'خواب امروز ثبت نشده',
    this.workoutStatus = 'تمرین امروز ثبت نشده',
    this.isLoading = true,
  });

  HomeState copyWith({
    double? lifestyleScore,
    int? todayWaterTotal,
    int? todayCalories,
    String? sleepStatus,
    String? workoutStatus,
    bool? isLoading,
  }) {
    return HomeState(
      lifestyleScore: lifestyleScore ?? this.lifestyleScore,
      todayWaterTotal: todayWaterTotal ?? this.todayWaterTotal,
      todayCalories: todayCalories ?? this.todayCalories,
      sleepStatus: sleepStatus ?? this.sleepStatus,
      workoutStatus: workoutStatus ?? this.workoutStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier صفحه اصلی
///
/// داده‌های واقعی از دیتابیس خوانده شده و امتیاز سبک زندگی
/// با [BergamotRuleEngine] محاسبه می‌شود.
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    _loadTodayData();
    return const HomeState();
  }

  /// بارگذاری داده‌های امروز از دیتابیس
  Future<void> _loadTodayData() async {
    try {
      final db = ref.read(bergamotDatabaseProvider);
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final endOfDay = startOfDay + 24 * 60 * 60 * 1000;

      // --- آب ---
      final waterTotal = await HydrationDao(db).getTodayTotalMl();

      // --- تغذیه ---
      final calories = await NutritionDao(db).getDailyCalories(startOfDay);
      final macros = await NutritionDao(db).getDailyMacros(startOfDay);

      // --- خواب ---
      final sleepEntries = await SleepDao(db).getSleepByDateRange(
          startOfDay, endOfDay);
      int? sleepDuration;
      int? sleepQuality;
      String sleepStatus = 'خواب امروز ثبت نشده';
      if (sleepEntries.isNotEmpty) {
        sleepDuration = sleepEntries.last.durationMinutes;
        sleepQuality = sleepEntries.last.quality;
        final hours = (sleepDuration / 60).floor();
        final mins = sleepDuration % 60;
        sleepStatus = 'خواب $hours ساعت و $mins دقیقه';
      }

      // --- تمرین ---
      final workouts =
          await ExerciseDao(db).getWorkoutsByDateRange(startOfDay, endOfDay);
      bool hasWorkout = workouts.any((w) => w.isCompleted);
      String workoutStatus = 'تمرین امروز ثبت نشده';
      if (hasWorkout) {
        final completed = workouts.where((w) => w.isCompleted).length;
        workoutStatus = '$completed جلسه تمرین انجام شد';
      }

      // --- محاسبه امتیاز سبک زندگی ---
      final context = RuleContext(
        sleepDurationMinutes: sleepDuration,
        sleepQuality: sleepQuality,
        totalWaterMl: waterTotal.toDouble(),
        totalCalories: calories,
        totalProtein: macros.protein,
        totalFat: macros.fat,
        totalCarb: macros.carb,
        hasWorkout: hasWorkout,
      );

      final engine = BergamotRuleEngine.defaultRules();
      final evaluations = engine.evaluateAll(context);
      final score = engine.calculateLifestyleScore(evaluations);

      // بررسی دستاوردها — fire-and-forget so it doesn't block UI
      // TODO: Move to a periodic background task (e.g. after each data write)
      // instead of running on every home screen load.
      unawaited(AchievementChecker.checkAll(db));

      state = state.copyWith(
        lifestyleScore: score,
        todayWaterTotal: waterTotal,
        todayCalories: calories.round(),
        sleepStatus: sleepStatus,
        workoutStatus: workoutStatus,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[HomeNotifier] Error loading today data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// به‌روزرسانی داده‌ها (فراخوانی دستی)
  void refresh() {
    _loadTodayData();
  }

  /// افزودن آب مصرفی
  Future<void> addWater(int amountMl) async {
    final db = ref.read(bergamotDatabaseProvider);
    await HydrationDao(db).addWater(amountMl);
    await _loadTodayData();
  }

  /// به‌روزرسانی کالری (فقط نمایشی)
  ///
  /// مقدار کالری فقط در state محلی ذخیره می‌شود و به دیتابیس
  /// ارسال نمی‌شود. ثبت واقعی کالری از طریق صفحه تغذیه انجام
  /// می‌شود و در [_loadTodayData] از دیتابیس خوانده می‌شود.
  Future<void> updateCalories(int calories) async {
    state = state.copyWith(todayCalories: calories);
  }
}

/// Provider صفحه اصلی
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
