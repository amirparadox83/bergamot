import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../exercise_provider.dart';

/// صفحه تمرین فعال
///
/// شامل: کرنومتر، ورودی ست، تایمر استراحت (CustomPainter)،
/// لیست تمرینات و خلاصه نهایی
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
  // ── کرنومتر ──
  final _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  Duration _elapsed = Duration.zero;

  // ── تایمر استراحت ──
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _showRest = false;
  AnimationController? _restAnimController;
  Animation<double>? _restAnim;

  // ── ورودی‌ها ──
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _repsController = TextEditingController();
    _stopwatch.start();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final activeState = ref.read(activeWorkoutProvider);
      if (!activeState.isPaused) {
        setState(() {
          _elapsed = _stopwatch.elapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    _weightController.dispose();
    _repsController.dispose();
    _restAnimController?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // تایمر استراحت
  // ──────────────────────────────────────────────────────────────────────────

  void _startRestTimer(int totalSeconds) {
    _restRemaining = totalSeconds;
    _showRest = true;
    _restAnimController?.dispose();
    _restAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalSeconds),
    );
    _restAnim = CurvedAnimation(
      parent: _restAnimController!,
      curve: Curves.linear,
    );
    _restAnimController!.forward();

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _restRemaining--;
      });
      if (_restRemaining == 3) {
        HapticFeedback.mediumImpact();
      }
      if (_restRemaining <= 0) {
        _restTimer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _showRest = false;
        });
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _restAnimController?.stop();
    HapticFeedback.lightImpact();
    setState(() {
      _showRest = false;
    });
  }

  void _extendRest() {
    _restRemaining += 15;
    // افزایش مدت انیمیشن
    _restAnimController?.duration =
        Duration(seconds: _restRemaining + 15);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // تکمیل ست
  // ──────────────────────────────────────────────────────────────────────────

  void _completeSet() {
    final activeState = ref.read(activeWorkoutProvider);
    final exercise = activeState.currentExercise;
    if (exercise == null) return;

    HapticFeedback.mediumImpact();

    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    ref.read(activeWorkoutProvider.notifier).completeSet(
      weightKg: weight,
      reps: reps,
    );

    // بروزرسانی ورودی‌ها برای ست بعدی
    _repsController.text = exercise.reps?.toString() ?? '';

    final updated = ref.read(activeWorkoutProvider).currentExercise;
    if (updated != null && updated.isAllSetsDone) {
      // رفتن به تمرین بعدی یا اتمام
      if (activeState.currentExerciseIndex <
          activeState.exercises.length - 1) {
        _startRestTimer(updated.restSeconds);
        ref.read(activeWorkoutProvider.notifier).nextExercise();
      } else {
        _showFinishDialog();
      }
    } else {
      // شروع استراحت بین ست‌ها
      _startRestTimer(exercise.restSeconds);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // اتمام تمرین
  // ──────────────────────────────────────────────────────────────────────────

  void _showFinishDialog() {
    final activeState = ref.read(activeWorkoutProvider);

    int totalSets = 0;
    double totalVolume = 0;
    int exercisesDone = 0;
    for (final ex in activeState.exercises) {
      if (ex.completedSets.isNotEmpty) exercisesDone++;
      totalSets += ex.completedSets.length;
      for (final s in ex.completedSets) {
        if (s.weightKg != null && s.reps != null) {
          totalVolume += s.weightKg! * s.reps!;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تمرین تمام شد!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: 'مدت زمان', value: _formatStopwatch(_elapsed)),
              _SummaryRow(label: 'تعداد تمرینات', value: '$exercisesDone'),
              _SummaryRow(label: 'تعداد ست‌ها', value: '$totalSets'),
              _SummaryRow(
                label: 'حجم کل',
                value: '${totalVolume.toStringAsFixed(1)} کیلوگرم',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('بازگشت'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref
                      .read(activeWorkoutProvider.notifier)
                      .finishWorkout();
                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطا در ذخیره تمرین: $e')),
                    );
                  }
                }
              },
              child: const Text('ذخیره و خروج'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStopwatch(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final activeState = ref.watch(activeWorkoutProvider);
    final exercise = activeState.currentExercise;
    final currentSetNumber = exercise?.nextSetNumber ?? 1;
    final totalSets = exercise?.sets ?? 0;

    if (!activeState.isActive) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Text(
              'تمرین فعالی وجود ندارد',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── نوار بالا: زمان و کنترل ──
              _TopBar(
                elapsed: _elapsed,
                isPaused: activeState.isPaused,
                formatStopwatch: _formatStopwatch,
                onPause: () {
                  if (activeState.isPaused) {
                    _stopwatch.start();
                  } else {
                    _stopwatch.stop();
                  }
                  ref.read(activeWorkoutProvider.notifier).togglePause();
                },
                onFinish: () => _showFinishDialog(),
                colors: colors,
              ),

              // ── محتوای اصلی ──
              Expanded(
                child: _showRest && exercise != null
                    ? _RestTimerView(
                        exercise: exercise,
                        remaining: _restRemaining,
                        totalSeconds: exercise.restSeconds,
                        restAnim: _restAnim,
                        onSkip: _skipRest,
                        onExtend: _extendRest,
                        colors: colors,
                      )
                    : exercise != null
                        ? _ExerciseSessionView(
                            exercise: exercise,
                            currentSetNumber: currentSetNumber,
                            totalSets: totalSets,
                            weightController: _weightController,
                            repsController: _repsController,
                            onCompleteSet: _completeSet,
                            colors: colors,
                            activeState: activeState,
                            onExerciseTap: (index) {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .goToExercise(index);
                            },
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── نوار بالا ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Duration elapsed;
  final bool isPaused;
  final String Function(Duration) formatStopwatch;
  final VoidCallback onPause;
  final VoidCallback onFinish;
  final BergamotColors colors;

  const _TopBar({
    required this.elapsed,
    required this.isPaused,
    required this.formatStopwatch,
    required this.onPause,
    required this.onFinish,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BergamotSpacing.s16,
        vertical: BergamotSpacing.s12,
      ),
      color: colors.surface,
      child: Row(
        children: [
          // مکث/ادامه
          IconButton(
            onPressed: onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: BergamotSpacing.s8),
          // زمان
          Text(
            formatStopwatch(elapsed),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          // اتمام
          TextButton.icon(
            onPressed: onFinish,
            icon: Icon(Icons.stop, color: colors.error, size: 20),
            label: Text(
              'پایان',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ویو تایمر استراحت ──────────────────────────────────────────────────────

class _RestTimerView extends StatelessWidget {
  final ActiveExercise exercise;
  final int remaining;
  final int totalSeconds;
  final Animation<double>? restAnim;
  final VoidCallback onSkip;
  final VoidCallback onExtend;
  final BergamotColors colors;

  const _RestTimerView({
    required this.exercise,
    required this.remaining,
    required this.totalSeconds,
    required this.restAnim,
    required this.onSkip,
    required this.onExtend,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = remaining > 0 ? remaining / totalSeconds : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'استراحت',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),
            // دایره تایمر
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: restAnim ?? const AlwaysStoppedAnimation(0),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RestCirclePainter(
                      fraction: fraction,
                      color: colors.primary,
                      trackColor: colors.border,
                    ),
                    child: Center(
                      child: Text(
                        '${remaining}s',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remaining <= 3 ? colors.error : colors.text,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: BergamotSpacing.s32),
            // دکمه‌ها
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('رد کردن'),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                OutlinedButton(
                  onPressed: onExtend,
                  child: const Text('+۱۵ ثانیه'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── پینتر دایره تایمر استراحت ──────────────────────────────────────────────

class _RestCirclePainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _RestCirclePainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // مسیر ترک
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // مسیر پیشرفت
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * 3.141592653589793 * fraction.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RestCirclePainter old) {
    return old.fraction != fraction;
  }
}

// ─── ویو تمرین فعال ────────────────────────────────────────────────────────

class _ExerciseSessionView extends StatelessWidget {
  final ActiveExercise exercise;
  final int currentSetNumber;
  final int totalSets;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final VoidCallback onCompleteSet;
  final BergamotColors colors;
  final ActiveWorkoutState activeState;
  final ValueChanged<int> onExerciseTap;

  const _ExerciseSessionView({
    required this.exercise,
    required this.currentSetNumber,
    required this.totalSets,
    required this.weightController,
    required this.repsController,
    required this.onCompleteSet,
    required this.colors,
    required this.activeState,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: BergamotSpacing.s16,
            ),
            child: Column(
              children: [
                // ── کارت تمرین فعلی ──
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(BergamotSpacing.s24),
                    child: Column(
                      children: [
                        // شماره تمرین
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BergamotSpacing.s12,
                            vertical: BergamotSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.tagBg,
                            borderRadius: BergamotSpacing.br8,
                          ),
                          child: Text(
                            'تمرین ${activeState.currentExerciseIndex + 1} از ${activeState.exercises.length}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: colors.tagText),
                          ),
                        ),
                        const SizedBox(height: BergamotSpacing.s12),

                        // نام تمرین
                        Text(
                          exercise.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BergamotSpacing.s4),
                        Text(
                          categoryFa(exercise.category),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.textSecondary),
                        ),
                        const SizedBox(height: BergamotSpacing.s24),

                        // ست فعلی
                        Text(
                          'ست $currentSetNumber از $totalSets',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: BergamotSpacing.s16),

                        // ورودی وزن و تکرار
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: weightController,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^[\d.]*$'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'وزن (کیلوگرم)',
                                  prefixIcon: Icon(Icons.line_weight),
                                ),
                              ),
                            ),
                            const SizedBox(width: BergamotSpacing.s12),
                            Expanded(
                              child: TextField(
                                controller: repsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'تکرار',
                                  prefixIcon: Icon(Icons.repeat),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BergamotSpacing.s24),

                        // دکمه تکمیل ست
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: onCompleteSet,
                            icon: const Icon(Icons.check_circle),
                            label: const Text(
                              'تکمیل ست',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: BergamotSpacing.s24),

                // ── لیست تمرینات ──
                Text(
                  'تمرینات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: BergamotSpacing.s8),
                ...activeState.exercises.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ex = entry.value;
                  final isCurrent = idx == activeState.currentExerciseIndex;
                  final isDone = ex.isAllSetsDone;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: BergamotSpacing.s4,
                    ),
                    child: Material(
                      color: isCurrent
                          ? colors.primary.withAlpha((0.1 * 255).round())
                          : Colors.transparent,
                      borderRadius: BergamotSpacing.br12,
                      child: InkWell(
                        borderRadius: BergamotSpacing.br12,
                        onTap: () => onExerciseTap(idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BergamotSpacing.s12,
                            vertical: BergamotSpacing.s12,
                          ),
                          child: Row(
                            children: [
                              if (isDone)
                                Icon(
                                  Icons.check_circle,
                                  color: colors.success,
                                  size: 20,
                                )
                              else if (isCurrent)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.primary,
                                      width: 2,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.border,
                                  ),
                                ),
                              const SizedBox(width: BergamotSpacing.s12),
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: isDone
                                            ? colors.textSecondary
                                            : null,
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: BergamotSpacing.s8,
                                    vertical: BergamotSpacing.s4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BergamotSpacing.br8,
                                  ),
                                  child: Text(
                                    'ست ${ex.nextSetNumber}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                )
                              else
                                Text(
                                  '${ex.completedSets.length}/${ex.sets}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: BergamotSpacing.s16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ردیف خلاصه ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BergamotSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
