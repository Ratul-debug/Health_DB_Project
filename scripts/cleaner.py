#!/usr/bin/env python3

"""Clean extracted CSV tables without modifying the raw extraction files."""

from __future__ import annotations

import re
from pathlib import Path

import pandas as pd
from tqdm import tqdm


BASE_DIR = Path(__file__).resolve().parent.parent
INPUT_DIR = BASE_DIR / "extracted_tables"
OUTPUT_DIR = BASE_DIR / "cleaned_tables"
REPORT_DIR = BASE_DIR / "reports"
SUMMARY_FILE = REPORT_DIR / "cleaning_summary.csv"

NULL_TOKENS = {"", "nan", "none", "null", "n/a", "na", "-", "--"}


def normalize_text(value: object) -> object:
    if pd.isna(value):
        return pd.NA
    text = re.sub(r"\s+", " ", str(value)).strip()
    return pd.NA if text.lower() in NULL_TOKENS else text


def unique_columns(columns: list[object]) -> list[str]:
    result: list[str] = []
    seen: dict[str, int] = {}
    for position, raw_column in enumerate(columns, start=1):
        name = normalize_text(raw_column)
        name = "" if pd.isna(name) else str(name)
        name = re.sub(r"[^0-9A-Za-z]+", "_", name).strip("_").lower()
        if not name or name.isdigit():
            name = f"column_{position}"
        seen[name] = seen.get(name, 0) + 1
        result.append(name if seen[name] == 1 else f"{name}_{seen[name]}")
    return result


def promote_first_row_if_header(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty or not all(str(column).isdigit() for column in df.columns):
        return df
    candidate = [normalize_text(value) for value in df.iloc[0].tolist()]
    meaningful = [str(value) for value in candidate if not pd.isna(value)]
    if len(meaningful) < max(2, len(candidate) // 2):
        return df
    if len({value.lower() for value in meaningful}) != len(meaningful):
        return df
    promoted = df.iloc[1:].reset_index(drop=True).copy()
    promoted.columns = candidate
    return promoted


def clean_table(source: Path) -> tuple[pd.DataFrame, int, int]:
    frame = pd.read_csv(
        source,
        dtype=str,
        keep_default_na=False,
        on_bad_lines="skip",
        encoding_errors="ignore",
    )
    rows_before = len(frame)
    columns_before = len(frame.columns)
    frame = promote_first_row_if_header(frame)
    frame.columns = unique_columns(list(frame.columns))
    frame = frame.apply(lambda column: column.map(normalize_text))
    frame = frame.dropna(axis=0, how="all").dropna(axis=1, how="all")
    frame = frame.drop_duplicates().reset_index(drop=True)
    return frame, rows_before, columns_before


def main() -> None:
    if not INPUT_DIR.exists():
        raise FileNotFoundError(f"Input directory not found: {INPUT_DIR}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    sources = sorted(INPUT_DIR.rglob("*.csv"))
    summary: list[dict[str, object]] = []

    for source in tqdm(sources, desc="Cleaning extracted tables"):
        relative = source.relative_to(INPUT_DIR)
        destination = OUTPUT_DIR / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            cleaned, rows_before, columns_before = clean_table(source)
            cleaned.to_csv(destination, index=False)
            summary.append(
                {
                    "source_file": str(source.relative_to(BASE_DIR)),
                    "cleaned_file": str(destination.relative_to(BASE_DIR)),
                    "status": "ok",
                    "rows_before": rows_before,
                    "rows_after": len(cleaned),
                    "columns_before": columns_before,
                    "columns_after": len(cleaned.columns),
                    "duplicate_rows_removed": max(0, rows_before - len(cleaned)),
                    "error": "",
                }
            )
        except Exception as exc:
            summary.append(
                {
                    "source_file": str(source.relative_to(BASE_DIR)),
                    "cleaned_file": str(destination.relative_to(BASE_DIR)),
                    "status": "error",
                    "rows_before": 0,
                    "rows_after": 0,
                    "columns_before": 0,
                    "columns_after": 0,
                    "duplicate_rows_removed": 0,
                    "error": str(exc),
                }
            )

    pd.DataFrame(summary).to_csv(SUMMARY_FILE, index=False)
    failures = sum(item["status"] == "error" for item in summary)
    print(f"Input tables : {len(sources)}")
    print(f"Cleaned      : {len(sources) - failures}")
    print(f"Failed       : {failures}")
    print(f"Summary      : {SUMMARY_FILE}")


if __name__ == "__main__":
    main()
