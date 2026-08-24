import 'package:drift/drift.dart';

/// جدول دسته‌بندی‌های غذایی Bergamot
///
/// ۲۲ دسته‌بندی با کد ثابت برای استفاده در Food.categoryId
/// و نمایش نام فارسی/انگلیسی در UI.
class FoodCategories extends Table {
  /// شناسه یکتای عددی
  IntColumn get id => integer().autoIncrement()();

  /// کد ثابت دسته (مثلاً 'fruits', 'vegetables', 'iranian_foods')
  TextColumn get code => text().unique()();

  /// نام انگلیسی
  TextColumn get nameEn => text()();

  /// نام فارسی
  TextColumn get nameFa => text()();

  /// نسخه نرمالایز شده فارسی — برای search
  TextColumn get normalizedNameFa => text().withDefault(const Constant(''))();

  /// نسخه نرمالایز شده انگلیسی
  TextColumn get normalizedNameEn => text().withDefault(const Constant(''))();

  /// آیکون پیش‌فرض Material Icon برای نمایش
  TextColumn get icon => text().withDefault(const Constant('restaurant'))();
}
