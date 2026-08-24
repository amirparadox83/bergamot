import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/first_launch_provider.dart';
import '../screens/charts/charts_screen.dart';
import '../screens/charts/report_screen.dart';
import '../screens/exercise/exercise_screen.dart';
import '../screens/habits/habits_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/hydration/hydration_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/privacy/privacy_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/sleep/sleep_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/weight/weight_screen.dart';
import '../widgets/navigation/bottom_nav_shell.dart';
import '../screens/exercise/workout_programs/workout_programs_screen.dart';
import '../screens/daily_plan/daily_plan_screen.dart';
import '../screens/timeline/timeline_screen.dart';

/// Helper ساخت صفحه با Directionality RTL
Widget _rtl(Widget child) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: child,
  );
}

/// Provider روتر اصلی اپلیکیشن
///
/// مسیر اولیه بر اساس وضعیت firstLaunch تعیین می‌شود.
/// تمام صفحات در ShellRoute با BottomNavigationShell قرار دارند
/// به جز صفحه آنبوردینگ و صفحات مستقل.
final goRouterProvider = Provider<GoRouter>((ref) {
  final firstLaunchAsync = ref.watch(firstLaunchProvider);

  return GoRouter(
    initialLocation: firstLaunchAsync.when(
      data: (isFirst) => isFirst ? '/onboarding' : '/',
      loading: () => '/onboarding',
      error: (_, __) => '/',
    ),
    debugLogDiagnostics: kDebugMode,
    routes: [
      // صفحه آنبوردینگ (خارج از شل)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => _rtl(const OnboardingScreen()),
      ),

      // صفحات داخل شل ناوبری
      ShellRoute(
        builder: (context, state, child) => BergamotNavShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const HomeScreen()),
            ),
          ),
          GoRoute(
            path: '/sleep',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const SleepScreen()),
            ),
          ),
          GoRoute(
            path: '/nutrition',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const NutritionScreen()),
            ),
          ),
          GoRoute(
            path: '/hydration',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const HydrationScreen()),
            ),
          ),
          GoRoute(
            path: '/exercise',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const ExerciseScreen()),
            ),
          ),
          GoRoute(
            path: '/charts',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const ChartsScreen()),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const ProfileScreen()),
            ),
          ),
          GoRoute(
            path: '/habits',
            pageBuilder: (context, state) => NoTransitionPage(
              child: _rtl(const HabitsScreen()),
            ),
          ),
        ],
      ),

      // صفحات مستقل (خارج از شل ناوبری)
      GoRoute(
        path: '/settings',
        builder: (context, state) => _rtl(const SettingsScreen()),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => _rtl(const PrivacyScreen()),
      ),
      GoRoute(
        path: '/weight',
        builder: (context, state) => _rtl(const WeightScreen()),
      ),
      GoRoute(
        path: '/workout-programs',
        builder: (context, state) => _rtl(const WorkoutProgramsScreen()),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => _rtl(const SearchScreen()),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => _rtl(const ReportScreen()),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => _rtl(const AchievementsScreen()),
      ),
      GoRoute(
        path: '/daily-plan',
        builder: (context, state) => _rtl(const DailyPlanScreen()),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => _rtl(const TimelineScreen()),
      ),
    ],
  );
});
