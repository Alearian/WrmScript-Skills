---
name: wrm-data-builder
author: furniss
keywords: postgresql postgres sql schema database design wrm wormscript data model

description: Create PostgreSQL SQL schemas that are fully compatible with WRM (WormScript). Use when the user wants to design a database schema for a WRM project, convert an existing schema to WRM conventions, add tables to an existing WRM project, or produce annotated SQL ready to drop into a .wrm build script.
---

# WRM Data Builder Skill

This skill produces PostgreSQL SQL schemas that are 100% compatible with WRM (WormScript). It assesses the user's data requirements, recommends appropriate WRM features, detects and resolves schema conflicts, applies WRM annotations, and outputs annotated SQL plus a ready-to-paste `.wrm` feature block.

Reference files in this skill directory:
- [WRM_ANNOTATIONS.md](WRM_ANNOTATIONS.md) - COMMENT ON syntax and all WRM keywords
- [WRM_CONFLICTS.md](WRM_CONFLICTS.md) - Reserved column names per feature
- [FEATURE_ASSESSMENT.md](FEATURE_ASSESSMENT.md) - Feature detection heuristics and dependency graph
- [SQL_PATTERNS.md](SQL_PATTERNS.md) - Copy-paste SQL templates

---

## Workflow

### Step 1 — Gather Requirements

Accept any of:
- Natural language domain description ("I need a system to manage gym memberships")
- List of entities and fields
- Partial or draft SQL
- An explicit WRM feature name the user wants to use

If input is too vague to determine tables and columns, ask:
1. What entities/tables are needed?
2. Approximate row volume per table (to decide PAGED vs standard)
3. Are there users, logins, or authentication needs?
4. Are there multiple organisations or tenants?
5. Are there file upload or attachment needs?

Do **not** ask if the answers are already clear from context.

---

### Step 2 — Assess WRM Feature Fit

Read [FEATURE_ASSESSMENT.md](FEATURE_ASSESSMENT.md) and recommend features based on signals in the user's input.

If the user **explicitly names** a WRM feature, include it without question.

Present recommended features to the user before proceeding:
> "Based on your requirements I recommend these WRM features: **AUTH, FILEHANDLING**. AUTH brings in USERS, ORGANISATIONS, and BASE automatically. Shall I proceed with these, or would you like to adjust?"

Wait for confirmation or adjustment before continuing.

---

### Step 3 — Detect and Resolve Schema Conflicts

Read [WRM_CONFLICTS.md](WRM_CONFLICTS.md) for the full list of reserved column names injected by each active WRM feature.

For every user-defined column that matches a reserved name, pause and ask:

> "Your table `{table}` defines `{column}` which is already provided by WRM's {FEATURE} feature via `{source}`. How would you like to handle this?
> **A)** Use WRM's version — remove yours (recommended)
> **B)** Rename yours to `{suggested_rename}` and keep both
> **C)** Keep only yours and skip the WRM-provided one
> **D)** Something else — describe what you need"

Apply the user's chosen resolution before generating SQL.

---

### Step 4 — Classify Each Table

Apply the rules below automatically. Tell the user which classifications were applied and why.

#### Table-level annotations

| Condition | Annotation |
|---|---|
| Fixed reference data, ≤ ~20 rows (statuses, types, categories) | `COMMENT ON TABLE ... IS 'ENUM'` |
| Transactional or user data likely to exceed 10,000 rows | `COMMENT ON TABLE ... IS 'PAGED'` |
| System-managed, never directly user-edited | `COMMENT ON TABLE ... IS 'READONLY'` |
| Audit log or event history table | `COMMENT ON TABLE ... IS 'EVENT'` |
| Should not be exposed in the generated API | `COMMENT ON TABLE ... IS 'HIDE'` |
| Entity that can have files/documents attached | `COMMENT ON TABLE ... IS 'ATTACHMENTS'` |
| Explicitly should never have attachments | `COMMENT ON TABLE ... IS 'NOATTACHMENTS'` |

A table can have multiple keywords: `COMMENT ON TABLE orders IS 'PAGED, ATTACHMENTS';`

ENUM tables do **not** get `LIKE base.tracking` — they are static reference data.

#### Column-level annotations

| Condition | Annotation |
|---|---|
| Natural lookup key: email, code, slug, reference number, name | `COMMENT ON COLUMN ... IS '##'` |
| FK column pointing to another table | `COMMENT ON COLUMN ... IS '##'` — triggers WRM FindBy lookup generation |
| FK lookup that must be scoped to a parent (e.g. by organisation) | `COMMENT ON COLUMN ... IS '##&organisation_id'` |
| Primary human-readable display name for the entity | `COMMENT ON COLUMN ... IS 'NAME'` |
| Sensitive field: password hash, secret token, internal key | `COMMENT ON COLUMN ... IS 'HIDE'` |

WRM automatically generates `FindBy` lookup methods from `##` annotations — do **not** add `CREATE LOOKUP` commands manually.

---

### Step 5 — Generate the SQL

Invoke the `data:sql-queries` skill with the following constraints pre-specified. Pass these rules explicitly in your prompt to that skill:

**Schema rules:**
- All user-defined tables go in the `public` schema — no schema prefix on table names
- `base.*` tables (e.g. `base.tracking`, `base.address`, `base.gps`, `base.event`) may be referenced in `LIKE` clauses but are never created by the user
- Do NOT write `CREATE SCHEMA` statements

