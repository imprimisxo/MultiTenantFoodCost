begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(41);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'owner-a@rls.test',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Owner A"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'owner-b@rls.test',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Owner B"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'multi-org@rls.test',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Multi Org"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000004',
    'authenticated',
    'authenticated',
    'location-manager@rls.test',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Location Manager"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000005',
    'authenticated',
    'authenticated',
    'suspended@rls.test',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Suspended Owner"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-0000-0000-000000000006',
    'authenticated',
    'authenticated',
    'attacker@rls.test',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Attacker"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  );

insert into public.organizations (id, name, slug, created_by)
values
  (
    'a2000000-0000-0000-0000-000000000001',
    'Tenant A',
    'rls-tenant-a',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a2000000-0000-0000-0000-000000000002',
    'Tenant B',
    'rls-tenant-b',
    'a1000000-0000-0000-0000-000000000002'
  );

insert into public.locations (id, organization_id, name, code, created_by)
values
  (
    'a3000000-0000-0000-0000-000000000001',
    'a2000000-0000-0000-0000-000000000001',
    'Tenant A One',
    'a-one',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a3000000-0000-0000-0000-000000000002',
    'a2000000-0000-0000-0000-000000000001',
    'Tenant A Two',
    'a-two',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a3000000-0000-0000-0000-000000000003',
    'a2000000-0000-0000-0000-000000000002',
    'Tenant B One',
    'b-one',
    'a1000000-0000-0000-0000-000000000002'
  );

insert into public.memberships (id, organization_id, user_id, status, created_by)
values
  (
    'a4000000-0000-0000-0000-000000000001',
    'a2000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000001',
    'active',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a4000000-0000-0000-0000-000000000002',
    'a2000000-0000-0000-0000-000000000002',
    'a1000000-0000-0000-0000-000000000002',
    'active',
    'a1000000-0000-0000-0000-000000000002'
  ),
  (
    'a4000000-0000-0000-0000-000000000003',
    'a2000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000003',
    'active',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a4000000-0000-0000-0000-000000000004',
    'a2000000-0000-0000-0000-000000000002',
    'a1000000-0000-0000-0000-000000000003',
    'active',
    'a1000000-0000-0000-0000-000000000002'
  ),
  (
    'a4000000-0000-0000-0000-000000000005',
    'a2000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000004',
    'active',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a4000000-0000-0000-0000-000000000006',
    'a2000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000005',
    'suspended',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a4000000-0000-0000-0000-000000000007',
    'a2000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000006',
    'active',
    'a1000000-0000-0000-0000-000000000001'
  );

insert into public.roles (id, organization_id, key, name, created_by)
values
  (
    'a5000000-0000-0000-0000-000000000001',
    'a2000000-0000-0000-0000-000000000001',
    'owner',
    'Owner',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a5000000-0000-0000-0000-000000000002',
    'a2000000-0000-0000-0000-000000000001',
    'viewer',
    'Viewer',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a5000000-0000-0000-0000-000000000003',
    'a2000000-0000-0000-0000-000000000001',
    'location_manager',
    'Location manager',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a5000000-0000-0000-0000-000000000004',
    'a2000000-0000-0000-0000-000000000002',
    'owner',
    'Owner',
    'a1000000-0000-0000-0000-000000000002'
  ),
  (
    'a5000000-0000-0000-0000-000000000005',
    'a2000000-0000-0000-0000-000000000002',
    'viewer',
    'Viewer',
    'a1000000-0000-0000-0000-000000000002'
  );

insert into public.role_permissions (organization_id, role_id, permission_key, granted_by)
select
  'a2000000-0000-0000-0000-000000000001',
  'a5000000-0000-0000-0000-000000000001',
  permission.key,
  'a1000000-0000-0000-0000-000000000001'
from public.permissions as permission;

