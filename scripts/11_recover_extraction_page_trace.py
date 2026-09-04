#!/usr/bin/env python3

"""Reconcile every raw CSV with source-document/page evidence where available.

Existing extractor metadata is authoritative.  For legacy large-document folders
that pre-date committed metadata, exact table hashes are recovered by re-reading
the archived PDF.  A conservative weighted-token match is used only when an exact
table hash is unavailable.  Unresolved pages remain explicitly unresolved and are
never guessed or made SQL-loadable.
"""

from __future__ import annotations

import argparse
import gc
import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path

import pandas as pd
import pdfplumber


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "extracted_tables"
PDF_DIR = ROOT / "pdfs"
METADATA_DIR = ROOT / "metadata"
REPORT_DIR = ROOT / "reports"
OUTPUT = REPORT_DIR / "extraction_page_trace.csv"
SUMMARY = REPORT_DIR / "extraction_page_trace_summary.txt"
CACHE_FILE = REPORT_DIR / "page_trace_recovery_cache.json"
TOKEN_PATTERN = re.compile(r"[A-Za-z]{4,}|[0-9]{3,}|[\u0980-\u09ff]{3,}")
# The 2015 bulletin is an image-heavy 87 MB legacy PDF for which full table
# re-extraction is not bounded reliably. Its 53 raw outputs stay review-blocked
# with document-level provenance instead of receiving guessed page numbers.
SKIP_PAGE_RECOVERY_FOLDERS = {"035_Health_Bulletin_2015"}


def frame_hash(frame: pd.DataFrame) -> str:
    return hashlib.md5(
        frame.fillna("").astype(str).to_csv(index=False).encode("utf-8")
    ).hexdigest()


def raw_hash(path: Path) -> str:
    frame = pd.read_csv(
        path, dtype=str, keep_default_na=False, on_bad_lines="skip", encoding_errors="replace"
    )
    return frame_hash(frame)


def tokens(text: str) -> set[str]:
    return {token.lower() for token in TOKEN_PATTERN.findall(text)}


