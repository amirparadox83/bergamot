import 'package:drift/drift.dart';

/// جدول عادت‌ها
/// هر عادت دارای فرکانس و تعداد هدف است
/// عادت‌های بایگانی‌شده در لیست نمایش داده نمی‌شوند
/// فرکانس: ۰=روزانه، ۱=هفتگی
/// icon و color برای نمایش بصری عادت استفاده می‌شوند
class Habits extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// نام عادت
  TextColumn get name => text()();

  /// فرکانس: ۰=روزانه، ۱=هفتگی
  IntColumn get frequency => integer()();

  /// تعداد هدف در هر دوره - پیش‌فرض ۱
  IntColumn get targetCount => integer().withDefault(const Constant(1))();

  /// آیکون عادت (نام آیکون از مجموعه آیکون‌ها)
  TextColumn get icon => text().nullable()();

  /// رنگ عادت (مقدار ARGB)
  IntColumn get color => integer().nullable()();

  /// آیا عادت بایگانی شده است؟ - پیش‌فرض خیر
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
