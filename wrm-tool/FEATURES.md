# WRM Features

Features are optional capabilities enabled with `FEATURE <name>` in the CREATE PROJECT block. Features auto-include their dependencies.

**This is the user-facing feature guide** — what each feature creates, when to use it, dependencies. For implementation details (how features gate templates, file copying, condition evaluation), see [`wrm-development/FEATURES.md`](../../wrm-development/FEATURES.md). For per-table feature configuration via SQL annotations, see [`wrm-development/TABLE_ANNOTATIONS.md`](../../wrm-development/TABLE_ANNOTATIONS.md).

---

## Feature Reference

### SWAGGER / NOSWAGGER
**Keyword:** `FEATURE SWAGGER` or `FEATURE NOSWAGGER`
**Auto-included by:** None (Swagger is **enabled by default**)

Controls whether Swagger/OpenAPI documentation is generated for the API.

- `FEATURE SWAGGER` - Explicitly enables Swagger (this is the default; you can omit it).
- `FEATURE NOSWAGGER` - Disables Swagger documentation.
- Can also be overridden per-API: `CREATE API SERVICE NOSWAGGER;`

> **Note:** `DOC SWAGGER` / `DOC NODOC` are deprecated but still accepted for backward compatibility.

---

### BASE
**Keyword:** `FEATURE BASE`
**Auto-included by:** ORGANISATIONS, USERS, ENTITYCONFIG, FILEHANDLING, AUTH

Adds common base columns to all tables via PostgreSQL `LIKE` clause inheritance.

**Base schemas created:**
| Schema Table | Columns | Purpose |
|-------------|---------|---------|
| `base.tracking` | `created_at`, `updated_at`, `is_deleted`, `organisation_id` | Audit timestamps and soft delete |
| `base.gps` | NMEA GPS fields | GPS/location tracking |
| `base.address` | `house_name_or_number`, `street`, `town_or_city`, `county`, `postcode`, `country`, `what3words`, `latitude`, `longitude` | Standardised address |
| `base.event` | `event_at`, `event_type_id`, `event_data` (JSON) | Event logging |

**Tables created:**
| Table | Description |
|-------|-------------|
| `event_classes` | Categories of events (Vehicle, User-Action, Session, etc.) |
| `event_types` | Specific event types within a class |

**Usage in SQL:** When BASE is enabled, use `LIKE base.tracking INCLUDING DEFAULTS INCLUDING CONSTRAINTS` in your CREATE TABLE statements to inherit the tracking columns.

---

### ORGANISATIONS
**Keyword:** `FEATURE ORGANISATIONS` (also accepts `FEATURE ORGS`)
**Requires:** BASE

Multi-tenant organisation management with parent-child hierarchies. Adds `organisation_id` to all entity tables.

**Tables created:**
| Table | Description |
|-------|-------------|
| `organisation_types` | Enum of org types (Charity, Company, Government Agency, etc.) |
| `organisations` | Client organisations with name, type, parent org, address fields |

**When to use:** The user needs to isolate data by organisation, support multiple clients, or have a hierarchy of groups/companies.

---

### USERS
**Keyword:** `FEATURE USERS` (also accepts `FEATURE USER`)
**Requires:** BASE

User accounts, profiles, groups, and communication preferences.

**Tables created:**
| Table | Description |
|-------|-------------|
| `users` | User accounts (title, name, email, dob, passhash, mobile, phone, language) |
| `user_profiles` | Extended profile (bio, avatar_url) |
| `user_communications` | Notification preferences (general, marketing, social, security, email, txt, whatsapp) |
| `user_groups` | Named groups of users |
| `user_group_members` | Maps users to groups |
| `user_events` | User activity log for auditing |

**When to use:** The application has user accounts of any kind.

---

### AUTH
**Keyword:** `FEATURE AUTH` (also accepts `FEATURE AUTHENTICATION`)
**Requires:** BASE, ORGANISATIONS, USERS

JWT-based authentication with role-based access control (RBAC).

**Tables created:**
| Table | Description |
|-------|-------------|
| `permissions` | System and custom permissions (VIEW_, EDIT_, DELETE_ per entity) |
| `roles` | Named roles assigned to users per organisation |
| `user_roles` | Maps users to roles (UNIQUE user_id + role_id) |
| `role_permissions` | Maps roles to permissions (UNIQUE org + role + permission) |

