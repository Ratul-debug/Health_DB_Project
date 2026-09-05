# Source-verified tables

This directory contains small, manually source-checked corrections for raw
extractions that automatic cleaning cannot safely repair. Each subdirectory
retains the source number and includes its own provenance note.

It also contains `migration_006_loaded/`, the four deterministic, clean
source-to-schema outputs that contributed 67,690 rows to the canonical SQL
snapshot. Those files are checked against source headers, transformation rules,
target columns and the loaded SQL values.

Verified does not automatically mean SQL-loadable. A table must also match the
grain and mandatory attributes of one of the fixed 21 physical tables. The
final eligibility decision is recorded in
`reports/source_to_schema_mapping.csv`.
