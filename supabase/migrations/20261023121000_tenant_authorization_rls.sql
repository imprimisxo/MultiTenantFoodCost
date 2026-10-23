begin;

create or replace function private.is_active_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.memberships as membership
      where membership.organization_id = target_organization_id
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
    );
$$;

create or replace function private.has_permission(
  target_organization_id uuid,
  target_permission_key text,
  target_location_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and (
      target_location_id is null
      or exists (
        select 1
        from public.locations as target_location
        where target_location.organization_id = target_organization_id
          and target_location.id = target_location_id
      )
    )
    and exists (
      select 1
      from public.memberships as membership
      inner join public.role_assignments as assignment
        on assignment.organization_id = membership.organization_id
        and assignment.membership_id = membership.id
      inner join public.role_permissions as role_permission
        on role_permission.organization_id = assignment.organization_id
        and role_permission.role_id = assignment.role_id
      where membership.organization_id = target_organization_id
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
        and role_permission.permission_key = target_permission_key
        and (
          (target_location_id is null and assignment.location_id is null)
          or
          (
            target_location_id is not null
            and (assignment.location_id is null or assignment.location_id = target_location_id)
          )
        )
    );
$$;

create or replace function private.has_boolean_entitlement(
  target_organization_id uuid,
  target_entitlement_key text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_active_member(target_organization_id)
    and coalesce(
      (
        select subscription_entitlement.boolean_value
        from public.subscriptions as subscription
        inner join public.subscription_entitlements as subscription_entitlement
          on subscription_entitlement.organization_id = subscription.organization_id
          and subscription_entitlement.subscription_id = subscription.id
        inner join public.entitlements as entitlement
          on entitlement.id = subscription_entitlement.entitlement_id
        where subscription.organization_id = target_organization_id
          and subscription.status in ('trialing', 'active')
          and entitlement.key = target_entitlement_key
          and entitlement.value_type = 'boolean'
        limit 1
      ),
      false
    );
$$;

create or replace function private.entitlement_numeric_limit(
  target_organization_id uuid,
  target_entitlement_key text
)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when not private.is_active_member(target_organization_id) then null
    else (
      select subscription_entitlement.numeric_value
      from public.subscriptions as subscription
      inner join public.subscription_entitlements as subscription_entitlement
        on subscription_entitlement.organization_id = subscription.organization_id
        and subscription_entitlement.subscription_id = subscription.id
      inner join public.entitlements as entitlement
        on entitlement.id = subscription_entitlement.entitlement_id
      where subscription.organization_id = target_organization_id
        and subscription.status in ('trialing', 'active')
        and entitlement.key = target_entitlement_key
        and entitlement.value_type = 'numeric'
      limit 1
    )
  end;
$$;

revoke all on function private.is_active_member(uuid) from public, anon;
revoke all on function private.has_permission(uuid, text, uuid) from public, anon;
revoke all on function private.has_boolean_entitlement(uuid, text) from public, anon;
revoke all on function private.entitlement_numeric_limit(uuid, text) from public, anon;

grant usage on schema private to authenticated;
grant execute on function private.is_active_member(uuid) to authenticated;
grant execute on function private.has_permission(uuid, text, uuid) to authenticated;
grant execute on function private.has_boolean_entitlement(uuid, text) to authenticated;
grant execute on function private.entitlement_numeric_limit(uuid, text) to authenticated;

alter table public.profiles enable row level security;
alter table public.profiles force row level security;
alter table public.organizations enable row level security;
alter table public.organizations force row level security;
alter table public.locations enable row level security;
alter table public.locations force row level security;
alter table public.memberships enable row level security;
alter table public.memberships force row level security;
alter table public.permissions enable row level security;
alter table public.permissions force row level security;
alter table public.roles enable row level security;
alter table public.roles force row level security;
alter table public.role_permissions enable row level security;
alter table public.role_permissions force row level security;
alter table public.role_assignments enable row level security;
alter table public.role_assignments force row level security;
alter table public.plans enable row level security;
alter table public.plans force row level security;
alter table public.entitlements enable row level security;
alter table public.entitlements force row level security;
alter table public.plan_entitlements enable row level security;
alter table public.plan_entitlements force row level security;
alter table public.subscriptions enable row level security;
alter table public.subscriptions force row level security;
alter table public.subscription_entitlements enable row level security;
alter table public.subscription_entitlements force row level security;

create policy profiles_select_own
on public.profiles
for select
to authenticated
using ((select auth.uid()) is not null and id = (select auth.uid()));

create policy profiles_update_own
on public.profiles
for update
to authenticated
using ((select auth.uid()) is not null and id = (select auth.uid()))
with check ((select auth.uid()) is not null and id = (select auth.uid()));

create policy organizations_select_active_member
on public.organizations
for select
to authenticated
using ((select private.is_active_member(id)));

create policy organizations_update_authorized
on public.organizations
for update
to authenticated
using ((select private.has_permission(id, 'organization.update', null)))
with check ((select private.has_permission(id, 'organization.update', null)));

create policy locations_select_authorized
on public.locations
for select
to authenticated
using ((select private.has_permission(organization_id, 'locations.read', id)));

create policy locations_insert_authorized
on public.locations
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.has_permission(organization_id, 'locations.write', null))
);

