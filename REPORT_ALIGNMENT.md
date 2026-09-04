# Report and ERD alignment

## Authoritative implementation

The final physical database is defined by `sql/schema.sql` and the canonical
restorable snapshot `sql/health_db_21_tables_with_data.sql`. It contains:

- 21 entities/tables
- 89 mandatory (`NOT NULL`) columns
- 21 primary keys
- 25 foreign-key constraints
- 68,185 populated rows after migration 006

`sql/validation/validation_queries.sql` verifies these counts, every foreign-key
relationship, empty tables, NULL/blank values, duplicate business keys, and the
documented semantic rules. Every reported issue count is expected to be zero.

## Report sample alignment

`PROJECT_REPORT.pdf` records the development, normalization, and final physical
implementation. Section 3.6 uses only the implemented `Patient` relation with
its exact columns: `PatientID`, `FullName`, `DateOfBirth`, `Gender`,
`NationalID`, and `BedID`. The displayed Patient rows are copied from the
canonical SQL snapshot.

Tables 3.14-3.18 use physical integer identifiers, exact implemented columns,
their physical SQL column order, and actual canonical rows. In particular,
Table 3.14 follows `HealthFacility(FacilityID, FacilityType, FacilityName,
RegionID)` and Table 3.15 follows
`HospitalBed(BedID, FacilityID, BedType, Status)`:

| Report table | Physical implementation |
|---|---|
| Patient normalization | `Patient(PatientID, FullName, DateOfBirth, Gender, NationalID, BedID)` |
| Table 3.14 | `HealthFacility` rows 6, 7, 8, 10, and 11 |
| Table 3.15 | `HospitalBed` rows 6, 7, 8, 10, and 11 |
| Table 3.16 | `Designation` IDs 7, 14, 15, 17, and 19 |
| Table 3.17 | `Disease` IDs 14, 15, 16, 19, and 20 |
| Table 3.18 | `HealthWorker` rows 6, 7, 8, 10, and 11 |

## ERD interpretation

`Health_ER_Diagram_.pdf` and `ER_DIAGRAM.png` preserve the submitted conceptual
ERD and its 21-entity set. The relationship lines express the conceptual model;
they are not a literal rendering of every implementation column. The physical
schema adds the foreign-key columns needed to enforce patient, disease-subtype,
laboratory, bed, vaccination, malnutrition, cancer, biopsy, designation, and
facility relationships without adding or removing an entity.

For demonstrations and SQL queries, use the physical names and relationships in
`sql/schema.sql`. The conceptual ERD remains the presentation artifact, while
the schema and validation report are the executable proof of implementation.

## Migration 006 alignment

The 54-page `PROJECT_REPORT.pdf` is synchronized with the Bangladesh-only
migration-006 snapshot. Its discovery inventory, ETL stages, normalization
sample summaries, validation matrix, provenance table, and final maintenance
summary all report the canonical 68,185-row state. The seven-step ETL flow
separates discovery, acquisition, extraction, value cleaning plus quality
screening, explicit source-to-schema mapping, MySQL loading, and live/restore
validation. It distinguishes the 3,802 raw extracted CSV tables from the 3,807
catalogued pipeline outputs and no longer calls every output clean. The report
records accepted, curated, review-required and rejected counts, and identifies
the three source-verified Measles corrections as aggregate reference tables
excluded from patient/event loading. Sections 3.2.1-3.2.8 now appear before Section 3.3, and
the affected Contents entries point to their corrected printed pages. The
Contents and List of Tables entries remain internal PDF links. The displayed sample rows
remain present after the expansion; their final table totals are
`HealthFacility = 39,614`, `Designation = 85`, `Disease = 18,517`,
`Laboratory = 9,709`, and `HealthWorker = 12`.

The final ETL evidence also includes an archive-wide structure/OCR integrity
audit: every one of the 3,802 immutable raw CSVs has a SHA-256 fingerprint,
structural and OCR-risk decision, provenance status and SQL-load-safety result.
The report states that unsafe raw outputs remain blocked rather than deleted or
presented as clean.

## Data-layer and normalization interpretation

`extracted_tables/` is the immutable raw extraction archive, not a second copy
of the 21-table schema. Its tables retain source document grain and may therefore
be wide, aggregate or structurally irregular. Generated `cleaned_tables/`
outputs are only quality-passed extraction candidates; they still cannot load
without an explicit compatible-grain mapping. `verified_tables/` contains
source-checked corrections, while `sql/schema.sql` alone defines the physical
relational database.

The report's detailed 1NF-to-BCNF proof is explicitly scoped to `Patient`. It
does not assert that all 3,802 raw CSVs are normalized relations. Exact field
lineage for the four migration-006 mappings is committed in
`reports/loaded_source_to_sql_lineage.csv`; this demonstrates why the source
data and the target schema differ in shape while still being traceably related.

`reports/final_validation.txt` and
`reports/restore_test_validation.txt` are the identical 207-line live and
clean-restore evidence for this state. The historical 495-row count is retained
only in `DATA_PROVENANCE.md` and the static expansion report as the explicitly
labelled pre-migration baseline, not as the final database size.
