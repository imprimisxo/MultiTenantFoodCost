begin;

create table public.staff_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  email text not null,
  token_hash bytea not null unique,
  role_id uuid not null,
  location_id uuid,
  status text not null default 'pending',
  expires_at timestamptz not null,
  created_by uuid not null references auth.users (id) on delete restrict,
  accepted_by uuid references auth.users (id) on delete restrict,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint staff_invitations_organization_id_id_key unique (organization_id, id),
  constraint staff_invitations_role_tenant_fk
    foreign key (organization_id, role_id)
    references public.roles (organization_id, id)
    on delete restrict,
  constraint staff_invitations_location_tenant_fk
    foreign key (organization_id, location_id)
    references public.locations (organization_id, id)
    on delete restrict,
  constraint staff_invitations_email_normalized
    check (email = lower(btrim(email)) and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
  constraint staff_invitations_status
    check (status in ('pending', 'accepted', 'revoked', 'expired')),
  constraint staff_invitations_acceptance_shape check (
    (status = 'accepted' and accepted_by is not null and accepted_at is not null and revoked_at is null)
    or
    (status = 'revoked' and accepted_by is null and accepted_at is null and revoked_at is not null)
    or
    (status in ('pending', 'expired') and accepted_by is null and accepted_at is null and revoked_at is null)
  )
);

create unique index staff_invitations_one_pending_recipient_key
  on public.staff_invitations (organization_id, email)
  where status = 'pending';

create index staff_invitations_admin_lookup_idx
  on public.staff_invitations (organization_id, status, expires_at desc);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  actor_user_id uuid references auth.users (id) on delete restrict,
  event_type text not null,
  target_type text not null,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default statement_timestamp(),
  constraint audit_events_organization_id_id_key unique (organization_id, id),
  constraint audit_events_event_type_format
    check (event_type ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'),
  constraint audit_events_target_type_format check (target_type ~ '^[a-z][a-z0-9_]*$'),
  constraint audit_events_metadata_object check (jsonb_typeof(metadata) = 'object')
);

create index audit_events_tenant_timeline_idx
  on public.audit_events (organization_id, created_at desc, id desc);

create trigger staff_invitations_set_updated_at
before update on public.staff_invitations
for each row execute function private.set_updated_at();

create trigger staff_invitations_protect_identity
before update on public.staff_invitations
for each row execute function private.protect_columns(
  'id',
  'organization_id',
  'email',
  'token_hash',
  'role_id',
  'location_id',
  'expires_at',
  'created_by',
  'created_at'
);

insert into public.plans (
  id,
  code,
  name,
  description,
  billing_interval,
  price_amount,
  currency_code,
  is_active
)
values (
  '60000000-0000-0000-0000-000000000001',
  'starter',
  'Starter',
  'Starter plan used for the initial organization trial.',
  'month',
  49.00,
  'USD',
  true
)
on conflict (id) do update
set
  name = excluded.name,
  description = excluded.description,
  billing_interval = excluded.billing_interval,
  price_amount = excluded.price_amount,
  currency_code = excluded.currency_code,
  is_active = excluded.is_active;

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
on conflict (id) do update
set description = excluded.description;

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
on conflict (plan_id, entitlement_id) do update
set
  value_type = excluded.value_type,
  boolean_value = excluded.boolean_value,
  numeric_value = excluded.numeric_value;

create or replace function private.require_verified_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  is_verified boolean;
begin
  if current_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select users.email_confirmed_at is not null
  into is_verified
  from auth.users as users
  where users.id = current_user_id;

  if coalesce(is_verified, false) is false then
    raise exception 'verified email required' using errcode = '42501';
  end if;

  return current_user_id;
end;
$$;

create or replace function private.enforce_active_location_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  location_limit numeric;
  active_location_count bigint;
