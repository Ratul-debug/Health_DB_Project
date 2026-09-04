#!/usr/bin/env python3

"""Validate the archive-wide ETL controls introduced after supervisor review."""

from __future__ import annotations

import json
import re
from pathlib import Path

import pymupdf as fitz
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports"
OUTPUT = REPORTS / "supervisor_correction_validation.txt"
MEASLES = ROOT / "verified_tables" / "086_Measles_Update_Till_14_05_26_"


def require(condition: bool, name: str, lines: list[str]) -> None:
    if not condition:
        raise AssertionError(name)
    lines.append(f"{name}=PASS")


def totals_reconcile(frame: pd.DataFrame, numeric_columns: list[str]) -> bool:
    detail = frame.iloc[:-1]
    total = frame.iloc[-1]
    return all(int(detail[column].sum()) == int(total[column]) for column in numeric_columns)


def main() -> None:
    lines = ["SUPERVISOR CORRECTION VALIDATION", ""]
    cleaning = pd.read_csv(REPORTS / "cleaning_summary.csv", keep_default_na=False)
    catalog = pd.read_csv(REPORTS / "table_catalog.csv", keep_default_na=False)
    classified = pd.read_csv(REPORTS / "classified_tables.csv", keep_default_na=False)
    mapping = pd.read_csv(REPORTS / "source_to_schema_mapping.csv", keep_default_na=False)

    require(len(cleaning) == 3802, "all_3802_raw_tables_screened", lines)
    require(cleaning["source_file"].is_unique, "one_quality_decision_per_raw_table", lines)
    require(not cleaning["quality_status"].eq("").any(), "no_missing_quality_status", lines)
    require(len(catalog) == len(classified) == len(mapping) == 3807, "all_3807_pipeline_outputs_reconciled", lines)
    require(not mapping["mapping_status"].eq("").any(), "no_missing_mapping_decision", lines)
    require(
        set(mapping.loc[mapping["load_eligible"] == "yes", "mapping_status"]) == {"loaded_by_migration_006"},
        "only_explicit_mappings_load_eligible",
        lines,
    )
    require(int(mapping["loaded_rows"].sum()) == 67690, "migration_006_lineage_rows_67690", lines)
    require((classified["classification_status"] != "").all(), "no_forced_or_unexplained_classification", lines)

    measles_files = sorted(MEASLES.glob("table_*.csv"))
    require(len(measles_files) == 3, "three_verified_measles_tables", lines)
    frames = {path.name: pd.read_csv(path) for path in measles_files}
    require(sum(int(frame.isna().sum().sum()) for frame in frames.values()) == 0, "measles_blank_cells_zero", lines)
    surveillance_columns = list(frames["table_001.csv"].columns[1:])
    require(totals_reconcile(frames["table_001.csv"], surveillance_columns), "measles_surveillance_totals_reconcile", lines)
    campaign_numeric = [
        "total_target", "cumulative_target_since_2026_04_05",
        "cumulative_vaccinated_since_2026_04_05", "last_24h_target", "last_24h_vaccinated",
    ]
    require(totals_reconcile(frames["table_002.csv"], campaign_numeric), "measles_division_campaign_totals_reconcile", lines)
    require(totals_reconcile(frames["table_003.csv"], campaign_numeric), "measles_city_campaign_totals_reconcile", lines)
    measles_mapping = mapping[mapping["pipeline_file"].str.contains("086_Measles", regex=False)]
    require(len(measles_mapping) == 3, "three_measles_mapping_decisions", lines)
    require((measles_mapping["mapping_status"] == "excluded").all(), "measles_aggregate_not_fabricated_as_patient_events", lines)
    measles_metadata = json.loads(
        (ROOT / "metadata" / "086_Measles_Update_Till_14_05_26_.json").read_text(encoding="utf-8")
    )
    require(len(measles_metadata["verified_tables"]) == 3, "measles_metadata_links_three_verified_tables", lines)
    require(not measles_metadata["source_to_schema_decision"]["load_eligible"], "measles_metadata_records_exclusion", lines)

    schema = (ROOT / "sql" / "schema.sql").read_text(encoding="utf-8")
    require(len(re.findall(r"^CREATE TABLE", schema, flags=re.MULTILINE)) == 21, "schema_tables_21", lines)
    require(len(re.findall(r"FOREIGN KEY", schema)) == 25, "schema_foreign_keys_25", lines)
    require(len(re.findall(r"^  `.* NOT NULL", schema, flags=re.MULTILINE)) == 89, "schema_mandatory_columns_89", lines)
    require("DEFAULT NULL" not in schema, "schema_nullable_definitions_zero", lines)
    final_validation = (REPORTS / "final_validation.txt").read_text(encoding="utf-8")
    require("68185\t0" in final_validation, "sql_rows_68185_empty_tables_zero", lines)

    pdf = fitz.open(ROOT / "PROJECT_REPORT.pdf")
    require(pdf.page_count == 54, "report_pages_54", lines)
    report_text = "\n".join(page.get_text() for page in pdf)
    for value, name in [
        ("3,022", "report_review_count"), ("773", "report_rejected_count"),
        ("67,690", "report_loaded_source_rows"), ("68,185", "report_final_rows"),
        ("unclassified", "report_unclassified_rule"),
    ]:
        require(value in report_text, name, lines)
    internal_links = sum(1 for page in pdf for link in page.get_links() if link.get("kind") == fitz.LINK_GOTO)
    repository_links = [
        link for page in pdf for link in page.get_links()
        if link.get("kind") == fitz.LINK_URI
        and link.get("uri") == "https://github.com/Ratul-debug/Health_DB_Project"
    ]
    require(internal_links == 98, "report_internal_links_98", lines)
    require(len(repository_links) == 1, "report_clickable_repository_link", lines)
    pdf.close()

    lines.extend([
        "", "quality_status_counts",
        *[f"{key}={value}" for key, value in cleaning["quality_status"].value_counts().to_dict().items()],
        "", "result=ALL_CHECKS_PASS",
    ])
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(OUTPUT.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