**Auto-generated:**
- `AuthController.cs` with login/register/refresh endpoints
- `JwtTokenService.cs` for token generation
- `[Authorize]` attributes on all controller endpoints
- System permissions: `VIEW_<TABLE>`, `EDIT_<TABLE>`, `DELETE_<TABLE>` for every entity

**When to use:** The user mentions login, authentication, authorization, roles, permissions, or access control.

---

### FILEHANDLING
**Keyword:** `FEATURE FILEHANDLING`
**Requires:** BASE, ORGANISATIONS, USERS

File uploads, document attachments, folders, retention and availability policies.

**Tables created:**
| Table | Description |
|-------|-------------|
| `storage_types` | Types of file storage |
| `attachments` | File records (filename, store_location, store_type, size, file_type, version, retention_policy_id) |
| `entity_attachments` | Associates files to any entity via entity_type + entity_id |
| `folders` | Folder hierarchy for organising documents |
| `retention_policies` | When to delete/archive documents |
| `availability_policies` | When/to whom documents are available |

**Table annotations required:** Tables that should support attachments need `ATTACHMENTS` in their table comment:
```sql
COMMENT ON TABLE documents IS 'PAGED, ATTACHMENTS';
```

**When to use:** The user needs file uploads, document management, image attachments, or any file association with entities.

---

### ENTITYCONFIG
**Keyword:** `FEATURE ENTITYCONFIG` (also `FEATURE CONFIG`)
**Requires:** BASE

Key-value metadata that can be attached to any entity.

**Tables created:**
| Table | Description |
|-------|-------------|
| `entity_configs` | Key-value pairs associated with entity_type + entity_id |

**When to use:** The user needs tags, custom configuration, or arbitrary metadata on entities.

---

### GRAPHQL
**Keyword:** `FEATURE GRAPHQL`
**Requires:** None

Adds a GraphQL API layer alongside REST.

**Generated per table:**
- `<Model>QLQuery.cs` - GraphQL query operations
- `<Model>QLMutation.cs` - GraphQL mutation operations

**When to use:** The user explicitly asks for GraphQL.

---

### MCP — NOT a FEATURE

> **There is no `FEATURE MCP`.** MCP is enabled by writing a separate top-level CREATE command, not by a `FEATURE` line.

```wrm
-- Correct: enable MCP via its own CREATE command
CREATE MCP SERVICE;        -- generate the MCP service project
-- or
CREATE MCP CONTROLLERS;    -- generate MCP controllers only
```

Internally, while emitting MCP files, `ProjectBuilder.PushFeature("MCP")` sets a transient flag so templates can check `//WRM_IF HasFeature("MCP")`. The user never writes `FEATURE MCP` — and doing so raises *"Unknown feature MCP"*.

See the [`COMMAND_REFERENCE.md` § CREATE MCP](COMMAND_REFERENCE.md) section for full syntax.

---

### RPC
**Keyword:** `FEATURE RPC`
**Requires:** None

Remote Procedure Call support via JSON-RPC.

**Status:** Not fully implemented yet.

---

### MULTIAPP
**Keyword:** `FEATURE MULTIAPP`
**Requires:** None

Supports multiple web applications accessing the same service with an Application ID.

**Status:** Not fully implemented yet.

---

### SUBSCRIBERS
**Keyword:** `FEATURE SUBSCRIBERS`
**Requires:** None

Generates event-subscriber scaffolding (templates in `Worm/Templates/Features/Subscribers/`).

---

### ADDITIONAL
**Keyword:** `FEATURE ADDITIONAL`
**Requires:** None

Additional controller scaffolding hooks. Internal-extension flag.

---

### REDIS
**Keyword:** `FEATURE REDIS ['<connection-string>']`
**Requires:** None

Enables the Redis caching feature. Gates `docker-compose.cache.yml`, `publish-docker-cache.ps1`, and Redis blocks in compose files.

The optional quoted connection string immediately after the feature name sets `RedisConnectionString` in the generated `AppConfig`. Omit it if the connection is supplied via env var or `appsettings.json`.

```wrm
CREATE PROJECT MyApp
    CONNECTION POSTGRES '...'
    FEATURE REDIS 'localhost:6379';
```

> **Migration note:** the legacy `REDIS '<conn>'` CREATE PROJECT subcommand was removed. The parser now emits a hard error if it sees the old form — search-and-replace to `FEATURE REDIS '<conn>'`.

---

### RABBITMQ
**Keyword:** `FEATURE RABBITMQ ['<connection-string>']`
**Requires:** None

