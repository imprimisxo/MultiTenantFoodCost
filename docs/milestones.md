# Delivery milestones

Each milestone is an approval gate. Starting a later milestone requires an explicit scope review; completing an earlier milestone does not implicitly authorize later work.

## Milestone 1 — engineering foundation (current)

- pnpm modular monorepo
- Next.js, TypeScript, Tailwind CSS, and shadcn/ui-compatible UI foundation
- shared configuration and package boundaries
- environment variable template
- architecture, security, and development documentation
- repository instructions in `AGENTS.md`
- initial test and GitHub Actions verification

Explicitly excluded: database schema, migrations, seed data, Supabase clients/authentication, RLS, tenant entities, application authorization, onboarding, dashboards, subscriptions, and restaurant operations modules.

## Milestone 2 — identity and tenant data (requires approval)

- PostgreSQL migration tooling and local database workflow
- users/profiles, organizations, locations, memberships, roles, permissions, subscriptions, and entitlements schema
- Supabase Auth server integration
- database-enforced RLS and least-privilege database roles
- server authorization primitives
- seed fixtures and automated cross-tenant isolation tests

Exit gate: adversarial tests prove that users cannot read or mutate another organization's data, including through guessed identifiers and nested resources.

## Milestone 3 — onboarding and organization shell

- create an organization and first location transactionally
- invite and membership flows
- organization dashboard and accessible location switcher
- permission- and entitlement-aware navigation
- audit events for security-sensitive changes

## Milestone 4 — recipes and costing

- ingredients, units, conversions, recipes, sub-recipes, yields, and price history
- exact decimal calculations and explicit rounding policies
- versioned cost rollups and test fixtures

## Milestone 5 — inventory and purchasing

- counts, adjustments, transfers, par levels, vendors, purchase orders, receipts, and invoice matching
- transactional stock movement ledger
- reconciliation and audit reporting

## Milestone 6 — subscriptions and external integrations

- Stripe checkout, portal, signed webhooks, and entitlement synchronization
- POS/vendor adapter contracts, idempotent imports, retries, and reconciliation
- operational monitoring, rate limits, and recovery procedures

The sequence may be refined by a later approved proposal, but security and exact-number exit gates remain mandatory.
