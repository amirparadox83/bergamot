/// یک کاندیدای غذا برای استفاده در تطبیق مواد اولیه رسپی‌ها.
///
/// این کلاس intentionally ساده است تا بتوان آن را بدون وابستگی به دیتابیس
/// در unit test ها آزمایش کرد.
class FoodCandidate {
  final int id;
  final String normalizedNameEn;
  final String? source;
  final String? nameFa;

  const FoodCandidate({
    required this.id,
    required this.normalizedNameEn,
    this.source,
    this.nameFa,
  });

  @override
  String toString() =>
      'FoodCandidate(id=$id, normalizedNameEn="$normalizedNameEn", '
      'source=$source, nameFa=$nameFa)';
}

/// نتیجه‌ی یک تطبیق مواد اولیه.
class IngredientMatchResult {
  final FoodCandidate food;
  final IngredientMatchStrategy strategy;

  const IngredientMatchResult(this.food, this.strategy);

  @override
  String toString() =>
      'IngredientMatchResult(food=$food, strategy=$strategy)';
}

/// استراتژی استفاده‌شده برای تطبیق.
enum IngredientMatchStrategy {
  /// `normalizedNameEn == ingredientKey` (دقیق)
  exact,

  /// با افزودن/حذف 's' انتهایی (جمع/مفرد)
  pluralSingular,

  /// همه‌ی توکن‌های غذا در توکن‌های recipe key هستند (مثلاً recipe "cilantro fresh"
  /// با food "cilantro" تطبیق می‌کند چون {cilantro} ⊆ {cilantro, fresh})
  tokenSuperset,

  /// همه‌ی توکن‌های recipe key در توکن‌های غذا هستند (مثلاً recipe "lamb raw"
  /// با food "lamb liver raw" تطبیق می‌دهد). با penalty برای توکن‌های اضافه نامطلوب.
  tokenSubset,

  /// همپوشانی توکن‌ها (حداقل یک توکن غیر-qualifier از recipe در غذا باشد).
  /// آخرین fallback برای مواردی مثل "lamb raw" → "lamb meat"
  tokenOverlap,

  /// هیچ تطبیقی پیدا نشد
  none,
}

/// اولویت منبع داده — هر چه کمتر، اولویت بیشتر.
///
/// `IRANIAN_REFERENCE` بالاترین اولویت را دارد چون رکوردهای curated برای
/// غذاهای ایرانی هستند. سپس USDA_FOUNDATION و USDA_SR_LEGACY.
int _sourcePriority(String? source) {
  switch (source) {
    case 'IRANIAN_REFERENCE':
      return 0;
    case 'USDA_FOUNDATION':
      return 1;
    case 'USDA_SR_LEGACY':
      return 2;
    case 'USDA_FDC':
      return 3;
    case 'BERGAMOT':
      return 4;
    case 'CUSTOM':
      return 5;
    default:
      return 99;
  }
}

/// توکن‌هایی که وقتی در نام غذا هستند ولی در recipe key نیستند، نشان‌دهنده‌ی
/// این هستند که غذا variant متفاوتی است (organs، leaves، sweet potato و ...).
///
/// این توکن‌ها به شدت penalize می‌شوند تا از تطبیق‌های اشتباه مانند
/// "lamb raw" → "lamb liver raw" جلوگیری شود.
const Set<String> _badExtraTokens = {
  // Organ meats
  'liver', 'heart', 'kidneys', 'kidney', 'testes', 'giblets', 'brains',
  'brain', 'tongue', 'tripe', 'feet', 'foot', 'head', 'blood',
  'spleen', 'lung', 'lungs', 'lips', 'ears', 'tail', 'neck', 'gizzard',
  'sweetbread', 'sweetbreads', 'variety', 'by-products', 'organs',
  // Plant parts we don't want
  'leaves', 'leaf', 'stems', 'stem', 'peels', 'peel', 'shell', 'skin',
  'bones', 'bone', 'pits', 'pit', 'husk', 'cob',
  // Sweet qualifier (different food entirely: "sweet potato" vs "potato")
  'sweet',
  // Processing states that change nutrition significantly
  'canned', 'frozen', 'pickled', 'smoked', 'salted', 'fermented',
  'cooked', 'boiled', 'fried', 'baked', 'roasted', 'steamed',
  'dried', 'dehydrated',
};

