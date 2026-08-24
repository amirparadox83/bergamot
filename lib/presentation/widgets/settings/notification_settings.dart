import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';
import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// ویجت تنظیمات نوتیفیکیشن
///
/// شامل یادآوری‌های: خواب، آب، تمرین، وعده غذایی
/// تمام تنظیمات در جدول AppSettings ذخیره می‌شوند
class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  BergamotNotificationService? _service;

  // ── وضعیت خواب ──
  bool _sleepEnabled = false;
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);

  // ── وضعیت آب ──
  bool _waterEnabled = false;
  int _waterInterval = 2; // ساعت

  // ── وضعیت تمرین ──
  bool _workoutEnabled = false;
  TimeOfDay _workoutTime = const TimeOfDay(hour: 18, minute: 0);

  // ── وضعیت وعده غذایی ──
  bool _mealEnabled = false;
  final Set<String> _selectedMealTypes = {
    'breakfast',
    'lunch',
    'dinner',
  };

  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final db = BergamotDatabase.instance;
    final service = BergamotNotificationService(db: db);
    setState(() => _service = service);

    // خواندن وضعیت فعلی
    final sleepStatus = await service.getSleepReminderStatus();
    final waterStatus = await service.getWaterReminderStatus();
    final workoutStatus = await service.getWorkoutReminderStatus();
    final mealStatus = await service.getMealReminderStatus();

    if (mounted) {
      setState(() {
        _sleepEnabled = sleepStatus.enabled;
        _waterEnabled = waterStatus.enabled;
        _waterInterval = waterStatus.intervalHours;
        _workoutEnabled = workoutStatus.enabled;
        _mealEnabled = mealStatus.enabled;
        _selectedMealTypes.clear();
        _selectedMealTypes.addAll(mealStatus.mealTypes);
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    if (!_isLoaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── یادآوری خواب ──
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha((0.12 * 255).round()),
                    borderRadius: BergamotSpacing.br12,
                  ),
                  child: const Icon(Icons.bedtime_outlined,
                      color: Color(0xFF6366F1), size: 22),
                ),
                title: const Text('یادآوری خواب'),
                subtitle: Text(
                  _sleepEnabled
                      ? _formatTimeOfDay(_sleepTime)
                      : 'غیرفعال',
                ),
                value: _sleepEnabled,
                activeColor: colors.primary,
                onChanged: (val) async {
                  setState(() => _sleepEnabled = val);
                  await _service?.setSleepReminder(
                    enabled: val,
                    timeStr: _timeOfDayToString(_sleepTime),
                  );
                },
              ),
              if (_sleepEnabled)
                Padding(
                  padding: const EdgeInsets.only(
                    left: BergamotSpacing.s16,
                    right: BergamotSpacing.s16,
                    bottom: BergamotSpacing.s12,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickSleepTime(context),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: const Text('تغییر ساعت'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: BergamotSpacing.s8),

        // ── یادآوری آب ──
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha((0.12 * 255).round()),
                    borderRadius: BergamotSpacing.br12,
                  ),
                  child: const Icon(Icons.water_drop_outlined,
                      color: Color(0xFF3B82F6), size: 22),
                ),
                title: const Text('یادآوری آب'),
                subtitle: Text(
                  _waterEnabled
                      ? 'هر $_waterInterval ساعت'
                      : 'غیرفعال',
                ),
                value: _waterEnabled,
                activeColor: colors.primary,
                onChanged: (val) async {
                  setState(() => _waterEnabled = val);
                  await _service?.setWaterReminder(
                    enabled: val,
                    intervalHours: _waterInterval,
                  );
                },
              ),
              if (_waterEnabled)
                Padding(
                  padding: const EdgeInsets.only(
                    left: BergamotSpacing.s16,
                    right: BergamotSpacing.s16,
                    bottom: BergamotSpacing.s12,
                  ),
                  child: _IntervalSelector(
                    currentInterval: _waterInterval,
                    onChanged: (val) async {
                      setState(() => _waterInterval = val);
                      await _service?.setWaterReminder(
                        enabled: true,
                        intervalHours: val,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: BergamotSpacing.s8),

        // ── یادآوری تمرین ──
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha((0.12 * 255).round()),
                    borderRadius: BergamotSpacing.br12,
                  ),
                  child: const Icon(Icons.fitness_center_outlined,
                      color: Color(0xFFEF4444), size: 22),
                ),
                title: const Text('یادآوری تمرین'),
                subtitle: Text(
                  _workoutEnabled
                      ? _formatTimeOfDay(_workoutTime)
                      : 'غیرفعال',
                ),
                value: _workoutEnabled,
                activeColor: colors.primary,
                onChanged: (val) async {
                  setState(() => _workoutEnabled = val);
                  await _service?.setWorkoutReminder(
                    enabled: val,
                    timeStr: _timeOfDayToString(_workoutTime),
                  );
                },
              ),
              if (_workoutEnabled)
                Padding(
                  padding: const EdgeInsets.only(
                    left: BergamotSpacing.s16,
                    right: BergamotSpacing.s16,
                    bottom: BergamotSpacing.s12,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickWorkoutTime(context),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: const Text('تغییر ساعت'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: BergamotSpacing.s8),

        // ── یادآوری وعده غذایی ──
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha((0.12 * 255).round()),
                    borderRadius: BergamotSpacing.br12,
                  ),
                  child: const Icon(Icons.restaurant_outlined,
                      color: Color(0xFFF59E0B), size: 22),
                ),
                title: const Text('یادآوری وعده غذایی'),
                subtitle: Text(
                  _mealEnabled
                      ? _selectedMealNames()
                      : 'غیرفعال',
                ),
                value: _mealEnabled,
                activeColor: colors.primary,
                onChanged: (val) async {
                  setState(() => _mealEnabled = val);
                  await _service?.setMealReminder(
                    enabled: val,
                    mealTypes: _selectedMealTypes.toList(),
                  );
                },
              ),
              if (_mealEnabled)
                Padding(
                  padding: const EdgeInsets.only(
                    left: BergamotSpacing.s16,
                    right: BergamotSpacing.s16,
                    bottom: BergamotSpacing.s12,
                  ),
                  child: _MealTypeCheckboxes(
                    selectedTypes: _selectedMealTypes,
                    onChanged: (types) async {
                      setState(() {
                        _selectedMealTypes.clear();
                        _selectedMealTypes.addAll(types);
                      });
                      await _service?.setMealReminder(
                        enabled: true,
                        mealTypes: types.toList(),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── عملیات ────────────────────────────────────────────────────────

  Future<void> _pickSleepTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime,
      helpText: 'ساعت یادآوری خواب',
    );
    if (picked != null && picked != _sleepTime) {
      setState(() => _sleepTime = picked);
      await _service?.setSleepReminder(
        enabled: true,
        timeStr: _timeOfDayToString(picked),
      );
    }
  }

  Future<void> _pickWorkoutTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _workoutTime,
      helpText: 'ساعت یادآوری تمرین',
    );
    if (picked != null && picked != _workoutTime) {
      setState(() => _workoutTime = picked);
      await _service?.setWorkoutReminder(
        enabled: true,
        timeStr: _timeOfDayToString(picked),
      );
    }
  }

  String _timeOfDayToString(TimeOfDay t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _selectedMealNames() {
    const names = {
      'breakfast': 'صبحانه',
      'lunch': 'ناهار',
      'dinner': 'شام',
      'snack': 'میان‌وعده',
    };
    return _selectedMealTypes
        .map((t) => names[t] ?? t)
        .join('، ');
  }
}

