begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(42);

select has_table('public', 'staff_invitations', 'staff invitations table exists');
select has_table('public', 'audit_events', 'audit events table exists');
select ok(
  (
    select relrowsecurity and relforcerowsecurity
    from pg_catalog.pg_class
    where oid = 'public.staff_invitations'::regclass
  ),
  'staff invitations have enabled and forced RLS'
);
select ok(
  (
    select relrowsecurity and relforcerowsecurity
    from pg_catalog.pg_class
    where oid = 'public.audit_events'::regclass
  ),
  'audit events have enabled and forced RLS'
);
select ok(
  not has_table_privilege('authenticated', 'public.staff_invitations', 'INSERT'),
  'authenticated users cannot insert invitations directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.audit_events', 'UPDATE'),
  'authenticated users cannot alter audit events'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.onboard_organization(text,text,text,text,text,text)',
    'EXECUTE'
  ),
  'anonymous users cannot call onboarding'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.onboard_organization(text,text,text,text,text,text)',
    'EXECUTE'
  ),
  'authenticated users can call the reviewed onboarding function'
);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'owner-a@milestone3.test',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'owner-b@milestone3.test',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'invitee@milestone3.test',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000004',
    'authenticated',
    'authenticated',
    'attacker@milestone3.test',
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'b1000000-0000-0000-0000-000000000005',
    'authenticated',
    'authenticated',
    'unverified@milestone3.test',
    null,
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  );

select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000005', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000005","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $$
    select public.onboard_organization(
      'Unverified Company',
      'unverified-company',
      'USD',
      'First',
      'first',
      'UTC'
    )
  $$,
  '42501',
  null,
  'unverified users cannot create tenant data'
);

reset role;
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    select public.onboard_organization(
      'Milestone Three A',
      'milestone-three-a',
      'USD',
      'Downtown',
      'downtown',
      'America/Chicago'
    )
  $$,
  'verified user onboards an organization transactionally'
);
select results_eq(
  $$ select count(*) from public.organizations where slug = 'milestone-three-a' $$,
  array[1::bigint],
  'onboarding creates one organization'
);
select results_eq(
  $$
    select count(*)
    from public.locations
    where organization_id = (select id from public.organizations where slug = 'milestone-three-a')
  $$,
  array[1::bigint],
  'onboarding creates the first location'
);
select results_eq(
  $$
    select count(*)
    from public.memberships
    where organization_id = (select id from public.organizations where slug = 'milestone-three-a')
      and user_id = 'b1000000-0000-0000-0000-000000000001'
      and status = 'active'
  $$,
  array[1::bigint],
  'onboarding creates the active owner membership'
);
select results_eq(
  $$
    select count(*)
    from public.roles
    where organization_id = (select id from public.organizations where slug = 'milestone-three-a')
  $$,
  array[3::bigint],
  'onboarding installs the system roles'
);
select results_eq(
  $$
    select count(*)
    from public.subscriptions
    where organization_id = (select id from public.organizations where slug = 'milestone-three-a')
      and status = 'trialing'
  $$,
  array[1::bigint],
  'onboarding creates one trial subscription'
);
select results_eq(
  $$
    select count(*)
    from public.subscription_entitlements
    where organization_id = (select id from public.organizations where slug = 'milestone-three-a')
  $$,
  array[2::bigint],
  'onboarding snapshots plan entitlements'
);
select cmp_ok(
  (
    select count(*)
    from public.audit_events
    where organization_id = (select id from public.organizations where slug = 'milestone-three-a')
  ),
  '>=',
  2::bigint,
  'onboarding emits organization and location audit events'
);
select is(
  (
    public.organization_dashboard(
      (select id from public.organizations where slug = 'milestone-three-a'),
      (select id from public.locations where code = 'downtown')
    ) ->> 'locationLimit'
  ),
  '3.000000',
  'dashboard serializes the exact numeric location entitlement as text'
);
select is(
  (
    public.organization_dashboard(
      (select id from public.organizations where slug = 'milestone-three-a'),
      (select id from public.locations where code = 'downtown')
    ) ->> 'analyticsEnabled'
  )::boolean,
  false,
  'dashboard reports a disabled boolean entitlement'
);
select lives_ok(
  $$
    select public.create_staff_invitation(
      (select id from public.organizations where slug = 'milestone-three-a'),
      'external@milestone3.test',
      (select id from public.roles where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and key = 'viewer'),
      (select id from public.locations where code = 'downtown'),
      72
    )
  $$,
  'authorized owner creates a scoped staff invitation'
);
select results_eq(
  $$
    select octet_length(token_hash)
    from public.staff_invitations
    where email = 'external@milestone3.test'
  $$,
  array[32],
  'only a SHA-256 invitation token digest is stored'
);
select throws_ok(
  $$
    select public.create_staff_invitation(
      (select id from public.organizations where slug = 'milestone-three-a'),
      'external@milestone3.test',
      (select id from public.roles where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and key = 'viewer'),
      (select id from public.locations where code = 'downtown'),
      72
    )
  $$,
  '23505',
  null,
  'duplicate pending recipient invitations are rejected'
);
select lives_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      (select id from public.organizations where slug = 'milestone-three-a'),
      'Second',
      'second',
      'UTC',
      'b1000000-0000-0000-0000-000000000001'
    )
  $$,
  'second active location is within the entitlement'
);
select lives_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      (select id from public.organizations where slug = 'milestone-three-a'),
      'Third',
      'third',
      'UTC',
      'b1000000-0000-0000-0000-000000000001'
    )
  $$,
  'third active location reaches the entitlement limit'
);
select throws_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      (select id from public.organizations where slug = 'milestone-three-a'),
      'Fourth',
      'fourth',
      'UTC',
      'b1000000-0000-0000-0000-000000000001'
    )
  $$,
  '23514',
  null,
  'database rejects active locations beyond the exact entitlement limit'
);

