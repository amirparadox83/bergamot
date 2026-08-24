import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'exercise_detail_sheet.dart';
import '../exercise_provider.dart';

/// صفحه کتابخانه تمرینات
///
/// جستجو، فیلتر دسته‌بندی و لیست تمرینات
/// حالت انتخاب: وقتی selectionMode=true، دکمه افزودن نمایش داده می‌شود
///
/// PHASE 3.2: دکمه Favorite (قلب) به کارت و detail sheet اضافه شد.
/// PHASE 3.5: فیلتر عضله/هدف/دشواری/تجهیزات اضافه شد.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// آیا در حالت انتخاب (برای افزودن به تمرین) است؟
  final bool selectionMode;

  const ExerciseLibraryScreen({super.key, this.selectionMode = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _selectedMuscle; // primaryMuscle filter (PHASE 3.5)
  int? _selectedDifficulty; // 1/2/3 (PHASE 3.5)
  bool _showFavoritesOnly = false; // (PHASE 3.2)

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final exercisesAsync = ref.watch(exercisesProvider);
    final favIdsAsync = ref.watch(favoriteExerciseIdsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            widget.selectionMode ? 'افزودن تمرین' : 'کتابخانه تمرینات',
          ),
        ),
        body: Column(
          children: [
            // ── نوار جستجو ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BergamotSpacing.s16,
                vertical: BergamotSpacing.s8,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'جستجوی تمرین...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            // ── فیلتر دسته‌بندی (legacy) ──
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s16,
                ),
                itemCount: categoryFilters.length + 2,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: BergamotSpacing.s8),
                itemBuilder: (context, index) {
                  // favorites filter first
                  if (index == 0) {
                    return FilterChip(
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, size: 14),
                          SizedBox(width: 4),
                          Text('علاقه‌مندی‌ها'),
                        ],
                      ),
                      selected: _showFavoritesOnly,
                      onSelected: (selected) {
                        setState(() => _showFavoritesOnly = selected);
                      },
                      selectedColor: colors.primary,
                      labelStyle: TextStyle(
                        color: _showFavoritesOnly ? Colors.white : null,
                      ),
                    );
                  }
                  // difficulty filter chip
                  if (index == 1) {
                    return FilterChip(
                      label: Text(_selectedDifficulty == null
                          ? 'همه سطوح'
                          : 'دشواری: ${'★' * _selectedDifficulty!}'),
                      selected: _selectedDifficulty != null,
                      onSelected: (_) => _showDifficultyFilter(context),
                    );
                  }
                  // category filters
                  final cat = categoryFilters[index - 2];
                  final isSelected = _selectedCategory == cat.key;
                  return FilterChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat.key);
                    },
                  );
                },
              ),
            ),

            // ── فیلتر گروه عضلانی (PHASE 3.5) ──
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s16,
                  vertical: BergamotSpacing.s4,
                ),
                itemCount: muscleGroupFilters.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: BergamotSpacing.s8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: const Text('همه عضلات'),
                      selected: _selectedMuscle == null,
                      onSelected: (_) {
                        setState(() => _selectedMuscle = null);
                      },
                    );
                  }
                  final m = muscleGroupFilters[index - 1];
                  return ChoiceChip(
                    label: Text(m.label),
                    selected: _selectedMuscle == m.code,
                    onSelected: (_) {
                      setState(() => _selectedMuscle = m.code);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: BergamotSpacing.s8),

            // ── لیست تمرینات ──
            Expanded(
              child: favIdsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('خطا در بارگذاری')),
                data: (favIds) => exercisesAsync.when(
                  data: (exercises) {
                    var filtered = exercises;

                    // فیلتر علاقه‌مندی‌ها
                    if (_showFavoritesOnly) {
                      filtered = filtered
                          .where((e) => favIds.contains(e.id))
                          .toList();
                    }

                    // فیلتر دسته‌بندی (legacy)
                    if (_selectedCategory != 'all') {
                      filtered = filtered
                          .where((e) => e.category == _selectedCategory)
                          .toList();
                    }

                    // فیلتر عضله اصلی (PHASE 3.5)
                    if (_selectedMuscle != null) {
                      filtered = filtered.where((e) {
                        // First check primaryMuscle (v7 field)
                        if (e.primaryMuscle == _selectedMuscle) return true;
                        // Fall back to legacy muscleGroups CSV
                        return e.muscleGroups
                            .split(',')
                            .any((g) => g.trim() == _selectedMuscle);
                      }).toList();
                    }

                    // فیلتر دشواری
                    if (_selectedDifficulty != null) {
                      filtered = filtered
                          .where((e) => e.difficulty == _selectedDifficulty)
                          .toList();
                    }

                    // فیلتر جستجو
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      filtered = filtered
                          .where((e) =>
                              e.nameFa.toLowerCase().contains(q) ||
                              (e.nameEn?.toLowerCase().contains(q) ?? false))
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showFavoritesOnly
                                  ? Icons.favorite_border
                                  : Icons.search_off,
                              size: 48,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(height: BergamotSpacing.s12),
                            Text(
                              _showFavoritesOnly
                                  ? 'هیچ علاقه‌مندی‌ای موجود نیست'
                                  : 'تمرینی یافت نشد',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BergamotSpacing.s16,
                        vertical: BergamotSpacing.s8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: BergamotSpacing.s8),
                      itemBuilder: (context, index) {
                        return _ExerciseCard(
                          exercise: filtered[index],
                          colors: colors,
                          selectionMode: widget.selectionMode,
                          isFavorite: favIds.contains(filtered[index].id),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: ExerciseDetailSheet(
                                  exercise: filtered[index],
                                  selectionMode: widget.selectionMode,
                                ),
                              ),
                            );
                          },
                          onToggleFavorite: () {
                            ref
                                .read(favoriteExerciseNotifierProvider
                                    .notifier)
                                .toggle(filtered[index].id);
                          },
                          onAdd: widget.selectionMode
                              ? () {
                                  Navigator.of(context).pop(filtered[index]);
                                }
                              : null,
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'خطا در بارگذاری تمرینات',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نمایش dialog فیلتر دشواری
  Future<void> _showDifficultyFilter(BuildContext context) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('سطح دشواری'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 0), // 0 = no filter
            child: const Text('همه سطوح'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('★ مبتدی'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 2),
            child: const Text('★★ متوسط'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 3),
            child: const Text('★★★ پیشرفته'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _selectedDifficulty = selected == 0 ? null : selected);
    }
  }
}

