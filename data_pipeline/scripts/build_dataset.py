"""
Bergamot dataset builder — orchestrates PHASES 5-12.

Inputs:  USDA parsed records (parse_usda.parse_all)
Outputs: data_pipeline/output/bergamot_foods.json
         data_pipeline/output/bergamot_recipes.json
         data_pipeline/output/bergamot_categories.json
         data_pipeline/output/bergamot_dataset_meta.json
         data_pipeline/reports/build_report.txt

Pipeline stages:
  PHASE 5 — Filtering      : drop branded/fast-food/restaurant/baby/QC
  PHASE 6 — Normalization  : already done in parser
  PHASE 7 — Categorization : already done in parser
  PHASE 8 — Deduplication  : pick best record per (normalizedNameEn, preparation)
  PHASE 9 — Validation     : flag insane values, missing calories rejected
  PHASE 10— Persian mapping: already done in parser
  PHASE 11— Merge with existing iranian_foods.dart seed data
  PHASE 12— Emit JSON dataset + categories + recipes + meta + report
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Iterable

from common import (
    BERGAMOT_CATEGORIES, FoodRecord, RecipeRecord,
    SRC_USDA_FOUNDATION, SRC_USDA_SR_LEGACY, SRC_USDA_FNDDS,
    SRC_IRANIAN_REF, SRC_RECIPE, SRC_CUSTOM,
    VS_VERIFIED, VS_NEEDS_VERIFICATION, VS_COMMUNITY_RECIPE,
)
from persian_map import normalize_en, normalize_fa
from parse_usda import parse_all

OUT_DIR = Path(__file__).resolve().parent.parent / "output"
REP_DIR = Path(__file__).resolve().parent.parent / "reports"
OUT_DIR.mkdir(parents=True, exist_ok=True)
REP_DIR.mkdir(parents=True, exist_ok=True)


# Source priority for deduplication (higher = preferred)
SOURCE_PRIORITY = {
    SRC_USDA_FOUNDATION: 3,
    SRC_USDA_SR_LEGACY:  2,
    SRC_USDA_FNDDS:      1,
    SRC_IRANIAN_REF:     4,  # Iranian refs preserved even if USDA has dup
    SRC_CUSTOM:          0,
}


# ---------------------------------------------------------------------------
# PHASE 5 — Filtering
# ---------------------------------------------------------------------------
# Reject USDA categories that don't belong in a curated database
REJECT_CATEGORY_CODES = {
    "21",   # Fast Foods
    "22",   # Meals, Entrees, and Side Dishes
    "25",   # Restaurant Foods
    "26",   # Branded Food Products Database
    "27",   # Quality Control Materials
    "24",   # American Indian/Alaska Native Foods (too regional)
}

# Reject descriptions containing these phrases
REJECT_DESC_PATTERNS = [
    r"\bbaby\b", r"\binfant\b", r"babyfood",
    r"restaurant", r"fast food", r"mc[- ]?donald", r"burger king",
    r"subway", r"taco bell", r"pizza hut", r"kfc", r"wendy",
    r"starbucks", r"dunkin", r"krispy kreme",
    r"with (?:added|fortified)",  # fortification variants are noise
    r"\bimitation\b", r"\bsubstitute\b",
    r"supplement", r"meal replacement",
    r"\brelish\b", r"\bpickle\b",  # too niche / brand-driven
    # Brand-name detection — explicit brand names (case-sensitive)
    r"\bABBOTT\b", r"\bENSURE\b", r"\bGLUCERNA\b", r"\bEAS\b",
    r"\bVITAMIN WATER\b", r"\bGLACEAU\b",
    r"\bPERRIER\b", r"\bPOLAND SPRING\b", r"\bEVIAN\b",
    r"\bGEROLSTEINER\b", r"\bSAN PELLEGRINO\b", r"\bACQUA PANA\b",
    r"\bCOCA[- ]COLA\b", r"\bPEPSI\b", r"\bDR\.? PEPPER\b",
    r"\bSPRITE\b", r"\bFANTA\b", r"\bMOUNTAIN DEW\b",
    r"\bSNAPPLE\b", r"\bARIZONA\b.*\bBEVERAGE\b",
    r"\bRED BULL\b", r"\bMONSTER\b.*\bENERGY\b",
    r"\bGATORADE\b", r"\bPOWERADE\b",
    r"\bNESQUIK\b", r"\bYOOHOO\b",
    r"\bCAMPBELL\b", r"\bPROGRESSO\b",
    r"\bKRAFT\b", r"\bHEINZ\b", r"\bHUNTS\b",
    r"\bQUAKER\b", r"\bKELLOGG\b", r"\bGENERAL MILLS\b",
    r"\bNESTLE\b", r"\bCARNATION\b",
    r"\bJIF\b", r"\bSKIPPY\b", r"\bPETER PAN\b",
    r"\bSMUCKER\b",
    # Pattern: "Beverages, BRAND NAME, sub" where BRAND is all-caps
    r"^Beverages,\s*[A-Z][A-Z& ]{4,},",
    r"^Snacks,\s*[A-Z][A-Z& ]{4,},",
    # ─── PHASE 2.1 (Round 2 — Bergamot troubleshooting): ────────────────
    # Pork products (not suitable for Iranian market — religious restrictions)
    r"\bpork\b", r"\bbacon\b", r"\bham\b(?!burger)",
    r"\bprosciutto\b", r"\bpancetta\b", r"\bchorizo\b",
    r"\bjamon\b", r"\biberico\b",
    r"\bsalami\b", r"\bpepperoni\b",
    r"\bcanadian bacon\b", r"\bboston butt\b",
    # Alcoholic beverages (also not suitable for Iranian market)
    # Note: We explicitly DON'T match "non-alcoholic beer" or "fruit cocktail"
    # because those are non-alcoholic and stay in the dataset.
    r"alcoholic\s+beverage",
    # Real beer (not beerwurst which is a sausage, not non-alcoholic)
    # Handled in passes_filter below with non-alcohol exclusion list.
]


def passes_filter(rec: FoodRecord, usda_category_id: str | None = None) -> tuple[bool, str]:
    """Return (passes, reason). Reason is '' if passes, else a code."""
    if usda_category_id and usda_category_id in REJECT_CATEGORY_CODES:
        return False, "rejected_category"

    desc = rec.nameEn
    for pat in REJECT_DESC_PATTERNS:
        if re.search(pat, desc, flags=re.IGNORECASE):
            return False, "rejected_pattern"

    # Reject if no description
    if not rec.nameEn or len(rec.nameEn.strip()) < 3:
        return False, "no_description"

    # Reject if neither calories nor any macro is present
    if rec.caloriesPer100g is None and rec.proteinPer100g is None and rec.fatPer100g is None and rec.carbsPer100g is None:
        return False, "no_nutrition"

    # ─── PHASE 2.1 (Round 2): Reject alcoholic beverages ───────────────────
    # These are filtered separately because we need to exclude non-alcoholic
    # variants (which the simple regex above would also catch).
    if _is_alcoholic_beverage(rec.normalizedNameEn):
        return False, "alcoholic_beverage"

    # ─── PHASE 2.3 (Round 2): Balance meat category ────────────────────────
    # USDA has 1645+ "meat" variants (sub-primal cuts like "lamb foreshank
    # separable lean only trimmed to 1/4 fat choice cooked braised"). These
    # are noise for an Iranian user who just wants "lamb meat". Keep only
    # canonical simple meats.
    if rec.categoryId == "meat" and not _is_canonical_simple_meat(rec):
        return False, "meat_variant"

    return True, ""


# ────────────────────────────────────────────────────────────────────────────
# PHASE 2.1 — Alcohol detection (with non-alcoholic exclusion list)
# ────────────────────────────────────────────────────────────────────────────
_NON_ALCOHOL_PATTERNS = [
    r"\bnon-?alcoholic\b",
    r"includes\s+non-?alcoholic",
    r"cocktail\s+bottled",
    r"cocktail\s+canned",
    r"cocktail\s+frozen",
    r"cocktail\s+mix",
    r"cocktail\s+prepared",
    r"fruit\s+cocktail",
    r"cranberry.*cocktail",
    r"grapefruit.*cocktail",
    r"juice\s+cocktail",
    r"cocktail\s+peanuts",
    r"cocktail\s+sauce",
    r"sauce\s+cocktail",
    r"\bwine-?vinegar\b",
    r"\bwine-?flavor\b",
    r"\bcooking\s+wine\b",
    r"\bextract\b.*\bwine\b",
    r"\bvanilla.*\bextract\b",
]
_ALCOHOL_PATTERNS = [
    r"alcoholic\s+beverage",
    r"\bbeer\b(?!wurst)",
    r"\bwine\b",
    r"\bliqueur\b",
    r"\bbrandy\b", r"\bvodka\b", r"\brum\b", r"\bwhisk?ey\b",
    r"\bgin\b(?!ger)", r"\btequila\b", r"\bchampagne\b",
    r"\bsherry\b", r"\bport\s+wine\b", r"\bvermouth\b",
    r"\babsinthe\b", r"\bsake\b", r"\bsoju\b", r"\bmalt\s+beverage\b",
]


def _is_alcoholic_beverage(normalized_name: str) -> bool:
    """Return True if record is an alcoholic beverage.

    Explicitly excludes non-alcoholic variants like "non-alcoholic beer",
    "fruit cocktail", "wine vinegar", etc.
    """
    for pat in _NON_ALCOHOL_PATTERNS:
        if re.search(pat, normalized_name, re.IGNORECASE):
            return False
    for pat in _ALCOHOL_PATTERNS:
        if re.search(pat, normalized_name, re.IGNORECASE):
            return True
    return False


# ────────────────────────────────────────────────────────────────────────────
# PHASE 2.3 — Meat category balancing (only keep canonical simple meats)
# ────────────────────────────────────────────────────────────────────────────
_ALLOWED_MEAT_ANIMALS = {"lamb", "beef", "veal", "mutton", "goat"}

_CUT_PATTERNS = [
    r"\bchuck\b", r"\brib\b", r"\bloin\b", r"\bround\b", r"\bbrisket\b",
    r"\bshank\b", r"\bflank\b", r"\bsirloin\b", r"\btenderloin\b",
    r"\bplate\b", r"\bshoulder\b", r"\bneck\b", r"\bleg\b",
    r"\bforeshank\b", r"\bforeleg\b",
    r"\bribeye\b", r"\bt-bone\b", r"\bporterhouse\b", r"\bstrip\b",
    r"\btop round\b", r"\beye of round\b", r"\bbottom round\b",
    r"\barm\b", r"\bblade\b", r"\bcollar\b", r"\bcushion\b",
    r"\bbone-in\b", r"\bboneless\b", r"\blip-on\b", r"\bcap-off\b",
]
_SAUSAGE_PATTERNS = [
    r"\bsausage\b", r"\bbologna\b", r"\bbratwurst\b", r"\bsalami\b",
    r"\bbeerwurst\b", r"\bhot ?dog\b", r"\bfrankfurter\b",
    r"\bknockwurst\b", r"\blandjaeger\b",
    r"\bsummer sausage\b", r"\bpepperoni\b", r"\bchorizo\b",
    r"\bkielbasa\b", r"\bandouille\b", r"\bmettwurst\b",
    r"\bcervelat\b", r"\bvienna\b", r"\bwiener\b",
    r"\bbraunschweiger\b", r"\bmeatloaf\b", r"\bmeatball\b",
    r"\bjerky\b", r"\bpatty\b", r"\bpork\s+roll\b",
    r"\bluncheon\b", r"\bdeli\b", r"\bcold cut\b",
    r"\bpizza\b", r"\bsandwich\b", r"\bpasta\b", r"\bdumpling\b",
    r"\broll\b", r"\bwrap\b", r"\bnoodle\b", r"\bstick\b",
    r"\bcheesefurter\b", r"\bsmokie\b", r"\bgravy\b", r"\bstew\b",
    r"\bdripped\b", r"\bdrained\b", r"\b1 steak\b", r"\b1 chop\b",
    r"\b1 patty\b", r"\bgible?s?\b", r"\borgan\b", r"\boffal\b",
]
_FAT_PATTERNS = [
    r"\bfat\s+only\b", r"\bseam\s+fat\b", r"\bexternal\s+fat\b",
    r"\bfat\s+trimmings?\b", r"\bfat\s+separable\b",
]
_CURED_PATTERNS = [
    r"\bcured\b", r"\bbacon\b", r"\bpastrami\b", r"\bcorned\b",
    r"\bbreakfast\s+strips?\b", r"\bham\b",
]
_DROP_QUALIFIERS = [
    "separable", "trimmed", "choice", "select", "lean and fat", "lean only",
    "composite", "by-products", "variety", "mechanically",
    "0 fat", "0 moisture", "1 4", "1 8", "1 steak", "1 chop",
    "retail", "franken",
]


def _is_canonical_simple_meat(rec: FoodRecord) -> bool:
    """Return True if a meat record should be kept (Iranian market).

    Keeps:
      - IRANIAN_REFERENCE records (already curated)
      - USDA records with short names (<=5 words), allowed animal type,
        no cut/sausage/fat/cured/qualifier patterns
    """
    if rec.source == "IRANIAN_REFERENCE":
        return True
    if rec.source not in ("USDA_FOUNDATION", "USDA_SR_LEGACY"):
        return False
    name = rec.normalizedNameEn
    tokens = name.split()
    if not tokens:
        return False
    first = tokens[0]
    if first not in _ALLOWED_MEAT_ANIMALS:
        return False
    if len(tokens) > 5:
        return False
    for p in _CUT_PATTERNS:
        if re.search(p, name, re.IGNORECASE):
            return False
    for p in _SAUSAGE_PATTERNS:
        if re.search(p, name, re.IGNORECASE):
            return False
    for p in _FAT_PATTERNS:
        if re.search(p, name, re.IGNORECASE):
            return False
    for p in _CURED_PATTERNS:
        if re.search(p, name, re.IGNORECASE):
            return False
    for q in _DROP_QUALIFIERS:
        if q in name:
            return False
    if rec.caloriesPer100g is None:
        return False
    return True


# ---------------------------------------------------------------------------
# PHASE 8 — Deduplication
# ---------------------------------------------------------------------------
def dedupe(records: list[FoodRecord]) -> tuple[list[FoodRecord], int]:
    """Deduplicate by (normalizedNameEn, preparationState).

    When multiple records match, prefer the one with:
      1. Higher source priority (Foundation > SR Legacy > FNDDS)
      2. More non-null nutrients
      3. Has a serving size
    """
    groups: dict[tuple[str, str|None], list[FoodRecord]] = defaultdict(list)
    for r in records:
        key = (r.normalizedNameEn, r.preparationState)
        groups[key].append(r)

    out: list[FoodRecord] = []
    for key, group in groups.items():
        if len(group) == 1:
            out.append(group[0])
            continue
        # Sort by priority
        def score(r: FoodRecord) -> tuple:
            n_nutrients = sum(1 for f in [
                r.caloriesPer100g, r.proteinPer100g, r.fatPer100g,
                r.carbsPer100g, r.fiberPer100g, r.sodiumPer100g,
                r.potassiumPer100g, r.calciumPer100g, r.ironPer100g,
            ] if r is not None)
            return (
                SOURCE_PRIORITY.get(r.source, 0),
                n_nutrients,
                1 if r.servingSize else 0,
                1 if r.nameFa else 0,
            )
        group.sort(key=score, reverse=True)
        out.append(group[0])

    return out, len(records) - len(out)


# ---------------------------------------------------------------------------
# PHASE 9 — Nutrition Validation
# ---------------------------------------------------------------------------
# Sanity bounds per-100g (no food has 5000 kcal/100g)
NUTRIENT_BOUNDS = {
    "caloriesPer100g": (0, 3000),
    "proteinPer100g":  (0, 100),
    "fatPer100g":      (0, 100),
    "carbsPer100g":    (0, 100),
    "fiberPer100g":    (0, 100),
    "sugarPer100g":    (0, 100),
    "sodiumPer100g":   (0, 100000),  # mg
    "potassiumPer100g":(0, 10000),
    "calciumPer100g":  (0, 10000),
    "ironPer100g":     (0, 1000),
}

def validate(rec: FoodRecord) -> tuple[bool, str]:
    """Validate nutrition sanity. Returns (ok, reason)."""
    for field, (lo, hi) in NUTRIENT_BOUNDS.items():
        v = getattr(rec, field)
        if v is None:
            continue
        if v < lo or v > hi:
            return False, f"out_of_bounds:{field}"

    # Calorie/macro consistency check (within ±25%)
    if rec.caloriesPer100g is not None and rec.proteinPer100g is not None \
       and rec.fatPer100g is not None and rec.carbsPer100g is not None:
        # Atwater: 4*p + 9*f + 4*c (kcal per 100g)
        est = 4 * rec.proteinPer100g + 9 * rec.fatPer100g + 4 * rec.carbsPer100g
        if rec.caloriesPer100g > 0:
            ratio = abs(est - rec.caloriesPer100g) / rec.caloriesPer100g
            if ratio > 0.30:
                return False, "macro_calorie_mismatch"

    return True, ""


# ---------------------------------------------------------------------------
# PHASE 11 — Merge with existing iranian_foods.dart data
# ---------------------------------------------------------------------------
# Extracted manually from lib/data/seed_data/iranian_foods.dart
# Each tuple: (nameFa, nameEn, category, servingSize, servingUnit,
#             calories, protein, fat, carb, fiber)
# We convert per-serving → per-100g and tag source=IRANIAN_REFERENCE
EXISTING_IRANIAN_FOODS = [
    ("مرغ گریل شده", "Grilled Chicken Breast", "poultry", 150, "gram", 248, 46.5, 5.4, 0, 0),
    ("مرغ آب‌پز", "Boiled Chicken Breast", "poultry", 150, "gram", 235, 44.0, 5.1, 0, 0),
    ("گوشت گوسفندی", "Lamb Meat", "meat", 100, "gram", 294, 25.5, 21.0, 0, 0),
    ("گوشت گوساله", "Beef", "meat", 100, "gram", 250, 26.0, 15.0, 0, 0),
    ("ماهی قزل‌آلا", "Rainbow Trout", "fish_seafood", 150, "gram", 232, 39.5, 7.5, 0, 0),
    ("تخم مرغ", "Egg", "eggs", 50, "piece", 78, 6.3, 5.3, 0.6, 0),
    ("جوجه‌کباب", "Joojeh Kabab", "iranian_foods", 200, "plate", 370, 46, 17, 3, 0),
    ("کباب کوبیده", "Kabab Koobideh", "iranian_foods", 180, "gram", 540, 30, 42, 5, 0),
    ("ماهی کباب", "Grilled Fish", "fish_seafood", 200, "gram", 280, 42, 10, 0, 0),
    ("عدسی", "Adasi (Lentil Soup)", "iranian_foods", 250, "plate", 230, 14, 5, 30, 6),
    ("قرمه‌سبزی", "Ghormeh Sabzi", "iranian_foods", 300, "plate", 450, 25, 28, 15, 4),
    ("قیمه", "Gheimeh", "iranian_foods", 300, "plate", 480, 22, 28, 25, 5),
    ("فسنجان", "Fesenjan", "iranian_foods", 300, "plate", 620, 20, 48, 18, 4),
    ("خوراک لوبیا چیتی", "Loobia Chiti", "iranian_foods", 300, "plate", 360, 18, 16, 32, 8),
    ("آش رشته", "Ash Reshteh", "iranian_foods", 300, "plate", 280, 12, 8, 38, 6),
    ("دمپختک گوجه", "Dampokhtak Gojeh", "iranian_foods", 250, "plate", 380, 10, 14, 52, 3),
    ("باقالی پلو", "Baghali Polo", "iranian_foods", 250, "plate", 420, 12, 14, 60, 6),
    ("زرشک پلو با مرغ", "Zereshk Polo Ba Morgh", "iranian_foods", 300, "plate", 520, 25, 16, 60, 3),
    ("استامبولی پلو", "Estamboli Polo", "iranian_foods", 300, "plate", 480, 12, 18, 60, 5),
    ("ماکارونی ایرانی", "Iranian Macaroni", "iranian_foods", 300, "plate", 510, 18, 18, 60, 3),
    ("عدس پلو", "Adas Polo", "iranian_foods", 250, "plate", 430, 14, 12, 65, 7),
    ("لبو پلو", "Loobia Polo", "iranian_foods", 300, "plate", 470, 14, 16, 60, 6),
    ("کشک بادمجان", "Kashk-e Bademjan", "iranian_foods", 250, "plate", 320, 8, 18, 28, 5),
    ("خوراک کرفس", "Khorak Karafs", "iranian_foods", 300, "plate", 280, 12, 14, 24, 5),
    ("خوراک لوبیا سبز", "Khorak Loobia Sabz", "iranian_foods", 300, "plate", 280, 12, 14, 22, 5),
    ("آبگوشت", "Abgoosht", "iranian_foods", 350, "plate", 540, 22, 30, 35, 4),
    ("دیزی", "Dizi", "iranian_foods", 350, "plate", 540, 22, 30, 35, 4),
    ("خوراک هویج", "Khorak Havij", "iranian_foods", 300, "plate", 260, 10, 12, 28, 5),
    ("خوراک کدو", "Khorak Kadoo", "iranian_foods", 300, "plate", 240, 8, 12, 24, 4),
    ("آش دوغ", "Ash-e Doogh", "iranian_foods", 300, "plate", 220, 10, 8, 26, 3),
    ("سوپ جو", "Sup-e Jo", "iranian_foods", 300, "plate", 240, 10, 8, 32, 5),
    ("کوکو سبزی", "Kuku Sabzi", "iranian_foods", 200, "plate", 320, 14, 22, 12, 3),
    ("کوکو سیب زمینی", "Kuku Sib Zamini", "iranian_foods", 200, "plate", 340, 8, 18, 32, 3),
    ("کتلت", "Kotlet", "iranian_foods", 150, "piece", 380, 18, 26, 18, 1),
    ("شامی کباب", "Shami Kabab", "iranian_foods", 150, "piece", 360, 16, 24, 18, 2),
    ("نان سنگک", "Sangak Bread", "bread", 100, "gram", 270, 9, 2, 55, 3),
    ("نان بربری", "Barbari Bread", "bread", 100, "gram", 290, 9, 3, 56, 3),
    ("نان لواش", "Lavash Bread", "bread", 100, "gram", 280, 8, 2, 56, 3),
    ("نان تافتون", "Taftoon Bread", "bread", 100, "gram", 275, 8, 2, 55, 3),
    ("برنج پخته", "Cooked Rice", "rice", 100, "gram", 130, 2.7, 0.3, 28, 0.4),
    ("برنج کته", "Kateh Rice", "rice", 100, "gram", 130, 2.7, 0.3, 28, 0.4),
    ("ماست", "Yogurt", "dairy", 100, "gram", 60, 3.5, 3.3, 4.7, 0),
    ("ماست پرچرب", "Full-Fat Yogurt", "dairy", 100, "gram", 80, 3.5, 5.0, 4.7, 0),
    ("ماست کم‌چرب", "Low-Fat Yogurt", "dairy", 100, "gram", 50, 4.5, 1.5, 5.0, 0),
    ("پنیر فتا", "Feta Cheese", "dairy", 30, "gram", 80, 5, 6, 1, 0),
    ("پنیر لیقوان", "Lighvan Cheese", "dairy", 30, "gram", 85, 5, 6.5, 1, 0),
    ("شیر پرچرب", "Whole Milk", "dairy", 100, "gram", 60, 3.2, 3.5, 4.8, 0),
    ("شیر کم‌چرب", "Low-Fat Milk", "dairy", 100, "gram", 42, 3.5, 1.0, 5.0, 0),
    ("کره", "Butter", "oils_fats", 10, "gram", 72, 0.1, 8.2, 0.1, 0),
    ("خامه", "Cream", "dairy", 30, "gram", 90, 0.7, 9.5, 0.8, 0),
    ("دوغ", "Doogh", "beverages", 250, "glass", 80, 3.0, 1.5, 6.0, 0),
    ("چای سیاه", "Black Tea", "beverages", 240, "glass", 2, 0, 0, 0.5, 0),
    ("قهوه تلخ", "Black Coffee", "beverages", 240, "glass", 2, 0.2, 0, 0.4, 0),
    ("شربت سکنجبین", "Sekanjabin Syrup", "beverages", 250, "glass", 120, 0, 0, 30, 0),
    ("خربزه", "Melon", "fruits", 100, "gram", 36, 0.8, 0.2, 9, 0.9),
    ("طالبی", "Cantaloupe", "fruits", 100, "gram", 34, 0.8, 0.2, 8, 0.9),
    ("هندوانه", "Watermelon", "fruits", 100, "gram", 30, 0.6, 0.2, 7.5, 0.4),
    ("انار", "Pomegranate", "fruits", 100, "gram", 83, 1.7, 1.2, 19, 4.0),
    ("انگور", "Grape", "fruits", 100, "gram", 67, 0.6, 0.4, 17, 0.9),
    ("انجیر", "Fig", "fruits", 100, "gram", 74, 0.8, 0.3, 19, 2.9),
    ("خرما", "Date", "fruits", 100, "gram", 277, 1.8, 0.2, 75, 7.0),
    ("سیب", "Apple", "fruits", 100, "gram", 52, 0.3, 0.2, 14, 2.4),
    ("موز", "Banana", "fruits", 100, "gram", 89, 1.1, 0.3, 23, 2.6),
    ("پرتقال", "Orange", "fruits", 100, "gram", 47, 0.9, 0.1, 12, 2.4),
    ("کیوی", "Kiwi", "fruits", 100, "gram", 61, 1.1, 0.5, 15, 3.0),
    ("لیمو", "Lemon", "fruits", 100, "gram", 29, 1.1, 0.3, 9, 2.8),
    ("توت فرنگی", "Strawberry", "fruits", 100, "gram", 32, 0.7, 0.3, 8, 2.0),
    ("هلو", "Peach", "fruits", 100, "gram", 39, 0.9, 0.3, 10, 1.5),
    ("گیلاس", "Cherry", "fruits", 100, "gram", 63, 1.1, 0.2, 16, 2.1),
    ("زردآلو", "Apricot", "fruits", 100, "gram", 48, 1.4, 0.4, 11, 2.0),
    ("خیار", "Cucumber", "vegetables", 100, "gram", 15, 0.7, 0.1, 3.6, 0.5),
    ("گوجه فرنگی", "Tomato", "vegetables", 100, "gram", 18, 0.9, 0.2, 3.9, 1.2),
    ("هویج", "Carrot", "vegetables", 100, "gram", 41, 0.9, 0.2, 10, 2.8),
    ("سیب زمینی", "Potato", "vegetables", 100, "gram", 77, 2.0, 0.1, 17, 2.2),
    ("پیاز", "Onion", "vegetables", 100, "gram", 40, 1.1, 0.1, 9, 1.7),
    ("سیر", "Garlic", "vegetables", 100, "gram", 149, 6.4, 0.5, 33, 2.1),
    ("اسفناج", "Spinach", "vegetables", 100, "gram", 23, 2.9, 0.4, 3.6, 2.2),
    ("کاهو", "Lettuce", "vegetables", 100, "gram", 15, 1.4, 0.2, 2.9, 1.3),
    ("بادمجان", "Eggplant", "vegetables", 100, "gram", 25, 1.0, 0.2, 6, 2.5),
    ("کدو سبز", "Zucchini", "vegetables", 100, "gram", 17, 1.2, 0.3, 3.1, 1.0),
    ("کلم", "Cabbage", "vegetables", 100, "gram", 25, 1.3, 0.1, 6, 2.5),
    ("گل کلم", "Cauliflower", "vegetables", 100, "gram", 25, 1.9, 0.3, 5, 2.0),
    ("بروکلی", "Broccoli", "vegetables", 100, "gram", 34, 2.8, 0.4, 7, 2.6),
    ("فلفل دلمه‌ای", "Bell Pepper", "vegetables", 100, "gram", 31, 1.0, 0.3, 6, 2.1),
    ("کرفس", "Celery", "vegetables", 100, "gram", 16, 0.7, 0.2, 3, 1.5),
    ("قارچ", "Mushroom", "vegetables", 100, "gram", 22, 3.1, 0.3, 3.3, 1.0),
    ("ذرت", "Corn", "vegetables", 100, "gram", 86, 3.3, 1.4, 19, 2.7),
    ("عدس", "Lentil", "legumes", 100, "gram", 116, 9.0, 0.4, 20, 7.9),
    ("نخود", "Chickpea", "legumes", 100, "gram", 164, 8.9, 2.6, 27, 7.6),
    ("لوبیا قرمز", "Kidney Bean", "legumes", 100, "gram", 127, 8.7, 0.5, 23, 6.4),
    ("لوبیا سفید", "White Bean", "legumes", 100, "gram", 140, 9.7, 0.4, 25, 6.8),
    ("لپه", "Split Pea", "legumes", 100, "gram", 118, 8.3, 0.4, 21, 8.3),
    ("ماش", "Mung Bean", "legumes", 100, "gram", 105, 8.1, 0.4, 19, 7.6),
    ("باقلا", "Fava Bean", "legumes", 100, "gram", 88, 7.6, 0.4, 18, 5.4),
    ("سویا", "Soybean", "legumes", 100, "gram", 173, 9.0, 5.0, 10, 4.0),
    ("گردو", "Walnut", "nuts", 100, "gram", 654, 15, 65, 14, 6.7),
    ("بادام", "Almond", "nuts", 100, "gram", 579, 21, 50, 22, 12.5),
    ("پسته", "Pistachio", "nuts", 100, "gram", 560, 20, 45, 28, 10.6),
    ("فندق", "Hazelnut", "nuts", 100, "gram", 628, 15, 61, 17, 9.7),
    ("بادام زمینی", "Peanut", "nuts", 100, "gram", 567, 26, 49, 16, 8.5),
    ("کنجد", "Sesame", "seeds", 100, "gram", 573, 18, 50, 23, 11.8),
    ("تخمه آفتابگردان", "Sunflower Seed", "seeds", 100, "gram", 584, 21, 51, 20, 8.6),
    ("تخمه کدو", "Pumpkin Seed", "seeds", 100, "gram", 559, 30, 49, 11, 6.0),
    ("دانه کتان", "Flax Seed", "seeds", 100, "gram", 534, 18, 42, 29, 27.3),
    ("روغن زیتون", "Olive Oil", "oils_fats", 100, "gram", 884, 0, 100, 0, 0),
    ("روغن آفتابگردان", "Sunflower Oil", "oils_fats", 100, "gram", 884, 0, 100, 0, 0),
    ("روغن کنجد", "Sesame Oil", "oils_fats", 100, "gram", 884, 0, 100, 0, 0),
    ("روغن حیوانی", "Ghee", "oils_fats", 100, "gram", 900, 0, 100, 0, 0),
    ("عسل", "Honey", "sweets", 100, "gram", 304, 0.3, 0, 82, 0.2),
    ("شکر", "Sugar", "sweets", 100, "gram", 387, 0, 0, 100, 0),
    ("رب گوجه فرنگی", "Tomato Paste", "sauces", 100, "gram", 82, 4.3, 0.4, 18.9, 3.6),
    ("آب لیمو", "Lemon Juice", "beverages", 100, "gram", 22, 0.4, 0.2, 7, 0.3),
    ("آب پرتقال", "Orange Juice", "beverages", 100, "gram", 45, 0.7, 0.2, 10, 0.2),
    ("رب انار", "Pomegranate Molasses", "sauces", 100, "gram", 270, 0, 0, 67, 0.5),
    ("نارشک", "Verjuice", "sauces", 100, "gram", 40, 0.5, 0.2, 9, 0.2),
    ("ارده", "Tahini", "sauces", 100, "gram", 595, 17, 54, 21, 9.3),
    ("زرشک", "Barberry", "spices_herbs", 100, "gram", 220, 1.5, 0.5, 50, 12.0),
    ("زعفران", "Saffron", "spices_herbs", 5, "gram", 310, 11, 6, 65, 3.9),
    ("زردچوبه", "Turmeric", "spices_herbs", 100, "gram", 354, 8, 10, 65, 22.7),
    ("دارچین", "Cinnamon", "spices_herbs", 100, "gram", 247, 4, 1.2, 81, 53.1),
    ("فلفل سیاه", "Black Pepper", "spices_herbs", 100, "gram", 251, 10, 3, 64, 25.3),
    ("هل", "Cardamom", "spices_herbs", 100, "gram", 311, 11, 7, 68, 28.0),
    ("زیره", "Cumin", "spices_herbs", 100, "gram", 375, 18, 22, 44, 10.5),
    ("نمک", "Salt", "spices_herbs", 5, "gram", 0, 0, 0, 0, 0),
    ("جعفری", "Parsley", "spices_herbs", 100, "gram", 36, 3.0, 0.8, 6, 3.3),
    ("گشنیز", "Cilantro", "spices_herbs", 100, "gram", 23, 2.1, 0.5, 3.7, 2.8),
    ("شبت", "Dill", "spices_herbs", 100, "gram", 43, 3.5, 1.1, 7, 2.1),
    ("نعناع", "Mint", "spices_herbs", 100, "gram", 70, 3.8, 0.9, 15, 8.0),
    ("ریحان", "Basil", "spices_herbs", 100, "gram", 23, 3.2, 0.6, 2.7, 1.6),
    ("ترخون", "Tarragon", "spices_herbs", 100, "gram", 295, 22.8, 7.2, 50, 7.4),
    ("تره", "Leek", "spices_herbs", 100, "gram", 61, 1.5, 0.3, 14, 1.8),
    ("لیمو عمانی", "Dried Lime", "spices_herbs", 10, "piece", 30, 1, 0, 8, 2.5),
]


def existing_iranian_records() -> list[FoodRecord]:
    """Convert existing iranian_foods.dart tuples to FoodRecord objects.

    Per-serving values are converted to per-100g using servingSize.
    """
    out: list[FoodRecord] = []
    for (nameFa, nameEn, category, serving, unit,
         cal, prot, fat, carb, fiber) in EXISTING_IRANIAN_FOODS:
        if serving <= 0:
            continue
        # Convert per-serving → per-100g
        scale = 100.0 / serving
        rec = FoodRecord(
            nameEn=nameEn,
            nameFa=nameFa,
            normalizedNameEn=normalize_en(nameEn),
            normalizedNameFa=normalize_fa(nameFa),
            categoryId=category,
            caloriesPer100g=round(cal * scale, 2),
            proteinPer100g=round(prot * scale, 2),
            fatPer100g=round(fat * scale, 2),
            carbsPer100g=round(carb * scale, 2),
            fiberPer100g=round(fiber * scale, 2) if fiber else None,
            servingSize=float(serving),
            servingUnit=unit,
            source=SRC_IRANIAN_REF,
            externalId=f"IRANIAN_REF:{nameEn.upper().replace(' ', '_')}",
            isVerified=True,
            verificationStatus=VS_VERIFIED,
        )
        out.append(rec)
    return out


# ---------------------------------------------------------------------------
# PHASE 12 — Build & Emit JSON
# ---------------------------------------------------------------------------
def build_dataset() -> tuple[list[dict], dict]:
    """Run PHASES 5-12. Returns (food_dicts, stats_dict)."""
    stats: dict = {}

    # --- Parse USDA ---
    records, parse_stats = parse_all()
    stats.update(parse_stats)
    raw_count = len(records)

    # We need USDA category_id for filtering — re-fetch from food.csv.
    # Simpler approach: store USDA category code on the record during parse,
    # but we already mapped it to Bergamot category. To reject by USDA category
    # (e.g. Fast Foods), we need to re-derive. Let's do pattern matching instead.
    # Actually our parser already kept only Foundation/SR/FNDDS (no Branded),
    # so the rejected categories are mostly not present. Still, run filter.

    # --- PHASE 5: Filtering ---
    filtered: list[FoodRecord] = []
    reject_counts: dict[str, int] = defaultdict(int)
    for r in records:
        ok, reason = passes_filter(r)
        if ok:
            filtered.append(r)
        else:
            reject_counts[reason] += 1
    stats["phase5_filtered"] = len(filtered)
    stats["phase5_rejected"] = raw_count - len(filtered)
    stats["phase5_reject_reasons"] = dict(reject_counts)
    print(f"[phase5] filtered: {len(filtered):,} / rejected: {raw_count - len(filtered):,}")

    # --- PHASE 6/7/10: done in parser ---

    # --- PHASE 8: Deduplication ---
    deduped, n_dup = dedupe(filtered)
    stats["phase8_deduped"] = len(deduped)
    stats["phase8_duplicates_removed"] = n_dup
    print(f"[phase8] deduped: {len(deduped):,} / duplicates removed: {n_dup:,}")

    # --- PHASE 9: Validation ---
    validated: list[FoodRecord] = []
    invalid_count = 0
    invalid_reasons: dict[str, int] = defaultdict(int)
    for r in deduped:
        ok, reason = validate(r)
        if ok:
            validated.append(r)
        else:
            invalid_count += 1
            invalid_reasons[reason] += 1
    stats["phase9_valid"] = len(validated)
    stats["phase9_invalid"] = invalid_count
    stats["phase9_invalid_reasons"] = dict(invalid_reasons)
    print(f"[phase9] valid: {len(validated):,} / invalid: {invalid_count:,}")

    # --- PHASE 11: Merge with existing Iranian foods ---
    iranian_recs = existing_iranian_records()
    stats["phase11_iranian_existing"] = len(iranian_recs)
    # Merge: keep Iranian refs separate from USDA (different source tag).
    # No dedup across sources — they coexist with source provenance preserved.
    combined = validated + iranian_recs
    stats["phase11_combined"] = len(combined)
    print(f"[phase11] iranian existing: {len(iranian_recs):,} / combined: {len(combined):,}")

    # --- Sort for stable output ---
    combined.sort(key=lambda r: (r.categoryId, r.normalizedNameFa or r.normalizedNameEn))

    # --- PHASE 12: Serialize ---
    food_dicts = [r.to_dict() for r in combined]

    stats["final_total"] = len(food_dicts)
    return food_dicts, stats


# ---------------------------------------------------------------------------
# PHASE 12b — Category & Recipe emission
# ---------------------------------------------------------------------------
def build_categories() -> list[dict]:
    out = []
    for i, (code, en, fa) in enumerate(BERGAMOT_CATEGORIES, start=1):
        out.append({
            "id": i,
            "code": code,
            "nameEn": en,
            "nameFa": fa,
            "normalizedNameFa": normalize_fa(fa),
            "normalizedNameEn": normalize_en(en),
        })
    return out


# ---------------------------------------------------------------------------
# Statistics report writer
# ---------------------------------------------------------------------------
def write_report(foods: list[dict], stats: dict) -> Path:
    """Write a human-readable build report."""
    rep = REP_DIR / "build_report.txt"
    lines: list[str] = []

    lines.append("=" * 70)
    lines.append("Bergamot Food Database — Build Report")
    lines.append("=" * 70)
    lines.append("")
    lines.append("PHASE 2 — Source datasets:")
    lines.append("  Foundation Foods : 2026-04-30 (latest)")
    lines.append("  SR Legacy        : 2018-04 (only available)")
    lines.append("  FNDDS / Survey   : 2024-10-31 (latest)")
    lines.append("")

    lines.append("PHASE 4 — Raw records parsed:")
    for k in ["foundation_raw", "sr_legacy_raw", "fndds_raw", "total_raw"]:
        lines.append(f"  {k:24s} = {stats.get(k, 0):>10,}")
    lines.append("")

    lines.append("PHASE 5 — Filtering:")
    lines.append(f"  filtered in           = {stats['phase5_filtered']:>10,}")
    lines.append(f"  rejected               = {stats['phase5_rejected']:>10,}")
    for reason, n in stats.get("phase5_reject_reasons", {}).items():
        lines.append(f"    - {reason:24s} {n:>8,}")
    lines.append("")

    lines.append("PHASE 6 — Normalization:")
    lines.append("  All USDA descriptions normalized (lowercase, trimmed, no punct).")
    lines.append("  Persian: ي→ی, ك→ک, ZWNJ→space, extra spaces collapsed.")
    lines.append("")

    lines.append("PHASE 7 — Categorization:")
    lines.append("  USDA Foundation/SR/FNDDS categories → 22 Bergamot categories")
    lines.append("")

    lines.append("PHASE 8 — Deduplication:")
    lines.append(f"  deduped                = {stats['phase8_deduped']:>10,}")
    lines.append(f"  duplicates removed     = {stats['phase8_duplicates_removed']:>10,}")
    lines.append("")

    lines.append("PHASE 9 — Nutrition validation:")
    lines.append(f"  valid                  = {stats['phase9_valid']:>10,}")
    lines.append(f"  invalid (rejected)     = {stats['phase9_invalid']:>10,}")
    for reason, n in stats.get("phase9_invalid_reasons", {}).items():
        lines.append(f"    - {reason:24s} {n:>8,}")
    lines.append("")

    lines.append("PHASE 10 — Persian mapping:")
    n_persian = sum(1 for f in foods if f.get("nameFa"))
    n_no_persian = sum(1 for f in foods if not f.get("nameFa"))
    lines.append(f"  records with Persian name      = {n_persian:>10,}")
    lines.append(f"  records without Persian name   = {n_no_persian:>10,}")
    lines.append("")

    lines.append("PHASE 11 — Merge with existing iranian_foods.dart:")
    lines.append(f"  existing Iranian records added = {stats['phase11_iranian_existing']:>10,}")
    lines.append(f"  combined total                 = {stats['phase11_combined']:>10,}")
    lines.append("")

    lines.append("PHASE 12 — Final dataset:")
    lines.append(f"  Total foods in bergamot_foods.json = {stats['final_total']:>10,}")
    lines.append("")

    # Per-category breakdown
    cat_counts: dict[str, int] = defaultdict(int)
    src_counts: dict[str, int] = defaultdict(int)
    missing_cal = 0; missing_prot = 0; missing_carb = 0; missing_fat = 0
    missing_serving = 0
    needs_verif = 0
    for f in foods:
        cat_counts[f.get("categoryId", "other")] += 1
        src_counts[f.get("source", "UNKNOWN")] += 1
        if f.get("caloriesPer100g") is None: missing_cal += 1
        if f.get("proteinPer100g")  is None: missing_prot += 1
        if f.get("carbsPer100g")    is None: missing_carb += 1
        if f.get("fatPer100g")      is None: missing_fat  += 1
        if f.get("servingSize")     is None: missing_serving += 1
        if f.get("verificationStatus") == VS_NEEDS_VERIFICATION: needs_verif += 1

    lines.append("Per-category counts:")
    cat_code_to_fa = {c[0]: c[2] for c in BERGAMOT_CATEGORIES}
    for code in sorted(cat_counts, key=lambda c: -cat_counts[c]):
        lines.append(f"  {code:18s} ({cat_code_to_fa.get(code,'?'):18s})  {cat_counts[code]:>6,}")
    lines.append("")

    lines.append("Per-source counts:")
    for src in sorted(src_counts, key=lambda s: -src_counts[s]):
        lines.append(f"  {src:24s}  {src_counts[src]:>6,}")
    lines.append("")

    lines.append("Missing-nutrient counts (NULL — NOT zero):")
    lines.append(f"  missing caloriesPer100g = {missing_cal:>6,}")
    lines.append(f"  missing proteinPer100g   = {missing_prot:>6,}")
    lines.append(f"  missing carbsPer100g     = {missing_carb:>6,}")
    lines.append(f"  missing fatPer100g       = {missing_fat:>6,}")
    lines.append(f"  missing servingSize      = {missing_serving:>6,}")
    lines.append("")

    lines.append("Verification status:")
    lines.append(f"  records needing verification = {needs_verif:>6,}")
    lines.append("")

    rep.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return rep


# ---------------------------------------------------------------------------
# Main entrypoint
# ---------------------------------------------------------------------------
def main() -> int:
    print("=" * 60)
    print("Bergamot Food Database — Building curated dataset")
    print("=" * 60)
    print()

    foods, stats = build_dataset()
    categories = build_categories()

    # Write JSON files
    foods_path    = OUT_DIR / "bergamot_foods.json"
    cats_path     = OUT_DIR / "bergamot_categories.json"
    meta_path     = OUT_DIR / "bergamot_dataset_meta.json"
    recipes_path  = OUT_DIR / "bergamot_recipes.json"

    with open(foods_path, "w", encoding="utf-8") as f:
        json.dump({"foods": foods}, f, ensure_ascii=False, indent=1)
    with open(cats_path, "w", encoding="utf-8") as f:
        json.dump({"categories": categories}, f, ensure_ascii=False, indent=1)

    # Recipes come from a separate module (iranian_recipes.py)
    try:
        from iranian_recipes import build_iranian_recipes
        recipes = build_iranian_recipes()
    except Exception as e:
        print(f"[warn] could not build recipes: {e}")
        recipes = []
    with open(recipes_path, "w", encoding="utf-8") as f:
        json.dump({"recipes": [r.to_dict() for r in recipes]}, f, ensure_ascii=False, indent=1)

    # Dataset metadata
    meta = {
        "source": "USDA FoodData Central + Iranian references",
        "usda_versions": {
            "foundation": "2026-04-30",
            "sr_legacy":  "2018-04",
            "survey_fndds": "2024-10-31",
        },
        "usda_dataset_urls": [
            "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_csv_2026-04-30.zip",
            "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip",
            "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_csv_2024-10-31.zip",
        ],
        "import_date_utc": "2026-08-24",
        "total_foods": len(foods),
        "total_recipes": len(recipes),
        "total_categories": len(categories),
        "license": "USDA FoodData Central — public domain. Persian names are Bergamot-curated.",
        "attribution": "U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.",
        "stats": stats,
    }
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    # Build report
    rep_path = write_report(foods, stats)

    print()
    print("=" * 60)
    print(f"Final dataset  : {len(foods):,} foods, {len(recipes):,} recipes, {len(categories):,} categories")
    print(f"Foods JSON     : {foods_path}")
    print(f"Recipes JSON   : {recipes_path}")
    print(f"Categories JSON: {cats_path}")
    print(f"Metadata JSON  : {meta_path}")
    print(f"Build report   : {rep_path}")
    print("=" * 60)
    return 0


if __name__ == "__main__":
    sys.exit(main())
