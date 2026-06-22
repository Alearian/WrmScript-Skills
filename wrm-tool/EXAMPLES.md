# WRM Project Examples

Real-world examples of .wrm scripts and SQL schemas.

---

## Example 1: Minimal Starter (Star Systems)

A simple project with three tables demonstrating basic relationships.

### Schema: `.wrm/SpaceExplorer.sql`

```sql
-- STAR-SYSTEMS
DROP TABLE IF EXISTS star_systems;
CREATE TABLE star_systems(
    star_system_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    system_name VARCHAR(255) NOT NULL
);

-- STARS - Stars that belong in a star-system
DROP TABLE IF EXISTS stars;
CREATE TABLE stars(
    star_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    star_system_id INTEGER,
    star_name VARCHAR(255) NOT NULL
);

-- PLANETS
DROP TABLE IF EXISTS planets;
CREATE TABLE planets(
    planet_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    star_id INTEGER,
    planet_name VARCHAR(255) NOT NULL,
    planet_code VARCHAR(25) NOT NULL
);
```

### Build Script: `.wrm/SpaceExplorer.wrm`

```wrm
CREATE PROJECT SpaceExplorer
    FEATURE SWAGGER
    FEATURE HARD DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=SpaceExplorer';

DATABASE RUN '.wrm/SpaceExplorer.sql';

CREATE TESTDATA IFEMPTY TESTCASES 10;
CREATE MODELS;
CREATE API CONTROLLERS SERVICE;
CREATE COMPONENTS REACT;
```

**What this generates:**
- 3 DbModels, 3 DTOs, 3 Mappers, 3 Repositories, 3 Controllers
- React components (Table, Form, Card, Dropdown, Api) for each entity
- Swagger documentation
- No auth, no soft delete, no features

---

## Example 2: RevCamp (Event Management)

A full-featured event/camp management application with auth, file handling, and multiple entity relationships.

### Build Script: `.wrm/RevCamp.wrm`

```wrm
CREATE PROJECT RevCamp
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=RevCamp'
    HTTP 5010 HTTPS 5011
    FEATURE USERS
    FEATURE ORGANISATIONS
    FEATURE FILEHANDLING
    FEATURE AUTH;

DATABASE RUN '.wrm/RevCamp.sql';

CREATE TESTDATA TESTCASES 10;
CREATE MODELS;
CREATE MODEL FLAT Registrations FROM camps HAVING bookings;

CREATE API CONTROLLERS SERVICE OVERWRITE CLEAR;
```

### Schema highlights: `.wrm/RevCamp.sql`

```sql
-- Uses base.tracking for all tables
CREATE TABLE camps
    (
        camp_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
        camp_title            VARCHAR(255) NOT NULL,
        gathering_description VARCHAR(255) NOT NULL,
        start_date TIMESTAMPTZ NOT NULL,
        end_date TIMESTAMPTZ NOT NULL,
        address VARCHAR(255) NOT NULL,
        lat     FLOAT,
        lng     FLOAT,
        CONSTRAINT fk_gatherings_organisation_id FOREIGN KEY(organisation_id)
            REFERENCES organisations(organisation_id) ON DELETE CASCADE
    );
COMMENT ON TABLE camps IS 'ATTACHMENTS';
COMMENT ON COLUMN camps.organisation_id IS '##';
COMMENT ON COLUMN camps.camp_title IS '##';
CREATE INDEX camps_organisation_idx ON camps (organisation_id);

-- Enum table with dropdown UI
CREATE TABLE facility_types
    (
        facility_type_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
        facility_group_id     INT,
        facility_type_name    VARCHAR(255) NOT NULL,
        facility_type_details TEXT,
        CONSTRAINT fk_facility_types_organisation_id FOREIGN KEY(organisation_id)
            REFERENCES organisations(organisation_id)
    );
COMMENT ON TABLE facility_types IS 'ENUM DROPDOWN';
COMMENT ON COLUMN facility_types.facility_group_id IS '##';

-- Bookings with multiple FindBy annotations
CREATE TABLE bookings
    (
        booking_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
        camp_id        INTEGER NOT NULL,
        user_id        INTEGER NOT NULL,
        invoice_total  FLOAT NOT NULL,
        invoice_pretax FLOAT NOT NULL,
        invoice_tax    FLOAT NOT NULL,
        tax_rate       FLOAT NOT NULL,
        CONSTRAINT fk_bookings_user_id FOREIGN KEY(user_id)
            REFERENCES users(user_id) ON DELETE CASCADE
    );
COMMENT ON COLUMN bookings.camp_id IS '##';

-- Attendees with multiple ## annotations for different lookups
CREATE TABLE attendees
    (
        attendee_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
        camp_id         INT,
        booking_id      INTEGER NOT NULL,
        family_group_id INTEGER,
        user_id         INT NOT NULL,
        due_arrival TIMESTAMPTZ NOT NULL,
        due_departure TIMESTAMPTZ NOT NULL,
        attendee_age INT,
        gender       VARCHAR(1),
        status       VARCHAR(20),
        CONSTRAINT fk_attendees_user_id FOREIGN KEY(user_id)
            REFERENCES users(user_id) ON DELETE CASCADE,
        CONSTRAINT fk_attendees_booking_id FOREIGN KEY(booking_id)
            REFERENCES bookings(booking_id) ON DELETE CASCADE
    );
COMMENT ON COLUMN attendees.camp_id IS '##';
COMMENT ON COLUMN attendees.user_id IS '##';
COMMENT ON COLUMN attendees.booking_id IS '##';
CREATE INDEX attendees_user_idx ON attendees (user_id);

-- Contacts with email-based lookup and index
CREATE TABLE contacts
    (
        contact_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        phone_number VARCHAR(20),
        alternate_phone VARCHAR(20),
        address TEXT
    );
COMMENT ON COLUMN contacts.last_name IS '##';
COMMENT ON COLUMN contacts.email IS '##';
COMMENT ON COLUMN contacts.phone_number IS '##';
CREATE INDEX contacts_email_idx ON contacts (email);

-- Entity contacts (cross-entity association)
CREATE TABLE entity_contacts
    (
        contact_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
        entity_id INT NOT NULL,
        entity_type VARCHAR(20) NOT NULL
    );
COMMENT ON TABLE entity_contacts IS 'ENTITIES:users, sites, organisations';
```

