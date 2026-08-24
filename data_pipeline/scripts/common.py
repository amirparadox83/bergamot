"""
Common constants and types shared by all pipeline modules.

All nutrient amounts in Bergamot are stored per-100g (canonical),
following the USDA convention.
"""
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Optional

# ---------------------------------------------------------------------------
# USDA nutrient IDs we care about (per-100g amounts in food_nutrient.csv)
# Source: USDA FoodData Central / nutrient.csv
# ---------------------------------------------------------------------------
USDA_NUTRIENT_ID = {
    "energy_kcal": 1008,        # Energy (kcal) — preferred
    "energy_kcal_alt": 2048,    # Atwater Specific Factors fallback
    "protein_g": 1003,          # Protein (g)
    "fat_g": 1004,              # Total lipid (fat) (g)
    "carbs_g": 1005,            # Carbohydrate, by difference (g)
    "fiber_g": 1079,            # Fiber, total dietary (g) — preferred
    "fiber_alt": 2033,           # AOAC 2011.25 fallback
    "sugars_g": 1063,            # Sugars, Total
    "sugars_alt": 2000,          # Total Sugars fallback
    "sodium_mg": 1093,
    "potassium_mg": 1092,
    "calcium_mg": 1087,
    "iron_mg": 1089,
}

# Preferred order for each canonical Bergamot nutrient (first non-null wins)
NUTRIENT_PREFERENCE = {
    "caloriesPer100g": [1008, 2048, 1062],
    "proteinPer100g":  [1003, 1053],
    "fatPer100g":      [1004],
    "carbsPer100g":    [1005, 1050],
    "fiberPer100g":    [1079, 2033],
    "sugarPer100g":    [1063, 2000],
    "sodiumPer100g":   [1093],
    "potassiumPer100g":[1092],
    "calciumPer100g":  [1087],
    "ironPer100g":     [1089],
}

# ---------------------------------------------------------------------------
# Source tags (stored in DB `source` column)
# ---------------------------------------------------------------------------
SRC_USDA_FOUNDATION = "USDA_FOUNDATION"
SRC_USDA_SR_LEGACY  = "USDA_SR_LEGACY"
SRC_USDA_FNDDS      = "USDA_FNDDS"
SRC_IRANIAN_REF     = "IRANIAN_REFERENCE"
SRC_CUSTOM          = "CUSTOM"
SRC_RECIPE          = "IRANIAN_RECIPE"

# ---------------------------------------------------------------------------
# Verification status (stored in DB `verificationStatus` column)
# ---------------------------------------------------------------------------
VS_VERIFIED         = "VERIFIED"
VS_NEEDS_VERIFICATION = "NEEDS_VERIFICATION"
VS_COMMUNITY_RECIPE = "COMMUNITY_RECIPE"

# ---------------------------------------------------------------------------
# Bergamot category codes — kept as short stable strings.
# The Flutter side has a FoodCategories table with these as keys.
# ---------------------------------------------------------------------------
BERGAMOT_CATEGORIES = [
    # (code, nameEn, nameFa)
    ("fruits",          "Fruits",            "میوه‌ها"),
    ("vegetables",      "Vegetables",        "سبزیجات"),
    ("legumes",         "Legumes",           "حبوبات"),
    ("grains",          "Grains",            "غلات"),
    ("rice",            "Rice",              "برنج"),
    ("bread",           "Bread",             "نان"),
    ("dairy",           "Dairy",             "لبنیات"),
    ("meat",            "Meat",              "گوشت"),
    ("poultry",         "Poultry",           "مرغ و طیور"),
    ("fish_seafood",    "Fish & Seafood",    "ماهی و غذاهای دریایی"),
    ("eggs",            "Eggs",              "تخم‌مرغ"),
    ("nuts",            "Nuts",              "مغزها"),
    ("seeds",           "Seeds",             "دانه‌ها"),
    ("oils_fats",       "Oils & Fats",       "روغن و چربی"),
    ("breakfast",       "Breakfast",        "صبحانه"),
    ("beverages",       "Beverages",         "نوشیدنی"),
    ("snacks",          "Snacks",            "تنقلات"),
    ("sweets",          "Sweets",            "شیرینی"),
    ("spices_herbs",    "Spices & Herbs",    "ادویه و سبزی‌های معطر"),
    ("sauces",          "Sauces",            "سس‌ها"),
    ("iranian_foods",   "Iranian Foods",     "غذاهای ایرانی"),
    ("other",           "Other",             "سایر"),
]

