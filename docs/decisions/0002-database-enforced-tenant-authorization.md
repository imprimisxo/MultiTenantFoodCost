# ADR 0002: Enforce tenant authorization in PostgreSQL

- Status: accepted
- Date: 2026-10-23

## Context

Organization and location data will be reached from browser and server workflows over time. Application-only filters are too easy to omit, especially for nested records, guessed identifiers, background jobs, or future modules. Authorization must also represent users who belong to multiple organizations and roles limited to one location.

## Decision

Use the organization as the primary tenant boundary and carry its immutable identifier on every tenant-owned row. Use composite foreign keys whenever one tenant-owned table references another so PostgreSQL rejects mixed-tenant relationships before policy evaluation.

Enable and force RLS on every public application table. Resolve active membership and permission scope through security-definer functions in the unexposed `private` schema. These functions pin an empty search path, schema-qualify every relation, check `auth.uid()`, and expose only boolean or numeric authorization answers.

Grant authenticated users only the operations and columns supported by current workflows. Membership, role, permission mapping, subscription, plan, and entitlement mutations remain service-owned until dedicated, audited commands are approved. The service role is not an ordinary request path.

Keep permission names as migration-managed data. Keep plan and entitlement examples in the local seed until commercial configuration is approved. Snapshot exact subscription price and effective entitlement values so later plan edits do not rewrite historical commercial state.

## Consequences

- A missing membership, inactive membership, role, location scope, or entitlement denies access.
- One identity can participate in multiple tenants without tenant IDs in editable JWT metadata.
- Tenant reassignment requires creating a new row; protected identifiers cannot be updated in place.
- Management workflows require narrow server operations rather than direct table writes.
- Authorization changes require PostgreSQL integration tests under real request roles.
- RLS helpers bypass recursive policy evaluation, so function ownership, search paths, grants, and return values require security review.
