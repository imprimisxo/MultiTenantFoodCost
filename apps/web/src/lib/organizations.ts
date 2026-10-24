import "server-only";

import { z } from "zod";
import { cookies } from "next/headers";

import { createClient } from "./supabase/server";

export const ACTIVE_ORGANIZATION_COOKIE = "restaurantos_active_organization";
export const ACTIVE_LOCATION_COOKIE = "restaurantos_active_location";
export const INVITATION_TOKEN_COOKIE = "restaurantos_invitation_token";
export const INVITATION_ORGANIZATION_COOKIE =
  "restaurantos_invitation_organization";

export interface OrganizationSummary {
  defaultCurrency: string;
  id: string;
  name: string;
  slug: string;
}

export interface LocationSummary {
  code: string;
  id: string;
  isActive: boolean;
  name: string;
  timeZone: string;
}

export interface OrganizationContext {
  location: LocationSummary | null;
  locations: LocationSummary[];
  organization: OrganizationSummary;
  organizations: OrganizationSummary[];
}

interface MembershipRow {
  organization_id: string;
}

interface OrganizationRow {
  default_currency: string;
  id: string;
  name: string;
  slug: string;
}

interface LocationRow {
  code: string;
  id: string;
  is_active: boolean;
  name: string;
  time_zone: string;
}

const dashboardSchema = z.object({
  activeLocationCount: z.number().int().nonnegative(),
  analyticsEnabled: z.boolean(),
  currentPeriodEnd: z.string().nullable(),
  locationLimit: z.string().nullable(),
  permissions: z.array(z.string()),
  planName: z.string().nullable(),
  subscriptionStatus: z.string(),
});

export type DashboardData = z.infer<typeof dashboardSchema>;

export async function listOrganizations(
  userId: string,
): Promise<OrganizationSummary[]> {
  const supabase = await createClient();
  const { data: membershipData, error: membershipError } = await supabase
    .from("memberships")
    .select("organization_id")
    .eq("user_id", userId)
    .eq("status", "active");

  if (membershipError) {
    throw new Error("Unable to load organization memberships.");
  }

  const memberships = (membershipData ?? []) as unknown as MembershipRow[];
  const organizationIds = memberships.map(
    (membership) => membership.organization_id,
  );

  if (organizationIds.length === 0) {
    return [];
  }

  const { data: organizationData, error: organizationError } = await supabase
    .from("organizations")
    .select("id, name, slug, default_currency")
    .in("id", organizationIds)
    .order("name");

  if (organizationError) {
    throw new Error("Unable to load organizations.");
  }

  return ((organizationData ?? []) as unknown as OrganizationRow[]).map(
    (organization) => ({
      defaultCurrency: organization.default_currency,
      id: organization.id,
      name: organization.name,
      slug: organization.slug,
    }),
  );
}

export async function listLocations(
  organizationId: string,
): Promise<LocationSummary[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("locations")
    .select("id, name, code, time_zone, is_active")
    .eq("organization_id", organizationId)
    .order("name");

  if (error) {
    throw new Error("Unable to load authorized locations.");
  }

  return ((data ?? []) as unknown as LocationRow[]).map((location) => ({
    code: location.code,
    id: location.id,
    isActive: location.is_active,
    name: location.name,
    timeZone: location.time_zone,
  }));
}

export async function loadDashboard(
  organizationId: string,
  locationId: string | null,
): Promise<DashboardData> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("organization_dashboard", {
    target_location_id: locationId,
    target_organization_id: organizationId,
  });

  if (error) {
    throw new Error("Unable to load the authorized organization dashboard.");
  }

  return dashboardSchema.parse(data);
}

export async function resolveOrganizationContext(
  userId: string,
): Promise<OrganizationContext | null> {
  const organizations = await listOrganizations(userId);
  if (organizations.length === 0) {
    return null;
  }

  const cookieStore = await cookies();
  const requestedOrganizationId = cookieStore.get(
    ACTIVE_ORGANIZATION_COOKIE,
  )?.value;
  const organization =
    organizations.find(
      (candidate) => candidate.id === requestedOrganizationId,
    ) ?? organizations[0];
  const locations = await listLocations(organization.id);
  const requestedLocationId = cookieStore.get(ACTIVE_LOCATION_COOKIE)?.value;
  const location =
    locations.find(
      (candidate) => candidate.id === requestedLocationId && candidate.isActive,
    ) ??
    locations.find((candidate) => candidate.isActive) ??
    null;

  return { location, locations, organization, organizations };
}
