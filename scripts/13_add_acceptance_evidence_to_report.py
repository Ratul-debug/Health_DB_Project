#!/usr/bin/env python3

"""Add concise acceptance evidence to the final report without repagination."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

import pymupdf as fitz


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "PROJECT_REPORT.pdf"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
NOTES = (
    "4. Verified loaded extraction: 4 tracked CSVs, 67,690 rows, 12 reconciled target columns, blank/NULL 0. "
    "Evidence: reports/source_column_reconciliation.csv. normalized_sql_tables/ provides 21 schema-exact "
    "CSV relations matching all 68,185 SQL rows."
)


def main() -> None:
    pdf = fitz.open(REPORT)
    full_text = "\n".join(page.get_text() for page in pdf)
    commands = [
        "python scripts/10_audit_all_extracted_tables.py",
        "python scripts/12_export_verified_relational_tables.py",
        "python scripts/09_validate_supervisor_corrections.py",
        "mysql -u healthuser -p < sql/health_db_21_tables_with_data.sql",
        "mysql -u healthuser -p < sql/validation/validation_queries.sql",
    ]
    notes_present = "Verified loaded extraction: 4 tracked" in full_text
    if notes_present and all(command in full_text for command in commands):
        pdf.close()
        print("Acceptance evidence already present; no change made.")
        return

    commands_page = pdf[41]
    commands_page.add_redact_annot(fitz.Rect(66, 386, 348, 432), fill=(1, 1, 1))
    commands_page.apply_redactions()
    mono_name = "AcceptanceMono"
    commands_page.insert_font(fontname=mono_name, fontfile=MONO)
    for index, command in enumerate(commands):
        commands_page.insert_text(
            fitz.Point(68, 395.9 + index * 6.817),
            command,
            fontsize=6.8,
            fontname=mono_name,
            color=(0, 0, 0),
        )

    if not notes_present:
        normalization_page = pdf[43]
        serif_name = "AcceptanceSerif"
        normalization_page.insert_font(fontname=serif_name, fontfile=SERIF)
        remaining = normalization_page.insert_textbox(
            fitz.Rect(80, 715, 515, 740),
            NOTES,
            fontsize=7.0,
            fontname=serif_name,
            color=(0, 0, 0),
            lineheight=1.0,
        )
        if remaining < 0:
            pdf.close()
            raise RuntimeError("Acceptance evidence did not fit on report page 44")

    descriptor, temporary_name = tempfile.mkstemp(
        prefix="project_report_acceptance_", suffix=".pdf", dir=ROOT
    )
    os.close(descriptor)
    temporary_path = Path(temporary_name)
    try:
        pdf.save(temporary_path, garbage=4, deflate=True)
        pdf.close()
        temporary_path.replace(REPORT)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()
    print("Updated PROJECT_REPORT.pdf with clean-extraction and relational-export evidence.")


if __name__ == "__main__":
    main()
