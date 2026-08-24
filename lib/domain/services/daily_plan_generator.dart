import 'package:drift/drift.dart' hide Column;

import '../../data/database/bergamot_database.dart';
import '../../data/database/sleep_dao.dart';

/// آیتم ساده برنامه روزانه — قبل از تبدیل به DailyPlansCompanion
///
/// کلاس دیتای ساده که ژنراتور تولید می‌کند
class DailyPlanItem {
  final String title;
  final int scheduledTimeMs;
  final int? durationMinutes;
  final String category;

  const DailyPlanItem({
    required this.title,
    required this.scheduledTimeMs,
    this.durationMinutes,
    required this.category,
  });
}

/// ژنراتور برنامه روزانه
///
/// بر اساس پروفایل کاربر (هدف، سطح فعالیت) و SleepEntry های اخیر یک
/// برنامه روزانه مبتنی بر قوانین ساده (rule-based، نه AI) تولید می‌کند.
///
/// PHASE 4 (Bergamot troubleshooting round):
/// این ژنراتور حالا زمان بیداری/خواب را از SleepEntry های اخیر محاسبه
/// می‌کند (اگر موجود بود؛ در غیر این صورت مقدار پیش‌فرض منطقی ۷:۰۰ / ۲۳:۰۰
/// استفاده می‌شود).
///
/// ترجیح schedule کاربر از Onboarding هنوز پشتیبانی نمی‌شود چون فیلد
/// `preferredSchedule` در پروفایل کاربر موجود نیست (مشخص شده در audit).
/// این یک مورد TODO برای پرامپت آینده است.
class DailyPlanGenerator {
  final BergamotDatabase db;
  DailyPlanGenerator(this.db);

  /// تولید برنامه روزانه برای یک تاریخ مشخص
  ///
  /// [dateMs] شروع روز به میلی‌ثانیه از Epoch
  /// بازگشت لیست DailyPlansCompanion آماده برای ذخیره
  Future<List<DailyPlansCompanion>> generate(int dateMs) async {
    final profile = await (db.select(db.userProfiles)..limit(1)).getSingleOrNull();

    // پیش‌فرض‌ها
    final goalType = profile?.goalType ?? 0; // ۰=حفظ، ۱=کاهش، ۲=افزایش
    final activityLevel = profile?.activityLevel ?? 2; // ۰=کم‌تحرک تا ۴=بسیار فعال

    // ─── محاسبه زمان بیداری/خواب از SleepEntry های اخیر (PHASE 4) ────────
    // میانگین ساعت بیداری و خواب ۷ روز اخیر را محاسبه می‌کنیم.
    // اگر داده‌ای موجود نبود، از مقادیر پیش‌فرض ۷:۰۰ / ۲۳:۰۰ استفاده می‌کنیم.
    final wakeSleepTimes = await _computeAverageWakeSleepTimes();
    final wakeHour = wakeSleepTimes.$1;
    final sleepHour = wakeSleepTimes.$2;

    final dayStart = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final wakeTime = dayStart.add(Duration(hours: wakeHour));
    final sleepTime = dayStart.add(Duration(hours: sleepHour));

    final items = <DailyPlanItem>[];

    // ── خواب و بیداری ──
    items.add(DailyPlanItem(
      title: 'بیداری',
      scheduledTimeMs: wakeTime.millisecondsSinceEpoch,
      durationMinutes: 0,
      category: 'sleep',
    ));
    items.add(DailyPlanItem(
      title: 'خواب',
      scheduledTimeMs: sleepTime.millisecondsSinceEpoch,
      durationMinutes: 480, // ۸ ساعت
      category: 'sleep',
    ));

    // ── وعده‌های غذایی ──
    final breakfastTime = wakeTime.add(const Duration(hours: 1));
    final lunchTime = wakeTime.add(const Duration(hours: 5));
    final snackTime = lunchTime.add(const Duration(hours: 3));
    final dinnerTime = wakeTime.add(const Duration(hours: 10));

    items.add(DailyPlanItem(
      title: 'صبحانه',
      scheduledTimeMs: breakfastTime.millisecondsSinceEpoch,
      durationMinutes: 20,
      category: 'meal',
    ));
    items.add(DailyPlanItem(
      title: 'ناهار',
      scheduledTimeMs: lunchTime.millisecondsSinceEpoch,
      durationMinutes: 30,
      category: 'meal',
    ));

    // میان‌وعده: بیشتر برای کاهش وزن و حفظ وزن
    if (goalType <= 1) {
      items.add(DailyPlanItem(
        title: 'میان‌وعده',
        scheduledTimeMs: snackTime.millisecondsSinceEpoch,
        durationMinutes: 10,
        category: 'meal',
      ));
    }

    // شام
    items.add(DailyPlanItem(
      title: 'شام',
      scheduledTimeMs: dinnerTime.millisecondsSinceEpoch,
      durationMinutes: 30,
      category: 'meal',
    ));

    // وعده اضافه برای افزایش وزن
    if (goalType == 2) {
      final extraMealTime = dinnerTime.add(const Duration(hours: 2));
      items.add(DailyPlanItem(
        title: 'وعده قبل از خواب',
        scheduledTimeMs: extraMealTime.millisecondsSinceEpoch,
        durationMinutes: 15,
        category: 'meal',
      ));
    }

    // ── تمرین ──
    // زمان تمرین بر اساس سطح فعالیت
    final workoutHour = activityLevel >= 3
        ? 16 // فعال و بسیار فعال: عصر
        : 17; // سایر: اواخر عصر

    final workoutTime = DateTime.fromMillisecondsSinceEpoch(dateMs)
        .add(Duration(hours: workoutHour));
    final workoutDuration = _workoutMinutes(goalType, activityLevel);

    items.add(DailyPlanItem(
      title: 'تمرین',
      scheduledTimeMs: workoutTime.millisecondsSinceEpoch,
      durationMinutes: workoutDuration,
      category: 'workout',
    ));

    // ── یادآوری آب ──
    // هر ۲ ساعت از بیداری تا خواب
    const waterInterval = Duration(hours: 2);
    var waterTime = wakeTime.add(waterInterval);
    while (waterTime.isBefore(sleepTime)) {
      items.add(DailyPlanItem(
        title: 'نوشیدن آب',
        scheduledTimeMs: waterTime.millisecondsSinceEpoch,
        durationMinutes: 2,
        category: 'water',
      ));
      waterTime = waterTime.add(waterInterval);
    }

    // تبدیل به DailyPlansCompanion
    final now = DateTime.now().millisecondsSinceEpoch;
    return items.map((item) => DailyPlansCompanion(
      date: Value(dateMs),
      itemTitle: Value(item.title),
      scheduledTime: Value(item.scheduledTimeMs),
      durationMinutes: Value(item.durationMinutes),
      category: Value(item.category),
      createdAt: Value(now),
    )).toList();
  }

