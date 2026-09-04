# Supervisor review corrections

The handwritten review identifies the three extracted tables in
`086_Measles_Update_Till_14_05_26_` as concrete examples of bad structure/OCR.
The remaining observations concern the archive-wide ETL design and are applied
to all 3,802 raw extracted CSV tables.

| Review observation | Corrective control | Evidence |
|---|---|---|
| Measles tables have bad structure/OCR | Reconstructed all three against the official DGHS bulletin; flattened headers, standardized place names and Bengali digits, retained printed values | `verified_tables/086_Measles_Update_Till_14_05_26_/` |
| Cleaner only cleans headers | Cleaner now normalizes every cell, including Unicode/control characters, Bangla digits, numeric separators, whitespace/null tokens and duplicates | `scripts/cleaner.py`, `reports/cleaning_summary.csv` |
| Supposed clean tables are dirty | Every extracted table receives an accepted/review/rejected decision; unsafe results are routed to generated quarantine and blocked from load | `reports/etl_quality_gate_summary.txt` |
| Unlabelled data is forced into a category | Keyword classification requires two matches and a unique top score; insufficient/ambiguous evidence remains `unclassified` | `scripts/06_classify_tables.py`, `reports/classified_tables.csv` |
| Dirty data is imported | Only four explicit verified mappings are load-eligible; all other rows have a committed exclusion/block/reference reason | `reports/source_to_schema_mapping.csv` |
| Extracted data and schema seem unrelated | Every catalogued pipeline output now has a target-table decision or an explicit reason why no mapping is valid | `reports/source_to_schema_mapping.csv` |
| Tables are not normalized | Raw source tables remain raw evidence; normalization occurs only at the 21-table physical SQL target, not by altering source grain | `sql/schema.sql`, `REPORT_ALIGNMENT.md` |
| Extracted data is not populated | Migration 006 loads 67,690 rows from four source-compatible mappings into `HealthFacility`, `Laboratory`, `Disease` and `Designation` | `reports/bangladesh_scale_pipeline_manifest.csv`, `sql/migrations/006_bangladesh_national_scale_expansion.sql` |

The Measles bulletin tables are aggregate division/city observations. The fixed
SQL `Measles` table is patient/event-grain and requires a real `PatientID`.
Consequently, those three corrected tables are verified reference outputs but
are excluded from SQL loading; converting them would fabricate individual
patient events. This preserves the submitted 21 entities, 89 columns and 25
foreign keys.
