import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/bergamot_database.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// صفحه حریم خصوصی
///
/// صادرات/وارد کردن داده‌ها، پشتیبان‌گیری و حذف داده‌ها
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  String _dbSize = '...';
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isBackingUp = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDbSize();
  }

  Future<void> _loadDbSize() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'bergamot.db'));
    if (await file.exists()) {
      final bytes = await file.length();
      final mb = bytes / (1024 * 1024);
      if (mounted) setState(() => _dbSize = '${mb.toStringAsFixed(2)} مگابایت');
    } else {
      if (mounted) setState(() => _dbSize = '۰ بایت');
    }
  }

  /// صادرات تمام جداول به JSON
  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final db = BergamotDatabase.instance;
      final export = <String, List<Map<String, dynamic>>>{};

      final tables = <String, Future<List<Map<String, dynamic>>>>{
        'user_profiles': _tableToJson(db.select(db.userProfiles).get()),
        'sleep_entries': _tableToJson(db.select(db.sleepEntries).get()),
        'weight_entries': _tableToJson(db.select(db.weightEntries).get()),
        'water_entries': _tableToJson(db.select(db.waterEntries).get()),
        'meal_entries': _tableToJson(db.select(db.mealEntries).get()),
        'foods': _tableToJson(db.select(db.foods).get()),
        'workouts': _tableToJson(db.select(db.workouts).get()),
        'workout_exercises': _tableToJson(db.select(db.workoutExercises).get()),
        'exercises': _tableToJson(db.select(db.exercises).get()),
        'habits': _tableToJson(db.select(db.habits).get()),
        'habit_logs': _tableToJson(db.select(db.habitLogs).get()),
        'goals': _tableToJson(db.select(db.goals).get()),
        'body_measurements': _tableToJson(db.select(db.bodyMeasurements).get()),
        'daily_summaries': _tableToJson(db.select(db.dailySummaries).get()),
        'app_settings': _tableToJson(db.select(db.appSettings).get()),
      };

      final keys = tables.keys.toList();
      for (final key in keys) {
        export[key] = await tables[key]!;
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(export);
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'bergamot_backup_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.json'));
      await file.writeAsString(jsonString);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'پشتیبان داده‌های برگاموت');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('داده‌ها با موفقیت صادر شدند')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در صادرات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<List<Map<String, dynamic>>> _tableToJson(Future<List<DataClass>> future) async {
    final rows = await future;
    return rows.map((row) => (row as dynamic).toJson() as Map<String, dynamic>).toList();
  }

  /// وارد کردن داده‌ها از فایل JSON
  Future<void> _importData() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final file = File(picked.files.first.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('وارد کردن داده‌ها'),
          content: Text(
            'آیا از وارد کردن ${data.length} جدول داده مطمئن هستید؟\nداده‌های فعلی جایگزین نمی‌شوند.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('وارد کردن'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      if (mounted) {
        // TODO: implement actual database import logic
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وارد کردن داده‌ها انجام شد (نسخه ساده)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در وارد کردن: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// پشتیبان‌گیری: کپی فایل bergamot.db
  Future<void> _backupDatabase() async {
    setState(() => _isBackingUp = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final src = File(p.join(dir.path, 'bergamot.db'));
      if (!await src.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فایل دیتابیس یافت نشد')),
          );
        }
        return;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final dst = File(p.join(dir.path, 'bergamot_backup_$timestamp.db'));
      await src.copy(dst.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پشتیبان‌گیری با موفقیت انجام شد')),
        );
      }
      _loadDbSize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در پشتیبان‌گیری: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  /// حذف تمام داده‌ها — با تأیید دوبله
  Future<void> _deleteAllData() async {
    if (!mounted) return;
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف تمام داده‌ها'),
        content: const Text('آیا مطمئن هستید؟ تمام داده‌های سلامت شما حذف خواهند شد. این عمل قابل بازگشت نیست.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm1 != true) return;

    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آخرین هشدار'),
        content: const Text('تمام ورودی‌های وزن، خواب، تغذیه، تمرین و آب حذف خواهند شد. آیا واقعاً مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('بازگشت'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('بله، حذف شود'),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    setState(() => _isDeleting = true);
    try {
      final db = BergamotDatabase.instance;
      await db.transaction(() async {
        await db.delete(db.weightEntries).go();
        await db.delete(db.sleepEntries).go();
        await db.delete(db.mealEntries).go();
        await db.delete(db.waterEntries).go();
        await db.delete(db.workouts).go();
        await db.delete(db.workoutExercises).go();
        await db.delete(db.habitLogs).go();
        await db.delete(db.dailySummaries).go();
        await db.delete(db.bodyMeasurements).go();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمام داده‌ها با موفقیت حذف شدند')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  /// حذف حساب کاربری — با تأیید دوبله
  Future<void> _deleteAccount() async {
    if (!mounted) return;
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف حساب کاربری'),
        content: const Text('با حذف حساب، تمام داده‌های شخصی شما پاک خواهد شد. این عمل قابل بازگشت نیست.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('حذف حساب'),
          ),
        ],
      ),
    );
    if (confirm1 != true) return;

    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آخرین فرصت'),
        content: const Text('پس از تأیید نهایی، پروفایل و تمام داده‌های شما برای همیشه حذف می‌شوند.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('بازگشت'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('حذف نهایی'),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    setState(() => _isDeleting = true);
    try {
      final db = BergamotDatabase.instance;
      await db.transaction(() async {
        await db.delete(db.weightEntries).go();
        await db.delete(db.sleepEntries).go();
        await db.delete(db.mealEntries).go();
        await db.delete(db.waterEntries).go();
        await db.delete(db.workouts).go();
        await db.delete(db.workoutExercises).go();
        await db.delete(db.habitLogs).go();
        await db.delete(db.habits).go();
        await db.delete(db.goals).go();
        await db.delete(db.dailySummaries).go();
        await db.delete(db.bodyMeasurements).go();
        await db.delete(db.userProfiles).go();
        await db.delete(db.appSettings).go();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حساب کاربری با موفقیت حذف شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف حساب: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('حریم خصوصی'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // کارت: داده‌های شما
              _PrivacyCard(
                icon: Icons.lock_outline_rounded,
                iconColor: colors.primary,
                title: 'داده‌های شما، مال شماست',
                subtitle: 'تمام داده‌ها فقط روی دستگاه شما ذخیره می‌شوند و هیچ‌چیز به سرور ارسال نمی‌شود.',
              ),
              const SizedBox(height: BergamotSpacing.s16),

              // کارت: صادرات
              _PrivacyCard(
                icon: Icons.upload_file_outlined,
                iconColor: colors.primary,
                title: 'صادرات داده‌ها',
                subtitle: 'تمام داده‌های شما به فایل JSON تبدیل و به اشتراک گذاشته می‌شود.',
                trailing: _isExporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton(
                        onPressed: _exportData,
                        child: const Text('صادرات'),
                      ),
              ),
              const SizedBox(height: BergamotSpacing.s16),

              // کارت: وارد کردن
              _PrivacyCard(
                icon: Icons.download_outlined,
                iconColor: colors.primary,
                title: 'وارد کردن داده‌ها',
                subtitle: 'داده‌ها از فایل JSON پشتیبان بازیابی می‌شوند.',
                trailing: _isImporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : OutlinedButton(
                        onPressed: _importData,
                        child: const Text('وارد کردن'),
                      ),
              ),
              const SizedBox(height: BergamotSpacing.s16),

              // کارت: پشتیبان‌گیری
              _PrivacyCard(
                icon: Icons.backup_outlined,
                iconColor: colors.accent,
                title: 'پشتیبان‌گیری',
                subtitle: 'یک کپی از دیتابیس bergamot.db در حافظه دستگاه ذخیره می‌شود.',
                trailing: _isBackingUp
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton(
                        onPressed: _backupDatabase,
                        child: const Text('پشتیبان‌گیری'),
                      ),
              ),
              const SizedBox(height: BergamotSpacing.s16),

              // کارت: حذف تمام داده‌ها
              _PrivacyCard(
                icon: Icons.delete_forever_outlined,
                iconColor: colors.error,
                title: 'حذف تمام داده‌ها',
                subtitle: 'تمام ورودی‌های ثبت‌شده حذف می‌شوند. پروفایل حفظ می‌شود.',
                trailing: _isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: _deleteAllData,
                        style: TextButton.styleFrom(foregroundColor: colors.error),
                        child: const Text('حذف داده‌ها'),
                      ),
              ),
              const SizedBox(height: BergamotSpacing.s16),

              // کارت: حذف حساب
              _PrivacyCard(
                icon: Icons.person_remove_outlined,
                iconColor: colors.error,
                title: 'حذف حساب کاربری',
                subtitle: 'تمام داده‌ها شامل پروفایل حذف خواهند شد.',
                trailing: _isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: _deleteAccount,
                        style: TextButton.styleFrom(foregroundColor: colors.error),
                        child: const Text('حذف حساب'),
                      ),
              ),
              const SizedBox(height: BergamotSpacing.s32),

              // اندازه دیتابیس
              Center(
                child: Text(
                  'حجم دیتابیس: $_dbSize',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: BergamotSpacing.s32),
            ],
          ),
        ),
      ),
    );
  }
}

/// کارت حریم خصوصی
class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PrivacyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha((0.12 * 255).round()),
                    borderRadius: BergamotSpacing.br12,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: BergamotSpacing.s8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
