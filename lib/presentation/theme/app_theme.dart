import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// تم اصلی اپلیکیشن برگاموت
///
/// دو حالت [light] و [dark] دارد و تمام تنظیمات بصری اپ
/// شامل رنگ، تایپوگرافی، فاصله‌گذاری و استایل کامپوننت‌ها
/// را یکپارچه مدیریت می‌کند.
///
/// تمام متن‌ها به‌صورت پیش‌فرض RTL و راست‌چین هستند.
class BergamotTheme {
  BergamotTheme._();

  // --- تم روشن ---

  /// تم روشن برگاموت
  static ThemeData light() {
    final colorScheme = _buildLightColorScheme();
    final textTheme = BergamotTypography.toTextTheme(
      textColor: BergamotLightColors.text,
    );

    return _buildThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      colors: BergamotLightColors,
    );
  }

  // --- تم تاریک ---

  /// تم تاریک برگاموت
  static ThemeData dark() {
    final colorScheme = _buildDarkColorScheme();
    final textTheme = BergamotTypography.toTextTheme(
      textColor: BergamotDarkColors.text,
    );

    return _buildThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      colors: BergamotDarkColors,
    );
  }

  // --- ColorScheme ---

  static ColorScheme _buildLightColorScheme() {
    return const ColorScheme.light(
      primary: BergamotLightColors.primary,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD8F3DC),
      onPrimaryContainer: BergamotLightColors.primary,
      secondary: BergamotLightColors.accent,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF5E6D3),
      onSecondaryContainer: Color(0xFF5D3A1A),
      surface: BergamotLightColors.surface,
      onSurface: BergamotLightColors.text,
      surfaceContainerHighest: Color(0xFFF3F4F6),
      error: BergamotLightColors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
    );
  }

  static ColorScheme _buildDarkColorScheme() {
    return const ColorScheme.dark(
      primary: BergamotDarkColors.primary,
      onPrimary: Color(0xFF1A1A2E),
      primaryContainer: Color(0xFF1A3A2A),
      onPrimaryContainer: BergamotDarkColors.primary,
      secondary: BergamotDarkColors.accent,
      onSecondary: Color(0xFF1A1A2E),
      secondaryContainer: Color(0xFF3D2E1F),
      onSecondaryContainer: BergamotDarkColors.accent,
      surface: BergamotDarkColors.surface,
      onSurface: BergamotDarkColors.text,
      surfaceContainerHighest: Color(0xFF252540),
      error: BergamotDarkColors.error,
      onError: Color(0xFF1A1A2E),
      errorContainer: Color(0xFF450A0A),
      onErrorContainer: BergamotDarkColors.error,
    );
  }

  // --- ThemeData ---

  static ThemeData _buildThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required dynamic colors,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? BergamotDarkColors.surface : BergamotLightColors.surface;
    final borderColor =
        isDark ? BergamotDarkColors.border : BergamotLightColors.border;
    final textSecondaryColor = isDark
        ? BergamotDarkColors.textSecondary
        : BergamotLightColors.textSecondary;
    final bgColor =
        isDark ? BergamotDarkColors.background : BergamotLightColors.background;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,

      // --- فونت ---
      fontFamily: kFontFamily,
      textTheme: textTheme,

      // --- پس‌زمینه ---
      scaffoldBackgroundColor: bgColor,

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),

      // --- کارت ---
      cardTheme: CardTheme(
        elevation: 0,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br16,
          side: BorderSide(
            color: borderColor,
            width: BergamotSpacing.borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // --- فیلد ورودی ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BergamotSpacing.s16,
          vertical: BergamotSpacing.s12,
        ),
        border: OutlineInputBorder(
          borderRadius: BergamotSpacing.br10,
          borderSide: BorderSide(
            color: borderColor,
            width: BergamotSpacing.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BergamotSpacing.br10,
          borderSide: BorderSide(
            color: borderColor,
            width: BergamotSpacing.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BergamotSpacing.br10,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BergamotSpacing.br10,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: BergamotSpacing.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BergamotSpacing.br10,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        hintStyle: textTheme.bodyMedium!.copyWith(
          color: textSecondaryColor,
        ),
        labelStyle: textTheme.bodyMedium!.copyWith(
          color: textSecondaryColor,
        ),
        // راست‌چین برای RTL
        alignLabelWithHint: true,
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: textSecondaryColor,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
        elevation: 0,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),

      // --- Snackbar ---
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br12,
        ),
        backgroundColor: isDark
            ? BergamotDarkColors.surface
            : BergamotLightColors.text,
        contentTextStyle: textTheme.bodyMedium!.copyWith(
          color: isDark
              ? BergamotDarkColors.text
              : BergamotLightColors.surface,
        ),
      ),

      // --- Divider ---
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: BergamotSpacing.dividerThickness,
        space: BergamotSpacing.s16,
      ),

      // --- Chip ---
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? BergamotDarkColors.tagBg
            : BergamotLightColors.tagBg,
        labelStyle: textTheme.labelLarge!.copyWith(
          color: isDark
              ? BergamotDarkColors.tagText
              : BergamotLightColors.tagText,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: BergamotSpacing.s12,
          vertical: BergamotSpacing.s4,
        ),
        side: BorderSide.none,
      ),

      // --- Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, BergamotSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: BergamotSpacing.br12,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // --- Outlined Button ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, BergamotSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: BergamotSpacing.br12,
          ),
          side: BorderSide(color: borderColor),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // --- Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, BergamotSpacing.touchTargetMin),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // --- Toggle ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return textSecondaryColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withAlpha((0.3 * 255).round());
          }
          return borderColor;
        }),
      ),

      // --- Slider ---
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: borderColor,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withAlpha((0.12 * 255).round()),
        trackHeight: 4,
      ),

      // --- Progress Indicator ---
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: borderColor,
      ),

      // --- Bottom Sheet ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
      ),

      // --- Dialog ---
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br20,
        ),
        elevation: 0,
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // --- Icon ---
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      // --- Floating Action Button ---
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br16,
        ),
      ),

      // --- Tab Bar ---
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: Colors.transparent,
      ),


    );
  }
}
