# Health DB ETL and Load

## Setup
1. From project root:
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

## Run ETL (dry run)
python -m scripts.run_etl --input_dir extracted_tables --dry_run

## Run full ETL
python -m scripts.run_etl --input_dir extracted_tables

## Optional cleanup choices
- Drop title/header rows:
  staging/reports.cleaned_drop_titles.csv is produced by the helper script (or run the provided Python snippet).
- Fill missing dates by year extraction:
  staging/reports.filled_dates.csv is produced by the provided Python snippet.

## Create MySQL schema
mysql -u root -p < create_tables_mysql.sql

## Create staging table
mysql -u youruser -p health_db < create_reports_staging.sql

## Load CSV into staging
mysql --local-infile=1 -u youruser -p health_db -e "
LOAD DATA LOCAL INFILE '/full/path/to/Health_DB_Project_2/staging/reports.filled_dates.csv'
INTO TABLE reports_staging
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(pdf_name, facility_name, facility_code, division, district, upazila, disease_name, report_date, age_group, sex, cases, deaths, notes, ocr_confidence);
"

## Aggregate and upsert into reports
mysql -u youruser -p health_db < upsert_reports.sql

## Verify
mysql -u youruser -p -e "USE health_db; SELECT COUNT(*) FROM reports; SELECT SUM(cases) FROM reports;"

