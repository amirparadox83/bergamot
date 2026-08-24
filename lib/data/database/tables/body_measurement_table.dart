import 'package:drift/drift.dart';

/// جدول اندازه‌گیری بدن
/// هر رکورد شامل اندازه‌گیری‌های مختلف بدن در یک روز است
/// برای ردیابی تغییرات بدنی و پیشرفت استفاده می‌شود
/// تمام فیلدهای اندازه اختیاری هستند (کاربر ممکن است فقط برخی را ثبت کند)
class BodyMeasurements extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// تاریخ به میلی‌ثانیه Epoch (ابتدای روز)
  IntColumn get date => integer()();

  /// دور سینه به سانتی‌متر
  RealColumn get chestCm => real().nullable()();

  /// دور کمر به سانتی‌متر
  RealColumn get waistCm => real().nullable()();

  /// دور باسن به سانتی‌متر
  RealColumn get hipCm => real().nullable()();

  /// دور بازو به سانتی‌متر
  RealColumn get bicepCm => real().nullable()();

  /// دور ران به سانتی‌متر
  RealColumn get thighCm => real().nullable()();

  /// دور گردن به سانتی‌متر
  RealColumn get neckCm => real().nullable()();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
