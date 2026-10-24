import { Button } from "@workspace/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@workspace/ui/components/card";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import {
  ErrorMessage,
  labelClassName,
  SelectInput,
  TextInput,
} from "@/components/form-controls";
import { getDashboardRequest } from "@/lib/dashboard";
import { firstSearchParam } from "@/lib/navigation";
import {
  INVITATION_ORGANIZATION_COOKIE,
  INVITATION_TOKEN_COOKIE,
} from "@/lib/organizations";
import { getApplicationUrl } from "@/lib/supabase/config";
import { createClient } from "@/lib/supabase/server";

import { createInvitation, revokeInvitation } from "./actions";

interface RoleRow {
  id: string;
  key: string;
  name: string;
}

interface InvitationRow {
  created_at: string;
  email: string;
  expires_at: string;
  id: string;
  location_id: string | null;
  role_id: string;
  status: string;
}

export default async function TeamPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const { context, dashboard } = await getDashboardRequest();
  if (!dashboard.permissions.includes("memberships.read")) {
    redirect(
      "/dashboard?error=Team%20access%20is%20not%20granted%20in%20this%20scope.",
    );
  }

  const canManage = dashboard.permissions.includes("memberships.manage");
  const supabase = await createClient();
  const [{ data: roleData }, { data: invitationData }] = await Promise.all([
    supabase
      .from("roles")
      .select("id, key, name")
      .eq("organization_id", context.organization.id)
      .order("name"),
    supabase
      .from("staff_invitations")
      .select("id, email, role_id, location_id, status, expires_at, created_at")
      .eq("organization_id", context.organization.id)
      .order("created_at", { ascending: false }),
  ]);
  const roles = (roleData ?? []) as unknown as RoleRow[];
  const invitations = (invitationData ?? []) as unknown as InvitationRow[];
  const roleNames = new Map(roles.map((role) => [role.id, role.name]));
  const locationNames = new Map(
    context.locations.map((location) => [location.id, location.name]),
  );
  const query = await searchParams;
  const cookieStore = await cookies();
  const invitationToken = cookieStore.get(INVITATION_TOKEN_COOKIE)?.value;
  const invitationOrganization = cookieStore.get(
    INVITATION_ORGANIZATION_COOKIE,
  )?.value;
  const invitationLink =
    invitationToken && invitationOrganization === context.organization.id
      ? `${getApplicationUrl()}/invitations/accept?token=${invitationToken}`
      : null;

  return (
    <div className="grid gap-6">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">
          Team & invitations
        </h1>
        <p className="text-muted-foreground mt-2">
          Invitation secrets are stored as hashes, expire automatically, and can
          be accepted only by the verified recipient.
        </p>
      </div>
      <ErrorMessage message={firstSearchParam(query.error)} />
      {invitationLink ? (
        <Card className="border-primary/30">
          <CardHeader>
            <CardTitle className="text-lg">Invitation link created</CardTitle>
            <CardDescription>
              This secret is shown briefly. Share it only with the intended
              recipient.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <TextInput
              aria-label="Invitation link"
              readOnly
              value={invitationLink}
            />
          </CardContent>
        </Card>
      ) : firstSearchParam(query.notice) ? (
        <p
          className="border-primary/20 bg-accent rounded-md border px-3 py-2 text-sm"
          role="status"
        >
          Invitation updated.
        </p>
      ) : null}
      {canManage ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Invite staff member</CardTitle>
            <CardDescription>
              The selected role cannot exceed your own effective permissions.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form
              action={createInvitation}
              className="grid gap-4 md:grid-cols-4"
            >
              <input
                name="organizationId"
                type="hidden"
                value={context.organization.id}
              />
              <label className={labelClassName}>
                Recipient email
                <TextInput name="email" required type="email" />
              </label>
              <label className={labelClassName}>
                Role
                <SelectInput name="roleId" required>
                  {roles.map((role) => (
                    <option key={role.id} value={role.id}>
                      {role.name}
                    </option>
                  ))}
                </SelectInput>
              </label>
              <label className={labelClassName}>
                Scope
                <SelectInput name="locationId">
                  <option value="">Organization-wide</option>
                  {context.locations
                    .filter((location) => location.isActive)
                    .map((location) => (
                      <option key={location.id} value={location.id}>
                        {location.name}
                      </option>
                    ))}
                </SelectInput>
              </label>
              <label className={labelClassName}>
                Expires
                <SelectInput defaultValue="72" name="expiresInHours">
                  <option value="24">24 hours</option>
                  <option value="72">3 days</option>
                  <option value="168">7 days</option>
                </SelectInput>
              </label>
              <div className="md:col-span-4">
                <Button type="submit">Create invitation</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      ) : null}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Invitation history</CardTitle>
          <CardDescription>
            Security-sensitive changes are also written to the tenant audit log.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {invitations.length === 0 ? (
            <p className="text-muted-foreground text-sm">No invitations yet.</p>
          ) : (
            <ul className="divide-border divide-y">
              {invitations.map((invitation) => (
                <li
                  className="flex flex-col gap-3 py-4 sm:flex-row sm:items-center sm:justify-between"
                  key={invitation.id}
                >
                  <div>
                    <p className="text-sm font-medium">{invitation.email}</p>
                    <p className="text-muted-foreground mt-1 text-xs">
                      {roleNames.get(invitation.role_id) ?? "Role"} ·{" "}
                      {invitation.location_id
                        ? (locationNames.get(invitation.location_id) ??
                          "Location")
                        : "Organization-wide"}{" "}
                      · {invitation.status} · expires{" "}
                      {new Date(invitation.expires_at).toLocaleString("en-US")}
                    </p>
                  </div>
                  {canManage && invitation.status === "pending" ? (
                    <form action={revokeInvitation}>
                      <input
                        name="invitationId"
                        type="hidden"
                        value={invitation.id}
                      />
                      <input
                        name="organizationId"
                        type="hidden"
                        value={context.organization.id}
                      />
                      <Button size="sm" type="submit" variant="outline">
                        Revoke
                      </Button>
                    </form>
                  ) : null}
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