// ─── کارت تمرین ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final BergamotColors colors;
  final bool selectionMode;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onAdd;

  const _ExerciseCard({
    required this.exercise,
    required this.colors,
    required this.selectionMode,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BergamotSpacing.br16,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s12),
          child: Row(
            children: [
              // ستاره‌های دشواری
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < exercise.difficulty ? Icons.star : Icons.star_border,
                    size: 16,
                    color: colors.accent,
                  ),
                ),
              ),
              const SizedBox(width: BergamotSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nameFa,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    Wrap(
                      spacing: BergamotSpacing.s4,
                      runSpacing: BergamotSpacing.s4,
                      children: [
                        // برچسب دسته‌بندی
                        _Tag(
                          label: categoryFa(exercise.category),
                          colors: colors,
                        ),
                        // برچسب تجهیزات
                        _Tag(
                          label: equipmentFa(exercise.equipment),
                          colors: colors,
                          outlined: true,
                        ),
                        // عضله اصلی (v7)
                        if (exercise.primaryMuscle != null &&
                            exercise.primaryMuscle!.isNotEmpty)
                          _Tag(
                            label: muscleGroupFa(exercise.primaryMuscle!),
                            colors: colors,
                            outlined: true,
                          ),
                        // گروه‌های عضلانی legacy (2 مورد اول)
                        ...exercise.muscleGroups
                            .split(',')
                            .where((g) => g.trim().isNotEmpty)
                            .take(2)
                            .map(
                              (g) => _Tag(
                                label: g.trim(),
                                colors: colors,
                                outlined: true,
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
              // دکمه favorite (PHASE 3.2)
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFEC4899) : colors.textSecondary,
                  size: 22,
                ),
                tooltip: isFavorite ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها',
                visualDensity: VisualDensity.compact,
              ),
              if (selectionMode && onAdd != null) ...[
                IconButton(
                  onPressed: onAdd,
                  icon: Icon(
                    Icons.add_circle,
                    color: colors.primary,
                    size: 32,
                  ),
                  tooltip: 'افزودن به تمرین',
                ),
              ] else if (!selectionMode) ...[
                Icon(
                  Icons.chevron_left,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── تگ ─────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final BergamotColors colors;
  final bool outlined;

  const _Tag({
    required this.label,
    required this.colors,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s8,
        vertical: BergamotSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : colors.tagBg,
        borderRadius: BergamotSpacing.br8,
        border: outlined ? Border.all(color: colors.border) : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: outlined ? colors.textSecondary : colors.tagText,
        ),
      ),
    );
  }
}

// ─── لیست فیلترهای گروه عضلانی (PHASE 3.5) ──────────────────────────────────

/// فیلترهای گروه عضلانی (v7 codes)
const List<MuscleGroupFilterItem> muscleGroupFilters = [
  MuscleGroupFilterItem(code: 'chest', label: 'سینه'),
  MuscleGroupFilterItem(code: 'back', label: 'پشت'),
  MuscleGroupFilterItem(code: 'shoulder', label: 'شانه'),
  MuscleGroupFilterItem(code: 'bicep', label: 'جلو بازو'),
  MuscleGroupFilterItem(code: 'tricep', label: 'پشت بازو'),
  MuscleGroupFilterItem(code: 'leg', label: 'پا'),
  MuscleGroupFilterItem(code: 'glute', label: 'سرینی'),
  MuscleGroupFilterItem(code: 'core', label: 'شکم'),
  MuscleGroupFilterItem(code: 'cardio', label: 'هوازی'),
  MuscleGroupFilterItem(code: 'stretch', label: 'کشش'),
];

class MuscleGroupFilterItem {
  final String code;
  final String label;
  const MuscleGroupFilterItem({required this.code, required this.label});
}

/// نام فارسی گروه عضلانی (PHASE 3.5 helper)
String muscleGroupFa(String code) {
  switch (code) {
    case 'chest':
      return 'سینه';
    case 'back':
      return 'پشت';
    case 'shoulder':
      return 'شانه';
    case 'bicep':
      return 'جلو بازو';
    case 'tricep':
      return 'پشت بازو';
    case 'leg':
      return 'پا';
    case 'glute':
      return 'سرینی';
    case 'core':
      return 'شکم';
    case 'cardio':
      return 'هوازی';
    case 'stretch':
      return 'کشش';
    default:
      return code;
  }
}
