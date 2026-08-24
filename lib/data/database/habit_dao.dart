import 'package:drift/drift.dart' hide Column;
import 'bergamot_database.dart';

/// دیتابیس عادت‌ها
/// مدیریت عادت‌ها، ثبت انجام، محاسبه امتیاز و استریک
class HabitDao {
  final BergamotDatabase db;
  HabitDao(this.db);

  /// واچ تمام عادت‌های فعال (غیربایگانی)
  Stream<List<Habit>> watchAllHabits() {
    return (db.select(db.habits)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// دریافت لاگ‌های عادت در محدوده تاریخ
  Future<List<HabitLog>> getHabitLogsForRange(
    int habitId,
    int startMs,
    int endMs,
  ) {
    return (db.select(db.habitLogs)
          ..where((t) =>
              t.habitId.equals(habitId) & t.date.isBetweenValues(startMs, endMs)))
        .get();
  }

  /// دریافت تمام لاگ‌های یک عادت (نزولی بر اساس تاریخ)
  Future<List<HabitLog>> getAllLogsForHabit(int habitId) {
    return (db.select(db.habitLogs)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
          ]))
        .get();
  }

  /// ثبت یا بروزرسانی لاگ عادت (تاگل امروز)
  Future<void> toggleHabitLog(
    int habitId,
    int dateMs,
    bool completed,
  ) async {
    await db.transaction(() async {
      // بررسی وجود لاگ برای این روز
      final existing = await (db.select(db.habitLogs)
            ..where((t) =>
                t.habitId.equals(habitId) & t.date.equals(dateMs)))
          .getSingleOrNull();

      if (existing != null) {
        await (db.update(db.habitLogs)
              ..where((t) => t.id.equals(existing.id)))
            .write(HabitLogsCompanion(
          isCompleted: Value(completed),
          completedAt: Value(completed ? DateTime.now().millisecondsSinceEpoch : null),
        ));
      } else {
        await db.into(db.habitLogs).insert(HabitLogsCompanion(
          habitId: Value(habitId),
          date: Value(dateMs),
          isCompleted: Value(completed),
          completedAt: Value(
              completed ? DateTime.now().millisecondsSinceEpoch : null),
        ));
      }
    });
  }

  /// افزودن عادت جدید
  Future<int> addHabit(HabitsCompanion entry) {
    return db.into(db.habits).insert(entry);
  }

  /// بروزرسانی عادت
  Future<bool> updateHabit(int id, HabitsCompanion entry) {
    return (db.update(db.habits)..where((t) => t.id.equals(id)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// حذف عادت و تمام لاگ‌هایش
  Future<void> deleteHabit(int id) async {
    await (db.delete(db.habitLogs)..where((t) => t.habitId.equals(id))).go();
    await (db.delete(db.habits)..where((t) => t.id.equals(id))).go();
  }

  // PERFORMANCE NOTE: This loads all logs from creation date. For long-lived habits,
  // consider a SQL-based approach or incremental cached score.
  /// محاسبه امتیاز عادت با Smoothing نمایی
  ///
  /// الگوریتم: از تاریخ ایجاد تا امروز پیمایش می‌شود
  /// score = score * 0.95 + (completed ? 1.0 : 0.0) * 0.05
  /// مقدار نهایی بین ۰ و ۱ محدود می‌شود
  Future<double> calculateHabitScore(int habitId) async {
    // دریافت اطلاعات عادت
    final habit = await (db.select(db.habits)
          ..where((t) => t.id.equals(habitId)))
        .getSingleOrNull();
    if (habit == null) return 0.0;

    // دریافت تمام لاگ‌ها به‌صورت صعودی
    final logs = await (db.select(db.habitLogs)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
          ]))
        .get();

    // ساخت مپ تاریخ → وضعیت
    final logMap = <int, bool>{};
    for (final log in logs) {
      logMap[log.date] = log.isCompleted;
    }

    // پیمایش از تاریخ ایجاد تا امروز
    final creationDate =
        DateTime.fromMillisecondsSinceEpoch(habit.createdAt);
    final today = DateTime.now();
    final todayMs = DateTime(today.year, today.month, today.day)
        .millisecondsSinceEpoch;
    final creationMs = DateTime(creationDate.year, creationDate.month, creationDate.day)
        .millisecondsSinceEpoch;

    double score = 0.0;
    var current = creationMs;
    const dayMs = 24 * 60 * 60 * 1000;

    while (current <= todayMs) {
      final completed = logMap[current] ?? false;
      score = score * 0.95 + (completed ? 1.0 : 0.0) * 0.05;
      current += dayMs;
    }

    // محدود به بازه ۰ تا ۱
    return score.clamp(0.0, 1.0);
  }

  /// محاسبه استریک فعلی — تعداد روزهای متوالی انجام‌شده
  /// اگر امروز هنوز انجام نشده، از دیروز شروع می‌شود
  Future<int> getCurrentStreak(int habitId) async {
    final logs = await (db.select(db.habitLogs)
          ..where((t) =>
              t.habitId.equals(habitId) & t.isCompleted.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
          ]))
        .get();

    if (logs.isEmpty) return 0;

    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;

    // شروع از امروز یا دیروز
    final startDate = logs.any((l) => l.date == todayMs)
        ? todayMs
        : todayMs - dayMs;

    int streak = 0;
    var checkDate = startDate;
    final logDates = logs.map((l) => l.date).toSet();

    while (logDates.contains(checkDate)) {
      streak++;
      checkDate -= dayMs;
    }

    return streak;
  }

  /// دریافت وضعیت امروز برای یک عادت
  Future<HabitLog?> getTodayStatus(int habitId) async {
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return (db.select(db.habitLogs)
          ..where((t) =>
              t.habitId.equals(habitId) & t.date.equals(todayMs)))
        .getSingleOrNull();
  }
}
