"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireUser } from "@/lib/auth";
import { errorRedirect, publicErrorMessage } from "@/lib/errors";
import { formString } from "@/lib/forms";
import {
  ACTIVE_LOCATION_COOKIE,
  ACTIVE_ORGANIZATION_COOKIE,
} from "@/lib/organizations";
import { createClient } from "@/lib/supabase/server";
import { databaseUuidSchema, invitationTokenSchema } from "@/lib/validation";

const acceptanceResultSchema = z.object({
  locationId: databaseUuidSchema.nullable(),
  organizationId: databaseUuidSchema,
});

export async function acceptInvitation(formData: FormData): Promise<never> {
  await requireUser("/invitations/accept");
  const parsed = invitationTokenSchema.safeParse(formString(formData, "token"));
  if (!parsed.success) {
    redirect(
      errorRedirect("/invitations/accept", "Invitation link is invalid."),
    );
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("accept_staff_invitation", {
    invitation_token: parsed.data,
  });

  if (error) {
    const destination = `/invitations/accept?token=${encodeURIComponent(parsed.data)}`;
    redirect(
      errorRedirect(
        destination,
        publicErrorMessage(error, "This invitation could not be accepted."),
      ),
    );
  }

  const result = acceptanceResultSchema.safeParse(data);
  if (!result.success) {
    redirect(
      errorRedirect(
        "/invitations/accept",
        "The invitation response was invalid.",
      ),
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
  if (result.data.locationId) {
    cookieStore.set(ACTIVE_LOCATION_COOKIE, result.data.locationId, options);
  } else {
    cookieStore.delete(ACTIVE_LOCATION_COOKIE);
  }
  redirect("/dashboard?notice=invitation-accepted");
}
