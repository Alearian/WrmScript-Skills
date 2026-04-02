# WRM-Compatible SQL Patterns

Copy-paste templates for WRM-compliant PostgreSQL DDL. All tables go in the `public` schema (no prefix needed — PostgreSQL defaults to `public`).

---

## Column Order Rule (always enforced)

```
1. Primary key          — INTEGER or BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
2. LIKE base.*          — one or more LIKE clauses (when BASE is active, not for ENUM/EVENT)
3. Foreign key columns  — *_id columns referencing other tables
4. All other columns    — descriptive, business data columns
```

---

## Standard Table (with BASE tracking)

Use for: most transactional and entity tables.

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking          INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id             INTEGER NOT NULL REFERENCES organisations(organisation_id),
    -- FK columns
    {fk_column}_id              INTEGER NOT NULL REFERENCES {fk_tables}({fk_column}_id),
    -- Business columns
    {column_name}               {DATA_TYPE} NOT NULL,
    {column_name}               {DATA_TYPE}
);

COMMENT ON TABLE {plural_table_names} IS '{TABLE_KEYWORD}[, optional description]';
COMMENT ON COLUMN {plural_table_names}.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN {plural_table_names}.{fk_column}_id IS '##';
COMMENT ON COLUMN {plural_table_names}.{natural_key_column} IS '##';
COMMENT ON COLUMN {plural_table_names}.{display_name_column} IS 'NAME';
```

---

## ENUM Table (reference/lookup data)

Use for: status types, categories, classifications — small fixed sets of values.

Rules:
- No `LIKE base.tracking` — ENUM tables are static, no audit trail needed
- No `organisation_id` — ENUMs are global reference data
- Include pre-seeded `INSERT` statements
- `COMMENT ON TABLE ... IS 'ENUM'`
- No `##` on the PK — lookups are by code or name column instead

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    {singular_table_name}_code  VARCHAR(50) NOT NULL UNIQUE,
    {singular_table_name}_name  VARCHAR(200) NOT NULL,
    display_order               INTEGER NOT NULL DEFAULT 0,
    is_active                   BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE {plural_table_names} IS 'ENUM';
COMMENT ON COLUMN {plural_table_names}.{singular_table_name}_code IS '##';
COMMENT ON COLUMN {plural_table_names}.{singular_table_name}_name IS 'NAME';

INSERT INTO {plural_table_names} ({singular_table_name}_code, {singular_table_name}_name, display_order) VALUES
    ('{CODE_1}', '{Name 1}', 1),
    ('{CODE_2}', '{Name 2}', 2),
    ('{CODE_3}', '{Name 3}', 3);
```

---

## PAGED Table (high volume)

Use for: orders, transactions, bookings, messages, log entries — anything expected > 10,000 rows.

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking          INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id             INTEGER NOT NULL REFERENCES organisations(organisation_id),
    {fk_column}_id              INTEGER NOT NULL REFERENCES {fk_tables}({fk_column}_id),
    {natural_key}               VARCHAR(100) NOT NULL,
    {column_name}               {DATA_TYPE} NOT NULL
);

COMMENT ON TABLE {plural_table_names} IS 'PAGED';
COMMENT ON COLUMN {plural_table_names}.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN {plural_table_names}.{fk_column}_id IS '##';
COMMENT ON COLUMN {plural_table_names}.{natural_key} IS '##';
```

---

## PAGED + ATTACHMENTS Table

Use for: entities that are high volume AND support file attachments.

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking          INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id             INTEGER NOT NULL REFERENCES organisations(organisation_id),
    {fk_column}_id              INTEGER REFERENCES {fk_tables}({fk_column}_id),
    {column_name}               {DATA_TYPE} NOT NULL
);

COMMENT ON TABLE {plural_table_names} IS 'PAGED, ATTACHMENTS';
COMMENT ON COLUMN {plural_table_names}.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN {plural_table_names}.{fk_column}_id IS '##';
```

---

## EVENT / Audit Log Table

Use for: append-only audit trails, activity logs, event streams.

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organisation_id             INTEGER REFERENCES organisations(organisation_id),
    user_id                     INTEGER REFERENCES users(user_id),
    entity_type                 VARCHAR(100) NOT NULL,
    entity_id                   INTEGER NOT NULL,
    event_type                  VARCHAR(100) NOT NULL,
    event_data                  JSONB,
    occurred_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE {plural_table_names} IS 'EVENT, READONLY, NOATTACHMENTS';
COMMENT ON COLUMN {plural_table_names}.organisation_id IS '##';
COMMENT ON COLUMN {plural_table_names}.user_id IS '##';
COMMENT ON COLUMN {plural_table_names}.entity_type IS '##&entity_id';
```

---

## Junction / Many-to-Many Table

