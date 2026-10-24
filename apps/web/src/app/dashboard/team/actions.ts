"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireUser } from "@/lib/auth";
import { errorRedirect, publicErrorMessage } from "@/lib/errors";
import { formString } from "@/lib/forms";
import {
  INVITATION_ORGANIZATION_COOKIE,
  INVITATION_TOKEN_COOKIE,
} from "@/lib/organizations";
import { createClient } from "@/lib/supabase/server";
import {
  databaseUuidSchema,
  invitationSchema,
  revokeInvitationSchema,
} from "@/lib/validation";

const invitationResultSchema = z.object({
  expiresAt: z.string(),
  invitationId: databaseUuidSchema,
  token: z.string().regex(/^[a-f0-9]{64}$/),
});

export async function createInvitation(formData: FormData): Promise<never> {
  await requireUser("/dashboard/team");
  const parsed = invitationSchema.safeParse({
    email: formString(formData, "email"),
    expiresInHours: formString(formData, "expiresInHours"),
    locationId: formString(formData, "locationId"),
    organizationId: formString(formData, "organizationId"),
    roleId: formString(formData, "roleId"),
  });

  if (!parsed.success) {
    redirect(errorRedirect("/dashboard/team", "Check the invitation details."));
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("create_staff_invitation", {
    expires_in_hours: parsed.data.expiresInHours,
    recipient_email: parsed.data.email,
    target_location_id: parsed.data.locationId || null,
    target_organization_id: parsed.data.organizationId,
    target_role_id: parsed.data.roleId,
  });

  if (error) {
    redirect(
      errorRedirect(
        "/dashboard/team",
        publicErrorMessage(
          error,
          "You are not authorized to create that invitation.",
        ),
      ),
    );
  }

  const result = invitationResultSchema.safeParse(data);
  if (!result.success) {
    redirect(
      errorRedirect("/dashboard/team", "The invitation response was invalid."),
    );
  }

  const cookieStore = await cookies();
  const options = {
    httpOnly: true,
    maxAge: 300,
    path: "/dashboard/team",
    sameSite: "strict" as const,
    secure: process.env.NODE_ENV === "production",
  };
  cookieStore.set(INVITATION_TOKEN_COOKIE, result.data.token, options);
  cookieStore.set(
    INVITATION_ORGANIZATION_COOKIE,
    parsed.data.organizationId,
    options,
  );
  redirect("/dashboard/team?notice=invitation-created");
}

export async function revokeInvitation(formData: FormData): Promise<never> {
  await requireUser("/dashboard/team");
  const parsed = revokeInvitationSchema.safeParse({
    invitationId: formString(formData, "invitationId"),
    organizationId: formString(formData, "organizationId"),
  });

  if (!parsed.success) {
    redirect(errorRedirect("/dashboard/team", "Choose a valid invitation."));
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("revoke_staff_invitation", {
    target_invitation_id: parsed.data.invitationId,
  });

  if (error) {
    redirect(
      errorRedirect(
        "/dashboard/team",
        publicErrorMessage(
          error,
          "You are not authorized to revoke that invitation.",
        ),
      ),
    );
  }

  redirect("/dashboard/team?notice=invitation-revoked");
}