# ---------------------------------------------------------------------------
# USDA Foundation/SR/FNDDS food_category.id → Bergamot category code
# Derived from USDA food_category.csv (codes 0100..4500).
# ---------------------------------------------------------------------------
USDA_CATEGORY_MAP = {
    "1":  "dairy",
    "2":  "spices_herbs",
    "3":  "other",            # Baby Foods
    "4":  "oils_fats",
    "5":  "poultry",
    "6":  "sauces",
    "7":  "meat",             # Sausages and Luncheon Meats
    "8":  "grains",           # Breakfast Cereals
    "9":  "fruits",
    "10": "meat",             # Pork
    "11": "vegetables",
    "12": "nuts",             # Nuts and Seeds
    "13": "meat",             # Beef
    "14": "beverages",
    "15": "fish_seafood",
    "16": "legumes",
    "17": "meat",             # Lamb/Veal/Game
    "18": "bread",            # Baked Products
    "19": "sweets",
    "20": "grains",           # Cereal Grains and Pasta
    "21": "other",            # Fast Foods — skip
    "22": "other",            # Meals/Entrees — skip
    "23": "snacks",
    "24": "other",            # American Indian/Alaska Native
    "25": "other",            # Restaurant Foods
    "26": "other",            # Branded — skip
    "27": "other",            # Quality Control
    "28": "beverages",        # Alcoholic Beverages
}


# ---------------------------------------------------------------------------
# Data model for an intermediate Food record (before serialization to JSON)
# ---------------------------------------------------------------------------
@dataclass
class FoodRecord:
    """A single food record produced by the pipeline."""
    # Identity
    nameEn: str
    nameFa: Optional[str] = None
    normalizedNameEn: str = ""
    normalizedNameFa: str = ""

    # Category
    categoryId: str = "other"

    # Nutrition per 100g (None = missing — NEVER silently zero)
    caloriesPer100g: Optional[float] = None
    proteinPer100g:  Optional[float] = None
    carbsPer100g:    Optional[float] = None
    fatPer100g:      Optional[float] = None
    fiberPer100g:    Optional[float] = None
    sugarPer100g:    Optional[float] = None
    sodiumPer100g:   Optional[float] = None
    potassiumPer100g:Optional[float] = None
    calciumPer100g:  Optional[float] = None
    ironPer100g:     Optional[float] = None

    # Serving
    servingSize: Optional[float] = None  # grams
    servingUnit: str = "gram"
    servingDescriptionEn: Optional[str] = None
    servingDescriptionFa: Optional[str] = None

    # Provenance
    source: str = SRC_USDA_FOUNDATION
    externalId: Optional[str] = None
    barcode: Optional[str] = None
    brand: Optional[str] = None

    # Verification
    isCustom: bool = False
    isVerified: bool = True
    verificationStatus: str = VS_VERIFIED

    # Preparation state extracted from description (raw/cooked/fried/etc.)
    preparationState: Optional[str] = None

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class RecipeRecord:
    """A recipe (e.g. Iranian dish) made of ingredient foods."""
    nameEn: str
    nameFa: str
    categoryId: str = "iranian_foods"
    normalizedNameFa: str = ""
    normalizedNameEn: str = ""

    # Total yield in grams (used to compute per-serving nutrition)
    totalYieldGrams: float = 0.0

    # Default serving
    servingSize: float = 250.0
    servingUnit: str = "plate"
    servingDescriptionFa: Optional[str] = None

    # Ingredients: list of {ingredientKey: str, grams: float}
    # ingredientKey is "source:externalId" of a base Food, resolved at DB seed time.
    ingredients: list = field(default_factory=list)

    # Provenance
    source: str = SRC_RECIPE
    isCustom: bool = False
    isVerified: bool = True
    verificationStatus: str = VS_COMMUNITY_RECIPE

    notes: Optional[str] = None

    def to_dict(self) -> dict:
        from dataclasses import asdict
        return asdict(self)


__all__ = [
    "USDA_NUTRIENT_ID",
    "NUTRIENT_PREFERENCE",
    "SRC_USDA_FOUNDATION", "SRC_USDA_SR_LEGACY", "SRC_USDA_FNDDS",
    "SRC_IRANIAN_REF", "SRC_CUSTOM", "SRC_RECIPE",
    "VS_VERIFIED", "VS_NEEDS_VERIFICATION", "VS_COMMUNITY_RECIPE",
    "BERGAMOT_CATEGORIES",
    "USDA_CATEGORY_MAP",
    "FoodRecord", "RecipeRecord",
]
