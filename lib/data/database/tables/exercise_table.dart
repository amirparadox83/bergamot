import 'package:drift/drift.dart';

/// جدول تمرینات Bergamot — schema v7
///
/// دسته‌بندی‌ها: عضلات بالاتنه، پایین‌تنه، هسته، کاردیو، کشش
/// تجهیزات: وزن بدن، دمبل، هالتر، دستگاه، کابل، باند
/// دشواری: ۱=مبتدی، ۲=متوسط، ۳=پیشرفته
/// دسته‌بندی: chest/back/shoulder/bicep/tricep/leg/glute/core/cardio/stretch
/// تجهیزات: bodyweight/dumbbell/barbell/machine/cable/band
///
/// در v7 فیلدهای جدید اضافه شد:
///   - normalizedNameFa/En برای search
///   - primaryMuscle (FK به MuscleGroups.code)
///   - exerciseType ('rep_based' | 'time_based')
///   - isBodyweight, isTimed
///   - defaultSets, defaultReps, defaultDurationSeconds, restSeconds
///   - caloriesEstimatePerRep (rule-based, no AI)
///   - tips, commonMistakes
///   - source, externalId (provenance)
///   - imageAsset, videoUrl (placeholder for future)
///   - updatedAt
///
/// muscleGroups قدیمی (CSV) همچنان حفظ می‌شود برای backward compatibility
/// با کد قدیمی که آن را می‌خواند. در v7 queries از جدول ExerciseMuscleGroups
/// استفاده می‌کنند.
class Exercises extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// نام فارسی تمرین
  TextColumn get nameFa => text()();

  /// نام انگلیسی تمرین (اختیاری)
  TextColumn get nameEn => text().nullable()();

  /// نسخه نرمالایز شده فارسی (ي→ی، ك→ک، ZWNJ→space، lowercase)
  TextColumn get normalizedNameFa =>
      text().nullable().withDefault(const Constant(''))();

  /// نسخه نرمالایز شده انگلیسی
  TextColumn get normalizedNameEn =>
      text().nullable().withDefault(const Constant(''))();

  /// دسته‌بندی تمرین (legacy: chest/back/...)
  TextColumn get category => text()();

  /// تجهیزات مورد نیاز (legacy: bodyweight/dumbbell/...)
  TextColumn get equipment => text()();

  /// سطح دشواری: ۱ تا ۳
  IntColumn get difficulty => integer()();

  /// دستورالعمل فارسی تمرین (اختیاری)
  TextColumn get instructionsFa => text().nullable()();

  /// گروه‌های عضلانی (CSV — legacy)
  /// در v7 از جدول ExerciseMuscleGroups استفاده می‌شود، ولی این فیلد حفظ می‌شود.
  TextColumn get muscleGroups => text()();

  // ── فیلدهای جدید v7 ────────────────────────────────────────────────────

  /// گروه عضلانی اصلی (کد MuscleGroup)
  /// مثلاً 'chest', 'back', 'quadriceps'
  /// این فیلد برای فیلتر سریع استفاده می‌شود.
  TextColumn get primaryMuscle => text().nullable()();

  /// نوع تمرین: 'rep_based' | 'time_based'
  /// - rep_based: مثل Push-up (۳ ست × ۱۲ تکرار)
  /// - time_based: مثل Plank (۳ ست × ۳۰ ثانیه)
  TextColumn get exerciseType =>
      text().withDefault(const Constant('rep_based'))();

  /// آیا تمرین وزن بدن است؟ (equipment='bodyweight')
  /// برای فیلتر "بدون تجهیزات"
  BoolColumn get isBodyweight =>
      boolean().withDefault(const Constant(false))();

  /// آیا تمرین زمان‌محور است؟
  BoolColumn get isTimed => boolean().withDefault(const Constant(false))();

  /// تعداد ست پیش‌فرض
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();

  /// تعداد تکرار پیش‌فرض (NULL برای time-based)
  IntColumn get defaultReps => integer().nullable()();

  /// مدت زمان پیش‌فرض به ثانیه (NULL برای rep-based)
  IntColumn get defaultDurationSeconds => integer().nullable()();

  /// استراحت بین ست‌ها به ثانیه
  IntColumn get restSeconds => integer().withDefault(const Constant(30))();

  /// تخمین کالری به‌ازای هر تکرار (rule-based, no AI)
  /// برای محاسبه کل کالری یک جلسه: sum(reps × caloriesEstimatePerRep)
  /// NULL = داده موجود نیست (NEEDS_VERIFICATION)
  RealColumn get caloriesEstimatePerRep => real().nullable()();

  /// نکات فارسی (اختیاری)
  TextColumn get tips => text().nullable()();

  /// اشتباهات رایج فارسی (اختیاری)
  TextColumn get commonMistakes => text().nullable()();

  /// منبع داده
  /// - 'BERGAMOT_LEGACY': از iranian_exercises.dart قدیم (IDs 1-45)
  /// - 'BERGAMOT_CURATED': از dataset جدید Bergamot
  /// - 'CUSTOM': تمرین سفارشی کاربر
  TextColumn get source =>
      text().withDefault(const Constant('CUSTOM'))();

  /// شناسه خارجی (مثلاً 'BERGAMOT_CURATED:push_up')
  TextColumn get externalId => text().nullable()();

  /// مسیر asset تصویر (NULL = تصویر موجود نیست)
  /// در نسخه اول بدون تصاویر — placeholder برای آینده.
  TextColumn get imageAsset => text().nullable()();

  /// URL ویدیو (NULL = ویدیو موجود نیست)
  TextColumn get videoUrl => text().nullable()();

  // ── Legacy fields ──────────────────────────────────────────────────────

  /// آیا تمرین سفارشی کاربر است؟
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();

  /// زمان آخرین به‌روزرسانی (v7)
  IntColumn get updatedAt => integer().nullable()();
}
