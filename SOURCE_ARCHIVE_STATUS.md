# Source archive status

The catalog contains 117 source records. The repository preserves 61 files that
have valid PDF signatures under `pdfs/`. Four downloaded URLs returned HTML web
pages rather than PDF documents; they are retained with truthful `.html`
extensions under `source_pages/`.

| Preserved file | Source URL |
|---|---|
| `source_pages/017_Measles.html` | https://www.who.int/emergencies/disease-outbreak-news/item/2026-DON598 |
| `source_pages/018_Information.html` | https://data.who.int/countries/050 |
| `source_pages/019_All_Health_Indicators_for_Bangladesh.html` | https://ap.wps.com/cms/docs/d/cbMascEJoyZx1ADs |
| `source_pages/072_Dengue_Press_Release_Till_11_05_2026_.html` | https://old.dghs.gov.bd/index.php/bd/home/5200-daily-dengue-status-report |

The original grouped catalog is preserved in the `Health` worksheet of
`health_data.xlsx`. The `Health_Catalog_Clean` worksheet is the machine-readable
version: it contains 117 rows, 117 populated links, no blank fields, explicit
source types, and an alias note for the one repeated URL used by two distinct
catalog descriptions.

Existing extracted CSV tables and metadata remain unchanged as raw evidence;
raw does not mean clean or loadable. All 3,802 are now assessed by the cleaner.
Accepted outputs are generated under `cleaned_tables/`, review/rejected outputs
under `quarantined_tables/`, and the table-level decisions are committed in
`reports/cleaning_summary.csv`.
The downloader now validates the response signature before choosing `.pdf` and
stores HTML responses in `source_pages/`, preventing misleading file extensions
in future runs.

Five official Bangladesh dataset/catalog entries were added for the
national-scale expansion. Their downloaded XLSX, XLS, JSON, and ZIP evidence is
stored under `source_datasets/`; the exact URLs, publication/snapshot dates,
collection date, mappings, exclusions, and hashes are recorded in
`source_datasets/README.md`. These files are separate from the 61-document PDF
count.

Their tabular extraction outputs are retained in numbered folders 114-118 under
`extracted_tables/`, matching their workbook catalog rows. Five corresponding
JSON lineage records are stored under `metadata/`; the generated cleaned layer
feeds migration 006 and is reproducible with
`scripts/08_build_bangladesh_scale_expansion.py`.

Across the complete archive there are 73 extraction/metadata source folders and
3,802 raw extracted CSV tables. The full catalog contains 3,807 pipeline outputs
after adding five derived mapping/reference files. It must not be described as
3,807 clean tables: `reports/etl_quality_gate_summary.txt` separates accepted,
curated, review-required, rejected and explicitly mapped outputs.

The three source-verified Measles corrections are tracked under
`verified_tables/086_Measles_Update_Till_14_05_26_/`. They remain aggregate
reference data because their grain cannot satisfy the existing patient/event
`Measles` schema without invented identifiers.