### Separate UI script: `.wrm/RevCampUI.wrm`

Uses `SET STAGE API` to skip database reading and generate components for an already-built project:

```wrm
CREATE PROJECT RevCamp
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=RevCamp'
    HTTP 5010 HTTPS 5011
    FEATURE USERS
    FEATURE ORGANISATIONS
    FEATURE FILEHANDLING
    FEATURE AUTH;

SET STAGE API;
CREATE COMPONENTS COREUI OVERWRITE;
```

### Azure deployment script: `.wrm/RevCamp.Azure.wrm`

```wrm
CREATE PROJECT RevCamp
    FEATURE SWAGGER
    FEATURE HARD DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=RevCamp'
    FEATURE USER
    FEATURE ORGANISATIONS
    FEATURE FILEHANDLING;

DATABASE RUN '.wrm/RevCamp.sql';

CREATE MODELS;

CREATE AZURE CONTAINER
    REGISTRY "myapp.azurecr.io"
    RESOURCE_GROUP "my-rg"
    BICEP
    GITHUB_ACTIONS;

CREATE AZURE FUNCTIONS
    RUNTIME "dotnet-isolated"
    TRIGGER "http";
```

---

## Example 3: ITMS (IT Management System)

A project using hard delete, multiple SQL scripts, and custom UI templates.

### Build Script: `.wrm/ITMS.wrm`

```wrm
CREATE PROJECT ITMS
    FEATURE SWAGGER
    FEATURE HARD DELETE
    CONNECTION POSTGRES 'Host=localhost:5432;Username=postgres;Password=postgres;Database=ITMS'
    FEATURE USERS
    FEATURE AUTH
    FEATURE ORGS
    FEATURE FILEHANDLING;

DATABASE RUN 'sql/network.sql';
DATABASE RUN 'sql/geometry.sql';
DATABASE RUN 'sql/default-rbac.psql';

CREATE TESTDATA IFEMPTY TESTCASES 10;
CREATE MODELS OVERWRITE;

CREATE API CONTROLLERS OVERWRITE;
CREATE API SERVICE OVERWRITE;
```

**Key patterns:**
- Uses `FEATURE ORGS` (shorthand for ORGANISATIONS)
- Multiple `DATABASE RUN` commands for different SQL scripts
- `OVERWRITE` on both models and API to replace existing files
- Separate `CREATE API CONTROLLERS` and `CREATE API SERVICE` commands

### Separate UI script: `.wrm/ITMS_UX.wrm`

Uses custom user templates from a project-specific directory:

```wrm
CREATE PROJECT ITMS
    FEATURE SWAGGER
    FEATURE HARD DELETE
    CONNECTION POSTGRES 'Host=localhost:5432;Username=postgres;Password=postgres;Database=ITMS';

STAGE API;
CREATE COMPONENTS USER TEMPLATES "ITMSReact/UXTemplates" PATH "ITMSReact" OVERWRITE;
```

**Key patterns:**
- `STAGE API` (without SET) also works
- `USER` component type with custom `TEMPLATES` path
- `PATH` specifies where generated components go

---

## Run and Deploy Lifecycle

A typical end-to-end flow once the `.wrm` script is written:

```bash
# 1. Generate the .NET solution + components from the schema
wrm build

# 2. Run the API service locally (uses the script's HTTPS port)
wrm run
#    → opens https://localhost:<PORT>/swagger

# 3. Deploy as a local Docker stack (API + Postgres)
wrm deploy docker

# Or run only the MCP service (script must have CREATE MCP SERVICE)
wrm run mcp

# Or deploy just the API container behind Cloudflare
wrm deploy docker-cloudflare
```

`wrm run` and `wrm deploy` both pick the default `.wrm` script automatically when there is exactly one in `./.wrm`. To target a specific script, pass its name: `wrm run RevCamp`, `wrm deploy docker RevCamp`.

---

## Common Patterns Summary

| Pattern | Example |
|---------|---------|
| Standard full build | `CREATE MODELS; CREATE API CONTROLLERS SERVICE; CREATE COMPONENTS REACT;` |
| Regenerate everything | Add `OVERWRITE CLEAR` to CREATE API and CREATE COMPONENTS |
| Multiple SQL files | Multiple `DATABASE RUN` commands |
| Skip to component gen | `SET STAGE API; CREATE COMPONENTS COREUI OVERWRITE;` |
| Flat composite model | `CREATE MODEL FLAT <Name> FROM <table> HAVING <subtables>;` |
| Custom frontend templates | `CREATE COMPONENTS USER TEMPLATES "<path>" PATH "<path>";` |
| Full-featured project | `FEATURE AUTH` (pulls in USERS + BASE; add `FEATURE ORGANISATIONS` separately for multi-tenancy) |