reset role;
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000002', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$
    select public.onboard_organization(
      'Milestone Three B',
      'milestone-three-b',
      'USD',
      'Uptown',
      'uptown',
      'America/Chicago'
    )
  $$,
  'a second identity onboards an isolated organization'
);

reset role;
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $$
    insert into public.locations (organization_id, name, code, time_zone, created_by)
    values (
      (select id from public.organizations where slug = 'milestone-three-b'),
      'Cross tenant',
      'cross-tenant',
      'UTC',
      'b1000000-0000-0000-0000-000000000001'
    )
  $$,
  '42501',
  null,
  'owner cannot create a location in another organization'
);

reset role;
insert into public.staff_invitations (
  organization_id,
  email,
  token_hash,
  role_id,
  location_id,
  expires_at,
  created_by
)
values (
  (select id from public.organizations where slug = 'milestone-three-a'),
  'invitee@milestone3.test',
  extensions.digest(repeat('c', 64), 'sha256'),
  (select id from public.roles where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and key = 'viewer'),
  (select id from public.locations where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and code = 'downtown'),
  statement_timestamp() + interval '1 day',
  'b1000000-0000-0000-0000-000000000001'
);

select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000004', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000004","role":"authenticated"}',
  true
);
set local role authenticated;

select results_eq(
  $$ select count(*) from public.staff_invitations $$,
  array[0::bigint],
  'unrelated identity cannot read invitation rows'
);
select results_eq(
  $$ select count(*) from public.audit_events $$,
  array[0::bigint],
  'unrelated identity cannot read tenant audit events'
);
select throws_ok(
  $$
    select public.create_staff_invitation(
      (select id from public.organizations where slug = 'milestone-three-a'),
      'victim@milestone3.test',
      (select id from public.roles where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and key = 'viewer'),
      null,
      72
    )
  $$,
  '42501',
  null,
  'non-member cannot create an invitation'
);
select throws_ok(
  $$ select public.accept_staff_invitation(repeat('c', 64)) $$,
  '42501',
  null,
  'wrong recipient cannot accept a valid invitation token'
);
select results_eq(
  $$
    select count(*)
    from public.memberships
    where user_id = 'b1000000-0000-0000-0000-000000000004'
  $$,
  array[0::bigint],
  'failed recipient check creates no membership'
);

