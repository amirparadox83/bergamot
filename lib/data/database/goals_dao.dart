import 'package:drift/drift.dart';
import 'bergamot_database.dart';

/// دیتابیس اهداف کاربر
/// مدیریت اهداف فعال، بروزرسانی پیشرفت و حذف
class GoalsDao {
  final BergamotDatabase db;
  GoalsDao(this.db);

  /// واچ تمام اهداف (فعال و غیرفعال)
  Stream<List<Goal>> watchGoals() {
    return (db.select(db.goals)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// ثبت هدف جدید
  Future<int> insertGoal(GoalsCompanion entry) {
    return db.into(db.goals).insert(entry);
  }

  /// بروزرسانی هدف (مثلاً مقدار فعلی)
  Future<bool> updateGoal(GoalsCompanion entry, int id) {
    return (db.update(db.goals)..where((t) => t.id.equals(id)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// حذف هدف
  Future<int> deleteGoal(int id) {
    return (db.delete(db.goals)..where((t) => t.id.equals(id))).go();
  }
}
