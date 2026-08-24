import 'package:drift/drift.dart';

/// جدول تنظیمات برنامه (کلید-مقدار)
/// ساختار انعطاف‌پذیر برای اضافه کردن تنظیمات جدید بدون نیاز به migration
/// مثال: notifications=true, theme=dark, language=fa
/// اگر کلیدی یافت نشد، مقدار پیش‌فرض استفاده می‌شود
class AppSettings extends Table {
  /// کلید تنظیمات (کلید اصلی)
  TextColumn get key => text()();

  /// مقدار تنظیمات (به‌صورت رشته ذخیره می‌شود)
  TextColumn get value => text()();

  /// زمان آخرین بروزرسانی
  IntColumn get updatedAt => integer()();

  /// کلید اصلی بر اساس فیلد key
  @override
  Set<Column> get primaryKey => {key};
}