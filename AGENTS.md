# Repository instructions

These rules apply to every contributor and coding agent working in this repository.

## Architecture

- Build a modular monolith. Keep one deployable web application while separating capabilities through explicit workspace and module boundaries.
- Keep framework code in `apps/web`, reusable interface primitives in `packages/ui`, and shared compiler policy in `packages/typescript-config`.
- When domain modules are approved, expose narrow public entry points. Do not import another module's internal files.
- Domain rules must not depend on Next.js, Supabase, Stripe, or a UI package. Infrastructure adapts external services to domain-owned interfaces.
- Prefer server components. Add `"use client"` only at the smallest interactive boundary.
- Milestones 1–3 are implemented. Do not begin recipes, costing, inventory, purchasing, POS integrations, external billing, or another operational module without the next explicit milestone approval.

## Tenant and security requirements

- Treat the organization as the primary tenant boundary and locations as organization-owned children.
- Tenant isolation must be enforced in PostgreSQL row-level security, not only in application queries.
- Every tenant-owned row must carry an immutable organization identifier unless the approved data model documents a stronger inherited boundary.
- Server-side authorization is mandatory even when the UI hides an action. Authentication never implies authorization.
- Default to deny. A missing membership, permission, location scope, subscription entitlement, or tenant context must reject the operation.
- Never expose a Supabase service-role key, Stripe secret, database URL, or webhook secret to browser code. Only variables prefixed with `NEXT_PUBLIC_` may be imported by client components.
- Service-role access is reserved for narrowly scoped server-side administration and background jobs; it must not back normal user requests.
- Use a fresh `@supabase/ssr` server client per request. Validate identity with `getUser()` or `getClaims()`; never authorize from `getSession()` data alone.
- Keep auth and tenant-context cookies HTTP-only, secure in production, same-site, and server-managed. Revalidate organization, location, permission, membership status, and entitlement at every mutation boundary.
- Store invitation secrets only as cryptographic digests. Never log or persist a plaintext invitation token after presenting the one-time link to its creator.
- Validate webhook signatures and make integration handlers idempotent before accepting external events.
- Do not log tokens, secrets, payment details, or sensitive personal data.

## Money and quantities

- Never use JavaScript floating-point arithmetic for money, recipe quantities, inventory quantities, yields, conversion factors, or costs.
- Persist exact values with PostgreSQL `numeric` using reviewed precision and scale.
- Represent exact decimal values as strings at API and serialization boundaries. Use an approved decimal library for calculations once the costing module is introduced.
- Store currency as an explicit ISO 4217 code alongside monetary values. Do not assume a global currency.

## Testing

- Add or update tests with each behavior change.
- Tenant-aware work is incomplete until tests prove cross-organization access is denied at both the service and database-policy layers.
- Favor deterministic unit tests for domain rules, integration tests for database/RLS behavior, and a small number of end-to-end tests for critical journeys.
- Never claim a feature works without running the relevant check. Report the exact command and outcome.
- Required repository gates are `pnpm format:check`, `pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build`, and `pnpm db:verify`. Run `pnpm test:e2e` for auth, onboarding, or organization-shell changes.

## Code standards

- TypeScript strict mode stays enabled. Do not use `any`, non-null assertions, or blanket lint suppressions to bypass a design problem.
- Validate untrusted data at system boundaries. Keep validated types distinct from raw input types.
- Use semantic HTML and preserve keyboard, focus, label, and contrast accessibility.
- Prefer small named functions, explicit return types at public boundaries, and immutable data.
- Keep secrets out of source control. Update `.env.example` with safe placeholders when configuration changes.
- Use conventional commit subjects when committing: `type(scope): imperative summary`.

## Dependency and change discipline

- Use pnpm only. Do not introduce a second package manager or lockfile.
- Add dependencies to the workspace that imports them; do not rely on accidental hoisting.
- Preserve package boundaries and avoid deep relative imports between workspaces.
- Record meaningful architecture decisions in `docs/decisions`.
- Keep changes inside the approved milestone. If a request crosses a milestone gate, stop and request approval.
