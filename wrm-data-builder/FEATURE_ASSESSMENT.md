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

### ORGANISATIONS (10-organisations.psql)
**Tables created:** `organisation_types` (ENUM), `organisations`

Signals:
- Multiple clients, customers, tenants
- "Multi-tenant", "white-label", "SaaS"
- Data partitioned by company, organisation, club, school, charity
- Need to separate data between different client groups

Auto-includes: BASE

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

### AUTH (30-authorisation.psql + 35-neworg-rbac.psql)
**Tables created:** `permissions`, `roles`, `user_roles`, `role_permissions`

Signals:
- Login / authentication
- Access control, who can do what
- Roles: admin, manager, viewer, editor
- Permissions on resources
- "Only certain users can..."
- RBAC, ACL, security

Auto-includes: USERS, ORGANISATIONS, BASE

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

### FORMS (60-formmanagement.psql)
**Tables created:** `form_definitions`, `field_definitions`

Signals:
- Dynamic/configurable forms
- Forms whose fields change per organisation or use case
- Survey or questionnaire builder
- "Custom forms", "configurable fields", "dynamic data entry"
- Field types: text, checkbox, dropdown, photo, signature, location

Auto-includes: nothing (standalone)

---

### SUBSCRIPTIONS (70-subscriptions.psql)
**Tables created:** `subscription_tiers` (ENUM, pre-seeded: Free/Pro/Enterprise), `user_subscriptions`

Signals:
- Subscription plans, tiers, pricing
- Free/paid/premium access levels
- SaaS billing, feature gating by tier
- "Subscription", "plan", "pricing tier"

Auto-includes: USERS (implicitly — subscriptions are linked to users)

---

## Feature Dependency Graph

```
AUTH ─────────────────► USERS ──────► BASE
  │                       │
  └──────────────────► ORGANISATIONS ─► BASE

FILEHANDLING ─────────► ORGANISATIONS ─► BASE
  │                       │
  └──────────────────► USERS ──────► BASE

ENTITYCONFIG ──────────────────────► BASE
ORGANISATIONS ─────────────────────► BASE
USERS ─────────────────────────────► BASE
FORMS ─────────────────────────────► (standalone)
SUBSCRIPTIONS ─────────────────────► (requires USERS tables)
```

When recommending AUTH, you automatically include: USERS, ORGANISATIONS, BASE.
When recommending FILEHANDLING, you automatically include: ORGANISATIONS, USERS, BASE.

---

## .wrm Feature Keywords

| Feature | .wrm Keyword |
|---|---|
| BASE | `FEATURE BASE` |
| ORGANISATIONS | `FEATURE ORGANISATIONS` |
| USERS | `FEATURE USERS` |
| AUTH | `FEATURE AUTH` |
| ENTITYCONFIG | `FEATURE ENTITYCONFIG` |
| FILEHANDLING | `FEATURE FILEHANDLING` |
| FORMS | `FEATURE FORMS` |
| SUBSCRIPTIONS | `FEATURE SUBSCRIPTIONS` |
| GraphQL API | `FEATURE GRAPHQL` |
| MCP server | `FEATURE MCP` |
| OpenAPI/Swagger | `FEATURE SWAGGER` (default on) |
| Soft delete | `FEATURE SOFT DELETE` |
| Hard delete | `FEATURE HARD DELETE` |

---

## Feature → SQL Script Mapping

| Feature | Script |
|---|---|
| BASE | `00-base.psql` |
| ORGANISATIONS | `10-organisations.psql` |
| USERS | `20-users.psql` |
| AUTH | `30-authorisation.psql`, `35-neworg-rbac.psql` |
| ENTITYCONFIG | `40-entityconfig.psql` |
| FILEHANDLING | `50-entityattachments.psql` |
| FORMS | `60-formmanagement.psql` |
| SUBSCRIPTIONS | `70-subscriptions.psql` |
| PostGIS/pgcrypto | `90-extensions.psql` |

WRM runs these feature scripts automatically at build time based on the `FEATURE` directives in the `.wrm` file. The user does **not** need to include `DATABASE RUN` for these — only for their own SQL files.