insert into public.role_permissions (organization_id, role_id, permission_key, granted_by)
select
  'a2000000-0000-0000-0000-000000000002',
  'a5000000-0000-0000-0000-000000000004',
  permission.key,
  'a1000000-0000-0000-0000-000000000002'
from public.permissions as permission;

insert into public.role_permissions (organization_id, role_id, permission_key, granted_by)
values
  (
    'a2000000-0000-0000-0000-000000000001',
    'a5000000-0000-0000-0000-000000000002',
    'locations.read',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a2000000-0000-0000-0000-000000000001',
    'a5000000-0000-0000-0000-000000000003',
    'locations.read',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a2000000-0000-0000-0000-000000000001',
    'a5000000-0000-0000-0000-000000000003',
    'locations.write',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a2000000-0000-0000-0000-000000000002',
    'a5000000-0000-0000-0000-000000000005',
    'locations.read',
    'a1000000-0000-0000-0000-000000000002'
  );

insert into public.role_assignments (
  id,
  organization_id,
  membership_id,
  role_id,
  location_id,
  assigned_by
)
values
  (
    'a5100000-0000-0000-0000-000000000001',
    'a2000000-0000-0000-0000-000000000001',
    'a4000000-0000-0000-0000-000000000001',
    'a5000000-0000-0000-0000-000000000001',
    null,
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a5100000-0000-0000-0000-000000000002',
    'a2000000-0000-0000-0000-000000000002',
    'a4000000-0000-0000-0000-000000000002',
    'a5000000-0000-0000-0000-000000000004',
    null,
    'a1000000-0000-0000-0000-000000000002'
  ),
  (
    'a5100000-0000-0000-0000-000000000003',
    'a2000000-0000-0000-0000-000000000001',
    'a4000000-0000-0000-0000-000000000003',
    'a5000000-0000-0000-0000-000000000002',
    null,
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a5100000-0000-0000-0000-000000000004',
    'a2000000-0000-0000-0000-000000000002',
    'a4000000-0000-0000-0000-000000000004',
    'a5000000-0000-0000-0000-000000000005',
    null,
    'a1000000-0000-0000-0000-000000000002'
  ),
  (
    'a5100000-0000-0000-0000-000000000005',
    'a2000000-0000-0000-0000-000000000001',
    'a4000000-0000-0000-0000-000000000005',
    'a5000000-0000-0000-0000-000000000003',
    'a3000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a5100000-0000-0000-0000-000000000006',
    'a2000000-0000-0000-0000-000000000001',
    'a4000000-0000-0000-0000-000000000006',
    'a5000000-0000-0000-0000-000000000001',
    null,
    'a1000000-0000-0000-0000-000000000001'
  );

insert into public.plans (
  id,
  code,
  name,
  billing_interval,
  price_amount,
  currency_code
)
values (
  'a6000000-0000-0000-0000-000000000001',
  'rls_plan',
  'RLS plan',
  'month',
  99.00,
  'USD'
);

insert into public.entitlements (id, key, description, value_type)
values
  (
    'a7000000-0000-0000-0000-000000000001',
    'testing.feature',
    'Boolean entitlement for RLS tests.',
    'boolean'
  ),
  (
    'a7000000-0000-0000-0000-000000000002',
    'testing.limit',
    'Numeric entitlement for RLS tests.',
    'numeric'
  );

insert into public.subscriptions (
  id,
  organization_id,
  plan_id,
  status,
  billing_amount,
  currency_code,
  created_by
)
values
  (
    'a8000000-0000-0000-0000-000000000001',
    'a2000000-0000-0000-0000-000000000001',
    'a6000000-0000-0000-0000-000000000001',
    'active',
    99.00,
    'USD',
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a8000000-0000-0000-0000-000000000002',
    'a2000000-0000-0000-0000-000000000002',
    'a6000000-0000-0000-0000-000000000001',
    'active',
    99.00,
    'USD',
    'a1000000-0000-0000-0000-000000000002'
  );

