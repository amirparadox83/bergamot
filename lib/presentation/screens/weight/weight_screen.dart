import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'weight_provider.dart';

/// صفحه وزن
///
/// نمایش وزن فعلی، BMI، نمودار روند و لیست تاریخچه

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final weightAsync = ref.watch(weightProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('وزن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWeightSheet(context, ref),
          ),
        ],
      ),
      body: weightAsync.when(
        data: (state) {
          if (state.entries.isEmpty) {
            return _EmptyWeightState(colors: colors);
          }
          return _WeightContent(state: state, colors: colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطا در بارگذاری: $e'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeightSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddWeightSheet(),
    );
  }
}

/// حالت خالی — هنوز وزنی ثبت نشده
class _EmptyWeightState extends StatelessWidget {
  final BergamotColors colors;
  const _EmptyWeightState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 80,
              color: colors.textSecondary,
            ),
            const SizedBox(height: BergamotSpacing.s24),
            Text(
              'هنوز وزنی ثبت نشده',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'با دکمه + وزن خود را ثبت کنید',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// محتوای اصلی صفحه وزن
class _WeightContent extends ConsumerWidget {
  final WeightState state;
  final BergamotColors colors;

  const _WeightContent({required this.state, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = state.entries.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(BergamotSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // کارت وزن فعلی
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BergamotSpacing.s24),
              child: Column(
                children: [
                  Text(
                    'وزن فعلی',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: BergamotSpacing.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        latest.weightKg.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: colors.text,
                            ),
                      ),
                      const SizedBox(width: BergamotSpacing.s8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'کیلوگرم',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),

                  // BMI
                  if (state.latestWeight != null) ...[
                    const SizedBox(height: BergamotSpacing.s16),
                    _BmiDisplay(
                      weightKg: state.latestWeight!,
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: BergamotSpacing.s24),

          // نمودار روند
          if (state.entries.length >= 2) ...[
            Text(
              'روند تغییرات (۳۰ روز اخیر)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BergamotSpacing.s16),
                child: SizedBox(
                  height: 200,
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _WeightLineChartPainter(
                      entries: state.entries,
                      colors: colors,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
          ],

          // لیست تاریخچه
          Text(
            'تاریخچه',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.text,
                ),
          ),
          const SizedBox(height: BergamotSpacing.s12),
          // TODO: For large histories, consider paginating or using
          // a lazy-loading approach. Currently renders all entries.
          ...state.entries.reversed.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
              child: _WeightHistoryItem(
                entry: e,
                colors: colors,
              ),
            ),
          ),
          const SizedBox(height: BergamotSpacing.s32),
        ],
      ),
    );
  }
}

/// نمایش BMI
class _BmiDisplay extends ConsumerWidget {
  final double weightKg;
  final BergamotColors colors;

  const _BmiDisplay({required this.weightKg, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // خواندن قد از پروفایل
    final profileDao = ref.watch(profileDaoProvider);

    return FutureBuilder(
      future: profileDao.getProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Text(
            'برای محاسبه BMI ابتدا پروفایل خود را تکمیل کنید',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          );
        }

        final heightCm = snapshot.data!.heightCm;
        if (heightCm <= 0) {
          return const SizedBox.shrink();
        }

        final heightM = heightCm / 100;
        final bmi = weightKg / (heightM * heightM);
        final category = bmiCategory(bmi);
        final categoryColor = bmiCategoryColor(bmi);

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s16,
            vertical: BergamotSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: categoryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BergamotSpacing.br12,
            border: Border.all(color: categoryColor.withAlpha((0.3 * 255).round())),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'شاخص توده بدنی',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: BergamotSpacing.s4),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s12,
                  vertical: BergamotSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BergamotSpacing.br20,
                ),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// نمودار خطی وزن — CustomPainter
class _WeightLineChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final BergamotColors colors;

  _WeightLineChartPainter({required this.entries, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    // فیلتر ۳۰ روز اخیر
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final filtered = entries.where((e) => e.date >= thirtyDaysAgo).toList();
    if (filtered.length < 2) return;

    final weights = filtered.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW) == 0 ? 1.0 : (maxW - minW);

    const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 20);
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;

    // محاسبه نقاط
    final points = <Offset>[];
    for (var i = 0; i < filtered.length; i++) {
      final x = padding.left + (i / (filtered.length - 1)) * chartW;
      final y = padding.top + chartH - ((weights[i] - minW) / range) * chartH;
      points.add(Offset(x, y));
    }

    // خط راهنماها
    final guidePaint = Paint()
      ..color = colors.border
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i <= 4; i++) {
      final y = padding.top + (i / 4) * chartH;
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        guidePaint,
      );

      // برچسب مقدار
      final val = maxW - (i / 4) * range;
      final textPainter = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(1),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 9,
            fontFamily: 'Vazirmatn',
          ),
        ),
        textDirection: TextDirection.ltr,
        textWidthBasis: TextWidthBasis.longestLine,
      )..layout();
      textPainter.paint(canvas, Offset(padding.left, y - 12));
    }

    // خط روند
    final linePaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // نقطه‌ها
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = colors.primary);
      canvas.drawCircle(point, 2, Paint()..color = colors.surface);
    }

    // نقطه آخر بزرگ‌تر
    if (points.isNotEmpty) {
      final last = points.last;
      canvas.drawCircle(last, 6, Paint()..color = colors.primary);
      canvas.drawCircle(last, 3, Paint()..color = colors.surface);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

/// آیتم تاریخچه وزن
class _WeightHistoryItem extends ConsumerWidget {
  final WeightEntry entry;
  final BergamotColors colors;

  const _WeightHistoryItem({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.date);
    final dateStr = '${date.year}/${date.month}/${date.day}';

    return Dismissible(
      key: ValueKey(entry.id),
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
      onDismissed: (_) {
        ref.read(weightProvider.notifier).deleteWeight(entry.id);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s16,
            vertical: BergamotSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_outlined,
                  color: colors.primary, size: 22),
              const SizedBox(width: BergamotSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.weightKg.toStringAsFixed(1)} کیلوگرم',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: BergamotSpacing.s4),
                      Text(
                        entry.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شیت پایین افزودن وزن
class _AddWeightSheet extends ConsumerStatefulWidget {
  const _AddWeightSheet();

  @override
  ConsumerState<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<_AddWeightSheet> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0 || weight > 500) return;

    setState(() => _saving = true);
    try {
      await ref.read(weightProvider.notifier).addWeight(
            weightKg: weight,
            note: _noteController.text.isEmpty ? null : _noteController.text,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // وزن
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'وزن (کیلوگرم)',
              hintText: 'مثلاً ۷۵.۵',
              suffixText: 'کیلوگرم',
              suffixStyle: TextStyle(color: colors.textSecondary),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            autofocus: true,
          ),
          const SizedBox(height: BergamotSpacing.s16),

          // یادداشت
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'یادداشت (اختیاری)',
              hintText: 'مثلاً: بعد از باشگاه...',
            ),
            maxLines: 2,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: BergamotSpacing.s24),

          // دکمه ذخیره
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ذخیره'),
            ),
          ),
        ],
      ),
    );
  }
}
