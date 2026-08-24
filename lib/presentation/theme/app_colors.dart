import 'package:flutter/material.dart';

/// کلاس رنگ‌های تم روشن برگاموت
///
/// پالت رنگی الهام‌گرفته از طبیعت (تنه درخت برگاموت):
/// سبز طبیعی ملایم، کرم گرم و خنثی.
class BergamotLightColors {
  BergamotLightColors._();

  /// رنگ اصلی سبز — دکمه‌ها، لینک‌ها و عناصر تأکیدی
  static const Color primary = Color(0xFF2D6A4F);

  /// سبز روشن‌تر — هاور، انتخاب فعال، پیشرفت
  static const Color primaryLight = Color(0xFF52B788);

  /// رنگ تأکیدی طلایی — برند برگاموت (تنه درخت)
  static const Color accent = Color(0xFFD4A574);

  /// پس‌زمینه اصلی صفحه
  static const Color background = Color(0xFFFAFAF8);

  /// پس‌زمینه کارت‌ها و کانتینرها
  static const Color surface = Color(0xFFFFFFFF);

  /// متن اصلی
  static const Color text = Color(0xFF1A1A2E);

  /// متن ثانویه — توضیحات، کپشن
  static const Color textSecondary = Color(0xFF6B7280);

  /// حاشیه فیلدها و تقسیم‌کننده‌ها
  static const Color border = Color(0xFFE5E7EB);

  /// موفقیت — تکمیل، تأیید
  static const Color success = Color(0xFF10B981);

  /// هشدار — نیاز به توجه
  static const Color warning = Color(0xFFF59E0B);

  /// خطا — لغو، مشکل
  static const Color error = Color(0xFFEF4444);

  /// پس‌زمینه تگ‌ها و برچسب‌ها
  static const Color tagBg = Color(0xFFE8F5E9);

  /// متن تگ‌ها و برچسب‌ها
  static const Color tagText = Color(0xFF2D6A4F);

  /// رنگ کاربوهیدرات
  static const Color carbs = Color(0xFF3B82F6);

  /// رنگ شکر
  static const Color sugar = Color(0xFFEC4899);

  /// رنگ سدیم
  static const Color sodium = Color(0xFF8B5CF6);

  /// رنگ پتاسیم
  static const Color potassium = Color(0xFF14B8A6);

  /// رنگ کلسیم
  static const Color calcium = Color(0xFFF97316);

  /// رنگ آهن
  static const Color iron = Color(0xFF64748B);

  /// سایه ظریف طبیعی
  static const Color shadow = Color(0x14000000);

  /// رنگی برای overlay ها و ماسک
  static const Color overlay = Color(0x0A000000);
}

/// کلاس رنگ‌های تم تاریک برگاموت
///
/// تم تاریک با حفظ حس Calm و Premium.
class BergamotDarkColors {
  BergamotDarkColors._();

  /// رنگ اصلی — در تم تاریک از سبز روشن‌تر استفاده می‌شود
  static const Color primary = Color(0xFF52B788);

  /// سبز روشن — هاور و انتخاب فعال
  static const Color primaryLight = Color(0xFF74C69D);

  /// رنگ تأکیدی — ثابت در هر دو تم
  static const Color accent = Color(0xFFD4A574);

  /// پس‌زمینه اصلی صفحه تاریک
  static const Color background = Color(0xFF0F1117);

  /// پس‌زمینه کارت‌ها و کانتینرها
  static const Color surface = Color(0xFF1A1A2E);

  /// متن اصلی در تم تاریک
  static const Color text = Color(0xFFE8E6E3);

  /// متن ثانویه
  static const Color textSecondary = Color(0xFF9CA3AF);

  /// حاشیه‌ها
  static const Color border = Color(0xFF2D2D44);

  /// موفقیت
  static const Color success = Color(0xFF34D399);

  /// هشدار
  static const Color warning = Color(0xFFFBBF24);

  /// خطا
  static const Color error = Color(0xFFF87171);

  /// پس‌زمینه تگ‌ها
  static const Color tagBg = Color(0xFF1A3A2A);

  /// متن تگ‌ها
  static const Color tagText = Color(0xFF52B788);

  /// رنگ کاربوهیدرات
  static const Color carbs = Color(0xFF60A5FA);

  /// رنگ شکر
  static const Color sugar = Color(0xFFF472B6);

  /// رنگ سدیم
  static const Color sodium = Color(0xFFA78BFA);

