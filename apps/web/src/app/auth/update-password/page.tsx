import { Button } from "@workspace/ui/components/button";

import { AuthShell } from "@/components/auth-shell";
import {
  ErrorMessage,
  labelClassName,
  TextInput,
} from "@/components/form-controls";
import { requireUser } from "@/lib/auth";
import { firstSearchParam } from "@/lib/navigation";

import { updatePassword } from "../actions";

export const dynamic = "force-dynamic";

export default async function UpdatePasswordPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  await requireUser("/auth/update-password");
  const query = await searchParams;

  return (
    <AuthShell
      description="Choose a new password for your account."
      title="Set a new password"
    >
      <form action={updatePassword} className="grid gap-4">
        <ErrorMessage message={firstSearchParam(query.error)} />
        <label className={labelClassName}>
          New password
          <TextInput
            autoComplete="new-password"
            minLength={12}
            name="password"
            required
            type="password"
          />
        </label>
        <Button className="mt-2 w-full" type="submit">
          Update password
        </Button>
      </form>
    </AuthShell>
  );
}
