# Data layers and normalization boundary

This file prevents a common interpretation error: the CSVs under
`extracted_tables/` are not the 21 MySQL relations. They are immutable source
evidence captured before relational mapping and may retain merged headers,
aggregate layouts, sparse cells or OCR defects from the source document.

## Four distinct layers

| Layer | Repository location | Meaning | May load directly to MySQL? |
|---|---|---|---|
| Raw extraction archive | `extracted_tables/` | Source-shaped CSV evidence preserved for audit | No |
| Quality-screened output | generated `cleaned_tables/` or `quarantined_tables/` | Cell-standardized extraction candidate plus a quality decision; neither directory is the SQL schema | No |
| Source-verified correction | `verified_tables/` | A table manually checked against its authoritative source | No; it still requires compatible grain and explicit mapping |
| Physical relational database | `sql/schema.sql`, migrations and full dump | The implemented 21-table MySQL target with PK/FK constraints | Yes, through an explicit mapping or migration |

The historical folder name `cleaned_tables/` means that automated cell and
structure checks passed. It does **not** mean “normalized SQL table” or
“approved for loading.” Renaming the archive folders would break committed
provenance paths, so the stable names are retained and their meanings are made
explicit here and in each mapping decision.

## Two different meanings of normalization

1. **Value standardization** removes control characters, standardizes digits,
   whitespace and null tokens, removes empty rows/columns and exact duplicates,
   and screens structure/OCR risk. This occurs in the extraction pipeline.
2. **Relational normalization** organizes target entities, keys and
   relationships to reduce update anomalies. This applies to the physical SQL
   layer, not to source-layout evidence.

Section 3.6 of the report gives a complete 1NF-to-BCNF worked proof for the
implemented `Patient` relation. The complete database is described more
precisely as the **21-table relational target schema**: it preserves the
submitted entity/attribute design and enforces 21 primary keys and 25 foreign
keys. The project does not claim that every raw CSV is normalized or that all
3,802 raw tables belong in the SQL database.

## Exact source-to-SQL population lineage

Only four compatible mappings from the Bangladesh national-scale expansion are
load-eligible. Their field transformations are committed in
`reports/loaded_source_to_sql_lineage.csv` and implemented by
`scripts/08_build_bangladesh_scale_expansion.py` and migration 006.

| Source evidence | Target SQL table | Source rows used | SQL rows inserted |
|---|---|---:|---:|
| DGHS Active Facility Registry | `HealthFacility` | 39,434 | 39,434 |
| DGHS Active Facility Registry, laboratory-type subset | `Laboratory` | 9,694 | 9,694 |
| Bangladesh ICD-11 Condition ValueSet | `Disease` | 18,508 | 18,508 |
| Bangladesh Open Data Doctor Directory, distinct valid posts | `Designation` | 54 | 54 |
| **Total** |  |  | **67,690** |

The final database contains 68,185 rows: the verified 495-row baseline plus
67,690 source-derived rows. The other 17 SQL tables retain their validated
demonstration rows because the archived sources do not provide compatible
record-level values for every mandatory field.

## Why the Measles tables are not loaded

The three corrected Measles tables contain division/city aggregate surveillance
and campaign totals. The SQL `Measles` relation stores patient/event records and
requires a real `PatientID`, `DiseaseID`, symptoms, fever and diagnosis date.
Converting aggregate totals into patient events would fabricate identities and
clinical values. The tables are therefore corrected and preserved in
`verified_tables/`, but explicitly excluded from SQL loading.

For every catalogued pipeline output, consult
`reports/source_to_schema_mapping.csv`. A blank target accompanied by a block,
exclusion or reference-only reason is an intentional non-mapping decision, not
missing work.