  /// رنگ پتاسیم
  static const Color potassium = Color(0xFF2DD4BF);

  /// رنگ کلسیم
  static const Color calcium = Color(0xFFFB923C);

  /// رنگ آهن
  static const Color iron = Color(0xFF94A3B8);

  /// سایه (تیره‌تر)
  static const Color shadow = Color(0x33000000);

  /// overlay
  static const Color overlay = Color(0x1A000000);
}

/// سیستم رنگ برگاموت — پوشش‌دهنده هر دو تم
///
/// با استفاده از [isDark] رنگ‌های مناسب تم جاری برگردانده می‌شوند.
/// این کلاس به‌عنوان منبع واحد رنگ در سراسر اپ استفاده می‌شود.
@immutable
class BergamotColors {
  /// ساخت سیستم رنگ بر اساس حالت تم
  const BergamotColors({
    required this.isDark,
  });

  /// آیا تم تاریک فعال است؟
  final bool isDark;

  /// رنگ اصلی
  Color get primary => isDark ? BergamotDarkColors.primary : BergamotLightColors.primary;

  /// رنگ اصلی روشن‌تر
  Color get primaryLight => isDark ? BergamotDarkColors.primaryLight : BergamotLightColors.primaryLight;

  /// رنگ تأکیدی
  Color get accent => isDark ? BergamotDarkColors.accent : BergamotLightColors.accent;

  /// پس‌زمینه اصلی
  Color get background => isDark ? BergamotDarkColors.background : BergamotLightColors.background;

  /// پس‌زمینه کارت
  Color get surface => isDark ? BergamotDarkColors.surface : BergamotLightColors.surface;

  /// متن اصلی
  Color get text => isDark ? BergamotDarkColors.text : BergamotLightColors.text;

  /// متن ثانویه
  Color get textSecondary => isDark ? BergamotDarkColors.textSecondary : BergamotLightColors.textSecondary;

  /// حاشیه
  Color get border => isDark ? BergamotDarkColors.border : BergamotLightColors.border;

  /// موفقیت
  Color get success => isDark ? BergamotDarkColors.success : BergamotLightColors.success;

  /// هشدار
  Color get warning => isDark ? BergamotDarkColors.warning : BergamotLightColors.warning;

  /// خطا
  Color get error => isDark ? BergamotDarkColors.error : BergamotLightColors.error;

  /// پس‌زمینه تگ
  Color get tagBg => isDark ? BergamotDarkColors.tagBg : BergamotLightColors.tagBg;

  /// متن تگ
  Color get tagText => isDark ? BergamotDarkColors.tagText : BergamotLightColors.tagText;

  /// رنگ سایه
  Color get shadowColor => isDark ? BergamotDarkColors.shadow : BergamotLightColors.shadow;

  /// رنگ overlay
  Color get overlay => isDark ? BergamotDarkColors.overlay : BergamotLightColors.overlay;

  /// رنگ کاربوهیدرات
  Color get carbs => isDark ? BergamotDarkColors.carbs : BergamotLightColors.carbs;

  /// رنگ شکر
  Color get sugar => isDark ? BergamotDarkColors.sugar : BergamotLightColors.sugar;

  /// رنگ سدیم
  Color get sodium => isDark ? BergamotDarkColors.sodium : BergamotLightColors.sodium;

  /// رنگ پتاسیم
  Color get potassium => isDark ? BergamotDarkColors.potassium : BergamotLightColors.potassium;

  /// رنگ کلسیم
  Color get calcium => isDark ? BergamotDarkColors.calcium : BergamotLightColors.calcium;

  /// رنگ آهن
  Color get iron => isDark ? BergamotDarkColors.iron : BergamotLightColors.iron;

  /// نسخه رنگ‌های تم روشن
  static const BergamotColors light = BergamotColors(isDark: false);

  /// نسخه رنگ‌های تم تاریک
  static const BergamotColors dark = BergamotColors(isDark: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BergamotColors && isDark == other.isDark;

  @override
  int get hashCode => isDark.hashCode;
}

/// اکستنشن برای دسترسی آسان به رنگ‌های برگاموت از BuildContext
extension BergamotColorsExtension on BuildContext {
  /// رنگ‌های برگاموت بر اساس تم فعلی
  ///
  /// ```dart
  /// final colors = context.bergamotColors;
  /// Container(color: colors.primary);
  /// ```
  BergamotColors get bergamotColors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? BergamotColors.dark : BergamotColors.light;
  }
}
