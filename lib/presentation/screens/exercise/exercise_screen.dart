import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'exercise_provider.dart';
import 'library/exercise_library_screen.dart';
import 'workout_builder/workout_builder_screen.dart';

/// صفحه اصلی تمرین — هاب مرکزی
///
/// شامل: شروع تمرین جدید، کتابخانه تمرینات، تاریخچه اخیر
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final workoutsAsync = ref.watch(workoutsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('تمرین'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.read(workoutsProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: BergamotSpacing.s16,
              vertical: BergamotSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: BergamotSpacing.s8),

                // ── کارت شروع تمرین جدید ──
                _StartWorkoutCard(colors: colors),
                const SizedBox(height: BergamotSpacing.s12),

                // ── بخش پیشرفت و streak (PHASE 3.3) ──
                _ProgressSection(colors: colors, ref: ref),
                const SizedBox(height: BergamotSpacing.s12),

                // ── کارت کتابخانه تمرینات ──
                _LibraryCard(colors: colors),
                const SizedBox(height: BergamotSpacing.s24),

                // ── تمرینات اخیر ──
                _RecentWorkoutsSection(
                  colors: colors,
                  workoutsAsync: workoutsAsync,
                ),
                const SizedBox(height: BergamotSpacing.s32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── کارت شروع تمرین جدید ──────────────────────────────────────────────────

class _StartWorkoutCard extends StatelessWidget {
  final BergamotColors colors;
  const _StartWorkoutCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.primary,
      borderRadius: BergamotSpacing.br16,
      child: InkWell(
        borderRadius: BergamotSpacing.br16,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const Directionality(
                textDirection: TextDirection.rtl,
                child: WorkoutBuilderScreen(),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(BergamotSpacing.s24),
          decoration: const BoxDecoration(
            borderRadius: BergamotSpacing.br16,
            boxShadow: BergamotSpacing.cardShadowInteractive,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                  borderRadius: BergamotSpacing.br12,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: BergamotSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شروع تمرین جدید',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    Text(
                      'تمرین خود را بسازید و شروع کنید',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha((0.8 * 255).round()),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بخش پیشرفت و streak (PHASE 3.3) ──────────────────────────────────────────

/// نمایش streak فعلی، مجموع تمرینات و یک نمودار ۷ روزه ساده.
///
/// داده‌ها از `workoutProgressProvider` (که از BergamotStreakCalculator و
/// ExerciseDao استفاده می‌کند) می‌آیند. نمودار با CustomPainter رسم می‌شود
/// (الگوی موجود در weight_screen.dart و sleep_history_screen.dart).
class _ProgressSection extends ConsumerWidget {
  final BergamotColors colors;
  final WidgetRef ref;

  const _ProgressSection({required this.colors, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(workoutProgressProvider);

    return progressAsync.when(
      loading: () => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br16,
          side: BorderSide(color: colors.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(BergamotSpacing.s24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (e, _) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br16,
          side: BorderSide(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Text(
            'خطا در بارگذاری پیشرفت: $e',
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
      data: (info) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BergamotSpacing.br16,
          side: BorderSide(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── هدر: عنوان و streak ──
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: _streakColor(info.currentStreak, colors),
                    size: 24,
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  Text(
                    'پیشرفت',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BergamotSpacing.s12,
                      vertical: BergamotSpacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: _streakColor(info.currentStreak, colors)
                          .withAlpha(30),
                      borderRadius: BergamotSpacing.br20,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: _streakColor(info.currentStreak, colors),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${info.currentStreak} روز',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: _streakColor(info.currentStreak, colors),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BergamotSpacing.s12),

              // ── نمودار ۷ روزه ──
              SizedBox(
                height: 80,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeekBarChartPainter(
                    data: info.last7Days,
                    barColor: colors.primary,
                    emptyColor: colors.border,
                    textColor: colors.textSecondary,
                    todayColor: colors.accent,
                  ),
                ),
              ),
              const SizedBox(height: BergamotSpacing.s12),

              // ── آمار خلاصه ──
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.check_circle_outline,
                      label: 'کل جلسات',
                      value: '${info.totalWorkouts}',
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.timer_outlined,
                      label: 'کل دقیقه',
                      value: '${info.totalMinutes}',
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.local_fire_department_outlined,
                      label: 'کالری تخمینی',
                      value: '${info.totalEstimatedCalories}',
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BergamotSpacing.s8),
              // ── رکورد بهترین streak ──
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 16,
                    color: colors.accent,
                  ),
                  const SizedBox(width: BergamotSpacing.s4),
                  Text(
                    'بهترین زنجیره: ${info.longestStreak} روز',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// رنگ streak بر اساس تعداد روز
  Color _streakColor(int streak, BergamotColors colors) {
    if (streak == 0) return colors.textSecondary;
    if (streak < 3) return const Color(0xFF10B981); // سبز
    if (streak < 7) return const Color(0xFFF59E0B); // نارنجی
    return const Color(0xFFEF4444); // قرمز (hot streak)
  }
}

/// آیتم آمار خلاصه (مجموع جلسات، دقیقه، کالری)
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BergamotColors colors;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// نمودار میله‌ای ۷ روزه (الگوی موجود در پروژه)
class _WeekBarChartPainter extends CustomPainter {
  final List<({DateTime date, int workouts, int calories})> data;
  final Color barColor;
  final Color emptyColor;
  final Color textColor;
  final Color todayColor;

  const _WeekBarChartPainter({
    required this.data,
    required this.barColor,
    required this.emptyColor,
    required this.textColor,
    required this.todayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final n = data.length;
    final barWidth = size.width / (n * 1.6);
    final gap = (size.width - barWidth * n) / (n + 1);
    final maxVal = data.fold<int>(1, (m, d) => d.workouts > m ? d.workouts : m);
    final chartHeight = size.height - 18; // 18 for day labels

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var i = 0; i < n; i++) {
      final d = data[i];
      final x = gap + i * (barWidth + gap);
      final isToday = d.date == todayDate;

      // Bar height (at least 2px for visibility when 0)
      final h = (d.workouts / maxVal) * chartHeight;
      final barHeight = h < 2 ? 2.0 : h.toDouble();
      final rect = Rect.fromLTWH(
        x,
        chartHeight - barHeight,
        barWidth,
        barHeight,
      );

      // Choose color: today's bar is highlighted
      final color = isToday ? todayColor : barColor;
      final paint = Paint()
        ..color = d.workouts > 0
            ? color
            : emptyColor.withAlpha(60)
        ..style = PaintingStyle.fill;

      // Rounded top
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rrect, paint);

      // Day label (single letter)
      final dayLetter = _dayLetter(d.date.weekday);
      final tp = TextPainter(
        text: TextSpan(
          text: dayLetter,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(x + (barWidth - tp.width) / 2, chartHeight + 4),
      );
    }
  }

  String _dayLetter(int weekday) {
    // weekday: 1=Mon..7=Sun (Dart convention)
    const letters = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    // Persian weekday letters — دوشنبه، سه‌شنبه، چهارشنبه، پنجشنبه، جمعه، شنبه، یکشنبه
    // weekday 1=Monday → letters[0]
    final idx = weekday - 1;
    if (idx < 0 || idx >= letters.length) return '?';
    return letters[idx];
  }

  @override
  bool shouldRepaint(covariant _WeekBarChartPainter old) =>
      data != old.data ||
      barColor != old.barColor ||
      textColor != old.textColor ||
      todayColor != old.todayColor;
}

// ─── کارت کتابخانه تمرینات ──────────────────────────────────────────────────

class _LibraryCard extends StatelessWidget {
  final BergamotColors colors;
  const _LibraryCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BergamotSpacing.br16,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const Directionality(
                textDirection: TextDirection.rtl,
                child: ExerciseLibraryScreen(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.tagBg,
                  borderRadius: BergamotSpacing.br12,
                ),
                child: Icon(
                  Icons.library_books,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: BergamotSpacing.s16),
              Expanded(
                child: Text(
                  'کتابخانه تمرینات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بخش تمرینات اخیر ──────────────────────────────────────────────────────

class _RecentWorkoutsSection extends StatelessWidget {
  final BergamotColors colors;
  final AsyncValue<List<Workout>> workoutsAsync;

  const _RecentWorkoutsSection({
    required this.colors,
    required this.workoutsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تمرینات اخیر',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: BergamotSpacing.s12),
        workoutsAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return _EmptyState(colors: colors);
            }
            return Column(
              children: workouts
                  .map((w) => _WorkoutCard(workout: w, colors: colors))
                  .toList(),
            );
          },
          loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(BergamotSpacing.s32),
                child: CircularProgressIndicator(),
              ),
            ),
          error: (_, __) => _EmptyState(colors: colors),
        ),
      ],
    );
  }
}

// ─── کارت یک جلسه تمرین ─────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final BergamotColors colors;

  const _WorkoutCard({required this.workout, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BergamotSpacing.br16,
          onTap: () {
            // Show workout summary in a bottom sheet (detail view)
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Directionality(
                textDirection: TextDirection.rtl,
                child: _WorkoutDetailSheet(
                  workout: workout,
                  colors: colors,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BergamotSpacing.s16,
              vertical: BergamotSpacing.s12,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.tagBg,
                    borderRadius: BergamotSpacing.br10,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: BergamotSpacing.s4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: BergamotSpacing.s4),
                          Text(
                            formatDateFa(workout.date),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: BergamotSpacing.s12),
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: BergamotSpacing.s4),
                          Text(
                            formatDuration(workout.durationMinutes),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── حالت خالی ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BergamotColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: colors.textSecondary,
            ),
            const SizedBox(height: BergamotSpacing.s12),
            Text(
              'هنوز تمرینی ثبت نشده',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s4),
            Text(
              'اولین تمرین خود را شروع کنید!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شیت جزئیات جلسه تمرین
///
/// نمایش اطلاعات کامل یک Workout ثبت‌شده.
class _WorkoutDetailSheet extends StatelessWidget {
  final Workout workout;
  final BergamotColors colors;

  const _WorkoutDetailSheet({required this.workout, required this.colors});

  @override
  Widget build(BuildContext context) {
    // محاسبه مدت زمان از startTime/endTime یا durationMinutes
    final int durationMin;
    if (workout.durationMinutes != null) {
      durationMin = workout.durationMinutes!;
    } else if (workout.endTime != null) {
      durationMin = ((workout.endTime! - workout.startTime) / 60000).round();
    } else {
      durationMin = 0;
    }

    final date = DateTime.fromMillisecondsSinceEpoch(workout.date);
    final dateStr = '${date.year}/${date.month}/${date.day}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نام جلسه
            Text(
              workout.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s4),
            Text(
              'تاریخ: $dateStr  ·  مدت: $durationMin دقیقه',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // وضعیت جلسه
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BergamotSpacing.s12,
                vertical: BergamotSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: workout.isCompleted
                    ? colors.success.withAlpha((0.15 * 255).round())
                    : colors.warning.withAlpha((0.15 * 255).round()),
                borderRadius: BergamotSpacing.br8,
              ),
              child: Text(
                workout.isCompleted ? 'تکمیل شده' : 'در حال انجام',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: workout.isCompleted
                          ? colors.success
                          : colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (workout.notes != null && workout.notes!.isNotEmpty) ...[
              const SizedBox(height: BergamotSpacing.s16),
              Text(
                'یادداشت',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Text(
                workout.notes!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                    ),
              ),
            ],
            const SizedBox(height: BergamotSpacing.s24),

            // دکمه بستن
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('بستن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
