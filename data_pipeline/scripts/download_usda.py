#!/usr/bin/env python3
"""
USDA FoodData Central — Bulk Dataset Downloader
================================================

Downloads the latest official USDA bulk CSV zips for:
  - Foundation Foods  (latest: 2026-04-30)
  - SR Legacy         (only:    2018-04)
  - FNDDS / Survey    (latest: 2024-10-31)

NO API calls. NO API key required. Pure bulk download.

Usage:
    python3 download_usda.py [--force]

Outputs:
    data_pipeline/raw/<dataset>.zip

The script is IDEMPOTENT: if a file already exists and is non-empty,
it is skipped (unless --force).
"""
from __future__ import annotations

import argparse
import hashlib
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration — pinned USDA dataset URLs (latest as of 2026-08-24)
# ---------------------------------------------------------------------------
BASE_URL = "https://fdc.nal.usda.gov"

DATASETS = [
    {
        "key": "foundation",
        "filename": "FoodData_Central_foundation_food_csv_2026-04-30.zip",
        "version": "2026-04-30",
        "source_tag": "USDA_FOUNDATION",
    },
    {
        "key": "sr_legacy",
        "filename": "FoodData_Central_sr_legacy_food_csv_2018-04.zip",
        "version": "2018-04",
        "source_tag": "USDA_SR_LEGACY",
    },
    {
        "key": "survey_fndds",
        "filename": "FoodData_Central_survey_food_csv_2024-10-31.zip",
        "version": "2024-10-31",
        "source_tag": "USDA_FNDDS",
    },
]

RAW_DIR = Path(__file__).resolve().parent.parent / "raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)


def _download(url: str, dest: Path, force: bool) -> bool:
    if dest.exists() and dest.stat().st_size > 0 and not force:
        print(f"  [skip] {dest.name} already exists ({dest.stat().st_size:,} bytes)")
        return True
    tmp = dest.with_suffix(dest.suffix + ".tmp")
    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "BergamotPipeline/1.0 (USDA bulk download)",
                "Accept": "application/zip,*/*",
            },
        )
        with urllib.request.urlopen(req, timeout=120) as resp, open(tmp, "wb") as fh:
            total = int(resp.headers.get("Content-Length", 0))
            done = 0
            while True:
                chunk = resp.read(64 * 1024)
                if not chunk:
                    break
                fh.write(chunk)
                done += len(chunk)
                if total:
                    pct = done * 100 / total
                    sys.stdout.write(f"\r  [get ] {dest.name}  {done:,}/{total:,} ({pct:.1f}%)")
                    sys.stdout.flush()
            print()
        tmp.replace(dest)
        return True
    except (urllib.error.URLError, OSError) as e:
        print(f"\n  [fail] {dest.name}: {e}")
        if tmp.exists():
            tmp.unlink()
        return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="re-download even if cached")
    args = ap.parse_args()

    print(f"=== USDA bulk download ===")
    print(f"Output dir: {RAW_DIR}")
    print()

    results = []
    for ds in DATASETS:
        url = f"{BASE_URL}/fdc-datasets/{ds['filename']}"
        dest = RAW_DIR / ds["filename"]
        print(f"- {ds['key']}  ({ds['version']})")
        ok = _download(url, dest, args.force)
        results.append((ds, ok, dest))

    print()
    print("=== Summary ===")
    for ds, ok, dest in results:
        status = "OK" if ok else "FAIL"
        size = dest.stat().st_size if dest.exists() else 0
        print(f"  [{status}] {ds['key']:14s} {ds['version']:12s} {size:>14,} B  {dest.name}")

    if not all(ok for _, ok, _ in results):
        print("\nERROR: some downloads failed")
        return 1
    print("\nAll datasets downloaded successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