create policy locations_update_authorized
on public.locations
for update
to authenticated
using ((select private.has_permission(organization_id, 'locations.write', id)))
with check ((select private.has_permission(organization_id, 'locations.write', id)));

create policy memberships_select_self_or_authorized
on public.memberships
for select
to authenticated
using (
  ((select auth.uid()) is not null and user_id = (select auth.uid()))
  or (select private.has_permission(organization_id, 'memberships.read', null))
);

create policy permissions_select_authenticated
on public.permissions
for select
to authenticated
using ((select auth.uid()) is not null);

create policy roles_select_active_member
on public.roles
for select
to authenticated
using ((select private.is_active_member(organization_id)));

create policy role_permissions_select_active_member
on public.role_permissions
for select
to authenticated
using ((select private.is_active_member(organization_id)));

create policy role_assignments_select_self_or_authorized
on public.role_assignments
for select
to authenticated
using (
  exists (
    select 1
    from public.memberships as own_membership
    where own_membership.organization_id = role_assignments.organization_id
      and own_membership.id = role_assignments.membership_id
      and own_membership.user_id = (select auth.uid())
  )
  or (select private.has_permission(organization_id, 'roles.read', null))
);

create policy plans_select_authenticated
on public.plans
for select
to authenticated
using ((select auth.uid()) is not null and is_active);

create policy entitlements_select_authenticated
on public.entitlements
for select
to authenticated
using ((select auth.uid()) is not null);

create policy plan_entitlements_select_authenticated
on public.plan_entitlements
for select
to authenticated
using ((select auth.uid()) is not null);

create policy subscriptions_select_authorized
on public.subscriptions
for select
to authenticated
using ((select private.has_permission(organization_id, 'billing.read', null)));

create policy subscription_entitlements_select_authorized
on public.subscription_entitlements
for select
to authenticated
using ((select private.has_permission(organization_id, 'billing.read', null)));

revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.organizations from public, anon, authenticated;
revoke all on table public.locations from public, anon, authenticated;
revoke all on table public.memberships from public, anon, authenticated;
revoke all on table public.permissions from public, anon, authenticated;
revoke all on table public.roles from public, anon, authenticated;
revoke all on table public.role_permissions from public, anon, authenticated;
revoke all on table public.role_assignments from public, anon, authenticated;
revoke all on table public.plans from public, anon, authenticated;
revoke all on table public.entitlements from public, anon, authenticated;
revoke all on table public.plan_entitlements from public, anon, authenticated;
revoke all on table public.subscriptions from public, anon, authenticated;
revoke all on table public.subscription_entitlements from public, anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (display_name, locale, time_zone) on table public.profiles to authenticated;

grant select on table public.organizations to authenticated;
grant update (name, slug, default_currency) on table public.organizations to authenticated;

grant select on table public.locations to authenticated;
grant insert (organization_id, name, code, time_zone, created_by)
  on table public.locations to authenticated;
grant update (name, code, time_zone, is_active)
  on table public.locations to authenticated;

grant select on table public.memberships to authenticated;
grant select on table public.permissions to authenticated;
grant select on table public.roles to authenticated;
grant select on table public.role_permissions to authenticated;
grant select on table public.role_assignments to authenticated;
grant select on table public.plans to authenticated;
grant select on table public.entitlements to authenticated;
grant select on table public.plan_entitlements to authenticated;
grant select on table public.subscriptions to authenticated;
grant select on table public.subscription_entitlements to authenticated;

grant all on table public.profiles to service_role;
grant all on table public.organizations to service_role;
grant all on table public.locations to service_role;
grant all on table public.memberships to service_role;
grant all on table public.permissions to service_role;
grant all on table public.roles to service_role;
grant all on table public.role_permissions to service_role;
grant all on table public.role_assignments to service_role;
grant all on table public.plans to service_role;
grant all on table public.entitlements to service_role;
grant all on table public.plan_entitlements to service_role;
grant all on table public.subscriptions to service_role;
grant all on table public.subscription_entitlements to service_role;

commit;
