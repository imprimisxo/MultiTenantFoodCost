# Security baseline

## Milestone 2 posture

The database schema is ready for Supabase identities, but the application still contains no authentication UI or privileged client. PostgreSQL is the final authorization boundary: public tables have forced RLS, tenant policies derive identity from `auth.uid()`, and normal users receive only the table and column grants needed by an allowed workflow.

Tenant membership, permission, location scope, and subscription entitlement checks run in security-definer functions in the unexposed `private` schema. Those functions use an empty search path, schema-qualified relations, explicit execute grants, active-membership checks, and no user-editable JWT authorization metadata.

Direct authenticated writes to memberships, roles, role assignments, permission mappings, plans, subscriptions, and entitlements are denied. Future management workflows must use reviewed server-side operations that preserve the same invariants; Milestone 3 must not weaken these table grants for convenience.

## Implemented controls

- PostgreSQL row-level security on every tenant-owned table
- forced RLS and explicit least-privilege grants on every public table
- active-membership, permission, location, and entitlement helper functions
- immutable tenant identifiers and tenant-consistent composite foreign keys
- exact numeric persistence for subscription prices and entitlement quantities
- adversarial PostgreSQL tests using distinct authenticated identities

## Non-negotiable controls for later milestones

- server-verified Supabase sessions; client state is never authorization evidence
- signed and idempotent webhook processing
- CSRF, redirect, cookie, and cache behavior reviewed at each server mutation boundary
- structured audit events for membership, role, billing, integration, and inventory changes
- no secrets or sensitive payloads in logs
- automated negative tests for cross-tenant reads and writes

## Environment classification

| Prefix/example                                | Classification                                  | Allowed in browser bundle |
| --------------------------------------------- | ----------------------------------------------- | ------------------------- |
| `NEXT_PUBLIC_APP_URL`                         | Public configuration                            | Yes                       |
| `NEXT_PUBLIC_SUPABASE_URL`                    | Public service endpoint                         | Yes                       |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`        | Public publishable credential, protected by RLS | Yes                       |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`          | Public publishable credential                   | Yes                       |
| `DATABASE_URL` / `DIRECT_URL`                 | Secret                                          | No                        |
| `SUPABASE_SERVICE_ROLE_KEY`                   | Highly privileged secret                        | No                        |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` | Secret                                          | No                        |

The word “public” does not remove the need for RLS or server authorization. Publishable Supabase credentials identify a project; they do not protect tenant rows.

## Reporting

Do not open a public issue containing a suspected vulnerability, credential, or customer data. Use the repository owner's private security reporting channel once one is configured before production launch.