  /// محاسبه‌ی میانگین ساعت بیداری/خواب از ۷ SleepEntry اخیر (PHASE 4)
  ///
  /// بازگشت: (wakeHour, sleepHour) — هر دو به‌صورت int (۰..۲۳).
  /// اگر SleepEntry موجود نبود، مقادیر پیش‌فرض (7, 23) برمی‌گردد.
  Future<(int, int)> _computeAverageWakeSleepTimes() async {
    final sleepDao = SleepDao(db);
    final now = DateTime.now();
    final sevenDaysAgoMs = now
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final entries = await sleepDao.getSleepByDateRange(sevenDaysAgoMs, now.millisecondsSinceEpoch);

    if (entries.isEmpty) {
      // No sleep data — use sensible defaults
      return (7, 23);
    }

    // محاسبه‌ی میانگین ساعت wake و sleep
    var totalWakeHour = 0.0;
    var totalSleepHour = 0.0;
    var count = 0;
    for (final entry in entries) {
      // sleepTime = bedtime (epoch ms)
      // wakeTime = wake time (epoch ms)
      final wakeDate = DateTime.fromMillisecondsSinceEpoch(entry.wakeTime);
      final sleepDate = DateTime.fromMillisecondsSinceEpoch(entry.sleepTime);

      // اگر sleepTime قبل از wakeTime است، یعنی فرد شب قبل خوابیده
      // (مثلاً ۲۳:۰۰ شب قبل، بیداری ۷:۰۰ صبح). در غیر این صورت، فرد امروز خوابیده.
      // در هر دو حالت، فقط ساعت ۰..۲۳ را حساب می‌کنیم.
      totalWakeHour += wakeDate.hour + wakeDate.minute / 60.0;
      totalSleepHour += sleepDate.hour + sleepDate.minute / 60.0;
      count++;
    }

    if (count == 0) return (7, 23);

    final avgWakeHour = (totalWakeHour / count).round();
    final avgSleepHour = (totalSleepHour / count).round();

    // Sanity check: wake باید بین ۴ و ۱۲ باشد، sleep بین ۲۰ و ۲۴ (یا ۰..۳)
    final wakeClamped = avgWakeHour < 4 ? 7 : (avgWakeHour > 12 ? 7 : avgWakeHour);
    var sleepClamped = avgSleepHour;
    if (sleepClamped < 18 && sleepClamped > 5) {
      // Invalid waking hour — treat as late night
      sleepClamped = 23;
    }

    return (wakeClamped, sleepClamped);
  }

  /// محاسبه مدت تمرین بر اساس هدف و سطح فعالیت
  int _workoutMinutes(int goalType, int activityLevel) {
    // کاهش وزن: تمرین بیشتر
    if (goalType == 1) {
      return activityLevel >= 3 ? 60 : 45;
    }
    // افزایش وزن: تمرین متوسط
    if (goalType == 2) {
      return 30;
    }
    // حفظ وزن
    return activityLevel >= 3 ? 45 : 30;
  }
}
