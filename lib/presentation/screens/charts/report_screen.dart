import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_provider.dart';
import '../../../domain/services/report_data.dart';
import '../../../domain/services/report_generator.dart';
import '../../../domain/services/pdf_report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// صفحه گزارش سلامت
///
/// امکان تولید و مشاهده گزارش هفتگی/ماهانه و اشتراک‌گذاری PDF
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isWeekly = true;
  bool _isLoading = false;
  ReportData? _reportData;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colors = context.bergamotColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('گزارش سلامت'),
          actions: [
            if (_reportData != null)
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'اشتراک‌گذاری PDF',
                onPressed: _sharePdf,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(BergamotSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── انتخاب دوره ──
              _buildPeriodSelector(colors),
              const SizedBox(height: BergamotSpacing.s16),

              // ── دکمه تولید گزارش ──
              _buildGenerateButton(colors),
              const SizedBox(height: BergamotSpacing.s24),

              // ── خطا ──
              if (_error != null)
                _buildErrorCard(colors),

              // ── محتوای گزارش ──
              if (_reportData != null) ...[
                _buildReportContent(colors),
              ],

              // ── لودینگ ──
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// انتخاب‌گر دوره هفتگی/ماهانه
  Widget _buildPeriodSelector(BergamotColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BergamotSpacing.br12,
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              label: 'هفتگی',
              isSelected: _isWeekly,
              colors: colors,
              onTap: () => setState(() => _isWeekly = true),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              label: 'ماهانه',
              isSelected: !_isWeekly,
              colors: colors,
              onTap: () => setState(() => _isWeekly = false),
            ),
          ),
        ],
      ),
    );
  }

  /// دکمه تولید گزارش
  Widget _buildGenerateButton(BergamotColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateReport,
        icon: const Icon(Icons.assessment_outlined),
        label: const Text('تولید گزارش'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: BergamotSpacing.s16),
          shape: const RoundedRectangleBorder(
            borderRadius: BergamotSpacing.br12,
          ),
        ),
      ),
    );
  }

  /// کارت خطا
  Widget _buildErrorCard(BergamotColors colors) {
    return Card(
      color: colors.error.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: BergamotSpacing.s12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// محتوای گزارش
  Widget _buildReportContent(BergamotColors colors) {
    final data = _reportData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان دوره
        Card(
          color: colors.primary,
          child: Padding(
            padding: const EdgeInsets.all(BergamotSpacing.s16),
            child: Column(
              children: [
                Text(
                  'برگاموت — گزارش سلامت',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: BergamotSpacing.s8),
                Text(
                  data.periodTitle,
                  style: TextStyle(color: Colors.white.withAlpha(200)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BergamotSpacing.s16),

        // امتیاز
        _buildScoreSection(colors, data),
        const SizedBox(height: BergamotSpacing.s16),

        // بخش‌ها
        if (data.sleepStats != null) ...[
          _buildSleepSection(colors, data.sleepStats!),
          const SizedBox(height: BergamotSpacing.s12),
        ],
        if (data.nutritionStats != null) ...[
          _buildNutritionSection(colors, data.nutritionStats!),
          const SizedBox(height: BergamotSpacing.s12),
        ],
        if (data.workoutStats != null) ...[
          _buildWorkoutSection(colors, data.workoutStats!),
          const SizedBox(height: BergamotSpacing.s12),
        ],
        if (data.hydrationStats != null) ...[
          _buildHydrationSection(colors, data.hydrationStats!),
          const SizedBox(height: BergamotSpacing.s12),
        ],
        if (data.weightChange != null) ...[
          _buildWeightSection(colors, data.weightChange!),
          const SizedBox(height: BergamotSpacing.s12),
        ],

        // توصیه‌ها
        _buildRecommendationsSection(colors, data.recommendations),
        const SizedBox(height: BergamotSpacing.s12),

        // بزرگ‌ترین موفقیت هفته
        if (data.biggestWin != null)
          _buildBiggestWinCard(colors, data.biggestWin!),
        if (data.biggestWin != null)
          const SizedBox(height: BergamotSpacing.s12),

        // تمرکز هفته آینده
        if (data.nextWeekFocus != null)
          _buildNextWeekFocusCard(colors, data.nextWeekFocus!),
        if (data.nextWeekFocus != null)
          const SizedBox(height: BergamotSpacing.s12),

        // اگر داده‌ی کافی برای مقایسه نیست
        if (data.biggestWin == null && data.nextWeekFocus == null) ...[
          _buildNoComparisonCard(colors),
          const SizedBox(height: BergamotSpacing.s12),
        ],

        // دکمه اشتراک PDF
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('اشتراک‌گذاری فایل PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(vertical: BergamotSpacing.s16),
              shape: const RoundedRectangleBorder(
                borderRadius: BergamotSpacing.br12,
              ),
            ),
          ),
        ),
        const SizedBox(height: BergamotSpacing.s48),
      ],
    );
  }

  /// بخش امتیاز
  Widget _buildScoreSection(BergamotColors colors, ReportData data) {
    final score = data.overallScore;
    final scoreColor =
        score >= 80 ? colors.success : score >= 50 ? colors.warning : colors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          children: [
            Text(
              'امتیاز سبک زندگی',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: BergamotSpacing.s16),
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              'از ۱۰۰',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// بخش خواب
  Widget _buildSleepSection(BergamotColors colors, SleepStats stats) {
    return _ReportCard(
      title: 'خواب',
      icon: Icons.bedtime_outlined,
      iconColor: const Color(0xFF6366F1),
      colors: colors,
      children: [
        _StatRow(label: 'میانگین مدت', value: _fmtMin(stats.avgDurationMinutes), colors: colors),
        _StatRow(label: 'میانگین کیفیت', value: '${stats.avgQuality.toStringAsFixed(1)} از ۵', colors: colors),
        if (stats.bestDuration != null)
          _StatRow(label: 'بهترین شب', value: _fmtMin(stats.bestDuration!.toDouble()), colors: colors),
        if (stats.worstDuration != null)
          _StatRow(label: 'بدترین شب', value: _fmtMin(stats.worstDuration!.toDouble()), colors: colors),
      ],
    );
  }

  /// بخش تغذیه
  Widget _buildNutritionSection(BergamotColors colors, NutritionStats stats) {
    return _ReportCard(
      title: 'تغذیه',
      icon: Icons.restaurant_outlined,
      iconColor: const Color(0xFFF59E0B),
      colors: colors,
      children: [
        _StatRow(label: 'میانگین کالری', value: '${stats.avgCalories.toStringAsFixed(0)} کیلوکالری', colors: colors),
        _StatRow(label: 'پروتئین', value: '${stats.avgProtein.toStringAsFixed(1)} گرم', colors: colors),
        _StatRow(label: 'چربی', value: '${stats.avgFat.toStringAsFixed(1)} گرم', colors: colors),
        _StatRow(label: 'کربوهیدرات', value: '${stats.avgCarb.toStringAsFixed(1)} گرم', colors: colors),
        _StatRow(label: 'روزهای در محدوده هدف', value: '${stats.daysOnTarget} روز', colors: colors),
      ],
    );
  }

  /// بخش تمرین
  Widget _buildWorkoutSection(BergamotColors colors, WorkoutStats stats) {
    return _ReportCard(
      title: 'تمرین',
      icon: Icons.fitness_center_outlined,
      iconColor: const Color(0xFFEF4444),
      colors: colors,
      children: [
        _StatRow(label: 'تعداد تمرینات', value: '${stats.count} جلسه', colors: colors),
        _StatRow(label: 'مجموع حجم', value: '${stats.totalVolume.toStringAsFixed(0)} کیلوگرم', colors: colors),
        _StatRow(label: 'مجموع مدت', value: _fmtMin(stats.totalDurationMinutes.toDouble()), colors: colors),
      ],
    );
  }

  /// بخش آب
  Widget _buildHydrationSection(BergamotColors colors, HydrationStats stats) {
    return _ReportCard(
      title: 'هیدراتاسیون',
      icon: Icons.water_drop_outlined,
      iconColor: const Color(0xFF3B82F6),
      colors: colors,
      children: [
        _StatRow(label: 'میانگین آب', value: '${stats.avgMl.toStringAsFixed(0)} میلی‌لیتر', colors: colors),
        _StatRow(label: 'روزهای رسیدن به هدف', value: '${stats.daysOnTarget} روز', colors: colors),
      ],
    );
  }

  /// بخش وزن
  Widget _buildWeightSection(BergamotColors colors, WeightChange wc) {
    final diffText = wc.diffKg > 0
        ? '+${wc.diffKg.abs().toStringAsFixed(1)} کیلوگرم'
        : wc.diffKg < 0
            ? '-${wc.diffKg.abs().toStringAsFixed(1)} کیلوگرم'
            : 'بدون تغییر';
    final diffColor = wc.diffKg > 0
        ? colors.warning
        : wc.diffKg < 0
            ? colors.success
            : colors.textSecondary;

    return _ReportCard(
      title: 'وزن',
      icon: Icons.monitor_weight_outlined,
      iconColor: const Color(0xFF10B981),
      colors: colors,
      children: [
        _StatRow(label: 'وزن شروع', value: '${wc.startWeight.toStringAsFixed(1)} کیلوگرم', colors: colors),
        _StatRow(label: 'وزن پایان', value: '${wc.endWeight.toStringAsFixed(1)} کیلوگرم', colors: colors),
        _StatRow(label: 'تغییر', value: diffText, colors: colors, valueColor: diffColor),
      ],
    );
  }

  /// بخش توصیه‌ها
  Widget _buildRecommendationsSection(
      BergamotColors colors, List<String> recommendations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: colors.accent, size: 22),
                const SizedBox(width: BergamotSpacing.s8),
                Text(
                  'توصیه‌ها',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s12),
            ...recommendations.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(r, style: TextStyle(color: colors.text, fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// بخش بزرگ‌ترین موفقیت هفته
  Widget _buildBiggestWinCard(BergamotColors colors, String winText) {
    return Card(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    borderRadius: BergamotSpacing.br8,
                  ),
                  child: const Icon(Icons.emoji_events_outlined,
                      color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Text(
                  'بزرگ‌ترین موفقیت هفته',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s12),
            Text(
              winText,
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بخش تمرکز هفته آینده
  Widget _buildNextWeekFocusCard(BergamotColors colors, String focusText) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(30),
                    borderRadius: BergamotSpacing.br8,
                  ),
                  child: const Icon(Icons.my_location_outlined,
                      color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Text(
                  'تمرکز هفته آینده',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s12),
            Text(
              focusText,
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// کارت عدم داده‌ی کافی برای مقایسه
  Widget _buildNoComparisonCard(BergamotColors colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BergamotSpacing.s16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.textSecondary),
            const SizedBox(width: BergamotSpacing.s12),
            Expanded(
              child: Text(
                'اطلاعات کافی برای مقایسه با هفته قبل وجود ندارد',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── عملیات ────────────────────────────────────────────────────────

  /// تولید گزارش
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _reportData = null;
    });
    try {
      final db = ref.read(bergamotDatabaseProvider);
      final generator = ReportGenerator(db);
      final data = _isWeekly
          ? await generator.generateWeeklyReport()
          : await generator.generateMonthlyReport();
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطا در تولید گزارش: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// اشتراک‌گذاری PDF
  Future<void> _sharePdf() async {
    if (_reportData == null) return;
    try {
      final bytes = await PdfReportService.generateHealthPDF(_reportData!);
      final periodLabel = _isWeekly ? 'هفتگی' : 'ماهانه';
      await PdfReportService.sharePdf(
          bytes, 'گزارش_سلامت_برگاموت_$periodLabel.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در اشتراک‌گذاری: $e')),
        );
      }
    }
  }

  /// فرمت دقیقه به ساعت و دقیقه
  String _fmtMin(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) return '$m دقیقه';
    return '$h ساعت و $m دقیقه';
  }
}

// ── ویجت‌های کمکی ═══════════════════════════════════════════════════

/// دکمه انتخاب دوره
class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final BergamotColors colors;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colors.primary : Colors.transparent,
      borderRadius: BergamotSpacing.br8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BergamotSpacing.br8,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: BergamotSpacing.s12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : colors.text,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// کارت بخش گزارش
class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final BergamotColors colors;
  final List<Widget> children;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.colors,
    required this.children,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    borderRadius: BergamotSpacing.br8,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: BergamotSpacing.s12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: BergamotSpacing.s12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// ردیف آمار
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final BergamotColors colors;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? colors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
