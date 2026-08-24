#!/usr/bin/env python3

"""Rank the largest candidate tables in every classification category."""

from __future__ import annotations

from pathlib import Path

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent.parent
INPUT_FILE = BASE_DIR / "reports" / "classified_tables.csv"
OUTPUT_FILE = BASE_DIR / "reports" / "best_tables.txt"


def main() -> None:
    if not INPUT_FILE.exists():
        raise FileNotFoundError(f"Run scripts/06_classify_tables.py first: {INPUT_FILE}")

    frame = pd.read_csv(INPUT_FILE)
    sections: list[str] = []
    for category in sorted(frame["category"].dropna().unique()):
        subset = frame[frame["category"] == category].sort_values(
            ["rows", "cols"], ascending=False
        )
        sections.extend(
            [
                "=" * 80,
                str(category).upper(),
                "=" * 80,
                subset.head(20)[["file", "rows", "cols", "keyword_score"]].to_string(index=False),
                "",
            ]
        )

    output = "\n".join(sections)
    OUTPUT_FILE.write_text(output, encoding="utf-8")
    print(output)
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
