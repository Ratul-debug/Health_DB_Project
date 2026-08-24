#!/usr/bin/env python3

"""Find exact duplicate CSV files and write an auditable report."""

from __future__ import annotations

import hashlib
from pathlib import Path

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = BASE_DIR / "reports"
OUTPUT_FILE = REPORT_DIR / "duplicate_tables.csv"


def main() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    preferred = BASE_DIR / "cleaned_tables"
    roots = [preferred] if any(preferred.rglob("*.csv")) else [BASE_DIR / "extracted_tables"]
    first_seen: dict[str, Path] = {}
    duplicates: list[dict[str, str]] = []

    for root in roots:
        for csv_file in sorted(root.rglob("*.csv")):
            digest = hashlib.sha256(csv_file.read_bytes()).hexdigest()
            if digest in first_seen:
                duplicates.append(
                    {
                        "sha256": digest,
                        "original": str(first_seen[digest].relative_to(BASE_DIR)),
                        "duplicate": str(csv_file.relative_to(BASE_DIR)),
                    }
                )
            else:
                first_seen[digest] = csv_file

    pd.DataFrame(duplicates, columns=["sha256", "original", "duplicate"]).to_csv(
        OUTPUT_FILE, index=False
    )
    print(f"Duplicates: {len(duplicates)}")
    print(f"Report    : {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
