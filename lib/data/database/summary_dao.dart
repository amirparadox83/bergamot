import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// دیتابیس خلاصه روزانه
/// درج/بروزرسانی و خواندن خلاصه روزانه برای نمودارها و صفحه اصلی
class SummaryDao {
  final BergamotDatabase db;
  SummaryDao(this.db);

  /// درج یا بروزرسانی خلاصه روزانه
  /// date یکتاست، پس اگر رکورد وجود داشت بروزرسانی می‌شود
  Future<void> upsertDailySummary(DailySummariesCompanion entry) async {
    final date = entry.date.value;
    await db.transaction(() async {
      final existing = await (db.select(db.dailySummaries)
            ..where((t) => t.date.equals(date)))
          .getSingleOrNull();
      if (existing == null) {
        await db.into(db.dailySummaries).insert(entry);
      } else {
        await (db.update(db.dailySummaries)..where((t) => t.id.equals(existing.id)))
            .write(entry);
      }
    });
  }

  /// دریافت خلاصه یک تاریخ خاص
  Future<DailySummary?> getSummaryByDate(int date) {
    return (db.select(db.dailySummaries)
          ..where((t) => t.date.equals(date)))
        .getSingleOrNull();
  }

  /// خلاصه‌های روزانه بر اساس محدوده تاریخ (برای نمودار)
  Future<List<DailySummary>> getSummariesByDateRange(int start, int end) {
    return (db.select(db.dailySummaries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }
}
