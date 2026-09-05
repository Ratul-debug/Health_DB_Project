# SQL directory guide

The physical MySQL implementation is defined by the following files:

| Path | Meaning |
|---|---|
| `schema.sql` | Canonical 21-table schema without data |
| `health_db_21_tables_with_data.sql` | Canonical schema plus all 68,185 rows |
| `validation/validation_queries.sql` | Structural, relationship, blank, duplicate, semantic, and lineage checks |
| `migrations/` | Ordered historical transformations used to reach the canonical snapshot |

The migration files are not alternative schemas. They are retained as an
auditable history and are already incorporated into the full dump. For a fresh
demonstration database, restore `health_db_21_tables_with_data.sql` directly and
then run `validation/validation_queries.sql`.

Expected final state: 21 tables, 21 primary keys, 25 foreign keys, 89 mandatory
columns, 68,185 populated rows, zero empty tables, and zero stored blank/NULL
values.
