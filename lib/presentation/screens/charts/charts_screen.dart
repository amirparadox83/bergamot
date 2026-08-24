import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/database/exercise_dao.dart';
import '../../../data/database/nutrition_dao.dart';
import '../../../data/database/sleep_dao.dart';
import '../../../data/database/weight_dao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// صفحه پیشرفت و نمودارها
///
/// شامل ۴ تب: وزن، خواب، تغذیه، ورزش
/// هر تب نمودار مربوطه را با داده واقعی دیتابیس نشان می‌دهد
class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedPeriod = 30; // ۷، ۳۰، ۹۰

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('پیشرفت'),
        ),
        body: Column(
          children: [
            // انتخاب دوره
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BergamotSpacing.s16,
                vertical: BergamotSpacing.s8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodChip('۷ روز', 7),
                  const SizedBox(width: BergamotSpacing.s8),
                  _buildPeriodChip('۳۰ روز', 30),
                  const SizedBox(width: BergamotSpacing.s8),
                  _buildPeriodChip('۹۰ روز', 90),
                ],
              ),
            ),
            // تب‌بار
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: const [
                Tab(text: 'وزن'),
                Tab(text: 'خواب'),
                Tab(text: 'تغذیه'),
                Tab(text: 'ورزش'),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s8),
            // محتوای تب‌ها
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _WeightChartTab(days: _selectedPeriod),
                  _SleepChartTab(days: _selectedPeriod),
                  _NutritionChartTab(days: _selectedPeriod),
                  _ExerciseChartTab(days: _selectedPeriod),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, int days) {
    final isSelected = _selectedPeriod == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedPeriod = days),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تب نمودار وزن — LineChart
// ═══════════════════════════════════════════════════════════════════════════