/// توکن‌های qualifier که در recipe key می‌آیند و state غذا را مشخص می‌کنند
/// (raw، fresh، dried، ...). در Strategy 5 نباید به تنهایی باعث match شوند.
const Set<String> _qualifierTokens = {
  'raw', 'fresh', 'dried', 'cooked', 'ground', 'whole', 'paste',
  'powder', 'juice', 'oil',
};

/// Generate plural/singular variants of a single token.
///
/// Returns a list of possible variants (does NOT include the original).
/// For "onion" → ["onions"]. For "onions" → ["onion"]. For "potato" →
/// ["potatoes", "potatos"]. For "berries" → ["berry"].
List<String> _pluralSingularVariants(String token) {
  if (token.isEmpty) return const [];
  final result = <String>{};
  // Pluralize (singular → plural)
  if (!token.endsWith('s')) {
    // "onion" → "onions"
    result.add('${token}s');
    // "potato" → "potatoes" (ends in -o, add -es)
    if (token.endsWith('o') ||
        token.endsWith('x') ||
        token.endsWith('z') ||
        token.endsWith('ch') ||
        token.endsWith('sh')) {
      result.add('${token}es');
    }
    // "berry" → "berries" (ends in -y preceded by consonant)
    if (token.endsWith('y') && token.length >= 2) {
      final before = token[token.length - 2];
      if (!_isVowel(before)) {
        result.add('${token.substring(0, token.length - 1)}ies');
      }
    }
    // "leaf" → "leaves" (ends in -f or -fe)
    if (token.endsWith('fe') && token.length >= 3) {
      result.add('${token.substring(0, token.length - 2)}ves');
    } else if (token.endsWith('f') && token.length >= 2 &&
        token != 'if' && token != 'of' && token != 'chef') {
      // Some -f words take -ves; this is a heuristic.
      result.add('${token.substring(0, token.length - 1)}ves');
    }
  } else {
    // Singularize (plural → singular)
    // "onions" → "onion"
    result.add(token.substring(0, token.length - 1));
    // "potatoes" → "potato" (ends in -es, strip -es)
    if (token.endsWith('es')) {
      result.add(token.substring(0, token.length - 2));
    }
    // "berries" → "berry"
    if (token.endsWith('ies') && token.length >= 4) {
      result.add('${token.substring(0, token.length - 3)}y');
    }
    // "leaves" → "leaf"
    if (token.endsWith('ves') && token.length >= 4) {
      result.add('${token.substring(0, token.length - 3)}f');
      result.add('${token.substring(0, token.length - 3)}fe');
    }
  }
  return result.toList();
}

bool _isVowel(String c) {
  return c == 'a' || c == 'e' || c == 'i' || c == 'o' || c == 'u';
}

/// Split a string into tokens (space-separated, non-empty).
List<String> _tokenize(String s) {
  return s.split(' ').where((t) => t.isNotEmpty).toList();
}

