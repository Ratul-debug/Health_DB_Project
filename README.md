# Health Data Integration Model

A Bangladesh healthcare data engineering and MySQL project created by the **NULL TERMINATORS** group. The repository inventories source reports, downloads PDFs, extracts and cleans tables, and provides a normalized 21-table demonstration database.

## Current implementation

- 21 MySQL tables matching the submitted entity list
- 21 primary keys and 25 implemented foreign-key constraints
- All 89 table columns populated in the canonical snapshot and enforced as `NOT NULL`
- 68,185 populated rows after the Bangladesh-only national-scale expansion
- 117 source records inventoried in `health_data.xlsx`; 61 valid PDFs, 4
  HTML source pages, and 5 additional official Bangladesh dataset/catalog
  entries retained with their real file types
- 73 extraction/metadata source folders and 3,802 raw extracted CSV tables
  retained for traceability; every table has a structure/OCR audit, SHA-256
  fingerprint, cleaning decision and mapping decision, while only accepted,
  explicitly mapped outputs can reach SQL
- Mixed-source demonstration data: source-derived rows where usable, synthetic rows where the extracted tables were insufficient

Synthetic patient and clinical records are clearly demo data and must not be presented as real patient observations. See `DATA_PROVENANCE.md`.

## Repository structure

```text
Health_DB_Project/
├── extracted_tables/          Raw CSV tables extracted from PDFs/datasets
├── cleaned_tables/            Generated normalized/mapping-ready CSVs (ignored)
├── quarantined_tables/        Generated tables blocked by quality gates (ignored)
├── verified_tables/           Tracked source-checked corrections for OCR edge cases
├── metadata/                  Per-source extraction and mapping metadata
├── pdfs/                      Downloaded source reports
├── source_pages/              Downloaded sources that are HTML pages
├── source_datasets/           Official Bangladesh XLSX/XLS/JSON/ZIP datasets
├── reports/                   Catalog, classification, and cleaning summaries
├── scripts/                   Download, extraction, cleaning, and catalog scripts
├── sql/
│   ├── migrations/            Historical one-time database migrations
│   ├── validation/            Integrity and demonstration queries
│   ├── schema.sql             Canonical 21-table schema (no data)
│   └── health_db_21_tables_with_data.sql
├── ER_DIAGRAM.png             21-entity ERD image
├── Health_ER_Diagram_.pdf     Submitted 21-entity ERD
├── PROJECT_REPORT.pdf         Submitted project report
├── REPORT_ALIGNMENT.md        Report-to-database alignment addendum
├── SUPERVISOR_CORRECTIONS.md  Review findings and project-wide fixes
├── SOURCE_ARCHIVE_STATUS.md   Source-file type and archive status
├── health_data.xlsx           Original and clean source-catalog sheets
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
python scripts/11_recover_extraction_page_trace.py --recover-pages
python scripts/10_audit_all_extracted_tables.py
python scripts/09_validate_supervisor_corrections.py
```

The cleaner preserves `extracted_tables/` as raw evidence, normalizes values as
well as headers, and writes accepted tables to `cleaned_tables/`. Tables with
placeholder headers, excessive internal blanks, suspicious encoding, unsafe
width, or unusable structure go to `quarantined_tables/` with a reason in
`reports/cleaning_summary.csv`. No quarantined table is eligible for SQL load.

`reports/structure_ocr_integrity_audit.csv` contains one structure-integrity,
OCR-risk, provenance and load-safety decision for every one of the 3,802 raw
tables. `reports/extraction_page_trace.csv` retains original page metadata,
recovers legacy page links conservatively where possible, and explicitly marks
unresolved or unavailable source pages instead of guessing them.

The three OCR-damaged tables from the 14 May 2026 DGHS Measles bulletin are
source-checked in `verified_tables/086_Measles_Update_Till_14_05_26_/`. Their
headers, area names and digits are corrected, but the aggregate division/city
rows are not forced into the patient/event-grain `Measles` SQL table.

## Run the Bangladesh dataset pipeline