class _WeightChartTab extends ConsumerWidget {
  final int days;
  const _WeightChartTab({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bergamotDatabaseProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    return FutureBuilder<List<WeightEntry>>(
      future: WeightDao(db).getWeightByDateRange(start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) return _buildEmptyState();
        return _WeightLineChart(entries: data);
      },
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    if (entries.isEmpty) return _buildEmptyState();

    final weights = entries.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final minY = (minW - 1).clamp(0.0, double.infinity);
    final maxY = maxW + 1;

    final spots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].weightKg));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s8,
      ),
      child: SizedBox(
        height: 280,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: colors.border,
                strokeWidth: 0.5,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: entries.length <= 14,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final d = DateTime.fromMillisecondsSinceEpoch(
                        entries[idx].date);
                    return SideTitleWidget(
                      axisSide: AxisSide.bottom,
                      child: Text(
                        '${d.month}/${d.day}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colors.textSecondary),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: colors.primary,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: colors.primary,
                      strokeWidth: 2,
                      strokeColor: colors.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primary.withAlpha((0.25 * 255).round()),
                      colors.primary.withAlpha((0.02 * 255).round()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تب نمودار خواب — BarChart
// ═══════════════════════════════════════════════════════════════════════════

class _SleepChartTab extends ConsumerWidget {
  final int days;
  const _SleepChartTab({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bergamotDatabaseProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    return FutureBuilder<List<SleepEntry>>(
      future: SleepDao(db).getSleepByDateRange(start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) return _buildEmptyState();
        return _SleepBarChart(entries: data);
      },
    );
  }
}

class _SleepBarChart extends StatelessWidget {
  final List<SleepEntry> entries;
  const _SleepBarChart({required this.entries});

  Color _qualityColor(int quality) => switch (quality) {
        1 => const Color(0xFFEF4444),
        2 => const Color(0xFFF97316),
        3 => const Color(0xFFEAB308),
        4 => const Color(0xFF84CC16),
        5 => const Color(0xFF22C55E),
        _ => const Color(0xFF9CA3AF),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    if (entries.isEmpty) return _buildEmptyState();

    const maxY = 12.0;

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      final hours = entries[i].durationMinutes / 60.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: _qualityColor(entries[i].quality),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              width: 20,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s8,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    if (value == 8) {
                      return FlLine(
                        color:
                            colors.primary.withAlpha((0.6 * 255).round()),
                        strokeWidth: 1.5,
                        dashArray: [5, 3],
                      );
                    }
                    return FlLine(
                      color: colors.border,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: entries.length <= 14,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final d = DateTime.fromMillisecondsSinceEpoch(
                            entries[idx].date);
                        return SideTitleWidget(
                          axisSide: AxisSide.bottom,
                          child: Text(
                            '${d.month}/${d.day}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: BergamotSpacing.s8),
          // راهنمای کیفیت
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFFEF4444), 'خیلی بد'),
              const SizedBox(width: BergamotSpacing.s8),
              _legendDot(const Color(0xFFF97316), 'بد'),
              const SizedBox(width: BergamotSpacing.s8),
              _legendDot(const Color(0xFFEAB308), 'متوسط'),
              const SizedBox(width: BergamotSpacing.s8),
              _legendDot(const Color(0xFF84CC16), 'خوب'),
              const SizedBox(width: BergamotSpacing.s8),
              _legendDot(const Color(0xFF22C55E), 'عالی'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تب نمودار تغذیه — BarChart (پروتئین/چربی/کربوهیدرات)
// ═══════════════════════════════════════════════════════════════════════════

class _NutritionChartTab extends ConsumerWidget {
  final int days;
  const _NutritionChartTab({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bergamotDatabaseProvider);
    final effectiveDays = days > 30 ? 30 : days;

    return FutureBuilder<
        List<({int date, double protein, double fat, double carb})>>(
      future: _loadDailyMacros(NutritionDao(db), effectiveDays),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) return _buildEmptyState();
        return _NutritionBarChart(data: data);
      },
    );
  }

  Future<List<({int date, double protein, double fat, double carb})>>
      _loadDailyMacros(NutritionDao dao, int days) async {
    final now = DateTime.now();
    final results =
        <({int date, double protein, double fat, double carb})>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dateMs = day.millisecondsSinceEpoch;
      final macros = await dao.getDailyMacros(dateMs);
      if (macros.protein > 0 || macros.fat > 0 || macros.carb > 0) {
        results.add((
          date: dateMs,
          protein: macros.protein,
          fat: macros.fat,
          carb: macros.carb,
        ));
      }
    }
    return results;
  }
}

class _NutritionBarChart extends StatelessWidget {
  final List<({int date, double protein, double fat, double carb})> data;
  const _NutritionBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    if (data.isEmpty) return _buildEmptyState();

    double maxVal = 0;
    for (final d in data) {
      final total = d.protein + d.fat + d.carb;
      if (total > maxVal) maxVal = total;
    }
    maxVal = (maxVal * 1.1).ceilToDouble();

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i].protein,
              color: const Color(0xFF3B82F6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
              width: 8,
            ),
            BarChartRodData(
              toY: data[i].fat,
              color: const Color(0xFFF59E0B),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
              width: 8,
            ),
            BarChartRodData(
              toY: data[i].carb,
              color: const Color(0xFF8B5CF6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
              width: 8,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s8,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: maxVal,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: data.length <= 14,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final d = DateTime.fromMillisecondsSinceEpoch(
                            data[idx].date);
                        return SideTitleWidget(
                          axisSide: AxisSide.bottom,
                          child: Text(
                            '${d.month}/${d.day}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: BergamotSpacing.s8),
          // راهنما
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF3B82F6), 'پروتئین (g)'),
              const SizedBox(width: BergamotSpacing.s12),
              _legendDot(const Color(0xFFF59E0B), 'چربی (g)'),
              const SizedBox(width: BergamotSpacing.s12),
              _legendDot(const Color(0xFF8B5CF6), 'کربوهیدرات (g)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// تب نمودار ورزش — BarChart (حجم تمرین: ست × تکرار × وزن)
// ═══════════════════════════════════════════════════════════════════════════

class _ExerciseChartTab extends ConsumerWidget {
  final int days;
  const _ExerciseChartTab({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bergamotDatabaseProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    return FutureBuilder<List<Workout>>(
      future: ExerciseDao(db).getWorkoutsByDateRange(start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final workouts =
            (snapshot.data ?? []).where((w) => w.isCompleted).toList();
        if (workouts.isEmpty) return _buildEmptyState();
        return _ExerciseVolumeChart(db: db, workouts: workouts);
      },
    );
  }
}

class _ExerciseVolumeChart extends StatelessWidget {
  final BergamotDatabase db;
  final List<Workout> workouts;
  const _ExerciseVolumeChart(
      {required this.db, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return FutureBuilder<
        List<({String name, double volume})>>(
      future: _loadVolumes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final volumes = snapshot.data ?? [];
        if (volumes.isEmpty) return _buildEmptyState();

        double maxVol = 0;
        for (final v in volumes) {
          if (v.volume > maxVol) maxVol = v.volume;
        }
        maxVol = (maxVol * 1.15).ceilToDouble();

        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < volumes.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: volumes[i].volume,
                  color: colors.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  width: 24,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s16,
            vertical: BergamotSpacing.s8,
          ),
          child: SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: maxVol,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= volumes.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: AxisSide.bottom,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              volumes[idx].name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: colors.textSecondary),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<({String name, double volume})>> _loadVolumes() async {
    final result = <({String name, double volume})>[];
    for (final workout in workouts) {
      final exercises = await (db.select(db.workoutExercises)
            ..where((t) => t.workoutId.equals(workout.id)))
          .get();
      double totalVolume = 0;
      for (final ex in exercises) {
        if (ex.isCompleted && ex.reps != null && ex.weightKg != null) {
          totalVolume += ex.sets * ex.reps! * ex.weightKg!;
        }
      }
      final d = DateTime.fromMillisecondsSinceEpoch(workout.date);
      result.add((
        name: '${d.month}/${d.day}',
        volume: totalVolume,
      ));
    }
    return result.reversed.toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// وضعیت خالی
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildEmptyState() {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bar_chart_rounded,
            size: 48, color: Color(0xFF9CA3AF)),
        SizedBox(height: BergamotSpacing.s12),
        Text(
          'داده‌ای برای نمایش وجود ندارد',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
      ],
    ),
  );
}