/// Check if two tokens match considering English plural/singular variants.
///
/// Handles common English pluralization patterns:
/// - `-s` suffix: "onions" ↔ "onion"
/// - `-es` suffix: "potatoes" ↔ "potato", "tomatoes" ↔ "tomato"
/// - `-ies` ↔ `-y`: "berries" ↔ "berry", "cherries" ↔ "cherry"
/// - `-ves` ↔ `-f` / `-fe`: "leaves" ↔ "leaf", "halves" ↔ "half"
///
/// Note: This is a best-effort heuristic and may not catch all irregular
/// plurals (e.g., "children", "mice", "geese"). For our food-ingredient
/// use case, the regular patterns cover ~99% of cases.
bool _tokenMatch(String a, String b) {
  if (a == b) return true;
  // -s suffix (most common): "onions" ↔ "onion"
  if (a.endsWith('s') && a.substring(0, a.length - 1) == b) return true;
  if (b.endsWith('s') && b.substring(0, b.length - 1) == a) return true;
  // -es suffix: "potatoes" ↔ "potato", "tomatoes" ↔ "tomato"
  if (a.endsWith('es') && a.substring(0, a.length - 2) == b) return true;
  if (b.endsWith('es') && b.substring(0, b.length - 2) == a) return true;
  // -ies ↔ -y: "berries" ↔ "berry", "cherries" ↔ "cherry"
  if (a.endsWith('ies') && '${a.substring(0, a.length - 3)}y' == b) {
    return true;
  }
  if (b.endsWith('ies') && '${b.substring(0, b.length - 3)}y' == a) {
    return true;
  }
  // -ves ↔ -f: "leaves" ↔ "leaf", "halves" ↔ "half"
  if (a.endsWith('ves') && '${a.substring(0, a.length - 3)}f' == b) {
    return true;
  }
  if (b.endsWith('ves') && '${b.substring(0, b.length - 3)}f' == a) {
    return true;
  }
  // -ves ↔ -fe: (rare, e.g., "knives" ↔ "knife")
  if (a.endsWith('ves') && '${a.substring(0, a.length - 3)}fe' == b) {
    return true;
  }
  if (b.endsWith('ves') && '${b.substring(0, b.length - 3)}fe' == a) {
    return true;
  }
  return false;
}

/// Check if recipe token [rt] appears in [foodTokens] (with s/pl tolerance).
bool _recipeTokenInFood(String rt, Iterable<String> foodTokens) {
  for (final ft in foodTokens) {
    if (_tokenMatch(rt, ft)) return true;
  }
  return false;
}

/// توکن‌های اضافه‌ی غذا که در recipe key نیستند (با درنظرگرفتن s/pl).
List<String> _realExtras(String foodName, Set<String> recipeTokens) {
  final foodTokens = _tokenize(foodName).toSet();
  final extras = foodTokens.difference(recipeTokens);
  // Filter out tokens that are s/pl variants of recipe tokens
  return extras
      .where((et) => !recipeTokens.any((rt) => _tokenMatch(et, rt)))
      .toList();
}

/// Score یک کاندیداد — کمتر = بهتر.
///
/// اولویت‌ها به ترتیب:
/// 1. تعداد bad_extra (توکن‌های نامطلوب در نام غذا که در recipe نیستند)
/// 2. تعداد real extras (توکن‌های اضافه کلی)
/// 3. طول نام غذا (کوتاه‌تر = کم‌جزئیات‌تر = بهتر)
/// 4. اولویت source (IRANIAN_REFERENCE > USDA_FOUNDATION > ...)
List<int> _score(FoodCandidate food, Set<String> recipeTokens) {
  final realExtras = _realExtras(food.normalizedNameEn, recipeTokens);
  final badExtraCount =
      realExtras.where((t) => _badExtraTokens.contains(t.toLowerCase())).length;
  return [
    badExtraCount,
    realExtras.length,
    food.normalizedNameEn.length,
    _sourcePriority(food.source),
  ];
}

/// تطبیق‌دهنده‌ی مواد اولیه رسپی‌ها با کاندیداهای غذا.
///
/// این کلاس چندین استراتژی تطبیق را به ترتیب اولویت امتحان می‌کند:
/// 1. تطبیق دقیق
/// 2. تطبیق با plural/singular
/// 3. Token-superset (نام غذا زیرمجموعه‌ی recipe key باشد)
/// 4. Token-subset با penalty برای توکن‌های نامطلوب
/// 5. Token overlap با الزام به match حداقل یک توکن غیر-qualifier
///
/// اگر هیچ استراتژی‌ای موفق نشود، `null` برمی‌گرداند.
class IngredientMatcher {
  const IngredientMatcher();

