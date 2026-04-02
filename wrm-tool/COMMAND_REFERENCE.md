# WRM Command Reference

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

Execute SQL script files against the connected database. Can be called multiple times for different scripts.

```wrm
DATABASE RUN '<path-to-sql-file>';
```

Examples:
```wrm
DATABASE RUN '.wrm/MyProject.sql';
DATABASE RUN 'sql/network.sql';
DATABASE RUN 'sql/geometry.sql';
DATABASE RUN 'sql/default-rbac.psql';
```

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

Generate API controllers and service project structure.

```wrm
CREATE API [CONTROLLERS] [SERVICE] [OVERWRITE] [CLEAR] [FORMAT] [BUILD] [SWAGGER|NOSWAGGER] [PATH '<path>'];
```

| Option | Description |
|--------|-------------|
| `CONTROLLERS` | Generate controller files for each table |
| `SERVICE` | Generate the API service project (Program.cs, config, Docker, etc.) |
| `OVERWRITE` | Replace existing controller/service files |
| `CLEAR` | Remove old controllers before generating |
| `FORMAT` | Auto-format generated C# code |
| `BUILD` | Build the service project after generation |
| `SWAGGER` | Override global setting: enable Swagger for this API |
| `NOSWAGGER` | Override global setting: disable Swagger for this API |
| `PATH '<path>'` | Override output path for controllers |

Common combinations:
```wrm
CREATE API CONTROLLERS SERVICE OVERWRITE;       -- Generate everything, overwrite existing
CREATE API CONTROLLERS SERVICE OVERWRITE CLEAR; -- Full clean regeneration
CREATE API SERVICE;                              -- Service project only (no per-table controllers)
```

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
CREATE COMPONENTS <REACT|COREUI|VUE|ANGULAR|USER> [TEMPLATES '<path>'] [PATH '<path>'] [OVERWRITE] [CLEAR] [CASE <convention>];
```

| Option | Description |
|--------|-------------|
| `REACT` | Generate React components |
| `COREUI` | Generate CoreUI (Bootstrap admin) components |
| `VUE` | Generate Vue.js components |
| `ANGULAR` | Generate Angular components |
| `USER` | Use custom user-provided templates |
| `TEMPLATES '<path>'` | Path to custom template directory |
| `PATH '<path>'` | Target output path for components |
| `OVERWRITE` | Replace existing component files |
| `CLEAR` | Remove old components before generating |
| `CASE <conv>` | Naming convention: `CAMEL`, `PASCAL`, `KEBAB`, `SNAKE`, `LOWER` |

Examples:
```wrm
CREATE COMPONENTS REACT;
CREATE COMPONENTS COREUI OVERWRITE;
CREATE COMPONENTS USER TEMPLATES "MyReact/UXTemplates" PATH "MyReact" OVERWRITE;
```

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
8. `CREATE COMPONENTS` (after CREATE API or with STAGE)
9. `CREATE AZURE` (after CREATE MODELS)

Or use `STAGE` to skip to a specific point.
