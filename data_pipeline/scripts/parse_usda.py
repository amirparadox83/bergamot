"""
Parse USDA FoodData Central CSVs into intermediate FoodRecord objects.

Each USDA dataset (Foundation / SR Legacy / FNDDS) shares the same CSV
structure:
  - food.csv        — list of foods (FDC ID, description, category)
  - food_nutrient.csv — nutrient values per FDC ID (per-100g)
  - food_portion.csv — serving sizes with gram weights
  - nutrient.csv    — nutrient definitions (id → name)
  - food_category.csv — category id → description

We extract a curated list of FoodRecord, normalizing all nutrient values
to per-100g, attaching serving weights where available, and tagging source.

For Foundation Foods we skip `sub_sample_food` rows (analytical sub-samples)
to avoid massive duplication of the same food name.
"""
from __future__ import annotations

import csv
import os
import sys
from pathlib import Path
from typing import Iterable

from common import (
    FoodRecord, NUTRIENT_PREFERENCE, USDA_CATEGORY_MAP,
    SRC_USDA_FOUNDATION, SRC_USDA_SR_LEGACY, SRC_USDA_FNDDS,
)
from persian_map import normalize_en, normalize_fa, fa_name_for


# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------
PROC_DIR = Path(__file__).resolve().parent.parent / "processed"
RAW_DIR  = Path(__file__).resolve().parent.parent / "raw"


def _find_dir(name_substring: str) -> Path:
    """Find a USDA dataset dir under processed/ by substring match."""
    for p in PROC_DIR.iterdir():
        if p.is_dir() and name_substring.lower() in p.name.lower():
            for sub in p.iterdir():
                if sub.is_dir():
                    return sub
            return p
    raise FileNotFoundError(f"No processed dir matching {name_substring!r}")


FOUNDATION_DIR = _find_dir("foundation_food")
SR_LEGACY_DIR  = _find_dir("sr_legacy_food")
SURVEY_DIR     = _find_dir("survey_food")


