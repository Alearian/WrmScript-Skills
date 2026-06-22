# WRM Feature Assessment Guide

Use this guide in Step 2 to identify which WRM features best fit the user's requirements. Scan the user's description for the signals listed below. If the user explicitly names a feature, include it without question.

---

## Feature Signals

### BASE (00-base.psql)
**Tables created:** `base.tracking`, `base.event`, `base.gps`, `base.address`, `base.event_classes`, `base.event_types`

Signals:
- Audit trail, created/modified timestamps
- Address data
- GPS or geolocation data
- Event or activity logging
- Almost always needed — included automatically by all other features

**Note:** BASE is automatically included by ORGANISATIONS, USERS, AUTH, FILEHANDLING, and ENTITYCONFIG. Only specify it explicitly if the user needs BASE alone.

---

### ORGANISATIONS (10-organisations.psql + 35-neworg-rbac.psql)
**Tables created:** `organisation_types` (ENUM), `organisations`

Signals:
- Multiple clients, customers, tenants
- "Multi-tenant", "white-label", "SaaS"
- Data partitioned by company, organisation, club, school, charity
- Need to separate data between different client groups

Auto-includes: BASE, AUTH, USERS (adding ORGANISATIONS forces in the full authentication stack)

---

### USERS (20-users.psql)
**Tables created:** `users`, `user_profiles`, `user_communications`, `user_groups`, `user_group_members`, `user_events`, `sessions`, `session_events`

Signals:
- User accounts, login, registration
- Profiles, avatars, contact details
- User groups or teams
- Session tracking
- "People who use the system"

Auto-includes: BASE

---

### AUTH (30-authorisation.psql)
**Tables created:** `permissions`, `roles`, `user_roles`, `role_permissions`

Signals:
- Login / authentication
- Access control, who can do what
- Roles: admin, manager, viewer, editor
- Permissions on resources
- "Only certain users can..."
- RBAC, ACL, security

Auto-includes: USERS, BASE (not ORGANISATIONS — add that separately for multi-tenancy)

---

### ENTITYCONFIG (40-entityconfig.psql)
**Tables created:** `entity_configs`, `entity_allowed_tags`, `entity_tags`

Signals:
- Flexible metadata on entities
- Tags, labels, custom fields
- Key-value configuration per record
- "Custom attributes", "additional properties"
- Entity-level settings or preferences

Auto-includes: BASE

---

### FILEHANDLING (50-entityattachments.psql)
**Tables created:** `retention_policies`, `availability_policies`, `storage_types`, `attachments`, `entity_attachments`, `folders`

Signals:
- File upload, document storage
- Attachments to records (receipts, photos, certificates)
- Folder/directory structure
- Document versioning
- Retention or availability policies
- "Upload a file", "attach a document"

Auto-includes: ORGANISATIONS, USERS, BASE

---

### INTEGRATIONS (57-integrations.psql)
**Tables created:** `integration_connection_types` (ENUM), `integration_connections`, `integration_entity_mappings`

Signals:
- "Connect to Jira / GitHub / Slack / AWS / Azure / Salesforce"
- "Sync with an external system"
- "Track which local records correspond to external records"
- "Integration catalogue", "connection management", "external system mapping"
- Bi-directional sync, conflict detection, external record references
- When `FEATURE ORGANISATIONS` is active, connections are scoped per tenant

Auto-includes: BASE

---

### MESSAGING (80-messaging.psql)
**Tables created:** `wrm_messaging` schema — `messages`, `message_recipients`, `conversations`, `conversation_posts`, `notifications`, `send_states` (ENUM), `priorities` (ENUM), plus supporting tables (10 total)

Signals:
- "Users send messages to each other"
- Chat, conversations, threads
- System notifications to users
- Inbox, unread messages, delivery tracking

Auto-includes: USERS, BASE

---

## Feature Dependency Graph

```
AUTH ──────────────────────────────► USERS ──────► BASE

ORGANISATIONS ─────────────────────► BASE
  │                                   ▲
  ├──────────────────────────────► AUTH ─► USERS ─► BASE
  └──────────────────────────────► USERS ──────► BASE

FILEHANDLING ─────────────────────► ORGANISATIONS ─► (see above)
  │
  └──────────────────────────────► USERS ──────► BASE

SUBSCRIBERS ──────────────────────► AUTH ─► USERS ─► BASE
MULTIAPP    ──────────────────────► AUTH ─► USERS ─► BASE

ENTITYCONFIG ──────────────────────► BASE
INTEGRATIONS ──────────────────────► BASE
MESSAGING    ──────────────────────► USERS ──────► BASE

GRAPHQL     (standalone — no dependencies)
ADDITIONAL  (standalone)
REDIS       (standalone — optional connection string)
RABBITMQ    (standalone — optional connection string)
SOFT DELETE (standalone — auto-includes BASE)
HARD DELETE (standalone)
SWAGGER     (standalone — enabled by default)
NOSWAGGER   (standalone)
RPC         (standalone — but use CREATE RPC SERVICE to generate the RPC project)
```

