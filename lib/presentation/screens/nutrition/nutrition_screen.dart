import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/meal_template_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'food_search/food_search_sheet.dart';
import 'meal_template_sheet.dart';
import 'nutrition_provider.dart';

/// صفحه تغذیه
///
/// نمایش خلاصه کالری و ماکروهای امروز با حلقه دایره‌ای،
/// نوارهای ماکرو، و چهار بخش وعده غذایی

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final mealsAsync = ref.watch(todayMealsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('تغذیه'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            onPressed: () => _openTemplateSheet(context),
            tooltip: 'قالب‌ها',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openFoodSearch(context),
            tooltip: 'جستجوی غذا',
          ),
        ],
      ),
      body: mealsAsync.when(
        data: (meals) => _NutritionContent(meals: meals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطا در بارگذاری: $e'),
        ),
      ),
    );
  }

  void _openFoodSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FoodSearchSheet(),
    );
  }

  void _openTemplateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const MealTemplateSheet(),
    );
  }
}

/// محتوای اصلی صفحه تغذیه
class _NutritionContent extends ConsumerWidget {
  final List<MealEntry> meals;

  const _NutritionContent({required this.meals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final nutrition = ref.watch(todayNutritionProvider);
    // TODO(b enhancement): Read targets from user profile/goals via GoalsDao instead of hardcoded defaults
    const calorieTarget = 2000.0;
    const proteinTarget = 120.0;
    const fatTarget = 65.0;
    const carbTarget = 250.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayMealsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          children: [
            // حلقه کالری
            _CalorieRing(
              consumed: nutrition.calories,
              target: calorieTarget,
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // نوارهای ماکرو
            _MacroBar(
              label: 'پروتئین',
              current: nutrition.protein,
              target: proteinTarget,
              color: colors.error,
              unit: 'گرم',
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            _MacroBar(
              label: 'چربی',
              current: nutrition.fat,
              target: fatTarget,
              color: colors.warning,
              unit: 'گرم',
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            _MacroBar(
              label: 'کربوهیدرات',
              current: nutrition.carb,
              target: carbTarget,
              color: const Color(0xFF3B82F6),
              unit: 'گرم',
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // چهار بخش وعده غذایی
            for (int type = 0; type < 4; type++)
              Padding(
                padding: const EdgeInsets.only(bottom: BergamotSpacing.s12),
                child: _MealSectionCard(
                  mealType: type,
                  meals: meals.where((m) => m.mealType == type).toList(),
                ),
              ),

            const SizedBox(height: BergamotSpacing.s32),
          ],
        ),
      ),
    );
  }
}

/// حلقه دایره‌ای پیشرفت کالری
class _CalorieRing extends StatelessWidget {
  final double consumed;
  final double target;
  final BergamotColors colors;

  const _CalorieRing({
    required this.consumed,
    required this.target,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (consumed / target).clamp(0.0, 1.5);
    final displayPercentage = (consumed / target * 100).clamp(0, 999);

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _CalorieRingPainter(
            percentage: percentage.clamp(0, 1),
            colors: colors,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consumed.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'از ${target.toStringAsFixed(0)} کیلوکالری',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: BergamotSpacing.s4),
                Text(
                  '%${displayPercentage.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter حلقه کالری
class _CalorieRingPainter extends CustomPainter {
  final double percentage;
  final BergamotColors colors;

  _CalorieRingPainter({required this.percentage, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    const strokeWidth = 14.0;

    // پس‌زمینه حلقه
    final bgPaint = Paint()
      ..color = colors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // حلقه پیشرفت
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = percentage >= 1.0 ? colors.success : colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.141592653589793 * percentage;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.141592653589793 / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

/// نوار پیشرفت ماکرو
class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
  final BergamotColors colors;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (current / target).clamp(0.0, 1.0);
    final percentText = (current / target * 100).toStringAsFixed(0);

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BergamotSpacing.br4,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BergamotSpacing.br4,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: BergamotSpacing.s8),
        SizedBox(
          width: 100,
          child: Text(
            '${current.toStringAsFixed(1)} $unit (%$percentText)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// کارت بخش وعده غذایی
class _MealSectionCard extends ConsumerWidget {
  final int mealType;
  final List<MealEntry> meals;

  const _MealSectionCard({
    required this.mealType,
    required this.meals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final mealName = mealTypeNames[mealType] ?? '';
    final icon = mealTypeIcons[mealType] ?? Icons.restaurant;
    final totalCalories =
        meals.fold<double>(0, (sum, m) => sum + m.calories);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // هدر وعده
            Row(
              children: [
                Icon(icon, color: colors.primary, size: 22),
                const SizedBox(width: BergamotSpacing.s8),
                Expanded(
                  child: Text(
                    mealName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '${totalCalories.toStringAsFixed(0)} کیلوکالری',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                if (meals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: BergamotSpacing.s4),
                    child: InkWell(
                      onTap: () => _saveAsTemplate(context, ref, mealType, meals),
                      borderRadius: BergamotSpacing.br8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.tagBg,
                          borderRadius: BergamotSpacing.br8,
                        ),
                        child: Icon(
                          Icons.bookmark_add_outlined,
                          color: colors.tagText,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: BergamotSpacing.s4),
                InkWell(
                  onTap: () => _openFoodSearchForMeal(context, mealType),
                  borderRadius: BergamotSpacing.br8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.tagBg,
                      borderRadius: BergamotSpacing.br8,
                    ),
                    child: Icon(
                      Icons.add,
                      color: colors.tagText,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s12),

            // لیست غذاها یا حالت خالی
            if (meals.isEmpty)
              _EmptyMealState(
                onTap: () => _openFoodSearchForMeal(context, mealType),
                colors: colors,
              )
            else
              ...meals.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
                  child: _MealFoodItem(entry: m, colors: colors),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFoodSearchForMeal(BuildContext context, int mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FoodSearchSheet(preselectedMealType: mealType),
    );
  }

  void _saveAsTemplate(
      BuildContext context, WidgetRef ref, int mealType, List<MealEntry> meals) {
    final controller = TextEditingController();
    final colors = context.bergamotColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BergamotSpacing.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ذخیره به‌عنوان قالب',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: BergamotSpacing.s16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'مثلاً ${mealTypeNames[mealType]} همیشگی',
                    hintStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: BergamotSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      final db = ref.read(bergamotDatabaseProvider);
                      final dao = MealTemplateDao(db);
                      await dao.saveTemplate(name, mealType, meals);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('قالب ذخیره شد'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('ذخیره'),
                  ),
                ),
                const SizedBox(height: BergamotSpacing.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// آیتم غذای یک وعده
class _MealFoodItem extends StatelessWidget {
  final MealEntry entry;
  final BergamotColors colors;

  const _MealFoodItem({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
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
        final ref = ProviderScope.containerOf(context);
        ref.read(todayMealsProvider.notifier).deleteMeal(entry.id);
      },
      child: InkWell(
        onTap: () {
          // نمایش جزئیات غذا
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => _MealEntryDetailSheet(entry: entry),
          );
        },
        borderRadius: BergamotSpacing.br12,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s12,
            vertical: BergamotSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: colors.overlay,
            borderRadius: BergamotSpacing.br12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.foodName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.servingCount.toStringAsFixed(1)} سروینگ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.calories.toStringAsFixed(0)} کیلوکالری',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حالت خالی وعده
class _EmptyMealState extends StatelessWidget {
  final VoidCallback onTap;
  final BergamotColors colors;

  const _EmptyMealState({required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BergamotSpacing.br12,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: BergamotSpacing.s16,
          horizontal: BergamotSpacing.s12,
        ),
        decoration: BoxDecoration(
          borderRadius: BergamotSpacing.br12,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: colors.textSecondary, size: 20),
            const SizedBox(width: BergamotSpacing.s8),
            Text(
              'هیچ غذایی ثبت نشده',
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

/// شیت جزئیات وعده ثبت‌شده (غیرغذای پایه)
class _MealEntryDetailSheet extends StatelessWidget {
  final MealEntry entry;

  const _MealEntryDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.foodName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s4),
            Text(
              '${entry.servingCount.toStringAsFixed(1)} سروینگ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s16),
            _NutritionGrid(
              calories: entry.calories,
              protein: entry.protein,
              fat: entry.fat,
              carb: entry.carb,
              fiber: 0,
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
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

/// گرید اطلاعات غذایی
class _NutritionGrid extends StatelessWidget {
  final double calories;
  final double protein;
  final double fat;
  final double carb;
  final double fiber;
  final BergamotColors colors;

  const _NutritionGrid({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.fiber,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: BergamotSpacing.s8,
      crossAxisSpacing: BergamotSpacing.s8,
      childAspectRatio: 1.1,
      children: [
        _NutritionCard(
          label: 'کالری',
          value: calories.toStringAsFixed(0),
          unit: 'کیلوکالری',
          color: colors.primary,
          colors: colors,
        ),
        _NutritionCard(
          label: 'پروتئین',
          value: protein.toStringAsFixed(1),
          unit: 'گرم',
          color: colors.error,
          colors: colors,
        ),
        _NutritionCard(
          label: 'چربی',
          value: fat.toStringAsFixed(1),
          unit: 'گرم',
          color: colors.warning,
          colors: colors,
        ),
        _NutritionCard(
          label: 'کربوهیدرات',
          value: carb.toStringAsFixed(1),
          unit: 'گرم',
          color: const Color(0xFF3B82F6),
          colors: colors,
        ),
        _NutritionCard(
          label: 'فیبر',
          value: fiber.toStringAsFixed(1),
          unit: 'گرم',
          color: colors.success,
          colors: colors,
        ),
      ],
    );
  }
}

/// کارت واحد اطلاعات غذایی
class _NutritionCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final BergamotColors colors;

  const _NutritionCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BergamotSpacing.s8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.08 * 255).round()),
        borderRadius: BergamotSpacing.br12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.text,
                ),
          ),
        ],
      ),
    );
  }
}
