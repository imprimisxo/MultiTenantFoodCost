# RestaurantOS SaaS foundation

Milestone 1 of a production-oriented, multi-tenant restaurant management SaaS. This repository establishes the application shell, package boundaries, shared interface system, engineering standards, and continuous integration needed before tenant data is introduced.

> **Scope boundary:** no database schema, migrations, row-level security policies, Supabase authentication, organizations, memberships, roles, permissions, subscriptions, or entitlements are implemented in this milestone.

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
```

The repository uses pnpm workspaces and Turborepo. Workspace imports are explicit (`@workspace/ui` and `@workspace/typescript-config`), which keeps the modular-monolith boundaries visible and enforceable.

## Prerequisites

- Node.js 24 LTS or newer
- pnpm 11.25.0

## Start locally

```bash
pnpm install
cp .env.example apps/web/.env.local
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000). The Milestone 1 app does not read the future database, Supabase, or Stripe values, so placeholder values are sufficient for the foundation screen.

## Verify

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Run every check in sequence with `pnpm check`. GitHub Actions runs the same gates on pull requests and pushes to `main`.

## Add interface components

Both the web and UI workspaces include `components.json`, so the shadcn CLI can route shared primitives correctly:

```bash
pnpm exec shadcn add input -c apps/web
```

Reusable primitives belong in `packages/ui`; app-specific compositions remain in `apps/web`.

## Documentation

- [Architecture](docs/architecture.md)
- [Development workflow](docs/development.md)
- [Milestone 1 implementation report](docs/implementation-report.md)
- [Milestone gates](docs/milestones.md)
- [Security baseline](docs/security.md)
- [Modular-monolith decision](docs/decisions/0001-modular-monolith.md)

## Current status

Milestone 1 only. See `docs/milestones.md` before expanding scope.
