#!/usr/bin/env python3

"""Validate the archive-wide ETL controls introduced after supervisor review."""

from __future__ import annotations

import csv
import json
import hashlib
import re
import runpy
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
    structure_ocr = pd.read_csv(
        REPORTS / "structure_ocr_integrity_audit.csv", keep_default_na=False
    )
    page_trace = pd.read_csv(REPORTS / "extraction_page_trace.csv", keep_default_na=False)
    loaded_lineage = pd.read_csv(
        REPORTS / "loaded_source_to_sql_lineage.csv", keep_default_na=False
    )

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

    require(len(structure_ocr) == 3802, "all_3802_tables_structure_ocr_audited", lines)
    require(structure_ocr["raw_file"].is_unique, "one_integrity_audit_per_raw_table", lines)
    require(
        not structure_ocr[["structure_status", "ocr_status", "overall_status"]]
        .eq("")
        .any()
        .any(),
        "no_missing_structure_or_ocr_decision",
        lines,
    )
    require(
        (structure_ocr["raw_retention_policy"] == "retain_immutable_evidence").all(),
        "all_raw_tables_retained_as_evidence",
        lines,
    )
    require(
        (structure_ocr["sql_load_eligible"] != "yes").all(),
        "no_raw_extraction_directly_sql_loadable",
        lines,
    )
    require(
        (structure_ocr["mapping_status"] != "missing_mapping_decision").all(),
        "all_integrity_audits_have_mapping_decisions",
        lines,
    )
    require(
        all(
            (ROOT / row.raw_file).is_file()
            and hashlib.sha256((ROOT / row.raw_file).read_bytes()).hexdigest() == row.raw_sha256
            for row in structure_ocr.itertuples(index=False)
        ),
        "all_raw_sha256_values_reconcile",
        lines,
    )
    require(
        len(
            structure_ocr[
                structure_ocr["overall_status"] == "pass_source_verified_curated_output"
            ]
        )
        == 3,
        "three_source_verified_curated_integrity_outputs",
        lines,
    )
    require(len(page_trace) == 3802, "all_3802_raw_tables_page_trace_assessed", lines)
    require(page_trace["raw_file"].is_unique, "one_page_trace_per_raw_table", lines)
    require(
        all(
            (ROOT / row.raw_file).is_file()
            and hashlib.sha256((ROOT / row.raw_file).read_bytes()).hexdigest() == row.raw_sha256
            for row in page_trace.itertuples(index=False)
        ),
        "all_page_trace_hashes_reconcile",
        lines,
    )
    require(
        (page_trace["source_document"] != "").all(),
        "all_raw_tables_have_source_document_identity",
        lines,
    )
    require(
        (
            page_trace["sql_load_policy"]
            == "blocked_unless_separately_verified_and_explicitly_mapped"
        ).all(),
        "unresolved_page_trace_never_load_eligible",
        lines,
    )

    require(len(loaded_lineage) == 4, "four_explicit_loaded_field_mappings", lines)
    require(
        set(loaded_lineage["target_sql_table"])
        == {"HealthFacility", "Laboratory", "Disease", "Designation"},
        "loaded_field_mapping_targets_exact",
        lines,
    )
    require(
        int(loaded_lineage["loaded_rows"].sum()) == 67690,
        "loaded_field_mapping_rows_67690",
        lines,
    )
    require(
        not loaded_lineage[["source_fields", "selection_or_transformation", "target_columns"]]
        .eq("")
        .any()
        .any(),
        "all_loaded_mappings_have_field_rules",
        lines,
    )
    mapping_counts = {
        row.target_sql_table: int(row.loaded_rows)
        for row in mapping[mapping["load_eligible"] == "yes"].itertuples(index=False)
    }
    lineage_counts = {
        row.target_sql_table: int(row.loaded_rows)
        for row in loaded_lineage.itertuples(index=False)
    }
    require(
        mapping_counts == lineage_counts,
        "loaded_lineage_matches_archive_mapping_decisions",
        lines,
    )
    require(
        (ROOT / "DATA_LAYER_AND_NORMALIZATION_GUIDE.md").is_file()
        and (ROOT / "extracted_tables" / "00_READ_ME_FIRST_RAW_NOT_SQL.md").is_file(),
        "raw_sql_layer_boundary_documented",
        lines,
    )

    relational_export = runpy.run_path(
        str(ROOT / "scripts" / "12_export_verified_relational_tables.py"),
        run_name="verified_relational_export_module",
    )
    schema_columns = relational_export["read_schema"]()
    canonical_rows = relational_export["read_dump_rows"](schema=schema_columns)
    source_006 = relational_export["SOURCE_006"]
    normalized_dir = ROOT / "normalized_sql_tables"
    verified_dir = ROOT / "verified_tables" / "migration_006_loaded"

    column_reconciliation = pd.read_csv(
        REPORTS / "source_column_reconciliation.csv", keep_default_na=False
    )
    require(len(column_reconciliation) == 12, "twelve_target_columns_reconciled", lines)
    require(
        not column_reconciliation.duplicated(["target_sql_table", "target_column"]).any(),
        "one_rule_per_loaded_target_column",
        lines,
    )
    require(
        all(
            set(group["target_column"]) == set(schema_columns[table])
            for table, group in column_reconciliation.groupby("target_sql_table")
        ),
        "all_loaded_target_columns_match_schema",
        lines,
    )
    raw_headers: dict[int, set[str]] = {}
    for _, (source_record, _, source_path) in source_006.items():
        if source_record in raw_headers:
            continue
        with (ROOT / source_path).open(encoding="utf-8-sig", newline="") as handle:
            raw_headers[source_record] = set(next(csv.reader(handle)))
    require(
        all(
            row.source_header_check == "not_applicable_generated_key"
            or (
                row.source_header_check == "yes"
                and all(
                    field.strip() in raw_headers[int(row.source_record)]
                    for field in row.source_field.split(";")
                )
            )
            for row in column_reconciliation.itertuples(index=False)
        ),
        "source_fields_exist_or_generated_key_declared",
        lines,
    )
    require(
        (column_reconciliation["target_schema_check"] == "yes").all()
        and (column_reconciliation["verification_status"] == "verified").all(),
        "source_to_target_column_checks_verified",
        lines,
    )

    verified_files = sorted(verified_dir.glob("*.csv"))
    require(len(verified_files) == 4, "four_tracked_verified_loaded_csvs", lines)
    verified_manifest = pd.read_csv(
        REPORTS / "verified_loaded_extracts_manifest.csv", keep_default_na=False
    )
    require(
        len(verified_manifest) == 4
        and int(verified_manifest["loaded_rows"].sum()) == 67690,
        "verified_loaded_manifest_rows_67690",
        lines,
    )
    for table, (_, source_count, _) in source_006.items():
        with (verified_dir / f"{table}.csv").open(
            encoding="utf-8-sig", newline=""
        ) as handle:
            reader = csv.reader(handle)
            header = next(reader)
            rows = list(reader)
        require(header == schema_columns[table], f"verified_{table}_columns_match_schema", lines)
        require(
            rows
            == [
                ["" if value is None else value for value in row]
                for row in canonical_rows[table][-source_count:]
            ],
            f"verified_{table}_rows_match_loaded_sql",
            lines,
        )
        require(
            not any(value == "" for row in rows for value in row),
            f"verified_{table}_blank_cells_zero",
            lines,
        )
    require(
        all(
            hashlib.sha256((ROOT / row.verified_csv).read_bytes()).hexdigest() == row.sha256
            for row in verified_manifest.itertuples(index=False)
        ),
        "verified_loaded_manifest_hashes_reconcile",
        lines,
    )

    normalized_files = sorted(normalized_dir.glob("*.csv"))
    require(len(normalized_files) == 21, "normalized_sql_csv_tables_21", lines)
    require(
        {path.stem for path in normalized_files} == set(schema_columns),
        "normalized_sql_table_names_exact",
        lines,
    )
    normalized_total = 0
    for table, columns in schema_columns.items():
        with (normalized_dir / f"{table}.csv").open(
            encoding="utf-8-sig", newline=""
        ) as handle:
            reader = csv.reader(handle)
            header = next(reader)
            rows = list(reader)
        require(header == columns, f"normalized_{table}_columns_match_schema", lines)
        require(
            rows
            == [
                ["" if value is None else value for value in row]
                for row in canonical_rows[table]
            ],
            f"normalized_{table}_values_match_dump",
            lines,
        )
        require(
            not any(value == "" for row in rows for value in row),
            f"normalized_{table}_blank_cells_zero",
            lines,
        )
        normalized_total += len(rows)
    require(normalized_total == 68185, "normalized_sql_rows_68185", lines)
    normalized_manifest = pd.read_csv(
        REPORTS / "normalized_sql_tables_manifest.csv", keep_default_na=False
    )
    require(
        len(normalized_manifest) == 21
        and int(normalized_manifest["row_count"].sum()) == 68185
        and int(normalized_manifest["migration_006_source_rows"].sum()) == 67690
        and int(normalized_manifest["pre_migration_006_rows"].sum()) == 495,
        "normalized_sql_manifest_counts_reconcile",
        lines,
    )
    require(
        all(
            hashlib.sha256((ROOT / row.csv_file).read_bytes()).hexdigest() == row.sha256
            for row in normalized_manifest.itertuples(index=False)
        ),
        "normalized_sql_manifest_hashes_reconcile",
        lines,
    )
    relational_validation = (
        REPORTS / "relational_export_validation.txt"
    ).read_text(encoding="utf-8")
    require(
        "result=ALL_CHECKS_PASS" in relational_validation,
        "relational_export_validation_pass",
        lines,
    )

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
        ("Archive-wide Structure and OCR Integrity Control", "report_archive_wide_structure_ocr_control"),
        ("structure_ocr_integrity_audit.csv", "report_structure_ocr_evidence_link"),
        ("extraction_page_trace.csv", "report_page_trace_evidence_link"),
        ("IMPORTANT LAYER BOUNDARY", "report_raw_archive_not_sql_warning"),
        ("Loaded source-to-SQL lineage", "report_loaded_source_lineage_table"),
        ("loaded_source_to_sql_lineage.csv", "report_field_lineage_evidence_link"),
        ("Normalization scope and data-layer terminology", "report_normalization_scope"),
        ("Verified loaded extraction", "report_verified_loaded_extraction"),
        ("source_column_reconciliation.csv", "report_column_reconciliation_evidence"),
        ("normalized_sql_tables/", "report_normalized_sql_csv_layer"),
        ("21 schema-exact CSV relations", "report_normalized_sql_csv_count"),
    ]:
        require(value in report_text, name, lines)
    require(
        "Loaded into existing normalized" not in report_text,
        "report_avoids_ambiguous_mapping_wording",
        lines,
    )
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
