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
**Requires:** BASE, AUTH, USERS (all auto-included)

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
**Requires:** BASE, USERS (auto-included; ORGANISATIONS is NOT auto-included by AUTH)

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

Key-value metadata and tagging that can be attached to any entity.

**Tables created:**
| Table | Description |
|-------|-------------|
| `entity_configs` | Key-value pairs attached to any entity (`entity_type` + `entity_id` + `item_key` + `item_value`). FindBy endpoints generated on `entity_id`, `entity_type`, and `item_key`. |
| `entity_allowed_tags` | Catalogue of allowed tag values per entity type. Define which tags are permitted for each entity type (e.g. users can be tagged `"pastor"`, `"musician"`). |
| `entity_tags` | Assigns an allowed tag to a specific entity (`entity_type` + `entity_id` → `entity_allowed_tag_id` FK). FindBy endpoint on `entity_type&entity_id`. |

**When to use:** The user needs tags, custom configuration, or arbitrary metadata on entities without adding columns to each table.

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

`FEATURE RPC` is accepted by the parser and adds `"RPC"` to the project's feature set. However, the actual JSON-RPC 2.0 service project is generated by a separate top-level command, not by `FEATURE RPC` alone:

```wrm
CREATE RPC SERVICE CONTROLLERS;
```

During `CREATE RPC` generation, the builder transiently sets the `RPC` feature flag so templates can check `//WRM_IF HasFeature("RPC")`. You do not need to write `FEATURE RPC` explicitly in your script — `CREATE RPC SERVICE` handles it. See [`COMMAND_REFERENCE.md` § CREATE RPC](COMMAND_REFERENCE.md) for full syntax.

---

### MULTIAPP
**Keyword:** `FEATURE MULTIAPP`
**Requires:** AUTH (auto-included, which transitively includes BASE + USERS)

Supports multiple web applications accessing the same service with an Application ID.

---

### SUBSCRIBERS
**Keyword:** `FEATURE SUBSCRIBERS`
**Requires:** BASE, USERS, AUTH (all auto-included)

Generates event-subscriber scaffolding (templates in `Worm/Templates/Features/Subscribers/`).

---

### MESSAGING
**Keyword:** `FEATURE MESSAGING`
**Requires:** BASE, USERS (auto-included)

Adds backend support for three independent messaging subdomains, all under the `wrm_messaging` schema:

- **Direct messages** (email-style) — a user composes a message (up to 1024 chars), addresses one or more user IDs and/or user-group IDs, sets a priority, and sends. The send endpoint reads the sender from the authenticated `UserContext` — there is no `senderUserId` field in the request, so impersonation is structurally prevented.
- **Conversations** (chat-box) — threaded posts inside a `conversations` row of type `direct`, `group`, or `system`. Standard CRUD; the feature provides only the schema.
- **Notifications** (system → user, one-way) — `notifications` table for system-raised alerts. No human sender.

Two ENUM tables are shared across all three subdomains: `send_states` (`SENT` → `DELIVERED` → `VIEWED`) and `priorities` (`LOW`, `NORMAL`, `HIGH`).

When `FEATURE ORGANISATIONS` is also enabled, the direct-message send flow rejects recipients outside the sender's organisation hierarchy. With ORGANISATIONS off, no boundary check is applied.

Generated artefacts:
- `ProjectApi/Messaging/MessagingService.cs` — send + state-transition logic.
- `ProjectApi/Messaging/MessagesAdditionalController.cs` — `POST /api/messages/send`, `PUT /api/messages/{id}/delivered`, `PUT /api/messages/{id}/viewed`.
- `services.AddMessagingServices()` is injected into `Startup.ConfigureServices`.

Unread messages are pulled via the auto-generated `GET /api/messageRecipients/findByRecipientUserId/{userId}` endpoint; filter the result by `sendStateId != VIEWED` client-side. Push notifications are out of scope for the current iteration.

```wrm
CREATE PROJECT MyApp
    CONNECTION POSTGRES '...'
    FEATURE AUTH
    FEATURE MESSAGING;
```

---

### INTEGRATIONS
**Keyword:** `FEATURE INTEGRATIONS` (the singular `FEATURE INTEGRATION` is also accepted)
**Requires:** BASE (auto-included)

Adds backend scaffolding for connecting the project to external systems and tracking which local records map to their external counterparts.

