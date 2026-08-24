import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/bergamot_database.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../exercise_provider.dart';
import '../library/exercise_library_screen.dart';
import '../active_workout/active_workout_screen.dart';

/// صفحه سازنده جلسه تمرین
///
/// کاربر تمرینات را انتخاب، تنظیم و سپس شروع می‌کند
class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  ConsumerState<WorkoutBuilderScreen> createState() =>
      _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nameController = TextEditingController(
      text: 'تمرین ${now.year}/${now.month}/${now.day}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final builderState = ref.watch(workoutBuilderProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('ساخت تمرین'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: BergamotSpacing.s16,
                  vertical: BergamotSpacing.s8,
                ),
                children: [
                  // ── نام تمرین ──
                  TextField(
                    controller: _nameController,
                    onChanged: (v) =>
                        ref.read(workoutBuilderProvider.notifier).setName(v),
                    decoration: const InputDecoration(
                      labelText: 'نام تمرین',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: BergamotSpacing.s24),

                  // ── لیست تمرینات اضافه‌شده ──
                  if (builderState.items.isEmpty) ...[
                    const SizedBox(height: BergamotSpacing.s48),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 64,
                            color: colors.textSecondary.withAlpha(128),
                          ),
                          const SizedBox(height: BergamotSpacing.s16),
                          Text(
                            'تمرینی اضافه نشده',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: BergamotSpacing.s4),
                          Text(
                            'از دکمه زیر تمرین اضافه کنید',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    ...builderState.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _BuilderExerciseCard(
                        index: index,
                        item: item,
                        colors: colors,
                        onChanged: (updated) {
                          ref
                              .read(workoutBuilderProvider.notifier)
                              .updateItem(index, updated);
                        },
                        onRemove: () {
                          ref
                              .read(workoutBuilderProvider.notifier)
                              .removeExercise(index);
                        },
                      );
                    }),
                ],
              ),
            ),

            // ── دکمه‌های پایین ──
            Container(
              padding: const EdgeInsets.fromLTRB(
                BergamotSpacing.s16,
                BergamotSpacing.s12,
                BergamotSpacing.s16,
                BergamotSpacing.s24,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.border),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // افزودن تمرین
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<Exercise>(
                          MaterialPageRoute(
                            builder: (_) => const Directionality(
                              textDirection: TextDirection.rtl,
                              child: ExerciseLibraryScreen(
                                selectionMode: true,
                              ),
                            ),
                          ),
                        );
                        if (result != null) {
                          ref.read(workoutBuilderProvider.notifier).addExercise(
                            WorkoutBuilderItem(
                              exerciseId: result.id,
                              name: result.nameFa,
                              category: result.category,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('افزودن تمرین'),
                    ),
                    const SizedBox(height: BergamotSpacing.s8),

                    // شروع تمرین
                    FilledButton.icon(
                      onPressed: builderState.items.isEmpty
                          ? null
                          : () => _startWorkout(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('شروع'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startWorkout() async {
    final builder = ref.read(workoutBuilderProvider);
    await ref.read(activeWorkoutProvider.notifier).startWorkout(
      name: _nameController.text,
      items: builder.items,
    );
    ref.read(workoutBuilderProvider.notifier).clear();

    if (mounted) {
      Navigator.of(context).pushReplacement(
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

// ─── کارت تمرین در سازنده ───────────────────────────────────────────────────

class _BuilderExerciseCard extends StatefulWidget {
  final int index;
  final WorkoutBuilderItem item;
  final BergamotColors colors;
  final ValueChanged<WorkoutBuilderItem> onChanged;
  final VoidCallback onRemove;

  const _BuilderExerciseCard({
    required this.index,
    required this.item,
    required this.colors,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_BuilderExerciseCard> createState() => _BuilderExerciseCardState();
}

class _BuilderExerciseCardState extends State<_BuilderExerciseCard> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.item.sets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.item.reps?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.item.weightKg?.toString() ?? '',
    );
    _restController = TextEditingController(
      text: widget.item.restSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      widget.item.copyWith(
        sets: int.tryParse(_setsController.text) ?? widget.item.sets,
        reps: int.tryParse(_repsController.text),
        weightKg: double.tryParse(_weightController.text),
        restSeconds: int.tryParse(_restController.text) ?? 90,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: BergamotSpacing.s12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(BergamotSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ردیف نام و حذف
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.tagBg,
                      borderRadius: BergamotSpacing.br8,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BergamotSpacing.s8,
                      vertical: BergamotSpacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tagBg,
                      borderRadius: BergamotSpacing.br8,
                    ),
                    child: Text(
                      categoryFa(widget.item.category),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.tagText,
                      ),
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.close, color: colors.error, size: 20),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: BergamotSpacing.s12),

              // ردیف ورودی‌ها
              Row(
                children: [
                  // ست
                  Expanded(
                    child: _InputField(
                      controller: _setsController,
                      label: 'ست',
                      onChanged: _notify,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  // تکرار
                  Expanded(
                    child: _InputField(
                      controller: _repsController,
                      label: 'تکرار',
                      onChanged: _notify,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  // وزن
                  Expanded(
                    child: _InputField(
                      controller: _weightController,
                      label: 'وزن (کیلو)',
                      onChanged: _notify,
                      inputType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: BergamotSpacing.s8),
                  // استراحت
                  Expanded(
                    child: _InputField(
                      controller: _restController,
                      label: 'استراحت (ثانیه)',
                      onChanged: _notify,
                      inputType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── فیلد ورودی کوچک ─────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;
  final TextInputType inputType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      keyboardType: inputType,
      inputFormatters: inputType == const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'^[\d.]*$'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BergamotSpacing.s8,
          vertical: BergamotSpacing.s8,
        ),
      ),
    );
  }
}
