# Reports directory guide

This directory contains both current acceptance evidence and historical stage
results. Historical files are retained for auditability; they do not describe a
different current database.

## Current authoritative evidence

| File | Purpose |
|---|---|
| `supervisor_correction_validation.txt` | Master project-wide acceptance result; must end with `result=ALL_CHECKS_PASS` |
| `final_validation.txt` | Validation output from the canonical 68,185-row database |
| `restore_test_validation.txt` | Fresh-restore validation; byte-identical to `final_validation.txt` |
| `relational_export_validation.txt` | Confirms the 21 normalized CSV relations match the SQL dump |
| `normalized_sql_tables_manifest.csv` | Counts and hashes for all 21 normalized SQL CSVs |
| `verified_loaded_extracts_manifest.csv` | Counts and hashes for the four source-derived loaded CSVs |
| `source_column_reconciliation.csv` | Exact source-field to SQL-column rules for 12 loaded target columns |
| `loaded_source_to_sql_lineage.csv` | Source, transformation, target table, and loaded-row lineage |
| `structure_ocr_integrity_audit.csv` | One structure/OCR decision for each of 3,802 raw extracted tables |
| `extraction_page_trace.csv` | Source-document and page-trace decision for every raw table |
| `source_to_schema_mapping.csv` | Explicit load, exclude, reference-only, or quality-block decision |

## Supporting summaries

`cleaning_summary.csv`, `classified_tables.csv`, `table_catalog.csv`,
`best_tables.txt`, `duplicate_tables.csv`, `etl_quality_gate_summary.txt`, and
the two integrity summary text files provide compact views of the detailed
evidence above.

## Historical stage evidence

The files whose names contain `003`, `004`, `005`, or `006` record completed
migration stages. They are retained to show how the database reached its final
state. The authoritative current row count is **68,185**, not an earlier
baseline count. Use `final_validation.txt` for the current database.
