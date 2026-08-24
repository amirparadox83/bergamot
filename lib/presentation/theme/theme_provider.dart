import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// کلید ذخیره‌سازی ترجیح تم در SharedPreferences
const String _kThemeModeKey = 'bergamot_theme_mode';

/// Notifier مدیریت حالت تم
///
/// ترجیح کاربر در [SharedPreferences] ذخیره می‌شود تا
/// پس از بستن اپ حفظ شود. پیش‌فرض: حالت سیستم.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // بارگذاری ترجیح ذخیره‌شده — بدون انتظار (async init)
    _loadSavedThemeMode();
    // پیش‌فرض: پیروی از تنظیمات سیستم
    return ThemeMode.system;
  }

  /// بارگذاری ترجیح ذخیره‌شده از حافظه محلی
  Future<void> _loadSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_kThemeModeKey);
      if (index != null && index >= 0 && index < ThemeMode.values.length) {
        state = ThemeMode.values[index];
      }
    } catch (_) {
      // در صورت خطا، پیش‌فرض (system) حفظ می‌شود
    }
  }

  /// تغییر حالت تم
  ///
  /// ترجیح جدید بلافاصله اعمال و در حافظه محلی ذخیره می‌شود.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeModeKey, mode.index);
    } catch (_) {
      // ذخیره‌سازی best-effort — خطا مانع اعمال تم نمی‌شود
    }
  }
}

/// Provider مدیر حالت تم
///
/// ```dart
/// final themeMode = ref.watch(themeModeProvider);
/// ```
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Provider تم جاری اپلیکیشن
///
/// بر اساس [ThemeMode] ذخیره‌شده، ThemeData مناسب برمی‌گرداند.
/// این provider مستقیماً در MaterialApp.router استفاده می‌شود.
///
/// ```dart
/// final theme = ref.watch(bergamotThemeProvider);
/// MaterialApp.router(theme: theme.light, darkTheme: theme.dark, themeMode: theme.mode);
/// ```
final bergamotThemeProvider = Provider<({ThemeData light, ThemeData dark, ThemeMode mode})>(
  (ref) {
    final mode = ref.watch(themeModeProvider);
    return (
      light: BergamotTheme.light(),
      dark: BergamotTheme.dark(),
      mode: mode,
    );
  },
);