reset role;
select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000003', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select lives_ok(
  $$ select public.accept_staff_invitation(repeat('c', 64)) $$,
  'verified recipient accepts the invitation'
);
select results_eq(
  $$
    select count(*)
    from public.memberships
    where user_id = 'b1000000-0000-0000-0000-000000000003'
      and status = 'active'
  $$,
  array[1::bigint],
  'acceptance creates one active membership'
);
select results_eq(
  $$
    select count(*)
    from public.role_assignments as assignment
    inner join public.memberships as membership on membership.id = assignment.membership_id
    where membership.user_id = 'b1000000-0000-0000-0000-000000000003'
      and assignment.location_id = (select id from public.locations where code = 'downtown')
  $$,
  array[1::bigint],
  'acceptance grants only the invitation location scope'
);

reset role;
select results_eq(
  $$
    select count(*)
    from public.staff_invitations
    where email = 'invitee@milestone3.test'
      and status = 'accepted'
  $$,
  array[1::bigint],
  'accepted invitation is marked used'
);

set local role authenticated;
select throws_ok(
  $$ select public.accept_staff_invitation(repeat('c', 64)) $$,
  '22023',
  null,
  'accepted invitation cannot be reused'
);

reset role;
update public.memberships
set status = 'suspended'
where user_id = 'b1000000-0000-0000-0000-000000000003'
  and organization_id = (select id from public.organizations where slug = 'milestone-three-a');

insert into public.staff_invitations (
  organization_id,
  email,
  token_hash,
  role_id,
  location_id,
  expires_at,
  created_by
)
values (
  (select id from public.organizations where slug = 'milestone-three-a'),
  'invitee@milestone3.test',
  extensions.digest(repeat('d', 64), 'sha256'),
  (select id from public.roles where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and key = 'viewer'),
  (select id from public.locations where organization_id = (select id from public.organizations where slug = 'milestone-three-a') and code = 'downtown'),
  statement_timestamp() + interval '1 day',
  'b1000000-0000-0000-0000-000000000001'
);

select set_config('request.jwt.claim.sub', 'b1000000-0000-0000-0000-000000000003', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"b1000000-0000-0000-0000-000000000003","role":"authenticated"}',
  true
);
set local role authenticated;

select throws_ok(
  $$ select public.accept_staff_invitation(repeat('d', 64)) $$,
  '42501',
  null,
  'invitation cannot reactivate a suspended membership'
);
select results_eq(
  $$
    select count(*)
    from public.memberships
    where user_id = 'b1000000-0000-0000-0000-000000000003'
      and status = 'suspended'
  $$,
  array[1::bigint],
  'suspended membership remains suspended after invitation abuse attempt'
);
select throws_ok(
  $$
    select public.organization_dashboard(
      (select id from public.organizations where slug = 'milestone-three-a'),
      (select id from public.locations where code = 'downtown')
    )
  $$,
  '42501',
  null,
  'suspended member cannot load server-side dashboard entitlements'
);

reset role;
select results_eq(
  $$
    select count(*)
    from public.audit_events
    where event_type = 'invitation.accepted'
      and actor_user_id = 'b1000000-0000-0000-0000-000000000003'
  $$,
  array[1::bigint],
  'successful invitation acceptance is audited once'
);
select ok(
  not has_table_privilege('authenticated', 'public.role_assignments', 'INSERT'),
  'authenticated users cannot bypass invitations by assigning roles directly'
);

select * from finish();
rollback;
