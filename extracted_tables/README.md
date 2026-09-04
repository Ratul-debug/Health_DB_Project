# Raw extracted tables

Files in this directory are immutable **raw extraction evidence**. They preserve
what the automated PDF/dataset extractor produced, including OCR defects,
multi-row headers, shifted cells and sparse layouts. A file being present here
does not mean that it is clean, normalized, classified or eligible for MySQL.

The next pipeline stages are:

1. `scripts/cleaner.py` normalizes values and headers and applies structural
   quality checks to every raw CSV.
2. Accepted outputs are generated under `cleaned_tables/`; unsafe outputs are
   generated under `quarantined_tables/`.
3. `reports/cleaning_summary.csv` records the quality status and reason for all
   3,802 raw tables.
4. `reports/source_to_schema_mapping.csv` records the classification, target
   table, load eligibility and decision reason for all 3,807 pipeline outputs.
5. Only an explicit, field-level, compatible-grain mapping can feed SQL.
6. `scripts/10_audit_all_extracted_tables.py` independently records structure
   integrity, OCR risk, raw SHA-256, provenance and load safety for every raw
   table in `reports/structure_ocr_integrity_audit.csv`.
7. `scripts/11_recover_extraction_page_trace.py --recover-pages` reconciles
   original and legacy page traces; unresolved pages are never guessed.

The three OCR-damaged Measles examples from source 086 have source-verified
corrections under `verified_tables/086_Measles_Update_Till_14_05_26_/`. Their
aggregate division/city grain is incompatible with the patient/event-grain
`Measles` SQL table, so they are verified reference data and are not fabricated
as individual patient rows.