insert into public.subscription_entitlements (
  id,
  organization_id,
  subscription_id,
  entitlement_id,
  value_type,
  boolean_value,
  numeric_value
)
values
  (
    'a9000000-0000-0000-0000-000000000001',
    'a2000000-0000-0000-0000-000000000001',
    'a8000000-0000-0000-0000-000000000001',
    'a7000000-0000-0000-0000-000000000001',
    'boolean',
    true,
    null
  ),
  (
    'a9000000-0000-0000-0000-000000000002',
    'a2000000-0000-0000-0000-000000000001',
    'a8000000-0000-0000-0000-000000000001',
    'a7000000-0000-0000-0000-000000000002',
    'numeric',
    null,
    2.000000
  ),
  (
    'a9000000-0000-0000-0000-000000000003',
    'a2000000-0000-0000-0000-000000000001',
    'a8000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'numeric',
    null,
    3.000000
  );

select is(
  (
    select count(*)
    from public.profiles
    where id::text like 'a1000000-%'
  ),
  6::bigint,
  'profile trigger creates one profile for each auth identity'
);

select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select results_eq(
  $$ select count(*) from public.organizations where id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[1::bigint],
  'authorized member reads their organization'
);
select results_eq(
  $$ select count(*) from public.locations where organization_id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[2::bigint],
  'organization-scoped owner reads authorized locations'
);
select lives_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      'a2000000-0000-0000-0000-000000000001',
      'Tenant A Three',
      'a-three',
      'UTC',
      'a1000000-0000-0000-0000-000000000001'
    )
  $$,
  'organization-scoped owner creates a location in their tenant'
);
select results_eq(
  $$
    update public.locations
    set name = 'Tenant A One Updated'
    where id = 'a3000000-0000-0000-0000-000000000001'
    returning id
  $$,
  array['a3000000-0000-0000-0000-000000000001'::uuid],
  'authorized location update succeeds'
);
select results_eq(
  $$ select count(*) from public.organizations where id = 'a2000000-0000-0000-0000-000000000002' $$,
  array[0::bigint],
  'cross-tenant organization read is denied'
);
select results_eq(
  $$ select count(*) from public.locations where id = 'a3000000-0000-0000-0000-000000000003' $$,
  array[0::bigint],
  'cross-tenant location read is denied'
);
select results_eq(
  $$
    update public.locations
    set name = 'Compromised'
    where id = 'a3000000-0000-0000-0000-000000000003'
    returning id
  $$,
  array[]::uuid[],
  'cross-tenant location update affects no rows'
);
select throws_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      'a2000000-0000-0000-0000-000000000002',
      'Unauthorized',
      'unauthorized',
      'UTC',
      'a1000000-0000-0000-0000-000000000001'
    )
  $$,
  '42501',
  null,
  'cross-tenant location insert is denied'
);
select results_eq(
  $$ select count(*) from public.subscriptions where organization_id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[1::bigint],
  'billing reader sees their subscription'
);
select results_eq(
  $$ select count(*) from public.subscriptions where organization_id = 'a2000000-0000-0000-0000-000000000002' $$,
  array[0::bigint],
  'billing reader cannot see another tenant subscription'
);
select ok(
  private.has_boolean_entitlement(
    'a2000000-0000-0000-0000-000000000001',
    'testing.feature'
  ),
  'active member receives their boolean entitlement'
);
select is(
  private.entitlement_numeric_limit(
    'a2000000-0000-0000-0000-000000000001',
    'testing.limit'
  ),
  2.000000::numeric,
  'active member receives the exact numeric entitlement limit'
);
select isnt(
  private.has_boolean_entitlement(
    'a2000000-0000-0000-0000-000000000002',
    'testing.feature'
  ),
  true,
  'entitlement helper does not leak access across tenants'
);

