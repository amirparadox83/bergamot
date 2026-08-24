import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../exercise_provider.dart';

/// شیت پایین جزئیات تمرین
///
/// نمایش اطلاعات کامل تمرین و دکمه افزودن
///
/// PHASE 3.2: دکمه favorite (قلب) در هدر اضافه شد.
class ExerciseDetailSheet extends ConsumerWidget {
  final Exercise exercise;
  final bool selectionMode;

  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final favAsync = ref.watch(favoriteExerciseIdsProvider);
    final isFavorite = favAsync.maybeWhen(
      data: (ids) => ids.contains(exercise.id),
      orElse: () => false,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BergamotSpacing.s16,
          BergamotSpacing.s8,
          BergamotSpacing.s16,
          BergamotSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ردیف نام و دکمه favorite ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── نام تمرین ──
                      Text(
                        exercise.nameFa,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (exercise.nameEn != null) ...[
                        const SizedBox(height: BergamotSpacing.s4),
                        Text(
                          exercise.nameEn!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: BergamotSpacing.s8),
                // ── دکمه favorite (PHASE 3.2) ──
                IconButton(
                  onPressed: () {
                    ref
                        .read(favoriteExerciseNotifierProvider.notifier)
                        .toggle(exercise.id);
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? const Color(0xFFEC4899)
                        : colors.textSecondary,
                    size: 28,
                  ),
                  tooltip: isFavorite
                      ? 'حذف از علاقه‌مندی‌ها'
                      : 'افزودن به علاقه‌مندی‌ها',
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // ── ردیف اطلاعات ──
            Row(
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: categoryFa(exercise.category),
                  colors: colors,
                ),
                const SizedBox(width: BergamotSpacing.s8),
                _InfoChip(
                  icon: Icons.star,
                  label: '${exercise.difficulty} از ۳',
                  colors: colors,
                ),
                const SizedBox(width: BergamotSpacing.s8),
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: equipmentFa(exercise.equipment),
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // ── گروه‌های عضلانی ──
            if (exercise.muscleGroups.isNotEmpty) ...[
              Text(
                'گروه‌های عضلانی',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Wrap(
                spacing: BergamotSpacing.s8,
                runSpacing: BergamotSpacing.s8,
                children: exercise.muscleGroups
                    .split(',')
                    .where((g) => g.trim().isNotEmpty)
                    .map((g) => Chip(
                          label: Text(g.trim()),
                        ))
                    .toList(),
              ),
              const SizedBox(height: BergamotSpacing.s16),
            ],

            // ── دستورالعمل ──
            if (exercise.instructionsFa != null &&
                exercise.instructionsFa!.isNotEmpty) ...[
              Text(
                'دستورالعمل',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BergamotSpacing.s12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BergamotSpacing.br12,
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  exercise.instructionsFa!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s16),
            ],

            // ── نکات (v7 field) ──
            if (exercise.tips != null && exercise.tips!.isNotEmpty) ...[
              Text(
                'نکات',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BergamotSpacing.s12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BergamotSpacing.br12,
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  exercise.tips!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s16),
            ],

            // ── اشتباهات رایج (v7 field) ──
            if (exercise.commonMistakes != null &&
                exercise.commonMistakes!.isNotEmpty) ...[
              Text(
                'اشتباهات رایج',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.error,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BergamotSpacing.s12),
                decoration: BoxDecoration(
                  color: colors.error.withAlpha(15),
                  borderRadius: BergamotSpacing.br12,
                  border: Border.all(color: colors.error.withAlpha(50)),
                ),
                child: Text(
                  exercise.commonMistakes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: BergamotSpacing.s16),
            ],

            // ── دکمه افزودن ──
            if (selectionMode)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(exercise),
                icon: const Icon(Icons.add),
                label: const Text('افزودن به تمرین'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── آیتم اطلاعات ────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final BergamotColors colors;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s12,
        vertical: BergamotSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: colors.tagBg,
        borderRadius: BergamotSpacing.br10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: BergamotSpacing.s4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.tagText,
            ),
          ),
        ],
      ),
    );
  }
}