# ---------------------------------------------------------------------------
# Generic CSV loader with iterator
# ---------------------------------------------------------------------------
def _iter_csv(path: Path) -> Iterable[dict]:
    if not path.exists():
        return
    with open(path, encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            yield row


def _to_float(x) -> float | None:
    """Parse USDA numeric values. Empty/None → None."""
    if x is None:
        return None
    s = str(x).strip()
    if s == "" or s == "0" and False:  # explicit zero is valid; keep
        return None
    if s == "":
        return None
    try:
        return float(s)
    except (ValueError, TypeError):
        return None


# ---------------------------------------------------------------------------
# Per-dataset extraction
# ---------------------------------------------------------------------------
# Skip data_types that are analytical sub-samples (massive duplication)
FOUNDATION_SKIP_DATATYPES = {"sub_sample_food"}


def parse_dataset(base_dir: Path, source_tag: str) -> list[FoodRecord]:
    """Parse one USDA dataset directory into a list of FoodRecord."""
    food_csv   = base_dir / "food.csv"
    nut_csv    = base_dir / "food_nutrient.csv"
    portion_csv= base_dir / "food_portion.csv"
    cat_csv    = base_dir / "food_category.csv"

    # --- 1. Load categories ---
    cat_map: dict[str, dict] = {}
    for r in _iter_csv(cat_csv):
        cat_map[str(r["id"])] = {
            "code": r["code"],
            "description": r["description"],
        }

    # --- 2. Load foods ---
    foods: dict[str, dict] = {}  # fdc_id → metadata
    for r in _iter_csv(food_csv):
        dt = r.get("data_type", "")
        if source_tag == SRC_USDA_FOUNDATION and dt in FOUNDATION_SKIP_DATATYPES:
            continue
        fdc_id = str(r["fdc_id"])
        foods[fdc_id] = {
            "fdc_id": fdc_id,
            "data_type": dt,
            "description": r.get("description", "").strip(),
            "food_category_id": r.get("food_category_id", ""),
            "publication_date": r.get("publication_date", ""),
        }

    # --- 3. Load nutrients per food ---
    # For each food, collect a dict {nutrient_id: amount}
    food_nuts: dict[str, dict[int, float]] = {fdc: {} for fdc in foods}
    for r in _iter_csv(nut_csv):
        fdc_id = str(r["fdc_id"])
        if fdc_id not in food_nuts:
            continue
        nid = r.get("nutrient_id", "")
        if not nid:
            continue
        try:
            nid_int = int(nid)
        except ValueError:
            continue
        amt = _to_float(r.get("amount"))
        if amt is None:
            continue
        # Keep first non-null value for each nutrient (USDA may have duplicates
        # with different derivation codes; we accept the first occurrence)
        d = food_nuts[fdc_id]
        if nid_int not in d:
            d[nid_int] = amt

    # --- 4. Load portions (serving weights) ---
    # Pick the "most representative" portion per food:
    # Priority: smallest seq_num (typically the standard serving)
    food_portions: dict[str, dict] = {fdc: None for fdc in foods}
    for r in _iter_csv(portion_csv):
        fdc_id = str(r["fdc_id"])
        if fdc_id not in food_portions:
            continue
        gw = _to_float(r.get("gram_weight"))
        if gw is None or gw <= 0:
            continue
        seq = r.get("seq_num", "")
        # First portion (smallest seq_num) wins; if seq_num empty use first seen
        if food_portions[fdc_id] is None:
            food_portions[fdc_id] = {
                "gram_weight": gw,
                "portion_description": r.get("portion_description", "").strip(),
                "modifier": r.get("modifier", "").strip(),
                "amount": _to_float(r.get("amount")),
            }

    # --- 5. Build FoodRecord list ---
    records: list[FoodRecord] = []
    for fdc_id, meta in foods.items():
        desc = meta["description"]
        if not desc:
            continue

        nuts = food_nuts.get(fdc_id, {})
        rec = FoodRecord(
            nameEn=desc,
            normalizedNameEn=normalize_en(desc),
            nameFa=fa_name_for(desc),
            source=source_tag,
            externalId=f"{source_tag}:{fdc_id}",
            categoryId=USDA_CATEGORY_MAP.get(meta["food_category_id"], "other"),
        )
        if rec.nameFa:
            rec.normalizedNameFa = normalize_fa(rec.nameFa)

        # Per-100g nutrition — use preference order, NEVER fabricate
        for field, nids in NUTRIENT_PREFERENCE.items():
            for nid in nids:
                if nid in nuts:
                    setattr(rec, field, nuts[nid])
                    break
        # Mark unverified if no Persian name was mapped
        if not rec.nameFa:
            rec.verificationStatus = "NEEDS_VERIFICATION"
            rec.isVerified = False

        # Serving
        p = food_portions.get(fdc_id)
        if p:
            rec.servingSize = p["gram_weight"]
            rec.servingUnit = "serving"
            desc_text = (p.get("portion_description") or "").strip()
            if not desc_text:
                desc_text = (p.get("modifier") or "").strip()
            rec.servingDescriptionEn = desc_text or None
            # Approximate Persian serving description for common cases
            if desc_text:
                low = desc_text.lower()
                if "cup" in low:       rec.servingDescriptionFa = "۱ لیوان"
                elif "tablespoon" in low: rec.servingDescriptionFa = "۱ قاشق غذاخوری"
                elif "teaspoon" in low:   rec.servingDescriptionFa = "۱ قاشق چایخوری"
                elif "serving" in low:    rec.servingDescriptionFa = "۱ سروینگ"
                elif "piece" in low or "medium" in low: rec.servingDescriptionFa = "۱ عدد متوسط"
                elif "small" in low:      rec.servingDescriptionFa = "۱ عدد کوچک"
                elif "large" in low:      rec.servingDescriptionFa = "۱ عدد بزرگ"

        # Preparation state extracted from description
        low_desc = desc.lower()
        for state in ["raw", "cooked", "boiled", "fried", "baked", "steamed",
                      "grilled", "roasted", "smoked", "dried", "fresh", "canned",
                      "frozen", "juice", "puree", "powder", "ground", "whole"]:
            if f", {state}" in low_desc or f" {state}," in low_desc or low_desc.endswith(f", {state}"):
                rec.preparationState = state
                break

        records.append(rec)

    return records


def parse_all() -> tuple[list[FoodRecord], dict]:
    """Parse all three USDA datasets.

    Returns (records, stats) where stats is a dict of dataset → count.
    """
    print("[parse] Foundation Foods...")
    foundation = parse_dataset(FOUNDATION_DIR, SRC_USDA_FOUNDATION)
    print(f"  → {len(foundation):,} records (excl. sub_sample_food)")

    print("[parse] SR Legacy...")
    sr_legacy = parse_dataset(SR_LEGACY_DIR, SRC_USDA_SR_LEGACY)
    print(f"  → {len(sr_legacy):,} records")

    print("[parse] FNDDS / Survey...")
    fndds = parse_dataset(SURVEY_DIR, SRC_USDA_FNDDS)
    print(f"  → {len(fndds):,} records")

    stats = {
        "foundation_raw": len(foundation),
        "sr_legacy_raw": len(sr_legacy),
        "fndds_raw": len(fndds),
        "total_raw": len(foundation) + len(sr_legacy) + len(fndds),
    }
    return foundation + sr_legacy + fndds, stats


if __name__ == "__main__":
    recs, stats = parse_all()
    print()
    print(f"Total records parsed: {len(recs):,}")
    print(f"Stats: {stats}")
