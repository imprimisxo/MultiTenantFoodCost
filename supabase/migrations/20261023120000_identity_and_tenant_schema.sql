begin;

create schema if not exists private;

revoke all on schema private from public;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  locale text not null default 'en-US',
  time_zone text not null default 'UTC',
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint profiles_display_name_not_blank
    check (display_name is null or btrim(display_name) <> ''),
  constraint profiles_locale_not_blank check (btrim(locale) <> ''),
  constraint profiles_time_zone_not_blank check (btrim(time_zone) <> '')
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  default_currency text not null default 'USD',
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint organizations_name_not_blank check (btrim(name) <> ''),
  constraint organizations_slug_format
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint organizations_currency_format
    check (default_currency ~ '^[A-Z]{3}$')
);

create table public.locations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  name text not null,
  code text not null,
  time_zone text not null default 'UTC',
  is_active boolean not null default true,
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint locations_name_not_blank check (btrim(name) <> ''),
  constraint locations_code_not_blank check (btrim(code) <> ''),
  constraint locations_time_zone_not_blank check (btrim(time_zone) <> ''),
  constraint locations_organization_id_id_key unique (organization_id, id),
  constraint locations_organization_id_code_key unique (organization_id, code)
);

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete restrict,
  status text not null default 'active',
  created_by uuid references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint memberships_status
    check (status in ('invited', 'active', 'suspended', 'revoked')),
  constraint memberships_organization_id_user_id_key unique (organization_id, user_id),
  constraint memberships_organization_id_id_key unique (organization_id, id)
);

create table public.permissions (
  key text primary key,
  description text not null,
  created_at timestamptz not null default statement_timestamp(),
  constraint permissions_key_format
    check (key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
  constraint permissions_description_not_blank check (btrim(description) <> '')
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  key text not null,
  name text not null,
  description text,
  is_system boolean not null default false,
  created_by uuid references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint roles_key_format check (key ~ '^[a-z][a-z0-9_]*$'),
  constraint roles_name_not_blank check (btrim(name) <> ''),
  constraint roles_description_not_blank
    check (description is null or btrim(description) <> ''),
  constraint roles_organization_id_key_key unique (organization_id, key),
  constraint roles_organization_id_id_key unique (organization_id, id)
);

create table public.role_permissions (
  organization_id uuid not null references public.organizations (id) on delete restrict,
  role_id uuid not null,
  permission_key text not null references public.permissions (key) on delete restrict,
  granted_by uuid references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  primary key (organization_id, role_id, permission_key),
  constraint role_permissions_role_tenant_fk
    foreign key (organization_id, role_id)
    references public.roles (organization_id, id)
    on delete cascade
);

create table public.role_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  membership_id uuid not null,
  role_id uuid not null,
  location_id uuid,
  assigned_by uuid references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  constraint role_assignments_organization_id_id_key unique (organization_id, id),
  constraint role_assignments_membership_tenant_fk
    foreign key (organization_id, membership_id)
    references public.memberships (organization_id, id)
    on delete cascade,
  constraint role_assignments_role_tenant_fk
    foreign key (organization_id, role_id)
    references public.roles (organization_id, id)
    on delete cascade,
  constraint role_assignments_location_tenant_fk
    foreign key (organization_id, location_id)
    references public.locations (organization_id, id)
    on delete cascade
);

create unique index role_assignments_org_scope_key
  on public.role_assignments (organization_id, membership_id, role_id)
  where location_id is null;

create unique index role_assignments_location_scope_key
  on public.role_assignments (organization_id, membership_id, role_id, location_id)
  where location_id is not null;

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  billing_interval text not null,
  price_amount numeric(12, 2) not null,
  currency_code text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint plans_code_format check (code ~ '^[a-z][a-z0-9_]*$'),
  constraint plans_name_not_blank check (btrim(name) <> ''),
  constraint plans_description_not_blank
    check (description is null or btrim(description) <> ''),
  constraint plans_billing_interval
    check (billing_interval in ('month', 'year')),
  constraint plans_price_amount_nonnegative check (price_amount >= 0),
  constraint plans_currency_format check (currency_code ~ '^[A-Z]{3}$')
);

