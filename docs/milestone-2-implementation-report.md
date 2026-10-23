# Milestone 2 implementation report

- Date: 2026-10-23
- Baseline: `f8bd0a2` on `feature/milestone-1-foundation-1023a`
- Scope: identity-linked tenant data and database-enforced authorization only

## Delivered

- Supabase CLI project configuration with a repository-specific PostgreSQL port
- ordered, forward-only migrations for profiles, organizations, locations, memberships, permissions, roles, role permissions, role assignments, plans, plan entitlements, subscriptions, and effective subscription entitlements
- profiles keyed to `auth.users`, including a safe profile-creation trigger and existing-user backfill
- immutable tenant identifiers and composite foreign keys for tenant-consistent relationships
- exact `numeric(12,2)` subscription prices and `numeric(20,6)` entitlement quantities
- organization- and location-scoped permission evaluation using active memberships
- boolean and numeric entitlement helpers that require an active member and a current subscription
- forced RLS and explicit grants on every public application table
- direct authenticated mutation denial for memberships, roles, permission mappings, plans, subscriptions, and entitlements
- local-only seed identities, tenant fixtures, roles, plan, subscription, and effective entitlements
- pgTAP schema and adversarial RLS integration tests using separate PostgreSQL request identities
- CI database job for clean migration replay, database lint, and integration tests
- architecture, security, environment, development, milestone, and ADR updates

No authentication UI, onboarding flow, invitations, application database adapter, organization shell, audit event module, Stripe behavior, or restaurant operations module was started.

## Security properties proved

The integration tests execute as actual PostgreSQL `authenticated` and `anon` roles with distinct JWT subject claims. They prove:

- authorized organization, location, subscription, and entitlement access
- cross-tenant organization, location, subscription, and entitlement denial
- cross-tenant write denial for both updates and inserts
- one user holding independent memberships in multiple organizations
- suspension overriding an otherwise privileged role and commercial entitlements
- location-scoped read and write access without access to sibling locations
- direct role, permission, membership, and entitlement escalation denial
- tenant-consistent role and subscription-entitlement foreign keys
- immutable tenant identifiers
- one current subscription per organization while retaining canceled subscription history
- profile isolation and anonymous denial

## Verification

All final commands completed with exit code 0.

| Command                                            | Exact result                                                                                                                                                                                                     |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pnpm install --frozen-lockfile`                   | 4 workspace projects; lockfile current; 642 packages restored; completed in 2.8 seconds with pnpm 11.25.0                                                                                                        |
| `pnpm peers check`                                 | `No peer dependency issues found`                                                                                                                                                                                |
| `pnpm db:verify`                                   | Database recreated from empty state; 2 migrations applied in order; seed loaded; database lint found no schema errors; security and performance advisors found no issues; 2 pgTAP files and 79 assertions passed |
| `supabase db diff --local --schema public,private` | Shadow database rebuilt from migrations; `No schema changes found`                                                                                                                                               |
| `pnpm format:check`                                | All matched files use Prettier code style                                                                                                                                                                        |
| `pnpm lint`                                        | ESLint completed with zero errors and zero warnings                                                                                                                                                              |
| `pnpm typecheck`                                   | 2 tasks successful; web and UI completed `tsc --noEmit`                                                                                                                                                          |
| `pnpm test`                                        | 1 Vitest file passed; 1 application test passed                                                                                                                                                                  |
| `pnpm build`                                       | 2 tasks successful; Next.js 16.4.3 compiled with Webpack; TypeScript passed; 3 static pages generated                                                                                                            |
| `pnpm check`                                       | Aggregate format, lint, type-check, application test, and production build sequence passed                                                                                                                       |
| `git diff --check`                                 | No whitespace errors                                                                                                                                                                                             |

The local verification used Supabase CLI 2.95.4 and PostgreSQL 17 in an isolated container on port 55322. GitHub Actions was updated but could not be executed remotely because the restored bundle has no hosted Git remote.

## Gate

Milestone 2 is complete. Milestone 3 requires explicit approval before authentication UI, onboarding, invitations, organization-shell work, or operational modules begin.
