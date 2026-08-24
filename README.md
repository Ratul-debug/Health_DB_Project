# Health Data Integration Model

A Bangladesh healthcare data engineering and MySQL project created by the **NULL TERMINATORS** group. The repository inventories source reports, downloads PDFs, extracts and cleans tables, and provides a normalized 21-table demonstration database.

## Current implementation

- 21 MySQL tables matching the submitted entity list
- 21 primary keys and 25 implemented foreign-key constraints
- All 89 table columns populated in the canonical snapshot and enforced as `NOT NULL`
- 495 populated demonstration rows after the source-backed expansion
- 112 source records inventoried in `health_data.xlsx`; 61 valid PDFs retained
- 68 extraction/metadata source folders and 3,797 extracted CSV tables retained for traceability
- Mixed-source demonstration data: source-derived rows where usable, synthetic rows where the extracted tables were insufficient

Synthetic patient and clinical records are clearly demo data and must not be presented as real patient observations. See `DATA_PROVENANCE.md`.

## Repository structure

```text
Health_DB_Project/
├── extracted_tables/          Raw CSV tables extracted from PDFs
├── metadata/                  Per-document extraction metadata
├── pdfs/                      Downloaded source reports
├── reports/                   Catalog, classification, and cleaning summaries
├── scripts/                   Download, extraction, cleaning, and catalog scripts
├── sql/
│   ├── migrations/            Historical one-time database migrations
│   ├── validation/            Integrity and demonstration queries
│   ├── schema.sql             Canonical 21-table schema (no data)
│   └── health_db_21_tables_with_data.sql
├── ER_DIAGRAM.png             21-entity ERD image
├── Health_ER_Diagram_.pdf     Submitted 21-entity ERD
├── health_data.xlsx           Original source catalog
└── requirements.txt
```

## Python setup

```bash
python3 -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

## Run the PDF pipeline

Run commands from the repository root:

```bash
python scripts/downloader.py
python scripts/extractor.py
python scripts/cleaner.py
python scripts/04_find_duplicates.py
python scripts/05_build_catalog.py
python scripts/06_classify_tables.py
python scripts/07_find_best_tables.py
```

The cleaner preserves `extracted_tables/` as raw evidence and writes normalized copies to `cleaned_tables/`.

## Restore MySQL

Choose one option, not both.

Schema only:

```bash
mysql -u healthuser -p < sql/schema.sql
```

Schema plus demonstration data:

```bash
mysql -u healthuser -p < sql/health_db_21_tables_with_data.sql
```

Validate the restored database:

```bash
mysql -u healthuser -p < sql/validation/validation_queries.sql
```

The validation report checks table/PK/FK counts, non-empty tables, every
foreign-key relationship, all-column NULL/blank values, and the documented
semantic rules. Every reported `issue_count` is expected to be `0`.

Migration `005_source_backed_row_expansion.sql` adds 100 high-confidence rows
without changing the ERD or schema: 80 facilities, 8 IPH laboratories, and 12
workforce designations. The facility rows come from Tables 5.4 and 5.5 of
`pdfs/027_Health_Bulletin_2023.pdf`; the laboratories come from Table 4.7.3,
and the designations come from Table 7. Existing facility aliases are
normalized and duplicate insertion is prevented on repeated execution.

The same source reports sanctioned bed totals, but not one complete row per
physical bed with the required `BedType`, `Status`, and `SnapshotDate` fields.
Those aggregate totals are therefore not expanded into synthetic `HospitalBed`
rows.

No database password is stored in this repository.

## ERD note

The submitted diagram shows the 21 entities and their conceptual relationships. The MySQL implementation enforces those relationships with 25 foreign-key constraints, including implementation columns used for patient, disease-subtype, laboratory, bed, vaccination, malnutrition, and designation links.

## Report alignment note

The normalized rows shown in Tables 3.14-3.18 of the submitted report are illustrative examples that use business-style identifiers such as `FAC001` and `BED-101`. The final physical MySQL implementation uses integer surrogate primary keys while preserving the same 21 entities and relationships. `DiseaseID` is the physical primary key for `Disease`; `ICDCode` remains a domain attribute. A health worker's region is obtained through `HealthWorker -> HealthFacility -> AdministrativeRegion`, avoiding a duplicated `RegionID` in `HealthWorker`.

## GitHub

Repository: https://github.com/Ratul-debug/Health_DB_Project
