# Bangladesh-only source datasets

Collected on **2026-09-01** for migration
`006_bangladesh_national_scale_expansion.sql`. The physical database remains the
same 21 tables, 89 mandatory columns, 21 primary keys, and 25 foreign keys.

| Archived source | Official publisher and source | Release/snapshot | Source rows/concepts | Existing-table use |
|---|---|---|---:|---|
| `dghs_active_facility_registry_2026-09-01.xlsx` | DGHS Facility Registry: https://hrm.dghs.gov.bd/public/facility-registry | Live snapshot collected 2026-09-01 | 39,434 | `HealthFacility`; 9,694 qualifying facility types also create linked `Laboratory` rows |
| `bd_condition_icd11_2025_01_ocl.json` | DGHS/MoHFW Bangladesh Condition ValueSet: https://fhir.dghs.gov.bd/core/ValueSet-bd-condition-icd11-diagnosis-valueset.html | ICD-11-MMS source version 2025-01; public expansion collected 2026-09-01 | 18,508 | `Disease` (`display_name` to `DiseaseName`; OCL concept ID to `ICDCode`) |
| `bd_core_fhir_ig_0.4.6_full.zip` | Bangladesh Core FHIR Implementation Guide: https://fhir.dghs.gov.bd/core/artifacts.html | v0.4.6, generated 2026-04-27 | Documentation package | Terminology and profile evidence |
| `bd_vaccine_valueset_0.4.6.json` and `bd_vaccine_code_system_0.4.6.json` | DGHS/MoHFW Bangladesh Vaccine ValueSet: https://fhir.dghs.gov.bd/core/ValueSet-bd-vaccine-valueset.html | IG v0.4.6, generated 2026-04-27 | 10 codes | Reference evidence only; not patient events |
| `bangladesh_open_data_doctor_directory_2016.xls` | Bangladesh Open Data Doctor Directory: https://data.gov.bd/dataset/doctor-directory | Released 2016-10-18; metadata modified 2017-01-18 | 199 providers; 68 raw Post values | 54 clean, previously absent Post values to `Designation` |

The raw downloads remain in this directory. Faithful machine-readable
conversions are retained under the matching catalog-row folders in
`extracted_tables/`; mapping-ready physical-table CSVs are generated under
`cleaned_tables/`. Per-source lineage is stored in `metadata/114_*.json` through
`metadata/118_*.json`.

## Mapping and inclusion rules

- Every DGHS facility source row has non-blank `Id`, `Name`, `Type`, and
  `Division`; all 39,434 unique IDs are included. `FacilityID` is the official
  ID plus 100,000. The stored name retains the exact source name and appends the
  official DGHS ID for uniqueness and traceability.
- Facility types `Consultancy & Diagnostic Center`, `Blood Bank`, and
  `Drug Testing Laboratory` are included as `Laboratory` rows. Each laboratory
  foreign key points to its own included facility.
- All 18,508 concepts returned by the public Bangladesh OCL expansion are
  included: 13,389 Diagnosis and 5,119 Finding concepts. Code and display name
  are non-blank and unique. The FHIR guide's narrative count is 19,661; the
  database uses the 18,508 records actually returned and archived on the
  collection date, not the larger narrative figure.
- The Doctor Directory has 199 provider rows but no Gender field. Since
  `HealthWorker.Gender` is mandatory, provider rows are excluded rather than
  filled with invented values. Only 54 clean, non-duplicate Post values are
  mapped to `Designation`.
- The vaccine source is a terminology list and has no patient identifiers or
  vaccination dates. It is retained in the catalog and archive but does not
  create synthetic `Vaccination` events.

## Reproducibility and integrity

Run from the repository root:

```bash
python scripts/08_download_bangladesh_scale_sources.py
python scripts/08_build_bangladesh_scale_expansion.py
```

The downloader validates XLSX/ZIP/XLS signatures, JSON parsing, OCL pagination,
and the expected Condition concept count before replacing archived files. The
generator asserts row counts, required fields, unique IDs/codes, valid
division mappings, and laboratory-to-facility relationships before producing
SQL. It recreates the extraction and cleaned mapping layers, reads the cleaned
rows back, and writes `reports/bangladesh_scale_pipeline_manifest.csv` plus
`reports/bangladesh_national_scale_static_validation.txt` with source hashes and
table totals. This static report is not a substitute for the isolated MySQL
restore and full validation required before commit/push.

## Licensing note

The Bangladesh Condition ValueSet uses ICD-11-MMS terminology. ICD-11 content
is copyrighted by the World Health Organization and is used under the licence
identified by the official DGHS/MoHFW implementation guide. Retention in this
academic repository does not transfer ownership or create a new licence; users
must follow the official source terms when redistributing or reusing it.