> **Key distinction:** AUTH does NOT auto-include ORGANISATIONS. It is ORGANISATIONS that auto-includes AUTH (and transitively BASE + USERS). Writing `FEATURE AUTH` alone gives you authentication without multi-tenancy. Writing `FEATURE ORGANISATIONS` forces in the full auth stack.

When recommending AUTH, you automatically include: USERS, BASE.
When recommending ORGANISATIONS, you automatically include: BASE, AUTH, USERS.
When recommending FILEHANDLING, you automatically include: ORGANISATIONS, USERS, BASE (and AUTH transitively via ORGANISATIONS).
When recommending MESSAGING, you automatically include: USERS, BASE.

---

## .wrm Feature Keywords

The table below lists every valid `FEATURE` keyword accepted by the parser. Writing any other value raises *"Unknown feature"* and aborts the build.

| Feature | .wrm Keyword | Notes |
|---|---|---|
| BASE | `FEATURE BASE` | Auto-included by most other features |
| ORGANISATIONS | `FEATURE ORGANISATIONS` | Auto-includes BASE + AUTH + USERS (forces full auth stack) |
| USERS | `FEATURE USERS` | Auto-includes BASE |
| AUTH | `FEATURE AUTH` (or `FEATURE AUTHENTICATION`) | Auto-includes BASE + USERS (does NOT include ORGANISATIONS) |
| ENTITYCONFIG | `FEATURE ENTITYCONFIG` (or `FEATURE CONFIG`) | Auto-includes BASE |
| FILEHANDLING | `FEATURE FILEHANDLING` | Auto-includes BASE + ORGANISATIONS + USERS (and AUTH transitively) |
| GRAPHQL | `FEATURE GRAPHQL` | HotChocolate GraphQL layer |
| MULTIAPP | `FEATURE MULTIAPP` | Multi-application project layout; auto-includes AUTH (+ BASE + USERS) |
| SUBSCRIBERS | `FEATURE SUBSCRIBERS` | Event subscriber scaffolding; auto-includes BASE + USERS + AUTH |
| MESSAGING | `FEATURE MESSAGING` | Direct messages, conversations, notifications; auto-includes BASE + USERS |
| INTEGRATIONS | `FEATURE INTEGRATIONS` (or `FEATURE INTEGRATION`) | External-system connections + mappings; auto-includes BASE |
| ADDITIONAL | `FEATURE ADDITIONAL` | Additional controller scaffolding hooks |
| REDIS | `FEATURE REDIS ['<conn>']` | Distributed caching; optional quoted connection string |
| RABBITMQ | `FEATURE RABBITMQ ['<conn>']` | RabbitMQ publishing; optional quoted connection string |
| Swagger (default) | `FEATURE SWAGGER` | Enabled by default; explicit only if previously disabled |
| Disable Swagger | `FEATURE NOSWAGGER` | Disables Swagger/OpenAPI |
| Soft delete | `FEATURE SOFT DELETE` | `is_deleted` column; auto-includes BASE; mutually exclusive with HARD DELETE |
| Hard delete | `FEATURE HARD DELETE` | Physical row removal; mutually exclusive with SOFT DELETE |

> ⚠️ **Not features:** `MCP`, `AZURE`, `FORMS`, and `SUBSCRIPTIONS` are **not** valid `FEATURE` keywords. MCP is enabled via `CREATE MCP SERVICE/CONTROLLERS`; Azure via `CREATE AZURE CONTAINER/FUNCTIONS`. Using them as `FEATURE` lines raises a parse error. Note: `FEATURE RPC` IS accepted by the parser but the actual RPC project is generated by `CREATE RPC SERVICE/CONTROLLERS` — you rarely need to write `FEATURE RPC` explicitly.

---

## Feature → SQL Script Mapping

| Feature | Script |
|---|---|
| BASE | `00-base.psql` |
| ORGANISATIONS | `10-organisations.psql`, `35-neworg-rbac.psql` |
| USERS | `20-users.psql` |
| AUTH | `30-authorisation.psql` |
| ENTITYCONFIG | `40-entityconfig.psql` |
| FILEHANDLING | `50-entityattachments.psql` |
| INTEGRATIONS | `57-integrations.psql` |
| MULTIAPP | `65-multiapp.psql` |
| SUBSCRIBERS | `70-subscriptions.psql` |
| MESSAGING | `80-messaging.psql` |
| PostGIS/pgcrypto | `90-extensions.psql` |

WRM runs these feature scripts automatically at build time based on the `FEATURE` directives in the `.wrm` file. The user does **not** need to include `DATABASE RUN` for these — only for their own SQL files.
