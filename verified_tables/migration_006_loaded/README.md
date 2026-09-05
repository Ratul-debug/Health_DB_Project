# Source-verified outputs loaded by migration 006

These four CSV files are the clean, source-to-schema transformed outputs that
populate migration 006. Unlike `extracted_tables/`, they use exact target SQL
columns and have passed source-field, row-count, blank-cell and canonical SQL
reconciliation.

| Output | Source-derived rows |
|---|---:|
| `HealthFacility.csv` | 39,434 |
| `Laboratory.csv` | 9,694 |
| `Disease.csv` | 18,508 |
| `Designation.csv` | 54 |
| **Total** | **67,690** |

The original source-shaped evidence remains under numbered
`extracted_tables/` folders. Exact source fields, target columns and
transformation rules are listed in
`reports/source_column_reconciliation.csv`. File hashes and counts are listed
in `reports/verified_loaded_extracts_manifest.csv`.