reset role;
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000003', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select results_eq(
  $$ select count(*) from public.organizations where id in ('a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002') $$,
  array[2::bigint],
  'one identity can hold active memberships in multiple organizations'
);
select results_eq(
  $$ select count(*) from public.locations where id in ('a3000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a3000000-0000-0000-0000-000000000003') $$,
  array[3::bigint],
  'multi-organization roles grant location access independently in both tenants'
);
select results_eq(
  $$ select count(*) from public.memberships where user_id = 'a1000000-0000-0000-0000-000000000003' $$,
  array[2::bigint],
  'multi-organization identity can read both of its membership rows'
);

reset role;
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000004', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000004","role":"authenticated"}',
  true
);
set local role authenticated;

select results_eq(
  $$ select id from public.locations where organization_id = 'a2000000-0000-0000-0000-000000000001' order by id $$,
  array['a3000000-0000-0000-0000-000000000001'::uuid],
  'location-scoped manager reads only the assigned location'
);
select results_eq(
  $$ select count(*) from public.locations where id = 'a3000000-0000-0000-0000-000000000002' $$,
  array[0::bigint],
  'unassigned location read is denied'
);
select results_eq(
  $$
    update public.locations
    set name = 'Scoped Manager Updated'
    where id = 'a3000000-0000-0000-0000-000000000001'
    returning id
  $$,
  array['a3000000-0000-0000-0000-000000000001'::uuid],
  'location-scoped manager updates the assigned location'
);
select results_eq(
  $$
    update public.locations
    set name = 'Unauthorized Update'
    where id = 'a3000000-0000-0000-0000-000000000002'
    returning id
  $$,
  array[]::uuid[],
  'location-scoped manager cannot update an unassigned location'
);
select throws_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      'a2000000-0000-0000-0000-000000000001',
      'Unauthorized New Location',
      'unauthorized-new',
      'UTC',
      'a1000000-0000-0000-0000-000000000004'
    )
  $$,
  '42501',
  null,
  'location-scoped role cannot create organization-scoped resources'
);

reset role;
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000005', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000005","role":"authenticated"}',
  true
);
set local role authenticated;

select results_eq(
  $$ select count(*) from public.organizations where id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[0::bigint],
  'suspended member cannot read the organization'
);
select results_eq(
  $$ select count(*) from public.locations where organization_id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[0::bigint],
  'suspended member cannot read locations'
);
select is(
  private.has_permission(
    'a2000000-0000-0000-0000-000000000001',
    'locations.write',
    'a3000000-0000-0000-0000-000000000001'
  ),
  false,
  'suspension overrides an assigned owner role'
);
select is(
  private.has_boolean_entitlement(
    'a2000000-0000-0000-0000-000000000001',
    'testing.feature'
  ),
  false,
  'suspended member cannot use subscription entitlements'
);

reset role;
select set_config('request.jwt.claim.sub', 'a1000000-0000-0000-0000-000000000006', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"a1000000-0000-0000-0000-000000000006","role":"authenticated"}',
  true
);
set local role authenticated;

