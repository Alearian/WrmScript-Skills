# WRM Data Builder Instructions

When designing or reviewing PostgreSQL database schemas for WormScript (WRM) projects, follow these instructions.

## Workflow

### 1. Gather requirements
Accept natural language, entity lists, or partial SQL. If unclear, ask: entity names, row volumes per table, auth/users/orgs/file upload needs.

### 2. Recommend WRM features
Present recommendations and confirm before generating SQL.

| Signal | Feature |
|---|---|
| Users, login, accounts | `FEATURE USERS` |
| Roles, permissions | `FEATURE AUTH` (includes USERS, BASE; does NOT include ORGANISATIONS) |
| Multiple tenants/orgs | `FEATURE ORGANISATIONS` |
| File uploads, attachments | `FEATURE FILEHANDLING` |
| Metadata, tags | `FEATURE ENTITYCONFIG` |
| Dynamic forms | `FEATURE FORMS` |
| Subscriptions, billing | `FEATURE SUBSCRIPTIONS` |

### 3. Detect and resolve conflicts
Check user columns against WRM reserved names. NEVER silently resolve — always ask:
> "Your table `{table}` defines `{column}` which WRM's {FEATURE} already provides via `{source}`. A) Use WRM's (recommended) B) Rename yours to `{table}_{column}` C) Keep yours D) Something else"

**Reserved names:**
- BASE: `created_at`, `updated_at`, `is_deleted`, `created_by`, `updated_by`, `address_line_1`, `address_line_2`, `town_city`, `county`, `postcode`, `country_code`, `latitude`, `longitude`, `altitude`
- ORGANISATIONS adds: `organisation_id` (and reserved tables `organisation_types`, `organisations`)
- AUTH adds: `role_id`, `permission_id` (and reserved tables `permissions`, `roles`, `user_roles`, `role_permissions`)
- FILEHANDLING adds: `attachment_id`, `folder_id` (and reserved tables `attachments`, `entity_attachments`, `folders`, `storage_types`)
- USERS reserved tables: `users`, `user_profiles`, `user_communications`, `user_groups`, `sessions`

### 4. Classify each table
Apply automatically and explain to the user.

**Table `COMMENT ON` keywords:**
- `ENUM` — fixed reference data ≤~20 rows (no tracking columns, include INSERT seeds)
- `PAGED` — expected >10,000 rows (API requires skip/take)
- `READONLY` — system-managed, no create/update/delete
- `EVENT` — append-only audit log
- `ATTACHMENTS` — file upload endpoints (requires FILEHANDLING)
- `NOATTACHMENTS` — explicitly opt out of attachments
- `HIDE` — excluded from generated API

Multiple keywords: `COMMENT ON TABLE orders IS 'PAGED, ATTACHMENTS';`

**Column `COMMENT ON` keywords:**
- `##` — generates FindBy method; apply to ALL FK columns and natural lookup keys
- `##&organisation_id` — scoped/filtered FindBy
- `NAME` — primary display name field
- `HIDE` — excluded from DTOs and API responses

**Do NOT add `CREATE LOOKUP` commands** — WRM generates these automatically from `##`.

### 5. SQL rules (mandatory)

1. **All user tables in `public` schema** — `base.*` LIKE references are allowed; any other schema prefix: move to public and notify: *"moved to `public` — WRM requires all user tables in public. Request multi-schema at https://github.com/Alearian/WormScript/issues"*
2. **Column order: PK → LIKE clauses → FK columns → other columns**
3. **PK always first** — `INTEGER` or `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
4. **LIKE base.tracking on all standard tables** when BASE active — NOT on ENUM or EVENT tables
5. Table names: plural snake_case; PK: `{singular_table}_id`; FK columns end in `_id`

### 6. Output

**Block 1:** Annotated SQL as fenced code block(s), labelled with filename (`.wrm/MyProject.sql`)

**Block 2:** Ready-to-paste `.wrm` snippet:
```
CREATE PROJECT <Name>
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    FEATURE AUTH
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=<Name>';

DATABASE RUN '.wrm/<Name>.sql';

CREATE TESTDATA IFEMPTY TESTCASES 10;
CREATE MODELS;
CREATE API CONTROLLERS SERVICE OVERWRITE;
CREATE COMPONENTS;
```
One `DATABASE RUN` line per SQL file generated.

**Block 3:** Classification summary table showing what was applied and why.

## SQL patterns

**Standard table:**
```sql
CREATE TABLE orders (
    order_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id INTEGER NOT NULL REFERENCES organisations(organisation_id),
    status_id       INTEGER NOT NULL REFERENCES order_statuses(order_status_id),
    order_ref       VARCHAR(50) NOT NULL
);
COMMENT ON TABLE orders IS 'PAGED, ATTACHMENTS';
COMMENT ON COLUMN orders.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN orders.status_id IS '##';
COMMENT ON COLUMN orders.order_ref IS '##';
COMMENT ON COLUMN orders.order_ref IS 'NAME';
```

**ENUM table (no LIKE, with seed data):**
```sql
CREATE TABLE order_statuses (
    order_status_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_code      VARCHAR(50) NOT NULL UNIQUE,
    status_name      VARCHAR(100) NOT NULL,
    display_order    INTEGER NOT NULL DEFAULT 0
);
COMMENT ON TABLE order_statuses IS 'ENUM';
COMMENT ON COLUMN order_statuses.status_code IS '##';
COMMENT ON COLUMN order_statuses.status_name IS 'NAME';
INSERT INTO order_statuses (status_code, status_name, display_order) VALUES
    ('DRAFT', 'Draft', 1), ('ACTIVE', 'Active', 2), ('CLOSED', 'Closed', 3);
```
