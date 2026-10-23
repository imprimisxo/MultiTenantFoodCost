# ADR 0001: Begin as a modular monolith

- Status: accepted
- Date: 2026-10-23

## Context

The product will serve multi-location restaurant companies across tightly related workflows. Recipe costing affects inventory and purchasing; subscriptions and permissions constrain access across every module. The team needs strong boundaries without the operational cost and consistency challenges of a distributed system.

## Decision

Use one Next.js application and one PostgreSQL database, structured as a modular monolith. Capability modules own their rules and writes, communicate through explicit application contracts, and share cross-cutting platform services only through narrow interfaces.

The initial repository creates only boundaries with immediate responsibilities: web delivery, shared UI, and compiler policy. Domain and infrastructure packages will be added with their approved milestones rather than as speculative empty layers.

## Consequences

- Local development, transactions, deployment, and debugging remain simple.
- Cross-module invariants can be maintained transactionally.
- Package/API discipline is required to prevent the monolith from becoming tangled.
- Later extraction remains possible for a capability with demonstrated scaling or ownership needs.
- Database-wide RLS remains the final tenant boundary even when application modules are separated.