def metadata_records() -> tuple[dict[str, dict[str, object]], dict[str, dict[str, object]]]:
    page_records: dict[str, dict[str, object]] = {}
    source_records: dict[str, dict[str, object]] = {}
    for path in sorted(METADATA_DIR.glob("*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        folder = path.stem
        source_records[folder] = payload
        for item in payload.get("tables", []):
            filename = str(item.get("file", ""))
            if filename:
                page_records[f"extracted_tables/{folder}/{filename}"] = item
        for item in payload.get("extracted_tables", []):
            filename = str(item.get("file", ""))
            if filename:
                page_records[filename] = {**item, "digital_source": True}
    return page_records, source_records


def source_document(folder: str, payload: dict[str, object] | None) -> str:
    payload = payload or {}
    if payload.get("pdf"):
        return str(payload["pdf"])
    raw_files = payload.get("raw_files", [])
    if raw_files:
        return str(raw_files[0].get("file", ""))
    return f"{folder}.pdf"


def conservative_token_pages(
    unresolved: list[Path], page_tokens: dict[int, set[str]]
) -> dict[str, tuple[int, float, int]]:
    if not page_tokens:
        return {}
    page_frequency: Counter[str] = Counter()
    for values in page_tokens.values():
        page_frequency.update(values)
    page_count = len(page_tokens)
    recovered: dict[str, tuple[int, float, int]] = {}
    for raw in unresolved:
        try:
            frame = pd.read_csv(
                raw, dtype=str, keep_default_na=False, on_bad_lines="skip", encoding_errors="replace"
            )
        except Exception:
            continue
        table_tokens = tokens(
            " ".join(map(str, frame.columns))
            + " "
            + " ".join(frame.fillna("").astype(str).values.flatten())
        )
        if len(table_tokens) < 3:
            continue
        weights = {
            token: math.log((page_count + 1) / (page_frequency.get(token, 0) + 1)) + 1
            for token in table_tokens
        }
        denominator = sum(weights.values()) or 1.0
        scores: list[tuple[float, int, int]] = []
        for page, values in page_tokens.items():
            common = table_tokens & values
            score = sum(weights[token] for token in common) / denominator
            scores.append((score, page, len(common)))
        scores.sort(reverse=True)
        best_score, best_page, common_count = scores[0]
        runner_up = scores[1][0] if len(scores) > 1 else 0.0
        strong = common_count >= 4 and best_score >= 0.45 and best_score - runner_up >= 0.10
        very_strong = common_count >= 3 and best_score >= 0.70
        if strong or very_strong:
            recovered[str(raw.relative_to(ROOT))] = (best_page, best_score, common_count)
    return recovered


def recover_folder(folder: Path) -> dict[str, dict[str, object]]:
    pdf_path = PDF_DIR / f"{folder.name}.pdf"
    if not pdf_path.is_file() or pdf_path.read_bytes()[:5] != b"%PDF-":
        return {}
    raw_files = sorted(folder.glob("*.csv"))
    by_hash: dict[str, list[Path]] = defaultdict(list)
    for path in raw_files:
        try:
            by_hash[raw_hash(path)].append(path)
        except Exception:
            pass
    exact: dict[str, dict[str, object]] = {}
    page_tokens: dict[int, set[str]] = {}
    with pdfplumber.open(pdf_path) as pdf:
        for page_number, page in enumerate(pdf.pages, start=1):
            try:
                page_tokens[page_number] = tokens(page.extract_text() or "")
            except Exception:
                page_tokens[page_number] = set()
            try:
                page_tables = page.extract_tables() or []
            except Exception:
                page_tables = []
            for table in page_tables:
                frame = pd.DataFrame(table).dropna(axis=0, how="all").dropna(axis=1, how="all")
                if len(frame) < 5 or len(frame.columns) < 2:
                    continue
                value_hash = frame_hash(frame)
                for raw in by_hash.get(value_hash, []):
                    relative = str(raw.relative_to(ROOT))
                    exact.setdefault(
                        relative,
                        {
                            "source_page": page_number,
                            "trace_method": "recovered_exact_table_hash",
                            "trace_confidence": "1.000000",
                            "matched_token_count": "",
                        },
                    )
            page.flush_cache()
            if page_number % 10 == 0:
                gc.collect()
    unresolved = [path for path in raw_files if str(path.relative_to(ROOT)) not in exact]
    for relative, (page, score, common) in conservative_token_pages(unresolved, page_tokens).items():
        exact[relative] = {
            "source_page": page,
            "trace_method": "recovered_conservative_token_match",
            "trace_confidence": f"{score:.6f}",
            "matched_token_count": common,
        }
    return exact


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--recover-pages",
        action="store_true",
        help="scan archived PDFs to recover page numbers for legacy metadata gaps",
    )
    args = parser.parse_args()
    page_metadata, sources = metadata_records()
    raw_files = sorted(RAW_DIR.rglob("*.csv"))
    folders = sorted({path.parent for path in raw_files})
    recovered: dict[str, dict[str, object]] = {}
    if args.recover_pages:
        cache = {"completed_folders": [], "recovered": {}}
        if CACHE_FILE.is_file():
            try:
                cache = json.loads(CACHE_FILE.read_text(encoding="utf-8"))
            except Exception:
                cache = {"completed_folders": [], "recovered": {}}
        completed = set(cache.get("completed_folders", []))
        recovered.update(cache.get("recovered", {}))
        missing_folders = [
            folder
            for folder in folders
            if folder.name not in SKIP_PAGE_RECOVERY_FOLDERS
            if not any(
                str(path.relative_to(ROOT)) in page_metadata for path in folder.glob("*.csv")
            )
        ]
        for position, folder in enumerate(missing_folders, start=1):
            if folder.name in completed:
                print(f"[{position}/{len(missing_folders)}] cached {folder.name}", flush=True)
                continue
            print(f"[{position}/{len(missing_folders)}] recovering {folder.name}", flush=True)
            recovered.update(recover_folder(folder))
            completed.add(folder.name)
            CACHE_FILE.write_text(
                json.dumps(
                    {"completed_folders": sorted(completed), "recovered": recovered},
                    indent=2,
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

    records: list[dict[str, object]] = []
    for raw in raw_files:
        relative = str(raw.relative_to(ROOT))
        folder = raw.parent.name
        payload = sources.get(folder)
        source = source_document(folder, payload)
        if relative in page_metadata:
            item = page_metadata[relative]
            if item.get("digital_source"):
                page, method, confidence, matched = "", "digital_source_metadata", "1.000000", ""
            else:
                page, method, confidence, matched = (
                    item.get("page", ""), "original_exact_page_metadata", "1.000000", ""
                )
        elif relative in recovered:
            item = recovered[relative]
            page, method, confidence, matched = (
                item["source_page"], item["trace_method"],
                item["trace_confidence"], item["matched_token_count"],
            )
        else:
            pdf_path = PDF_DIR / f"{folder}.pdf"
            source_available = pdf_path.is_file() and pdf_path.read_bytes()[:5] == b"%PDF-"
            page, confidence, matched = "", "0.000000", ""
            method = "unresolved_page_review_required" if source_available else "source_document_unavailable"
        records.append(
            {
                "raw_file": relative,
                "raw_sha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                "source_document": source,
                "source_page": page,
                "trace_method": method,
                "trace_confidence": confidence,
                "matched_token_count": matched,
                "sql_load_policy": "blocked_unless_separately_verified_and_explicitly_mapped",
            }
        )
    result = pd.DataFrame(records)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    result.to_csv(OUTPUT, index=False)
    counts = result["trace_method"].value_counts().to_dict()
    traced = int((result["trace_confidence"].astype(float) > 0).sum())
    summary_lines = [
        "EXTRACTION PAGE-TRACE RECONCILIATION",
        "",
        f"raw_tables={len(result)}",
        f"raw_tables_with_source_document={result['source_document'].ne('').sum()}",
        f"page_or_digital_source_traced={traced}",
        f"original_exact_page_metadata={counts.get('original_exact_page_metadata', 0)}",
        f"recovered_exact_table_hash={counts.get('recovered_exact_table_hash', 0)}",
        f"recovered_conservative_token_match={counts.get('recovered_conservative_token_match', 0)}",
        f"digital_source_metadata={counts.get('digital_source_metadata', 0)}",
        f"unresolved_page_review_required={counts.get('unresolved_page_review_required', 0)}",
        f"source_document_unavailable={counts.get('source_document_unavailable', 0)}",
        "unresolved_or_unavailable_sql_loadable=0",
    ]
    SUMMARY.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")
    if args.recover_pages and CACHE_FILE.is_file():
        CACHE_FILE.unlink()
    print("\n".join(summary_lines))
    print(f"trace_file={OUTPUT.relative_to(ROOT)}")
    print(f"summary_file={SUMMARY.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
