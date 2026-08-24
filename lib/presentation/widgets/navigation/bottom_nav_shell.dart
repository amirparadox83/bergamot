import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// شل ناوبری پایین برگاموت
///
/// ۵ تب اصلی: خانه، تغذیه، تمرین، پیشرفت، پروفایل
/// رنگ فعال از تم اصلی گرفته می‌شود.
class BergamotNavShell extends StatelessWidget {
  const BergamotNavShell({
    required this.child,
    super.key,
  });

  /// فرزند داخلی (صفحه فعلی)
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentIndex = _calculateSelectedIndex(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
          height: 64,
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primary.withAlpha((0.12 * 255).round()),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'تغذیه',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'تمرین',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'پیشرفت',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'پروفایل',
            ),
          ],
        ),
      ),
    );
  }

  /// محاسبه اندیس تب فعال بر اساس مسیر جاری
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/nutrition') return 1;
    if (location == '/exercise') return 2;
    if (location == '/charts') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

 /// هدایت به مسیر تب انتخاب‌شده
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/nutrition');
      case 2:
        context.go('/exercise');
      case 3:
        context.go('/charts');
      case 4:
        context.go('/profile');
    }
  }
}
