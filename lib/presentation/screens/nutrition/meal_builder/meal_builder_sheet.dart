import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../../domain/entities/bergamot_nutrition_calculator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../nutrition_provider.dart';

/// شیت ساخت وعده غذایی
///
/// انتخاب تعداد سروینگ و نوع وعده، سپس ثبت در دیتابیس.
///
/// محاسبات از BergamotNutritionCalculator مرکزی استفاده می‌کند که بر اساس
/// per-100g canonical است. مقادیر نهایی قبل از ثبت در MealEntry به‌عنوان
/// snapshot ذخیره می‌شوند تا تاریخچه کاربر در صورت تغییرات آینده Foods
/// خراب نشود.
class MealBuilderSheet extends ConsumerStatefulWidget {
  final Food food;
  final int? preselectedMealType;

  const MealBuilderSheet({
    super.key,
    required this.food,
    this.preselectedMealType,
  });

  @override
  ConsumerState<MealBuilderSheet> createState() => _MealBuilderSheetState();
}

class _MealBuilderSheetState extends ConsumerState<MealBuilderSheet> {
  double _servingCount = 1.0;
  int _selectedMealType = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.preselectedMealType ?? 0;
  }

  /// کل gram weight که کاربر می‌خواهد بخورد.
  double get _totalGrams {
    final perServing = widget.food.servingSize ?? 100.0;
    return perServing * _servingCount;
  }

  BergamotNutrition get _nutrition {
    final n = BergamotNutritionCalculator.scaleByGrams(widget.food, _totalGrams);
    return BergamotNutritionCalculator.roundForDisplay(n);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final n = _nutrition;
      await ref.read(todayMealsProvider.notifier).addMeal(
            foodId: widget.food.id,
            foodName: widget.food.nameFa?.isNotEmpty == true
                ? widget.food.nameFa!
                : widget.food.nameEn,
            mealType: _selectedMealType,
            servingCount: _servingCount,
            // Save snapshot — meal history won't break if food changes later
            // TODO: Snapshot all 10 nutrition fields (sugar, sodium, potassium, calcium, iron missing)
            calories: n.calories ?? 0,
            protein: n.protein ?? 0,
            fat: n.fat ?? 0,
            carb: n.carbs ?? 0,
            fiber: n.fiber ?? 0,
            grams: _totalGrams,
            foodSource: widget.food.source,
            foodExternalId: widget.food.externalId,
          );
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final n = _nutrition;
    final displayName = widget.food.nameFa?.isNotEmpty == true
        ? widget.food.nameFa!
        : widget.food.nameEn;
    final servingInfo = widget.food.servingSize != null
        ? 'هر سروینگ: ${widget.food.servingSize!.toStringAsFixed(0)} ${servingUnitFa(widget.food.servingUnit)}  ·  ${widget.food.caloriesPer100g != null ? (widget.food.caloriesPer100g! * widget.food.servingSize! / 100).toStringAsFixed(0) : '—'} کیلوکالری'
        : 'هر ۱۰۰ گرم: ${widget.food.caloriesPer100g?.toStringAsFixed(0) ?? '—'} کیلوکالری';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نام غذا و اطلاعات سروینگ
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s4),
            Text(
              servingInfo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // استپر تعداد سروینگ
            Text(
              'تعداد سروینگ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            _ServingStepper(
              count: _servingCount,
              onChanged: (v) => setState(() => _servingCount = v),
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'مجموع: ${_totalGrams.toStringAsFixed(0)} گرم',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // مجموع مقادیر غذایی
            _TotalNutritionSummary(
              calories: n.calories ?? 0,
              protein: n.protein ?? 0,
              fat: n.fat ?? 0,
              carb: n.carbs ?? 0,
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // انتخاب نوع وعده
            Text(
              'افزودن به',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s12),
            _MealTypeSelector(
              selectedType: _selectedMealType,
              onChanged: (v) => setState(() => _selectedMealType = v),
              colors: colors,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // دکمه تأیید
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ثبت'),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
          ],
        ),
      ),
    );
  }
}

/// استپر تعداد سروینگ
class _ServingStepper extends StatelessWidget {
  final double count;
  final ValueChanged<double> onChanged;
  final BergamotColors colors;

  const _ServingStepper({
    required this.count,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(
          icon: Icons.remove,
          onTap: count > 0.5
              ? () => onChanged((count - 0.5).clamp(0.5, 20))
              : null,
          colors: colors,
        ),
        const SizedBox(width: BergamotSpacing.s24),
        Container(
          width: 64,
          alignment: Alignment.center,
          child: Text(
            count.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(width: BergamotSpacing.s24),
        _StepperButton(
          icon: Icons.add,
          onTap: count < 20
              ? () => onChanged((count + 0.5).clamp(0.5, 20))
              : null,
          colors: colors,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final BergamotColors colors;

  const _StepperButton({
    required this.icon,
    this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BergamotSpacing.br12,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap != null ? colors.tagBg : colors.border,
          ),
          child: Icon(
            icon,
            color: onTap != null ? colors.tagText : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TotalNutritionSummary extends StatelessWidget {
  final double calories;
  final double protein;
  final double fat;
  final double carb;
  final BergamotColors colors;

  const _TotalNutritionSummary({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BergamotSpacing.s16),
      decoration: BoxDecoration(
        color: colors.overlay,
        borderRadius: BergamotSpacing.br16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مجموع مقادیر غذایی',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: BergamotSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroItem(
                label: 'کالری',
                value: calories.toStringAsFixed(0),
                unit: 'کیلوکالری',
                color: colors.primary,
              ),
              _MacroItem(
                label: 'پروتئین',
                value: protein.toStringAsFixed(1),
                unit: 'گرم',
                color: colors.error,
              ),
              _MacroItem(
                label: 'چربی',
                value: fat.toStringAsFixed(1),
                unit: 'گرم',
                color: colors.warning,
              ),
              _MacroItem(
                label: 'کربوهیدرات',
                value: carb.toStringAsFixed(1),
                unit: 'گرم',
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
          textDirection: TextDirection.ltr,
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.bergamotColors.textSecondary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.bergamotColors.text,
              ),
        ),
      ],
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  final int selectedType;
  final ValueChanged<int> onChanged;
  final BergamotColors colors;

  const _MealTypeSelector({
    required this.selectedType,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int type = 0; type < 4; type++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: type < 3 ? BergamotSpacing.s4 : 0,
                right: type > 0 ? BergamotSpacing.s4 : 0,
              ),
              child: _MealTypeButton(
                type: type,
                isSelected: type == selectedType,
                onTap: () => onChanged(type),
                colors: colors,
              ),
            ),
          ),
      ],
    );
  }
}

class _MealTypeButton extends StatelessWidget {
  final int type;
  final bool isSelected;
  final VoidCallback onTap;
  final BergamotColors colors;

  const _MealTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final icon = mealTypeIcons[type] ?? Icons.restaurant;
    final name = mealTypeNames[type] ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BergamotSpacing.br12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: BergamotSpacing.s12,
          horizontal: BergamotSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BergamotSpacing.br12,
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.surface : colors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: BergamotSpacing.s4),
            Text(
              name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected ? colors.surface : colors.text,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
