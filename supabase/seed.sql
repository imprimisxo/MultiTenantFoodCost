-- Local-development fixtures only. Do not run this file against production.

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'owner@example.test',
    extensions.crypt('local-password-only', extensions.gen_salt('bf')),
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Alex Owner"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'manager@example.test',
    extensions.crypt('local-password-only', extensions.gen_salt('bf')),
    statement_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"Morgan Manager"}'::jsonb,
    statement_timestamp(),
    statement_timestamp()
  )
on conflict (id) do nothing;

insert into auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
values
  (
    '11000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '{"sub":"10000000-0000-0000-0000-000000000001","email":"owner@example.test"}'::jsonb,
    'email',
    statement_timestamp(),
    statement_timestamp(),
    statement_timestamp()
  ),
  (
    '11000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '{"sub":"10000000-0000-0000-0000-000000000002","email":"manager@example.test"}'::jsonb,
    'email',
    statement_timestamp(),
    statement_timestamp(),
    statement_timestamp()
  )
on conflict (provider_id, provider) do nothing;

insert into public.organizations (id, name, slug, default_currency, created_by)
values (
  '20000000-0000-0000-0000-000000000001',
  'Demo Restaurant Group',
  'demo-restaurant-group',
  'USD',
  '10000000-0000-0000-0000-000000000001'
)
on conflict (id) do nothing;

insert into public.locations (id, organization_id, name, code, time_zone, created_by)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'Downtown',
    'downtown',
    'America/Chicago',
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'Northside',
    'northside',
    'America/Chicago',
    '10000000-0000-0000-0000-000000000001'
  )
on conflict (id) do nothing;

insert into public.memberships (id, organization_id, user_id, status, created_by)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active',
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'active',
    '10000000-0000-0000-0000-000000000001'
  )
on conflict (id) do nothing;

insert into public.roles (id, organization_id, key, name, description, is_system, created_by)
values
  (
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'owner',
    'Owner',
    'Full organization administration.',
    true,
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    '50000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'location_manager',
    'Location manager',
    'Read and update one assigned location.',
    true,
    '10000000-0000-0000-0000-000000000001'
  )
on conflict (id) do nothing;

insert into public.role_permissions (organization_id, role_id, permission_key, granted_by)
select
  '20000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000001',
  permission.key,
  '10000000-0000-0000-0000-000000000001'
from public.permissions as permission
on conflict do nothing;

insert into public.role_permissions (organization_id, role_id, permission_key, granted_by)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000002',
    'locations.read',
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    '20000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000002',
    'locations.write',
    '10000000-0000-0000-0000-000000000001'
  )
on conflict do nothing;

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
    '51000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    null,
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    '51000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001'
  )
on conflict (id) do nothing;

insert into public.plans (
  id,
  code,
  name,
  description,
  billing_interval,
  price_amount,
  currency_code
)
values (
  '60000000-0000-0000-0000-000000000001',
  'starter',
  'Starter',
  'Local development plan fixture.',
  'month',
  49.00,
  'USD'
)
on conflict (id) do nothing;

insert into public.entitlements (id, key, description, value_type)
values
  (
    '70000000-0000-0000-0000-000000000001',
    'locations.maximum',
    'Maximum active locations.',
    'numeric'
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    'analytics.enabled',
    'Access to analytics capabilities.',
    'boolean'
  )
on conflict (id) do nothing;

insert into public.plan_entitlements (
  plan_id,
  entitlement_id,
  value_type,
  boolean_value,
  numeric_value
)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'numeric',
    null,
    3.000000
  ),
  (
    '60000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000002',
    'boolean',
    false,
    null
  )
on conflict do nothing;

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
  '80000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '60000000-0000-0000-0000-000000000001',
  'active',
  49.00,
  'USD',
  '10000000-0000-0000-0000-000000000001'
)
on conflict (id) do nothing;

insert into public.subscription_entitlements (
  id,
  organization_id,
  subscription_id,
  entitlement_id,
  value_type,
  boolean_value,
  numeric_value,
  source
)
values
  (
    '90000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '80000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000001',
    'numeric',
    null,
    3.000000,
    'plan'
  ),
  (
    '90000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    '80000000-0000-0000-0000-000000000001',
    '70000000-0000-0000-0000-000000000002',
    'boolean',
    false,
    null,
    'plan'
  )
on conflict (id) do nothing;