// ── انتخاب‌گر فاصله آب ═════════════════════════════════════════════

class _IntervalSelector extends StatelessWidget {
  final int currentInterval;
  final ValueChanged<int> onChanged;

  const _IntervalSelector({
    required this.currentInterval,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _IntervalChip(
          label: '۱ ساعت',
          value: 1,
          current: currentInterval,
          colors: colors,
          onTap: onChanged,
        ),
        const SizedBox(width: 8),
        _IntervalChip(
          label: '۲ ساعت',
          value: 2,
          current: currentInterval,
          colors: colors,
          onTap: onChanged,
        ),
        const SizedBox(width: 8),
        _IntervalChip(
          label: '۳ ساعت',
          value: 3,
          current: currentInterval,
          colors: colors,
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _IntervalChip extends StatelessWidget {
  final String label;
  final int value;
  final int current;
  final BergamotColors colors;
  final ValueChanged<int> onTap;

  const _IntervalChip({
    required this.label,
    required this.value,
    required this.current,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      selectedColor: colors.primary.withAlpha(30),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.textSecondary,
      ),
    );
  }
}

// ── چک‌باکس‌های نوع وعده ════════════════════════════════════════════

class _MealTypeCheckboxes extends StatelessWidget {
  final Set<String> selectedTypes;
  final ValueChanged<Set<String>> onChanged;

  const _MealTypeCheckboxes({
    required this.selectedTypes,
    required this.onChanged,
  });

  static const _mealOptions = [
    ('breakfast', 'صبحانه'),
    ('lunch', 'ناهار'),
    ('dinner', 'شام'),
    ('snack', 'میان‌وعده'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    return Column(
      children: _mealOptions.map((entry) {
        final (key, label) = entry;
        final checked = selectedTypes.contains(key);
        return CheckboxListTile(
          title: Text(label),
          value: checked,
          activeColor: colors.primary,
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (val) {
            final newSet = Set<String>.from(selectedTypes);
            if (val == true) {
              newSet.add(key);
            } else {
              newSet.remove(key);
            }
            onChanged(newSet);
          },
        );
      }).toList(),
    );
  }
}
