import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../../data/database/meal_template_dao.dart';
import '../../../../data/database/database_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'nutrition_provider.dart';

/// پرووایر DAO قالب‌های غذایی
final mealTemplateDaoProvider = Provider<MealTemplateDao>((ref) {
  return MealTemplateDao(ref.watch(bergamotDatabaseProvider));
});

/// شیت قالب‌های غذایی
///
/// نمایش لیست قالب‌های ذخیره‌شده با امکان ثبت سریع هر قالب
/// از صفحه تغذیه با دکمه «قالب‌ها» باز می‌شود
class MealTemplateSheet extends ConsumerStatefulWidget {
  const MealTemplateSheet({super.key});

  @override
  ConsumerState<MealTemplateSheet> createState() => _MealTemplateSheetState();
}

class _MealTemplateSheetState extends ConsumerState<MealTemplateSheet> {
  bool _isLoading = true;
  List<MealTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final dao = ref.read(mealTemplateDaoProvider);
    final templates = await dao.getAllTemplates();
    if (mounted) {
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    }
  }

  Future<void> _useTemplate(MealTemplate template) async {
    final dao = ref.read(mealTemplateDaoProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    await dao.useTemplate(template.id, startOfDay);
    ref.invalidate(todayMealsProvider);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('«${template.name}» ثبت شد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteTemplate(int id) async {
    final dao = ref.read(mealTemplateDaoProvider);
    await dao.deleteTemplate(id);
    await _loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // هدر
            Padding(
              padding: const EdgeInsets.all(BergamotSpacing.s16),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: colors.primary, size: 22),
                  const SizedBox(width: BergamotSpacing.s8),
                  Text(
                    'قالب‌های غذایی',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // محتوا
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(BergamotSpacing.s32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_templates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(BergamotSpacing.s32),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: colors.textSecondary, size: 48),
                    const SizedBox(height: BergamotSpacing.s12),
                    Text(
                      'هنوز قالب غذایی ذخیره نشده',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: BergamotSpacing.s8),
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    return _TemplateCard(
                      template: t,
                      colors: colors,
                      onRegister: () => _useTemplate(t),
                      onDelete: () => _deleteTemplate(t.id),
                    );
                  },
                ),
              ),
            const SizedBox(height: BergamotSpacing.s16),
          ],
        ),
      ),
    );
  }
}

/// کارت قالب غذایی

class _TemplateCard extends StatelessWidget {
  final MealTemplate template;
  final BergamotColors colors;
  final VoidCallback onRegister;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.colors,
    required this.onRegister,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mealName = mealTypeNames[template.mealType] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BergamotSpacing.s16),
      child: Container(
        padding: const EdgeInsets.all(BergamotSpacing.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BergamotSpacing.br12,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // اطلاعات قالب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$mealName  ·  ${template.totalCalories.toStringAsFixed(0)} کیلوکالری',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BergamotSpacing.s8),
            // دکمه حذف
            InkWell(
              onTap: onDelete,
              borderRadius: BergamotSpacing.br8,
              child: Padding(
                padding: const EdgeInsets.all(BergamotSpacing.s8),
                child: Icon(
                  Icons.delete_outline,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: BergamotSpacing.s4),
            // دکمه ثبت
            InkWell(
              onTap: onRegister,
              borderRadius: BergamotSpacing.br8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s12,
                  vertical: BergamotSpacing.s8,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BergamotSpacing.br8,
                ),
                child: Text(
                  'ثبت',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.surface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
