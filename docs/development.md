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

## First run

```bash
pnpm install
cp .env.example apps/web/.env.local
pnpm dev
```

The web app is served at `http://localhost:3000` by default. No external service is called in Milestone 1.

## Commands

| Command             | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `pnpm dev`          | Run persistent development tasks              |
| `pnpm format`       | Apply repository formatting                   |
| `pnpm format:check` | Verify formatting without changing files      |
| `pnpm lint`         | Run ESLint with warnings treated as failures  |
| `pnpm typecheck`    | Type-check every workspace                    |
| `pnpm test`         | Run automated tests                           |
| `pnpm build`        | Create production builds                      |
| `pnpm check`        | Run every required verification gate in order |

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
