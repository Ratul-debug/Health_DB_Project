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
individual bed type and status required by the physical
`HospitalBed` entity, so the project does not misrepresent aggregate capacity
as patient-level or bed-level source records.

The source catalog is retained in two forms inside `health_data.xlsx`:
`Health` preserves the original grouped presentation, while
`Health_Catalog_Clean` provides 117 machine-readable records with every field
populated. Four catalog URLs returned HTML web pages rather than PDF documents;
their original responses are preserved under `source_pages/` with `.html`
extensions. See `SOURCE_ARCHIVE_STATUS.md`.

PDF extraction can capture sentence fragments instead of clean entity names. The final cleanup migration removes obvious fragments from the curated demonstration database while retaining the unmodified raw evidence under `extracted_tables/` and `metadata/`.

Raw extraction is not claimed to be database-ready. The current cleaner applies
Unicode/control-character repair, Bengali-digit conversion, numeric-separator
normalization, whitespace/null normalization, empty row/column removal and
duplicate removal to values and headers. It then assigns `accepted`,
`review_required`, or `rejected` status. Review/rejected tables are quarantined
and cannot be loaded. The decision for every table is committed in
`reports/cleaning_summary.csv` and `reports/source_to_schema_mapping.csv`.

Structure integrity and OCR risk are not assessed only for the three Measles
examples. `reports/structure_ocr_integrity_audit.csv` records parseability,
header integrity, rectangular shape, blanks, multiline/merged cells, encoding
and OCR-risk indicators, SHA-256, provenance status and load safety for all
3,802 raw tables. `reports/extraction_page_trace.csv` reconciles each raw table
with existing page metadata or a conservative recovered trace. Any unresolved
page, unavailable source, structural concern or OCR concern remains review
blocked and cannot become SQL-load eligible by classification alone.

The three extracted tables from the DGHS Measles update dated 14 May 2026 were
manually checked against the official three-page bulletin. Corrected copies are
in `verified_tables/086_Measles_Update_Till_14_05_26_/`. They report aggregated
division/city surveillance and vaccination-campaign totals, whereas the fixed
SQL `Measles` entity is patient/event-grain and requires `PatientID`. Therefore
the source tables are retained as verified evidence but deliberately not loaded;
no patient identifier or event row is fabricated.

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
facility data.

Migration `006_bangladesh_national_scale_expansion.sql` then adds 67,690 rows
from official Bangladesh sources: 39,434 DGHS active facilities, 9,694
laboratory/diagnostic facilities linked to them, 18,508 Bangladesh ICD-11
Condition concepts, and 54 designation values. The final snapshot contains
68,185 rows. The source-to-table rules are deterministic and are implemented by
`scripts/08_build_bangladesh_scale_expansion.py`; full metadata and hashes are
in `source_datasets/README.md`.

For catalog rows 114-118, raw downloads are preserved under
`source_datasets/`, extracted CSV tables under matching numbered folders in
`extracted_tables/`, and per-source lineage records under `metadata/`. The
script writes normalized physical-table mappings to the generated
`cleaned_tables/` layer and reads those cleaned files back before producing
migration 006. `reports/bangladesh_scale_pipeline_manifest.csv` reconciles each
source's extracted rows, mapped table, inserted rows, and explicit exclusions.
The four compatible physical mappings are also present in the archive-wide
`reports/source_to_schema_mapping.csv`; their loaded-row total is 67,690.

Their clean transformed outputs are committed under
`verified_tables/migration_006_loaded/`. Each file uses the exact target schema
columns and matches the source-derived portion of the canonical SQL rows.
`reports/source_column_reconciliation.csv` records all 12 source/generated-key
to target-column rules. After the full dump is built,
`scripts/12_export_verified_relational_tables.py` also creates the complete 21
schema-exact CSV relations under `normalized_sql_tables/`. These are derived
views of the same 68,185-row database, not additional source data.

Here `cleaned_tables/` is a historical path name for quality-passed extraction
candidates, not for the normalized database relations. The source-shaped raw,
screened/verified candidate, explicit mapping and physical SQL layers are
defined in `DATA_LAYER_AND_NORMALIZATION_GUIDE.md`. Exact field transformations
for all four load-eligible migration-006 mappings are recorded in
`reports/loaded_source_to_sql_lineage.csv`.

The source Doctor Directory contains 199 provider names, but it has no Gender
field. Because `HealthWorker.Gender` is mandatory, those names are not imported
as workers. Likewise, the 10-code Bangladesh Vaccine ValueSet is terminology,
not patient vaccination events, so it is not converted into `Vaccination` rows.
This boundary prevents missing values from being invented. None of the ordered
migrations changes the 21-entity design, its 89 columns, or its 25 foreign keys.

## Row-count reconciliation

An earlier working estimate of 124,334 rows included 74,721 Disease reference
rows from a US CDC terminology source. That scenario was not accepted as the
canonical expansion because the project requirement was subsequently narrowed
to Bangladesh-only sources. It was replaced rather than combined with the
official Bangladesh OCL Condition expansion.

| Group | Earlier draft | Bangladesh-only canonical | Change |
|---|---:|---:|---:|
| `Disease` | 74,721 | 18,517 | -56,204 |
| `HealthFacility` | 39,613 | 39,614 | +1 |
| `Laboratory` | 9,709 | 9,709 | 0 |
| Other 18 tables | 291 | 345 | +54 |
| **Total** | **124,334** | **68,185** | **-56,149** |

The valid comparison is therefore the verified 495-row baseline versus the
68,185-row Bangladesh-only snapshot: migration 006 adds 67,690 defensible SQL
rows. The discarded 124,334-row draft must not be cited as a previously
validated Bangladesh database.
