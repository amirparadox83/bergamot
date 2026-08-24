import 'package:drift/drift.dart';

/// جدول پروفایل کاربر
/// اطلاعات فیزیکی و تنظیمات هدف کاربر در این جدول ذخیره می‌شود
/// هر کاربر فقط یک رکورد پروفایل دارد (رابطه ۱:۱)
class UserProfiles extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// نام نمایشی کاربر (اختیاری)
  TextColumn get displayName => text().nullable()();

  /// جنسیت: ۰=مرد، ۱=زن، ۲=سایر
  IntColumn get gender => integer()();

  /// تاریخ تولد به میلی‌ثانیه از Epoch
  IntColumn get birthDate => integer()();

  /// قد به سانتی‌متر
  RealColumn get heightCm => real()();

  /// وزن به کیلوگرم
  RealColumn get weightKg => real()();

  /// سطح فعالیت: ۰=کم‌تحرک، ۱=سبک، ۲=متوسط، ۳=فعال، ۴=بسیار فعال
  IntColumn get activityLevel => integer()();

  /// نوع هدف: ۰=حفظ وزن، ۱=کاهش وزن، ۲=افزایش وزن
  IntColumn get goalType => integer()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();

  /// زمان آخرین بروزرسانی
  IntColumn get updatedAt => integer()();
}
