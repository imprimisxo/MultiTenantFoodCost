# Development workflow

## Toolchain

- Node.js 24 LTS or newer
- pnpm 11.25.0 (pinned by the root `packageManager` field)
- Next.js App Router
- TypeScript strict mode
- Tailwind CSS v4 and shadcn/ui-compatible source components
- Vitest and Testing Library
- ESLint and Prettier
- Turborepo task orchestration
- Supabase CLI 2.95.4 and a Docker-compatible runtime for PostgreSQL tests

## First run

```bash
pnpm install
cp .env.example apps/web/.env.local
supabase start
supabase status -o env
pnpm db:verify
pnpm dev
```

The web app is served at `http://localhost:3000` by default. Local PostgreSQL listens on port `55322`; this repository-specific port avoids the default Supabase port used by other projects.

## Commands

| Command             | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `pnpm dev`          | Run persistent development tasks              |
| `pnpm format`       | Apply repository formatting                   |
| `pnpm format:check` | Verify formatting without changing files      |
| `pnpm lint`         | Run ESLint with warnings treated as failures  |
| `pnpm typecheck`    | Type-check every workspace                    |
| `pnpm test`         | Run unit and component tests                  |
| `pnpm test:e2e`     | Run Playwright auth and tenant journeys       |
| `pnpm build`        | Create production builds                      |
| `pnpm check`        | Run every required verification gate in order |
| `pnpm db:start`     | Start the isolated local PostgreSQL database  |
| `pnpm db:reset`     | Rebuild PostgreSQL from migrations and seed   |
| `pnpm db:lint`      | Validate stored database functions            |
| `pnpm db:advisors`  | Check database security and performance       |
| `pnpm db:test`      | Run pgTAP schema and RLS integration tests    |
| `pnpm db:verify`    | Reset, inspect, lint, and test the database   |
| `pnpm db:stop`      | Stop this repository's local services         |

## Database changes

Create forward-only, timestamped SQL files in `supabase/migrations`. Never edit a migration that has reached a shared environment; add a new migration instead. Keep production-safe schema and authorization data in migrations. Keep disposable local identities and example tenants in `supabase/seed.sql`.

Every tenant-owned table carries `organization_id`, and foreign keys that cross tenant-owned tables include that identifier. Every public table has forced RLS. Normal requests run as `authenticated`; do not use the service role to bypass policies for user traffic.

The integration tests live in `supabase/tests/database`. They set real PostgreSQL roles and JWT claims, so an allowed or denied assertion exercises table grants, RLS policies, and helper functions together. `pnpm db:verify` also fails on Supabase advisor warnings so missing RLS and common indexing or function-security mistakes do not silently enter CI.

For browser tests, start the full local stack and export the CLI values without committing them:

```bash
eval "$(supabase status -o env)"
export NEXT_PUBLIC_SUPABASE_URL="$API_URL"
export NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$ANON_KEY"
pnpm test:e2e
```

Local auth requires email confirmation, has a 24-hour absolute session limit, and expires sessions after eight hours of inactivity. Inbucket captures local verification and recovery mail. The application stores Supabase sessions in HTTP-only, same-site cookies and does not use the service role for user traffic.

The production build uses Next.js's supported Webpack mode for portability in restricted build environments. Development can still use the Next.js default compiler. Re-evaluate this pin when the Turbopack CSS worker no longer requires an internal loopback port in managed sandboxes.

## Environment files

`.env.example` is the committed contract. Copy it to `apps/web/.env.local` for local work. Values without the `NEXT_PUBLIC_` prefix are server-only. Never rename a secret to add that prefix.

When a variable is added:

1. Decide whether browser code truly requires it.
2. Add a safe placeholder and explanation to `.env.example`.
3. Configure the real value in the deployment environment.
4. Validate it at the server boundary before first use.

## Package ownership

- Put route-level composition in `apps/web/src/app`.
- Put reusable interface primitives in `packages/ui/src/components`.
- Put UI helpers in `packages/ui/src/lib`.
- Do not add a domain package until its owning milestone defines a cohesive responsibility and public API.

The shadcn CLI is configured in both workspaces. Run component additions from the repository root with the web workspace as context:

```bash
pnpm exec shadcn add dialog -c apps/web
```

Review generated code and dependencies before committing it.

## Change checklist

1. Confirm the work is within the approved milestone.
2. Make the smallest coherent change behind an explicit boundary.
3. Add or update tests.
4. Run the relevant focused checks while iterating.
5. Run `pnpm check` before handoff.
6. Record material architecture decisions in `docs/decisions`.
