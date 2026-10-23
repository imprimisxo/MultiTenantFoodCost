begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(38);

select has_table('public', 'profiles', 'profiles table exists');
select has_table('public', 'organizations', 'organizations table exists');
select has_table('public', 'locations', 'locations table exists');
select has_table('public', 'memberships', 'memberships table exists');
select has_table('public', 'permissions', 'permissions table exists');
select has_table('public', 'roles', 'roles table exists');
select has_table('public', 'role_permissions', 'role_permissions table exists');
select has_table('public', 'role_assignments', 'role_assignments table exists');
select has_table('public', 'plans', 'plans table exists');
select has_table('public', 'entitlements', 'entitlements table exists');
select has_table('public', 'plan_entitlements', 'plan_entitlements table exists');
select has_table('public', 'subscriptions', 'subscriptions table exists');
select has_table(
  'public',
  'subscription_entitlements',
  'subscription_entitlements table exists'
);

select ok(
  table_metadata.relrowsecurity and table_metadata.relforcerowsecurity,
  format('%I has enabled and forced RLS', table_metadata.relname)
)
from pg_catalog.pg_class as table_metadata
inner join pg_catalog.pg_namespace as table_schema
  on table_schema.oid = table_metadata.relnamespace
where table_schema.nspname = 'public'
  and table_metadata.relname = any (
    array[
      'profiles',
      'organizations',
      'locations',
      'memberships',
      'permissions',
      'roles',
      'role_permissions',
      'role_assignments',
      'plans',
      'entitlements',
      'plan_entitlements',
      'subscriptions',
      'subscription_entitlements'
    ]
  )
order by table_metadata.relname;

select col_type_is(
  'public',
  'plans',
  'price_amount',
  'numeric(12,2)',
  'plan prices use exact numeric values'
);
select col_type_is(
  'public',
  'subscriptions',
  'billing_amount',
  'numeric(12,2)',
  'subscription prices use exact numeric values'
);
select col_type_is(
  'public',
  'plan_entitlements',
  'numeric_value',
  'numeric(20,6)',
  'plan quantity limits use exact numeric values'
);
select col_type_is(
  'public',
  'subscription_entitlements',
  'numeric_value',
  'numeric(20,6)',
  'subscription quantity limits use exact numeric values'
);

select has_trigger(
  'auth',
  'users',
  'on_auth_user_created',
  'auth users automatically receive a profile'
);
select has_fk('public', 'profiles', 'profiles reference auth users');

select ok(
  not has_table_privilege('authenticated', 'public.roles', 'INSERT'),
  'authenticated users cannot insert roles directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.role_assignments', 'INSERT'),
  'authenticated users cannot assign roles directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.entitlements', 'UPDATE'),
  'authenticated users cannot update entitlement definitions directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.subscription_entitlements', 'INSERT'),
  'authenticated users cannot grant subscription entitlements directly'
);

select ok(
  (
    select count(*)
    from pg_catalog.pg_constraint as constraint_metadata
    where constraint_metadata.conrelid = 'public.role_assignments'::regclass
      and constraint_metadata.contype = 'f'
      and array_length(constraint_metadata.conkey, 1) = 2
  ) = 3,
  'role assignments have tenant-consistent membership, role, and location foreign keys'
);

select ok(
  exists (
    select 1
    from pg_catalog.pg_constraint as constraint_metadata
    where constraint_metadata.conrelid = 'public.subscription_entitlements'::regclass
      and constraint_metadata.contype = 'f'
      and array_length(constraint_metadata.conkey, 1) = 2
  ),
  'subscription entitlements have a tenant-consistent subscription foreign key'
);

select * from finish();
rollback;
