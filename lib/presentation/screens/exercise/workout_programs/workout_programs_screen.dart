import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../../data/database/exercise_dao.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../active_workout/active_workout_screen.dart';
import '../exercise_provider.dart';

/// صفحه لیست برنامه‌های تمرینی
///
/// PHASE 3.1 (Bergamot troubleshooting round 3):
/// این صفحه از جدول `WorkoutPrograms` و `WorkoutProgramDays` دیتابیس
/// می‌خواند (نه از فایل قدیمی const Dart). ۵ برنامه و ۶۵ روز برنامه‌ریزی‌شده
/// که در v7 seed شده‌اند، در این صفحه نمایش داده می‌شوند.
class WorkoutProgramsScreen extends ConsumerStatefulWidget {
  const WorkoutProgramsScreen({super.key});

  @override
  ConsumerState<WorkoutProgramsScreen> createState() =>
      _WorkoutProgramsScreenState();
}

class _WorkoutProgramsScreenState
    extends ConsumerState<WorkoutProgramsScreen> {
  late Future<List<WorkoutProgram>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _programsFuture = _loadPrograms();
  }

  Future<List<WorkoutProgram>> _loadPrograms() async {
    final dao = ref.read(exerciseDaoProvider);
    return dao.getAllPrograms();
  }

  Future<void> _refresh() async {
    setState(() {
      _programsFuture = _loadPrograms();
    });
    await _programsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('برنامه‌های تمرینی'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.pop(),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<WorkoutProgram>>(
            future: _programsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BergamotSpacing.s16),
                    child: Text(
                      'خطا در بارگذاری برنامه‌ها: ${snapshot.error}',
                      style: TextStyle(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final programs = snapshot.data ?? [];
              if (programs.isEmpty) {
                return _buildEmptyState(colors, context);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(BergamotSpacing.s16),
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final program = programs[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < programs.length - 1
                          ? BergamotSpacing.s12
                          : 0,
                    ),
                    child: _ProgramCard(
                      program: program,
                      colors: colors,
                      onTap: () => _showProgramDetail(context, program),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Empty state — وقتی هیچ برنامه‌ای موجود نیست
  Widget _buildEmptyState(BergamotColors colors, BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: colors.textSecondary.withAlpha(128),
              ),
              const SizedBox(height: BergamotSpacing.s12),
              Text(
                'برنامه‌ای موجود نیست',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: BergamotSpacing.s4),
              Text(
                'برای بارگذاری مجدد، صفحه را پایین بکشید',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// نمایش جزئیات برنامه
  void _showProgramDetail(BuildContext context, WorkoutProgram program) {
    final colors = context.bergamotColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ProgramDetailSheet(
          program: program,
          colors: colors,
          dao: ref.read(exerciseDaoProvider),
          onStart: () {
            Navigator.of(context).pop();
            _startProgram(context, ref, program);
          },
        ),
      ),
    );
  }

  /// شروع برنامه — به صفحه Active Workout می‌رود
  ///
  /// PHASE 3.4: از adapter `startWorkoutFromTemplate` استفاده می‌کند.
  /// این متد یک WorkoutTemplateExercise (v7) را به WorkoutBuilderItem
  /// (مدلی که Active Workout Screen انتظار دارد) تبدیل می‌کند.
  Future<void> _startProgram(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
  ) async {
    // Get the first non-rest day's template to start with
    final dao = ref.read(exerciseDaoProvider);
    final days = await dao.getProgramDays(program.id);
    final firstWorkoutDay = days
        .where((d) => !d.isRestDay && d.templateId != null)
        .firstOrNull;

    if (firstWorkoutDay?.templateId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'برنامه «${program.nameFa}» هیچ روز تمرینی‌ای ندارد',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final templateId = firstWorkoutDay!.templateId!;
    final template = await dao.getTemplateById(templateId);
    final templateName = template?.nameFa ?? program.nameFa;

    // Use the adapter: convert WorkoutTemplateExercise → WorkoutBuilderItem
    // and start the workout via the existing Active Workout screen.
    await ref
        .read(activeWorkoutProvider.notifier)
        .startWorkoutFromTemplate(
          templateId: templateId,
          templateName: templateName,
        );

    if (context.mounted) {
      // Navigate to Active Workout screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Directionality(
            textDirection: TextDirection.rtl,
            child: ActiveWorkoutScreen(),
          ),
        ),
      );
    }
  }
}

// ─── کارت برنامه تمرینی ─────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BergamotSpacing.br16,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BergamotSpacing.br16,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ردیف اول: نام و ستاره‌ها ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      program.nameFa,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  _DifficultyStars(
                    difficulty: program.difficulty,
                    colors: colors,
                  ),
                ],
              ),
              if (program.descriptionFa != null &&
                  program.descriptionFa!.isNotEmpty) ...[
                const SizedBox(height: BergamotSpacing.s4),
                Text(
                  program.descriptionFa!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: BergamotSpacing.s12),

              // ── ردیف پایین: تعداد روز و هدف ──
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: BergamotSpacing.s4),
                  Text(
                    '${program.dayCount} روز',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: BergamotSpacing.s16),
                  if (program.goalCode != null) ...[
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: BergamotSpacing.s4),
                    Text(
                      _goalFa(program.goalCode!),
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.chevron_left,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _goalFa(String code) {
    switch (code) {
      case 'weight_loss':
        return 'کاهش وزن';
      case 'muscle_gain':
        return 'افزایش عضله';
      case 'strength':
        return 'قدرت';
      case 'endurance':
        return 'استقامت';
      case 'mobility':
        return 'انعطاف‌پذیری';
      default:
        return code;
    }
  }
}

