#!/usr/bin/env python3

"""Build a catalog that retains the quality decision for every pipeline table."""

from __future__ import annotations

from pathlib import Path

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = BASE_DIR / "reports"
SUMMARY_FILE = REPORT_DIR / "cleaning_summary.csv"
OUTPUT_FILE = REPORT_DIR / "table_catalog.csv"


def dimensions(path: Path) -> tuple[int, int, str]:
    try:
        frame = pd.read_csv(
            path, dtype=str, keep_default_na=False, on_bad_lines="skip", encoding_errors="replace"
        )
        return len(frame), len(frame.columns), ""
    except Exception as exc:
        return 0, 0, str(exc)


def main() -> None:
    if not SUMMARY_FILE.exists():
        raise FileNotFoundError(f"Run scripts/cleaner.py first: {SUMMARY_FILE}")
    cleaning = pd.read_csv(SUMMARY_FILE, keep_default_na=False)
    records: list[dict[str, object]] = []
    associated_outputs: set[str] = set()
    for item in cleaning.to_dict("records"):
        output = str(item["output_file"])
        if output:
            associated_outputs.add(output)
        records.append(
            {
                "source_file": item["source_file"],
                "file": output,
                "rows": int(item["rows_after"]),
                "cols": int(item["columns_after"]),
                "quality_status": item["quality_status"],
                "quality_reasons": item["quality_reasons"],
                "status": "ok" if output else "error",
                "error": item["error"],
            }
        )

    # Include deterministic mapping/reference tables created by the national-scale builder.
    cleaned_root = BASE_DIR / "cleaned_tables"
    for csv_file in sorted(cleaned_root.rglob("*.csv")):
        relative = str(csv_file.relative_to(BASE_DIR))
        if relative in associated_outputs:
            continue
        rows, cols, error = dimensions(csv_file)
        records.append(
            {
                "source_file": "derived_mapping_output",
                "file": relative,
                "rows": rows,
                "cols": cols,
                "quality_status": "accepted_mapped" if not error else "rejected",
                "quality_reasons": "explicit_source_to_schema_mapping",
                "status": "ok" if not error else "error",
                "error": error,
            }
        )

    result = pd.DataFrame(records).sort_values(["source_file", "file"])
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    result.to_csv(OUTPUT_FILE, index=False)
    print(f"Tables : {len(result)}")
    print(result["quality_status"].value_counts().to_string())
    print(f"Catalog: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
