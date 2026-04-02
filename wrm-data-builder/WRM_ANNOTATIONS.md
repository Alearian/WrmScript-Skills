# WRM Annotation Reference

WRM reads PostgreSQL `COMMENT ON` statements to configure code generation behaviour. Comments are parsed at build time by `CommentParser.cs`.

---

## Table-Level Annotations

Set with: `COMMENT ON TABLE table_name IS 'KEYWORD[, KEYWORD, optional description]';`

Multiple keywords are comma-separated. A human-readable description can follow the keywords and is used in generated documentation.

| Keyword | Effect on WRM Code Generation |
|---|---|
| `ENUM` | Marks as enumeration/reference table. No pagination. Read-only API endpoints. No `LIKE base.tracking`. Pre-seeded rows appear in generated test data seed scripts. |
| `PAGED` | All list endpoints require `skip`/`take` parameters. Generated components include pagination controls. Use when row count expected > 10,000. |
| `READONLY` | No Create, Update, or Delete endpoints generated. GET only. Used for system-managed tables. |
| `EVENT` | Treated as an append-only audit/event log. No update or delete. No `LIKE base.tracking` needed (events record their own timestamp). |
| `HIDE` | Table is excluded entirely from generated API, repositories, and components. Useful for internal or infrastructure tables. |
| `ATTACHMENTS` | Generated API includes file attachment endpoints for this entity. Requires FILEHANDLING feature. |
| `NOATTACHMENTS` | Explicitly suppresses attachment endpoints even when FILEHANDLING feature is active. Use on tables that would normally inherit attachment support. |
| `TREE` | Generates hierarchical tree model. Entity has a self-referencing parent FK. Generated API includes recursive tree queries. |
| `FLAT` | Generates a flat/denormalised read model joining multiple tables. Read-only. |
| `USESERVICE` | Forces generation of a service layer class even if the table wouldn't normally get one. |
| `ASQUERY` | Repository uses raw SQL queries instead of ORM-style Dapper mapping. Auto-applied to tables with geometry columns. |
| `NOTESTCASES` | Skips test case and test data generation for this table. |

### Examples

```sql
COMMENT ON TABLE order_statuses IS 'ENUM';
COMMENT ON TABLE orders IS 'PAGED, ATTACHMENTS';
COMMENT ON TABLE audit_events IS 'EVENT, READONLY, NOATTACHMENTS, NOTESTCASES';
COMMENT ON TABLE system_configs IS 'READONLY, HIDE';
COMMENT ON TABLE products IS 'PAGED, Catalogue of sellable products';
```

---

## Column-Level Annotations

Set with: `COMMENT ON COLUMN table_name.column_name IS 'KEYWORD[, description]';`

| Keyword | Effect on WRM Code Generation |
|---|---|
| `##` | Generates a `FindBy{ColumnName}()` repository method and corresponding API endpoint. Apply to natural lookup keys and all FK columns. |
| `##&{field}` | Generates a `FindBy{ColumnName}By{Field}()` method — a scoped/filtered lookup. The `{field}` is a second column on the same table used to filter results (typically `organisation_id`). |
| `## PAGED` | Same as `##` but the generated FindBy method is paginated. Use when the lookup could return many rows. |
| `NAME` | Marks this column as the primary human-readable name/title for the entity. Used in generated dropdowns, labels, and display components. |
| `HIDE` | Column is excluded from generated DTOs and API responses. Data exists in the database and DbModel but is never exposed. Use for password hashes, internal tokens, system flags. |
| `SHOW` | Explicitly includes a column in responses in soft-delete scenarios where it might otherwise be suppressed. |

### `##` — FindBy lookup (most common annotation)

Apply `##` to:
- Natural business keys: `email`, `user_name`, `reference_code`, `product_sku`, `slug`
- All FK columns: `organisation_id`, `user_id`, `category_id`, `status_id`, etc.
- Any column a developer would commonly search or filter by

WRM automatically generates the `FindBy` methods from `##` annotations — **do not add `CREATE LOOKUP` commands manually**.

### `##&field` — Scoped FindBy

Use when a FK lookup must be filtered by a second column on the same table:

```sql
-- Find role_permissions by role_id, filtered to a specific organisation
COMMENT ON COLUMN role_permissions.role_id IS '##&organisation_id';

-- Find entity_configs by entity_type and entity_id together
COMMENT ON COLUMN entity_configs.entity_type IS '##&entity_id';
```

### Examples

```sql
COMMENT ON COLUMN users.email IS '##';
COMMENT ON COLUMN users.user_name IS '##';
COMMENT ON COLUMN users.passhash IS 'HIDE';
COMMENT ON COLUMN users.display_name IS 'NAME';

COMMENT ON COLUMN orders.order_ref IS '##';
COMMENT ON COLUMN orders.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN orders.order_status_id IS '##';
COMMENT ON COLUMN orders.assigned_user_id IS '##';

COMMENT ON COLUMN products.product_sku IS '##';
COMMENT ON COLUMN products.product_name IS 'NAME';
COMMENT ON COLUMN products.category_id IS '##';
```

---

## LIKE Clauses — Base Schema Tables

WRM's base schema provides reusable column sets via PostgreSQL's `LIKE` clause. These are not annotations — they are SQL DDL that physically copies column definitions from a `base.*` table.

| Base Table | Columns Provided | When to Use |
|---|---|---|
| `base.tracking` | `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`, `is_deleted BOOLEAN DEFAULT FALSE`, `created_by INTEGER`, `updated_by INTEGER` | Every standard user table (not ENUM, not EVENT, not pure junction tables) |
| `base.address` | `address_line_1`, `address_line_2`, `town_city`, `county`, `postcode`, `country_code` | Any entity that has a physical address |
| `base.gps` | `latitude DOUBLE PRECISION`, `longitude DOUBLE PRECISION`, `altitude DOUBLE PRECISION` | Any entity with GPS/geolocation data |
| `base.event` | Base columns for event/audit log entries | Custom event tables (usually EVENT tables extend this) |

### LIKE syntax

```sql
-- Always after PK, before other columns
CREATE TABLE orders (
    order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id INTEGER NOT NULL REFERENCES organisations(organisation_id),
    -- ... remaining columns
);
```

Multiple LIKE clauses are allowed:

```sql
CREATE TABLE venues (
    venue_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    LIKE base.address INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    LIKE base.gps INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id INTEGER NOT NULL REFERENCES organisations(organisation_id),
    venue_name VARCHAR(200) NOT NULL
);
```
