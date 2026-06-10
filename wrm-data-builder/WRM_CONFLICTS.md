# WRM Reserved Column Names

When a user defines a column whose name matches one of these reserved names, a conflict must be raised and resolved interactively before generating SQL. Never silently drop or rename — always ask.

---

## Columns from `base.tracking` (via `LIKE base.tracking`)

Active when: any WRM feature except standalone ENUM tables uses `LIKE base.tracking`.

| Column | Type | Source |
|---|---|---|
| `created_at` | `TIMESTAMPTZ NOT NULL` | base.tracking |
| `updated_at` | `TIMESTAMPTZ` | base.tracking |
| `is_deleted` | `BOOLEAN NOT NULL DEFAULT FALSE` | base.tracking (SOFT DELETE only) |
| `created_by` | `INTEGER` | base.tracking (added by USERS feature) |
| `updated_by` | `INTEGER` | base.tracking (added by USERS feature) |

---

## Columns from `base.address` (via `LIKE base.address`)

Active when: user table includes `LIKE base.address`.

| Column | Type |
|---|---|
| `address_line_1` | `VARCHAR` |
| `address_line_2` | `VARCHAR` |
| `town_city` | `VARCHAR` |
| `county` | `VARCHAR` |
| `postcode` | `VARCHAR` |
| `country_code` | `VARCHAR` |

---

## Columns from `base.gps` (via `LIKE base.gps`)

Active when: user table includes `LIKE base.gps`.

| Column | Type |
|---|---|
| `latitude` | `DOUBLE PRECISION` |
| `longitude` | `DOUBLE PRECISION` |
| `altitude` | `DOUBLE PRECISION` |

---

## Columns injected by ORGANISATIONS feature (10-organisations.psql)

Active when: `FEATURE ORGANISATIONS` (or any feature that depends on it: AUTH, FILEHANDLING).

Reserved table names (do not create user tables with these names):
- `organisation_types`
- `organisations`

Reserved FK column name added to standard tables:
| Column | Notes |
|---|---|
| `organisation_id` | Added to most entities to support multi-tenancy |

---

## Columns injected by USERS feature (20-users.psql)

Active when: `FEATURE USERS` (or AUTH, FILEHANDLING).

Reserved table names:
- `users`
- `user_profiles`
- `user_communications`
- `user_groups`
- `user_group_members`
- `user_events`
- `sessions`
- `session_events`

Reserved column names on base.tracking (added by USERS):
| Column | Notes |
|---|---|
| `created_by` | Added to base.tracking when USERS is active |
| `updated_by` | Added to base.tracking when USERS is active |

Commonly used FK column (not auto-injected but frequently referenced):
| Column | Notes |
|---|---|
| `user_id` | FK to users.user_id — user-defined tables may add this manually |

---

## Columns injected by AUTH feature (30-authorisation.psql)

Active when: `FEATURE AUTH`.

Reserved table names:
- `permissions`
- `roles`
- `user_roles`
- `role_permissions`

Common FK columns that conflict:
| Column | Notes |
|---|---|
| `role_id` | FK to roles.role_id |
| `permission_id` | FK to permissions.permission_id |

---

## Columns injected by ENTITYCONFIG feature (40-entityconfig.psql)

Active when: `FEATURE ENTITYCONFIG`.

Reserved table names:
- `entity_configs`
- `entity_allowed_tags`
- `entity_tags`

---

## Columns injected by FILEHANDLING feature (50-entityattachments.psql)

Active when: `FEATURE FILEHANDLING`.

Reserved table names:
- `retention_policies`
- `availability_policies`
- `storage_types`
- `attachments`
- `entity_attachments`
- `folders`

Common FK columns that conflict:
| Column | Notes |
|---|---|
| `attachment_id` | FK to attachments.attachment_id |
| `folder_id` | FK to folders.folder_id |
| `storage_type_id` | FK to storage_types.storage_type_id |
| `retention_policy_id` | FK to retention_policies.retention_policy_id |
| `availability_policy_id` | FK to availability_policies.availability_policy_id |

---

## Columns injected by INTEGRATIONS feature (57-integrations.psql)

Active when: `FEATURE INTEGRATIONS`.

Reserved table names:
- `integration_connection_types`
- `integration_connections`
- `integration_entity_mappings`

Common FK columns that conflict:
| Column | Notes |
|---|---|
| `integration_connection_type_id` | FK to integration_connection_types |
| `integration_connection_id` | FK to integration_connections |

---

## Columns injected by FORMS feature (60-formmanagement.psql)

Active when: `FEATURE FORMS`.

Reserved table names:
- `form_definitions`
- `field_definitions`

---

## Columns injected by SUBSCRIPTIONS feature (70-subscriptions.psql)

Active when: `FEATURE SUBSCRIPTIONS`.

Reserved table names:
- `subscription_tiers`
- `user_subscriptions`

---

## Conflict Resolution Script

When a conflict is detected, present this message to the user (fill in the placeholders):

```
Your table `{user_table}` defines a column `{column_name}` that conflicts with WRM's
{FEATURE_NAME} feature. This column is provided by `{source}` ({source_description}).

How would you like to handle this?

A) Use WRM's version — remove your definition (recommended)
   The column will still exist in your table via the {source} LIKE clause / feature schema.

B) Rename yours to `{user_table}_{column_name}` and keep both columns
   Your column will be added alongside WRM's version.

C) Keep only yours and skip the WRM-provided one
   Note: this may break WRM feature functionality that depends on this column.

D) Something else — describe what you need
```

Await the user's response before generating any SQL.