select results_eq(
  $$ select count(*) from public.organizations where id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[1::bigint],
  'active membership alone permits organization discovery'
);
select results_eq(
  $$ select count(*) from public.locations where organization_id = 'a2000000-0000-0000-0000-000000000001' $$,
  array[0::bigint],
  'membership without a role grants no location access'
);
select results_eq(
  $$ select count(*) from public.profiles where id = 'a1000000-0000-0000-0000-000000000006' $$,
  array[1::bigint],
  'identity reads its own profile'
);
select results_eq(
  $$ select count(*) from public.profiles where id = 'a1000000-0000-0000-0000-000000000001' $$,
  array[0::bigint],
  'identity cannot read another profile'
);
select throws_ok(
  $$
    insert into public.role_assignments (
      organization_id,
      membership_id,
      role_id,
      assigned_by
    )
    values (
      'a2000000-0000-0000-0000-000000000001',
      'a4000000-0000-0000-0000-000000000007',
      'a5000000-0000-0000-0000-000000000001',
      'a1000000-0000-0000-0000-000000000006'
    )
  $$,
  '42501',
  null,
  'member cannot assign itself an owner role'
);
select throws_ok(
  $$ update public.roles set name = 'Escalated owner' where id = 'a5000000-0000-0000-0000-000000000001' $$,
  '42501',
  null,
  'member cannot modify role definitions'
);
select throws_ok(
  $$
    insert into public.role_permissions (organization_id, role_id, permission_key, granted_by)
    values (
      'a2000000-0000-0000-0000-000000000001',
      'a5000000-0000-0000-0000-000000000002',
      'roles.manage',
      'a1000000-0000-0000-0000-000000000006'
    )
  $$,
  '42501',
  null,
  'member cannot add permissions to a role'
);
select throws_ok(
  $$
    insert into public.subscription_entitlements (
      organization_id,
      subscription_id,
      entitlement_id,
      value_type,
      boolean_value
    )
    values (
      'a2000000-0000-0000-0000-000000000001',
      'a8000000-0000-0000-0000-000000000001',
      'a7000000-0000-0000-0000-000000000001',
      'boolean',
      true
    )
  $$,
  '42501',
  null,
  'member cannot grant subscription entitlements'
);
select throws_ok(
  $$
    update public.memberships
    set status = 'active'
    where id = 'a4000000-0000-0000-0000-000000000006'
  $$,
  '42501',
  null,
  'member cannot reactivate a suspended membership'
);

reset role;

select lives_ok(
  $$
    insert into public.subscriptions (
      id,
      organization_id,
      plan_id,
      status,
      billing_amount,
      currency_code,
      created_by
    )
    values (
      'a8000000-0000-0000-0000-000000000003',
      'a2000000-0000-0000-0000-000000000001',
      'a6000000-0000-0000-0000-000000000001',
      'canceled',
      79.00,
      'USD',
      'a1000000-0000-0000-0000-000000000001'
    )
  $$,
  'canceled subscription history can be retained'
);
select throws_ok(
  $$
    insert into public.subscriptions (
      id,
      organization_id,
      plan_id,
      status,
      billing_amount,
      currency_code,
      created_by
    )
    values (
      'a8000000-0000-0000-0000-000000000004',
      'a2000000-0000-0000-0000-000000000001',
      'a6000000-0000-0000-0000-000000000001',
      'active',
      99.00,
      'USD',
      'a1000000-0000-0000-0000-000000000001'
    )
  $$,
  '23505',
  null,
  'organization cannot have two current subscriptions'
);
select throws_ok(
  $$
    insert into public.role_assignments (
      organization_id,
      membership_id,
      role_id,
      assigned_by
    )
    values (
      'a2000000-0000-0000-0000-000000000001',
      'a4000000-0000-0000-0000-000000000001',
      'a5000000-0000-0000-0000-000000000004',
      'a1000000-0000-0000-0000-000000000001'
    )
  $$,
  '23503',
  null,
  'tenant-consistent role foreign key rejects a role from another organization'
);
select throws_ok(
  $$
    insert into public.subscription_entitlements (
      organization_id,
      subscription_id,
      entitlement_id,
      value_type,
      boolean_value
    )
    values (
      'a2000000-0000-0000-0000-000000000001',
      'a8000000-0000-0000-0000-000000000002',
      'a7000000-0000-0000-0000-000000000001',
      'boolean',
      true
    )
  $$,
  '23503',
  null,
  'tenant-consistent entitlement foreign key rejects another organization subscription'
);
select throws_ok(
  $$
    update public.locations
    set organization_id = 'a2000000-0000-0000-0000-000000000002'
    where id = 'a3000000-0000-0000-0000-000000000001'
  $$,
  '23514',
  null,
  'tenant identifier cannot be changed after creation'
);

set local role anon;
select throws_ok(
  $$ select * from public.organizations $$,
  '42501',
  null,
  'anonymous identities have no tenant table privileges'
);

select * from finish();
rollback;
