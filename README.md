# RestaurantOS SaaS

Milestone 2 of a production-oriented, multi-tenant restaurant management SaaS. The repository now includes a versioned Supabase/PostgreSQL tenant model, database-enforced authorization, local fixtures, and adversarial RLS tests alongside the Milestone 1 application foundation.

> **Scope boundary:** this milestone implements identity-linked data and database authorization only. Authentication UI, onboarding, invitations, operational restaurant modules, and external billing behavior remain deferred.

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
pnpm db:start
pnpm db:verify
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000). The application UI remains the foundation screen; Milestone 3 will connect session and onboarding flows to this schema.

The local PostgreSQL instance uses port `55322` to avoid colliding with the Supabase default. `pnpm db:verify` rebuilds it from the migrations and seed, lints stored functions, and runs the pgTAP suite. The local-only fixture password is `local-password-only` for both `owner@example.test` and `manager@example.test`.

## Verify

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm db:verify
```

Run the application checks in sequence with `pnpm check`. Run `pnpm db:verify` while the local database is running. GitHub Actions runs both sets of gates on pull requests and pushes to `main`.

## Add interface components

Both the web and UI workspaces include `components.json`, so the shadcn CLI can route shared primitives correctly:

```bash
pnpm exec shadcn add input -c apps/web
```

Reusable primitives belong in `packages/ui`; app-specific compositions remain in `apps/web`.

## Documentation

- [Architecture](docs/architecture.md)
- [Development workflow](docs/development.md)
- [Milestone 2 implementation report](docs/milestone-2-implementation-report.md)
- [Milestone gates](docs/milestones.md)
- [Security baseline](docs/security.md)
- [Modular-monolith decision](docs/decisions/0001-modular-monolith.md)
- [Tenant authorization decision](docs/decisions/0002-database-enforced-tenant-authorization.md)

## Current status

Milestone 2 is complete. Milestone 3 requires explicit approval before authentication UI, onboarding, invitations, or organization-shell work begins.