create table public.entitlements (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  description text not null,
  value_type text not null,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint entitlements_key_format
    check (key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
  constraint entitlements_description_not_blank check (btrim(description) <> ''),
  constraint entitlements_value_type check (value_type in ('boolean', 'numeric')),
  constraint entitlements_id_value_type_key unique (id, value_type)
);

create table public.plan_entitlements (
  plan_id uuid not null references public.plans (id) on delete cascade,
  entitlement_id uuid not null,
  value_type text not null,
  boolean_value boolean,
  numeric_value numeric(20, 6),
  created_at timestamptz not null default statement_timestamp(),
  primary key (plan_id, entitlement_id),
  constraint plan_entitlements_definition_fk
    foreign key (entitlement_id, value_type)
    references public.entitlements (id, value_type)
    on delete restrict,
  constraint plan_entitlements_value_shape check (
    (value_type = 'boolean' and boolean_value is not null and numeric_value is null)
    or
    (value_type = 'numeric' and boolean_value is null and numeric_value is not null and numeric_value >= 0)
  )
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  plan_id uuid not null references public.plans (id) on delete restrict,
  status text not null,
  billing_amount numeric(12, 2) not null,
  currency_code text not null,
  provider text not null default 'internal',
  external_reference text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  created_by uuid references auth.users (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint subscriptions_status
    check (status in ('trialing', 'active', 'past_due', 'paused', 'canceled')),
  constraint subscriptions_billing_amount_nonnegative check (billing_amount >= 0),
  constraint subscriptions_currency_format check (currency_code ~ '^[A-Z]{3}$'),
  constraint subscriptions_provider_not_blank check (btrim(provider) <> ''),
  constraint subscriptions_external_reference_not_blank
    check (external_reference is null or btrim(external_reference) <> ''),
  constraint subscriptions_period_order check (
    current_period_start is null
    or current_period_end is null
    or current_period_end > current_period_start
  ),
  constraint subscriptions_organization_id_id_key unique (organization_id, id)
);

create unique index subscriptions_provider_reference_key
  on public.subscriptions (provider, external_reference)
  where external_reference is not null;

create unique index subscriptions_one_current_per_organization_key
  on public.subscriptions (organization_id)
  where status in ('trialing', 'active', 'past_due', 'paused');

create table public.subscription_entitlements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  subscription_id uuid not null,
  entitlement_id uuid not null,
  value_type text not null,
  boolean_value boolean,
  numeric_value numeric(20, 6),
  source text not null default 'plan',
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint subscription_entitlements_subscription_tenant_fk
    foreign key (organization_id, subscription_id)
    references public.subscriptions (organization_id, id)
    on delete cascade,
  constraint subscription_entitlements_definition_fk
    foreign key (entitlement_id, value_type)
    references public.entitlements (id, value_type)
    on delete restrict,
  constraint subscription_entitlements_source
    check (source in ('plan', 'override')),
  constraint subscription_entitlements_value_shape check (
    (value_type = 'boolean' and boolean_value is not null and numeric_value is null)
    or
    (value_type = 'numeric' and boolean_value is null and numeric_value is not null and numeric_value >= 0)
  ),
  constraint subscription_entitlements_organization_id_id_key
    unique (organization_id, id),
  constraint subscription_entitlements_subscription_id_entitlement_id_key
    unique (subscription_id, entitlement_id)
);

create index memberships_user_active_idx
  on public.memberships (user_id, organization_id)
  where status = 'active';

create index role_assignments_authorization_idx
  on public.role_assignments (organization_id, membership_id, location_id, role_id);

create index role_permissions_authorization_idx
  on public.role_permissions (organization_id, permission_key, role_id);

create index subscriptions_active_idx
  on public.subscriptions (organization_id, id)
  where status in ('trialing', 'active');

create index subscription_entitlements_lookup_idx
  on public.subscription_entitlements (organization_id, entitlement_id, subscription_id);

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = statement_timestamp();
  return new;
end;
$$;

create or replace function private.protect_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  protected_column text;
begin
  foreach protected_column in array tg_argv loop
    if to_jsonb(new) -> protected_column is distinct from to_jsonb(old) -> protected_column then
      raise exception 'column "%" is immutable on %.%', protected_column, tg_table_schema, tg_table_name
        using errcode = '23514';
    end if;
  end loop;

  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();
create trigger profiles_protect_identity
before update on public.profiles
for each row execute function private.protect_columns('id', 'created_at');

create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function private.set_updated_at();
create trigger organizations_protect_identity
before update on public.organizations
for each row execute function private.protect_columns('id', 'created_by', 'created_at');

create trigger locations_set_updated_at
before update on public.locations
for each row execute function private.set_updated_at();
create trigger locations_protect_tenant
before update on public.locations
for each row execute function private.protect_columns('id', 'organization_id', 'created_by', 'created_at');

create trigger memberships_set_updated_at
before update on public.memberships
for each row execute function private.set_updated_at();
create trigger memberships_protect_tenant
before update on public.memberships
for each row execute function private.protect_columns('id', 'organization_id', 'user_id', 'created_at');

create trigger roles_set_updated_at
before update on public.roles
for each row execute function private.set_updated_at();
create trigger roles_protect_tenant
before update on public.roles
for each row execute function private.protect_columns('id', 'organization_id', 'created_at');

create trigger role_permissions_protect_tenant
before update on public.role_permissions
for each row execute function private.protect_columns(
  'organization_id',
  'role_id',
  'permission_key',
  'created_at'
);

create trigger role_assignments_protect_tenant
before update on public.role_assignments
for each row execute function private.protect_columns(
  'id',
  'organization_id',
  'membership_id',
  'role_id',
  'location_id',
  'created_at'
);

create trigger plans_set_updated_at
before update on public.plans
for each row execute function private.set_updated_at();
create trigger plans_protect_identity
before update on public.plans
for each row execute function private.protect_columns('id', 'code', 'created_at');

create trigger entitlements_set_updated_at
before update on public.entitlements
for each row execute function private.set_updated_at();
create trigger entitlements_protect_identity
before update on public.entitlements
for each row execute function private.protect_columns('id', 'key', 'value_type', 'created_at');

create trigger plan_entitlements_protect_identity
before update on public.plan_entitlements
for each row execute function private.protect_columns(
  'plan_id',
  'entitlement_id',
  'value_type',
  'created_at'
);

create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function private.set_updated_at();
create trigger subscriptions_protect_tenant
before update on public.subscriptions
for each row execute function private.protect_columns('id', 'organization_id', 'created_at');

create trigger subscription_entitlements_set_updated_at
before update on public.subscription_entitlements
for each row execute function private.set_updated_at();
create trigger subscription_entitlements_protect_tenant
before update on public.subscription_entitlements
for each row execute function private.protect_columns(
  'id',
  'organization_id',
  'subscription_id',
  'entitlement_id',
  'value_type',
  'created_at'
);

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(left(btrim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), 120), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();

insert into public.profiles (id, display_name)
select
  users.id,
  nullif(left(btrim(coalesce(users.raw_user_meta_data ->> 'display_name', '')), 120), '')
from auth.users as users
on conflict (id) do nothing;

insert into public.permissions (key, description)
values
  ('organization.update', 'Update organization settings.'),
  ('locations.read', 'Read locations within the granted scope.'),
  ('locations.write', 'Create or update locations within the granted scope.'),
  ('memberships.read', 'Read organization memberships.'),
  ('memberships.manage', 'Invite, suspend, or revoke organization memberships through privileged workflows.'),
  ('roles.read', 'Read role definitions and assignments.'),
  ('roles.manage', 'Manage role definitions and assignments through privileged workflows.'),
  ('billing.read', 'Read subscription and entitlement state.'),
  ('billing.manage', 'Manage billing through privileged workflows.')
on conflict (key) do update
set description = excluded.description;

revoke all on function private.set_updated_at() from public;
revoke all on function private.protect_columns() from public;
revoke all on function private.handle_new_auth_user() from public;

commit;
