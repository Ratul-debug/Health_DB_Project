# Supervisor review corrections

The handwritten review identifies the three extracted tables in
`086_Measles_Update_Till_14_05_26_` as concrete examples of bad structure/OCR.
The remaining observations concern the archive-wide ETL design and are applied
to all 3,802 raw extracted CSV tables.

| Review observation | Corrective control | Evidence |
|---|---|---|
| Measles tables have bad structure/OCR | Reconstructed all three against the official DGHS bulletin; flattened headers, standardized place names and Bengali digits, retained printed values | `verified_tables/086_Measles_Update_Till_14_05_26_/` |
| Structure integrity/OCR must be checked beyond the three examples | Added one strict structure/OCR/provenance/load-safety audit row and SHA-256 fingerprint for each of all 3,802 raw tables; unresolved results remain blocked | `reports/structure_ocr_integrity_audit.csv`, `reports/structure_ocr_integrity_summary.txt` |
| Legacy raw tables need page trace | Reconciled original metadata and conservatively recovered legacy page links; unavailable or uncertain pages are reported rather than guessed | `reports/extraction_page_trace.csv`, `scripts/11_recover_extraction_page_trace.py` |
| Cleaner only cleans headers | Cleaner now normalizes every cell, including Unicode/control characters, Bangla digits, numeric separators, whitespace/null tokens and duplicates | `scripts/cleaner.py`, `reports/cleaning_summary.csv` |
| Supposed clean tables are dirty | Every extracted table receives an accepted/review/rejected decision; unsafe results are routed to generated quarantine and blocked from load | `reports/etl_quality_gate_summary.txt` |
| Unlabelled data is forced into a category | Keyword classification requires two matches and a unique top score; insufficient/ambiguous evidence remains `unclassified` | `scripts/06_classify_tables.py`, `reports/classified_tables.csv` |
| Dirty data is imported | Only four explicit verified mappings are load-eligible; all other rows have a committed exclusion/block/reference reason | `reports/source_to_schema_mapping.csv` |
| “Schema and the extracted data seems unrelated” | Every catalogued output has a target decision or a reason why no compatible mapping exists; the four loaded mappings now show exact source fields, transformations, target columns and row counts | `reports/source_to_schema_mapping.csv`, `reports/loaded_source_to_sql_lineage.csv` |
| “Tables not normalized” | The ambiguous layer naming is corrected: `extracted_tables/` is explicitly labelled raw source evidence, `cleaned_tables/` means quality-passed extraction candidate, and only `sql/schema.sql` is the relational target. The report limits its BCNF proof to `Patient` instead of treating raw source layouts as normalized relations | `DATA_LAYER_AND_NORMALIZATION_GUIDE.md`, `extracted_tables/00_READ_ME_FIRST_RAW_NOT_SQL.md`, `sql/schema.sql` |
| Extracted data is not populated | Migration 006 loads 67,690 rows from four source-compatible mappings into `HealthFacility`, `Laboratory`, `Disease` and `Designation` | `reports/bangladesh_scale_pipeline_manifest.csv`, `sql/migrations/006_bangladesh_national_scale_expansion.sql` |

The Measles bulletin tables are aggregate division/city observations. The fixed
SQL `Measles` table is patient/event-grain and requires a real `PatientID`.
Consequently, those three corrected tables are verified reference outputs but
are excluded from SQL loading; converting them would fabricate individual
patient events. This preserves the submitted 21 entities, 89 columns and 25
foreign keys.

No raw table is deleted to improve the reported quality rate. A raw file may
retain OCR or structural defects because it is immutable extraction evidence;
its audit decision determines whether a corrected output is accepted,
quarantined, source-verified or excluded. This policy applies to all 3,802 raw
tables, not only to the three Measles examples.