**Tables created:**
| Table | Description |
|-------|-------------|
| `integration_connection_types` | ENUM catalogue of supported external systems — seeded with `jira`, `confluence`, `miro`, `aws`, `azure`, `servicenow`, `salesforce`, `visio`, `excel`, `generic_rest`, `slack`, `teams`, `sharepoint`, `email`, `youtube`, `linkedin`, `github`, `what3words` |
| `integration_connections` | One row per configured connection. `name`, `is_active`, `last_synced_at`, plus `connection_config JSONB` (`HIDE`) for endpoint params and credential references |
| `integration_entity_mappings` | Maps a local entity (`local_entity_type` + `local_entity_id`) to its external counterpart (`external_entity_ref`) for a given connection. Unique index prevents duplicate mappings per connection |

**Org scoping:** When `FEATURE ORGANISATIONS` is also active, `integration_connections` gains an `organisation_id` column (via `LIKE base.tracking`) and a `FindByOrganisationId` lookup endpoint, scoping connections per tenant. Without ORGANISATIONS, connections are global to the project.

**Auto-generated endpoints (via `##` column annotations):**
- `GET /api/integrationConnections/findByIntegrationConnectionTypeId/{id}` — connections of a given type
- `GET /api/integrationEntityMappings/findByIntegrationConnectionId/{id}` — all mappings for a connection
- `GET /api/integrationEntityMappings/findByLocalEntityTypeAndLocalEntityId/{type}/{id}` — external refs for a local entity

**Security:** `connection_config` and `mapping_config` are marked `HIDE` — excluded from all DTOs and API responses. They store a **reference** to credentials (e.g. a secrets vault key), never raw passwords or tokens. The application layer is responsible for resolving the reference at runtime.

**When to use:** The project needs to connect to, sync with, or track records in external systems (Jira issues, GitHub PRs, Salesforce opportunities, AWS resources, etc.).

**What the developer still needs to do after generation:**

> ⚠️ WRM scaffolds the data model. The integration logic itself is left to the developer.

| Task | Detail |
|------|--------|
| **Customise connection-type seed list** | `integration_connection_types` is seeded with a generic list. Add or remove rows in your `.sql` file to match the systems your project actually uses |
| **Define `connection_config` JSON structure** | Each integration type needs a documented JSONB schema (e.g. `{ "base_url": "...", "credential_key": "vault://..." }`). Enforce with a JSON Schema validator or PostgreSQL check constraint |
| **Wire credentials vault** | The application layer must resolve `credential_key` (or equivalent field) to the actual secret at runtime. WRM does not generate vault-resolver code |
| **Implement sync logic** | WRM generates CRUD endpoints for connections and mappings, not sync runners. Write services that call external APIs, update `last_synced_at`, and populate `integration_entity_mappings` |
| **Establish `local_entity_type` convention** | Decide what string identifies each table (e.g. plural snake_case `orders`, or class name `Order`). Document it in your project and use it consistently when inserting mapping rows |
| **Audit generated controllers** | Although `connection_config` is `HIDE`, verify that your generated `POST /api/integrationConnections` and `PUT` endpoints do not inadvertently echo any part of the config object in error messages |

```wrm
CREATE PROJECT MyApp
    CONNECTION POSTGRES '...'
    FEATURE ORGANISATIONS
    FEATURE INTEGRATIONS;
```

---

### CHATBOT
**Keyword:** `FEATURE CHATBOT`
**Requires:** nothing (standalone; composes with AUTH for user context)

Adds an AI chatbot capability with **server-side proxy** support. Generates a `ChatbotController`
(namespace `ProjectApi.Chatbot`, route `POST /api/chatbot/message`) that forwards a chat message
plus prior history to the configured MCP / AI service and returns its reply — keeping the MCP URL
and any credentials off the browser.

**Configuration** (`appsettings.json`):
| Key | Default | Description |
|-----|---------|-------------|
| `Chatbot:McpUrl` | `https://localhost:6011` | MCP / AI service base URL |
| `Chatbot:ApiKey` | *(empty)* | Optional API key sent as `X-Api-Key` |

**Frontend:** Web templates (e.g. TailComplete) gate their chat widget on `HasFeature("CHATBOT")`,
so the widget appears only when the feature is enabled.

**When to use:** The project should offer an in-app AI assistant backed by an MCP server.

```wrm
CREATE PROJECT MyApp
    CONNECTION POSTGRES '...'
    FEATURE AUTH
    FEATURE CHATBOT;
```

---

### LINKEDIN
**Keyword:** `FEATURE LINKEDIN`
**Requires:** `AUTH` (auto-included — which itself pulls in `BASE` + `USERS`)

