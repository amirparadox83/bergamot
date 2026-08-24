"""
Iranian dish recipes — built from real ingredients, not fabricated calories.

Each recipe lists base ingredients with gram amounts. The actual nutrition is
computed at runtime by NutritionCalculator.sum_recipe_ingredients(...) which
looks up each ingredient's per-100g nutrition in the Foods table and multiplies
by grams/100.

Yields and ingredient gram amounts are based on commonly published Persian
home-cooking recipes (e.g. Ashpazi Irani references). They are NOT fabricated —
they reflect realistic ratios used in actual cooking. The resulting nutrition
is the *sum* of ingredient data, which inherits its provenance from USDA +
IRANIAN_REFERENCE bases.

Each recipe carries verificationStatus = "COMMUNITY_RECIPE" — a UI badge should
show "غذای خانگی — مقادیر تقریبی" so the user understands.
"""
from __future__ import annotations

from common import RecipeRecord, SRC_RECIPE, VS_COMMUNITY_RECIPE
from persian_map import normalize_en, normalize_fa


# ---------------------------------------------------------------------------
# Iranian recipe definitions
# ---------------------------------------------------------------------------
# Format:
#   (nameEn, nameFa, categoryId, totalYieldGrams, servingGrams, servingUnit, servingFa,
#    notes,
#    [ (ingredientNameEn_normalized, grams), ... ])
# The ingredientNameEn is matched against FoodRecord.normalizedNameEn at seed time.
# If multiple matches, the highest-priority source wins (Foundation > SR > FNDDS).

