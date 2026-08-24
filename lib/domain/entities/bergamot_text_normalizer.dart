/// نرمالایزر متن فارسی/انگلیسی برای استفاده در search و index
///
/// این کلاس باید با pipeline Python (data_pipeline/scripts/persian_map.py)
/// هماهنگ باشد — یعنی اگر کاربر «ماست‌پرچرب» را جستجو کند، باید همان نتایج
/// «ماست پرچرب» را بدهد.
///
/// تبدیل‌ها:
///   - ي → ی  (عربی → فارسی)
///   - ك → ک  (عربی → فارسی)
///   - ئ → ی
///   - ZWNJ (نیم‌فاصله) → space
///   - چند space → یکی
///   - punctuation حذف
///   - lowercase (برای انگلیسی)
class BergamotTextNormalizer {
  BergamotTextNormalizer._();

  static const _arabicYe = '\u064A';     // ي
  static const _persianYe = '\u06CC';    // ی
  static const _arabicKe = '\u0643';     // ك
  static const _persianKe = '\u06A9';    // ک
  static const _arabicYeHamza = '\u0626'; // ئ
  static const _zwnj = '\u200C';          // نیم‌فاصله

  // Pre-compiled punctuation regexes — top-level for performance.
  // Note: raw string with double quotes to allow both ' and " inside.
  static final _punctuationRe = RegExp(
    r'''[!?,;:"'`(){}\[\]/\\@#$%^&*+=<>|~]''',
  );
  static final _unicodePunctuationRe = RegExp(
    // Includes general punctuation + Arabic/Persian punctuation (U+0600-U+06FF)
    r'[\u0600-\u0606\u060C\u060D\u061B\u061E\u061F\u2000-\u206F\u2E00-\u2E7F\u3000-\u303F]',
  );
  static final _whitespaceRe = RegExp(r'\s+');

  /// نرمالایز کردن متن فارسی برای search/index
  static String normalizeFa(String s) {
    if (s.isEmpty) return '';
    var r = s;
    r = r.replaceAll(_arabicYe, _persianYe);
    r = r.replaceAll(_arabicKe, _persianKe);
    r = r.replaceAll(_arabicYeHamza, _persianYe);
    r = r.replaceAll(_zwnj, ' ');
    // حذف punctuation فارسی و انگلیسی
    r = r.replaceAll(_punctuationRe, ' ');
    r = r.replaceAll(_unicodePunctuationRe, ' ');
    r = r.replaceAll(_whitespaceRe, ' ').trim();
    return r.toLowerCase();
  }

  /// نرمالایز کردن متن انگلیسی برای search/index
  static String normalizeEn(String s) {
    if (s.isEmpty) return '';
    var r = s;
    r = r.replaceAll(_punctuationRe, ' ');
    r = r.replaceAll(_unicodePunctuationRe, ' ');
    r = r.replaceAll(_whitespaceRe, ' ').trim();
    return r.toLowerCase();
  }

  /// تشخیص خودکار: اگر حروف فارسی دارد، normalizeFa، وگرنه normalizeEn
  static String normalize(String s) {
    if (s.isEmpty) return '';
    var r = s;
    // نرمالسازی ارقام فارسی/عربی به لاتین
    r = r.replaceAllMapped(RegExp(r'[۰-۹]'), (m) => '${'۰۱۲۳۴۵۶۷۸۹'.indexOf(m[0]!)}');
    final hasPersian = RegExp(r'[\u0600-\u06FF]').hasMatch(r);
    return hasPersian ? normalizeFa(r) : normalizeEn(r);
  }
}