Adds **"Sign In with LinkedIn using OpenID Connect"** to the auth stack. The confidential parts —
the client secret and the authorization-code → token exchange — happen **server-side** in
`LinkedInOAuthService`, wired into the existing `AuthController`; the SPA never sees the secret.
Users are JIT-provisioned on first sign-in (assigned `DefaultOrganisationId`).

**Configuration:** the client credentials come from environment variables
`LINKEDIN_CLIENT_ID` / `LINKEDIN_CLIENT_SECRET`. The non-secret OIDC endpoint URLs
(`TokenUrl`, `UserInfoUrl`) have sensible defaults and can be overridden under the `LinkedIn`
section of `appsettings.json`. The feature is **inert until both credentials are supplied**.

**When to use:** end users should be able to sign in with their LinkedIn account instead of
(or alongside) a local username/password.

```wrm
CREATE PROJECT MyApp
    CONNECTION POSTGRES '...'
    FEATURE AUTH
    FEATURE LINKEDIN;
```

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
        └─► FEATURE BASE

FEATURE ORGANISATIONS
  └─► FEATURE BASE
  └─► FEATURE AUTH
        └─► FEATURE USERS
              └─► FEATURE BASE

FEATURE FILEHANDLING
  └─► FEATURE USERS
  │     └─► FEATURE BASE
  └─► FEATURE ORGANISATIONS
        └─► FEATURE BASE
        └─► FEATURE AUTH
              └─► FEATURE USERS ─► BASE

FEATURE ENTITYCONFIG
  └─► FEATURE BASE

FEATURE USERS
  └─► FEATURE BASE

FEATURE SUBSCRIBERS
  └─► FEATURE AUTH
        └─► FEATURE USERS ─► BASE

FEATURE MULTIAPP
  └─► FEATURE AUTH
        └─► FEATURE USERS ─► BASE

FEATURE SWAGGER     (no dependencies, enabled by default)
FEATURE NOSWAGGER   (no dependencies, disables Swagger)
FEATURE GRAPHQL     (no dependencies)
FEATURE RPC         (no dependencies — but use CREATE RPC SERVICE to generate the RPC project)
FEATURE ADDITIONAL  (no dependencies)
FEATURE MESSAGING
  └─► FEATURE USERS
        └─► FEATURE BASE
FEATURE INTEGRATIONS
  └─► FEATURE BASE
FEATURE LINKEDIN
  └─► FEATURE AUTH
        └─► FEATURE USERS ─► BASE
FEATURE CHATBOT     (no dependencies — standalone; composes with AUTH for user context)
FEATURE REDIS    ['<conn>']  (no dependencies — optional quoted connection string)
FEATURE RABBITMQ ['<conn>']  (no dependencies — optional quoted connection string)
```

> **Key distinction:** AUTH does NOT auto-include ORGANISATIONS. It is ORGANISATIONS that auto-includes AUTH (and therefore BASE + USERS). Writing `FEATURE AUTH` alone gives you auth without multi-tenancy; writing `FEATURE ORGANISATIONS` forces in the full auth stack.

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
| "send messages between users" / "chat" / "notifications" | `FEATURE MESSAGING` |
| "AI integration" / "MCP" | `CREATE MCP SERVICE;` (top-level command — **not** a `FEATURE`) |
| "Redis cache" | `FEATURE REDIS 'localhost:6379'` |
| "publish events" / "RabbitMQ" / "message broker" | `FEATURE RABBITMQ 'amqp://guest:guest@localhost:5672/'` plus `PUBLISH=RABBITMQ` on the table comment |
| "tags" / "custom metadata" / "key-value config" | `FEATURE ENTITYCONFIG` |
| "connect to Jira / Slack / GitHub / AWS" / "external integrations" / "sync with external system" | `FEATURE INTEGRATIONS` |
| "sign in with LinkedIn" / "LinkedIn login" / "social login" | `FEATURE LINKEDIN` (auto-includes `AUTH`) |
| "AI assistant" / "chatbot" / "in-app chat widget" | `FEATURE CHATBOT` (standalone; proxies to an MCP/AI service) |
| "no swagger" / "disable docs" | `FEATURE NOSWAGGER` |
| "most real-world apps" | `FEATURE AUTH` (auto-includes BASE + USERS) |
| "multi-tenant with login" | `FEATURE ORGANISATIONS` (auto-includes BASE + AUTH + USERS) |
