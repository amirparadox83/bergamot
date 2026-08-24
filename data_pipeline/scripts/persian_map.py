"""
Text normalization and Persian-English food name mapping.

Two responsibilities:
  1. normalize_fa(s): Persian text normalization (ي/ی, ك/ك, ZWNJ, extra spaces).
  2. normalize_en(s): English text normalization (lowercase, collapse whitespace).
  3. EN_FA_MAP: hardcoded English → Farsi name dictionary for ~200 common foods.
  4. fa_name_for(en_name): best-effort Persian name lookup using exact + token match.

NO fabrication: if we don't have a Persian name, we return None.
"""
from __future__ import annotations

import re
import unicodedata

# ---------------------------------------------------------------------------
# Persian normalization
# ---------------------------------------------------------------------------
_ARABIC_YE = "\u064A"     # ي
_PERSIAN_YE = "\u06CC"    # ی
_ARABIC_KE = "\u0643"     # ك
_PERSIAN_KE = "\u06A9"    # ک
_ARABIC_YE_HAMZA = "\u0626"  # ئ
_ZWNJ = "\u200C"          # نیم‌فاصله
_PERSIAN_YE_HAMZA = "\u0626"  # ئ (already same, but kept for completeness)


def normalize_fa(s: str) -> str:
    """Normalize Persian text for search/indexing.

    - ي → ی
    - ك → ک
    - ZWNJ removed (so "ماست‌پرچرب" == "ماست پرچرب" == "ماست  پرچرب")
    - Extra spaces collapsed
    - Punctuation stripped
    - Lowercase (no-op for Persian but safe for mixed text)
    """
    if not s:
        return ""
    s = unicodedata.normalize("NFKC", s)
    s = s.replace(_ARABIC_YE, _PERSIAN_YE)
    s = s.replace(_ARABIC_KE, _PERSIAN_KE)
    s = s.replace(_ZWNJ, " ")
    # remove punctuation (Persian + English)
    s = re.sub(r"[\u2000-\u206F\u2E00-\u2E7F\u3000-\u303F.!?,;:\"'`(){}\[\]/\\@#$%^&*+=<>|~]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s.lower()


def normalize_en(s: str) -> str:
    """Normalize English text for search/indexing (commas removed)."""
    if not s:
        return ""
    s = unicodedata.normalize("NFKC", s)
    s = re.sub(r"[\u2000-\u206F!?,;:\"'`(){}\[\]/\\@#$%^&*+=<>|~]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s.lower()


def _normalize_en_with_commas(s: str) -> str:
    """Like normalize_en but preserves commas — used for prefix/suffix logic."""
    if not s:
        return ""
    s = unicodedata.normalize("NFKC", s)
    # strip all punctuation EXCEPT comma
    s = re.sub(r"[\u2000-\u206F!?;:\"'`(){}\[\]/\\@#$%^&*+=<>|~]", " ", s)
    s = re.sub(r"\s+", " ", s).strip().lower()
    # collapse ", " + spaces
    s = re.sub(r"\s*,\s*", ", ", s)
    return s


# ---------------------------------------------------------------------------
# Persian mapping for common foods.
# These are widely accepted Persian names. NO nutrition values are fabricated
# here — this is purely a name translation table.
# ---------------------------------------------------------------------------
EN_FA_MAP = {
    # Fruits
    "apple": "سیب",
    "banana": "موز",
    "orange": "پرتقال",
    "pear": " گلابی",  # leading space removed by normalize
    "pear ": " گلابی",
    "peach": "شلیل",
    "nectarine": "شلیل زرد",
    "plum": "آلو",
    "apricot": "زردآلو",
    "cherry": "گیلاس",
    "sour cherry": "آلبالو",
    "strawberry": "توت فرنگی",
    "raspberry": "تمشک",
    "blackberry": "توت سیاه",
    "blueberry": "بلوبری",
    "grape": "انگور",
    "pomegranate": "انار",
    "fig": "انجیر",
    "date": "خرما",
    "kiwi": "کیوی",
    "mango": "مانگو",
    "pineapple": "آناناس",
    "watermelon": "هندوانه",
    "cantaloupe": "طالبی",
    "melon": "خربزه",
    "lemon": "لیمو",
    "lime": "لیمو سبز",
    "grapefruit": "گریپ‌فروت",
    "avocado": "آووکادو",
    "coconut": "نارگیل",
    "raisin": "کشمش",
    "dried apricot": "قیسی",
    "dried fig": "انجیر خشک",

    # Vegetables
    "tomato": "گوجه فرنگی",
    "cucumber": "خیار",
    "carrot": "هویج",
    "potato": "سیب زمینی",
    "onion": "پیاز",
    "garlic": "سیر",
    "lettuce": "کاهو",
    "spinach": "اسفناج",
    "eggplant": "بادمجان",
    "zucchini": "کدو سبز",
    "cabbage": "کلم",
    "cauliflower": "گل کلم",
    "broccoli": "کلم بروکلی",
    "bell pepper": "فلفل دلمه‌ای",
    "pepper": "فلفل",
    "green pepper": "فلفل سبز",
    "chili pepper": "فلفل تند",
    "celery": "کرفس",
    "mushroom": "قارچ",
    "corn": "ذرت",
    "pumpkin": "کدو تنبل",
    "squash": "کدو",
    "sweet potato": "سیب زمینی شیرین",
    "beet": "چغندر",
    "radish": "شلغم",
    "turnip": "شلغم",
    "okra": "بامیه",
    "artichoke": "آرتیشو",
    "asparagus": "مارچوبه",
    "leek": "تره فرنگی",
    "green bean": "لوبیا سبز",
    "pea": "نخود فرنگی",
    "green pea": "نخود فرنگی",
    "pumpkin": "کدو تنبل",
    "kale": "کلم پیچ",
    "bok choy": "کلم چینی",
    "kohlrabi": "شلغم آلمانی",
    "fennel": "رازیانه",
    "watercress": "شاهی",
    "arugula": "اروگولا",
    "endive": "اندیو",
    "radicchio": "رادیکیو",
    "swiss chard": "چغندر سوئیسی",
    "collard greens": "کلم برگ",

    # Legumes
    "lentil": "عدس",
    "lentils": "عدس",
    "chickpea": "نخود",
    "chickpeas": "نخود",
    "kidney bean": "لوبیا قرمز",
    "kidney beans": "لوبیا قرمز",
    "white bean": "لوبیا سفید",
    "navy bean": "لوبیا navy",
    "pinto bean": "لوبیا pinto",
    "black bean": "لوبیا سیاه",
    "split pea": "لپه",
    "split peas": "لپه",
    "mung bean": "ماش",
    "mung beans": "ماش",
    "fava bean": "باقلا",
    "broad bean": "باقلا",
    "soybean": "سویا",
    "soybeans": "سویا",
    "tofu": "توفو",
    "tempeh": "تمپه",

    # Grains
    "rice": "برنج",
    "white rice": "برنج سفید",
    "brown rice": "برنج قهوه‌ای",
    "basmati rice": "برنج باسماتی",
    "wheat": "گندم",
    "wheat flour": "آرد گندم",
    "barley": "جو",
    "oat": "جو دوسر",
    "oats": "جو دوسر",
    "oatmeal": "جو دوسر پخته",
    "corn": "ذرت",
    "cornmeal": "آرد ذرت",
    "corn flour": "آرد ذرت",
    "rye": "چاودار",
    "buckwheat": "گندم سیاه",
    "quinoa": "کینوا",
    "millet": "ارزن",
    "sorghum": "باجر",
    "bulgur": "بلغور",
    "couscous": "کوسکوس",
    "pasta": "پاستا",
    "spaghetti": "اسپاگتی",
    "macaroni": "ماکارونی",
    "noodle": "رشته",
    "noodles": "رشته",
    "bread": "نان",
    "flour": "آرد",

    # Bread (Persian specifics handled in iranian_recipes.py)
    "white bread": "نان سفید",
    "whole wheat bread": "نان سبوس‌دار",
    "rye bread": "نان چاودار",
    "pita": "نان پیتا",
    "baguette": "باگت",

    # Dairy
    "milk": "شیر",
    "whole milk": "شیر پرچرب",
    "skim milk": "شیر کم‌چرب",
    "low fat milk": "شیر کم‌چرب",
    "yogurt": "ماست",
    "greek yogurt": "ماست یونانی",
    "cheese": "پنیر",
    "feta cheese": "پنیر فتا",
    "cottage cheese": "پنیر کاتیج",
    "mozzarella": "پنیر موزارلا",
    "cream cheese": "پنیر خامه‌ای",
    "parmesan": "پنیر پارمزان",
    "butter": "کره",
    "cream": "خامه",
    "whipping cream": "خامه فرم‌دار",
    "sour cream": "خامه ترش",
    "whey": "پنیر آب",
    "kefir": "کفیر",
    "buttermilk": "ماست شیرین",
    "ghee": "روغن حیوانی",

    # Meat
    "beef": "گوشت گاو",
    "ground beef": "گوشت چرخ‌کرده",
    "steak": "استیک",
    "lamb": "گوشت گوسفند",
    "mutton": "گوشت گوسفند بالغ",
    "veal": "گوشت گوساله",
    "pork": "گوشت خوک",
    "bacon": "بیکن",
    "ham": "ژامبون",
    "sausage": "سوسیس",
    "liver": "جگر",
    "kidney": "کلیه",
    "heart": "قلب",
    "tongue": "زبان",

    # Poultry
    "chicken": "مرغ",
    "chicken breast": "سینه مرغ",
    "chicken thigh": "ران مرغ",
    "chicken leg": "پا مرغ",
    "chicken wing": "بال مرغ",
    "turkey": "بوقلمون",
    "duck": "اردک",
    "goose": "غاز",
    "quail": "بلدرچین",

    # Fish & Seafood
    "salmon": "ماهی سالمون",
    "tuna": "ماهی تن",
    "trout": "ماهی قزل‌آلا",
    "cod": "ماهی کاد",
    "tilapia": "ماهی تیلاپیا",
    "sardine": "ماهی ساردین",
    "mackerel": "ماهی کولی",
    "herring": "ماهی شاه‌ماهی",
    "shrimp": "میگو",
    "prawn": "میگو",
    "lobster": "خرچنگ",
    "crab": "خرچنگ",
    "oyster": "صدف",
    "clam": "صدف دو لایه",
    "mussel": "صدف آبی",
    "squid": "ماهی مرکب",
    "octopus": "هشت‌پا",
    "anchovy": "ماهی ماهیان",

    # Eggs
    "egg": "تخم مرغ",
    "egg yolk": "زرده تخم مرغ",
    "egg white": "سفیده تخم مرغ",
    "duck egg": "تخم اردک",
    "quail egg": "تخم بلدرچین",

    # Nuts
    "almond": "بادام",
    "walnut": "گردو",
    "pistachio": "پسته",
    "cashew": "بادام هندی",
    "hazelnut": "فندق",
    "pecan": "پکان",
    "brazil nut": "بادام برزیلی",
    "macadamia": "بادام مکادمیا",
    "peanut": "بادام زمینی",
    "pine nut": "آرد کاج",
    "chestnut": "شاه‌بلوط",

    # Seeds
    "sesame seed": "کنجد",
    "sesame": "کنجد",
    "sunflower seed": "تخمه آفتابگردان",
    "pumpkin seed": "تخمه کدو",
    "flax seed": "دانه کتان",
    "chia seed": "دانه چیا",
    "hemp seed": "دانه شاهدانه",
    "poppy seed": "خشخاش",

    # Oils & Fats
    "olive oil": "روغن زیتون",
    "olive oil extra virgin": "روغن زیتون فرابکر",
    "sunflower oil": "روغن آفتابگردان",
    "corn oil": "روغن ذرت",
    "canola oil": "روغن کانولا",
    "soybean oil": "روغن سویا",
    "vegetable oil": "روغن گیاهی",
    "coconut oil": "روغن نارگیل",
    "sesame oil": "روغن کنجد",
    "margarine": "مارگارین",
    "lard": "روغن حیوانی خوک",
    "tallow": "روغن حیوانی",

    # Spices & Herbs
    "salt": "نمک",
    "black pepper": "فلفل سیاه",
    "white pepper": "فلفل سفید",
    "red pepper": "فلفل قرمز",
    "cayenne": "فلفل کاین",
    "paprika": "پاپریکا",
    "cumin": "زیره",
    "turmeric": "زردچوبه",
    "cinnamon": "دارچین",
    "cardamom": "هل",
    "coriander": "گشنیز",
    "coriander seed": "تخم گشنیز",
    "cilantro": "گشنیز تازه",
    "parsley": "جعفری",
    "dill": "شبت",
    "mint": "نعناع",
    "basil": "ریحان",
    "thyme": "آویشن",
    "oregano": "پونه",
    "rosemary": "رزماری",
    "sage": "مریم گلی",
    "tarragon": "ترخون",
    "saffron": "زعفران",
    "ginger": "زنجبیل",
    "nutmeg": "جوز هندی",
    "cloves": "میخک",
    "bay leaf": "برگ بو",
    "fenugreek": "شنبلیله",
    "leek": "تره",
    "chives": "تره‌فرنگی",
    "saffron": "زعفران",
    "sumac": "سماق",
    "dried lime": "لیمو عمانی",
    "dried lemon": "لیمو خشک",
    "rose water": "گلاب",
    "orange blossom water": "آب گل наргس",

    # Sauces
    "tomato paste": "رب گوجه فرنگی",
    "tomato sauce": "سس گوجه فرنگی",
    "soy sauce": "سس سویا",
    "mayonnaise": "سس مایونز",
    "ketchup": "سس کچاپ",
    "mustard": "خردل",
    "vinegar": "سرکه",
    "balsamic vinegar": "سرکه بالزامیک",
    "apple cider vinegar": "سرکه سیب",
    "tahini": "ارده",
    "pomegranate molasses": "نارشک",
    "pomegranate paste": "رب انار",
    "barberry": "زرشک",

    # Sweeteners
    "sugar": "شکر",
    "brown sugar": "شکر قهوه‌ای",
    "honey": "عسل",
    "molasses": "ملاس",
    "maple syrup": "شیره افرا",
    "agave syrup": "شیره آگاو",
    "stevia": "استویا",
    "date syrup": "شیره خرما",
    "vanilla extract": "وانیل",

    # Beverages
    "water": "آب",
    "coffee": "قهوه",
    "espresso": "اسپرسو",
    "tea": "چای",
    "green tea": "چای سبز",
    "black tea": "چای سیاه",
    "herbal tea": "دمنوش",
    "orange juice": "آب پرتقال",
    "apple juice": "آب سیب",
    "lemon juice": "آب لیمو",
    "pomegranate juice": "آب انار",
    "carrot juice": "آب هویج",
    "coconut water": "آب نارگیل",
    "cola": "نوشابه کولا",
    "soda": "نوشابه گازدار",
    "wine": "شراب",
    "beer": "آبجوی",

    # Sweets
    "chocolate": "شکلات",
    "dark chocolate": "شکلات تلخ",
    "cocoa": "کاکائو",
    "cocoa powder": "پودر کاکائو",
    "jam": "مربا",
    "cookie": "کلوچه",
    "biscuit": "بیسکویت",
    "cake": "کیک",
    "ice cream": "بستنی",
    "pudding": "پودینگ",
    "halva": "حلوا",
    "candy": "آبنبات",

    # Breakfast
    "oatmeal": "اوتمیل",
    "corn flakes": "کورن فلکس",
    "muesli": "موزلی",
    "granola": "گرانولا",
    "pancake": "پنکیک",
    "waffle": "وافل",
    "croissant": "کروسان",
    "muffin": "مافین",
    "donut": "دونات",

    # Other basics
    "hummus": "حمص",
    "tahini": "ارده",
    "yeast": "مخمر",
    "baking powder": "بیکینگ پودر",
    "baking soda": "جوش شیرین",
    "gelatin": "ژلاتین",
    "agar": "آگار",
    "starch": "نشاسته",
    "cornstarch": "نشاسته ذرت",
    "water": "آب",
}


# Build a token-level index for fuzzy matching
_TOKEN_INDEX: dict[str, str] = {}


def _build_token_index() -> None:
    for en, fa in EN_FA_MAP.items():
        # Exact phrase
        norm = normalize_en(en)
        _TOKEN_INDEX[norm] = fa
        # Also index each token (last one wins, but most specific match first)
        for tok in norm.split():
            if tok not in _TOKEN_INDEX:
                _TOKEN_INDEX[tok] = fa


_build_token_index()


def fa_name_for(en_description: str) -> Optional[str]:
    """Best-effort Persian name for an English food description.

    Strategy (in priority order):
      1. Exact normalized match in EN_FA_MAP
      2. Stem match: drop common USDA preparation/state suffixes from end
         (e.g. "apple, raw" → "apple" → "سیب")
      3. First-token match: first comma-segment first word matches a key
         (e.g. "chicken, breast, ..." → "chicken" → "مرغ")
      4. Longest key that appears as a *phrase boundary* in the description
         (avoids 'water' matching 'tonic water' to 'watermelon' etc.)

    Returns None if no confident match — caller should set
    verificationStatus = NEEDS_VERIFICATION.
    """
    if not en_description:
        return None
    norm = normalize_en(en_description)
    if not norm:
        return None
    norm_c = _normalize_en_with_commas(en_description)

    # 0. Strip leading USDA category prefixes that are noise for Persian mapping.
    # Use the comma-preserving form for this.
    CATEGORY_PREFIXES = [
        "spices, ", "beverages, ", "soups, ", "snacks, ", "sauces, ",
        "sweets, ", "fast foods, ", "meals, ", "restaurant foods, ",
        "baked products, ", "baby foods, ", "breakfast cereals, ",
    ]
    candidates_c = [norm_c]
    for p in CATEGORY_PREFIXES:
        if norm_c.startswith(p):
            candidates_c.append(norm_c[len(p):])
            break

    for cand_c in candidates_c:
        cand = normalize_en(cand_c)  # comma-stripped form for map lookup
        # 1. Exact
        if cand in EN_FA_MAP:
            return EN_FA_MAP[cand]

        # 1b. Try removing common USDA suffixes (one at a time, then combinations)
        SUFFIXES = [
            ", raw", ", cooked", ", boiled", ", fried", ", baked",
            ", steamed", ", grilled", ", roasted", ", fresh", ", dried",
            ", lean", ", fat", ", whole", ", low fat", ", skinless",
            ", boneless", ", with salt", ", without salt",
            ", mature seeds", ", sprouted", ", canned", ", frozen",
            ", ground", ", powder", ", whole grain", ", unenriched",
            ", enriched", ", regular", ", long grain", ", short grain",
            ", medium grain", ", brown", ", white",
        ]
        base = cand
        for suf in SUFFIXES:
            if base.endswith(suf):
                stem = base[: -len(suf)].strip()
                if stem in EN_FA_MAP:
                    return EN_FA_MAP[stem]
                # try stripping one more suffix
                for suf2 in SUFFIXES:
                    if stem.endswith(suf2):
                        stem2 = stem[: -len(suf2)].strip()
                        if stem2 in EN_FA_MAP:
                            return EN_FA_MAP[stem2]

        # 2. First-token (first comma segment, first word)
        first_segment = cand.split(",")[0].strip()
        if first_segment:
            first_tok = first_segment.split()[0]
            if first_tok in EN_FA_MAP:
                return EN_FA_MAP[first_tok]
            # Plural form
            if first_tok.endswith("s") and first_tok[:-1] in EN_FA_MAP:
                return EN_FA_MAP[first_tok[:-1]]
            # Try the full first segment as a key (e.g. "apple juice" → آب سیب)
            if first_segment in EN_FA_MAP:
                return EN_FA_MAP[first_segment]

        # 3. Phrase-boundary substring match (longest key wins).
        matched: list[tuple[int, str]] = []
        head = cand.split(",")[0].strip()
        for en, fa in EN_FA_MAP.items():
            norm_key = normalize_en(en)
            if not norm_key:
                continue
            if head == norm_key:
                matched.append((len(norm_key), fa))
            elif head.startswith(norm_key + " ") or head.startswith(norm_key + ","):
                matched.append((len(norm_key), fa))
        if matched:
            matched.sort(key=lambda x: -x[0])
            return matched[0][1]

    return None


__all__ = [
    "normalize_fa", "normalize_en",
    "EN_FA_MAP", "fa_name_for",
]
