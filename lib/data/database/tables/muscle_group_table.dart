import 'package:drift/drift.dart';

/// جدول گروه‌های عضلانی Bergamot
///
/// ۱۶ گروه عضلانی استاندارد به‌عنوان reference data.
/// هر Exercise به یک primaryMuscle و چندین secondaryMuscle متصل می‌شود
/// (از طریق جدول ExerciseMuscleGroups).
class MuscleGroups extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// کد ثابت گروه عضلانی (مثلاً 'chest', 'back', 'quadriceps')
  TextColumn get code => text().unique()();

  /// نام انگلیسی
  TextColumn get nameEn => text()();

  /// نام فارسی
  TextColumn get nameFa => text()();

  /// نسخه نرمالایز شده فارسی (برای search)
  TextColumn get normalizedNameFa =>
      text().withDefault(const Constant(''))();

  /// نسخه نرمالایز شده انگلیسی
  TextColumn get normalizedNameEn =>
      text().withDefault(const Constant(''))();

  /// آیکون Material برای نمایش
  TextColumn get icon => text().withDefault(const Constant('fitness_center'))();
}

/// جدول junction بین Exercise و MuscleGroup
///
/// هر Exercise می‌تواند چندین گروه عضلانی داشته باشد:
/// - یک primary (نقش اصلی)
/// - چندین secondary (نقش کمکی)
///
/// این ساختار به‌جای فیلد text کاما-جداشده در Exercises قدیمی استفاده می‌شود.
/// فیلد muscleGroups قدیمی حفظ می‌شود برای backward compatibility ولی
/// در queries جدید از این جدول استفاده می‌شود.
class ExerciseMuscleGroups extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه Exercise (FK)
  IntColumn get exerciseId =>
      integer().customConstraint('REFERENCES exercises(id) ON DELETE CASCADE')();

  /// کد MuscleGroup (FK به muscle_groups.code)
  TextColumn get muscleGroupCode => text()();

  /// نقش: 'primary' یا 'secondary'
  TextColumn get role => text().withDefault(const Constant('secondary'))();

  /// ترتیب نمایش (مخصوصاً برای secondary muscles)
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
