# ADR 0003: SSR authentication and transactional tenant workflows

## Status

Accepted for Milestone 3.

## Context

RestaurantOS needs email authentication, server-rendered sessions, organization onboarding, tenant switching, location administration, and staff invitations without weakening the Milestone 2 row-level security boundary. Client-side session state, form-hidden identifiers, and cookies are attacker-controlled inputs. Ordinary requests must not use the Supabase service role.

## Decision

- Use `@supabase/ssr` with a fresh user-scoped client per request, HTTP-only same-site cookies, Proxy token refresh, `getClaims()` for the optimistic route boundary, and `getUser()` for fresh server identity checks.
- Treat organization and location cookies only as selectors. Resolve them against active memberships and RLS-visible rows on every request.
- Implement onboarding and invitation mutations as explicitly granted PostgreSQL security-definer functions with empty search paths. These functions validate `auth.uid()`, verified email, permissions, tenant-consistent references, expiry, recipient identity, and state transitions.
- Return invitation secrets once and persist only SHA-256 digests. Acceptance locks the invitation row and changes invitation, membership, and role assignment state in one transaction.
- Enforce active-location limits in PostgreSQL using exact numeric entitlements and a tenant-scoped advisory transaction lock. The dashboard reflects the same server-side entitlement source.
- Record organization, location, and invitation security events in an append-only tenant audit table protected by forced RLS.

## Consequences

The browser cannot use the auth token directly, which is intentional for the server-action architecture. A future client-side Supabase requirement must receive a separate security review before relaxing HTTP-only cookies. Custom email delivery remains outside this milestone; the application creates a secure link for an authorized administrator to deliver through an approved channel. Operational modules remain blocked by the next milestone gate.
