import { Button } from "@workspace/ui/components/button";

import { AuthShell } from "@/components/auth-shell";
import { ErrorMessage } from "@/components/form-controls";
import { requireUser } from "@/lib/auth";
import { firstSearchParam } from "@/lib/navigation";
import { invitationTokenSchema } from "@/lib/validation";

import { acceptInvitation } from "./actions";

export const dynamic = "force-dynamic";

export default async function AcceptInvitationPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const user = await requireUser("/invitations/accept");
  const query = await searchParams;
  const token = firstSearchParam(query.token) ?? "";
  const validToken = invitationTokenSchema.safeParse(token).success;

  return (
    <AuthShell
      description="The database verifies the signed-in email, expiry, status, and assigned tenant scope atomically."
      title="Accept staff invitation"
    >
      <form action={acceptInvitation} className="grid gap-4">
        <ErrorMessage message={firstSearchParam(query.error)} />
        <p className="text-sm">
          Signed in as <strong>{user.email}</strong>
        </p>
        <p className="text-muted-foreground text-sm">
          Only the exact verified recipient can use this link, and it becomes
          unusable after acceptance.
        </p>
        <input name="token" type="hidden" value={token} />
        <Button disabled={!validToken} type="submit">
          Accept invitation
        </Button>
      </form>
    </AuthShell>
  );
}
