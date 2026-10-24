# Security baseline

## Milestone 3 posture

The application uses Supabase Auth through `@supabase/ssr`, server actions, HTTP-only same-site cookies, PKCE-compatible callback exchange, and a Next.js Proxy refresh boundary. Protected pages validate the current user on the server. PostgreSQL remains the final authorization boundary: public tables have forced RLS, tenant policies derive identity from `auth.uid()`, and normal users receive only the grants needed by an allowed workflow.

Tenant membership, permission, location scope, and subscription entitlement checks run in security-definer functions in the unexposed `private` schema. Those functions use an empty search path, schema-qualified relations, explicit execute grants, active-membership checks, and no user-editable JWT authorization metadata.

Direct authenticated writes to memberships, roles, role assignments, permission mappings, plans, subscriptions, entitlements, invitations, and audit events are denied. Transactional security-definer functions handle onboarding and invitation state changes after verified-email, permission, recipient, expiry, status, and tenant checks. Location writes retain user-scoped RLS and add a database trigger that enforces the exact numeric active-location entitlement under an advisory transaction lock.

## Implemented controls

- PostgreSQL row-level security on every tenant-owned table
- forced RLS and explicit least-privilege grants on every public table
- active-membership, permission, location, and entitlement helper functions
- immutable tenant identifiers and tenant-consistent composite foreign keys
- exact numeric persistence for subscription prices and entitlement quantities
- adversarial PostgreSQL tests using distinct authenticated identities
- expiring invitation tokens persisted only as SHA-256 digests
- single-use invitation acceptance bound to the verified recipient email
- structured tenant audit events for onboarding, location, and invitation changes
- 24-hour absolute and eight-hour idle session limits in local Supabase configuration

## Non-negotiable controls for later milestones

- server-verified Supabase sessions; client state and context cookies are never authorization evidence
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
