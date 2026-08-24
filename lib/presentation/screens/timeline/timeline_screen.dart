import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'timeline_provider.dart';

/// صفحه تایم‌لاین امروز
///
/// تمام رویدادهای امروز (خواب، تغذیه، آب، تمرین، عادت)
/// را به ترتیب زمانی روی یک تایم‌لاین عمودی نمایش می‌دهد.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final filter = ref.watch(timelineFilterProvider);
    final timelineAsync = ref.watch(timelineProvider);

    return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('تایم‌لاین امروز'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // فیلتر چیپ‌ها
            _buildFilterChips(context, ref, filter, colors),
            const SizedBox(height: BergamotSpacing.s12),

            // محتوای تایم‌لاین
            Expanded(
              child: timelineAsync.when(
                data: (state) {
                  final events = state.filteredEvents;
                  if (events.isEmpty) {
                    return _buildEmptyState(context, colors);
                  }
                  return _buildTimeline(context, events, colors);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('خطا: $e'),
                ),
              ),
            ),
          ],
        ),
      );
  }

  /// چیپ‌های فیلتر دسته‌بندی
  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    TimelineFilter filter,
    BergamotColors colors,
  ) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: BergamotSpacing.s16,
        ),
        children: [
          // همه
          Padding(
            padding: const EdgeInsets.only(left: BergamotSpacing.s8),
            child: FilterChip(
              label: const Text('همه'),
              selected: filter.isAll,
              onSelected: (_) {
                ref.read(timelineFilterProvider.notifier).state =
                    const TimelineFilter();
              },
            ),
          ),
          // هر دسته‌بندی
          for (final cat in kAllCategories)
            Padding(
              padding: const EdgeInsets.only(left: BergamotSpacing.s8),
              child: FilterChip(
                label: Text(kCategoryLabels[cat]!),
                selected: filter.isActive(cat),
                onSelected: (selected) {
                  final current = Set<String>.from(filter.activeCategories);
                  if (selected) {
                    current.add(cat);
                  } else {
                    current.remove(cat);
                  }
                  ref.read(timelineFilterProvider.notifier).state =
                      TimelineFilter(activeCategories: current);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// حالت خالی
  Widget _buildEmptyState(BuildContext context, BergamotColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: colors.textSecondary,
          ),
          const SizedBox(height: BergamotSpacing.s16),
          Text(
            'امروز هنوز فعالیتی ثبت نشده',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  /// تایم‌لاین عمودی
  Widget _buildTimeline(
    BuildContext context,
    List<TimelineEvent> events,
    BergamotColors colors,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s8,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        return _TimelineItem(
          event: event,
          isFirst: isFirst,
          isLast: isLast,
          colors: colors,
        );
      },
    );
  }
}

/// یک آیتم تایم‌لاین شامل خط عمودی و کارت
class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;
  final BergamotColors colors;

  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm', 'fa_IR').format(
      DateTime.fromMillisecondsSinceEpoch(event.timestampMs),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بخش خط تایم‌لاین و زمان (سمت راست در RTL)
          SizedBox(
            width: 56,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.border,
                    ),
                  ),
                // نقطه روی خط
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: event.iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BergamotSpacing.s12),

          // برچسب زمان
          Padding(
            padding: const EdgeInsets.only(top: BergamotSpacing.s4),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: BergamotSpacing.s12),

          // کارت رویداد
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: BergamotSpacing.s12,
              ),
              child: _EventCard(event: event, colors: colors),
            ),
          ),
        ],
      ),
    );
  }
}

/// کارت نمایش رویداد (مشابه کارت‌های گزارش)
class _EventCard extends StatelessWidget {
  final TimelineEvent event;
  final BergamotColors colors;

  const _EventCard({
    required this.event,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(BergamotSpacing.s12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BergamotSpacing.br16,
        border: Border.all(
          color: colorScheme.surfaceContainerHighest,
        ),
        boxShadow: BergamotSpacing.cardShadow,
      ),
      child: Row(
        children: [
          // آیکون در کانتینر رنگی
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: event.iconColor.withAlpha((0.12 * 255).round()),
              borderRadius: BergamotSpacing.br12,
            ),
            child: Icon(
              event.icon,
              color: event.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: BergamotSpacing.s12),

          // متن‌ها
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.subtitle.isNotEmpty) ...[
                  const SizedBox(height: BergamotSpacing.s4),
                  Text(
                    event.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface
                              .withAlpha((0.6 * 255).round()),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