// ─── ستاره‌های دشواری ──────────────────────────────────────────────────────

class _DifficultyStars extends StatelessWidget {
  final int difficulty;
  final BergamotColors colors;

  const _DifficultyStars({
    required this.difficulty,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < difficulty;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: filled
              ? colors.accent
              : colors.textSecondary.withAlpha(100),
        );
      }),
    );
  }
}

// ─── شیت جزئیات برنامه ─────────────────────────────────────────────────────

class _ProgramDetailSheet extends StatefulWidget {
  final WorkoutProgram program;
  final BergamotColors colors;
  final ExerciseDao dao;
  final VoidCallback onStart;

  const _ProgramDetailSheet({
    required this.program,
    required this.colors,
    required this.dao,
    required this.onStart,
  });

  @override
  State<_ProgramDetailSheet> createState() => _ProgramDetailSheetState();
}

class _ProgramDetailSheetState extends State<_ProgramDetailSheet> {
  late Future<List<WorkoutProgramDay>> _daysFuture;
  // Cache of template exercises per templateId (loaded lazily)
  final Map<int, List<({WorkoutTemplateExercise item, Exercise exercise})>>
      _templateExercisesCache = {};

  @override
  void initState() {
    super.initState();
    _daysFuture = widget.dao.getProgramDays(widget.program.id);
  }

  Future<List<({WorkoutTemplateExercise item, Exercise exercise})>?>
      _loadTemplateExercises(int? templateId) async {
    if (templateId == null) return null;
    if (_templateExercisesCache.containsKey(templateId)) {
      return _templateExercisesCache[templateId];
    }
    final items = await widget.dao.getTemplateExercises(templateId);
    _templateExercisesCache[templateId] = items;
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── هندل کشیدن ──
            Padding(
              padding: const EdgeInsets.only(top: BergamotSpacing.s12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── هدر ──
            Padding(
              padding: const EdgeInsets.all(BergamotSpacing.s16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.program.nameFa,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (widget.program.descriptionFa != null &&
                            widget.program.descriptionFa!.isNotEmpty) ...[
                          const SizedBox(height: BergamotSpacing.s4),
                          Text(
                            widget.program.descriptionFa!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: widget.colors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _DifficultyStars(
                    difficulty: widget.program.difficulty,
                    colors: widget.colors,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── لیست روزها ──
            Expanded(
              child: FutureBuilder<List<WorkoutProgramDay>>(
                future: _daysFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'خطا: ${snapshot.error}',
                        style: TextStyle(color: widget.colors.error),
                      ),
                    );
                  }
                  final days = snapshot.data ?? [];
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: BergamotSpacing.s16,
                      vertical: BergamotSpacing.s8,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      if (day.isRestDay) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: BergamotSpacing.s8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bedtime_outlined,
                                size: 18,
                                color: widget.colors.textSecondary,
                              ),
                              const SizedBox(width: BergamotSpacing.s8),
                              Text(
                                'روز ${day.dayNumber} — استراحت',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: widget.colors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      }
                      return _DayCard(
                        day: day,
                        colors: widget.colors,
                        loadExercises: _loadTemplateExercises,
                      );
                    },
                  );
                },
              ),
            ),

            // ── دکمه شروع برنامه ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BergamotSpacing.s16,
                BergamotSpacing.s8,
                BergamotSpacing.s16,
                BergamotSpacing.s32,
              ),
              child: SizedBox(
                width: double.infinity,
                height: BergamotSpacing.touchTargetMin,
                child: ElevatedButton(
                  onPressed: widget.onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colors.primary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BergamotSpacing.br12,
                    ),
                  ),
                  child: Text(
                    'شروع برنامه',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── کارت روز تمرینی ───────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final WorkoutProgramDay day;
  final BergamotColors colors;
  final Future<List<({WorkoutTemplateExercise item, Exercise exercise})>?>
      Function(int?) loadExercises;

  const _DayCard({
    required this.day,
    required this.colors,
    required this.loadExercises,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
      child: Container(
        padding: const EdgeInsets.all(BergamotSpacing.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BergamotSpacing.br12,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── نام روز ──
            Text(
              day.nameFa,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s8),

            // ── لیست تمرین‌ها (load lazily از template) ──
            FutureBuilder<
                List<({WorkoutTemplateExercise item, Exercise exercise})>?>(
              future: loadExercises(day.templateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: BergamotSpacing.s8),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData ||
                    snapshot.data == null || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: BergamotSpacing.s4),
                    child: Text(
                      '(بدون تمرین تعریف‌شده)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  );
                }
                final exercises = snapshot.data!;
                return Column(
                  children: exercises.map((row) {
                    final item = row.item;
                    final ex = row.exercise;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: BergamotSpacing.s4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: BergamotSpacing.s8),
                          Expanded(
                            child: Text(
                              ex.nameFa,
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (item.isTimed && item.durationSeconds != null)
                            Text(
                              '${item.durationSeconds}ث',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                            )
                          else
                            Text(
                              '${item.sets}×${item.reps ?? '-'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                            ),
                          const SizedBox(width: BergamotSpacing.s8),
                          Text(
                            '${item.restSeconds}ث استراحت',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
