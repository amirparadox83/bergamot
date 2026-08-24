import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// دیتابیس دیتابیس خواب
/// مدیریت ورودی‌های خواب، نمودارها و آمار
class SleepDao {
  final BergamotDatabase db;
  SleepDao(this.db);

  /// واچ امروز - تمام ورودی‌های خواب امروز
  Stream<List<SleepEntry>> watchTodaySleep() {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 24 * 60 * 60 * 1000;
    return (db.select(db.sleepEntries)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay)))
        .watch();
  }

  /// ورودی‌های خواب بر اساس محدوده تاریخ (برای نمودار)
  Future<List<SleepEntry>> getSleepByDateRange(int start, int end) {
    return (db.select(db.sleepEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// ثبت ورودی خواب جدید
  Future<int> insertSleep(SleepEntriesCompanion entry) {
    return db.into(db.sleepEntries).insert(entry);
  }

  /// بروزرسانی ورودی خواب
  Future<bool> updateSleep(SleepEntriesCompanion entry, int id) {
    return (db.update(db.sleepEntries)..where((t) => t.id.equals(id)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// حذف ورودی خواب
  Future<int> deleteSleep(int id) {
    return (db.delete(db.sleepEntries)..where((t) => t.id.equals(id)))
        .go();
  }

  /// میانگین کیفیت خواب در N روز اخیر
  Future<double?> getAverageSleepQuality(int days) {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final nDaysAgo = startOfDay - (days * 24 * 60 * 60 * 1000);
    final query = db.selectOnly(db.sleepEntries)
      ..addColumns([db.sleepEntries.quality.avg()])
      ..where(db.sleepEntries.date.isBetweenValues(nDaysAgo, startOfDay));
    return query
        .getSingleOrNull()
        .then((row) => row?.read(db.sleepEntries.quality.avg()));
  }

  /// میانگین مدت خواب در N روز اخیر (دقیقه)
  Future<double?> getAverageSleepDuration(int days) {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final nDaysAgo = startOfDay - (days * 24 * 60 * 60 * 1000);
    final query = db.selectOnly(db.sleepEntries)
      ..addColumns([db.sleepEntries.durationMinutes.avg()])
      ..where(db.sleepEntries.date.isBetweenValues(nDaysAgo, startOfDay));
    return query
        .getSingleOrNull()
        .then((row) => row?.read(db.sleepEntries.durationMinutes.avg()));
  }
}
