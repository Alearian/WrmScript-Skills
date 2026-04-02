---
name: wrm-tool
author: furniss
keywords: microservice code-generation api service mcp web wrm wormscript build deploy docker azure

description: Operate WormScript (WRM) to create and build projects — .wrm scripts, project initialisation, feature selection, composite models, Docker, Azure, and local deployment. Use when the user wants to create a WRM project, write or edit a .wrm script, run the wrm CLI, generate an API or MCP, build web components, or deploy. Does NOT design SQL schemas — use wrm-data-builder for that.
---

# WormScript Tool Skill (wrm-tool)

This skill covers everything needed to create, configure, build, and deploy a WRM project. It operates the `wrm` CLI and writes `.wrm` build scripts.

**Schema design is handled by a separate skill.** When the user needs a PostgreSQL schema designed or annotated for WRM, defer to `wrm-data-builder` (see [Step 3](#step-3-handle-the-database-schema)).

**Tool**: `wrm` (installed via `dotnet tool install --global Wrm`)

Reference files:
- [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md) — Complete `.wrm` script syntax
- [FEATURES.md](FEATURES.md) — All WRM features, what they create, and their dependencies
- [EXAMPLES.md](EXAMPLES.md) — Real-world `.wrm` build scripts and project patterns

---

## Typical Use Cases

- User wants to create a new WRM project from a database or SQL file and get a running .NET API
- User wants to write or edit a `.wrm` build script
- User wants to regenerate models, API, or components from an existing database
- User wants to add a feature (AUTH, GRAPHQL, MCP, etc.) to an existing project
- User wants to build Docker images or deploy to Azure
- User wants to use `STAGE` to re-run just one part of the build

---

## Workflow

### Step 1: Gather Requirements

Ask the user about:

1. **Project name** — PascalCase, no spaces or underscores (e.g. `MyProject`, `RevCamp`, `ITMS`)
2. **What the application does** — to recommend the right features
3. **Database situation** — see [Step 3](#step-3-handle-the-database-schema)
4. **Features needed** — see [Feature Selection Guide](#feature-selection-guide) and [FEATURES.md](FEATURES.md)
5. **Frontend type** — React or CoreUI?
6. **Database connection** — host, port, database name, credentials
7. **Delete strategy** — soft delete (recommended) or hard delete?
8. **Deployment target** — local, Docker, Azure Container Apps, Azure Functions?

---

### Step 2: Initialise the Project

```bash
wrm init <ProjectName> <react|coreui>
cd <ProjectName>
```

This creates `.wrm/<ProjectName>.wrm` and `.wrm/<ProjectName>.sql` starter files.

---

### Step 3: Handle the Database Schema

Determine which of these three scenarios applies:

#### Scenario A — Database already exists with tables
The user has a running PostgreSQL database that already contains their tables. WRM reads the schema from the live database at build time.

- Do **not** write a `.sql` file
- Do **not** include `DATABASE RUN` in the `.wrm` script
- Ensure the `CONNECTION` string points to the existing database

#### Scenario B — User has existing SQL files
The user has `.sql` or `.psql` files ready to use.

- Do **not** write new SQL files (use theirs)
- Include a `DATABASE RUN` line in the `.wrm` script for each file
- The database must exist first: `createdb -U postgres <ProjectName>`

```wrm
DATABASE RUN '.wrm/<Name>.sql';
DATABASE RUN 'sql/additional-tables.sql';
```

#### Scenario C — Schema needs to be designed from scratch
The user describes what they need but has no SQL yet.

**Defer to `wrm-data-builder`.** Tell the user:

> "To design a WRM-compatible schema I'll use the `wrm-data-builder` skill — it produces correctly annotated SQL with the right column conventions, ENUM/PAGED classifications, and FindBy comments. Once that's done I'll write the `.wrm` build script around it."

Then invoke `/wrm-data-builder` (or ask the user to do so). Once the SQL is produced, return here to complete Steps 4–6.

---

### Step 4: Write the `.wrm` Build Script

See [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md) for full syntax.

**With DATABASE RUN** (Scenarios B and C):
```wrm
CREATE PROJECT <Name>
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=<Name>'
    HTTP <port> HTTPS <port+1>
    FEATURE <feature1>
    FEATURE <feature2>;

DATABASE RUN '.wrm/<Name>.sql';

CREATE TESTDATA IFEMPTY TESTCASES 10;
CREATE MODELS;
CREATE API CONTROLLERS SERVICE OVERWRITE;
CREATE COMPONENTS REACT;
```

**Database already exists** (Scenario A — no DATABASE RUN):
```wrm
CREATE PROJECT <Name>
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=<Name>'
    HTTP <port> HTTPS <port+1>
    FEATURE <feature1>
    FEATURE <feature2>;

CREATE MODELS;
CREATE API CONTROLLERS SERVICE OVERWRITE;
CREATE COMPONENTS REACT;
```

---

### Step 5: Run the Build

**Scenario A** (database exists):
```bash
wrm build
```

**Scenarios B and C** (SQL needs executing):
```bash
createdb -U postgres <ProjectName>   # create the empty database first
wrm build                             # DATABASE RUN inside the script populates it
```

---

### Step 6: Report Results

After build completes tell the user:
- What was generated (models, controllers, components)
- How to run the API: `cd <ProjectName>Service && dotnet run`
- Swagger URL: `https://localhost:<HTTPS_PORT>/swagger`
- Any next steps (run database migrations, configure secrets, etc.)

---

## Feature Selection Guide

See [FEATURES.md](FEATURES.md) for full details on what each feature creates.

| User Need | Feature |
|---|---|
| Audit timestamps (created_at, updated_at, is_deleted) | `BASE` |
| Multiple organisations / tenants | `ORGANISATIONS` (auto-includes BASE) |
| User accounts, profiles, groups | `USERS` (auto-includes BASE) |
| Login, JWT auth, roles, permissions | `AUTH` (auto-includes BASE, ORGANISATIONS, USERS) |
| File uploads, document attachments | `FILEHANDLING` (auto-includes BASE, ORGANISATIONS, USERS) |
| Key-value metadata on entities | `ENTITYCONFIG` (auto-includes BASE) |
| GraphQL API layer | `GRAPHQL` |
| AI / Model Context Protocol integration | `MCP` |
| RPC-JSON command execution | `RPC` |

**Dependency graph:**
```
AUTH ──────► USERS ──────► BASE
         ├─► ORGANISATIONS ─► BASE
FILEHANDLING ─► ORGANISATIONS ─► BASE
            ├─► USERS ──────► BASE
ENTITYCONFIG ─► BASE
```

**Quick rules:**
- "login", "authentication", "roles", "permissions" → `FEATURE AUTH`
- "organisations", "tenants", "multi-tenant" → `FEATURE ORGANISATIONS`
- "users", "accounts", "profiles" → `FEATURE USERS`
- "file upload", "attachments", "documents" → `FEATURE FILEHANDLING`
- "GraphQL" → `FEATURE GRAPHQL`
- "AI tools", "MCP", "Model Context Protocol" → `FEATURE MCP`
- Most real-world apps need at least `FEATURE AUTH`

---

## Delete Strategy

| Strategy | When | Command |
|---|---|---|
| **Soft Delete** | Most apps — records marked `is_deleted = true`, supports audit/undo | `FEATURE SOFT DELETE` |
| **Hard Delete** | Simple apps, test projects, GDPR permanent removal | `FEATURE HARD DELETE` |

---

## Composite Models

| Type | When to Use | Syntax |
|---|---|---|
| **Standard** | Single table, normal CRUD | Auto-created by `CREATE MODELS` |
| **Flat** | Read-only denormalised join across tables | `CREATE MODEL FLAT <Name> FROM <table> WITH\|HAVING <subtables>` |
| **Tree** | Hierarchical parent-child with nested objects | `CREATE MODEL TREE <Name> FROM <table> WITH\|HAVING <subtables>` |

- `WITH` — child refers to parent (child table has parent's FK)
- `HAVING` / `HAS` — parent expands to children (parent's PK is in the child table)
- `ALL` — automatically include every related table

Must appear **after** `CREATE MODELS` in the script.

---

## Frontend Type

| Type | When to Use |
|---|---|
| `react` | Modern React components |
| `coreui` | Bootstrap-based admin dashboard (CoreUI) |

Custom templates: `CREATE COMPONENTS USER TEMPLATES "<path>" PATH "<path>"`

---

## Deployment

### Docker (local)
`CREATE API SERVICE` generates `docker-compose.yml` and `Dockerfile` in the project root. Run with:
```bash
docker compose up
```

### Azure Container Apps
```wrm
CREATE AZURE CONTAINER
    REGISTRY "<registry>.azurecr.io"
    RESOURCE_GROUP "<rg>"
    LOCATION "uksouth"
    BICEP
    GITHUB_ACTIONS;
```

### Azure Functions (serverless)
```wrm
CREATE AZURE FUNCTIONS
    RUNTIME "dotnet-isolated"
    TRIGGER "http"
    RESOURCE_GROUP "<rg>"
    LOCATION "uksouth";
```

See [COMMAND_REFERENCE.md — CREATE AZURE](COMMAND_REFERENCE.md#create-azure) for all options.

---

## Re-running Part of a Build (STAGE)

Use `STAGE` to skip directly to a build phase on an already-partially-built project:

```wrm
-- Regenerate only the web components against an existing API
CREATE PROJECT RevCamp
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=RevCamp'
    HTTP 5010 HTTPS 5011
    FEATURE AUTH;

SET STAGE API;
CREATE COMPONENTS COREUI OVERWRITE;
```

| Stage | Skips to |
|---|---|
| `READY` | Start |
| `DATA` | After database |
| `PROJECT` | After project config |
| `MODELS` | After models created |
| `API` | After API created |

---

## Common `.wrm` Patterns

| Goal | Pattern |
|---|---|
| Full build from scratch | `CREATE MODELS; CREATE API CONTROLLERS SERVICE; CREATE COMPONENTS REACT;` |
| Regenerate everything cleanly | Add `OVERWRITE CLEAR` to CREATE API and CREATE COMPONENTS |
| Multiple SQL scripts | Multiple `DATABASE RUN` commands (one per file) |
| Skip to component generation | `SET STAGE API; CREATE COMPONENTS COREUI OVERWRITE;` |
| Add a flat/tree model | `CREATE MODEL FLAT <Name> FROM <table> HAVING <subtables>;` after `CREATE MODELS` |
| Custom frontend templates | `CREATE COMPONENTS USER TEMPLATES "<path>" PATH "<path>"` |

---

## Questions to Ask

### Always ask
- What is the project name? (PascalCase, no spaces)
- Do you have an existing database, SQL files, or do you need the schema designed? (determines Scenario A/B/C)

### Ask if not clear
- Do you need user authentication and roles? → AUTH
- Will this be multi-tenant? → ORGANISATIONS
- Do you need file upload/attachment support? → FILEHANDLING
- Soft delete or hard delete?
- React or CoreUI frontend?
- Database connection details (host, port, database name, credentials)?

### Ask for advanced use cases
- Flat or tree composite models needed?
- Deploying to Docker, Azure Container Apps, or Azure Functions?
- Custom frontend templates?
- Re-running only part of the build (STAGE)?
