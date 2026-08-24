import 'package:flutter/material.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../../domain/entities/bergamot_nutrition_calculator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../meal_builder/meal_builder_sheet.dart';
import '../nutrition_provider.dart';

/// شیت جزئیات غذا
///
/// نمایش نام، اندازه سروینگ، source (USDA / IRANIAN_REFERENCE / CUSTOM)،
/// وضعیت تأیید و مقادیر غذایی یک غذا.
///
/// اگر غذا در وضعیت NEEDS_VERIFICATION باشد، یک badge زرد برجسته نمایش
/// داده می‌شود تا کاربر بداند مقادیر قطعی نیست.
class FoodDetailSheet extends StatelessWidget {
  final Food food;

  const FoodDetailSheet({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final displayName = food.nameFa?.isNotEmpty == true ? food.nameFa! : food.nameEn;
    final needsVerification = food.verificationStatus == 'NEEDS_VERIFICATION';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نام غذا + badge تأیید
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (needsVerification) _VerificationBadge(colors: colors),
              ],
            ),
            if (food.nameEn.isNotEmpty && food.nameEn != food.nameFa) ...[
              const SizedBox(height: BergamotSpacing.s4),
              Text(
                food.nameEn,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                textDirection: TextDirection.ltr,
              ),
            ],
            const SizedBox(height: BergamotSpacing.s8),

            // source chip + serving info
            Wrap(
              spacing: BergamotSpacing.s8,
              runSpacing: BergamotSpacing.s4,
              children: [
                _SourceChip(source: food.source, colors: colors),
                _ServingChip(
                  servingSize: food.servingSize,
                  servingUnit: food.servingUnit,
                  servingDescriptionFa: food.servingDescriptionFa,
                  colors: colors,
                ),
                if (food.preparationState != null)
                  _PreparationChip(state: food.preparationState!, colors: colors),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // گرید اطلاعات غذایی
            _NutritionDetailGrid(food: food, colors: colors),
            const SizedBox(height: BergamotSpacing.s24),

            // دکمه افزودن به وعده
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => MealBuilderSheet(food: food),
                  );
                },
                child: const Text('افزودن به وعده'),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
          ],
        ),
      ),
    );
  }
}