begin
  if auth.uid() is null then
    return new;
  end if;

  if (
    tg_op = 'INSERT'
    and not private.has_permission(new.organization_id, 'locations.write', null)
  ) or (
    tg_op = 'UPDATE'
    and not private.has_permission(new.organization_id, 'locations.write', new.id)
  ) then
    raise exception 'location write permission required'
      using errcode = '42501';
  end if;

  if new.is_active is false then
    return new;
  end if;

  if tg_op = 'UPDATE' and old.is_active is true then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.organization_id::text, 1938127)
  );

  location_limit := private.entitlement_numeric_limit(
    new.organization_id,
    'locations.maximum'
  );

  if location_limit is null or trunc(location_limit) < 1 then
    raise exception 'an active locations.maximum entitlement is required'
      using errcode = '42501';
  end if;

  select count(*)
  into active_location_count
  from public.locations as location
  where location.organization_id = new.organization_id
    and location.is_active;

  if active_location_count >= trunc(location_limit) then
    raise exception 'active location entitlement limit reached'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger locations_enforce_active_entitlement
before insert or update of is_active on public.locations
for each row execute function private.enforce_active_location_entitlement();

create or replace function private.audit_location_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  insert into public.audit_events (
    organization_id,
    actor_user_id,
    event_type,
    target_type,
    target_id,
    metadata
  )
  values (
    new.organization_id,
    auth.uid(),
    case when tg_op = 'INSERT' then 'location.created' else 'location.updated' end,
    'location',
    new.id,
    jsonb_build_object('active', new.is_active, 'code', new.code)
  );

  return new;
end;
$$;

create trigger locations_audit_change
after insert or update on public.locations
for each row execute function private.audit_location_change();

create or replace function private.audit_organization_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    insert into public.audit_events (
      organization_id,
      actor_user_id,
      event_type,
      target_type,
      target_id,
      metadata
    )
    values (
      new.id,
      auth.uid(),
      'organization.updated',
      'organization',
      new.id,
      jsonb_build_object('slug', new.slug)
    );
  end if;

  return new;
end;
$$;

create trigger organizations_audit_update
after update on public.organizations
for each row execute function private.audit_organization_update();

