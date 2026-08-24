import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'habits_provider.dart';

/// لیست آیکون‌های پیش‌فرض برای عادت‌ها
const List<IconData> _presetIcons = [
  Icons.self_improvement,
  Icons.directions_run,
  Icons.book_outlined,
  Icons.water_drop_outlined,
  Icons.local_florist_outlined,
  Icons.music_note_outlined,
  Icons.brush_outlined,
  Icons.restaurant_outlined,
  Icons.bedtime_outlined,
  Icons.fitness_center,
];

/// صفحه عادت‌ها
///
/// نمایش لیست عادت‌ها با وضعیت ۷ روز اخیر،
/// امتیاز Smoothing نمایی و استریک
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final stateAsync = ref.watch(habitsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('عادت‌ها'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddHabitSheet(context, ref),
              tooltip: 'افزودن عادت',
            ),
          ],
        ),
        body: stateAsync.when(
          data: (state) {
            if (state.habits.isEmpty) {
              return _EmptyState(colors: colors, onAdd: () => _showAddHabitSheet(context, ref));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(BergamotSpacing.s16),
              itemCount: state.habits.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: BergamotSpacing.s8),
              itemBuilder: (context, index) {
                final habit = state.habits[index];
                final isDone = state.todayStatus[habit.id] ?? false;
                final score = state.scores[habit.id] ?? 0.0;
                final streak = state.streaks[habit.id] ?? 0;
                return _HabitCard(
                  habit: habit,
                  isDoneToday: isDone,
                  score: score,
                  streak: streak,
                  colors: colors,
                  onToggle: () {
                    // PHASE 24 — haptic feedback for habit tick
                    HapticFeedback.lightImpact();
                    ref.read(habitsProvider.notifier).toggleToday(habit.id);
                  },
                  onDelete: () =>
                      ref.read(habitsProvider.notifier).deleteHabit(habit.id),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا در بارگذاری: $e')),
        ),
      ),
    );
  }

  /// نمایش شیت پایین افزودن عادت
  void _showAddHabitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddHabitSheet(),
    );
  }
}

/// حالت خالی — هنوز عادی ثبت نشده
class _EmptyState extends StatelessWidget {
  final BergamotColors colors;
  final VoidCallback onAdd;

  const _EmptyState({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: colors.textSecondary,
            ),
            const SizedBox(height: BergamotSpacing.s24),
            Text(
              'هنوز عادی ثبت نکردی',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'با افزودن عادت، ردیابی روزانه را شروع کن',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('افزودن عادت'),
            ),
          ],
        ),
      ),
    );
  }
}

