import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../../domain/entities/bergamot_text_normalizer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../nutrition/nutrition_provider.dart';
import '../meal_builder/meal_builder_sheet.dart';

/// شیت جستجوی غذا
///
/// جستجو بر اساس نام نرمالایز شده (فارسی یا انگلیسی)، فیلتر دسته‌بندی و انتخاب غذا.
/// از دیتابیس Bergamot استفاده می‌کند که شامل داده‌های USDA + منابع ایرانی است.
class FoodSearchSheet extends ConsumerStatefulWidget {
  /// نوع وعده از پیش انتخاب‌شده (اختیاری)
  final int? preselectedMealType;

  const FoodSearchSheet({super.key, this.preselectedMealType});

  @override
  ConsumerState<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<FoodSearchSheet> {
  final _searchController = TextEditingController();
  List<Food> _results = [];
  String? _selectedCategory; // null = all categories
  List<FoodCategory> _categories = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchFoods('');
  }

  Future<void> _loadCategories() async {
    try {
      final dao = ref.read(nutritionDaoProvider);
      final cats = await dao.getAllCategories();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _categories = []);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String query) async {
    final normalized = BergamotTextNormalizer.normalize(query);
    if (normalized.isEmpty && _selectedCategory == null) {
      // بدون جستجو — ۵۰ مورد اول
      try {
        final dao = ref.read(nutritionDaoProvider);
        final foods = await dao.searchFoods('');
        if (!mounted) return;
        setState(() {
          _results = foods;
          _isSearching = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      final dao = ref.read(nutritionDaoProvider);
      List<Food> foods;

      if (normalized.isEmpty && _selectedCategory != null) {
        foods = await dao.getFoodsByCategory(_selectedCategory!);
      } else {
        foods = await dao.searchFoods(normalized);
        if (_selectedCategory != null) {
          foods = foods.where((f) => f.categoryId == _selectedCategory).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _results = foods;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchFoods(query);
      setState(() {}); // به‌روزرسانی دکمه پاک کردن
    });
  }

  void _onCategoryTap(String? code) {
    setState(() => _selectedCategory = code);
    _searchFoods(_searchController.text);
  }

  void _onFoodTap(Food food) {
    // باز کردن شیت افزودن به وعده
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MealBuilderSheet(
        food: food,
        preselectedMealType: widget.preselectedMealType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: [
          // فیلد جستجو
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BergamotSpacing.s16,
              BergamotSpacing.s4,
              BergamotSpacing.s16,
              BergamotSpacing.s12,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'جستجوی غذا (فارسی یا انگلیسی)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFoods('');
                        },
                      )
                    : null,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),

          // چیپ‌های دسته‌بندی (داینامیک از دیتابیس)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: BergamotSpacing.s16,
              ),
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: BergamotSpacing.s8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategory == null;
                  return FilterChip(
                    label: const Text('همه'),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryTap(null),
                    showCheckmark: false,
                    selectedColor: colors.primary.withAlpha((0.15 * 255).round()),
                    labelStyle: TextStyle(
                      color: isSelected ? colors.primary : colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }
                final cat = _categories[index - 1];
                final isSelected = _selectedCategory == cat.code;
                return FilterChip(
                  label: Text(cat.nameFa),
                  selected: isSelected,
                  onSelected: (_) => _onCategoryTap(cat.code),
                  showCheckmark: false,
                  selectedColor: colors.primary.withAlpha((0.15 * 255).round()),
                  labelStyle: TextStyle(
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: BergamotSpacing.s8),

          // نتایج جستجو
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _EmptyState(colors: colors)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BergamotSpacing.s16,
                        ),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: BergamotSpacing.s4),
                        itemBuilder: (context, index) {
                          final food = _results[index];
                          return _FoodSearchItem(
                            food: food,
                            onTap: () => _onFoodTap(food),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// حالت خالی — نمایش پیام مناسب وقتی هیچ نتیجه‌ای پیدا نشد
class _EmptyState extends StatelessWidget {
  final BergamotColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: colors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: BergamotSpacing.s12),
          Text(
            'غذایی یافت نشد',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BergamotSpacing.s4),
          Text(
            'می‌توانید آن را به‌صورت دستی اضافه کنید',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// آیتم نتیجه جستجوی غذا
///
/// نمایش نام، serving size، کالری per-serving و نشان بصری source/verification.
class _FoodSearchItem extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const _FoodSearchItem({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final displayName = food.nameFa?.isNotEmpty == true ? food.nameFa! : food.nameEn;
    final needsVerification = food.verificationStatus == 'NEEDS_VERIFICATION';
    // نمایش کالری per-serving اگر servingSize موجود باشد، وگرنه per-100g
    final servingText = food.servingSize != null
        ? '${food.servingSize!.toStringAsFixed(0)} ${_servingUnitFa(food.servingUnit)}'
        : 'هر ۱۰۰ گرم';
    final calValue = food.caloriesPer100g != null
        ? (food.servingSize != null && food.servingSize! > 0
            ? food.caloriesPer100g! * food.servingSize! / 100.0
            : food.caloriesPer100g!)
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BergamotSpacing.br12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BergamotSpacing.s12,
          vertical: BergamotSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BergamotSpacing.br12,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: colors.text,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (needsVerification) ...[
                        const SizedBox(width: BergamotSpacing.s4),
                        Icon(
                          Icons.help_outline,
                          size: 14,
                          color: colors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    servingText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  calValue.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'کیلوکالری',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _servingUnitFa(String unit) {
    switch (unit) {
      case 'gram':
        return 'گرم';
      case 'piece':
        return 'عدد';
      case 'spoon':
        return 'قاشق';
      case 'glass':
        return 'لیوان';
      case 'palm':
        return 'کف دست';
      case 'plate':
        return 'بشقاب';
      case 'serving':
        return 'سروینگ';
      default:
        return unit;
    }
  }
}
