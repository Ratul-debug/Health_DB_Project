# Report and ERD alignment

## Authoritative implementation

The final physical database is defined by `sql/schema.sql` and the canonical
restorable snapshot `sql/health_db_21_tables_with_data.sql`. It contains:

- 21 entities/tables
- 89 mandatory (`NOT NULL`) columns
- 21 primary keys
- 25 foreign-key constraints
- 495 populated demonstration rows

`sql/validation/validation_queries.sql` verifies these counts, every foreign-key
relationship, empty tables, NULL/blank values, duplicate business keys, and the
documented semantic rules. Every reported issue count is expected to be zero.

## Why some report examples look different

`PROJECT_REPORT.pdf` records the development and normalization process. Its
early planning text refers to approximately 40 candidate entities, while the
submitted ERD and final normalized implementation contain the selected 21
entities. The report's sample rows use illustrative business-style identifiers
such as `FAC001`, `BED-101`, and `DES001`; these are examples, not the physical
MySQL key types.

The implemented schema uses integer surrogate keys consistently. In particular:

| Conceptual/report notation | Physical MySQL implementation |
|---|---|
| `WorkerID` | `HealthWorker.WorkID` |
| `ICDCode` as a disease identifier | `Disease.DiseaseID` is the PK; `ICDCode` is a mandatory domain attribute |
| Direct worker-to-region value | `HealthWorker -> HealthFacility -> AdministrativeRegion` |
| Business-style string IDs | Integer primary and foreign keys |

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