  /// بهترین تطبیق را برای [ingredientKey] در لیست [foods] پیدا کن.
  ///
  /// پارامتر [foods] باید لیستی از همه‌ی کاندیداهای غذا باشد. در عمل،
  /// این لیست از جدول `foods` دیتابیس بارگذاری می‌شود.
  ///
  /// خروجی: `[FoodCandidate, IngredientMatchStrategy]` یا `null` اگر هیچ تطبیقی نبود.
  IngredientMatchResult? findBestMatch({
    required String ingredientKey,
    required List<FoodCandidate> foods,
  }) {
    if (ingredientKey.isEmpty || foods.isEmpty) return null;

    final recipeTokens = _tokenize(ingredientKey).toSet();
    if (recipeTokens.isEmpty) return null;

    // ─── Strategy 1: exact match ───
    final exactCandidates =
        foods.where((f) => f.normalizedNameEn == ingredientKey).toList();
    if (exactCandidates.isNotEmpty) {
      exactCandidates
          .sort((a, b) => _sourcePriority(a.source).compareTo(_sourcePriority(b.source)));
      return IngredientMatchResult(exactCandidates.first, IngredientMatchStrategy.exact);
    }

    // ─── Strategy 2: plural/singular exact ───
    // Try variants where we pluralize/singularize the WHOLE string
    // (e.g., "onions" → "onion") OR the FIRST token only
    // (e.g., "onion raw" → "onions raw").
    final variants = <String>{};
    if (ingredientKey.endsWith('s')) {
      variants.add(ingredientKey.substring(0, ingredientKey.length - 1));
    } else {
      variants.add('${ingredientKey}s');
    }
    // Also try pluralizing/singularizing the FIRST token (the main ingredient).
    // For multi-word recipe keys like "onion raw", we want to match "onions raw".
    final keyTokens = _tokenize(ingredientKey);
    if (keyTokens.length >= 2) {
      final first = keyTokens.first;
      final rest = keyTokens.skip(1).join(' ');
      final firstVariants = _pluralSingularVariants(first);
      for (final v in firstVariants) {
        variants.add(rest.isEmpty ? v : '$v $rest');
      }
    }
    for (final variant in variants) {
      if (variant == ingredientKey) continue; // skip no-op
      final plCandidates =
          foods.where((f) => f.normalizedNameEn == variant).toList();
      if (plCandidates.isNotEmpty) {
        plCandidates.sort(
            (a, b) => _sourcePriority(a.source).compareTo(_sourcePriority(b.source)));
        return IngredientMatchResult(
            plCandidates.first, IngredientMatchStrategy.pluralSingular);
      }
    }

    // ─── Strategy 3: token-superset (food tokens ⊆ recipe tokens) ───
    // All food tokens must appear in recipe tokens (with s/pl tolerance).
    // This catches cases like recipe "cilantro fresh" matching food "cilantro"
    // (the IRANIAN_REFERENCE entry is the canonical simple form).
    List<FoodCandidate>? s3Matches;
    for (final food in foods) {
      final foodTokens = _tokenize(food.normalizedNameEn).toSet();
      final allFoodInRecipe = foodTokens
          .every((ft) => recipeTokens.any((rt) => _tokenMatch(ft, rt)));
      if (allFoodInRecipe) {
        s3Matches ??= [];
        s3Matches.add(food);
      }
    }
    if (s3Matches != null) {
      s3Matches.sort((a, b) {
        final sa = _score(a, recipeTokens);
        final sb = _score(b, recipeTokens);
        return _compareIntLists(sa, sb);
      });
      return IngredientMatchResult(s3Matches.first, IngredientMatchStrategy.tokenSuperset);
    }

    // ─── Strategy 4: token-subset (recipe tokens ⊆ food tokens) ───
    // All recipe tokens must appear in food tokens (with s/pl tolerance).
    // Bad extra tokens penalize; shortest + best source wins.
    List<FoodCandidate>? s4Matches;
    for (final food in foods) {
      final foodTokens = _tokenize(food.normalizedNameEn).toSet();
      final allRecipeInFood =
          recipeTokens.every((rt) => _recipeTokenInFood(rt, foodTokens));
      if (allRecipeInFood) {
        s4Matches ??= [];
        s4Matches.add(food);
      }
    }
    if (s4Matches != null) {
      s4Matches.sort((a, b) {
        final sa = _score(a, recipeTokens);
        final sb = _score(b, recipeTokens);
        return _compareIntLists(sa, sb);
      });
      return IngredientMatchResult(s4Matches.first, IngredientMatchStrategy.tokenSubset);
    }

    // ─── Strategy 5: token overlap (last-resort fallback) ───
    // At least one NON-QUALIFIER recipe token must match a food token.
    // This is needed for cases like recipe "lamb raw" → food "lamb meat"
    // where the food name doesn't have "raw" but is the canonical generic
    // Iranian reference entry for that ingredient.
    final nonQualRecipeTokens = recipeTokens
        .where((rt) => !_qualifierTokens.contains(rt.toLowerCase()))
        .toList();
    // If all recipe tokens are qualifiers (rare), fall back to all tokens.
    final effectiveNonQual =
        nonQualRecipeTokens.isEmpty ? recipeTokens.toList() : nonQualRecipeTokens;

    List<({FoodCandidate food, int matchedCount, int nonQualMatched, List<int> score})>?
        s5Matches;
    for (final food in foods) {
      final foodTokens = _tokenize(food.normalizedNameEn).toSet();
      final nonQualMatched = effectiveNonQual
          .where((rt) => _recipeTokenInFood(rt, foodTokens))
          .length;
      if (nonQualMatched < 1) continue;

      final matchedCount =
          recipeTokens.where((rt) => _recipeTokenInFood(rt, foodTokens)).length;
      final realExtras = _realExtras(food.normalizedNameEn, recipeTokens);
      final badExtra = realExtras
          .where((t) => _badExtraTokens.contains(t.toLowerCase()))
          .length;
      // Score: minimize bad_extra, maximize matched, maximize nonQualMatched,
      // minimize extras, minimize length, source priority.
      final score = [
        badExtra,
        -matchedCount,
        -nonQualMatched,
        realExtras.length,
        food.normalizedNameEn.length,
        _sourcePriority(food.source),
      ];
      s5Matches ??= [];
      s5Matches.add((
        food: food,
        matchedCount: matchedCount,
        nonQualMatched: nonQualMatched,
        score: score,
      ));
    }
    if (s5Matches != null) {
      s5Matches.sort((a, b) => _compareIntLists(a.score, b.score));
      return IngredientMatchResult(s5Matches.first.food, IngredientMatchStrategy.tokenOverlap);
    }

    return null;
  }

