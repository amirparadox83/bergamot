import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/daily_plan_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/services/daily_plan_generator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// پروویدر DAO برنامه روزانه
final dailyPlanDaoProvider = Provider<DailyPlanDao>((ref) {
  return DailyPlanDao(ref.read(bergamotDatabaseProvider));
});

/// پروویدر وضعیت صفحه برنامه روزانه
final dailyPlanProvider = StateNotifierProvider<DailyPlanNotifier, AsyncValue<List<DailyPlan>>>((ref) {
  return DailyPlanNotifier(ref.read(dailyPlanDaoProvider), ref.read(bergamotDatabaseProvider));
});

class DailyPlanNotifier extends StateNotifier<AsyncValue<List<DailyPlan>>> {
  final DailyPlanDao dao;
  final BergamotDatabase db;

  DailyPlanNotifier(this.dao, this.db) : super(const AsyncValue.loading()) {
    _loadToday();
  }

  int _todayMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }

  Future<void> _loadToday() async {
    try {
      final items = await dao.getPlanForDate(_todayMs());
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> hasPlanForToday() async {
    return dao.hasPlanForDate(_todayMs());
  }

  /// ساخت و ذخیره برنامه روزانه
  Future<void> generateAndSave() async {
    state = const AsyncValue.loading();
    try {
      final generator = DailyPlanGenerator(db);
      final items = await generator.generate(_todayMs());
      await dao.savePlanForDate(_todayMs(), items);
      final saved = await dao.getPlanForDate(_todayMs());
      state = AsyncValue.data(saved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// تاگل تکمیل آیتم
  Future<void> toggleComplete(int id) async {
    await dao.toggleComplete(id);
    await _loadToday();
  }

  /// بروزرسانی زمان آیتم
  Future<void> updateScheduledTime(int id, int newTimeMs) async {
    await dao.updateScheduledTime(id, newTimeMs);
    await _loadToday();
  }
}

/// صفحه برنامه روزانه
class DailyPlanScreen extends ConsumerWidget {
  const DailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final planAsync = ref.watch(dailyPlanProvider);

    return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('برنامه روزانه'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.go('/'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => ref.read(dailyPlanProvider.notifier).generateAndSave(),
              tooltip: 'بازسازی برنامه',
            ),
          ],
        ),
        body: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('خطا: $e', style: TextStyle(color: colors.error)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState(context, ref, colors);
            }
            return _buildTimeline(context, ref, items, colors);
          },
        ),
      );
  }

  /// حالت خالی — بدون برنامه
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, BergamotColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              'هنوز برنامه‌ای برای امروز نداری',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.text,
              ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'برنامه‌ای بر اساس هدف و سطح فعالیتت ساخته می‌شه',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
            FilledButton.icon(
              onPressed: () => ref.read(dailyPlanProvider.notifier).generateAndSave(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('ساخت برنامه روزانه'),
            ),
          ],
        ),
      ),
    );
  }

  /// تایم‌لاین برنامه روزانه
  Widget _buildTimeline(BuildContext context, WidgetRef ref, List<DailyPlan> items, BergamotColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _TimelineItem(
          item: item,
          colors: colors,
          onTapTime: () => _showTimePicker(context, ref, item),
          onToggle: () => ref.read(dailyPlanProvider.notifier).toggleComplete(item.id),
        );
      },
    );
  }

  /// نمایش تایم‌پیکر برای ویرایش زمان
  void _showTimePicker(BuildContext context, WidgetRef ref, DailyPlan item) {
    final currentTime = DateTime.fromMillisecondsSinceEpoch(item.scheduledTime);
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentTime.hour, minute: currentTime.minute),
    ).then((picked) async {
      if (picked == null) return;
      final date = DateTime.fromMillisecondsSinceEpoch(item.date);
      final newTime = date.add(Duration(hours: picked.hour, minutes: picked.minute));
      await ref.read(dailyPlanProvider.notifier).updateScheduledTime(
        item.id,
        newTime.millisecondsSinceEpoch,
      );
    });
  }
}

/// آیتم تایم‌لاین
class _TimelineItem extends StatelessWidget {
  final DailyPlan item;
  final BergamotColors colors;
  final VoidCallback onTapTime;
  final VoidCallback onToggle;

  const _TimelineItem({
    required this.item,
    required this.colors,
    required this.onTapTime,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(item.scheduledTime);
    final timeStr = DateFormat.jm('fa_IR').format(time);
    final iconData = _categoryIcon(item.category);
    final iconColor = _categoryColor(item.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: BergamotSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // خط تایم‌لاین
          Column(
            children: [
              // نقطه
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted ? colors.success : iconColor,
                  border: Border.all(
                    color: colors.surface,
                    width: 2,
                  ),
                ),
              ),
              // خط
              Container(
                width: 2,
                height: 56,
                color: colors.border,
              ),
            ],
          ),
          const SizedBox(width: BergamotSpacing.s12),

          // محتوای کارت
          Expanded(
            child: Card(
              elevation: 0,
              color: item.isCompleted ? colors.tagBg : colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BergamotSpacing.br12,
                side: BorderSide(
                  color: item.isCompleted ? colors.success : colors.border,
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BergamotSpacing.br12,
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(BergamotSpacing.s12),
                  child: Row(
                    children: [
                      // آیکون دسته‌بندی
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withAlpha((0.12 * 255).round()),
                          borderRadius: BergamotSpacing.br10,
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: BergamotSpacing.s12),

                      // عنوان و اطلاعات
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                color: item.isCompleted ? colors.textSecondary : colors.text,
                              ),
                            ),
                            const SizedBox(height: BergamotSpacing.s4),
                            GestureDetector(
                              onTap: onTapTime,
                              child: Row(
                                children: [
                                  Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: colors.textSecondary,
                                ),
                                  const SizedBox(width: BergamotSpacing.s4),
                                  Text(
                                    timeStr,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  if (item.durationMinutes != null) ...[
                                    const SizedBox(width: BergamotSpacing.s8),
                                    Text(
                                      '${item.durationMinutes} دقیقه',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // دکمه تکمیل
                      if (!item.isCompleted)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                        )
                      else
                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// آیکون بر اساس دسته‌بندی
  IconData _categoryIcon(String category) {
    return switch (category) {
      'sleep' => Icons.bedtime_outlined,
      'meal' => Icons.restaurant_outlined,
      'workout' => Icons.fitness_center_outlined,
      'water' => Icons.water_drop_outlined,
      'habit' => Icons.check_circle_outline,
      _ => Icons.circle_outlined,
    };
  }

  /// رنگ بر اساس دسته‌بندی
  Color _categoryColor(String category) {
    return switch (category) {
      'sleep' => const Color(0xFF6366F1),
      'meal' => const Color(0xFFF59E0B),
      'workout' => const Color(0xFF10B981),
      'water' => const Color(0xFF3B82F6),
      'habit' => const Color(0xFF8B5CF6),
      _ => const Color(0xFF6B7280),
    };
  }
}
