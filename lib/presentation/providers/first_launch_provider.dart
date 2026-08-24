import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کلید ذخیره‌سازی وضعیت اولین اجرا
const String _kFirstLaunchKey = 'first_launch';

/// Provider بررسی اولین اجرای اپلیکیشن
///
/// مقدار `true` به معنای اپ قبلاً اجرا شده و آنبوردینگ تکمیل شده است.
/// مقدار `false` یا عدم وجود کلید به معنای اولین اجراست.
final firstLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kFirstLaunchKey) ?? false;
});

/// تابع کمکی برای تنظیم اولین اجرا
Future<void> setFirstLaunchCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kFirstLaunchKey, true);
}
