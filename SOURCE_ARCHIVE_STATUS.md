# Source archive status

The catalog contains 112 source records. The repository preserves 61 files that
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
version: it contains 112 rows, 112 populated links, no blank fields, explicit
source types, and an alias note for the one repeated URL used by two distinct
catalog descriptions.

Existing extracted CSV tables and metadata remain unchanged as raw evidence.
The downloader now validates the response signature before choosing `.pdf` and
stores HTML responses in `source_pages/`, preventing misleading file extensions
in future runs.