Use for: linking two entities without tracking overhead. No LIKE base.tracking unless auditing is required.

```sql
CREATE TABLE {table_a}_{table_b} (
    {table_a}_{table_b}_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    {table_a}_id                INTEGER NOT NULL REFERENCES {table_a_plural}({table_a}_id),
    {table_b}_id                INTEGER NOT NULL REFERENCES {table_b_plural}({table_b}_id),
    UNIQUE ({table_a}_id, {table_b}_id)
);

COMMENT ON COLUMN {table_a}_{table_b}.{table_a}_id IS '##';
COMMENT ON COLUMN {table_a}_{table_b}.{table_b}_id IS '##';
```

---

## Table with Address and GPS

Use for: locations, venues, sites, branches.

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking          INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    LIKE base.address           INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    LIKE base.gps               INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id             INTEGER NOT NULL REFERENCES organisations(organisation_id),
    {singular_table_name}_name  VARCHAR(200) NOT NULL,
    {column_name}               {DATA_TYPE}
);

COMMENT ON TABLE {plural_table_names} IS 'ATTACHMENTS';
COMMENT ON COLUMN {plural_table_names}.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN {plural_table_names}.{singular_table_name}_name IS 'NAME, ##';
```

---

## READONLY System Table

Use for: system-managed configuration, generated reference data.

```sql
CREATE TABLE {plural_table_names} (
    {singular_table_name}_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking          INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    {column_name}               {DATA_TYPE} NOT NULL
);

COMMENT ON TABLE {plural_table_names} IS 'READONLY, NOATTACHMENTS';
COMMENT ON COLUMN {plural_table_names}.{natural_key} IS '##';
```

---

## COMMENT ON Block Template

Apply after each `CREATE TABLE`, in this order:
1. Table-level comment
2. FK column comments
3. Natural key / lookup column comments
4. NAME column comment
5. HIDE column comments (if any)

```sql
-- Table annotation
COMMENT ON TABLE {table} IS '{KEYWORD1}[, KEYWORD2][, description]';

-- FK columns (always ## or ##&scope)
COMMENT ON COLUMN {table}.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN {table}.{fk_name}_id IS '##';

-- Natural lookup keys
COMMENT ON COLUMN {table}.{code_or_ref_column} IS '##';

-- Display name
COMMENT ON COLUMN {table}.{name_column} IS 'NAME';

-- Hidden fields
COMMENT ON COLUMN {table}.{sensitive_column} IS 'HIDE';
```

---

## Complete Example: Order Management Schema

```sql
-- ENUM: order statuses
CREATE TABLE order_statuses (
    order_status_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_code         VARCHAR(50) NOT NULL UNIQUE,
    status_name         VARCHAR(100) NOT NULL,
    display_order       INTEGER NOT NULL DEFAULT 0
);

COMMENT ON TABLE order_statuses IS 'ENUM';
COMMENT ON COLUMN order_statuses.status_code IS '##';
COMMENT ON COLUMN order_statuses.status_name IS 'NAME';

INSERT INTO order_statuses (status_code, status_name, display_order) VALUES
    ('DRAFT',     'Draft',      1),
    ('SUBMITTED', 'Submitted',  2),
    ('APPROVED',  'Approved',   3),
    ('SHIPPED',   'Shipped',    4),
    ('DELIVERED', 'Delivered',  5),
    ('CANCELLED', 'Cancelled',  6);


-- PAGED + ATTACHMENTS: orders
CREATE TABLE orders (
    order_id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking  INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id     INTEGER NOT NULL REFERENCES organisations(organisation_id),
    order_status_id     INTEGER NOT NULL REFERENCES order_statuses(order_status_id),
    created_by_user_id  INTEGER REFERENCES users(user_id),
    order_ref           VARCHAR(50) NOT NULL,
    order_date          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_amount        NUMERIC(12, 2) NOT NULL DEFAULT 0,
    notes               TEXT
);

COMMENT ON TABLE orders IS 'PAGED, ATTACHMENTS';
COMMENT ON COLUMN orders.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN orders.order_status_id IS '##';
COMMENT ON COLUMN orders.created_by_user_id IS '##';
COMMENT ON COLUMN orders.order_ref IS '##';
COMMENT ON COLUMN orders.order_ref IS 'NAME';


-- Standard: order items
CREATE TABLE order_items (
    order_item_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking  INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    order_id            INTEGER NOT NULL REFERENCES orders(order_id),
    product_id          INTEGER NOT NULL REFERENCES products(product_id),
    quantity            INTEGER NOT NULL DEFAULT 1,
    unit_price          NUMERIC(10, 2) NOT NULL,
    line_total          NUMERIC(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

COMMENT ON COLUMN order_items.order_id IS '##';
COMMENT ON COLUMN order_items.product_id IS '##';
```
