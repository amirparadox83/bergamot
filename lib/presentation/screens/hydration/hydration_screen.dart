import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'hydration_provider.dart';

/// صفحه آب و هیدراتاسیون
///
/// نمایش میزان آب مصرفی امروز، نمودار دایره‌ای، دکمه‌های افزودن سریع
/// و لیست ورودی‌های امروز

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final hydrationAsync = ref.watch(hydrationProvider(null));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('آب'),
      ),
      body: hydrationAsync.when(
        data: (state) => _HydrationContent(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطا در بارگذاری: $e'),
        ),
      ),
    );
  }
}

/// محتوای اصلی صفحه هیدراتاسیون
class _HydrationContent extends ConsumerWidget {
  final HydrationState state;
  const _HydrationContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(hydrationProvider(null));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          children: [
            // نمودار دایره‌ای
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    percentage: state.percentage.clamp(0, 100) / 100,
                    colors: colors,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.totalMl}',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(color: colors.text),
                        ),
                        Text(
                          'از ${state.targetMl} میلی‌لیتر',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                        const SizedBox(height: BergamotSpacing.s4),
                        Text(
                          '%${state.percentage.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s32),

            // آیکون لیوان‌ها
            _GlassIcons(filledGlasses: state.filledGlasses, colors: colors),
            const SizedBox(height: BergamotSpacing.s32),

            // دکمه‌های افزودن سریع
            _QuickAddButtons(colors: colors),
            const SizedBox(height: BergamotSpacing.s24),

            // لیست ورودی‌های امروز
            const _TodayWaterLog(),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter نمودار دایره‌ای پیشرفت
class _CircularProgressPainter extends CustomPainter {
  final double percentage;
  final BergamotColors colors;

  _CircularProgressPainter({
    required this.percentage,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    // پس‌زمینه حلقه
    final bgPaint = Paint()
      ..color = colors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // پیشرفت
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = percentage >= 1.0 ? colors.success : colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.141592653589793 * percentage.clamp(0, 1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.141592653589793 / 2, // شروع از بالا
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

/// آیکون ۸ لیوان آب
class _GlassIcons extends StatelessWidget {
  final int filledGlasses;
  final BergamotColors colors;

  const _GlassIcons({
    required this.filledGlasses,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (i) {
        final isFilled = i < filledGlasses;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            Icons.local_drink,
            color: isFilled ? colors.primaryLight : colors.border,
            size: 28,
          ),
        );
      }),
    );
  }
}

/// دکمه‌های افزودن سریع آب
class _QuickAddButtons extends StatelessWidget {
  final BergamotColors colors;
  const _QuickAddButtons({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'افزودن سریع',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.text,
              ),
        ),
        const SizedBox(height: BergamotSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _QuickAddCard(
                icon: Icons.coffee,
                label: '۱ لیوان',
                amount: '۲۵۰ میلی‌لیتر',
                onTap: () => _addWater(context, 250),
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _QuickAddCard(
                icon: Icons.water_drop,
                label: '۱ بطری',
                amount: '۵۰۰ میلی‌لیتر',
                onTap: () => _addWater(context, 500),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: BergamotSpacing.s8),
        Row(
          children: [
            Expanded(
              child: _QuickAddCard(
                icon: Icons.water_drop_outlined,
                label: '۱ قمقمه',
                amount: '۷۵۰ میلی‌لیتر',
                onTap: () => _addWater(context, 750),
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _QuickAddCard(
                icon: Icons.edit,
                label: 'سفارشی',
                amount: 'مقدار دلخواه',
                onTap: () => _showCustomDialog(context),
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addWater(BuildContext context, int amount) {
    final ref = ProviderScope.containerOf(context);
    ref.read(hydrationProvider(null).notifier).addWater(amount);
    // PHASE 24 — haptic feedback for water log completion
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$amount میلی‌لیتر اضافه شد')),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('مقدار سفارشی'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مقدار (میلی‌لیتر)',
              hintText: 'مثلاً ۳۰۰',
              suffixText: 'میلی‌لیتر',
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  final ref = ProviderScope.containerOf(context);
                  ref.read(hydrationProvider(null).notifier).addWater(amount);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$amount میلی‌لیتر اضافه شد')),
                  );
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        );
      },
    );
  }
}

/// کارت دکمه افزودن سریع
class _QuickAddCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final VoidCallback onTap;
  final BergamotColors colors;

  const _QuickAddCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BergamotSpacing.br16,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: BergamotSpacing.s16,
          ),
          child: Column(
            children: [
              Icon(icon, color: colors.primary, size: 32),
              const SizedBox(height: BergamotSpacing.s8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: BergamotSpacing.s4),
              Text(
                amount,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

/// لاگ آب امروز
class _TodayWaterLog extends ConsumerWidget {
  const _TodayWaterLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final dao = ref.watch(hydrationDaoProvider);

    return StreamBuilder<List<WaterEntry>>(
      stream: dao.watchTodayWater(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final entries = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ورودی‌های امروز',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
                  child: _WaterLogItem(entry: e, colors: colors),
                )),
          ],
        );
      },
    );
  }
}

/// آیتم لاگ آب
class _WaterLogItem extends ConsumerWidget {
  final WaterEntry entry;
  final BergamotColors colors;

  const _WaterLogItem({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateTime.fromMillisecondsSinceEpoch(entry.time);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
        ref.read(hydrationProvider(null).notifier).deleteWater(entry.id);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s16,
            vertical: BergamotSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(Icons.water_drop, color: colors.primaryLight, size: 20),
              const SizedBox(width: BergamotSpacing.s12),
              Expanded(
                child: Text(
                  '${entry.amountMl} میلی‌لیتر',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                timeStr,
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
