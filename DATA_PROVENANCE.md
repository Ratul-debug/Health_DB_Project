# Data provenance

The project intentionally uses a **mixed-source demonstration dataset**.

## Source-derived or reference-derived values

- Bangladesh administrative division names
- Many health-facility names and facility types
- Many designation/job-title values
- Several laboratory labels
- Cancer-type and vaccine-name reference values

Migration `005_source_backed_row_expansion.sql` adds only rows supported by
`pdfs/027_Health_Bulletin_2023.pdf`: government medical college hospitals from
Table 5.4, district/general hospitals from Table 5.5, IPH laboratories from
Table 4.7.3, and workforce designations from Table 7. Extracted evidence is
retained in `extracted_tables/027_Health_Bulletin_2023/`.

Tables 5.4 and 5.5 also publish sanctioned bed totals. They do not provide the
individual bed type, status, and snapshot date required by the physical
`HospitalBed` entity, so the project does not misrepresent aggregate capacity
as patient-level or bed-level source records.

PDF extraction can capture sentence fragments instead of clean entity names. The final cleanup migration removes obvious fragments from the curated demonstration database while retaining the unmodified raw evidence under `extracted_tables/` and `metadata/`.

## Synthetic demonstration values

- Patient rows, including every `DEMO-NID-*` identifier
- Most disease-event dates, symptoms, temperatures, and test outcomes
- Bed status/type assignments
- Maternal-health, newborn, biopsy, telemedicine, population-group, and malnutrition sample values
- Foreign-key assignments added to demonstrate referential integrity
- Some health-worker names used to complete the demonstration

The synthetic values are suitable for schema demonstration and SQL testing. They are not real clinical observations and must not be used for patient care, epidemiological conclusions, or official statistics.

## Reproducibility rule

`sql/health_db_21_tables_with_data.sql` is the canonical restorable demonstration snapshot. `sql/schema.sql` contains the same 21-table structure without rows. Recreate both dumps after any database migration so their columns and foreign keys stay synchronized.

The ordered migrations are retained under `sql/migrations/`. Migration
`003_final_data_cleanup.sql` curates the demonstration values. Migration
`004_final_semantic_alignment.sql` completes the remaining values, aligns the
documented semantic relationships, and makes every populated column mandatory.
Migration `005_source_backed_row_expansion.sql` increases the canonical
demonstration snapshot from 395 to 495 rows using source-backed reference and
facility data. None of these migrations changes the 21-entity design, its 89
columns, or its 25 foreign keys.