create or replace function public.onboard_organization(
  organization_name text,
  organization_slug text,
  default_currency text,
  first_location_name text,
  first_location_code text,
  first_location_time_zone text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.require_verified_user();
  new_organization public.organizations%rowtype;
  new_location public.locations%rowtype;
  new_membership public.memberships%rowtype;
  owner_role public.roles%rowtype;
  starter_plan public.plans%rowtype;
  new_subscription public.subscriptions%rowtype;
begin
  if btrim(coalesce(organization_name, '')) = '' or length(btrim(organization_name)) > 120 then
    raise exception 'organization name must be between 1 and 120 characters'
      using errcode = '22023';
  end if;

  if organization_slug is null or organization_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or length(organization_slug) > 80 then
    raise exception 'organization slug is invalid' using errcode = '22023';
  end if;

  if default_currency is null or default_currency !~ '^[A-Z]{3}$' then
    raise exception 'currency must be a three-letter ISO 4217 code' using errcode = '22023';
  end if;

  if btrim(coalesce(first_location_name, '')) = '' or length(btrim(first_location_name)) > 120 then
    raise exception 'location name must be between 1 and 120 characters'
      using errcode = '22023';
  end if;

  if first_location_code is null or first_location_code !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or length(first_location_code) > 40 then
    raise exception 'location code is invalid' using errcode = '22023';
  end if;

  if btrim(coalesce(first_location_time_zone, '')) = '' or length(first_location_time_zone) > 100 then
    raise exception 'location time zone is invalid' using errcode = '22023';
  end if;

  select plan.*
  into strict starter_plan
  from public.plans as plan
  where plan.code = 'starter'
    and plan.is_active;

  insert into public.organizations (name, slug, default_currency, created_by)
  values (
    btrim(organization_name),
    organization_slug,
    default_currency,
    current_user_id
  )
  returning * into new_organization;

  insert into public.memberships (organization_id, user_id, status, created_by)
  values (new_organization.id, current_user_id, 'active', current_user_id)
  returning * into new_membership;

  insert into public.roles (
    organization_id,
    key,
    name,
    description,
    is_system,
    created_by
  )
  values (
    new_organization.id,
    'owner',
    'Owner',
    'Full organization administration.',
    true,
    current_user_id
  )
  returning * into owner_role;

  insert into public.roles (
    organization_id,
    key,
    name,
    description,
    is_system,
    created_by
  )
  values
    (
      new_organization.id,
      'location_manager',
      'Location manager',
      'Read and update one assigned location.',
      true,
      current_user_id
    ),
    (
      new_organization.id,
      'viewer',
      'Viewer',
      'Read an assigned location.',
      true,
      current_user_id
    );

  insert into public.role_permissions (
    organization_id,
    role_id,
    permission_key,
    granted_by
  )
  select new_organization.id, owner_role.id, permission.key, current_user_id
  from public.permissions as permission;

  insert into public.role_permissions (
    organization_id,
    role_id,
    permission_key,
    granted_by
  )
  select role.organization_id, role.id, permission_key, current_user_id
  from public.roles as role
  cross join lateral (
    values ('locations.read'::text), ('locations.write'::text)
  ) as granted(permission_key)
  where role.organization_id = new_organization.id
    and role.key = 'location_manager';

  insert into public.role_permissions (
    organization_id,
    role_id,
    permission_key,
    granted_by
  )
  select role.organization_id, role.id, 'locations.read', current_user_id
  from public.roles as role
  where role.organization_id = new_organization.id
    and role.key = 'viewer';

  insert into public.role_assignments (
    organization_id,
    membership_id,
    role_id,
    location_id,
    assigned_by
  )
  values (
    new_organization.id,
    new_membership.id,
    owner_role.id,
    null,
    current_user_id
  );

  insert into public.subscriptions (
    organization_id,
    plan_id,
    status,
    billing_amount,
    currency_code,
    provider,
    current_period_start,
    current_period_end,
    created_by
  )
  values (
    new_organization.id,
    starter_plan.id,
    'trialing',
    starter_plan.price_amount,
    starter_plan.currency_code,
    'internal',
    statement_timestamp(),
    statement_timestamp() + interval '14 days',
    current_user_id
  )
  returning * into new_subscription;

  insert into public.subscription_entitlements (
    organization_id,
    subscription_id,
    entitlement_id,
    value_type,
    boolean_value,
    numeric_value,
    source
  )
  select
    new_organization.id,
    new_subscription.id,
    plan_entitlement.entitlement_id,
    plan_entitlement.value_type,
    plan_entitlement.boolean_value,
    plan_entitlement.numeric_value,
    'plan'
  from public.plan_entitlements as plan_entitlement
  where plan_entitlement.plan_id = starter_plan.id;

  insert into public.locations (
    organization_id,
    name,
    code,
    time_zone,
    created_by
  )
  values (
    new_organization.id,
    btrim(first_location_name),
    first_location_code,
    btrim(first_location_time_zone),
    current_user_id
  )
  returning * into new_location;

  insert into public.audit_events (
    organization_id,
    actor_user_id,
    event_type,
    target_type,
    target_id,
    metadata
  )
  values (
    new_organization.id,
    current_user_id,
    'organization.created',
    'organization',
    new_organization.id,
    jsonb_build_object('initial_location_id', new_location.id)
  );

  return jsonb_build_object(
    'organizationId', new_organization.id,
    'locationId', new_location.id
  );
end;
$$;

create or replace function public.create_staff_invitation(
  target_organization_id uuid,
  recipient_email text,
  target_role_id uuid,
  target_location_id uuid default null,
  expires_in_hours integer default 72
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.require_verified_user();
  current_user_email text;
  normalized_email text := lower(btrim(coalesce(recipient_email, '')));
  invitation_token text;
  new_invitation public.staff_invitations%rowtype;
begin
  if normalized_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    or length(normalized_email) > 254 then
    raise exception 'recipient email is invalid' using errcode = '22023';
  end if;

  if expires_in_hours < 1 or expires_in_hours > 168 then
    raise exception 'invitation expiry must be between 1 and 168 hours'
      using errcode = '22023';
  end if;

  if not private.has_permission(
    target_organization_id,
    'memberships.manage',
    target_location_id
  ) then
    raise exception 'membership management permission required'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.roles as role
    where role.organization_id = target_organization_id
      and role.id = target_role_id
  ) then
    raise exception 'role does not belong to organization' using errcode = '22023';
  end if;

  if target_location_id is not null and not exists (
    select 1
    from public.locations as location
    where location.organization_id = target_organization_id
      and location.id = target_location_id
      and location.is_active
  ) then
    raise exception 'active location does not belong to organization'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.role_permissions as target_permission
    where target_permission.organization_id = target_organization_id
      and target_permission.role_id = target_role_id
      and not private.has_permission(
        target_organization_id,
        target_permission.permission_key,
        target_location_id
      )
  ) then
    raise exception 'cannot grant a role with permissions the inviter does not hold'
      using errcode = '42501';
  end if;

  select lower(users.email)
  into current_user_email
  from auth.users as users
  where users.id = current_user_id;

  if normalized_email = current_user_email then
    raise exception 'cannot invite your own email address' using errcode = '22023';
  end if;

  update public.staff_invitations as invitation
  set status = 'expired'
  where invitation.organization_id = target_organization_id
    and invitation.email = normalized_email
    and invitation.status = 'pending'
    and invitation.expires_at <= statement_timestamp();

  invitation_token := encode(extensions.gen_random_bytes(32), 'hex');

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
    target_organization_id,
    normalized_email,
    extensions.digest(invitation_token, 'sha256'),
    target_role_id,
    target_location_id,
    statement_timestamp() + make_interval(hours => expires_in_hours),
    current_user_id
  )
  returning * into new_invitation;

  insert into public.audit_events (
    organization_id,
    actor_user_id,
    event_type,
    target_type,
    target_id,
    metadata
  )
  values (
    target_organization_id,
    current_user_id,
    'invitation.created',
    'staff_invitation',
    new_invitation.id,
    jsonb_build_object(
      'email', normalized_email,
      'role_id', target_role_id,
      'location_id', target_location_id,
      'expires_at', new_invitation.expires_at
    )
  );

  return jsonb_build_object(
    'invitationId', new_invitation.id,
    'token', invitation_token,
    'expiresAt', new_invitation.expires_at
  );