  /// Compare two int lists lexicographically.
  static int _compareIntLists(List<int> a, List<int> b) {
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return a.length.compareTo(b.length);
  }
}

/// Utility: convert a list of drift Food rows (or any compatible shape) to
/// FoodCandidate. Useful for keeping the matcher pure.
///
/// Example:
/// ```dart
/// final candidates = foodsFromDb
///     .map((f) => FoodCandidate(
///           id: f.id,
///           normalizedNameEn: f.normalizedNameEn,
///           source: f.source,
///           nameFa: f.nameFa,
///         ))
///     .toList();
/// ```
List<FoodCandidate> foodsToCandidates({
  required List<int> ids,
  required List<String> normalizedNameEns,
  required List<String?> sources,
  required List<String?> nameFas,
}) {
  if (ids.length != normalizedNameEns.length) throw ArgumentError('Expected ${ids.length} normalizedNameEns, got ${normalizedNameEns.length}');
  if (ids.length != sources.length) throw ArgumentError('Expected ${ids.length} sources, got ${sources.length}');
  if (ids.length != nameFas.length) throw ArgumentError('Expected ${ids.length} nameFas, got ${nameFas.length}');
  return List.generate(
    ids.length,
    (i) => FoodCandidate(
      id: ids[i],
      normalizedNameEn: normalizedNameEns[i],
      source: sources[i],
      nameFa: nameFas[i],
    ),
  );
}
