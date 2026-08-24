import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/bergamot_database.dart';
import 'data/seed_data/seed_manager.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // مدیریت خطای سراسری
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  try {
    // مقداردهی دیتابیس
    await BergamotDatabase.init();

    // بارگذاری داده‌های اولیه در اولین اجرا
    final db = BergamotDatabase.instance;
    await SeedManager.seedIfNeeded(db);
  } catch (e, stack) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack: $stack');
    // TODO: Show a user-friendly error screen instead of running with broken DB.
    // For now, the app still launches but features depending on DB will fail.
  }

  runApp(const ProviderScope(child: BergamotApp()));
}

/// ویجت ریشه اپلیکیشن برگاموت
///
/// از ProviderScope برای مدیریت حالت و
/// MaterialApp.router برای ناوبری GoRouter استفاده می‌کند.
class BergamotApp extends ConsumerWidget {
  const BergamotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(bergamotThemeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'برگاموت',
      debugShowCheckedModeBanner: false,

      // تم
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: theme.mode,

      // ناوبری
      routerConfig: router,
    );
  }
}
