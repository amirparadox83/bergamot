import 'package:flutter/material.dart';

/// سیستم فاصله‌گذاری برگاموت
///
/// بر اساس گرید ۴ پیکسلی. تمام فواصل، حاشیه‌ها و اندازه‌ها
/// ضریبی از ۴ پیکسل هستند تا هماهنگی بصری حفظ شود.
class BergamotSpacing {
  BergamotSpacing._();

  // --- فاصله‌گذاری (Spacing) ---

  /// ۴ پیکسل — فاصله بسیار کوچک
  static const double s4 = 4.0;

  /// ۸ پیکسل — فاصله کوچک
  static const double s8 = 8.0;

  /// ۱۲ پیکسل — فاصله متوسط‌کوچک
  static const double s12 = 12.0;

  /// ۱۶ پیکسل — فاصله استاندارد
  static const double s16 = 16.0;

  /// ۲۴ پیکسل — فاصله متوسط
  static const double s24 = 24.0;

  /// ۳۲ پیکسل — فاصله بزرگ
  static const double s32 = 32.0;

  /// ۴۸ پیکسل — فاصله خیلی بزرگ
  static const double s48 = 48.0;

  /// ۶۴ پیکسل — فاصله بخش‌بندی
  static const double s64 = 64.0;

  // --- گردی گوشه (Border Radius) ---

  /// ۴ پیکسل — گردی بسیار کم (badge, small elements)
  static const Radius r4 = Radius.circular(4.0);

  /// ۸ پیکسل — گردی کم (کوچک‌ترین کارت‌ها)
  static const Radius r8 = Radius.circular(8.0);

  /// ۱۰ پیکسل — گردی متوسط (فیلدهای ورودی)
  static const Radius r10 = Radius.circular(10.0);

  /// ۱۲ پیکسل — گردی استاندارد (دکمه‌ها)
  static const Radius r12 = Radius.circular(12.0);

  /// ۱۶ پیکسل — گردی بزرگ (کارت‌ها)
  static const Radius r16 = Radius.circular(16.0);

  /// ۲۰ پیکسل — گردی pill (تب، chip)
  static const Radius r20 = Radius.circular(20.0);

  /// BorderRadialus برای استفاده مستقیم در ویجت‌ها
  static const BorderRadius br4 = BorderRadius.all(r4);
  static const BorderRadius br8 = BorderRadius.all(r8);
  static const BorderRadius br10 = BorderRadius.all(r10);
  static const BorderRadius br12 = BorderRadius.all(r12);
  static const BorderRadius br16 = BorderRadius.all(r16);
  static const BorderRadius br20 = BorderRadius.all(r20);

  // --- سایه (Shadows) ---

  /// سایه ظریف طبیعی — مناسب برای کارت‌ها در حالت عادی
  ///
  /// 0 2px 8px rgba(0,0,0,0.08)
  static const BoxShadow shadowSubtle = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  /// سایه متوسط — مناسب برای کارت‌های تعاملی و هاور
  ///
  /// 0 4px 16px rgba(0,0,0,0.10)
  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );

  /// سایه بزرگ — مناسب برای Bottom Sheet و Dialog
  ///
  /// 0 8px 32px rgba(0,0,0,0.12)
  static const BoxShadow shadowLarge = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 8),
    blurRadius: 32,
    spreadRadius: 0,
  );

  /// لیست سایه‌ها برای کارت‌ها
  static const List<BoxShadow> cardShadow = [shadowSubtle];

  /// لیست سایه‌ها برای کارت‌های تعاملی
  static const List<BoxShadow> cardShadowInteractive = [shadowMedium];

  /// لیست سایه‌ها برای Bottom Sheet و Dialog
  static const List<BoxShadow> elevatedShadow = [shadowLarge];

  // --- مدت زمان انیمیشن (Durations) ---

  /// ۱۵۰ میلی‌ثانیه — انیمیشن سریع
  ///
  /// کاربرد: هاور، تغییر وضعیت دکمه، micro-interactions
  static const Duration fast = Duration(milliseconds: 150);

  /// ۳۰۰ میلی‌ثانیه — انیمیشن متوسط
  ///
  /// کاربرد: باز/بسته شدن Sheet، انتقال بین صفحات
  static const Duration medium = Duration(milliseconds: 300);

  /// ۵۰۰ میلی‌ثانیه — انیمیشن کند
  ///
  /// کاربرد: ورود به صفحه، transition های اصلی
  static const Duration slow = Duration(milliseconds: 500);

  // --- اندازه‌های کمکی ---

  /// ارتفاع حداقل Target لمسی — ۴۸ پیکسل (Accessibility)
  static const double touchTargetMin = 48.0;

  /// ارتفاع Bottom Navigation Bar
  static const double bottomNavHeight = 64.0;

  /// ضخامت حاشیه استاندارد
  static const double borderWidth = 1.0;

  /// ضخامت تقسیم‌کننده
  static const double dividerThickness = 1.0;
}
