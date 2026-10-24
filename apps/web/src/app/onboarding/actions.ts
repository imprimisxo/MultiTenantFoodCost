"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";

import { publicErrorMessage, errorRedirect } from "@/lib/errors";
import { formString, slugify } from "@/lib/forms";
import {
  ACTIVE_LOCATION_COOKIE,
  ACTIVE_ORGANIZATION_COOKIE,
} from "@/lib/organizations";
import { createClient } from "@/lib/supabase/server";
import { databaseUuidSchema, onboardingSchema } from "@/lib/validation";

const resultSchema = z.object({
  locationId: databaseUuidSchema,
  organizationId: databaseUuidSchema,
});

export async function onboardOrganization(formData: FormData): Promise<never> {
  const parsed = onboardingSchema.safeParse({
    defaultCurrency: formString(formData, "defaultCurrency"),
    locationCode: slugify(formString(formData, "locationCode")),
    locationName: formString(formData, "locationName"),
    locationTimeZone: formString(formData, "locationTimeZone"),
    organizationName: formString(formData, "organizationName"),
    organizationSlug: slugify(formString(formData, "organizationSlug")),
  });

  if (!parsed.success) {
    redirect(
      errorRedirect(
        "/onboarding",
        "Check the organization and location details.",
      ),
    );
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/sign-in?next=/onboarding");
  }

  const { data, error } = await supabase.rpc("onboard_organization", {
    default_currency: parsed.data.defaultCurrency,
    first_location_code: parsed.data.locationCode,
    first_location_name: parsed.data.locationName,
    first_location_time_zone: parsed.data.locationTimeZone,
    organization_name: parsed.data.organizationName,
    organization_slug: parsed.data.organizationSlug,
  });

  if (error) {
    redirect(
      errorRedirect(
        "/onboarding",
        publicErrorMessage(
          error,
          "We couldn't create the organization. Try again.",
        ),
      ),
    );
  }

  const result = resultSchema.safeParse(data);
  if (!result.success) {
    redirect(
      errorRedirect("/onboarding", "The organization response was invalid."),
    );
  }

  const cookieStore = await cookies();
  const options = {
    httpOnly: true,
    path: "/",
    sameSite: "lax" as const,
    secure: process.env.NODE_ENV === "production",
  };
  cookieStore.set(
    ACTIVE_ORGANIZATION_COOKIE,
    result.data.organizationId,
    options,
  );
  cookieStore.set(ACTIVE_LOCATION_COOKIE, result.data.locationId, options);
  redirect("/dashboard?notice=organization-created");
}
