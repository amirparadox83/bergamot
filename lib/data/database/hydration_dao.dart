import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// دیتابیس دیتابیس آب و هیدراتاسیون
/// مدیریت ثبت و پیگیری آب دریافتی کاربر
class HydrationDao {
  final BergamotDatabase db;
  HydrationDao(this.db);

  /// واچ ورودی‌های آب امروز
  Stream<List<WaterEntry>> watchTodayWater() {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 24 * 60 * 60 * 1000;
    return (db.select(db.waterEntries)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.time)]))
        .watch();
  }

  /// مجموع آب دریافتی امروز (میلی‌لیتر)
  Future<int> getTodayTotalMl() async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 24 * 60 * 60 * 1000;
    final query = db.selectOnly(db.waterEntries)
      ..addColumns([db.waterEntries.amountMl.sum()])
      ..where(db.waterEntries.date.isBetweenValues(startOfDay, endOfDay));
    final row = await query.getSingleOrNull();
    return row?.read(db.waterEntries.amountMl.sum()) ?? 0;
  }

  /// ثبت سریع آب
  Future<int> addWater(int amountMl) {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return db.into(db.waterEntries).insert(WaterEntriesCompanion(
      date: Value(startOfDay),
      amountMl: Value(amountMl),
      time: Value(now.millisecondsSinceEpoch),
      createdAt: Value(now.millisecondsSinceEpoch),
    ));
  }

  /// حذف ورودی آب
  Future<int> deleteWaterEntry(int id) {
    return (db.delete(db.waterEntries)..where((t) => t.id.equals(id))).go();
  }

  /// ورودی‌های آب بر اساس محدوده تاریخ (برای نمودار)
  Future<List<WaterEntry>> getWaterByDateRange(int start, int end) {
    return (db.select(db.waterEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }
}
