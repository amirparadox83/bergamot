import 'package:drift/drift.dart' hide Column;
import 'bergamot_database.dart';

/// دیتابیس برنامه روزانه
/// مدیریت آیتم‌های برنامه روزانه شامل دریافت، ذخیره، تکمیل و ویرایش
final class DailyPlanDao {
  final BergamotDatabase db;
  DailyPlanDao(this.db);

  /// دریافت تمام آیتم‌های برنامه برای یک تاریخ، مرتب بر اساس زمان
  Future<List<DailyPlan>> getPlanForDate(int dateMs) {
    return (db.select(db.dailyPlans)
          ..where((t) => t.date.equals(dateMs))
          ..orderBy([
            (t) => OrderingTerm.asc(t.scheduledTime),
          ]))
        .get();
  }

  /// واچ برنامه روزانه برای یک تاریخ
  Stream<List<DailyPlan>> watchPlanForDate(int dateMs) {
    return (db.select(db.dailyPlans)
          ..where((t) => t.date.equals(dateMs))
          ..orderBy([
            (t) => OrderingTerm.asc(t.scheduledTime),
          ]))
        .watch();
  }

  /// ذخیره برنامه روزانه — حذف آیتم‌های قبلی و درج آیتم‌های جدید
  Future<void> savePlanForDate(
    int dateMs,
    List<DailyPlansCompanion> items,
  ) async {
    await db.transaction(() async {
      await (db.delete(db.dailyPlans)..where((t) => t.date.equals(dateMs))).go();
      for (final item in items) {
        await db.into(db.dailyPlans).insert(item);
      }
    });
  }

  /// تاگل وضعیت تکمیل آیتم
  Future<void> toggleComplete(int id) async {
    final item = await (db.select(db.dailyPlans)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item == null) return;

    final nowCompleted = !item.isCompleted;
    await (db.update(db.dailyPlans)..where((t) => t.id.equals(id))).write(
      DailyPlansCompanion(
        isCompleted: Value(nowCompleted),
        completedAt: Value(nowCompleted ? DateTime.now().millisecondsSinceEpoch : null),
      ),
    );
  }

  /// بروزرسانی زمان برنامه‌ریزی‌شده توسط کاربر
  Future<void> updateScheduledTime(int id, int newTimeMs) async {
    await (db.update(db.dailyPlans)..where((t) => t.id.equals(id))).write(
      DailyPlansCompanion(
        scheduledTime: Value(newTimeMs),
        isUserModified: const Value(true),
      ),
    );
  }

  /// بررسی وجود برنامه برای یک تاریخ
  Future<bool> hasPlanForDate(int dateMs) async {
    final result = await (db.select(db.dailyPlans)
          ..where((t) => t.date.equals(dateMs))
          ..limit(1))
        .getSingleOrNull();
    return result != null;
  }
}
