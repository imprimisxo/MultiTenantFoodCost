import { Button } from "@workspace/ui/components/button";
import Link from "next/link";

import { AuthShell } from "@/components/auth-shell";
import {
  ErrorMessage,
  labelClassName,
  TextInput,
} from "@/components/form-controls";
import { firstSearchParam, safeInternalPath } from "@/lib/navigation";

import { signIn } from "../actions";

export default async function SignInPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const query = await searchParams;
  const next = safeInternalPath(firstSearchParam(query.next), "/dashboard");

  return (
    <AuthShell
      description="Use your verified account to access an authorized organization."
      title="Welcome back"
    >
      <form action={signIn} className="grid gap-4">
        <input name="next" type="hidden" value={next} />
        <ErrorMessage message={firstSearchParam(query.error)} />
        <label className={labelClassName}>
          Email
          <TextInput autoComplete="email" name="email" required type="email" />
        </label>
        <label className={labelClassName}>
          Password
          <TextInput
            autoComplete="current-password"
            name="password"
            required
            type="password"
          />
        </label>
        <Button className="mt-2 w-full" type="submit">
          Sign in
        </Button>
      </form>
      <div className="text-muted-foreground mt-6 flex justify-between text-sm">
        <Link
          className="hover:text-foreground underline-offset-4 hover:underline"
          href="/auth/recover"
        >
          Forgot password?
        </Link>
        <Link
          className="hover:text-foreground underline-offset-4 hover:underline"
          href="/auth/sign-up"
        >
          Create account
        </Link>
      </div>
    </AuthShell>
  );
}
