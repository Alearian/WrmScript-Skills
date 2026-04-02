This skill allows your AI agent or tool to use WRM to build your RESTful Api, GraphQL, MCP or Web Components from your data schema.

# WormScript (WRM)

WRM Builds a 'ready-to-start' full-stack application based on your database schema. Just write your SQL tables, run a simple command, and get a complete .NET solution with RESTful APIs and React components generated for you. 

WormScript is designed for rapid prototyping and development, allowing you to focus on your unique business logic instead of boilerplate code.
With a simple command-line WRM generates clean, maintainable c# code for your API and web UI in minutes.

Out of the box :
- A ready-to-use multi-platform .NET solution based on YOUR DATABASE SCHEMA
- A Data Project with Dapper repositories and models generated from your database schema. 
- Add comments to your SQL tables and columns to control features such read-only tables, paged endpoints, and automatic finder methods.
- An API Service Project with RESTful controllers for each table, including CRUD operations
- Ready to-use swagger documentation generated from XML doc comments on the API controllers and models.
- A variety of of ready-to-use Docker builds using PostgreSQL and useful powershell scripts for deployments
- Optional features like soft deletes, multi-tenancy, GraphQL support, and more that can be enabled with simple configuration.
- JWT-based authentication and authorization system with role-based access control and organization scoping - simply use the "FEATURE AUTH" script command
- Example React components generated for each table, including forms, tables, cards, and dropdowns. Already wired up to the API.


### _**Let me know what to work on next !!**__
<br/>

---
## Basic Usage

1. Initialize a new project with `wrm init MyProject React`.
2. Edit the generated `.wrm/MyProject.wrm` with your connection string.
3. Run `wrm build`.
4. Sit back and watch your application-starter being generated!

## Table of Contents

