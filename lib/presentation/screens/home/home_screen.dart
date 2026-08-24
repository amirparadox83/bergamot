import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'home_provider.dart';

/// صفحه اصلی برگاموت
///
/// شامل: خوش‌آمدگویی، حلقه امتیاز سبک زندگی،
/// کارت‌های تمرکز روزانه، و بخش امروز چطور بودی؟
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.bergamotColors;

    // سلام بر اساس ساعت روز
    final greeting = _getGreeting();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            'برگاموت',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings'),
              tooltip: 'تنظیمات',
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: BergamotSpacing.s8),

                    // بخش خوش‌آمدگویی
                    _buildGreeting(context, greeting, colorScheme),
                    const SizedBox(height: BergamotSpacing.s24),

                    // حلقه امتیاز سبک زندگی
                    _buildLifestyleScore(context, state, colorScheme),
                    const SizedBox(height: BergamotSpacing.s24),

                    // کارت‌های تمرکز روزانه
                    _buildSectionTitle(context, 'تمرکز امروز', colorScheme),
                    const SizedBox(height: BergamotSpacing.s12),
                    _buildFocusCards(context, state, colorScheme),
                    const SizedBox(height: BergamotSpacing.s24),

                    // بخش امروز چطور بودی؟
                    _buildSectionTitle(context, 'امروز چطور بودی؟', colorScheme),
                    const SizedBox(height: BergamotSpacing.s12),
                    _buildMoodSection(context, colorScheme),
                    const SizedBox(height: BergamotSpacing.s32),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickAdd(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// منوی سریع افزودن
  void _showQuickAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<Widget>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetColors = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BergamotSpacing.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'افزودن سریع',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: BergamotSpacing.s16),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined, color: sheetColors.primary),
                  title: const Text('آب (۲۵۰ میلی‌لیتر)'),
                  onTap: () {
                    ref.read(homeProvider.notifier).addWater(250);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined, color: sheetColors.primary),
                  title: const Text('آب (۵۰۰ میلی‌لیتر)'),
                  onTap: () {
                    ref.read(homeProvider.notifier).addWater(500);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_fire_department_outlined, color: sheetColors.tertiary),
                  title: const Text('ثبت وعده غذایی'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/nutrition');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.fitness_center_outlined, color: sheetColors.secondary),
                  title: const Text('شروع تمرین'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/exercise');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.monitor_weight_outlined, color: sheetColors.secondary),
                  title: const Text('ثبت وزن'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/weight');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bedtime_outlined, color: sheetColors.secondary),
                  title: const Text('ثبت خواب'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/sleep');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.check_circle_outline, color: sheetColors.tertiary),
                  title: const Text('عادت‌ها'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/habits');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.timeline_outlined, color: sheetColors.secondary),
                  title: const Text('تایم‌لاین'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/timeline');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.schedule_outlined, color: sheetColors.tertiary),
                  title: const Text('برنامه روزانه'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/daily-plan');
                  },
                ),
                const SizedBox(height: BergamotSpacing.s8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// سلام بر اساس ساعت روز
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صبح بخیر';
    if (hour < 17) return 'ظهر بخیر';
    if (hour < 21) return 'عصر بخیر';
    return 'شب بخیر';
  }

  /// بخش خوش‌آمدگویی
  Widget _buildGreeting(BuildContext context, String greeting, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting، کاربر',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: BergamotSpacing.s4),
        Text(
          'بیا امروز هم به بدنت رسیدگی کنیم!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
          ),
        ),
      ],
    );
  }

  /// حلقه امتیاز سبک زندگی
  Widget _buildLifestyleScore(BuildContext context, HomeState state, ColorScheme colorScheme) {
    final score = state.lifestyleScore;
    final scoreColor = _getScoreColor(score, context);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: BergamotSpacing.s24,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BergamotSpacing.br20,
          border: Border.all(
            color: colorScheme.surfaceContainerHighest,
          ),
        ),
        child: Column(
          children: [
            Text(
              'امتیاز سبک زندگی',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: BergamotSpacing.s16),
            SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _HomeScoreRingPainter(
                  score: score,
                  color: scoreColor,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.round().toString(),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: scoreColor,
                          fontSize: 40,
                        ),
                      ),
                      Text(
                        'از ۱۰۰',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface
                              .withAlpha((0.5 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            Text(
              _getScoreLabel(score),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// کارت‌های تمرکز روزانه
  Widget _buildFocusCards(BuildContext context, HomeState state, ColorScheme colorScheme) {
    final cards = [
      _FocusCard(
        icon: Icons.bedtime_outlined,
        iconColor: colorScheme.secondary,
        title: 'خواب',
        subtitle: state.sleepStatus,
      ),
      _FocusCard(
        icon: Icons.local_fire_department_outlined,
        iconColor: colorScheme.tertiary,
        title: 'تغذیه',
        subtitle: '${state.todayCalories} کیلوکالری',
      ),
      _FocusCard(
        icon: Icons.water_drop_outlined,
        iconColor: colorScheme.primary,
        title: 'آب',
        subtitle: '${state.todayWaterTotal} میلی‌لیتر',
      ),
      _FocusCard(
        icon: Icons.fitness_center_outlined,
        iconColor: colorScheme.primary,
        title: 'تمرین',
        subtitle: state.workoutStatus,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: BergamotSpacing.s12,
      crossAxisSpacing: BergamotSpacing.s12,
      childAspectRatio: 1.1,
      children: cards.map((card) => _buildFocusCard(context, card, colorScheme)).toList(),
    );
  }

  /// ساخت یک کارت تمرکز
  Widget _buildFocusCard(BuildContext context, _FocusCard card, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: card.iconColor.withAlpha((0.12 * 255).round()),
                borderRadius: BergamotSpacing.br12,
              ),
              child: Icon(
                card.icon,
                color: card.iconColor,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              card.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: BergamotSpacing.s4),
            Text(
              card.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// عنوان بخش
  Widget _buildSectionTitle(BuildContext context, String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  /// بخش حال امروز چطور بودی
  Widget _buildMoodSection(BuildContext context, ColorScheme colorScheme) {
    final moods = [
      {'icon': '😊', 'label': 'عالی'},
      {'icon': '🙂', 'label': 'خوب'},
      {'icon': '😐', 'label': 'عادی'},
      {'icon': '😔', 'label': 'خسته'},
      {'icon': '😡', 'label': 'بد'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BergamotSpacing.s16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BergamotSpacing.br16,
        border: Border.all(
          color: colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالت امروز چطور بود؟',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: BergamotSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((mood) {
              return Column(
                children: [
                  Text(
                    mood['icon'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: BergamotSpacing.s4),
                  Text(
                    mood['label'] as String,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// رنگ بر اساس امتیاز — از رنگ‌های تم‌آگاه برگاموت استفاده می‌کند
  Color _getScoreColor(double score, BuildContext context) {
    final colors = context.bergamotColors;
    if (score >= 80) return colors.success;
    if (score >= 60) return colors.warning;
    return colors.error;
  }

  /// متن بر اساس امتیاز
  String _getScoreLabel(double score) {
    if (score >= 90) return 'عالی! سبک زندگی فوق‌العاده‌ای داری 🌟';
    if (score >= 75) return 'خوبه! ادامه بده 💪';
    if (score >= 60) return 'قابل قبوله، ولی جا برای بهبود داره';
    if (score >= 40) return 'کمی تلاش بیشتر لازمه';
    return 'بیا با هم بهترش کنیم!';
  }
}

/// نقاش حلقه امتیاز صفحه اصلی
class _HomeScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;

  _HomeScoreRingPainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 12.0;
    final radius = (size.width - strokeWidth * 2) / 2;

    // پس‌زمینه حلقه
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // حلقه پیشرفت
    if (score > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * math.pi * (score / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeScoreRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

/// داده‌های کارت تمرکز
class _FocusCard {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FocusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}
