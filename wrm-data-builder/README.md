# WRM Data Builder — AI Skill

Design PostgreSQL schemas that are fully compatible with [WormScript (WRM)](https://github.com/Alearian/WormScript) — the code scaffolding tool that generates complete .NET APIs, Dapper repositories, and React components from your database schema.

This skill gives your AI assistant expert knowledge of WRM's annotation system, naming conventions, feature architecture, and SQL patterns so it can produce schema files ready to drop straight into a `.wrm` project.

Supports **Claude Code**, **Cursor**, **GitHub Copilot**, **Windsurf**, and any tool that accepts a custom system prompt.

---

## What it does

When active, your AI will:

- **Assess your requirements** and recommend the right WRM features (AUTH, ORGANISATIONS, USERS, FILEHANDLING, FORMS, SUBSCRIPTIONS, etc.)
- **Detect schema conflicts** — if you define a column that WRM's feature system already provides (e.g. `created_at` from BASE), it asks you how to resolve it rather than silently overwriting
- **Classify every table** automatically — applying `ENUM` for small reference tables, `PAGED` for high-volume data, `EVENT` for audit logs, `ATTACHMENTS` where files are needed, etc.
- **Annotate columns** — adds `##` FindBy comments on FK and lookup columns, `NAME` on display fields, `HIDE` on sensitive fields
- **Enforce WRM column order** — PK first, then LIKE clauses, then FKs, then remaining columns
- **Enforce public schema** — corrects any non-`base.*` schema prefixes and explains why, with a link to request multi-schema support
- **Output annotated SQL** plus a ready-to-paste `.wrm` build script snippet with `DATABASE RUN` commands

---

## Quick install

### Claude Code

**macOS / Linux:**
```bash
git clone https://github.com/Alearian/WormScript-Skills.git
cd WormScript-Skills
bash install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/Alearian/WormScript-Skills.git
cd WormScript-Skills
.\install.ps1
```

Restart Claude Code. The skill loads automatically — trigger it with `/wrm-data-builder` or by describing a data design task.

---

### Cursor

Install into your project directory:

**macOS / Linux:**
```bash
bash install.sh --tool cursor
```

**Windows:**
```powershell
.\install.ps1 -Tool cursor
```

This copies `wrm-data-builder.mdc` into `.cursor/rules/`. Cursor picks it up automatically.

---

### GitHub Copilot

```bash
bash install.sh --tool copilot     # macOS/Linux
.\install.ps1 -Tool copilot        # Windows
```

Creates `.github/copilot-instructions.md` in the current directory.

---

### Windsurf

```bash
bash install.sh --tool windsurf    # macOS/Linux
.\install.ps1 -Tool windsurf       # Windows
```

Creates `.windsurfrules` in the current directory.

---

### Any other tool (Zed, Aider, Continue, custom system prompt)

Copy the contents of `adapters/generic.md` into your tool's system prompt or custom instructions field.

---

## Usage

Once installed, describe your data requirements naturally:

> *"I need a schema for a gym membership system with members, classes, bookings and payments"*

> *"Add a support ticket system to my existing WRM project that uses AUTH"*

> *"Design tables for a multi-tenant SaaS app where each organisation has projects and tasks"*

> *"I need a form builder feature — what WRM feature covers that?"*

The skill will walk you through feature selection, handle any conflicts with WRM's reserved schema, classify your tables, and produce annotated SQL ready for `DATABASE RUN`.

---

## Example output

Given *"a booking system for a sports centre"*, the skill produces SQL like:

```sql
-- Lookup table — static reference data
CREATE TABLE booking_statuses (
    booking_status_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_code         VARCHAR(50) NOT NULL UNIQUE,
    status_name         VARCHAR(100) NOT NULL,
    display_order       INTEGER NOT NULL DEFAULT 0
);
COMMENT ON TABLE booking_statuses IS 'ENUM';
COMMENT ON COLUMN booking_statuses.status_code IS '##';
COMMENT ON COLUMN booking_statuses.status_name IS 'NAME';

INSERT INTO booking_statuses (status_code, status_name, display_order) VALUES
    ('PENDING',   'Pending',   1),
    ('CONFIRMED', 'Confirmed', 2),
    ('CANCELLED', 'Cancelled', 3),
    ('COMPLETED', 'Completed', 4);


-- High-volume transactional table with file attachment support
CREATE TABLE bookings (
    booking_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LIKE base.tracking  INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
    organisation_id     INTEGER NOT NULL REFERENCES organisations(organisation_id),
    booking_status_id   INTEGER NOT NULL REFERENCES booking_statuses(booking_status_id),
    member_id           INTEGER NOT NULL REFERENCES members(member_id),
    facility_id         INTEGER NOT NULL REFERENCES facilities(facility_id),
    booking_ref         VARCHAR(20) NOT NULL,
    start_time          TIMESTAMPTZ NOT NULL,
    end_time            TIMESTAMPTZ NOT NULL,
    notes               TEXT
);
COMMENT ON TABLE bookings IS 'PAGED, ATTACHMENTS';
COMMENT ON COLUMN bookings.organisation_id IS '##&organisation_id';
COMMENT ON COLUMN bookings.booking_status_id IS '##';
COMMENT ON COLUMN bookings.member_id IS '##';
COMMENT ON COLUMN bookings.facility_id IS '##';
COMMENT ON COLUMN bookings.booking_ref IS '##';
COMMENT ON COLUMN bookings.booking_ref IS 'NAME';
```

...plus a `.wrm` snippet:

```
CREATE PROJECT SportsCentre
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    FEATURE AUTH
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=SportsCentre';

DATABASE RUN '.wrm/SportsCentre.sql';

CREATE TESTDATA IFEMPTY TESTCASES 10;
CREATE MODELS;
CREATE API CONTROLLERS SERVICE OVERWRITE;
CREATE COMPONENTS;
```

---

## WRM annotation reference

| Table comment | Effect |
|---|---|
| `ENUM` | Read-only reference table. No tracking columns. Pre-seeded data. |
| `PAGED` | API requires skip/take. Paginated components generated. |
| `READONLY` | GET endpoints only. No create/update/delete. |
| `EVENT` | Append-only audit log. No update/delete. |
| `ATTACHMENTS` | File upload endpoints generated. Requires FILEHANDLING feature. |
| `HIDE` | Table excluded from generated API entirely. |

| Column comment | Effect |
|---|---|
| `##` | Generates `FindBy{Column}()` method and API endpoint. Apply to FKs and lookup keys. |
| `##&field` | Scoped FindBy — filters by a second column (e.g. `##&organisation_id`). |
| `NAME` | Primary display name. Used in dropdowns and labels. |
| `HIDE` | Excluded from DTOs and API responses. |

---

## WRM features covered

| Feature | What it adds |
|---|---|
| `BASE` | Audit columns (created_at, updated_at, is_deleted) via base.tracking |
| `ORGANISATIONS` | Multi-tenancy — organisation_types, organisations |
| `USERS` | User accounts, profiles, groups, sessions |
| `AUTH` | JWT auth, roles, permissions, RBAC |
| `ENTITYCONFIG` | Key-value metadata and tagging on any entity |
| `FILEHANDLING` | File attachments, folders, retention/availability policies |
| `FORMS` | Dynamic form and field definitions |
| `SUBSCRIPTIONS` | Subscription tiers and user subscriptions |

---

## Requirements

- [WormScript (WRM)](https://github.com/Alearian/WormScript) — `dotnet tool install --global Wrm`
- PostgreSQL 13+

---

## Issues and feature requests

Found a problem or want to suggest an improvement?
- Skill issues: [github.com/Alearian/WormScript-Skills/issues](https://github.com/Alearian/WormScript-Skills/issues)
- WRM tool issues: [github.com/Alearian/WormScript/issues](https://github.com/Alearian/WormScript/issues)
