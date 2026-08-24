import 'package:drift/drift.dart';

/// جدول اهداف کاربر
/// اهداف می‌توانند از انواع مختلف باشند: وزن، تمرین، خواب، آب یا سفارشی
/// نوع هدف: ۰=وزن، ۱=تمرین، ۲=خواب، ۳=آب، ۴=سفارشی
/// هر هدف دارای مقدار هدف و مقدار فعلی برای محاسبه پیشرفت است
class Goals extends Table {
  /// شناسه یکتای خودکار
  IntColumn get id => integer().autoIncrement()();

  /// عنوان هدف
  TextColumn get title => text()();

  /// نوع هدف: ۰=وزن، ۱=تمرین، ۲=خواب، ۳=آب، ۴=سفارشی
  IntColumn get type => integer()();

  /// مقدار هدف
  RealColumn get targetValue => real()();

  /// مقدار فعلی - پیش‌فرض صفر
  RealColumn get currentValue => real().withDefault(const Constant(0))();

  /// واحد اندازه‌گیری (مثلاً کیلوگرم، دقیقه، میلی‌لیتر)
  TextColumn get unit => text()();

  /// مهلت رسیدن به هدف (اختیاری)
  IntColumn get deadline => integer().nullable()();

  /// آیا هدف تکمیل شده است؟ - پیش‌فرض خیر
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// زمان ایجاد رکورد
  IntColumn get createdAt => integer()();
}
