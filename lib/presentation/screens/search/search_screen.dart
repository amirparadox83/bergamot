import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/database_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'search_provider.dart';

/// صفحه جستجوی عمومی
///
/// جستجو در: غذاها، تمرینات، برنامه‌های تمرینی، عادت‌ها.
/// نتایج گروه‌بندی شده با بَج تعداد.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // فوکوس خودکار روی فیلد جستجو
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// بارگذاری جستجوهای اخیر از تنظیمات
  Future<void> _loadRecentSearches() async {
    final db = ref.read(bergamotDatabaseProvider);
    final setting = await (db.select(db.appSettings)
          ..where((t) => t.key.equals('recent_searches')))
        .getSingleOrNull();
    if (setting != null && setting.value.isNotEmpty) {
      setState(() {
        _recentSearches = setting.value.split('##').toList();
      });
    }
  }

  /// ذخیره عبارت جستجو در تنظیمات
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final db = ref.read(bergamotDatabaseProvider);
    final updated = [query, ..._recentSearches.where((s) => s != query)].take(10).toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: const Value('recent_searches'),
        value: Value(updated.join('##')),
        updatedAt: Value(now),
      ),
    );
    setState(() {
      _recentSearches = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final debouncedQuery = ref.watch(debouncedQueryProvider);
    final searchResults = ref.watch(searchProvider(debouncedQuery));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          titleSpacing: 0,
          title: _SearchField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (q) {
              ref.read(debouncedQueryProvider.notifier).update(q);
            },
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) _saveRecentSearch(q.trim());
            },
          ),
          actions: [
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  ref.read(debouncedQueryProvider.notifier).update('');
                },
              ),
          ],
        ),
        body: _buildBody(colors, debouncedQuery, searchResults),
      ),
    );
  }

  Widget _buildBody(
    BergamotColors colors,
    String debouncedQuery,
    AsyncValue<SearchResults> searchResults,
  ) {
    // بدون عبارت جستجو → جستجوهای اخیر
    if (debouncedQuery.isEmpty) {
      if (_recentSearches.isEmpty) {
        return _EmptyState(colors: colors, message: 'جستجو کنید...');
      }
      return _RecentSearchesSection(
        colors: colors,
        recentSearches: _recentSearches,
        onTap: (q) {
          _controller.text = q;
          ref.read(debouncedQueryProvider.notifier).update(q);
        },
        onClear: () async {
          final db = ref.read(bergamotDatabaseProvider);
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.into(db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion(
              key: const Value('recent_searches'),
              value: const Value(''),
              updatedAt: Value(now),
            ),
          );
          setState(() {
            _recentSearches = [];
          });
        },
      );
    }

    // عبارت جستجو وجود دارد
    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return _EmptyState(colors: colors, message: 'نتیجه‌ای یافت نشد');
        }
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s16,
            vertical: BergamotSpacing.s8,
          ),
          children: [
            if (results.foods.isNotEmpty)
              _SearchCategorySection<FoodSearchResult>(
                title: 'غذاها',
                icon: Icons.restaurant_outlined,
                count: results.foods.length,
                items: results.foods,
                colors: colors,
                itemBuilder: (item) => _FoodResultTile(
                  item: item,
                  colors: colors,
                  onTap: () {
                    _saveRecentSearch(debouncedQuery);
                    // آینده: رفتن به صفحه جزئیات غذا
                  },
                ),
              ),
            if (results.exercises.isNotEmpty)
              _SearchCategorySection<ExerciseSearchResult>(
                title: 'تمرینات',
                icon: Icons.fitness_center_outlined,
                count: results.exercises.length,
                items: results.exercises,
                colors: colors,
                itemBuilder: (item) => _ExerciseResultTile(
                  item: item,
                  colors: colors,
                  onTap: () {
                    _saveRecentSearch(debouncedQuery);
                    context.pop();
                  },
                ),
              ),
            if (results.workouts.isNotEmpty)
              _SearchCategorySection<WorkoutSearchResult>(
                title: 'برنامه‌های تمرینی',
                icon: Icons.event_note_outlined,
                count: results.workouts.length,
                items: results.workouts,
                colors: colors,
                itemBuilder: (item) => _WorkoutResultTile(
                  item: item,
                  colors: colors,
                  onTap: () {
                    _saveRecentSearch(debouncedQuery);
                    context.push('/workout-programs');
                  },
                ),
              ),
            if (results.habits.isNotEmpty)
              _SearchCategorySection<HabitSearchResult>(
                title: 'عادت‌ها',
                icon: Icons.check_circle_outline,
                count: results.habits.length,
                items: results.habits,
                colors: colors,
                itemBuilder: (item) => _HabitResultTile(
                  item: item,
                  colors: colors,
                  onTap: () {
                    _saveRecentSearch(debouncedQuery);
                    context.pop();
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(BergamotSpacing.s32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => _EmptyState(
        colors: colors,
        message: 'خطا در جستجو',
      ),
    );
  }
}

// ─── فیلد جستجو ────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'جستجو...',
          hintStyle: TextStyle(color: colors.textSecondary),
          border: InputBorder.none,
          filled: false,
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

// ─── حالت خالی ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BergamotColors colors;
  final String message;

  const _EmptyState({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_outlined,
            size: 64,
            color: colors.textSecondary.withAlpha(100),
          ),
          const SizedBox(height: BergamotSpacing.s16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── بخش جستجوهای اخیر ─────────────────────────────────────────────────────

class _RecentSearchesSection extends StatelessWidget {
  final BergamotColors colors;
  final List<String> recentSearches;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const _RecentSearchesSection({
    required this.colors,
    required this.recentSearches,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BergamotSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'جستجوهای اخیر',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                child: Text(
                  'پاک‌سازی',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BergamotSpacing.s8),
          Wrap(
            spacing: BergamotSpacing.s8,
            runSpacing: BergamotSpacing.s8,
            children: recentSearches
                .map((q) => _RecentChip(
                      label: q,
                      colors: colors,
                      onTap: () => onTap(q),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final String label;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _RecentChip({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BergamotSpacing.br20,
      child: InkWell(
        borderRadius: BergamotSpacing.br20,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s12,
            vertical: BergamotSpacing.s8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BergamotSpacing.br20,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 14, color: colors.textSecondary),
              const SizedBox(width: BergamotSpacing.s4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بخش دسته‌بندی نتایج ──────────────────────────────────────────────────

class _SearchCategorySection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final List<T> items;
  final BergamotColors colors;
  final Widget Function(T) itemBuilder;

  const _SearchCategorySection({
    required this.title,
    required this.icon,
    required this.count,
    required this.items,
    required this.colors,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── هدر دسته‌بندی با بَج تعداد ──
        Padding(
          padding: const EdgeInsets.only(
            top: BergamotSpacing.s16,
            bottom: BergamotSpacing.s8,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: BergamotSpacing.s8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: BergamotSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.tagBg,
                  borderRadius: BergamotSpacing.br20,
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.tagText,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
        // ── آیتم‌ها ──
        ...items.map(itemBuilder),
      ],
    );
  }
}

// ─── تایل نتیجه غذا ────────────────────────────────────────────────────────

class _FoodResultTile extends StatelessWidget {
  final FoodSearchResult item;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _FoodResultTile({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ResultTileBase(
      icon: Icons.restaurant,
      name: item.nameFa,
      subtitle: '${item.caloriesPerServing.toStringAsFixed(0)} کالری',
      badgeLabel: 'غذا',
      badgeColor: colors.accent,
      colors: colors,
      onTap: onTap,
    );
  }
}

// ─── تایل نتیجه تمرین ──────────────────────────────────────────────────────

class _ExerciseResultTile extends StatelessWidget {
  final ExerciseSearchResult item;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _ExerciseResultTile({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ResultTileBase(
      icon: Icons.fitness_center,
      name: item.nameFa,
      subtitle: item.muscleGroups,
      badgeLabel: 'تمرین',
      badgeColor: colors.primary,
      colors: colors,
      onTap: onTap,
    );
  }
}

// ─── تایل نتیجه برنامه تمرینی ─────────────────────────────────────────────

class _WorkoutResultTile extends StatelessWidget {
  final WorkoutSearchResult item;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _WorkoutResultTile({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ResultTileBase(
      icon: Icons.event_note,
      name: item.nameFa,
      subtitle: '${item.dayCount} روز در هفته',
      badgeLabel: 'برنامه',
      badgeColor: colors.warning,
      colors: colors,
      onTap: onTap,
    );
  }
}

// ─── تایل نتیجه عادت ────────────────────────────────────────────────────────

class _HabitResultTile extends StatelessWidget {
  final HabitSearchResult item;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _HabitResultTile({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ResultTileBase(
      icon: Icons.check_circle_outline,
      name: item.name,
      subtitle: item.frequency == 0 ? 'روزانه' : 'هفتگی',
      badgeLabel: 'عادت',
      badgeColor: colors.success,
      colors: colors,
      onTap: onTap,
    );
  }
}

// ─── تایل پایه نتیجه جستجو ─────────────────────────────────────────────────

class _ResultTileBase extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _ResultTileBase({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BergamotSpacing.s4),
      child: Material(
        color: colors.surface,
        borderRadius: BergamotSpacing.br12,
        child: InkWell(
          borderRadius: BergamotSpacing.br12,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BergamotSpacing.s12,
              vertical: BergamotSpacing.s12,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.tagBg,
                    borderRadius: BergamotSpacing.br10,
                  ),
                  child: Icon(icon, color: colors.primary, size: 18),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ── بَج دسته‌بندی ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BergamotSpacing.s8,
                    vertical: BergamotSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(25),
                    borderRadius: BergamotSpacing.br20,
                  ),
                  child: Text(
                    badgeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
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