Enables the RabbitMQ publishing feature (AMQP 0.9.1 via the `RabbitMQ.Client` .NET library).

For each table whose `COMMENT ON TABLE` contains `PUBLISH=RABBITMQ`, WRM:
- Forces `UseServiceLayer = true` (publisher hooks live on the service, not the repository).
- Generates `<Entity>RabbitMqPublisher.cs` per entity.
- Copies `RabbitMqConnectionHolder.cs` (process-wide singleton `IConnection`).
- Adds `<PackageReference Include="RabbitMQ.Client" Version="6.8.1" />` to the API `.csproj`.
- Includes a RabbitMQ service block in the generated docker-compose files plus a standalone `docker-compose.rabbit.yml` and `publish-docker-rabbit.ps1`.

**Topology** (created lazily on first publish):
- One project-wide topic exchange named `<projectlc>`.
- One durable queue per entity, named `<projectlc>.<entitylc>`.
- Bound with key `<projectlc>.<entitylc>.*`.
- Publish operations route with key `<projectlc>.<entitylc>.{insert|update|delete}`.
- Body is the DTO via `ModelDto.ToJson()` with `ContentType=application/json`, `DeliveryMode=2` (persistent).
- List/IEnumerable overloads emit one message per entity.

```wrm
CREATE PROJECT ShopApp
    CONNECTION POSTGRES '...'
    FEATURE RABBITMQ 'amqp://guest:guest@localhost:5672/';
```

```sql
COMMENT ON TABLE orders IS 'PUBLISH=RABBITMQ';
```

The default Docker image is `rabbitmq:3-management-alpine`. Swap to `dhi/rabbitmq` (Docker Hardened Images) by editing `docker-compose.rabbit.yml` after generation if you have a Docker subscription with hardened-images access.

---

## Dependency Graph

```
FEATURE AUTH
  └─► FEATURE USERS
  │     └─► FEATURE BASE
  └─► FEATURE ORGANISATIONS
        └─► FEATURE BASE

FEATURE FILEHANDLING
  └─► FEATURE USERS
  │     └─► FEATURE BASE
  └─► FEATURE ORGANISATIONS
        └─► FEATURE BASE

FEATURE ENTITYCONFIG
  └─► FEATURE BASE

FEATURE ORGANISATIONS
  └─► FEATURE BASE

FEATURE USERS
  └─► FEATURE BASE

FEATURE SWAGGER     (no dependencies, enabled by default)
FEATURE NOSWAGGER   (no dependencies, disables Swagger)
FEATURE GRAPHQL     (no dependencies)
FEATURE RPC         (no dependencies)
FEATURE MULTIAPP    (no dependencies)
FEATURE SUBSCRIBERS (no dependencies)
FEATURE ADDITIONAL  (no dependencies)
FEATURE REDIS    ['<conn>']  (no dependencies — optional quoted connection string)
FEATURE RABBITMQ ['<conn>']  (no dependencies — optional quoted connection string)
```

> **Not features (do not use `FEATURE …`):** `MCP` is enabled by `CREATE MCP SERVICE` / `CREATE MCP CONTROLLERS` (top-level CREATE commands). Azure deployment is `CREATE AZURE CONTAINER` / `CREATE AZURE FUNCTIONS`. See [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md).

---

## Feature Selection Cheat Sheet

| User Says | Enable |
|-----------|--------|
| "I need login" / "users can sign in" | `FEATURE AUTH` |
| "multiple organisations" / "tenants" | `FEATURE ORGANISATIONS` |
| "user accounts" / "profiles" | `FEATURE USERS` |
| "upload files" / "attachments" / "documents" | `FEATURE FILEHANDLING` |
| "GraphQL" | `FEATURE GRAPHQL` |
| "AI integration" / "MCP" | `CREATE MCP SERVICE;` (top-level command — **not** a `FEATURE`) |
| "Redis cache" | `FEATURE REDIS 'localhost:6379'` |
| "publish events" / "RabbitMQ" / "message broker" | `FEATURE RABBITMQ 'amqp://guest:guest@localhost:5672/'` plus `PUBLISH=RABBITMQ` on the table comment |
| "tags" / "custom metadata" / "key-value config" | `FEATURE ENTITYCONFIG` |
| "no swagger" / "disable docs" | `FEATURE NOSWAGGER` |
| "most real-world apps" | `FEATURE AUTH` (covers users, orgs, base) |
