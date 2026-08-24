import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'sleep_provider.dart';

/// صفحه تاریخچه خواب با نمودار میله‌ای
///
/// نمایش مدت خواب برای ۷، ۳۰ یا ۹۰ روز اخیر
class SleepHistoryScreen extends ConsumerStatefulWidget {
  const SleepHistoryScreen({super.key});

  @override
  ConsumerState<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends ConsumerState<SleepHistoryScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final historyAsync = ref.watch(sleepHistoryProvider(_selectedDays));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('تاریخچه خواب'),
      ),
      body: Column(
        children: [
          // انتخاب بازه زمانی
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BergamotSpacing.s16),
            child: Row(
              children: [
                _PeriodChip(
                  label: '۷ روز',
                  isSelected: _selectedDays == 7,
                  colors: colors,
                  onTap: () => setState(() => _selectedDays = 7),
                ),
                const SizedBox(width: BergamotSpacing.s8),
                _PeriodChip(
                  label: '۳۰ روز',
                  isSelected: _selectedDays == 30,
                  colors: colors,
                  onTap: () => setState(() => _selectedDays = 30),
                ),
                const SizedBox(width: BergamotSpacing.s8),
                _PeriodChip(
                  label: '۹۰ روز',
                  isSelected: _selectedDays == 90,
                  colors: colors,
                  onTap: () => setState(() => _selectedDays = 90),
                ),
              ],
            ),
          ),
          const SizedBox(height: BergamotSpacing.s16),

          // نمودار و لیست
          Expanded(
            child: historyAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'داده‌ای یافت نشد',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(sleepHistoryProvider(_selectedDays));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: BergamotSpacing.s16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // نمودار میله‌ای
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(BergamotSpacing.s16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مدت خواب',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: colors.text),
                                ),
                                const SizedBox(height: BergamotSpacing.s16),
                                SizedBox(
                                  height: 200,
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 200),
                                    painter: _SleepBarChartPainter(
                                      entries: entries,
                                      colors: colors,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: BergamotSpacing.s24),

                        // لیست ورودی‌ها
                        Text(
                          'جزئیات',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colors.text,
                              ),
                        ),
                        const SizedBox(height: BergamotSpacing.s12),
                        ...entries.reversed.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: BergamotSpacing.s8,
                            ),
                            child: _HistoryListItem(
                              entry: e,
                              colors: colors,
                            ),
                          ),
                        ),
                        const SizedBox(height: BergamotSpacing.s32),
                      ],
                    ),
                  ),
                );
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
}

/// چیپ انتخاب بازه زمانی
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colors.primary.withAlpha((0.15 * 255).round()),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.textSecondary,
        fontFamily: 'Vazirmatn',
      ),
      side: BorderSide(
        color: isSelected ? colors.primary : colors.border,
      ),
    );
  }
}

/// نمودار میله‌ای خواب — CustomPainter
class _SleepBarChartPainter extends CustomPainter {
  final List<SleepEntry> entries;
  final BergamotColors colors;

  _SleepBarChartPainter({required this.entries, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final maxMinutes = entries
        .map((e) => e.durationMinutes)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (maxMinutes == 0) return;

    // حداکثر مقیاس نمودار (حداقل ۸ ساعت)
    final maxScale = (maxMinutes / 60).ceilToDouble() < 8.0 ? 480.0 : maxMinutes;

    final chartHeight = size.height - 30; // فضای برای برچسب‌ها
    final barWidth = (size.width / entries.length) * 0.6;
    final gap = (size.width / entries.length) * 0.4;

    // خط راهنما ۸ ساعت
    final eightHourY = chartHeight - (480 / maxScale) * chartHeight;
    final guidePaint = Paint()
      ..color = colors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, eightHourY), Offset(size.width, eightHourY), guidePaint);

    // متن راهنما
    final guideTextStyle = TextStyle(
      color: colors.textSecondary,
      fontSize: 10,
      fontFamily: 'Vazirmatn',
    );
    final guideTextPainter = TextPainter(
      text: TextSpan(text: '۸ ساعت', style: guideTextStyle),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout();
    guideTextPainter.paint(canvas, Offset(size.width - 40, eightHourY - 14));

    // میله‌ها
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final barHeight = (entry.durationMinutes / maxScale) * chartHeight;
      final x = i * (barWidth + gap) + gap / 2;
      final y = chartHeight - barHeight;

      // رنگ بر اساس کیفیت
      final barColor = entry.quality >= 4
          ? colors.success
          : entry.quality >= 3
              ? colors.primary
              : entry.quality >= 2
                  ? colors.warning
                  : colors.error;

      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topRight: const Radius.circular(4),
        topLeft: const Radius.circular(4),
      );
      canvas.drawRRect(rrect, paint);

      // تاریخ در پایین
      final date = DateTime.fromMillisecondsSinceEpoch(entry.date);
      final dayLabel = '${date.day}/${date.month}';
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 9,
            fontFamily: 'Vazirmatn',
          ),
        ),
        textDirection: TextDirection.ltr,
        textWidthBasis: TextWidthBasis.longestLine,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - labelPainter.width / 2, chartHeight + 8),
      );

      // ساعت در بالای میله
      final hours = (entry.durationMinutes / 60).toStringAsFixed(1);
      final hourPainter = TextPainter(
        text: TextSpan(
          text: hours,
          style: TextStyle(
            color: colors.text,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFamily: 'Vazirmatn',
          ),
        ),
        textDirection: TextDirection.ltr,
        textWidthBasis: TextWidthBasis.longestLine,
      )..layout();
      hourPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - hourPainter.width / 2,
          y - 14,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SleepBarChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

/// آیتم لیست تاریخچه
class _HistoryListItem extends StatelessWidget {
  final SleepEntry entry;
  final BergamotColors colors;

  const _HistoryListItem({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hours = entry.durationMinutes ~/ 60;
    final minutes = entry.durationMinutes % 60;
    final date = DateTime.fromMillisecondsSinceEpoch(entry.date);
    final dateStr = '${date.year}/${date.month}/${date.day}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BergamotSpacing.s16,
          vertical: BergamotSpacing.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: BergamotSpacing.s4),
                  Text(
                    '$hours ساعت و $minutes دقیقه',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BergamotSpacing.s12),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < entry.quality
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: i < entry.quality ? colors.accent : colors.border,
                  size: 16,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