**Naming conventions:**
- Table names: plural snake_case (`orders`, `product_categories`, `booking_items`)
- Column names: singular snake_case
- Primary key: singular table name + `_id` (e.g. table `orders` → PK `order_id`)
- Foreign key columns: end in `_id`, no schema prefix (e.g. `organisation_id`, `user_id`)

**Column order within each CREATE TABLE (strictly enforced):**
1. **Primary key** — always first
2. **LIKE base.<table> clauses** — immediately after PK, before any other columns
3. **Foreign key columns** (`*_id`) — after LIKE clauses
4. **All other columns** — after FK columns

**Primary key rules:**
- Type must be `INTEGER` or `BIGINT` — no `SERIAL`, no `UUID`, no `BIGSERIAL`
- Always use `GENERATED ALWAYS AS IDENTITY`
- Example: `order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY`

**LIKE clauses (when BASE feature is active):**
- Every non-ENUM, non-EVENT, non-junction table: `LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS`
- Address data: add `LIKE base.address INCLUDING DEFAULTS INCLUDING CONSTRAINTS`
- GPS/location data: add `LIKE base.gps INCLUDING DEFAULTS INCLUDING CONSTRAINTS`
- ENUM tables: no LIKE clause, no tracking columns

**FK column conventions:**
- Include FK column even if it is also provided by a LIKE clause (e.g. `organisation_id` when ORGANISATIONS is active) — the conflict step handles duplicates
- Add NOT NULL to required FKs, allow NULL for optional relationships

---

### Step 6 — Post-Process the SQL

After the SQL is returned from the data skill, apply these checks and fixes in order:

**6a — Schema compliance**
Scan every `CREATE TABLE` statement. If any table has a `schema.tablename` prefix where schema is not `base`:
- Automatically remove the schema prefix, placing the table in `public`
- Notify the user:
  > "Table `{schema}.{table}` has been moved to the `public` schema. WRM currently requires all user-defined tables to be in `public` — multi-schema support is not yet implemented. You can request this feature at https://github.com/Alearian/WormScript/issues"

**6b — Column order**
Verify each table's column order: PK → LIKE clauses → FK columns → remaining columns. Re-order if the data skill placed them differently.

**6c — PK type**
Verify every PK is `INTEGER` or `BIGINT GENERATED ALWAYS AS IDENTITY`. Correct any `SERIAL`, `BIGSERIAL`, `UUID`, or bare `INTEGER PRIMARY KEY` found.

**6d — Add COMMENT ON blocks**
After each `CREATE TABLE` block add the table annotation (if any), then all column annotations. Format:

```sql
COMMENT ON TABLE orders IS 'PAGED, ATTACHMENTS';
COMMENT ON COLUMN orders.order_ref IS '##';
COMMENT ON COLUMN orders.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN orders.order_status_id IS '##';
```

**6e — Add pre-seeded INSERTs for ENUM tables**
If a table is ENUM and the user described the valid values, include `INSERT INTO` statements immediately after the COMMENT ON for that table.

---

### Step 7 — Output

Produce two clearly labelled blocks:

#### Block 1: SQL file(s)

Present as one or more fenced SQL code blocks labelled with the suggested filename (e.g. `.wrm/MyProject.sql`). If the schema is large, split into logical files:
- Core application tables → `.wrm/MyProject.sql`
- ENUM/lookup seed data → `.wrm/MyProject-enums.sql` (if it aids clarity)

#### Block 2: .wrm feature snippet

A ready-to-paste `.wrm` build script block. Include:
- All recommended features (one `FEATURE` line each)
- A `DATABASE RUN` command for **every SQL file** produced in Block 1 (one line per file)
- Standard build commands

```
CREATE PROJECT <Name>
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    FEATURE AUTH
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=<Name>';

DATABASE RUN '.wrm/<Name>.sql';
DATABASE RUN '.wrm/<Name>-enums.sql';

CREATE TESTDATA IFEMPTY TESTCASES 10;
CREATE MODELS;
CREATE API CONTROLLERS SERVICE OVERWRITE;
CREATE COMPONENTS;
```

#### Block 3: Classification summary

A short table telling the user what was applied and why:

| Table | Classification | Reason |
|---|---|---|
| `order_statuses` | ENUM | Fixed reference data, ~5 rows |
| `orders` | PAGED, ATTACHMENTS | High volume transactional, supports receipts |
| `audit_log` | EVENT, READONLY | Append-only audit trail |

---

## Key Rules (never break these)

1. **Never silently resolve a conflict** — always ask the user when a column name clashes with a WRM reserved name
2. **Never add CREATE LOOKUP commands** — WRM generates lookups automatically from `##` column comments
3. **PK is always first column, always INTEGER or BIGINT GENERATED ALWAYS AS IDENTITY**
4. **LIKE clauses are always immediately after PK, before all other columns**
5. **ENUM tables have no LIKE base.tracking** — they are static data
6. **All user tables in public schema** — correct silently but always notify the user when a correction is made
7. **FK columns get `##` comments** — this enables WRM to generate FindBy methods for relationship navigation
8. **One DATABASE RUN per SQL file** — never combine multiple files into one DATABASE RUN
