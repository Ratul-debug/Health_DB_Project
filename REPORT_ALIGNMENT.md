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
and actual canonical rows:

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

## Post-report data expansion

The 54-page `PROJECT_REPORT.pdf` documents the verified 495-row baseline at the
time that version was produced. Migration 006 is a later, Bangladesh-only data
expansion that preserves the same 21 entities, 89 columns, and 25 foreign keys
while increasing the canonical SQL snapshot to 68,185 rows. Before submitting
an updated report, regenerate its row-count tables and validation evidence from
a successful local MySQL restore of the migration-006 snapshot; do not present
the older 495-row validation files as proof of the expanded database.