exception
  when unique_violation then
    raise exception 'a pending invitation already exists for this recipient'
      using errcode = '23505';
end;
$$;

create or replace function public.revoke_staff_invitation(target_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.require_verified_user();
  invitation_record public.staff_invitations%rowtype;
begin
  select invitation.*
  into invitation_record
  from public.staff_invitations as invitation
  where invitation.id = target_invitation_id
  for update;

  if not found then
    raise exception 'invitation not found' using errcode = 'P0002';
  end if;

  if not private.has_permission(
    invitation_record.organization_id,
    'memberships.manage',
    invitation_record.location_id
  ) then
    raise exception 'membership management permission required'
      using errcode = '42501';
  end if;

  if invitation_record.status <> 'pending' then
    raise exception 'only pending invitations can be revoked' using errcode = '22023';
  end if;

  update public.staff_invitations
  set status = 'revoked', revoked_at = statement_timestamp()
  where id = invitation_record.id;

  insert into public.audit_events (
    organization_id,
    actor_user_id,
    event_type,
    target_type,
    target_id
  )
  values (
    invitation_record.organization_id,
    current_user_id,
    'invitation.revoked',
    'staff_invitation',
    invitation_record.id
  );
end;
$$;

create or replace function public.accept_staff_invitation(invitation_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.require_verified_user();
  current_user_email text;
  invitation_record public.staff_invitations%rowtype;
  membership_record public.memberships%rowtype;
begin
  if invitation_token is null or invitation_token !~ '^[a-f0-9]{64}$' then
    raise exception 'invitation token is invalid' using errcode = '22023';
  end if;

  select invitation.*
  into invitation_record
  from public.staff_invitations as invitation
  where invitation.token_hash = extensions.digest(invitation_token, 'sha256')
  for update;

  if not found then
    raise exception 'invitation token is invalid' using errcode = '22023';
  end if;

  if invitation_record.status <> 'pending' then
    raise exception 'invitation is no longer available' using errcode = '22023';
  end if;

  if invitation_record.expires_at <= statement_timestamp() then
    update public.staff_invitations
    set status = 'expired'
    where id = invitation_record.id;

    raise exception 'invitation has expired' using errcode = '22023';
  end if;

  select lower(users.email)
  into current_user_email
  from auth.users as users
  where users.id = current_user_id;

  if current_user_email is distinct from invitation_record.email then
    raise exception 'invitation belongs to a different recipient'
      using errcode = '42501';
  end if;

  select membership.*
  into membership_record
  from public.memberships as membership
  where membership.organization_id = invitation_record.organization_id
    and membership.user_id = current_user_id
  for update;

  if not found then
    insert into public.memberships (organization_id, user_id, status, created_by)
    values (
      invitation_record.organization_id,
      current_user_id,
      'active',
      invitation_record.created_by
    )
    returning * into membership_record;
  elsif membership_record.status = 'invited' then
    update public.memberships
    set status = 'active'
    where id = membership_record.id
    returning * into membership_record;
  elsif membership_record.status in ('suspended', 'revoked') then
    raise exception 'existing membership is not eligible for invitation acceptance'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.role_assignments as assignment
    where assignment.organization_id = invitation_record.organization_id
      and assignment.membership_id = membership_record.id
      and assignment.role_id = invitation_record.role_id
      and assignment.location_id is not distinct from invitation_record.location_id
  ) then
    insert into public.role_assignments (
      organization_id,
      membership_id,
      role_id,
      location_id,
      assigned_by
    )
    values (
      invitation_record.organization_id,
      membership_record.id,
      invitation_record.role_id,
      invitation_record.location_id,
      invitation_record.created_by
    );
  end if;

  update public.staff_invitations
  set
    status = 'accepted',
    accepted_by = current_user_id,
    accepted_at = statement_timestamp()
  where id = invitation_record.id;

  insert into public.audit_events (
    organization_id,
    actor_user_id,
    event_type,
    target_type,
    target_id,
    metadata
  )
  values (
    invitation_record.organization_id,
    current_user_id,
    'invitation.accepted',
    'staff_invitation',
    invitation_record.id,
    jsonb_build_object('membership_id', membership_record.id)
  );

  return jsonb_build_object(
    'organizationId', invitation_record.organization_id,
    'locationId', invitation_record.location_id
  );
end;
$$;

create or replace function public.organization_dashboard(
  target_organization_id uuid,
  target_location_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  plan_name text;
  subscription_status text;
  period_end timestamptz;
  location_limit numeric;
  analytics_enabled boolean;
  active_location_count bigint;
  granted_permissions jsonb;
begin
  if not private.is_active_member(target_organization_id) then
    raise exception 'active organization membership required' using errcode = '42501';
  end if;

  if target_location_id is not null and not private.has_permission(
    target_organization_id,
    'locations.read',
    target_location_id
  ) then
    raise exception 'location access denied' using errcode = '42501';
  end if;

  select plan.name, subscription.status, subscription.current_period_end
  into plan_name, subscription_status, period_end
  from public.subscriptions as subscription
  inner join public.plans as plan on plan.id = subscription.plan_id
  where subscription.organization_id = target_organization_id
    and subscription.status in ('trialing', 'active', 'past_due', 'paused')
  order by subscription.created_at desc
  limit 1;

  location_limit := private.entitlement_numeric_limit(
    target_organization_id,
    'locations.maximum'
  );
  analytics_enabled := private.has_boolean_entitlement(
    target_organization_id,
    'analytics.enabled'
  );

  select count(*)
  into active_location_count
  from public.locations as location
  where location.organization_id = target_organization_id
    and location.is_active;

  select coalesce(jsonb_agg(permission.permission_key order by permission.permission_key), '[]'::jsonb)
  into granted_permissions
  from (
    select distinct role_permission.permission_key
    from public.memberships as membership
    inner join public.role_assignments as assignment
      on assignment.organization_id = membership.organization_id
      and assignment.membership_id = membership.id
    inner join public.role_permissions as role_permission
      on role_permission.organization_id = assignment.organization_id
      and role_permission.role_id = assignment.role_id
    where membership.organization_id = target_organization_id
      and membership.user_id = auth.uid()
      and membership.status = 'active'
      and (
        assignment.location_id is null
        or (
          target_location_id is not null
          and assignment.location_id = target_location_id
        )
      )
  ) as permission;

  if jsonb_array_length(granted_permissions) = 0 then
    raise exception 'an effective permission is required for this dashboard context'
      using errcode = '42501';
  end if;

  return jsonb_build_object(
    'planName', plan_name,
    'subscriptionStatus', coalesce(subscription_status, 'none'),
    'currentPeriodEnd', period_end,
    'activeLocationCount', active_location_count,
    'locationLimit', case when location_limit is null then null else location_limit::text end,
    'analyticsEnabled', analytics_enabled,
    'permissions', granted_permissions
  );
end;
$$;

alter table public.staff_invitations enable row level security;
alter table public.staff_invitations force row level security;
alter table public.audit_events enable row level security;
alter table public.audit_events force row level security;

create policy staff_invitations_select_authorized
on public.staff_invitations
for select
to authenticated
using ((select private.has_permission(organization_id, 'memberships.read', location_id)));

create policy audit_events_select_authorized
on public.audit_events
for select
to authenticated
using (
  (select private.has_permission(organization_id, 'memberships.read', null))
  or (select private.has_permission(organization_id, 'roles.read', null))
);

revoke all on table public.staff_invitations from public, anon, authenticated;
revoke all on table public.audit_events from public, anon, authenticated;
grant select on table public.staff_invitations to authenticated;
grant select on table public.audit_events to authenticated;
grant all on table public.staff_invitations to service_role;
grant all on table public.audit_events to service_role;

revoke all on function private.require_verified_user() from public, anon, authenticated;
revoke all on function private.enforce_active_location_entitlement() from public, anon, authenticated;
revoke all on function private.audit_location_change() from public, anon, authenticated;
revoke all on function private.audit_organization_update() from public, anon, authenticated;

revoke all on function public.onboard_organization(text, text, text, text, text, text)
  from public, anon;
revoke all on function public.create_staff_invitation(uuid, text, uuid, uuid, integer)
  from public, anon;
revoke all on function public.revoke_staff_invitation(uuid) from public, anon;
revoke all on function public.accept_staff_invitation(text) from public, anon;
revoke all on function public.organization_dashboard(uuid, uuid) from public, anon;

grant execute on function public.onboard_organization(text, text, text, text, text, text)
  to authenticated;
grant execute on function public.create_staff_invitation(uuid, text, uuid, uuid, integer)
  to authenticated;
grant execute on function public.revoke_staff_invitation(uuid) to authenticated;
grant execute on function public.accept_staff_invitation(text) to authenticated;
grant execute on function public.organization_dashboard(uuid, uuid) to authenticated;

commit;
