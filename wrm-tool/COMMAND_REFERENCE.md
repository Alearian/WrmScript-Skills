# WRM Command Reference

This file documents both the `wrm` CLI subcommands and the `.wrm` script syntax executed by `wrm build`.

**This is the user-facing syntax reference.** For implementation details (how each command is parsed, dispatched, and which writer handles it), see [`wrm-development/COMMANDS.md`](../../wrm-development/COMMANDS.md).

---

## CLI Commands

The `wrm` CLI is invoked from a project root containing a `.wrm/` folder. When a command takes an optional `<script>`, it follows the same selection rule as `wrm build`: if no name is given, the single `.wrm` file in `./.wrm` (or `../.wrm`, `../../.wrm`) is used; otherwise the named script is required.

| Command | Description |
|---|---|
| `wrm init [<ProjectName>] [react\|coreui]` | Scaffolds `.wrm/<ProjectName>.wrm` and `.wrm/<ProjectName>.sql` starter files. `<ProjectName>` is optional — if omitted, the current folder name is used |
| `wrm build [<script>]` | Executes the build script — reads schema, generates models/controllers/components |
| `wrm run [<script>]` | Runs the generated API service via `dotnet run` |
| `wrm run api [<script>]` | Same as `wrm run` (explicit API target) |
| `wrm run mcp [<script>]` | Runs the generated MCP service via `dotnet run` |
| `wrm deploy [<target>]` | Runs `make-devcert.ps1` then `publish-<target>.ps1`. Default target is `docker` |
| `wrm test connection [<script>]` | Tests the database connection defined by the script |
| `wrm list <mode>` | Lists `entities\|models\|ports\|templates\|tables\|features\|scripts` |
| `wrm database` | Shows database connection info from the selected script |
| `wrm help [<topic>]` | Shows usage help (`init`, `build`, `run`, `deploy`, `test`, `list`) |

### `wrm run` rules

The selected script must contain **at most one** of each of these phrases:

- `CREATE API SERVICE`
- `CREATE API CONTROLLERS`
- `CREATE MCP SERVICE`
- `CREATE MCP CONTROLLERS`

Plus, depending on the target:

- `wrm run` / `wrm run api` → exactly one `CREATE API SERVICE`
- `wrm run mcp` → exactly one `CREATE MCP SERVICE`

`CREATE API CONTROLLERS` alongside `CREATE API SERVICE` is fine. Two `CREATE API SERVICE` lines is not.

### `wrm deploy` targets

`wrm deploy <target>` runs the API project's `make-devcert.ps1` (in `<ProjectName>Api/Development/`), then invokes `publish-<target>.ps1` from the **solution-root** `Development/` folder. Default target is `docker`. The publish scripts and Docker assets live at the solution root (`<Solution>/Development/` and `<Solution>/Development/Docker/`):

| Target | Script | Purpose |
|---|---|---|
| `docker` | `publish-docker.ps1` | Full local Docker stack (API + Postgres) |
| `docker-api` | `publish-docker-api.ps1` | API container only (no DB) |
| `docker-mcp` | `publish-docker-mcp.ps1` | MCP service container |
| `docker-cloudflare` | `publish-docker-cloudflare.ps1` | API + Cloudflare tunnel |
| `docker-prod` | `publish-docker-prod.ps1` | Production Docker config |
| `dotnet` | `publish-dotnet.ps1` | Plain `dotnet publish` self-contained build |

Any custom `publish-<name>.ps1` that you drop into the solution-root `Development/` folder is also dispatchable via `wrm deploy <name>`.

---

## .wrm Script Syntax

Complete syntax for all `.wrm` script commands. Commands are case-insensitive. Semicolons terminate command blocks. Comments use `--` or `//` (including inline).

---

## CREATE PROJECT

**Must be the first command in every .wrm script.** Defines project configuration.

