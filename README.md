# RestaurantOS SaaS

Milestone 3 of a production-oriented, multi-tenant restaurant management SaaS. The repository includes Supabase Auth with secure SSR cookies, transactional organization onboarding, authorized organization and location context, staff invitations, an entitlement-aware dashboard, and database-enforced tenant isolation.

> **Scope boundary:** recipes, costing, inventory, purchasing, POS integrations, external billing behavior, and every other operational restaurant module remain deferred.

## Workspace

```text
apps/
  web/                    Next.js App Router application
packages/
  ui/                     Shared shadcn/ui-compatible primitives and theme
  typescript-config/      Shared strict TypeScript configuration
docs/
  architecture.md         Approved architecture recorded as implementation rules
  development.md          Local setup and daily workflows
  milestone-3-implementation-report.md
  milestones.md           Delivery gates and deferred scope
supabase/
  migrations/             Ordered schema and RLS migrations
  tests/database/         PostgreSQL and RLS integration tests
  seed.sql                Local-only identities and tenant fixtures
```

The repository uses pnpm workspaces and Turborepo. Workspace imports are explicit (`@workspace/ui` and `@workspace/typescript-config`), which keeps the modular-monolith boundaries visible and enforceable.

## Prerequisites

- Node.js 24 LTS or newer
- pnpm 11.25.0
- Supabase CLI 2.95.4
- Docker-compatible container runtime

## Start locally

```bash
pnpm install
cp .env.example apps/web/.env.local
supabase start
pnpm db:verify
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000). Sign in with `owner@example.test` and the local-only password `local-password-only`, or use `new-owner@example.test` to exercise first-organization onboarding.

The local PostgreSQL instance uses port `55322` to avoid colliding with the Supabase default. `pnpm db:verify` rebuilds it from the migrations and seed, lints stored functions, runs security advisors, and executes the pgTAP suites. Local Auth also contains `manager@example.test`, `invitee@example.test`, and `attacker@example.test` for scoped and adversarial browser journeys.

## Verify

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm db:verify
pnpm test:e2e
```

Run the application checks in sequence with `pnpm check`. Run `pnpm db:verify` with the local database available. Run `pnpm test:e2e` with the full local Supabase stack running and its `API_URL`/`ANON_KEY` exported as the two public Supabase environment variables described in the development guide. GitHub Actions runs application, database, and browser gates separately.

## Add interface components

Both the web and UI workspaces include `components.json`, so the shadcn CLI can route shared primitives correctly:

```bash
pnpm exec shadcn add input -c apps/web
```

Reusable primitives belong in `packages/ui`; app-specific compositions remain in `apps/web`.

## Documentation

- [Architecture](docs/architecture.md)
- [Development workflow](docs/development.md)
- [Milestone 3 implementation report](docs/milestone-3-implementation-report.md)
- [Milestone gates](docs/milestones.md)
- [Security baseline](docs/security.md)
- [Modular-monolith decision](docs/decisions/0001-modular-monolith.md)
- [Tenant authorization decision](docs/decisions/0002-database-enforced-tenant-authorization.md)
- [SSR auth and tenant workflow decision](docs/decisions/0003-ssr-auth-and-tenant-workflows.md)

## Current status

Milestone 3 implementation is complete. Milestone 4 requires explicit approval before recipes, costing, or any operational module begins.
