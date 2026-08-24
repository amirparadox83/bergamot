import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'sleep_provider.dart';
import 'sleep_history_screen.dart';

/// صفحه اصلی خواب
///
/// نمایش وضعیت خواب امروز، افزودن خواب جدید و لیست تاریخچه

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bergamotColors;
    final sleepAsync = ref.watch(todaySleepProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('خواب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SleepHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: sleepAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptySleepState(colors: colors);
          }
          return _SleepContent(entries: entries, colors: colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطا در بارگذاری: $e'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSleepSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// نمایش شیت پایین برای افزودن خواب
  void _showAddSleepSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddSleepSheet(),
    );
  }
}

/// حالت خالی — هنوز خوابی امروز ثبت نشده
class _EmptySleepState extends StatelessWidget {
  final BergamotColors colors;
  const _EmptySleepState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 80,
              color: colors.textSecondary,
            ),
            const SizedBox(height: BergamotSpacing.s24),
            Text(
              'خواب امشب ثبت نشده',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.text,
                  ),
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              'با دکمه + خواب خود را ثبت کنید',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نمایش محتوای خواب امروز
class _SleepContent extends StatelessWidget {
  final List<SleepEntry> entries;
  final BergamotColors colors;

  const _SleepContent({required this.entries, required this.colors});

  @override
  Widget build(BuildContext context) {
    // آخرین ورودی خواب
    final latest = entries.last;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BergamotSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // کارت خواب اصلی
          _SleepCard(entry: latest, colors: colors),
          const SizedBox(height: BergamotSpacing.s24),

          // تاریخچه ۷ روز اخیر
          Text(
            'تاریخچه اخیر',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                ),
          ),
          const SizedBox(height: BergamotSpacing.s12),
          ...entries.reversed.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: BergamotSpacing.s8),
              child: _SleepHistoryItem(entry: e, colors: colors),
            ),
          ),
        ],
      ),
    );
  }
}

/// کارت نمایش اطلاعات خواب
class _SleepCard extends StatelessWidget {
  final SleepEntry entry;
  final BergamotColors colors;

