import { Button } from "@workspace/ui/components/button";
import Link from "next/link";

import { AuthShell } from "@/components/auth-shell";
import {
  ErrorMessage,
  labelClassName,
  TextInput,
} from "@/components/form-controls";
import { firstSearchParam } from "@/lib/navigation";

import { requestPasswordReset } from "../actions";

export default async function RecoverPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const query = await searchParams;
  const sent = firstSearchParam(query.sent) === "true";

  return (
    <AuthShell
      description="We'll send recovery instructions if the address belongs to an account."
      title="Reset your password"
    >
      {sent ? (
        <div className="grid gap-4 text-sm">
          <p className="border-primary/20 bg-accent rounded-md border p-3">
            Check your email for a password recovery link.
          </p>
          <Link className="underline underline-offset-4" href="/auth/sign-in">
            Return to sign in
          </Link>
        </div>
      ) : (
        <form action={requestPasswordReset} className="grid gap-4">
          <ErrorMessage message={firstSearchParam(query.error)} />
          <label className={labelClassName}>
            Email
            <TextInput
              autoComplete="email"
              name="email"
              required
              type="email"
            />
          </label>
          <Button className="mt-2 w-full" type="submit">
            Send recovery link
          </Button>
        </form>
      )}
    </AuthShell>
  );
}