The five additional catalog entries follow the same auditable sequence as the
earlier sources:

```text
health_data.xlsx catalog
  -> source_datasets raw download
  -> extracted_tables CSV
  -> cleaned_tables physical mapping
  -> migration 006 SQL
  -> canonical full dump
  -> validation reports
```

Run all deterministic stages from the repository root:

```bash
python scripts/08_download_bangladesh_scale_sources.py
python scripts/08_build_bangladesh_scale_expansion.py
python scripts/cleaner.py
python scripts/04_find_duplicates.py
python scripts/05_build_catalog.py
python scripts/06_classify_tables.py
python scripts/07_find_best_tables.py
python scripts/11_recover_extraction_page_trace.py --recover-pages
python scripts/10_audit_all_extracted_tables.py
python scripts/09_validate_supervisor_corrections.py
```

The downloader preserves five catalog entries as six validated raw files. The
builder then recreates five extracted tables, five mapping/reference outputs,
five metadata records, `reports/bangladesh_scale_pipeline_manifest.csv`, the
migration SQL, full data dump, schema AUTO_INCREMENT metadata, and the static
validation report. It then reads the cleaned physical mappings—not the raw
files directly—to generate the SQL rows.
The remaining commands refresh the archive-wide cleaning, quality, duplicate,
catalog, classification, and best-table reports. Classification now requires
at least two independent keyword matches with no top-score tie; otherwise the
table remains `unclassified`. `reports/source_to_schema_mapping.csv` records an
explicit load, exclusion, quality block, or reference-only reason for every
pipeline output. This prevents forced categories and dirty imports.

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
physical bed with the required `BedType` and `Status` fields.
Those aggregate totals are therefore not expanded into synthetic `HospitalBed`
rows.

Migration `006_bangladesh_national_scale_expansion.sql` adds 67,690
Bangladesh-only source rows without adding or changing an entity, column, or
foreign key:

- 39,434 active facilities from the DGHS Facility Registry
- 9,694 laboratory/diagnostic facilities linked to those facility rows
- 18,508 Bangladesh ICD-11 Condition concepts (Diagnosis and Finding)
- 54 workforce designation values from the Bangladesh Open Data Doctor Directory

The resulting canonical snapshot has 68,185 rows in the same 21 tables. Run
`python scripts/08_build_bangladesh_scale_expansion.py` to regenerate the SQL
deterministically from the archived source extracts. Source URLs, dates,
mapping rules, exclusions, and SHA-256 hashes are documented in
`source_datasets/README.md`.

The Doctor Directory's 199 provider rows are not inserted as `HealthWorker`
records because its published fields do not include the mandatory `Gender`
attribute. The Bangladesh Vaccine ValueSet is retained as reference evidence,
but its 10 codes are not converted into patient vaccination events because the
source does not publish a `PatientID`. These exclusions prevent fabricated
values.

No database password is stored in this repository.

## ERD note

The submitted diagram shows the 21 entities and their conceptual relationships. The MySQL implementation enforces those relationships with 25 foreign-key constraints, including implementation columns used for patient, disease-subtype, laboratory, bed, vaccination, malnutrition, and designation links. For an exact conceptual-to-physical mapping, see `REPORT_ALIGNMENT.md`; `sql/schema.sql` is authoritative for the implemented database.

## Report alignment note

Section 3.6 of `PROJECT_REPORT.pdf` verifies the implemented `Patient` table
through BCNF using its exact six physical columns and actual populated rows.
Tables 3.14-3.18 use the physical integer identifiers, exact column names, and
actual database values for `HealthFacility`, `HospitalBed`, `Designation`,
`Disease`, and `HealthWorker`. `DiseaseID` is the primary key for `Disease`,
while `ICDCode` is a mandatory domain attribute. A health worker's region is
derived through `HealthWorker -> HealthFacility -> AdministrativeRegion`, so
`RegionID` is not duplicated in `HealthWorker`. See `REPORT_ALIGNMENT.md` for
the complete report-to-schema mapping.

## GitHub

Repository: https://github.com/Ratul-debug/Health_DB_Project
