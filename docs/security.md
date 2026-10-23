# Security baseline

## Milestone 1 posture

This milestone contains no authentication flow, privileged service client, database connection, tenant data, or payment processing. The environment template reserves future variables while keeping all secret names server-only.

## Non-negotiable controls for later milestones

- PostgreSQL row-level security on every tenant-owned table
- deny-by-default server authorization for organization, location, permission, and entitlement scope
- server-verified Supabase sessions; client state is never authorization evidence
- least-privilege database roles and narrowly scoped service-role use
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
