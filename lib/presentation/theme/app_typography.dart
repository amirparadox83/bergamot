import 'package:flutter/material.dart';

/// نام خانواده فونت اصلی اپلیکیشن
const String kFontFamily = 'Vazirmatn';

/// سیستم تایپوگرافی برگاموت
///
/// فونت Vazirmatn برای زبان فارسی بهینه‌سازی شده و وزن‌های ۱۰۰ تا ۹۰۰
/// را پشتیبانی می‌کند. ارتفاع خط برای متن فارسی ۱.۸ تنظیم شده
/// (بالاتر از انگلیسی به‌دلیل پیچیدگی حروف).
@immutable
class BergamotTypography {
  /// ساختار تایپوگرافی با رنگ متن اصلی
  const BergamotTypography({required this.textStyle});

  /// رنگ متن اصلی برای اعمال روی تمام استایل‌ها
  final Color textStyle;

  /// --- نمایشی (Display) ---

  /// نمایشی بزرگ — ۳۲ پوینت، Black (۹۰۰)
  ///
  /// کاربرد: صفحه شروع، جشن دستاورد، عناوین بزرگ ویژه
  TextStyle get displayLarge => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1.4,
        letterSpacing: 0,
        color: textStyle,
      );

  /// نمایشی متوسط — ۲۴ پوینت، Bold (۷۰۰)
  ///
  /// کاربرد: Hero section، عنوان‌های ویژه صفحه
  TextStyle get displayMedium => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 0,
        color: textStyle,
      );

  /// --- تیتر (Headline) ---

  /// تیتر بزرگ — ۲۰ پوینت، Bold (۷۰۰)
  ///
  /// کاربرد: عنوان بخش‌های اصلی
  TextStyle get headlineLarge => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.6,
        letterSpacing: 0,
        color: textStyle,
      );

  /// تیتر متوسط — ۱۸ پوینت، SemiBold (۶۰۰)
  ///
  /// کاربرد: عنوان کارت‌ها، زیربخش‌ها
  TextStyle get headlineMedium => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.6,
        letterSpacing: 0,
        color: textStyle,
      );

  /// --- عنوان (Title) ---

  /// عنوان بزرگ — ۱۶ پوینت، Bold (۷۰۰)
  ///
  /// کاربرد: عنوان کارت‌های تعاملی، لیست آیتم‌ها
  TextStyle get titleLarge => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.7,
        letterSpacing: 0,
        color: textStyle,
      );

  /// عنوان متوسط — ۱۶ پوینت، SemiBold (۶۰۰)
  ///
  /// کاربرد: نام آیتم‌ها، عناوین دکمه‌ها
  TextStyle get titleMedium => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.7,
        letterSpacing: 0,
        color: textStyle,
      );

  /// --- بدنه (Body) ---

  /// متن بدنه بزرگ — ۱۶ پوینت، Regular (۴۰۰)، ارتفاع خط ۱.۸
  ///
  /// کاربرد: پاراگراف‌های اصلی، توضیحات طولانی
  TextStyle get bodyLarge => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.8,
        letterSpacing: 0.2,
        color: textStyle,
      );

  /// متن بدنه متوسط — ۱۴ پوینت، Regular (۴۰۰)، ارتفاع خط ۱.۸
  ///
  /// کاربرد: متن معمولی، توضیحات کوتاه
  TextStyle get bodyMedium => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.8,
        letterSpacing: 0.2,
        color: textStyle,
      );

  /// متن بدنه کوچک — ۱۲ پوینت، Regular (۴۰۰)
  ///
  /// کاربرد: کپشن، یادداشت‌ها
  TextStyle get bodySmall => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.6,
        letterSpacing: 0.1,
        color: textStyle,
      );

  /// --- برچسب (Label) ---

  /// برچسب بزرگ — ۱۲ پوینت، Medium (۵۰۰)
  ///
  /// کاربرد: برچسب‌ها، تگ‌ها، متن دکمه‌ها
  TextStyle get labelLarge => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0.3,
        color: textStyle,
      );

  /// برچسب متوسط — ۱۱ پوینت، Medium (۵۰۰)
  ///
  /// کاربرد: متادیتا، زمان، تعداد
  TextStyle get labelMedium => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.3,
        color: textStyle,
      );

  /// برچسب کوچک — ۱۰ پوینت، Medium (۵۰۰)
  ///
  /// کاربرد: اعلان‌ها، badges، overline
  TextStyle get labelSmall => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.4,
        color: textStyle,
      );

  /// --- کمکی ---

  /// ساخت TextTheme استاندارد فلتر برای استفاده در ThemeData
  ///
  /// تمام استایل‌ها با رنگ [textColor] ساخته می‌شوند.
  static TextTheme toTextTheme({
    required Color textColor,
  }) {
    final base = BergamotTypography(textStyle: textColor);

    return TextTheme(
      displayLarge: base.displayLarge,
      displayMedium: base.displayMedium,
      headlineLarge: base.headlineLarge,
      headlineMedium: base.headlineMedium,
      titleLarge: base.titleLarge,
      titleMedium: base.titleMedium,
      bodyLarge: base.bodyLarge,
      bodyMedium: base.bodyMedium,
      bodySmall: base.bodySmall,
      labelLarge: base.labelLarge,
      labelMedium: base.labelMedium,
      labelSmall: base.labelSmall,
    ).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
  }
}
