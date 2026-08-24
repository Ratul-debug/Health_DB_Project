#!/usr/bin/env python3

"""Build a full row/column catalog for extracted or cleaned CSV tables."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
from tqdm import tqdm


BASE_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = BASE_DIR / "reports"
OUTPUT_FILE = REPORT_DIR / "table_catalog.csv"


def main() -> None:
    cleaned = BASE_DIR / "cleaned_tables"
    source_root = cleaned if any(cleaned.rglob("*.csv")) else BASE_DIR / "extracted_tables"
    csv_files = sorted(source_root.rglob("*.csv"))
    records: list[dict[str, object]] = []

    for csv_file in tqdm(csv_files, desc="Cataloging tables"):
        try:
            frame = pd.read_csv(
                csv_file,
                dtype=str,
                keep_default_na=False,
                on_bad_lines="skip",
                encoding_errors="ignore",
            )
            records.append(
                {
                    "file": str(csv_file.relative_to(BASE_DIR)),
                    "rows": len(frame),
                    "cols": len(frame.columns),
                    "status": "ok",
                    "error": "",
                }
            )
        except Exception as exc:
            records.append(
                {
                    "file": str(csv_file.relative_to(BASE_DIR)),
                    "rows": 0,
                    "cols": 0,
                    "status": "error",
                    "error": str(exc),
                }
            )

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(records).to_csv(OUTPUT_FILE, index=False)
    print(f"Tables : {len(records)}")
    print(f"Catalog: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