- [Supported Technologies](#supported-technologies)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Commands](#commands)
  - [WRM Script Syntax](#wrm-script-syntax)
  - [Features System](#features-system)
- [Project Structure](#project-structure)
- [Generated Output](#generated-output)
- [Configuration](#configuration)
- [Database Support](#database-support)
- [Examples](#examples)
- [Contributing](#contributing)

**Additional Documentation:**
- [Architecture](Docs/Architecture.md) - public architecture and build process
- [Template System](Docs/TemplateSystem.md) - Template markers and available templates
- [Features](Docs/Features.md) - Feature system details

---

### Future Features

- SQL Server Support
- Azure Cosmos DB Support
- Vue.js Frontend Support
- Angular Frontend Support
- Enhanced Test Data Generation*
---

## Supported Technologies

### Backend
- **.NET 9.0** - Core framework
- **ASP.NET Core** - Web API
- **Entity Framework Core** - Schema reading
- **Dapper** - Generated CRUD operations with multi-mapping
- **Serilog** - Logging

### Frontend
- **React** - Modern UI library
- **React JSX** - Advanced component patterns
- **CoreUI** - Bootstrap-based admin templates

### Databases
- **PostgreSQL** (primary, fully supported)
- **MySQL** (future/untested)

### Docker
- **Docker** - Containerization of database + API
- **Docker Compose** - Multi-container orchestration
- **Docker for Cloudflare** - Production deployment configuration

---

## Installation

Install WormScript as a global .NET tool:

```bash
dotnet tool install --global Wrm
```

Verify installation:

```bash
wrm help
```

---

## Quick Start

### 1. Initialize a New Project

Choose the name of your project wisely, it will be used throughout the generated code. No spaces or underlines. Case sensitive.

```bash
wrm init MyProject react
cd MyProject
```

This creates:
- `.wrm/MyProject.wrm` - Build script
- `.wrm/MyProject.sql` - Database schema

### 2. Define Your Database Schema

Edit `.wrm/MyProject.sql`:

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

### 3. Create and Run Your Database

Create a PostgreSQL database named `MyProject` and run the SQL script to set up the schema.

**Optionally** don't use the `DATABASE RUN` command in the Wrm script and rely on an existing database.

### 4. Configure Your Wrm Script

Edit `.wrm/MyProject.wrm`:

```wrm
CREATE PROJECT MyProject
    CONNECTION POSTGRES 'Host=localhost:5432;Username=postgres;Password=postgres;Database=MyProject'
    FEATURE SWAGGER
    FEATURE SOFT DELETE

DATABASE RUN '.wrm/MyProject.sql'

CREATE TESTDATA IFEMPTY USECASES 10
CREATE MODELS
CREATE API CONTROLLERS
CREATE API SERVICE
CREATE COMPONENTS
```

### 5. Build Your Project

```bash
wrm build
```

Your application-starter is now generated!

---

## Usage

### Commands

`wrm <init|build|test|list|help> [options]`

- `init`    - Initialize a new project
- `build`   - Build the project
- `test`    - Test database connectivity
- `list`    - List project components for debugging

#### `wrm init [ProjectName] [WebComponentType]`

Creates a new WormScript project structure. A base set of components is created for each entity table in the required web framework form.

```bash
wrm init MyProject react      # React components
wrm init MyProject coreui     # CoreUI components
```

#### `wrm build`

Executes the .wrm script and generates all code.

```bash
wrm build
```

#### `wrm test connection`

Tests database connectivity.

```bash
wrm test connection
```

#### `wrm list [OPTION]`

Lists project components for debugging.

Options:
- `ENTITIES` - All entity tables
- `MODELS` - Generated models
- `PORTS` - API ports configuration
- `TEMPLATES` - Available templates
- `TABLES` - Database tables
- `FEATURES` - Enabled features
- `CONFIG` - Configuration settings
- `CONNECTION` - Database connection info (masked)

```bash
wrm list tables
wrm list features
```

#### `wrm database`

Shows database information and connection details.

```bash
wrm database
```

#### `wrm help [command]`

Shows help information.

```bash
wrm help
wrm help init
wrm help build
```

---

### WRM Script Syntax

WormScript uses a simple, declarative syntax:

#### Basic Structure

```wrm
-- Comments start with -- or //

CREATE PROJECT ProjectName
    CONNECTION POSTGRES 'Host=localhost;Database=mydb;Username=user;Password=pass'
    FEATURE SWAGGER              -- Enable Swagger docs
    FEATURE SOFT DELETE          -- Use soft delete (is_deleted column)
    -- FEATURE HARD DELETE   -- Alternative: permanent deletion

DATABASE RUN '.wrm/schema.sql'

CREATE MODELS               -- Generate model classes
CREATE API CONTROLLERS      -- Generate API controllers
CREATE API SERVICE          -- Generate microservice code
CREATE COMPONENTS           -- Generate web components
CREATE TESTDATA IFEMPTY USECASES 10  -- Generate test data
```

#### Commands

| Command | Description |
|---------|-------------|
| `CREATE PROJECT <name>` | Initialize project configuration (required first) |
| `DATABASE RUN '<filepath>'` | Execute SQL script to create/update schema |
| `CREATE MODELS` | Generate C# model classes from database tables |
| `CREATE MODEL <tablename>` | Generate single model |
| `CREATE API SERVICE` | Generate all API controllers |
| `CREATE COMPONENTS` | Generate web UI components |
| `CREATE LOOKUP ON '<table>' BY '<fields>'` | Generate lookup/finder methods (see [CREATE LOOKUP](#create-lookup)) |
| `CREATE MODEL FLAT <name> FROM <table> WITH/HAVING <subtables>` | Generate flat (joined) model |
| `CREATE MODEL TREE <name> FROM <table> WITH/HAVING <subtables>` | Generate tree (hierarchical) model |
| `CREATE TESTDATA [options]` | Generate test data |
| `CREATE TESTTABLE [name]` | Create test table with all data types |


#### Connection Strings

```wrm
-- PostgreSQL
CONNECTION POSTGRES 'Host=localhost:5432;Database=mydb;Username=user;Password=pass'

-- MySQL
CONNECTION MYSQL 'Server=localhost;Database=mydb;User=user;Password=pass'
```

---

### Features System

WormScript includes a modular feature system. Enable features with the `FEATURE` sub command:

```wrm
CREATE PROJECT <name>
FEATURE SOFT DELETE    -- Soft delete (is_deleted column, marks records as deleted)
-- FEATURE HARD DELETE -- Alternative: permanent deletion (default)
FEATURE BASE           -- Base functionality (required by others)
FEATURE AUTH           -- Authentication/Authorization (JWT)
FEATURE ORGANISATIONS  -- Multi-tenancy support with hierarchical organizations
FEATURE USERS          -- User management tables
FEATURE FILEHANDLING   -- File attachment support
FEATURE GRAPHQL        -- GraphQL API layer
FEATURE ENTITIES       -- Entity configuration framework
FEATURE MCP;           -- Model Context Protocol (AI integration)
FEATURE RPC            -- Remote Procedure Call support
```

**WARNING:**
The current implementation of FEATURES will DROP **EVERYTHING in the public schema** and recreate the public schema with nothing in it. **Use with caution on existing databases.**

See [Features.md](Docs/Features.md) for full list and descriptions.

**Feature Dependencies:**

Features automatically enable their dependencies. For example:
- `ORGANISATIONS` requires `BASE`
- `AUTH` requires `BASE` and `USERS`
- `FILEHANDLING` requires `BASE`

---

## Project Structure

After running `wrm init MyProject react` and `wrm build`, you get:

```
MyProject/
├── .wrm/
│   ├── MyProject.wrm              # Build script
│   └── MyProject.sql              # Database schema
│
├── MyProjectData/                 # Data Access Layer
│   ├── Config/
│   │   └── DbConnectionConfig.cs
│   ├── Database/
│   │   └── BaseRepository.cs      # Base repository class
│   ├── Models/
│   │   ├── IDatabaseModel.cs      # Model interface
│   │   ├── UserDbModel.cs         # Entity models
│   │   ├── UserFlatModel.cs       # Flat/joined models
│   │   └── UserTreeModel.cs       # Hierarchical models
│   ├── Repositories/
│   │   ├── UserRepository.cs      # Dapper CRUD operations
│   │   └── ...
│   └── MyProjectData.csproj
│
├── MyProjectService/              # API Service Layer
│   ├── Controllers/
│   │   ├── UserController.cs
│   │   └── ...
│   ├── GraphQL/                   # (if GRAPHQL feature enabled)
│   │   ├── UserQLQuery.cs
│   │   └── UserQLMutation.cs
│   ├── MCP/                       # (if MCP feature enabled)
│   │   └── UserMCPController.cs
│   ├── Security/                  # (if AUTH feature enabled)
│   │   ├── AuthController.cs
│   │   └── JwtTokenService.cs
│   ├── Config/
│   ├── Logging/
│   ├── Program.cs
│   ├── appsettings.json
│   └── MyProjectService.csproj
│
├── MyProjectReact/                # Web UI (React)
│   ├── src/
│   │   ├── components/
│   │   │   └── project/
│   │   │       └── User/
│   │   │           ├── UserApi.js
│   │   │           ├── UserForm.jsx
│   │   │           ├── UserTable.jsx
│   │   │           ├── UserCard.jsx
│   │   │           └── UserDropdown.jsx
│   │   ├── routes/
│   │   └── layouts/
│   └── package.json
│
├── MyProject.Tests/               # Unit Tests
│   ├── UserDbFullTests.cs
│   ├── UserDbQuickTests.cs
│   └── MyProject.Tests.csproj
│
├── docker/                        # Docker Configurations
│   ├── docker-compose.yml
│   ├── docker-compose.prod.yml
│   └── Dockerfile
│
└── MyProject.sln                  # Solution file
```

---

## Generated Output

### API Controllers

For each table, WormScript generates:

**UserController.cs:**
```csharp
[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly UserRepository _repository;

    [HttpGet]
    public async Task<IActionResult> GetAll() { ... }

    [HttpGet("paged")]
    public async Task<IActionResult> GetAllPaged(int page, int pageSize) { ... }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id) { ... }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UserDbModel model) { ... }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UserDbModel model) { ... }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) { ... }

    // Custom finder methods based on column annotations
    [HttpGet("email/{email}")]
    public async Task<IActionResult> FindByEmail(string email) { ... }
}
```

### Data Models

WormScript generates a dual-model architecture:

**DbModels (internal, snake_case for Dapper):**
```csharp
internal class UserDbModel : IDatabaseModel
{
    public int user_id { get; set; }
    public DateTime created_at { get; set; }
    public int? created_by { get; set; }
    public bool is_deleted { get; set; }
    public string username { get; set; }
    public string email { get; set; }
}
```

**DTOs (public, PascalCase for API with XML docs):**
```csharp
public class UserDto
{
    /// <summary>
    /// Unique identifier for the User
    /// </summary>
    [JsonIgnore]
    public int Id { get; set; }

    /// <summary>
    /// Username (required)
    /// </summary>
    public string Username { get; set; }

    /// <summary>
    /// Email (required)
    /// </summary>
    public string Email { get; set; }
}
```

**Mappers** are generated to convert between DbModel and DTO internally in the repository layer. Controllers and services work exclusively with DTOs.

**Flat Models:** Read-only models for joined queries across tables (see [Flat and Tree Models](#flat-and-tree-models)).

**Tree Models:** Hierarchical models with nested sub-objects for parent-child relationships.

### Dapper Repositories

**UserRepository.cs:**
```csharp
public class UserRepository : BaseRepository
{
    public async Task<UserDbModel> GetById(int id) { ... }
    public async Task<IEnumerable<UserDbModel>> GetAll() { ... }
    public async Task<PagedResult<UserDbModel>> GetAllPaged(int page, int pageSize) { ... }
    public async Task<int> Create(UserDbModel model) { ... }
    public async Task<bool> Update(UserDbModel model) { ... }
    public async Task<bool> Delete(int id) { ... }
    public async Task<bool> Upsert(UserDbModel model) { ... }

    // Custom finders based on ## annotations
    public async Task<UserDbModel> FindByEmail(string email) { ... }
}
```

### Web Components

**UserApi.js:**
```javascript
const API_BASE = '/api/user';

export const UserApi = {
    getAll: () => fetch(API_BASE),
    getById: (id) => fetch(`${API_BASE}/${id}`),
    create: (data) => fetch(API_BASE, { method: 'POST', body: JSON.stringify(data) }),
    update: (id, data) => fetch(`${API_BASE}/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
    delete: (id) => fetch(`${API_BASE}/${id}`, { method: 'DELETE' }),
};
```

---

## Configuration

### Database Annotations

Use SQL comments to control code generation:

```sql
CREATE TABLE users(
    userId INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    email VARCHAR(255) NOT NULL,           
    username VARCHAR(255) NOT NULL,
    organization_id INTEGER,                -- '_id' allows for automatic foreign key detection
    nickname VARCHAR(100)
);
COMMENT ON COLUMN user.email IS '##';       -- Creates FindByEmail() method in API
COMMENT ON COLUMN user.username IS '##';    -- Creates FindByUsername() method in API
COMMENT ON COLUMN user.nickname IS 'HIDE';  -- field is hidden from API and UI

COMMENT ON TABLE users IS 'PAGED';          -- API must use the skip & take parameters for paging
```

The `## fieldname` annotation tells WormScript to generate a finder method for that column.

### Special Comment Annotations

#### FindBy
Creation of a lookup/finder method for the field. Add ',PAGED' to indicate the method should return paged results.
```sql
COMMENT ON COLUMN table.field IS '##'
```

#### Name
Marks the field as a "name" field for display purposes.
```sql
COMMENT ON COLUMN table.field IS 'NAME'
```
Every table should have one field as the designated name field. If one is not specified, WormScript will look for common candidates like `name`, `title`, or `description`.
This may be used in dropdowns and other UI elements. It doesn't have to be unique.

#### Hide 
Hides the field from API and UI.
```sql
COMMENT ON COLUMN table.field IS 'HIDE'
```
    
#### Enumeration tables 
Defines the table as an enumeration.
```sql
COMMENT ON TABLE table IS 'ENUM'
```

#### PAGED tables
Marks the table for paginated API endpoints. Generated controllers and repositories will include `skip` and `take` parameters.
```sql
COMMENT ON TABLE table IS 'PAGED'
```

#### READONLY tables
Marks a table as read-only. No insert, update, or delete methods are generated.
```sql
COMMENT ON TABLE table IS 'READONLY'
```

#### Attachment support
When the `FILEHANDLING` feature is enabled, attachment endpoints are generated for tables that opt in. By default, tables must explicitly include the `ATTACHMENTS` keyword in their table comment. If `FileHandlingByDefault` is enabled in config, all eligible tables get attachments unless they opt out with `NOATTACHMENTS`.
```sql
COMMENT ON TABLE documents IS 'PAGED, ATTACHMENTS'    -- opt-in to file attachments
COMMENT ON TABLE lookups IS 'ENUM, NOATTACHMENTS'      -- explicitly opt-out
```

### Column Naming Conventions
Columns with certain names are treated specially for UI generation:

| Column Name Contains |  UX Effect |
|----------------------|------------|
| latitude | UX builds data-entry and validation relevant to a latitude or longitude |
| longitude | UX builds data-entry and validation relevant to a latitude or longitude |
| email| Email UX and validation |
| password| Password UX and validation |
| enum| Builds radio selection based on the referenced ENUM TABLE |
| w3w | UX data-entry and handling for What3Words |



## Database Support

### PostgreSQL (Recommended)

```sql
CREATE TABLE users(
    userId INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    username VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Features:**
- `GENERATED ALWAYS AS IDENTITY` for auto-increment
- `LIKE` clause for table inheritance
- `TIMESTAMPTZ` for timestamps
- JSON/JSONB support
- Schema support

### MySQL (Partial support)

```sql
CREATE TABLE users(
    userId INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Examples

### Complete Example

**1. Create project:**
```bash
wrm init BlogApp react
cd BlogApp
```

**2. Define schema (.wrm/BlogApp.sql):**
```sql
DROP TABLE IF EXISTS posts;
CREATE TABLE posts(
    post_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    author_id INTEGER NOT NULL,
    -- ## author_id
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

DROP TABLE IF EXISTS comments;
CREATE TABLE comments(
    comment_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    post_id INTEGER NOT NULL,
    -- ## post_id
    content TEXT NOT NULL,
    author_name VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**3. Configure build (.wrm/BlogApp.wrm):**
```wrm
CREATE PROJECT BlogApp
    CONNECTION POSTGRES 'Host=localhost:5432;Database=blogapp;Username=postgres;Password=postgres'
    FEATURE SWAGGER
    FEATURE SOFT DELETE
    FEATURE BASE
    FEATURE USERS

DATABASE RUN '.wrm/BlogApp.sql'

CREATE TESTDATA IFEMPTY USECASES 20
CREATE MODELS
CREATE API SERVICE
CREATE COMPONENTS
```

**4. Build:**
```bash
wrm build
```

**5. Run API:**
```bash
cd BlogAppService
dotnet run
```

Your API is now running with:
- `GET /api/post` - Get all posts
- `GET /api/post/paged?page=1&pageSize=10` - Get paged posts
- `GET /api/post/{id}` - Get post by ID
- `GET /api/post/author/{authorId}` - Get posts by author
- `POST /api/post` - Create post
- `PUT /api/post/{id}` - Update post
- `DELETE /api/post/{id}` - Soft delete post
- `GET /api/comment/post/{postId}` - Get comments by post

---

## Flat and Tree Models

WormScript can generate composite models that join data from multiple tables. These are read-only models useful for API responses that combine related data.

### Flat Models

Flat models join columns from related tables into a single denormalized model. Use `HAVING` when the primary table's ID appears in the subtable (parent expands on children), or `WITH` when the subtable's ID appears in the primary table (child refers to parent).

```wrm
-- Parent-to-child: star_system_id appears in stars and planets
CREATE MODEL FLAT StarSystemDetail FROM star_systems HAVING stars, planets;

-- Child-to-parent: organisation_id appears in the users table
CREATE MODEL FLAT UserDetail FROM users WITH organisations;

-- Use ALL to include every table that references the primary key
CREATE MODEL FLAT StarSystemFull FROM star_systems HAVING ALL;
```

### Tree Models

Tree models create hierarchical structures with nested sub-objects using Dapper multi-mapping. The generated repository uses SQL joins and splits results into parent/child objects.

```wrm
CREATE MODEL TREE StarSystemTree FROM star_systems HAVING stars, planets;
```

This generates a model where `StarSystemTree` contains nested collections of `Star` and `Planet` objects.

---

## CREATE LOOKUP

The `CREATE LOOKUP` command generates additional finder methods (repository + API endpoint) for a table, allowing you to query records by one or more columns. This is the script-based equivalent of using `##` column comments but gives you explicit control over multi-column lookups and custom naming.

### Syntax

```wrm
CREATE LOOKUP ["<name>"] ON '<table_name>' BY '<field_list>';
```

| Part | Required | Description |
|------|----------|-------------|
| `"<name>"` | No | Optional custom name for the generated method. If omitted, WormScript generates one automatically as `FindBy<Field1>[And<Field2>...]` |
| `ON '<table_name>'` | Yes | The database table to create the lookup for. Must be a table already read by `CREATE MODELS` |
| `BY '<field_list>'` | Yes | One or more column names to look up by, joined with `&` for compound lookups |

### Examples

**Single-column lookup:**
```wrm
CREATE LOOKUP ON 'attachments' BY 'attachment_type';
```
Generates `FindByAttachmentType(string attachmentType)` — returns all attachments matching the given type.

**Multi-column lookup:**
```wrm
CREATE LOOKUP ON 'entity_attachments' BY 'entity_id&entity_type&organisation_id';
```
Generates `FindByEntityIdAndEntityTypeAndOrganisationId(int entityId, string entityType, int organisationId)` — returns all entity attachments for a specific entity within an organisation.

**Custom-named lookup:**
```wrm
CREATE LOOKUP "FindActiveByOrg" ON 'entity_attachments' BY 'availability_policy_id&organisation_id';
```
Generates `FindActiveByOrg(int availabilityPolicyId, int organisationId)` instead of the auto-generated name.

### What Gets Generated

For each `CREATE LOOKUP`, WormScript generates:

1. **Repository method** — A Dapper query method in the entity's repository class that accepts the lookup column(s) as parameters and returns matching records.
2. **API endpoint** — A `GET` route on the entity's controller, e.g. `GET /api/entityattachment/attachmenttype/{attachmentType}`.
3. **FindBy API endpoint** — A controller method wired to call the repository finder.

### Usage Notes

- `CREATE LOOKUP` must appear **after** `CREATE MODELS` in your `.wrm` script, as the table metadata must be loaded first.
- The table name should match the database table name (snake_case), not the model name.
- Column names in the `BY` clause must be actual database column names (snake_case).
- Duplicate lookups (same fields on the same table) are silently skipped.
- Features like `AUTH` and `FILEHANDLING` automatically register their own lookups via internal `.wrm` scripts — you don't need to add those manually.

### Real-World Example

```wrm
CREATE PROJECT MyApp
    CONNECTION POSTGRES 'Host=localhost;Database=myapp;Username=postgres;Password=postgres'
    FEATURE BASE
    FEATURE AUTH
    FEATURE FILEHANDLING

DATABASE RUN '.wrm/MyApp.sql'

CREATE MODELS

-- Custom lookups beyond what ## annotations provide
CREATE LOOKUP ON 'attachments' BY 'attachment_type';                        -- All attachments of a given type
CREATE LOOKUP ON 'attachments' BY 'storage_type_id&organisation_id';        -- All attachments for an org stored a certain way
CREATE LOOKUP ON 'entity_attachments' BY 'entity_id&entity_type&organisation_id';  -- All attachments for a specific entity

CREATE API SERVICE
CREATE COMPONENTS
```

---

## Template Fragment System (WRM_APPLY)

Templates can include reusable fragment files using the `//WRM_APPLY` directive. Fragment files are prefixed with `#` and contain reusable code blocks.

```csharp
// In a controller template:
//WRM_APPLY "#GetAllPaged.cs"
//WRM_APPLY "#MetaData.cs"
//WRM_APPLY "#JsonSchema.cs"
```

At build time, each `//WRM_APPLY` directive is replaced with the contents of the referenced fragment file. Fragment files support all the same WRM conditional blocks and token replacements as regular templates.

Available fragment templates:
| Fragment | Description |
|----------|-------------|
| `#GetAllPaged.cs` | GetAll endpoint with optional pagination |
| `#FindBy.cs` | Repository FindBy method |
| `#FindByApi.cs` | Controller FindBy endpoint |
| `#FindByOrg.cs` | Organisation-scoped FindBy method |
| `#MetaData.cs` | Metadata endpoint returning entity field definitions |
| `#JsonSchema.cs` | JSON Schema endpoint for the entity DTO |
| `#HardDelete.cs` | Permanent delete endpoint |
| `#SoftDelete.cs` | Soft-delete endpoint with optional force-delete |

---

## Dependencies

### Runtime Requirements
- .NET 8.0 or 9.0 SDK/Runtime
- Database server (PostgreSQL or MySQL)

### Generated Project Dependencies

The generated projects include:
- ASP.NET Core 8.0/9.0
- Dapper 2.1.66
- Npgsql (for PostgreSQL)
- Serilog (logging)
- Swashbuckle.AspNetCore + Annotations (Swagger/OpenAPI)
- Optional: JWT Bearer, Entity Framework Core, HotChocolate (GraphQL)

---


## License

Copyright (c) 2026 Furniss Software. All rights reserved.
Working the wording on an AGPL licence but bascially:
- I own the tool and license it to you use as you want;
- the code it generates is all yours to do with with whatever you want;
- however where it generates code that comes from 3rd party templates its up to you to verify if and how you can use it.

---

## Support

- **Documentation:** Check `.wrm/` folder examples after running `wrm init`
- **Issues:** Report bugs via the project repository
- **Database Connection:** Use `wrm test connection` to diagnose connectivity
- **Debugging:** Use `wrm list` commands to inspect project state

---

**Happy Coding with WormScript!**

*Transform your database into a ready-to-start application in minutes.*

**Version:** 3.3.3
**Framework:** .NET 9.0
**License:** Furniss Software (c) 2026