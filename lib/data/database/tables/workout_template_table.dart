import 'package:drift/drift.dart';

/// جدول الگوهای تمرین (Workout Templates)
///
/// این جدول از session history (Workouts) جدا است.
/// - WorkoutTemplate: تعریف آماده یک جلسه (مثلاً "Full Body 15 min")
/// - Workout (session): اجرای واقعی آن توسط کاربر در یک تاریخ مشخص
///
/// هر Template می‌تواند چندین Exercise داشته باشد (WorkoutTemplateExercises).
/// Templates می‌توانند preset باشند (source='BERGAMOT_PRESET') یا
/// سفارشی کاربر (source='CUSTOM').
class WorkoutTemplates extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// کد ثابت template (مثلاً 'full_body_beginner_15min')
  TextColumn get code => text().unique()();

  /// نام فارسی
  TextColumn get nameFa => text()();

  /// نام انگلیسی (اختیاری)
  TextColumn get nameEn => text().nullable()();

  /// نسخه نرمالایز شده فارسی — برای search
  TextColumn get normalizedNameFa =>
      text().withDefault(const Constant(''))();

  /// نسخه نرمالایز شده انگلیسی
  TextColumn get normalizedNameEn =>
      text().withDefault(const Constant(''))();

  /// توضیحات فارسی (اختیاری)
  TextColumn get descriptionFa => text().nullable()();

  /// سطح دشواری: 1=Beginner, 2=Intermediate, 3=Advanced
  IntColumn get difficulty => integer().withDefault(const Constant(1))();

  /// کد هدف (مثلاً 'weight_loss', 'muscle_building')
  /// nullable برای templates بدون هدف مشخص
  TextColumn get goalCode => text().nullable()();

  /// مدت زمان تخمینی به دقیقه (اختیاری)
  IntColumn get durationMinutes => integer().nullable()();

  /// تخمین کالری (اختیاری — محاسبه rule-based، نه AI)
  IntColumn get caloriesEstimate => integer().nullable()();

  /// تجهیزات مورد نیاز (CSV of equipment codes)
  /// مثلاً 'no_equipment' یا 'dumbbells,mat'
  TextColumn get equipment => text().withDefault(const Constant('no_equipment'))();

  /// گروه‌های عضلانی هدف (CSV of muscle codes)
  /// مثلاً 'chest,shoulders,triceps'
  TextColumn get muscleGroups =>
      text().withDefault(const Constant('full_body'))();

  /// آیا template آماده Bergamot است؟ (preset)
  /// false برای templates سفارشی کاربر
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();

  /// آیا Quick Workout است؟ (5/7/10/15/20/30 min)
  BoolColumn get isQuick => boolean().withDefault(const Constant(false))();

  /// منبع: 'BERGAMOT_PRESET' | 'CUSTOM'
  TextColumn get source =>
      text().withDefault(const Constant('CUSTOM'))();

  /// شناسه خارجی (برای presetها که از data migration می‌آیند)
  TextColumn get externalId => text().nullable()();

  /// زمان ایجاد
  IntColumn get createdAt => integer()();

  /// زمان آخرین به‌روزرسانی
  IntColumn get updatedAt => integer().nullable()();
}

/// جدول آیتم‌های هر Workout Template
///
/// هر رکورد یک Exercise در یک Template مشخص است.
/// ترتیب با orderIndex حفظ می‌شود.
class WorkoutTemplateExercises extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// شناسه Template
  IntColumn get templateId =>
      integer().customConstraint('REFERENCES workout_templates(id) ON DELETE CASCADE')();

  /// شناسه Exercise (FK)
  IntColumn get exerciseId =>
      integer().customConstraint('REFERENCES exercises(id) ON DELETE CASCADE')();

  /// ترتیب در template (0-based)
  IntColumn get orderIndex => integer()();

  /// تعداد ست‌ها (پیش‌فرض 3)
  IntColumn get sets => integer().withDefault(const Constant(3))();

  /// تعداد تکرار در هر ست (اختیاری)
  /// برای تمرین‌های زمان‌محور مثل Plank این NULL می‌شود
  IntColumn get reps => integer().nullable()();

  /// مدت زمان هر ست به ثانیه (اختیاری)
  /// برای Plank: 30, 45, 60 ثانیه
  /// برای Squat: NULL (rep-based)
  IntColumn get durationSeconds => integer().nullable()();

  /// استراحت بین ست‌ها به ثانیه (پیش‌فرض 30)
  IntColumn get restSeconds => integer().withDefault(const Constant(30))();

  /// آیا این تمرین زمان‌محور است؟ (مثل Plank)
  /// false برای تمرین‌های rep-based (مثل Push-up)
  BoolColumn get isTimed => boolean().withDefault(const Constant(false))();

  /// یادداشت اختیاری فارسی
  TextColumn get notesFa => text().nullable()();
}
