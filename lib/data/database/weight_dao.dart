import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// دیتابیس وزن
/// مدیریت ثبت و نمودار وزن کاربر
class WeightDao {
  final BergamotDatabase db;
  WeightDao(this.db);

  /// واچ تمام ورودی‌های وزن
  Stream<List<WeightEntry>> watchAllWeights() {
    return (db.select(db.weightEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  /// ثبت وزن جدید
  Future<int> addWeight(WeightEntriesCompanion entry) {
    return db.into(db.weightEntries).insert(entry);
  }

  /// حذف ورودی وزن
  Future<int> deleteWeight(int id) {
    return (db.delete(db.weightEntries)..where((t) => t.id.equals(id)))
        .go();
  }

  /// ورودی‌های وزن بر اساس محدوده تاریخ (برای نمودار)
  Future<List<WeightEntry>> getWeightByDateRange(int start, int end) {
    return (db.select(db.weightEntries)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// آخرین وزن ثبت‌شده
  Future<WeightEntry?> getLatestWeight() {
    return (db.select(db.weightEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }
}
