#!/usr/bin/env python3

"""Audit structure integrity, OCR risk, provenance and load safety for every raw CSV.

The raw ``extracted_tables`` directory is immutable evidence.  This script never
rewrites or deletes a source table.  It produces one auditable decision per raw
CSV and reconciles that decision with cleaning and source-to-schema mapping
reports.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import unicodedata
from collections import Counter
from pathlib import Path

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "extracted_tables"
METADATA_DIR = BASE_DIR / "metadata"
REPORT_DIR = BASE_DIR / "reports"
CLEANING_FILE = REPORT_DIR / "cleaning_summary.csv"
MAPPING_FILE = REPORT_DIR / "source_to_schema_mapping.csv"
AUDIT_FILE = REPORT_DIR / "structure_ocr_integrity_audit.csv"
SUMMARY_FILE = REPORT_DIR / "structure_ocr_integrity_summary.txt"
PAGE_TRACE_FILE = REPORT_DIR / "extraction_page_trace.csv"

MEASLES_FOLDER = "086_Measles_Update_Till_14_05_26_"
CONTROL_PATTERN = re.compile(
    r"[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\u200b-\u200f\u202a-\u202e\u2060\ufeff]"
)
MOJIBAKE_PATTERN = re.compile(r"(?:\ufffd|Ã.|Â.|â€|ðŸ)")
LATIN_PATTERN = re.compile(r"[A-Za-z]")
BENGALI_PATTERN = re.compile(r"[\u0980-\u09ff]")
SUSPICIOUS_OCR_TOKEN = re.compile(
    r"(?:[|]{2,}|[_]{3,}|\?{3,}|[A-Za-z]\d[A-Za-z]|\d[A-Za-z]\d|\b(?:l{4,}|I{4,})\b)"
)


def normalized_header(value: object) -> str:
    text = unicodedata.normalize("NFKC", str(value or ""))
    return re.sub(r"\s+", " ", text).strip().lower()


def metadata_index() -> tuple[dict[str, dict[str, object]], dict[str, str]]:
    table_index: dict[str, dict[str, object]] = {}
    documents: dict[str, str] = {}
    for metadata_file in sorted(METADATA_DIR.glob("*.json")):
        try:
            payload = json.loads(metadata_file.read_text(encoding="utf-8"))
        except Exception:
            continue
        folder = metadata_file.stem
        raw_files = payload.get("raw_files", [])
        document = str(
            payload.get("pdf")
            or (raw_files[0].get("file", "") if raw_files else "")
            or f"{folder}.pdf"
        )
        documents[folder] = document
        for item in payload.get("tables", []):
            file_name = str(item.get("file", ""))
            if file_name:
                table_index[f"extracted_tables/{folder}/{file_name}"] = {
                    **item,
                    "_trace_status": "exact_page_metadata",
                }
        for item in payload.get("extracted_tables", []):
            table_file = str(item.get("file", ""))
            if table_file:
                table_index[table_file] = {
                    **item,
                    "_trace_status": "source_dataset_metadata",
                }
    return table_index, documents


def load_lookup(path: Path, key: str) -> dict[str, dict[str, object]]:
    if not path.is_file():
        raise FileNotFoundError(path)
    frame = pd.read_csv(path, keep_default_na=False)
    if key not in frame.columns:
        raise ValueError(f"Missing {key!r} in {path}")
    return {str(row[key]): row for row in frame.to_dict("records")}


def csv_shape(path: Path) -> tuple[list[list[str]], int, int, int]:
    with path.open("r", encoding="utf-8-sig", errors="replace", newline="") as stream:
        rows = list(csv.reader(stream))
    if not rows:
        return [], 0, 0, 0
    expected = len(rows[0])
    ragged = sum(len(row) != expected for row in rows[1:])
    width = max([expected, *(len(row) for row in rows[1:])], default=expected)
    padded = [row + [""] * (width - len(row)) for row in rows]
    return padded, max(0, len(rows) - 1), width, ragged


def audit_table(
    raw_path: Path,
    metadata: dict[str, dict[str, object]],
    documents: dict[str, str],
    page_trace: dict[str, dict[str, object]],
    cleaning: dict[str, dict[str, object]],
    mapping: dict[str, dict[str, object]],
) -> dict[str, object]:
    relative = str(raw_path.relative_to(BASE_DIR))
    folder = raw_path.parent.name
    raw_sha256 = hashlib.sha256(raw_path.read_bytes()).hexdigest()
    issues_structure: list[str] = []
    issues_ocr: list[str] = []
    parse_status = "ok"
    try:
        rows, data_rows, columns, ragged_rows = csv_shape(raw_path)
    except Exception as exc:
        rows, data_rows, columns, ragged_rows = [], 0, 0, 0
        parse_status = f"error:{type(exc).__name__}"
        issues_structure.append("csv_parse_error")

    header = rows[0] if rows else []
    data = rows[1:] if rows else []
    normalized_headers = [normalized_header(value) for value in header]
    header_counts = Counter(normalized_headers)
    blank_headers = sum(not value for value in normalized_headers)
    duplicate_headers = sum(count - 1 for value, count in header_counts.items() if value and count > 1)
    numeric_headers = sum(bool(re.fullmatch(r"\d+(?:\.\d+)?", value)) for value in normalized_headers)
    placeholder_headers = sum(
        not value or bool(re.fullmatch(r"(?:unnamed_?)?\d*|column_?\d+", value))
        for value in normalized_headers
    )
    cells = [cell for row in data for cell in row]
    total_cells = max(1, len(cells))
    blank_cells = sum(not str(cell).strip() for cell in cells)
    blank_ratio = blank_cells / total_cells
    empty_rows = sum(not any(str(cell).strip() for cell in row) for row in data)
    empty_columns = sum(
        not any(str(row[index]).strip() for row in data)
        for index in range(columns)
    ) if columns else 0
    multiline_cells = sum("\n" in str(cell) or "\r" in str(cell) for cell in cells)
    replacement_cells = sum("\ufffd" in str(cell) for cell in cells)
    control_cells = sum(bool(CONTROL_PATTERN.search(str(cell))) for cell in cells)
    mojibake_cells = sum(bool(MOJIBAKE_PATTERN.search(str(cell))) for cell in cells)
    mixed_script_cells = sum(
        bool(LATIN_PATTERN.search(str(cell)) and BENGALI_PATTERN.search(str(cell))) for cell in cells
    )
    suspicious_ocr_cells = sum(bool(SUSPICIOUS_OCR_TOKEN.search(str(cell))) for cell in cells)

    if not rows or data_rows == 0 or columns < 2:
        issues_structure.append("empty_or_single_column")
    if ragged_rows:
        issues_structure.append("ragged_csv_rows")
    if blank_headers:
        issues_structure.append("blank_headers")
    if duplicate_headers:
        issues_structure.append("duplicate_headers")
    if numeric_headers:
        issues_structure.append("numeric_headers")
    if placeholder_headers:
        issues_structure.append("placeholder_headers")
    if blank_ratio > 0.25:
        issues_structure.append("high_internal_blank_ratio")
    if empty_rows:
        issues_structure.append("empty_rows")
    if empty_columns:
        issues_structure.append("empty_columns")
    if multiline_cells:
        issues_structure.append("multiline_or_merged_cells")
    trace = metadata.get(relative, {})
    recovered_trace = page_trace.get(relative, {})
    trace_status = str(
        recovered_trace.get("trace_method") or trace.get("_trace_status", "")
    )
    digital_source = trace_status in {"source_dataset_metadata", "digital_source_metadata"}

    if replacement_cells:
        issues_ocr.append("replacement_character")
    if control_cells:
        issues_ocr.append("unicode_control_character")
    if mojibake_cells:
        issues_ocr.append("mojibake_pattern")
    if suspicious_ocr_cells and not digital_source:
        issues_ocr.append("suspicious_ocr_token_pattern")
    if mixed_script_cells:
        issues_ocr.append("mixed_bengali_latin_cell_review")

    source_page = recovered_trace.get("source_page", trace.get("page", ""))
    source_document = str(
        recovered_trace.get("source_document")
        or documents.get(folder, f"{folder}.pdf")
    )
    if recovered_trace:
        trace_status = str(recovered_trace.get("trace_method", ""))
    elif trace:
        trace_status = str(trace.get("_trace_status", "exact_page_metadata"))
    else:
        trace_status = "document_only_metadata_recovery_required"

    clean_row = cleaning.get(relative, {})
    clean_status = str(clean_row.get("quality_status", "missing_quality_decision"))
    output_file = str(clean_row.get("output_file", ""))
    map_row = mapping.get(output_file, {}) if output_file else {}
    mapping_status = str(map_row.get("mapping_status", "missing_mapping_decision"))
    load_eligible = str(map_row.get("load_eligible", "no"))
    loaded_rows = int(map_row.get("loaded_rows", 0) or 0)

    is_curated_measles = folder == MEASLES_FOLDER and raw_path.name in {
        "table_001.csv", "table_002.csv", "table_003.csv"
    }
    if parse_status != "ok" or "ragged_csv_rows" in issues_structure:
        structure_status = "reject"
    elif issues_structure:
        structure_status = "review"
    else:
        structure_status = "pass"
    ocr_status = "review" if issues_ocr else ("not_applicable_digital_source" if digital_source else "pass")
    if is_curated_measles:
        overall_status = "pass_source_verified_curated_output"
        corrected_output = (
            f"verified_tables/{MEASLES_FOLDER}/{raw_path.name}"
        )
    elif (
        clean_status == "accepted"
        and structure_status == "pass"
        and ocr_status in {"pass", "not_applicable_digital_source"}
    ):
        overall_status = "pass_automatic_clean_output"
        corrected_output = output_file
    elif clean_status == "rejected" or structure_status == "reject":
        overall_status = "reject_blocked_raw_evidence"
        corrected_output = output_file
    else:
        overall_status = "review_blocked_raw_evidence"
        corrected_output = output_file

    reasons = [*issues_structure, *issues_ocr]
    if trace_status in {
        "document_only_metadata_recovery_required",
        "unresolved_page_review_required",
        "source_document_unavailable",
    }:
        reasons.append("page_metadata_recovery_required")
    if not reasons:
        reasons.append("no_structure_or_ocr_indicator_detected")

    return {
        "raw_file": relative,
        "raw_sha256": raw_sha256,
        "source_document": source_document,
        "source_page": source_page,
        "trace_status": trace_status,
        "parse_status": parse_status,
        "data_rows": data_rows,
        "columns": columns,
        "ragged_rows": ragged_rows,
        "blank_headers": blank_headers,
        "duplicate_headers": duplicate_headers,
        "numeric_headers": numeric_headers,
        "placeholder_headers": placeholder_headers,
        "blank_cells": blank_cells,
        "blank_cell_ratio": round(blank_ratio, 6),
        "empty_rows": empty_rows,
        "empty_columns": empty_columns,
        "multiline_cells": multiline_cells,
        "replacement_character_cells": replacement_cells,
        "control_character_cells": control_cells,
        "mojibake_cells": mojibake_cells,
        "mixed_script_cells": mixed_script_cells,
        "suspicious_ocr_cells": suspicious_ocr_cells,
        "structure_status": structure_status,
        "ocr_status": ocr_status,
        "cleaning_quality_status": clean_status,
        "mapping_status": mapping_status,
        "sql_load_eligible": load_eligible,
        "loaded_rows": loaded_rows,
        "corrected_or_screened_output": corrected_output,
        "overall_status": overall_status,
        "decision_reasons": ";".join(dict.fromkeys(reasons)),
        "raw_retention_policy": "retain_immutable_evidence",
    }


def main() -> None:
    if not RAW_DIR.is_dir():
        raise FileNotFoundError(RAW_DIR)
    metadata, documents = metadata_index()
    page_trace = (
        load_lookup(PAGE_TRACE_FILE, "raw_file") if PAGE_TRACE_FILE.is_file() else {}
    )
    cleaning = load_lookup(CLEANING_FILE, "source_file")
    mapping = load_lookup(MAPPING_FILE, "pipeline_file")
    records = [
        audit_table(path, metadata, documents, page_trace, cleaning, mapping)
        for path in sorted(RAW_DIR.rglob("*.csv"))
    ]
    result = pd.DataFrame(records)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    result.to_csv(AUDIT_FILE, index=False)

    status_counts = result["overall_status"].value_counts().to_dict()
    structure_counts = result["structure_status"].value_counts().to_dict()
    ocr_counts = result["ocr_status"].value_counts().to_dict()
    trace_counts = result["trace_status"].value_counts().to_dict()
    summary = [
        "ARCHIVE-WIDE STRUCTURE AND OCR INTEGRITY AUDIT",
        "",
        f"raw_tables_audited={len(result)}",
        f"unique_raw_files={result['raw_file'].nunique()}",
        f"missing_quality_decisions={(result['cleaning_quality_status'] == 'missing_quality_decision').sum()}",
        f"missing_mapping_decisions={(result['mapping_status'] == 'missing_mapping_decision').sum()}",
        f"structure_pass={structure_counts.get('pass', 0)}",
        f"structure_review={structure_counts.get('review', 0)}",
        f"structure_reject={structure_counts.get('reject', 0)}",
        f"ocr_pass={ocr_counts.get('pass', 0)}",
        f"ocr_review={ocr_counts.get('review', 0)}",
        f"ocr_not_applicable_digital_source={ocr_counts.get('not_applicable_digital_source', 0)}",
        f"original_exact_page_metadata={trace_counts.get('original_exact_page_metadata', 0) + trace_counts.get('exact_page_metadata', 0)}",
        f"recovered_exact_table_hash={trace_counts.get('recovered_exact_table_hash', 0)}",
        f"recovered_conservative_token_match={trace_counts.get('recovered_conservative_token_match', 0)}",
        f"source_dataset_metadata={trace_counts.get('digital_source_metadata', 0) + trace_counts.get('source_dataset_metadata', 0)}",
        f"unresolved_page_review_required={trace_counts.get('unresolved_page_review_required', 0)}",
        f"source_document_unavailable={trace_counts.get('source_document_unavailable', 0)}",
        f"automatic_clean_pass={status_counts.get('pass_automatic_clean_output', 0)}",
        f"source_verified_curated_pass={status_counts.get('pass_source_verified_curated_output', 0)}",
        f"review_blocked={status_counts.get('review_blocked_raw_evidence', 0)}",
        f"reject_blocked={status_counts.get('reject_blocked_raw_evidence', 0)}",
        f"raw_files_deleted=0",
        "raw_retention_policy=retain immutable evidence; never SQL-load unapproved raw output",
    ]
    SUMMARY_FILE.write_text("\n".join(summary) + "\n", encoding="utf-8")
    print("\n".join(summary))
    print(f"audit_file={AUDIT_FILE.relative_to(BASE_DIR)}")
    print(f"summary_file={SUMMARY_FILE.relative_to(BASE_DIR)}")


if __name__ == "__main__":
    main()
