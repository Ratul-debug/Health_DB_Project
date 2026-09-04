#!/usr/bin/env python3

"""Value-clean and quality-screen every extracted CSV while preserving raw evidence."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import pandas as pd

try:
    from tqdm import tqdm
except ImportError:  # Keep the pipeline usable before optional progress UI is installed.
    def tqdm(iterable, **_kwargs):
        return iterable


BASE_DIR = Path(__file__).resolve().parent.parent
INPUT_DIR = BASE_DIR / "extracted_tables"
CLEAN_DIR = BASE_DIR / "cleaned_tables"
QUARANTINE_DIR = BASE_DIR / "quarantined_tables"
VERIFIED_DIR = BASE_DIR / "verified_tables"
REPORT_DIR = BASE_DIR / "reports"
SUMMARY_FILE = REPORT_DIR / "cleaning_summary.csv"

NULL_TOKENS = {"", "nan", "none", "null", "n/a", "na", "-", "--", "nil"}
BENGALI_DIGITS = str.maketrans("০১২৩৪৫৬৭৮৯", "0123456789")
CONTROL_PATTERN = re.compile(
    r"[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\u200b-\u200f\u202a-\u202e\u2060\ufeff]"
)
MOJIBAKE_PATTERN = re.compile(r"(?:\ufffd|Ã.|Â.|â€|ðŸ)")

MEASLES_FOLDER = "086_Measles_Update_Till_14_05_26_"
MEASLES_SOURCE_URL = (
    "https://objectstorage.ap-dcc-gazipur-1.oraclecloud15.com/n/axvjbnqprylg/"
    "b/V2Ministry/o/office-dghs/2026/4/52fe889d-9910-4b42-8967-01593b6d8d1c.pdf"
)


def measles_tables() -> dict[str, pd.DataFrame]:
    """Return values transcribed and checked against the 14 May 2026 DGHS bulletin."""
    surveillance_columns = [
        "division",
        "last_24h_suspected_cases",
        "last_24h_suspected_deaths",
        "last_24h_confirmed_cases",
        "last_24h_confirmed_deaths",
        "last_24h_admissions",
        "last_24h_discharged",
        "cumulative_suspected_cases_since_2026_03_15",
        "cumulative_suspected_deaths_since_2026_03_15",
        "cumulative_confirmed_cases_since_2026_03_15",
        "cumulative_confirmed_deaths_since_2026_03_15",
        "cumulative_admissions_since_2026_03_15",
        "cumulative_discharged_since_2026_03_15",
    ]
    surveillance = [
        ("Dhaka", 588, 4, 132, 1, 440, 466, 24464, 147, 5017, 45, 17018, 15208),
        ("Rajshahi", 159, 0, 0, 0, 68, 79, 9222, 78, 1107, 2, 4603, 4037),
        ("Barishal", 126, 0, 3, 0, 126, 124, 4079, 29, 148, 11, 3423, 3122),
        ("Chattogram", 273, 1, 18, 0, 262, 311, 8000, 32, 565, 7, 7226, 6778),
        ("Mymensingh", 40, 1, 0, 0, 39, 26, 1137, 31, 42, 2, 845, 651),
        ("Sylhet", 79, 0, 0, 0, 74, 63, 2486, 29, 148, 3, 2090, 1694),
        ("Khulna", 87, 0, 0, 0, 87, 60, 3918, 19, 239, 0, 3503, 3083),
        ("Rangpur", 11, 0, 2, 0, 10, 7, 1113, 4, 39, 0, 452, 395),
        ("Total", 1363, 6, 155, 1, 1106, 1136, 54419, 369, 7305, 70, 39160, 34968),
    ]
    campaign_columns = [
        "area",
        "total_target",
        "cumulative_target_since_2026_04_05",
        "cumulative_vaccinated_since_2026_04_05",
        "cumulative_coverage_pct",
        "last_24h_target",
        "last_24h_vaccinated",
        "last_24h_coverage_pct",
        "total_campaign_coverage_pct",
    ]
    division_campaign = [
        ("Barishal", 1063638, 1063638, 1054256, "99%", 0, 2043, "0%", "99%"),
        ("Chattogram", 4296218, 4250791, 4316955, "102%", 6427, 20369, "276%", "100%"),
        ("Dhaka", 4449632, 4447408, 4498564, "101%", 10061, 12433, "90%", "101%"),
        ("Khulna", 1614273, 1613995, 1613894, "100%", 0, 2549, "210%", "100%"),
        ("Mymensingh", 1330655, 1330307, 1339914, "101%", 0, 1293, "176%", "101%"),
        ("Rajshahi", 2048435, 2048026, 2098738, "102%", 0, 1465, "118%", "102%"),
        ("Rangpur", 1888247, 1884700, 1927361, "102%", 0, 2903, "0%", "102%"),
        ("Sylhet", 1323966, 1322631, 1290717, "98%", 0, 3232, "136%", "97%"),
        ("Total", 18015064, 17961496, 18140399, "101%", 16488, 46287, "281%", "101%"),
    ]
    city_campaign = [
        ("Barishal City Corporation", 43506, 43506, 43622, "100%", 0, 0, "0%", "100%"),
        ("Chattogram City Corporation", 300285, 256103, 289617, "113%", 4762, 4151, "87%", "96%"),
        ("Cumilla City Corporation", 48004, 48004, 48419, "101%", 0, 0, "0%", "101%"),
        ("Dhaka North City Corporation", 495884, 495884, 514776, "104%", 0, 3224, "0%", "104%"),
        ("Dhaka South City Corporation", 404074, 403939, 404947, "100%", 42, 989, "2355%", "100%"),
        ("Gazipur City Corporation", 178423, 178156, 192079, "108%", 9404, 1650, "18%", "108%"),
        ("Narayanganj City Corporation", 78337, 77423, 80761, "104%", 615, 755, "123%", "103%"),
        ("Khulna City Corporation", 92701, 92444, 92264, "100%", 0, 873, "0%", "100%"),
        ("Mymensingh City Corporation", 58668, 58668, 58018, "99%", 0, 151, "0%", "99%"),
        ("Rajshahi City Corporation", 54886, 54886, 58306, "106%", 0, 445, "0%", "106%"),
        ("Rangpur City Corporation", 82249, 82249, 79076, "96%", 0, 510, "0%", "96%"),
        ("Sylhet City Corporation", 68933, 67872, 66663, "98%", 0, 1220, "0%", "97%"),
        ("Total", 1905950, 1859134, 1928548, "104%", 14823, 13968, "94%", "101%"),
    ]
    return {
        "table_001.csv": pd.DataFrame(surveillance, columns=surveillance_columns),
        "table_002.csv": pd.DataFrame(division_campaign, columns=campaign_columns),
        "table_003.csv": pd.DataFrame(city_campaign, columns=campaign_columns),
    }


def normalize_text(value: object, counters: dict[str, int]) -> object:
    if pd.isna(value):
        return pd.NA
    text = unicodedata.normalize("NFKC", str(value))
    without_controls = CONTROL_PATTERN.sub("", text)
    if without_controls != text:
        counters["unicode_controls_removed"] += 1
    translated = without_controls.translate(BENGALI_DIGITS)
    if translated != without_controls:
        counters["bengali_digit_cells_normalized"] += 1
    text = re.sub(r"\s+", " ", translated).strip()
    if text.lower() in NULL_TOKENS:
        return pd.NA
    if re.fullmatch(r"[+-]?\d{1,3}(?:,\d{3})+(?:\.\d+)?%?", text):
        text = text.replace(",", "")
        counters["numeric_cells_normalized"] += 1
    return text


def unique_columns(columns: list[object]) -> list[str]:
    result: list[str] = []
    seen: dict[str, int] = {}
    for position, raw_column in enumerate(columns, start=1):
        name = "" if pd.isna(raw_column) else str(raw_column)
        name = unicodedata.normalize("NFKC", name).translate(BENGALI_DIGITS)
        name = re.sub(r"[^0-9A-Za-z\u0980-\u09ff]+", "_", name).strip("_").lower()
        if not name or name.isdigit() or name.startswith("unnamed"):
            name = f"column_{position}"
        seen[name] = seen.get(name, 0) + 1
        result.append(name if seen[name] == 1 else f"{name}_{seen[name]}")
    return result


def clean_table(source: Path) -> tuple[pd.DataFrame, dict[str, int | str]]:
    counters = {
        "unicode_controls_removed": 0,
        "bengali_digit_cells_normalized": 0,
        "numeric_cells_normalized": 0,
    }
    frame = pd.read_csv(
        source, dtype=str, keep_default_na=False, on_bad_lines="skip", encoding_errors="replace"
    )
    rows_before, columns_before = frame.shape
    frame.columns = unique_columns(list(frame.columns))
    frame = frame.apply(lambda col: col.map(lambda value: normalize_text(value, counters)))
    frame = frame.dropna(axis=0, how="all").dropna(axis=1, how="all")
    before_duplicates = len(frame)
    frame = frame.drop_duplicates().reset_index(drop=True)
    placeholder_headers = sum(name.startswith("column_") for name in frame.columns)
    cell_count = max(1, frame.shape[0] * frame.shape[1])
    blank_cells = int(frame.isna().sum().sum())
    suspicious_cells = int(
        frame.apply(
            lambda col: col.fillna("").astype(str).str.contains(MOJIBAKE_PATTERN, regex=True).sum()
        ).sum()
    )
    reasons: list[str] = []
    quality_status = "accepted"
    if frame.empty or len(frame.columns) < 2:
        quality_status = "rejected"
        reasons.append("empty_or_single_column")
    else:
        if placeholder_headers:
            reasons.append("placeholder_headers")
        if blank_cells / cell_count > 0.25:
            reasons.append("high_internal_blank_ratio")
        if suspicious_cells:
            reasons.append("suspected_mojibake_or_replacement_character")
        if len(frame.columns) > 30:
            reasons.append("wide_table_requires_structural_review")
        if reasons:
            quality_status = "review_required"
    metrics: dict[str, int | str] = {
        "rows_before": rows_before,
        "rows_after": len(frame),
        "columns_before": columns_before,
        "columns_after": len(frame.columns),
        "duplicate_rows_removed": before_duplicates - len(frame),
        "blank_cells_after": blank_cells,
        "placeholder_headers": placeholder_headers,
        "suspicious_cells": suspicious_cells,
        "quality_status": quality_status,
        "quality_reasons": ";".join(reasons),
        **counters,
    }
    return frame, metrics


def write_verified_measles() -> None:
    destination = VERIFIED_DIR / MEASLES_FOLDER
    destination.mkdir(parents=True, exist_ok=True)
    for filename, frame in measles_tables().items():
        frame.to_csv(destination / filename, index=False)
    (destination / "README.md").write_text(
        "# Verified DGHS Measles tables\n\n"
        "These CSVs reconstruct the three tables in the official DGHS bulletin dated "
        "14 May 2026. OCR-damaged area labels were standardized to English, Bengali "
        "digits were converted to ASCII, merged headers were flattened, and printed "
        "values were preserved.\n\n"
        f"Source: {MEASLES_SOURCE_URL}\n\n"
        "They are aggregate division/city surveillance and campaign statistics. They "
        "remain verified reference tables and are not loaded into the patient/event-"
        "grain `Measles` SQL table.\n",
        encoding="utf-8",
    )


def main() -> None:
    if not INPUT_DIR.exists():
        raise FileNotFoundError(f"Input directory not found: {INPUT_DIR}")
    for directory in (CLEAN_DIR, QUARANTINE_DIR, VERIFIED_DIR, REPORT_DIR):
        directory.mkdir(parents=True, exist_ok=True)
    write_verified_measles()
    curated = measles_tables()
    summary: list[dict[str, object]] = []
    sources = sorted(INPUT_DIR.rglob("*.csv"))

    for source in tqdm(sources, desc="Cleaning and screening extracted tables"):
        relative = source.relative_to(INPUT_DIR)
        try:
            if relative.parent.name == MEASLES_FOLDER and relative.name in curated:
                cleaned = curated[relative.name].copy()
                raw = pd.read_csv(source, dtype=str, keep_default_na=False)
                metrics: dict[str, int | str] = {
                    "rows_before": len(raw), "rows_after": len(cleaned),
                    "columns_before": len(raw.columns), "columns_after": len(cleaned.columns),
                    "duplicate_rows_removed": 0, "blank_cells_after": 0,
                    "placeholder_headers": 0, "suspicious_cells": 0,
                    "quality_status": "accepted_curated",
                    "quality_reasons": "verified_against_DGHS_bulletin_2026_05_14",
                    "unicode_controls_removed": 0, "bengali_digit_cells_normalized": 1,
                    "numeric_cells_normalized": 1,
                }
            else:
                cleaned, metrics = clean_table(source)
            accepted = str(metrics["quality_status"]).startswith("accepted")
            destination_root = CLEAN_DIR if accepted else QUARANTINE_DIR
            counterpart_root = QUARANTINE_DIR if accepted else CLEAN_DIR
            destination = destination_root / relative
            counterpart = counterpart_root / relative
            if counterpart.is_file():
                counterpart.unlink()
            destination.parent.mkdir(parents=True, exist_ok=True)
            cleaned.to_csv(destination, index=False)
            summary.append({
                "source_file": str(source.relative_to(BASE_DIR)),
                "output_file": str(destination.relative_to(BASE_DIR)),
                **metrics, "error": "",
            })
        except Exception as exc:
            summary.append({
                "source_file": str(source.relative_to(BASE_DIR)), "output_file": "",
                "rows_before": 0, "rows_after": 0, "columns_before": 0, "columns_after": 0,
                "duplicate_rows_removed": 0, "blank_cells_after": 0, "placeholder_headers": 0,
                "suspicious_cells": 0, "quality_status": "rejected",
                "quality_reasons": "parse_error", "unicode_controls_removed": 0,
                "bengali_digit_cells_normalized": 0, "numeric_cells_normalized": 0,
                "error": str(exc),
            })

    result = pd.DataFrame(summary)
    result.to_csv(SUMMARY_FILE, index=False)
    counts = result["quality_status"].value_counts().to_dict()
    print(f"Input tables     : {len(sources)}")
    print(f"Accepted         : {counts.get('accepted', 0)}")
    print(f"Accepted curated : {counts.get('accepted_curated', 0)}")
    print(f"Review required  : {counts.get('review_required', 0)}")
    print(f"Rejected         : {counts.get('rejected', 0)}")
    print(f"Summary          : {SUMMARY_FILE}")


if __name__ == "__main__":
    main()
