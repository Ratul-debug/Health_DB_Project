# Health Data Integration Model

A Bangladesh healthcare data engineering and MySQL project created by the **NULL TERMINATORS** group. The repository inventories source reports, downloads PDFs, extracts and cleans tables, and provides a normalized 21-table demonstration database.

## Current implementation

- 21 MySQL tables matching the submitted entity list
- 21 primary keys and 25 implemented foreign-key constraints
- 112 source records inventoried in `health_data.xlsx`
- Raw PDFs, extraction metadata, and extracted CSV tables retained for traceability
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

No database password is stored in this repository.

## ERD note

The submitted diagram shows the 21 entities and their conceptual relationships. The MySQL implementation enforces those relationships with 25 foreign-key constraints, including implementation columns used for patient, disease-subtype, laboratory, bed, vaccination, malnutrition, and designation links.

## GitHub

Repository: https://github.com/Ratul-debug/Health_DB_Project
