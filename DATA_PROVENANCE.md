# Data provenance

The project intentionally uses a **mixed-source demonstration dataset**.

## Source-derived or reference-derived values

- Bangladesh administrative division names
- Many health-facility names and facility types
- Many designation/job-title values
- Several laboratory labels
- Cancer-type and vaccine-name reference values

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

The ordered migrations are retained under `sql/migrations/`. Migration `003_final_data_cleanup.sql` changes demonstration values only; it does not alter the 21-table schema or its 25 foreign keys.