_IRANIAN_RECIPES = [
    # ----- Khoresht (Iranian stews) -----
    ("Ghormeh Sabzi", "قرمه‌سبزی", "iranian_foods",
     1200, 300, "plate", "یک بشقاب",
     "خورشت سبزی‌معطر با گوشت و لوبیا قرمز — دستور خانگی استاندارد.",
     [
        ("lamb, raw", 500),
        ("kidney beans, raw", 200),
        ("spinach, raw", 200),
        ("parsley, fresh", 100),
        ("cilantro, fresh", 100),
        ("leek, raw", 80),
        ("fenugreek, fresh", 30),
        ("onion, raw", 200),
        ("vegetable oil", 60),
        ("dried lime", 15),
        ("salt", 5),
        ("turmeric, ground", 5),
     ]),
    ("Gheimeh", "قیمه", "iranian_foods",
     1200, 300, "plate", "یک بشقاب",
     "خورشت گوشت و لپه با سیب‌زمینی سرخ‌شده.",
     [
        ("lamb, raw", 500),
        ("split peas, raw", 200),
        ("onion, raw", 200),
        ("tomato paste", 60),
        ("vegetable oil", 80),
        ("potato, raw", 300),
        ("dried lime", 15),
        ("turmeric, ground", 5),
        ("salt", 5),
        ("black pepper, ground", 2),
     ]),
    ("Fesenjan", "فسنجان", "iranian_foods",
     1100, 300, "plate", "یک بشقاب",
     "خورشت گردو با مرغ یا گوشت — دستور شمالی.",
     [
        ("chicken, raw", 700),
        ("walnuts, raw", 400),
        ("pomegranate molasses", 100),
        ("onion, raw", 150),
        ("vegetable oil", 30),
        ("turmeric, ground", 5),
        ("salt", 5),
        ("sugar", 20),
     ]),
    ("Khoresht-e Bademjan", "خورشت بادمجان", "iranian_foods",
     1200, 300, "plate", "یک بشقاب",
     "خورشت بادمجان و گوجه با گوشت.",
     [
        ("lamb, raw", 500),
        ("eggplant, raw", 600),
        ("tomato, raw", 400),
        ("onion, raw", 150),
        ("vegetable oil", 80),
        ("tomato paste", 40),
        ("turmeric, ground", 5),
        ("salt", 5),
     ]),
    ("Khoresht-e Karafs", "خوراک کرفس", "iranian_foods",
     1100, 300, "plate", "یک بشقاب",
     "خورشت کرفس با گوشت و گردو.",
     [
        ("lamb, raw", 500),
        ("celery, raw", 500),
        ("onion, raw", 150),
        ("vegetable oil", 50),
        ("mint, fresh", 30),
        ("parsley, fresh", 30),
        ("walnuts, raw", 80),
        ("turmeric, ground", 5),
        ("salt", 5),
     ]),

    # ----- Polo (rice dishes) -----
    ("Adas Polo", "عدس پلو", "iranian_foods",
     1500, 250, "plate", "یک بشقاب",
     "پلوی برنج با عدس و کشمش.",
     [
        ("rice, white, long-grain, raw", 500),
        ("lentils, raw", 250),
        ("onion, raw", 200),
        ("vegetable oil", 80),
        ("raisins", 100),
        ("salt", 8),
        ("turmeric, ground", 5),
     ]),
    ("Zereshk Polo Ba Morgh", "زرشک پلو با مرغ", "iranian_foods",
     1500, 300, "plate", "یک بشقاب",
     "پلوی زرشک با مرغ.",
     [
        ("rice, white, long-grain, raw", 500),
        ("chicken, raw", 600),
        ("barberry", 80),
        ("onion, raw", 150),
        ("vegetable oil", 80),
        ("saffron", 2),
        ("salt", 8),
        ("turmeric, ground", 5),
     ]),
    ("Baghali Polo", "باقالی پلو", "iranian_foods",
     1500, 250, "plate", "یک بشقاب",
     "پلوی برنج با باقالی و شوید.",
     [
        ("rice, white, long-grain, raw", 500),
        ("fava beans, raw", 300),
        ("dill, fresh", 80),
        ("vegetable oil", 80),
        ("salt", 8),
        ("turmeric, ground", 3),
     ]),
    ("Loobia Polo", "لوبو پلو", "iranian_foods",
     1500, 300, "plate", "یک بشقاب",
     "پلوی برنج با لوبیا قرمز و گوشت چرخ‌کرده.",
     [
        ("rice, white, long-grain, raw", 500),
        ("ground beef, raw", 400),
        ("kidney beans, raw", 200),
        ("onion, raw", 200),
        ("tomato paste", 60),
        ("vegetable oil", 80),
        ("salt", 8),
        ("cinnamon, ground", 3),
     ]),

    # ----- Kuku -----
    ("Kuku Sabzi", "کوکو سبزی", "iranian_foods",
     600, 200, "plate", "یک بشقاب",
     "کوکو سبزی معطر با تخم‌مرغ.",
     [
        ("egg, raw, whole", 300),
        ("parsley, fresh", 100),
        ("cilantro, fresh", 80),
        ("leek, raw", 80),
        ("dill, fresh", 50),
        ("vegetable oil", 40),
        ("turmeric, ground", 3),
        ("salt", 4),
     ]),
    ("Kuku Sib Zamini", "کوکو سیب‌زمینی", "iranian_foods",
     700, 200, "plate", "یک بشقاب",
     "کوکو سیب‌زمینی با تخم‌مرغ.",
     [
        ("potato, raw", 500),
        ("egg, raw, whole", 200),
        ("onion, raw", 100),
        ("vegetable oil", 50),
        ("turmeric, ground", 3),
        ("salt", 5),
     ]),

    # ----- Kabab -----
    ("Joojeh Kabab", "جوجه‌کباب", "iranian_foods",
     700, 200, "plate", "یک بشقاب",
     "جوجه‌کباب زعفرانی.",
     [
        ("chicken, raw", 600),
        ("onion, raw", 200),
        ("vegetable oil", 50),
        ("saffron", 2),
        ("lemon juice", 30),
        ("salt", 5),
        ("black pepper, ground", 2),
     ]),
    ("Kabab Koobideh", "کباب کوبیده", "iranian_foods",
     700, 180, "gram", "دو سیخ",
     "کباب گوشت چرخ‌کرده با پیاز.",
     [
        ("ground beef, raw", 600),
        ("onion, raw", 200),
        ("vegetable oil", 30),
        ("salt", 8),
        ("black pepper, ground", 3),
        ("turmeric, ground", 3),
     ]),

    # ----- Soup / Ash -----
    ("Ash Reshteh", "آش رشته", "iranian_foods",
     2000, 300, "plate", "یک کاسه",
     "آش رشته با حبوبات و سبزی معطر.",
     [
        ("lentils, raw", 100),
        ("chickpeas, raw", 100),
        ("kidney beans, raw", 100),
        ("rice, white, long-grain, raw", 100),
        ("noodles, dry", 150),
        ("parsley, fresh", 200),
        ("cilantro, fresh", 150),
        ("leek, raw", 150),
        ("onion, raw", 200),
        ("vegetable oil", 100),
        ("kashk", 100),
        ("salt", 10),
        ("turmeric, ground", 5),
     ]),
    ("Adasi", "عدسی", "iranian_foods",
     1500, 250, "plate", "یک کاسه",
     "سوپ عدس با پیاز داغ.",
     [
        ("lentils, raw", 400),
        ("onion, raw", 200),
        ("vegetable oil", 50),
        ("turmeric, ground", 5),
        ("salt", 8),
        ("lemon juice", 30),
     ]),

    # ----- Misc -----
    ("Kashk-e Bademjan", "کشک بادمجان", "iranian_foods",
     800, 250, "plate", "یک بشقاب",
     "بادمجان سرخ‌شده با کشک و نعناع داغ.",
     [
        ("eggplant, raw", 700),
        ("onion, raw", 150),
        ("garlic, raw", 20),
        ("vegetable oil", 80),
        ("kashk", 100),
        ("mint, dried", 15),
        ("walnuts, raw", 50),
        ("turmeric, ground", 3),
        ("salt", 5),
     ]),
    ("Abgoosht / Dizi", "آبگوشت / دیزی", "iranian_foods",
     1500, 350, "plate", "یک دیزی",
     "آبگوشت سنتی با گوشت، حبوبات و سیب‌زمینی.",
     [
        ("lamb, raw", 400),
        ("chickpeas, raw", 150),
        ("kidney beans, raw", 100),
        ("potato, raw", 400),
        ("onion, raw", 200),
        ("tomato paste", 50),
        ("vegetable oil", 50),
        ("dried lime", 15),
        ("turmeric, ground", 5),
        ("salt", 8),
     ]),
]


def build_iranian_recipes() -> list[RecipeRecord]:
    """Convert raw tuples into RecipeRecord objects with normalized names."""
    out: list[RecipeRecord] = []
    for (nameEn, nameFa, cat, totalYield, serving, unit, servingFa,
         notes, ingredients) in _IRANIAN_RECIPES:
        rec = RecipeRecord(
            nameEn=nameEn,
            nameFa=nameFa,
            categoryId=cat,
            totalYieldGrams=float(totalYield),
            servingSize=float(serving),
            servingUnit=unit,
            servingDescriptionFa=servingFa,
            normalizedNameFa=normalize_fa(nameFa),
            normalizedNameEn=normalize_en(nameEn),
            source=SRC_RECIPE,
            isVerified=True,
            verificationStatus=VS_COMMUNITY_RECIPE,
            notes=notes,
            ingredients=[
                {"ingredientKey": normalize_en(ing_name), "grams": float(g)}
                for ing_name, g in ingredients
            ],
        )
        out.append(rec)
    return out


if __name__ == "__main__":
    for r in build_iranian_recipes():
        print(f"{r.nameFa:25s} | {len(r.ingredients):2d} ingredients | {r.totalYieldGrams:.0f}g yield")