/// Badge وضعیت تأیید — به‌صورت برجسته نشان می‌دهد که مقادیر غذا قطعی نیست.
///
/// نمایش: آیکون هشدار + متن «نیازمند تأیید» با رنگ زرد/نارنجی.
class _VerificationBadge extends StatelessWidget {
  final BergamotColors colors;
  const _VerificationBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s8,
        vertical: BergamotSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: colors.warning.withAlpha((0.15 * 255).round()),
        borderRadius: BergamotSpacing.br8,
        border: Border.all(color: colors.warning.withAlpha((0.4 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: colors.warning),
          const SizedBox(width: 4),
          Text(
            'نیازمند تأیید',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.warning,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Chip نمایش منبع داده (USDA_FOUNDATION / IRANIAN_REFERENCE / ...)
class _SourceChip extends StatelessWidget {
  final String source;
  final BergamotColors colors;
  const _SourceChip({required this.source, required this.colors});

  String _label() {
    switch (source) {
      case 'USDA_FOUNDATION':
        return 'USDA Foundation';
      case 'USDA_SR_LEGACY':
        return 'USDA SR Legacy';
      case 'USDA_FNDDS':
        return 'USDA FNDDS';
      case 'IRANIAN_REFERENCE':
        return 'منبع ایرانی';
      case 'CUSTOM':
        return 'سفارشی';
      default:
        return source;
    }
  }

  IconData _icon() {
    switch (source) {
      case 'USDA_FOUNDATION':
      case 'USDA_SR_LEGACY':
      case 'USDA_FNDDS':
        return Icons.verified_outlined;
      case 'IRANIAN_REFERENCE':
        return Icons.flag_outlined;
      case 'CUSTOM':
        return Icons.person_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _color() {
    switch (source) {
      case 'USDA_FOUNDATION':
      case 'USDA_SR_LEGACY':
      case 'USDA_FNDDS':
        return colors.primary;
      case 'IRANIAN_REFERENCE':
        return colors.success;
      case 'CUSTOM':
        return colors.textSecondary;
      default:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s8,
        vertical: BergamotSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: c.withAlpha((0.1 * 255).round()),
        borderRadius: BergamotSpacing.br8,
        border: Border.all(color: c.withAlpha((0.25 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Chip نمایش اندازه سروینگ
class _ServingChip extends StatelessWidget {
  final double? servingSize;
  final String servingUnit;
  final String? servingDescriptionFa;
  final BergamotColors colors;
  const _ServingChip({
    required this.servingSize,
    required this.servingUnit,
    required this.servingDescriptionFa,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = servingDescriptionFa ??
        (servingSize != null
            ? 'هر ${servingSize!.toStringAsFixed(0)} ${servingUnitFa(servingUnit)}'
            : 'هر ۱۰۰ گرم');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s8,
        vertical: BergamotSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: colors.tagBg,
        borderRadius: BergamotSpacing.br8,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.tagText,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Chip نمایش وضعیت آماده‌سازی (raw / cooked / fried / ...)
class _PreparationChip extends StatelessWidget {
  final String state;
  final BergamotColors colors;
  const _PreparationChip({required this.state, required this.colors});

  String _label() {
    switch (state.toLowerCase()) {
      case 'raw':
        return 'خام';
      case 'cooked':
        return 'پخته';
      case 'boiled':
        return 'آب‌پز';
      case 'fried':
        return 'سرخ‌شده';
      case 'baked':
        return 'تنوری';
      case 'steamed':
        return 'بخارپز';
      case 'grilled':
        return 'گریل‌شده';
      case 'roasted':
        return 'برشته';
      case 'dried':
        return 'خشک';
      case 'fresh':
        return 'تازه';
      case 'canned':
        return 'کنسروی';
      case 'frozen':
        return 'منجمد';
      case 'juice':
        return 'آب‌میوه';
      case 'puree':
        return 'پوره';
      case 'powder':
        return 'پودر';
      case 'ground':
        return 'کوبیده';
      default:
        return state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s8,
        vertical: BergamotSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: colors.overlay,
        borderRadius: BergamotSpacing.br8,
      ),
      child: Text(
        _label(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
      ),
    );
  }
}

/// گرید جزئیات غذایی — ۹ ماکرو به‌صورت ۳×۳
class _NutritionDetailGrid extends StatelessWidget {
  final Food food;
  final BergamotColors colors;

  const _NutritionDetailGrid({required this.food, required this.colors});

  /// Per-serving nutrition values (or per-100g if no serving size defined).
  ///
  /// Conversion: `per100g × (servingSize / 100)`. Division-by-zero is
  /// impossible because [BergamotNutritionCalculator.scaleByGrams] guards
  /// against `grams <= 0` and returns an all-null [BergamotNutrition].
  BergamotNutrition get _perServing {
    if (food.servingSize == null) {
      return BergamotNutritionCalculator.scaleByGrams(food, 100);
    }
    return BergamotNutritionCalculator.scaleByServings(food, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final n = _perServing;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NutritionDetailCard(
                label: 'کالری',
                value: n.calories != null ? n.calories!.toStringAsFixed(0) : '—',
                unit: 'کیلوکالری',
                color: colors.primary,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _NutritionDetailCard(
                label: 'پروتئین',
                value: n.protein != null ? n.protein!.toStringAsFixed(1) : '—',
                unit: 'گرم',
                color: colors.error,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _NutritionDetailCard(
                label: 'چربی',
                value: n.fat != null ? n.fat!.toStringAsFixed(1) : '—',
                unit: 'گرم',
                color: colors.warning,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: BergamotSpacing.s8),
        Row(
          children: [
            Expanded(
              child: _NutritionDetailCard(
                label: 'کربوهیدرات',
                value: n.carbs != null ? n.carbs!.toStringAsFixed(1) : '—',
                unit: 'گرم',
                color: colors.carbs,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _NutritionDetailCard(
                label: 'فیبر',
                value: n.fiber != null ? n.fiber!.toStringAsFixed(1) : '—',
                unit: 'گرم',
                color: colors.success,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _NutritionDetailCard(
                label: 'شکر',
                value: n.sugar != null ? n.sugar!.toStringAsFixed(1) : '—',
                unit: 'گرم',
                color: colors.sugar,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: BergamotSpacing.s8),
        Row(
          children: [
            Expanded(
              child: _NutritionDetailCard(
                label: 'سدیم',
                value: n.sodium != null ? n.sodium!.toStringAsFixed(0) : '—',
                unit: 'میلی‌گرم',
                color: colors.sodium,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _NutritionDetailCard(
                label: 'پتاسیم',
                value: n.potassium != null ? n.potassium!.toStringAsFixed(0) : '—',
                unit: 'میلی‌گرم',
                color: colors.potassium,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            Expanded(
              child: _NutritionDetailCard(
                label: 'کلسیم',
                value: n.calcium != null ? n.calcium!.toStringAsFixed(0) : '—',
                unit: 'میلی‌گرم',
                color: colors.calcium,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: BergamotSpacing.s8),
        Row(
          children: [
            Expanded(
              child: _NutritionDetailCard(
                label: 'آهن',
                value: n.iron != null ? n.iron!.toStringAsFixed(1) : '—',
                unit: 'میلی‌گرم',
                color: colors.iron,
                colors: colors,
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            const Expanded(child: SizedBox()),
            const SizedBox(width: BergamotSpacing.s8),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

/// کارت واحد جزئیات غذایی
///
/// مقدار بزرگ، واحد و نام ماکرو. اگر مقدار NULL باشد، "—" نمایش داده می‌شود.
class _NutritionDetailCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final BergamotColors colors;

  const _NutritionDetailCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BergamotSpacing.s12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.08 * 255).round()),
        borderRadius: BergamotSpacing.br12,
        border: Border.all(
          color: color.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
            textDirection: TextDirection.ltr,
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
