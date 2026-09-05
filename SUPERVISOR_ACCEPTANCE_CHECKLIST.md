# Supervisor acceptance evidence

This checklist makes the project evidence directly reviewable without treating
the immutable raw extraction archive as the relational database.

Recommended review order: final report and ERD -> `normalized_sql_tables/` ->
`verified_tables/migration_006_loaded/` -> canonical SQL dump -> current
validation reports. The raw `extracted_tables/` archive should be inspected only
as provenance evidence, together with its quality and mapping decisions.

| Acceptance item | Project evidence | Result |
|---|---|---|
| Contains data sources | `health_data.xlsx`, `pdfs/`, `source_pages/`, `source_datasets/` | Present |
| Source identity is readable | Catalog, archive paths, metadata, and audit references | No `nan` or punctuation-only source names |
| Contains extracted data | 3,802 source-shaped CSVs under `extracted_tables/` | Present |
| Sources verified | URLs/dates/hashes plus 3,802 provenance decisions | Verified or explicitly review-blocked |
| Clean loaded extraction | Four tracked CSVs under `verified_tables/migration_006_loaded/` | 67,690 rows; blank/NULL 0 |
| Source/target columns reconcile | `reports/source_column_reconciliation.csv` | All 12 target columns explained |
| Unsafe extraction cannot load | quality, structure/OCR and mapping gates | Enforced |
| Normalized database relations visible | `normalized_sql_tables/` | 21 exact CSV relations; 68,185 rows |
| Schema/data integrity | final and restore validation reports | 21 tables, 25 FK, 89 mandatory columns, zero issues |
| Public GitHub repository | https://github.com/Ratul-debug/Health_DB_Project | Direct link |

The raw archive is deliberately retained for provenance; a raw file may still
show source layout or OCR defects. Review the tracked verified-loaded outputs
for accepted extraction quality and `normalized_sql_tables/` for the final
relational state.
