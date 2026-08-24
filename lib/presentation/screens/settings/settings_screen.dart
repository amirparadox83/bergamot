import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/settings/notification_settings.dart';

/// صفحه تنظیمات
///
/// شامل: ظاهر (تم تاریک)، هدف‌ها (کالری، آب، خواب)، و درباره اپلیکیشن
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _calorieTarget = 2000;
  int _waterTarget = 2500;
  int _sleepTarget = 8;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// بارگذاری اهداف از جدول app_settings
  Future<void> _loadSettings() async {
    final db = BergamotDatabase.instance;
    try {
      final cal = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('calorie_target')))
          .getSingleOrNull();
      final wat = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('water_target')))
          .getSingleOrNull();
      final slp = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('sleep_target')))
          .getSingleOrNull();

      if (mounted) {
        setState(() {
          _calorieTarget = int.tryParse(cal?.value ?? '') ?? 2000;
          _waterTarget = int.tryParse(wat?.value ?? '') ?? 2500;
          _sleepTarget = int.tryParse(slp?.value ?? '') ?? 8;
        });
      }
    } catch (_) {
      // در صورت خطا، مقادیر پیش‌فرض حفظ می‌شوند
    }
  }

  /// ذخیره یک تنظیم در جدول app_settings
  Future<void> _saveSetting(String key, String value) async {
    final db = BergamotDatabase.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await (db.select(db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing != null) {
      await (db.update(db.appSettings)..where((t) => t.key.equals(key)))
          .write(AppSettingsCompanion(value: Value(value), updatedAt: Value(now)));
    } else {
      await db.into(db.appSettings).insert(AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(now),
      ));
    }
  }

  Future<void> _editTarget({
    required String title,
    required int currentValue,
    required String unit,
    required String settingsKey,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: InputDecoration(
            suffixText: unit,
            hintText: currentValue.toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _saveSetting(settingsKey, result.toString());
      setState(() {
        switch (settingsKey) {
          case 'calorie_target':
            _calorieTarget = result;
          case 'water_target':
            _waterTarget = result;
          case 'sleep_target':
            _sleepTarget = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('تنظیمات'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── بخش ظاهر ──
              _buildSectionTitle(context, 'ظاهر'),
              const SizedBox(height: BergamotSpacing.s8),
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: colors.primary,
                  ),
                  title: const Text('حالت تاریک'),
                  value: isDarkMode,
                  activeColor: colors.primary,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ),
              const SizedBox(height: BergamotSpacing.s24),

              // ── بخش هدف‌ها ──
              _buildSectionTitle(context, 'هدف‌ها'),
              const SizedBox(height: BergamotSpacing.s8),
              _SettingsItem(
                icon: Icons.local_fire_department_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: 'هدف کالری روزانه',
                subtitle: '$_calorieTarget کیلوکالری',
                onTap: () => _editTarget(
                  title: 'هدف کالری روزانه',
                  currentValue: _calorieTarget,
                  unit: 'کیلوکالری',
                  settingsKey: 'calorie_target',
                ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              _SettingsItem(
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'هدف آب روزانه',
                subtitle: '$_waterTarget میلی‌لیتر',
                onTap: () => _editTarget(
                  title: 'هدف آب روزانه',
                  currentValue: _waterTarget,
                  unit: 'میلی‌لیتر',
                  settingsKey: 'water_target',
                ),
              ),
              const SizedBox(height: BergamotSpacing.s8),
              _SettingsItem(
                icon: Icons.bedtime_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'هدف خواب',
                subtitle: '$_sleepTarget ساعت',
                onTap: () => _editTarget(
                  title: 'هدف خواب',
                  currentValue: _sleepTarget,
                  unit: 'ساعت',
                  settingsKey: 'sleep_target',
                ),
              ),
              const SizedBox(height: BergamotSpacing.s24),

              // ── بخش یادآوری‌ها ──
              _buildSectionTitle(context, 'یادآوری‌ها'),
              const SizedBox(height: BergamotSpacing.s8),
              const NotificationSettings(),
              const SizedBox(height: BergamotSpacing.s24),

              // ── بخش درباره ──
              _buildSectionTitle(context, 'درباره'),
              const SizedBox(height: BergamotSpacing.s8),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline, color: Color(0xFF6B7280)),
                      title: Text('نسخه اپلیکیشن'),
                      // TODO: read from package_info_plus
                      subtitle: Text('۱.۰.۰+۱'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: Color(0xFF6B7280)),
                      title: const Text('حریم خصوصی'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.go('/privacy'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star_outline, color: Color(0xFF6B7280)),
                      title: const Text('امتیاز دادن به برگاموت'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () {
                        // لینک به مارکت در نسخه نهایی
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('بزودی در مارکت منتشر می‌شود')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BergamotSpacing.s48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

/// آیتم تنظیمات قابل کلیک
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha((0.12 * 255).round()),
            borderRadius: BergamotSpacing.br12,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
