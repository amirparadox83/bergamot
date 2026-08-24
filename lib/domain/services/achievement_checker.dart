import 'package:drift/drift.dart';

import '../../data/database/bergamot_database.dart';
import '../../data/database/achievement_dao.dart';
import '../../data/database/sleep_dao.dart';

/// بررسی‌کننده دستاوردها
///
/// شرط هر دستاورد را بررسی کرده و در صورت برقرار بودن
/// قفل آن را باز می‌کند.
class AchievementChecker {
  /// بررسی تمام دستاوردها
  static Future<void> checkAll(BergamotDatabase db) async {
    final dao = AchievementDao(db);

    // ابتدا مطمئن شویم رکوردهای پیش‌فرض وجود دارند
    await dao.seedAchievements();

    final checks = <String, bool>{};

    // first_workout: آیا هر تمرین تکمیل‌شده‌ای وجود دارد؟
    final anyWorkout = await (db.select(db.workouts)
          ..where((t) => t.isCompleted.equals(true))
          ..limit(1))
        .getSingleOrNull();
    checks['first_workout'] = anyWorkout != null;

    // first_sleep: آیا هر ورودی خوابی وجود دارد؟
    final anySleep = await (db.select(db.sleepEntries)..limit(1))
        .getSingleOrNull();
    checks['first_sleep'] = anySleep != null;

    // first_weight: آیا هر ورودی وزنی وجود دارد؟
    final anyWeight = await (db.select(db.weightEntries)..limit(1))
        .getSingleOrNull();
    checks['first_weight'] = anyWeight != null;

    // first_meal: آیا هر وعده غذایی وجود دارد؟
    final anyMeal = await (db.select(db.mealEntries)..limit(1))
        .getSingleOrNull();
    checks['first_meal'] = anyMeal != null;

    // water_7day_streak: ۷ روز متوالی رسیدن به هدف آب
    checks['water_7day_streak'] = await _checkWater7DayStreak(db);

    // sleep_7day_streak: ۷ روز متوالی ۷+ ساعت خواب
    checks['sleep_7day_streak'] = await _checkSleep7DayStreak(db);

    // total_100l_water: مجموع ۱۰۰,۰۰۰ میلی‌لیتر آب
    checks['total_100l_water'] = await _checkTotalWater(db);

    await dao.checkAndUnlock(checks);
  }

  /// بررسی ۷ روز متوالی رسیدن به هدف آب
  ///
  /// TODO: Refactor to use a single GROUP BY query instead of up to 30
  /// sequential per-day queries. Current approach is O(30) DB roundtrips.
  static Future<bool> _checkWater7DayStreak(BergamotDatabase db) async {
    final waterTargetSetting = await (db.select(db.appSettings)
          ..where((t) => t.key.equals('water_target')))
        .getSingleOrNull();
    final waterTarget = int.tryParse(waterTargetSetting?.value ?? '') ?? 2500;

    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final startOfDay =
          DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      final endOfDay = startOfDay + 24 * 60 * 60 * 1000;

      final query = db.selectOnly(db.waterEntries)
        ..addColumns([db.waterEntries.amountMl.sum()])
        ..where(db.waterEntries.date.isBetweenValues(startOfDay, endOfDay));
      final row = await query.getSingleOrNull();
      final total = row?.read(db.waterEntries.amountMl.sum()) ?? 0;

      if (total >= waterTarget) {
        streak++;
        if (streak >= 7) return true;
      } else {
        streak = 0;
      }
    }
    return false;
  }

  /// بررسی ۷ روز متوالی ۷+ ساعت خواب
  ///
  /// TODO: Refactor to use a single GROUP BY query instead of up to 30
  /// sequential per-day queries. Current approach is O(30) DB roundtrips.
  static Future<bool> _checkSleep7DayStreak(BergamotDatabase db) async {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final startOfDay =
          DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      final endOfDay = startOfDay + 24 * 60 * 60 * 1000;

      final sleepEntries = await SleepDao(db)
          .getSleepByDateRange(startOfDay, endOfDay);

      if (sleepEntries.isNotEmpty) {
        final totalMin =
            sleepEntries.fold<int>(0, (s, e) => s + e.durationMinutes);
        final avgMin = totalMin / sleepEntries.length;
        if (avgMin >= 420) {
          // ۷ ساعت = ۴۲۰ دقیقه
          streak++;
          if (streak >= 7) return true;
        } else {
          streak = 0;
        }
      } else {
        streak = 0;
      }
    }
    return false;
  }

  /// بررسی مجموع ۱۰۰,۰۰۰ میلی‌لیتر آب (۱۰۰ لیتر)
  static Future<bool> _checkTotalWater(BergamotDatabase db) async {
    final query = db.selectOnly(db.waterEntries)
      ..addColumns([db.waterEntries.amountMl.sum()]);
    final row = await query.getSingleOrNull();
    final total = row?.read(db.waterEntries.amountMl.sum()) ?? 0;
    return total >= 100000;
  }
}
