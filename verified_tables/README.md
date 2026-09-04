# Source-verified tables

This directory contains small, manually source-checked corrections for raw
extractions that automatic cleaning cannot safely repair. Each subdirectory
retains the source number and includes its own provenance note.

Verified does not automatically mean SQL-loadable. A table must also match the
grain and mandatory attributes of one of the fixed 21 physical tables. The
final eligibility decision is recorded in
`reports/source_to_schema_mapping.csv`.
