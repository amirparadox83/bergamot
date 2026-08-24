import 'package:drift/drift.dart';

/// جدول برنامه‌های تمرینی چندروزه (Workout Programs)
///
/// هر Program شامل چند روز (WorkoutProgramDays) است.
/// هر روز می‌تواند یک Template مشخص داشته باشد یا rest day باشد.
///
/// مثلاً: "30 Day Beginner" شامل ۳۰ روز است که در روزهای فرد یک Template Full Body،
/// در روزهای زوج rest، و الی آخر.
class WorkoutPrograms extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// کد ثابت program (مثلاً 'beginner_7day')
  TextColumn get code => text().unique()();

  /// نام فارسی
  TextColumn get nameFa => text()();

  /// نام انگلیسی (اختیاری)
  TextColumn get nameEn => text().nullable()();

  /// توضیحات فارسی (اختیاری)
  TextColumn get descriptionFa => text().nullable()();

  /// سطح دشواری: 1=Beginner, 2=Intermediate, 3=Advanced
  IntColumn get difficulty => integer().withDefault(const Constant(1))();

  /// کد هدف (اختیاری)
  TextColumn get goalCode => text().nullable()();

  /// تعداد روزهای program
  IntColumn get dayCount => integer()();

  /// آیا program سفارشی کاربر است؟
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// منبع: 'BERGAMOT_PRESET' | 'CUSTOM'
  TextColumn get source =>
      text().withDefault(const Constant('BERGAMOT_PRESET'))();

  /// زمان ایجاد
  IntColumn get createdAt => integer()();
}

/// جدول روزهای یک Program
///
/// ترتیب با dayNumber حفظ می‌شود.
/// اگر isRestDay=true باشد، templateId باید NULL باشد.
class WorkoutProgramDays extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه Program
  IntColumn get programId =>
      integer().customConstraint('REFERENCES workout_programs(id) ON DELETE CASCADE')();

  /// شماره روز (1-based)
  IntColumn get dayNumber => integer()();

  /// نام فارسی روز (مثلاً 'روز ۱ - Full Body')
  TextColumn get nameFa => text()();

  /// آیا این روز استراحت است؟
  /// اگر true باشد، templateId باید NULL باشد.
  /// Streak نباید به‌خاطر rest day خراب شود.
  BoolColumn get isRestDay => boolean().withDefault(const Constant(false))();

  /// شناسه WorkoutTemplate برای این روز (NULL برای rest days)
  IntColumn get templateId =>
      integer().nullable().customConstraint('REFERENCES workout_templates(id) ON DELETE SET NULL')();

  /// یادداشت فارسی اختیاری
  TextColumn get notesFa => text().nullable()();
}