/// کارت یک عادت
class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isDoneToday;
  final double score;
  final int streak;
  final BergamotColors colors;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.isDoneToday,
    required this.score,
    required this.streak,
    required this.colors,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconData = _getIconData(habit.icon);

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: BergamotSpacing.s24),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BergamotSpacing.br12,
        ),
        child: Icon(Icons.delete, color: colors.surface),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('حذف عادت'),
              content: Text('آیا از حذف «${habit.name}» مطمئنی؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('انصراف'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  child: const Text('حذف'),
                ),
              ],
            ),
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Row(
            children: [
              // آیکون عادت
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDoneToday
                      ? colors.success.withAlpha((0.12 * 255).round())
                      : colors.border,
                  borderRadius: BergamotSpacing.br12,
                ),
                child: Icon(
                  iconData,
                  color: isDoneToday ? colors.success : colors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: BergamotSpacing.s12),

              // نام و اطلاعات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.text,
                          ),
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    // مینی تقویم ۷ روزه
                    FutureBuilder<List<HabitLog>>(
                      future: _getLast7DaysLogs(ref, habit.id),
                      builder: (context, snapshot) {
                        final logs = snapshot.data ?? [];
                        return _MiniCalendar(
                          logs: logs,
                          colors: colors,
                        );
                      },
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    // امتیاز و استریک
                    Row(
                      children: [
                        Text(
                          '${(score * 100).round()}٪',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (streak > 0) ...[
                          const SizedBox(width: BergamotSpacing.s8),
                          Icon(
                            Icons.local_fire_department,
                            color: colors.accent,
                            size: 14,
                          ),
                          const SizedBox(width: BergamotSpacing.s4),
                          Text(
                            '$streak روز',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // دکمه تاگل امروز
              const SizedBox(width: BergamotSpacing.s8),
              IconButton(
                onPressed: onToggle,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDoneToday ? colors.success : colors.surface,
                    border: Border.all(
                      color: isDoneToday ? colors.success : colors.border,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    isDoneToday ? Icons.check : Icons.remove,
                    color: isDoneToday ? colors.surface : colors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// دریافت لاگ‌های ۷ روز اخیر
  Future<List<HabitLog>> _getLast7DaysLogs(WidgetRef ref, int habitId) async {
    final dao = ref.read(habitDaoProvider);
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sevenDaysAgoMs = todayMs - (6 * 24 * 60 * 60 * 1000);
    return dao.getHabitLogsForRange(habitId, sevenDaysAgoMs, todayMs);
  }

  /// تبدیل نام آیکون رشته‌ای به IconData
  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.check_circle_outline;
    final idx = _presetIcons.indexWhere((i) => i.codePoint.toString() == iconName);
    if (idx >= 0) return _presetIcons[idx];
    return Icons.check_circle_outline;
  }
}

/// مینی تقویم ۷ روزه
class _MiniCalendar extends StatelessWidget {
  final List<HabitLog> logs;
  final BergamotColors colors;

  const _MiniCalendar({required this.logs, required this.colors});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    // ساخت مپ تاریخ → وضعیت
    final logMap = <int, bool>{};
    for (final log in logs) {
      logMap[log.date] = log.isCompleted;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final dateMs = todayMs - (6 - i) * 24 * 60 * 60 * 1000;
        final status = _getDayStatus(logMap, dateMs, todayMs);

        Color circleColor;
        if (status == _DayStatus.done) {
          circleColor = colors.success;
        } else if (status == _DayStatus.missed) {
          circleColor = colors.border;
        } else {
          circleColor = colors.surface;
        }

        return Padding(
          padding: const EdgeInsets.only(left: BergamotSpacing.s4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: status == _DayStatus.future
                  ? Border.all(color: colors.border, width: 1)
                  : null,
            ),
          ),
        );
      }),
    );
  }

  /// تعیین وضعیت روز
  _DayStatus _getDayStatus(Map<int, bool> logMap, int dateMs, int todayMs) {
    if (dateMs > todayMs) return _DayStatus.future;
    if (logMap.containsKey(dateMs)) {
      return logMap[dateMs]! ? _DayStatus.done : _DayStatus.missed;
    }
    // روزهای گذشته بدون لاگ = انجام نشده
    if (dateMs < todayMs) return _DayStatus.missed;
    return _DayStatus.future; // امروز بدون لاگ
  }
}

/// وضعیت روز در مینی تقویم
enum _DayStatus { done, missed, future }

/// شیت پایین افزودن عادت
class _AddHabitSheet extends ConsumerStatefulWidget {
  const _AddHabitSheet();

  @override
  ConsumerState<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<_AddHabitSheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = '';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// ذخیره عادت جدید
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      await ref.read(habitsProvider.notifier).addHabit(
        name,
        _selectedIcon.isEmpty ? null : _selectedIcon,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: BergamotSpacing.s16,
        right: BergamotSpacing.s16,
        top: BergamotSpacing.s8,
        bottom: BergamotSpacing.s16 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: BergamotSpacing.s16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'عادت جدید',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // فیلد نام
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام عادت',
                hintText: 'مثلاً: مدیتیشن روزانه',
              ),
              textDirection: TextDirection.rtl,
              autofocus: true,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // انتخاب آیکون
            Text(
              'انتخاب آیکون',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            Wrap(
              spacing: BergamotSpacing.s8,
              runSpacing: BergamotSpacing.s8,
              children: _presetIcons.map((icon) {
                final iconCode = icon.codePoint.toString();
                final isSelected = _selectedIcon == iconCode;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconCode),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withAlpha((0.12 * 255).round())
                          : colors.surface,
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.border,
                      ),
                      borderRadius: BergamotSpacing.br12,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? colors.primary : colors.textSecondary,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // دکمه ذخیره
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}
