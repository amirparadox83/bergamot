import 'package:drift/drift.dart';

/// جدول علاقه‌مندی‌های Exercise کاربر
///
/// کاربر می‌تواند Exerciseهای مورد علاقه خود را علامت بزند.
/// هر Exercise فقط یک‌بار می‌تواند favorite باشد (UNIQUE constraint).
class FavoriteExercises extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه Exercise (FK)
  IntColumn get exerciseId =>
      integer().customConstraint('REFERENCES exercises(id) ON DELETE CASCADE')();

  /// زمان ایجاد علاقه‌مندی
  IntColumn get createdAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {exerciseId},
      ];
}

/// جدول علاقه‌مندی‌های Workout Template کاربر
///
/// کاربر می‌تواند Workout Templateهای مورد علاقه خود را علامت بزند.
class FavoriteWorkouts extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه WorkoutTemplate (FK)
  IntColumn get templateId =>
      integer().customConstraint('REFERENCES workout_templates(id) ON DELETE CASCADE')();

  /// زمان ایجاد علاقه‌مندی
  IntColumn get createdAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {templateId},
      ];
}