  const _SleepCard({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hours = entry.durationMinutes ~/ 60;
    final minutes = entry.durationMinutes % 60;
    final sleepTime = DateTime.fromMillisecondsSinceEpoch(entry.sleepTime);
    final wakeTime = DateTime.fromMillisecondsSinceEpoch(entry.wakeTime);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s24),
        child: Column(
          children: [
            // مدت خواب
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$hours',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: colors.primary,
                      ),
                ),
                const SizedBox(width: BergamotSpacing.s4),
                Text(
                  'ساعت',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Text(
                  '$minutes',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: colors.primary,
                      ),
                ),
                const SizedBox(width: BergamotSpacing.s4),
                Text(
                  'دقیقه',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s16),

            // کیفیت خواب — ستاره
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'کیفیت:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(width: BergamotSpacing.s8),
                ...List.generate(5, (i) {
                  return Icon(
                    i < entry.quality
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < entry.quality ? colors.accent : colors.border,
                    size: 24,
                  );
                }),
                const SizedBox(width: BergamotSpacing.s8),
                Text(
                  _qualityLabel(entry.quality),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s16),
            const Divider(),
            const SizedBox(height: BergamotSpacing.s16),

            // زمان خواب و بیداری
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TimeInfo(
                  icon: Icons.bedtime,
                  label: 'خواب رفتن',
                  time: _formatTime(sleepTime),
                  colors: colors,
                ),
                _TimeInfo(
                  icon: Icons.alarm,
                  label: 'بیدار شدن',
                  time: _formatTime(wakeTime),
                  colors: colors,
                ),
              ],
            ),

            // یادداشت
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: BergamotSpacing.s16),
              const Divider(),
              const SizedBox(height: BergamotSpacing.s12),
              Row(
                children: [
                  Icon(Icons.notes, size: 18, color: colors.textSecondary),
                  const SizedBox(width: BergamotSpacing.s8),
                  Expanded(
                    child: Text(
                      entry.notes!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.text,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _qualityLabel(int quality) {
    switch (quality) {
      case 1:
        return 'خیلی بد';
      case 2:
        return 'بد';
      case 3:
        return 'متوسط';
      case 4:
        return 'خوب';
      case 5:
        return 'عالی';
      default:
        return '';
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// ویجت نمایش زمان
class _TimeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final BergamotColors colors;

  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.time,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 28),
        const SizedBox(height: BergamotSpacing.s8),
        Text(
          time,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.text,
              ),
        ),
        const SizedBox(height: BergamotSpacing.s4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// آیتم تاریخچه خواب
class _SleepHistoryItem extends ConsumerWidget {
  final SleepEntry entry;
  final BergamotColors colors;

  const _SleepHistoryItem({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = entry.durationMinutes ~/ 60;
    final minutes = entry.durationMinutes % 60;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: BergamotSpacing.s24),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BergamotSpacing.br12,
        ),
        child: Icon(Icons.delete, color: colors.surface),
      ),
      onDismissed: (_) {
        ref.read(todaySleepProvider.notifier).deleteSleep(entry.id);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BergamotSpacing.s16,
            vertical: BergamotSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.bedtime_outlined,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: BergamotSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$hours ساعت و $minutes دقیقه',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: BergamotSpacing.s4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < entry.quality
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < entry.quality ? colors.accent : colors.border,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شیت پایین افزودن خواب
class _AddSleepSheet extends ConsumerStatefulWidget {
  const _AddSleepSheet();

  @override
  ConsumerState<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends ConsumerState<_AddSleepSheet> {
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeTime;
  double _quality = 3;
  final _notesController = TextEditingController();
  bool _saving = false;

  /// برچسب‌های کیفیت خواب
  static const List<String> _qualityLabels = [
    'خیلی بد',
    'بد',
    'متوسط',
    'خوب',
    'عالی',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// تبدیل [TimeOfDay] به میلی‌ثانیه Epoch برای امروز
  int _timeOfDayToEpoch(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute)
        .millisecondsSinceEpoch;
  }

  /// نمایش TimePicker
  Future<void> _pickTime(bool isSleepTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isSleepTime) {
          _sleepTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  /// ذخیره خواب
  Future<void> _save() async {
    if (_sleepTime == null || _wakeTime == null) return;

    setState(() => _saving = true);

    try {
      await ref.read(todaySleepProvider.notifier).addSleep(
        sleepTime: _timeOfDayToEpoch(_sleepTime!),
        wakeTime: _timeOfDayToEpoch(_wakeTime!),
        quality: _quality.round(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: BergamotSpacing.s16,
        right: BergamotSpacing.s16,
        top: BergamotSpacing.s8,
        bottom: BergamotSpacing.s16 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // خواب رفتن
            ListTile(
              leading: Icon(Icons.bedtime, color: colors.primary),
              title: const Text('خواب رفتن'),
              trailing: Text(
                _sleepTime != null
                    ? _sleepTime!.format(context)
                    : 'انتخاب زمان',
                style: TextStyle(color: colors.textSecondary),
              ),
              onTap: () => _pickTime(true),
              shape: RoundedRectangleBorder(
                borderRadius: BergamotSpacing.br12,
                side: BorderSide(color: colors.border),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s12),

            // بیدار شدن
            ListTile(
              leading: Icon(Icons.alarm, color: colors.primary),
              title: const Text('بیدار شدن'),
              trailing: Text(
                _wakeTime != null
                    ? _wakeTime!.format(context)
                    : 'انتخاب زمان',
                style: TextStyle(color: colors.textSecondary),
              ),
              onTap: () => _pickTime(false),
              shape: RoundedRectangleBorder(
                borderRadius: BergamotSpacing.br12,
                side: BorderSide(color: colors.border),
              ),
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // اسلایدر کیفیت
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'کیفیت خواب: ${_qualityLabels[(_quality - 1).toInt()]}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                      ),
                ),
                const SizedBox(height: BergamotSpacing.s8),
                Slider(
                  value: _quality,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => setState(() => _quality = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _qualityLabels
                      .map(
                        (l) => Text(
                          l,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // یادداشت
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                hintText: 'مثلاً: کابوس دیدم...',
              ),
              maxLines: 2,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: BergamotSpacing.s24),

            // دکمه ذخیره
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ذخیره'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
