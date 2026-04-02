# SQL Conventions

SQL schema design for WRM is handled by the **`wrm-data-builder`** skill.

Use `/wrm-data-builder` when you need to:
- Design PostgreSQL tables compatible with WRM
- Apply WRM annotations (`COMMENT ON TABLE/COLUMN` for `ENUM`, `PAGED`, `##`, `NAME`, `HIDE`, etc.)
- Use `LIKE base.tracking` and other base schema patterns
- Resolve conflicts with WRM's reserved column names
- Get a ready-to-use `.wrm` `DATABASE RUN` snippet for the generated SQL

`wrm-data-builder` produces annotated `.sql` files ready to drop into your `.wrm` project. Once you have the SQL file, use `wrm-tool` to write the build script and run `wrm build`.

---

For reference, WRM expects the following conventions in SQL files:

- Table names: **plural snake_case** (`orders`, `product_categories`)
- Primary key: **`{singular_table}_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY`** — always the first column
- `LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS` — immediately after PK on standard tables
- Foreign key columns — after LIKE clauses, before other columns; column name ends with `_id`
- All user tables in the **`public`** schema

For the full SQL pattern reference see the `wrm-data-builder` skill files:
`WRM_ANNOTATIONS.md`, `WRM_CONFLICTS.md`, `SQL_PATTERNS.md`
