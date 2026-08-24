#!/usr/bin/env python3

"""Classify cataloged CSV tables using transparent keyword rules."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
from tqdm import tqdm


BASE_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = BASE_DIR / "reports"
CATALOG_FILE = REPORT_DIR / "table_catalog.csv"
OUTPUT_FILE = REPORT_DIR / "classified_tables.csv"

RULES = {
    "population": ["population", "census", "division", "district"],
    "health_stat": ["disease", "admission", "deaths", "hospital", "opd", "patient"],
    "human_resource": ["designation", "sanctioned", "vacant", "professor", "nurse", "doctor"],
    "cancer": ["cancer", "tumour", "tumor", "site", "icd"],
    "surgery": ["surgery", "operation", "cataract"],
    "maternal_child": ["maternal", "pregnancy", "newborn", "nutrition", "immunization"],
}


def classify(text: str) -> tuple[str, int]:
    scores = {
        category: sum(keyword in text for keyword in keywords)
        for category, keywords in RULES.items()
    }
    category, score = max(scores.items(), key=lambda item: item[1])
    return (category, score) if score else ("other", 0)


def main() -> None:
    if not CATALOG_FILE.exists():
        raise FileNotFoundError(f"Run scripts/05_build_catalog.py first: {CATALOG_FILE}")

    catalog = pd.read_csv(CATALOG_FILE)
    rows: list[dict[str, object]] = []
    for item in tqdm(catalog.itertuples(index=False), total=len(catalog), desc="Classifying"):
        csv_file = BASE_DIR / str(item.file)
        try:
            frame = pd.read_csv(
                csv_file,
                dtype=str,
                keep_default_na=False,
                nrows=20,
                on_bad_lines="skip",
                encoding_errors="ignore",
            )
            preview = " ".join(frame.fillna("").astype(str).values.flatten()).lower()
            category, score = classify(f"{csv_file.name.lower()} {preview}")
            rows.append(
                {
                    "file": str(item.file),
                    "category": category,
                    "keyword_score": score,
                    "rows": int(item.rows),
                    "cols": int(item.cols),
                }
            )
        except Exception:
            rows.append(
                {
                    "file": str(item.file),
                    "category": "error",
                    "keyword_score": 0,
                    "rows": int(item.rows),
                    "cols": int(item.cols),
                }
            )

    pd.DataFrame(rows).to_csv(OUTPUT_FILE, index=False)
    print(f"Classified: {len(rows)}")
    print(f"Report    : {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
