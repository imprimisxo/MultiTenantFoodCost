"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { requireUser } from "@/lib/auth";
import { errorRedirect, publicErrorMessage } from "@/lib/errors";
import { formString, slugify } from "@/lib/forms";
import {
  ACTIVE_LOCATION_COOKIE,
  ACTIVE_ORGANIZATION_COOKIE,
  listLocations,
  listOrganizations,
} from "@/lib/organizations";
import { createClient } from "@/lib/supabase/server";
import { contextSchema, locationSchema } from "@/lib/validation";

const cookieOptions = {
  httpOnly: true,
  path: "/",
  sameSite: "lax" as const,
  secure: process.env.NODE_ENV === "production",
};

export async function switchContext(formData: FormData): Promise<never> {
  const user = await requireUser("/dashboard");
  const parsed = contextSchema.safeParse({
    locationId: formString(formData, "locationId"),
    organizationId: formString(formData, "organizationId"),
  });

  if (!parsed.success) {
    redirect(
      errorRedirect("/dashboard", "Choose a valid organization and location."),
    );
  }

  const organizations = await listOrganizations(user.id);
  if (
    !organizations.some(
      (organization) => organization.id === parsed.data.organizationId,
    )
  ) {
    redirect(
      errorRedirect(
        "/dashboard",
        "You do not have an active membership in that organization.",
      ),
    );
  }

  let authorizedLocationId: string | null = null;
  if (parsed.data.locationId) {
    const locations = await listLocations(parsed.data.organizationId);
    authorizedLocationId =
      locations.find(
        (location) =>
          location.id === parsed.data.locationId && location.isActive,
      )?.id ?? null;
  }

  const cookieStore = await cookies();
  cookieStore.set(
    ACTIVE_ORGANIZATION_COOKIE,
    parsed.data.organizationId,
    cookieOptions,
  );
  if (authorizedLocationId) {
    cookieStore.set(
      ACTIVE_LOCATION_COOKIE,
      authorizedLocationId,
      cookieOptions,
    );
  } else {
    cookieStore.delete(ACTIVE_LOCATION_COOKIE);
  }
  redirect("/dashboard");
}

export async function createLocation(formData: FormData): Promise<never> {
  const user = await requireUser("/dashboard/locations");
  const parsed = locationSchema.safeParse({
    code: slugify(formString(formData, "code")),
    isActive: true,
    name: formString(formData, "name"),
    organizationId: formString(formData, "organizationId"),
    timeZone: formString(formData, "timeZone"),
  });

  if (!parsed.success) {
    redirect(
      errorRedirect("/dashboard/locations", "Check the new location details."),
    );
  }

  const supabase = await createClient();
  const { error } = await supabase.from("locations").insert({
    code: parsed.data.code,
    created_by: user.id,
    is_active: true,
    name: parsed.data.name,
    organization_id: parsed.data.organizationId,
    time_zone: parsed.data.timeZone,
  });

  if (error) {
    redirect(
      errorRedirect(
        "/dashboard/locations",
        publicErrorMessage(
          error,
          "You are not authorized to create that location.",
        ),
      ),
    );
  }

  redirect("/dashboard/locations?notice=location-created");
}

export async function updateLocation(formData: FormData): Promise<never> {
  await requireUser("/dashboard/locations");
  const parsed = locationSchema.safeParse({
    code: slugify(formString(formData, "code")),
    isActive: formString(formData, "isActive") === "on",
    locationId: formString(formData, "locationId"),
    name: formString(formData, "name"),
    organizationId: formString(formData, "organizationId"),
    timeZone: formString(formData, "timeZone"),
  });

  if (!parsed.success || !parsed.data.locationId) {
    redirect(
      errorRedirect("/dashboard/locations", "Check the location details."),
    );
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("locations")
    .update({
      code: parsed.data.code,
      is_active: parsed.data.isActive,
      name: parsed.data.name,
      time_zone: parsed.data.timeZone,
    })
    .eq("id", parsed.data.locationId)
    .eq("organization_id", parsed.data.organizationId)
    .select("id")
    .maybeSingle();

  if (error || !data) {
    redirect(
      errorRedirect(
        "/dashboard/locations",
        publicErrorMessage(
          error,
          "You are not authorized to update that location.",
        ),
      ),
    );
  }

  redirect("/dashboard/locations?notice=location-updated");
}
