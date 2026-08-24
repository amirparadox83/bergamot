import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'report_data.dart';

/// سرویس تولید گزارش PDF برگاموت
///
/// از [ReportData] یک فایل PDF حرفه‌ای با چیدمان RTL و فونت وزیرمتن تولید می‌کند
class PdfReportService {
  static pw.Font? _vazirmatnFont;

  /// بارگذاری فونت وزیرمتن
  static Future<pw.Font> _getFont() async {
    if (_vazirmatnFont != null) return _vazirmatnFont!;
    final fontData =
        await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    _vazirmatnFont = pw.Font.ttf(fontData.buffer.asByteData());
    return _vazirmatnFont!;
  }

  /// تولید PDF از داده‌های گزارش
  ///
  /// [data] داده‌های گزارش
  /// بازگشت: بایت‌های PDF
  ///
  /// Throws [Exception] if font assets are missing or PDF generation fails.
  static Future<List<int>> generateHealthPDF(ReportData data) async {
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await _getFont();
      final boldFontData =
          await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
      boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());
    } catch (e) {
      throw Exception('خطا در بارگذاری فونت: $e');
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
    );

    // رنگ‌های برگاموت
    const primaryGreen = PdfColor(0.176, 0.416, 0.310); // #2D6A4F
    const textDark = PdfColor(0.102, 0.102, 0.180); // #1A1A2E
    const textSecondary = PdfColor(0.420, 0.447, 0.502); // #6B7280
    const successGreen = PdfColor(0.063, 0.725, 0.506); // #10B981
    const warningYellow = PdfColor(0.961, 0.620, 0.043); // #F59E0B
    const errorRed = PdfColor(0.937, 0.267, 0.267); // #EF4444
    const bgCard = PdfColor(0.980, 0.980, 0.976);

    // رنگ امتیاز
    PdfColor scoreColor;
    if (data.overallScore >= 80) {
      scoreColor = successGreen;
    } else if (data.overallScore >= 50) {
      scoreColor = warningYellow;
    } else {
      scoreColor = errorRed;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ══ بخش کاور ══
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: pw.BoxDecoration(
              color: primaryGreen,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'برگاموت',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 28,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'گزارش سلامت',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 18,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  data.periodTitle,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ══ بخش امتیاز ══
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: bgCard,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'امتیاز سبک زندگی',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                    color: textDark,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  data.overallScore.toStringAsFixed(0),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 56,
                    color: scoreColor,
                  ),
                ),
                pw.Text(
                  'از ۱۰۰',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ══ بخش خواب ══
          if (data.sleepStats != null) _buildSection(
            title: 'خواب',
            icon: '😴',
            font: font,
            boldFont: boldFont,
            textDark: textDark,
            textSecondary: textSecondary,
            bgCard: bgCard,
            children: [
              _buildStatRow(
                label: 'میانگین مدت خواب',
                value: _formatMinutes(data.sleepStats!.avgDurationMinutes),
                font: font,
                boldFont: boldFont,
                textDark: textDark,
                textSecondary: textSecondary,
              ),
              _buildStatRow(
                label: 'میانگین کیفیت',
                value: '${data.sleepStats!.avgQuality.toStringAsFixed(1)} از ۵',
                font: font,
                boldFont: boldFont,
                textDark: textDark,
                textSecondary: textSecondary,
              ),
              if (data.sleepStats!.bestDuration != null)
                _buildStatRow(
                  label: 'بهترین شب',
                  value: _formatMinutes(
                      data.sleepStats!.bestDuration!.toDouble()),
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
              if (data.sleepStats!.worstDuration != null)
                _buildStatRow(
                  label: 'بدترین شب',
                  value: _formatMinutes(
                      data.sleepStats!.worstDuration!.toDouble()),
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
            ],
          ),
          if (data.sleepStats != null) pw.SizedBox(height: 16),

          // ══ بخش تغذیه ══
          if (data.nutritionStats != null)
            _buildSection(
              title: 'تغذیه',
              icon: '🍽',
              font: font,
              boldFont: boldFont,
              textDark: textDark,
              textSecondary: textSecondary,
              bgCard: bgCard,
              children: [
                _buildStatRow(
                  label: 'میانگین کالری',
                  value:
                      '${data.nutritionStats!.avgCalories.toStringAsFixed(0)} کیلوکالری',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'پروتئین',
                  value:
                      '${data.nutritionStats!.avgProtein.toStringAsFixed(1)} گرم',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'چربی',
                  value:
                      '${data.nutritionStats!.avgFat.toStringAsFixed(1)} گرم',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'کربوهیدرات',
                  value:
                      '${data.nutritionStats!.avgCarb.toStringAsFixed(1)} گرم',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'روزهای در محدوده هدف',
                  value: '${data.nutritionStats!.daysOnTarget} روز',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          if (data.nutritionStats != null) pw.SizedBox(height: 16),

          // ══ بخش تمرین ══
          if (data.workoutStats != null)
            _buildSection(
              title: 'تمرین',
              icon: '💪',
              font: font,
              boldFont: boldFont,
              textDark: textDark,
              textSecondary: textSecondary,
              bgCard: bgCard,
              children: [
                _buildStatRow(
                  label: 'تعداد تمرینات',
                  value: '${data.workoutStats!.count} جلسه',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'مجموع حجم',
                  value:
                      '${data.workoutStats!.totalVolume.toStringAsFixed(0)} کیلوگرم',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'مجموع مدت تمرین',
                  value: _formatMinutes(
                      data.workoutStats!.totalDurationMinutes.toDouble()),
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          if (data.workoutStats != null) pw.SizedBox(height: 16),

          // ══ بخش آب ══
          if (data.hydrationStats != null)
            _buildSection(
              title: 'هیدراتاسیون',
              icon: '💧',
              font: font,
              boldFont: boldFont,
              textDark: textDark,
              textSecondary: textSecondary,
              bgCard: bgCard,
              children: [
                _buildStatRow(
                  label: 'میانگین آب مصرفی',
                  value:
                      '${data.hydrationStats!.avgMl.toStringAsFixed(0)} میلی‌لیتر',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'روزهای رسیدن به هدف',
                  value: '${data.hydrationStats!.daysOnTarget} روز',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          if (data.hydrationStats != null) pw.SizedBox(height: 16),

          // ══ بخش وزن ══
          if (data.weightChange != null)
            _buildSection(
              title: 'وزن',
              icon: '⚖',
              font: font,
              boldFont: boldFont,
              textDark: textDark,
              textSecondary: textSecondary,
              bgCard: bgCard,
              children: [
                _buildStatRow(
                  label: 'وزن شروع',
                  value:
                      '${data.weightChange!.startWeight.toStringAsFixed(1)} کیلوگرم',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'وزن پایان',
                  value:
                      '${data.weightChange!.endWeight.toStringAsFixed(1)} کیلوگرم',
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                ),
                _buildStatRow(
                  label: 'تغییر',
                  value: _formatWeightChange(data.weightChange!.diffKg),
                  font: font,
                  boldFont: boldFont,
                  textDark: textDark,
                  textSecondary: textSecondary,
                  valueColor: data.weightChange!.diffKg > 0
                      ? warningYellow
                      : data.weightChange!.diffKg < 0
                          ? successGreen
                          : textDark,
                ),
              ],
            ),
          if (data.weightChange != null) pw.SizedBox(height: 16),

          // ══ بخش توصیه‌ها ══
          _buildSection(
            title: 'توصیه‌ها',
            icon: '💡',
            font: font,
            boldFont: boldFont,
            textDark: textDark,
            textSecondary: textSecondary,
            bgCard: bgCard,
            children: data.recommendations.map((rec) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: primaryGreen,
                          )),
                      pw.Expanded(
                        child: pw.Text(
                          rec,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: textDark,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
          ),
          pw.SizedBox(height: 32),

          // ══ پاورقی ══
          pw.Center(
            child: pw.Text(
              'تولیدشده با برگاموت — اپلیکیشن سلامت شخصی',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: textSecondary,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// اشتراک‌گذاری PDF
  static Future<void> sharePdf(List<int> bytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: fileName,
      );
    } catch (e) {
      throw Exception('خطا در اشتراک‌گذاری PDF: $e');
    }
  }

  // ── ویجت‌های کمکی ═══════════════════════════════════════════════════

  /// ساخت بخش با عنوان و کارت
  static pw.Widget _buildSection({
    required String title,
    required String icon,
    required pw.Font font,
    required pw.Font boldFont,
    required PdfColor textDark,
    required PdfColor textSecondary,
    required PdfColor bgCard,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgCard,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: textDark,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                icon,
                style: const pw.TextStyle(fontSize: 20),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// ساخت ردیف آمار
  static pw.Widget _buildStatRow({
    required String label,
    required String value,
    required pw.Font font,
    required pw.Font boldFont,
    required PdfColor textDark,
    required PdfColor textSecondary,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 13,
              color: textSecondary,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: valueColor ?? textDark,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  /// تبدیل دقیقه به فرمت ساعت و دقیقه
  static String _formatMinutes(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) return '$m دقیقه';
    return '$h ساعت و $m دقیقه';
  }

  /// فرمت تغییر وزن
  static String _formatWeightChange(double diffKg) {
    final absDiff = diffKg.abs().toStringAsFixed(1);
    if (diffKg > 0) return '+$absDiff کیلوگرم';
    if (diffKg < 0) return '-$absDiff کیلوگرم';
    return 'بدون تغییر';
  }
}