```wrm
CREATE PROJECT <ProjectName>
    CONNECTION <POSTGRES|MYSQL|MSSQL|MARIADB|COSMOSDB> '<connection-string>'
    FEATURE SWAGGER
    FEATURE <SOFT|HARD> DELETE
    HTTP <port> HTTPS <port>
    APPID '<app-id>'
    VERSION '<version>'
    FEATURE <feature-name>
    FEATURE <feature-name>
    PATH '<project-path>';
```

| Option | Required | Description |
|--------|----------|-------------|
| `FEATURE SWAGGER` | No | Explicitly enable Swagger/OpenAPI documentation (enabled by default) |
| `FEATURE NOSWAGGER` | No | Disable Swagger documentation |
| `FEATURE SOFT DELETE` | Yes (one) | Mark records as deleted (is_deleted column) |
| `FEATURE HARD DELETE` | Yes (one) | Permanently delete records |
| `CONNECTION` | Yes | Database connection string (see [Connection Strings](#connection-strings)) |
| `HTTP <port>` | No | HTTP port for the API service |
| `HTTPS <port>` | No | HTTPS port for the API service |
| `APPID '<id>'` | No | Application identifier |
| `VERSION '<ver>'` | No | Application version string |
| `FEATURE <name>` | No | Enable a feature (repeatable, see [FEATURES.md](FEATURES.md)) |
| `PATH '<path>'` | No | Override default project output path |

### Connection Strings

```wrm
-- PostgreSQL (recommended)
CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=MyProject'

-- MySQL
CONNECTION MYSQL 'Server=localhost;Database=mydb;User=user;Password=pass'

-- SQL Server
CONNECTION MSSQL 'Server=localhost;Database=mydb;User Id=user;Password=pass'

-- MariaDB
CONNECTION MARIADB 'Server=localhost;Database=mydb;User=user;Password=pass'

-- Cosmos DB
CONNECTION COSMOSDB '<cosmos-connection-string>'
```

Note: Port can also be specified as part of Host: `Host=localhost:5432`

---

## DATABASE RUN

Execute SQL script files against the connected database during the schema creation phase. Can be called multiple times for different scripts.

**When to use:** Use `DATABASE RUN` for scripts that create or modify table schemas, add constraints, or set up database structure that must exist before code generation.

**Execution timing:** DATABASE RUN scripts execute during the `CREATE MODELS` stage, after feature schemas are created but before code generation.

```wrm
DATABASE RUN '<path-to-sql-file>';
```

**Options:**
| Option | Description |
|--------|-------------|
| `'<path-to-sql-file>'` | Relative or absolute path to SQL script. Can be called multiple times. |

**Examples:**
```wrm
DATABASE RUN '.wrm/MyProject.sql';
DATABASE RUN 'sql/network.sql';
DATABASE RUN 'sql/geometry.sql';
DATABASE RUN 'sql/custom-functions.psql';
```

---

## DATABASE SEED

Execute SQL script files to populate the database with reference data or seed records. Runs AFTER all schema creation and code generation is complete. Can be called multiple times for different seed scripts.

**When to use:** Use `DATABASE SEED` for scripts that populate lookup tables (ENUMs), insert default records, or load initial data after the schema is fully established. This prevents conflicts with feature-generated seed data.

**Execution timing:** DATABASE SEED scripts execute at the very end of the build process, after all tables, features, and user schemas are created. This ensures they don't conflict with feature-generated seed data.

**Common use cases:**
- Seeding ENUM lookup tables with reference data
- Populating organisation hierarchies
- Loading default roles and permissions
- Inserting initial user data
- Setting up configuration records

```wrm
DATABASE SEED '<path-to-sql-file>';
```

**Options:**
| Option | Description |
|--------|-------------|
| `'<path-to-sql-file>'` | Relative or absolute path to SQL seed script. Can be called multiple times. |

**Examples:**
```wrm
-- Seed reference data after schema is complete
DATABASE SEED '.wrm/seed-enums.sql';
DATABASE SEED 'sql/seed-default-roles.sql';
DATABASE SEED 'sql/seed-organisations.sql';
DATABASE SEED 'sql/seed-permissions.sql';
```

**Important:** Seeds run AFTER all code generation and feature creation, avoiding conflicts with WRM-generated seed data (e.g., from the `AUTH` or `ORGANISATIONS` features).

---

## CREATE MODELS

Generate C# DbModel, DTO, Mapper, and Repository files for all database tables.

```wrm
CREATE MODELS [OVERWRITE] [CLEAR] [FORMAT] [PATH '<path>'];
```

| Option | Description |
|--------|-------------|
| `OVERWRITE` | Replace existing model/repository files |
| `CLEAR` | Remove old models and repositories before generating |
| `FORMAT` | Auto-format generated C# code |
| `PATH '<path>'` | Override output path for repositories |

---

## CREATE MODEL FLAT / TREE

Generate composite read-only models that join data from multiple tables.

```wrm
CREATE MODEL <FLAT|TREE> <ModelName> FROM <TableName> <WITH|HAVING|HAS> <SubTable1>, <SubTable2>, ...;
CREATE MODEL <FLAT|TREE> <ModelName> FROM <TableName> <WITH|HAVING|HAS> ALL;
```

| Keyword | Meaning |
|---------|---------|
| `FLAT` | Denormalised single-row model joining columns from related tables |
| `TREE` | Hierarchical model with nested sub-objects (uses Dapper multi-mapping) |
| `FROM` | The primary/source table |
| `WITH` | Child refers to parent: subtable's FK points to the primary table's PK. Only matching records included. |
| `HAVING` / `HAS` | Parent expands to children: primary table's PK appears in the subtable. All parent records included (LEFT JOIN). |
| `ALL` | Automatically include every table that references the primary key |

Examples:
```wrm
-- Flat: join camp data with its bookings (camp_id in bookings table)
CREATE MODEL FLAT Registrations FROM camps HAVING bookings;

-- Flat: join user with their organisation (organisation_id in users table)
CREATE MODEL FLAT UserDetail FROM users WITH organisations;

-- Tree: star system with nested stars and planets
CREATE MODEL TREE StarSystemTree FROM star_systems HAVING stars, planets;

-- Flat: include all related tables automatically
CREATE MODEL FLAT StarSystemFull FROM star_systems HAVING ALL;
```

**Must appear after `CREATE MODELS`** since table metadata must be loaded first.

---

## CREATE API

Generate API controllers and service project structure. **At least one of `SERVICE` or `CONTROLLERS` must be specified** — `CREATE API;` alone is a parse error. Both may appear in the same command.

```wrm
CREATE API <SERVICE|CONTROLLERS|SERVICE CONTROLLERS> [OVERWRITE] [CLEAR] [FORMAT] [BUILD] [SWAGGER|NOSWAGGER] [PATH '<path>'];
```

| Option | Description |
|--------|-------------|
| `CONTROLLERS` | Generate per-entity REST controller and controller-service files |
| `SERVICE` | Scaffold the full API service project (Program.cs, appsettings.json, Docker, middleware, etc.) |
| `OVERWRITE` | Overwrite existing files without deleting anything first |
| `CLEAR` | **Behaviour depends on mode — see warning below** |
| `FORMAT` | Auto-format generated C# code |
| `BUILD` | Build the service project after generation |
| `SWAGGER` | Override global setting: enable Swagger for this API |
| `NOSWAGGER` | Override global setting: disable Swagger for this API |
| `PATH '<path>'` | Override output path for controllers |

**`CLEAR` behaviour by mode:**

| Mode | What `CLEAR` deletes |
|------|----------------------|
| `CONTROLLERS CLEAR` | Only the `Controllers\` and `Services\` subfolders inside the API project. All other project files are left untouched. |
| `SERVICE CLEAR` | ⚠️ **The entire `{ProjectName}Api\` folder** — including any `.git` repository, all custom code, Docker config, middleware, and every file you have ever written or edited in that folder. |
| `SERVICE CONTROLLERS CLEAR` | Same as `SERVICE CLEAR` — the whole folder is deleted before scaffolding, then controllers are generated fresh. |

> ⚠️ **`CREATE API SERVICE CLEAR` is destructive and permanent.** It wipes the entire API project directory with no confirmation prompt — including any `.git` repository inside it, all code you have written or customised, all configuration, Docker files, and middleware. Back up or commit everything to a remote repository before using it. If you only want to remove stale generated controllers, use `CREATE API CONTROLLERS CLEAR` instead.

Common combinations:
```wrm
CREATE API SERVICE CONTROLLERS;           -- Scaffold project + generate controllers (preserve existing)
CREATE API SERVICE CONTROLLERS OVERWRITE; -- Scaffold + generate; overwrite all existing files
CREATE API SERVICE;                        -- Scaffold the project only (no per-entity controllers)
CREATE API CONTROLLERS;                    -- Generate controllers only (project already exists)
CREATE API CONTROLLERS CLEAR;             -- Remove stale controllers, then regenerate
CREATE API SERVICE CLEAR;                 -- ⚠️ Delete entire project folder, then scaffold fresh
```

---

## CREATE MCP

Generate a Model Context Protocol (MCP) server project alongside the main API.

```wrm
CREATE MCP [CONTROLLERS] [SERVICE] [STDIO] [HTTP=<port>] [HTTPS=<port>] [OVERWRITE] [CLEAR] [FORMAT] [BUILD] [TABLES (<table1>, <table2>, ...)] [PATH '<path>'];
```

| Option | Description |
|--------|-------------|
| `CONTROLLERS` | Generate MCP controller files for each table (or the filtered TABLES list) |
| `SERVICE` | Generate the MCP service project (Program.cs, config, Docker, etc.) |
| `STDIO` | Use stdio JSON-RPC transport instead of HTTP/SSE. No certificate is required; no ports are allocated. Use for desktop AI clients (Claude Desktop, VS Code Copilot) that launch the MCP server as a subprocess. |
| `HTTP=<port>` | HTTP port for the MCP project. Default `5010`. Must differ from the API HTTP port. |
| `HTTPS=<port>` | HTTPS port for the MCP project. Default `5011`. Must differ from the API HTTPS port. |
| `OVERWRITE` | Replace existing MCP files |
| `CLEAR` | Remove old MCP files before generating |
| `FORMAT` | Auto-format generated C# code |
| `BUILD` | Build the MCP service project after generation |
| `TABLES (<list>)` | Restrict controller generation to the named tables only |
| `PATH '<path>'` | Override output path for controllers |

> **Port conflict guard:** When `SERVICE` is specified without `STDIO`, WRM raises a hard error if the MCP HTTP/HTTPS ports clash with the main API ports. Use `HTTP=` and `HTTPS=` to resolve conflicts explicitly.

Common combinations:
```wrm
-- HTTP/SSE transport (remote clients, Azure Container Apps)
CREATE MCP SERVICE CONTROLLERS OVERWRITE;

-- stdio transport (Claude Desktop, local AI tools)
CREATE MCP SERVICE CONTROLLERS STDIO OVERWRITE;

-- Custom ports to avoid clash with API on 5000/5001
CREATE MCP SERVICE CONTROLLERS HTTP=5010 HTTPS=5011 OVERWRITE;

-- Generate MCP controllers for a subset of tables only
CREATE MCP CONTROLLERS TABLES (products, orders, customers);
```

`CREATE MCP` must appear **after** `CREATE API` in the script.

---

## CREATE RPC

Generate a JSON-RPC 2.0 service project alongside the main API. Each entity gets a single `POST /rpc/{entity}` endpoint that dispatches to standard methods (`GetById`, `GetAll`, `Insert`, `Update`, `Delete`) plus any `FindBy*` methods defined via `##` column annotations.

**At least one of `SERVICE` or `CONTROLLERS` must be specified** — `CREATE RPC;` alone is a parse error. Both may appear in the same command.

```wrm
CREATE RPC <SERVICE|CONTROLLERS|SERVICE CONTROLLERS> [OVERWRITE] [CLEAR] [FORMAT] [BUILD]
           [HTTP=<port>] [HTTPS=<port>] [TABLES (<table1>, <table2>, ...)] [PATH '<path>'];
```

| Option | Description |
|--------|-------------|
| `SERVICE` | Scaffold the full RPC service project (`Program.cs`, appsettings, csproj, base classes, JSON-RPC models) |
| `CONTROLLERS` | Generate per-entity JSON-RPC 2.0 dispatcher controllers |
| `OVERWRITE` | Overwrite existing files without deleting anything first |
| `CLEAR` | Remove old files before generating. For `SERVICE`: deletes the entire `{ProjectName}Rpc\` folder. For `CONTROLLERS` only: clears the `Controllers\` subfolder. |
| `FORMAT` | Auto-format generated C# code |
| `BUILD` | Build the RPC project after generation |
| `HTTP=<port>` | HTTP port for the RPC project. Default `5020`. Must differ from the API HTTP port. |
| `HTTPS=<port>` | HTTPS port for the RPC project. Default `5021`. Must differ from the API HTTPS port. |
| `TABLES (<list>)` | Restrict controller generation to the named tables only |
| `PATH '<path>'` | Override output path for the RPC project |

> **Port conflict guard:** WRM raises a hard error if the RPC HTTP/HTTPS ports clash with the main API ports. Use `HTTP=` and `HTTPS=` to set different ports.

**Generated project structure:**

```
ProjectNameRpc/
  Controllers/
    RpcBaseController.cs          ← base class (helper methods: JsonRpcResult, JsonRpcError, etc.)
    {Entity}RpcController.cs      ← per-entity dispatcher (one per non-hidden, non-composite table)
  Models/
    JsonRpcRequest.cs             ← request envelope + TryGetParam<T> / GetDto<T> helpers
    JsonRpcResponse.cs            ← response envelope
    JsonRpcError.cs               ← error record + JSON-RPC 2.0 error codes
  Services/
    ServiceRegistrations.cs       ← DI registrations for repos / services
  Program.cs
  appsettings.json
  {ProjectName}Rpc.csproj         ← references {ProjectName}Data.csproj
```

**JSON-RPC 2.0 protocol:**

```
POST /rpc/{entity}
Content-Type: application/json

{ "jsonrpc": "2.0", "method": "GetById", "params": { "{entity_id}": 1 }, "id": 1 }
```

**Methods auto-generated per entity:**

| Method | Description |
|--------|-------------|
| `GetById` | Fetch a single record by primary key |
| `GetAll` | Fetch all records (org-scoped if `ORGANISATIONS` feature active) |
| `Insert` | Create a new record from `params` DTO |
| `Update` | Update an existing record from `params` DTO |
| `Delete` | Soft-delete (`is_deleted = true`) or hard-delete depending on the feature |
| `FindBy{Column}` | One method per `##` column annotation |

Read-only (`READONLY` annotation) and composite tables are skipped.

Common combinations:
```wrm
-- Scaffold RPC project + generate all entity controllers
CREATE RPC SERVICE CONTROLLERS;

-- Regenerate controllers only (project already scaffolded)
CREATE RPC CONTROLLERS CLEAR;

-- Custom ports to avoid clash with API (5010/5011) and MCP (5020/5021)
CREATE RPC SERVICE HTTP=5030 HTTPS=5031 CLEAR;
CREATE RPC CONTROLLERS CLEAR;

-- Generate controllers for a subset of tables only
CREATE RPC CONTROLLERS TABLES (products, orders);
```

`CREATE RPC` must appear **after** `CREATE MODELS` in the script.

---

## CREATE LOOKUP

Generate additional finder methods (repository + API endpoint) for specific columns.

```wrm
CREATE LOOKUP ["<custom-name>"] ON '<table_name>' BY '<field1>[&field2&field3]';
```

| Part | Required | Description |
|------|----------|-------------|
| `"<custom-name>"` | No | Custom method name. If omitted, auto-generates `FindBy<Field1>[And<Field2>...]` |
| `ON '<table>'` | Yes | Database table name (snake_case) |
| `BY '<fields>'` | Yes | Column name(s), joined with `&` for compound lookups |

Examples:
```wrm
-- Single field lookup
CREATE LOOKUP ON 'attachments' BY 'attachment_type';

-- Multi-field compound lookup
CREATE LOOKUP ON 'entity_attachments' BY 'entity_id&entity_type&organisation_id';

-- Custom-named lookup
CREATE LOOKUP "FindActiveByOrg" ON 'entity_attachments' BY 'availability_policy_id&organisation_id';
```

**Must appear after `CREATE MODELS`.**

---

## CREATE TESTDATA

Generate test/seed data for all tables.

```wrm
CREATE TESTDATA [IFEMPTY] TESTCASES <number>;
```

| Option | Description |
|--------|-------------|
| `IFEMPTY` | Only insert test data if tables are empty |
| `TESTCASES <n>` | Number of test rows to generate per table |

Examples:
```wrm
CREATE TESTDATA TESTCASES 10;           -- Always insert 10 rows per table
CREATE TESTDATA IFEMPTY TESTCASES 10;   -- Only if tables are empty
```

---

## CREATE COMPONENTS

Generate frontend web components for all tables.

```wrm
CREATE COMPONENTS <REACT|COREUI|VUE|ANGULAR|USER|TAILCOMPLETE> [VERSION '<ver>'] [TEMPLATES '<path>'] [PATH '<path>'] [OVERWRITE] [CLEAR] [CASE <convention>];
```

| Option | Description |
|--------|-------------|
| `REACT` | Generate React components |
| `COREUI` | Generate CoreUI (Bootstrap admin) components |
| `VUE` | Generate Vue.js components |
| `ANGULAR` | Generate Angular components |
| `USER` | Use custom user-provided templates |
| `TAILCOMPLETE` | Generate the **TailComplete** feature-complete React/Tailwind admin site from the external NPM package `@furniss/wrm-tailcomplete` (see below) |
| `VERSION '<ver>'` | Pin the NPM template package version (TailComplete). Omit for `latest` |
| `TEMPLATES '<path>'` | Path to custom template directory. For `TAILCOMPLETE`, use a **local checkout** of the package instead of downloading from npm |
| `PATH '<path>'` | Target output path for components |
| `OVERWRITE` | Replace existing component files |
| `CLEAR` | Remove old components before generating |
| `CASE <conv>` | Naming convention: `CAMEL`, `PASCAL`, `KEBAB`, `SNAKE`, `LOWER` |

Examples:
```wrm
CREATE COMPONENTS REACT;
CREATE COMPONENTS COREUI OVERWRITE;
CREATE COMPONENTS USER TEMPLATES "MyReact/UXTemplates" PATH "MyReact" OVERWRITE;
CREATE COMPONENTS TAILCOMPLETE PATH "MyAppWeb";                     -- downloads @furniss/wrm-tailcomplete@latest
CREATE COMPONENTS TAILCOMPLETE VERSION '1.2.0' PATH "MyAppWeb";     -- pins a version
CREATE COMPONENTS TAILCOMPLETE TEMPLATES "C:/src/WebTemplates/TailComplete" PATH "MyAppWeb";  -- local checkout, no npm
```

### TailComplete web templates

`TAILCOMPLETE` generates a complete, polished admin website whose surface is driven by the
**FEATUREs** enabled on your `CREATE PROJECT` — not by your schema. WRM strips the areas you
haven't enabled:

- No `AUTH` → the app opens straight to the dashboard (no sign-in).
- No `ORGANISATIONS` → no org switcher/overview, no organisation header.
- `USERS` → People admin; `FILEHANDLING` → Files; `MESSAGING` → notifications;
  `INTEGRATIONS` → integrations; `LINKEDIN` → Sign-in-with-LinkedIn; `CHATBOT` → AI chat widget.

WRM resolves the template in this order: a local checkout given via `TEMPLATES '<path>'`, then a
local cache, then a download of `@furniss/wrm-tailcomplete` (`npm pack`) into
`%LOCALAPPDATA%\wrm\web-templates\`. The raw package also runs standalone (`npm install && npm
run build`) as the "all features on" app — the `//WRM_IF` markers are ordinary TS comments.

---

## CREATE AZURE

Generate Azure deployment artifacts. Two deployment targets available.

### Azure Container Apps

```wrm
CREATE AZURE CONTAINER
    REGISTRY "<registry-url>"
    RESOURCE_GROUP "<resource-group>"
    LOCATION "<azure-region>"
    SUBSCRIPTION "<subscription-id>"
    [BICEP | NO_BICEP]
    [GITHUB_ACTIONS | NO_GITHUB_ACTIONS]
    [APPINSIGHTS | NO_APPINSIGHTS]
    [KEYVAULT | NO_KEYVAULT]
    [MANAGED_IDENTITY | NO_MANAGED_IDENTITY];
```

### Azure Functions

```wrm
CREATE AZURE FUNCTIONS
    RUNTIME "<runtime>"
    TRIGGER "<trigger-type>"
    RESOURCE_GROUP "<resource-group>"
    LOCATION "<azure-region>"
    SUBSCRIPTION "<subscription-id>"
    [BICEP | NO_BICEP]
    [GITHUB_ACTIONS | NO_GITHUB_ACTIONS]
    [APPINSIGHTS | NO_APPINSIGHTS]
    [KEYVAULT | NO_KEYVAULT]
    [MANAGED_IDENTITY | NO_MANAGED_IDENTITY];
```

| Option | Default | Description |
|--------|---------|-------------|
| `REGISTRY` | Required (Container) | Azure Container Registry URL |
| `RUNTIME` | `dotnet-isolated` | Functions runtime |
| `TRIGGER` | `http` | Functions trigger type |
| `RESOURCE_GROUP` | Required | Azure Resource Group name |
| `LOCATION` | `uksouth` | Azure region |
| `SUBSCRIPTION` | Optional | Azure Subscription ID |
| `BICEP` | On | Generate Bicep IaC templates |
| `GITHUB_ACTIONS` | On | Generate CI/CD workflow |
| `APPINSIGHTS` | On | Enable Application Insights |
| `KEYVAULT` | On | Enable Key Vault for secrets |
| `MANAGED_IDENTITY` | On | Enable managed identity auth |

---

## STAGE

Jump to a specific build stage without re-running earlier stages. Useful for running component generation against a previously built project.

```wrm
STAGE <stage-name>;
```

| Stage | Description |
|-------|-------------|
| `READY` | Initial state |
| `DATA` | After database setup |
| `PROJECT` | After project configuration |
| `MODELS` | After models created |
| `API` | After API created |

Also accepted as `SET STAGE <name>`.

Example - generate CoreUI components for an already-built API project:
```wrm
CREATE PROJECT RevCamp
    CONNECTION POSTGRES 'Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=RevCamp'
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    HTTP 5010 HTTPS 5011
    FEATURE USERS
    FEATURE ORGANISATIONS
    FEATURE FILEHANDLING
    FEATURE AUTH;

SET STAGE API;
CREATE COMPONENTS COREUI OVERWRITE;
```

---

## Script Ordering Rules

Commands must appear in this order:

1. `CREATE PROJECT` (always first)
2. `DATABASE RUN` (before CREATE MODELS)
3. `CREATE TESTDATA` (after DATABASE RUN, before or after MODELS)
4. `CREATE MODELS` (before API, LOOKUP, COMPONENTS, or FLAT/TREE models)
5. `CREATE MODEL FLAT/TREE` (after CREATE MODELS)
6. `CREATE LOOKUP` (after CREATE MODELS)
7. `CREATE API` (after CREATE MODELS)
8. `CREATE MCP` (after CREATE MODELS, typically after CREATE API)
9. `CREATE RPC` (after CREATE MODELS, typically after CREATE API)
10. `CREATE COMPONENTS` (after CREATE API or with STAGE)
11. `CREATE AZURE` (after CREATE MODELS)

Or use `STAGE` to skip to a specific point.
