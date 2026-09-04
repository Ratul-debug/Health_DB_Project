# Raw extraction archive - not the MySQL schema

The numbered subdirectories here contain source-shaped CSV evidence produced by
PDF/dataset extraction. They are intentionally preserved before relational
mapping and can contain merged headers, aggregate layouts, sparse cells or OCR
damage inherited from the source.

Do not evaluate these CSVs as the project's 21 normalized database tables and
do not import them directly. The implemented database is defined only by
`../sql/schema.sql` and `../sql/health_db_21_tables_with_data.sql`.

Every raw CSV has a structure/OCR/load-safety decision in
`../reports/structure_ocr_integrity_audit.csv` and a mapping decision in
`../reports/source_to_schema_mapping.csv`. Source-verified corrections are in
`../verified_tables/`; only explicit compatible-grain mappings may reach SQL.

See `../DATA_LAYER_AND_NORMALIZATION_GUIDE.md` for the complete layer model.
