# Final 21 schema-exact CSV relations

This directory is the directly inspectable CSV view of the implemented MySQL
database. It contains one file for each physical relation in `sql/schema.sql`.
Table names, column names, column order, values and row order exactly match
`sql/health_db_21_tables_with_data.sql`.

- Relations: 21
- Physical columns: 89
- Data rows: 68,185
- Blank or NULL stored values: 0
- Primary SQL authority: `sql/schema.sql` and the canonical full dump

These CSVs are generated outputs, not additional sources. Regenerate and
validate them with:

```bash
python scripts/12_export_verified_relational_tables.py
python scripts/09_validate_supervisor_corrections.py
```

Per-table counts and SHA-256 hashes are recorded in
`reports/normalized_sql_tables_manifest.csv`.
