import { Button } from "@workspace/ui/components/button";
import Link from "next/link";

import { AuthShell } from "@/components/auth-shell";
import {
  ErrorMessage,
  labelClassName,
  TextInput,
} from "@/components/form-controls";
import { firstSearchParam } from "@/lib/navigation";

import { signUp } from "../actions";

export default async function SignUpPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const query = await searchParams;

  return (
    <AuthShell
      description="Your email must be verified before organization data can be created."
      title="Create your account"
    >
      <form action={signUp} className="grid gap-4">
        <ErrorMessage message={firstSearchParam(query.error)} />
        <label className={labelClassName}>
          Your name
          <TextInput autoComplete="name" name="displayName" required />
        </label>
        <label className={labelClassName}>
          Email
          <TextInput autoComplete="email" name="email" required type="email" />
        </label>
        <label className={labelClassName}>
          Password
          <TextInput
            autoComplete="new-password"
            minLength={12}
            name="password"
            required
            type="password"
          />
          <span className="text-muted-foreground text-xs">
            At least 12 characters.
          </span>
        </label>
        <Button className="mt-2 w-full" type="submit">
          Create account
        </Button>
      </form>
      <p className="text-muted-foreground mt-6 text-sm">
        Already registered?{" "}
        <Link
          className="text-foreground underline-offset-4 hover:underline"
          href="/auth/sign-in"
        >
          Sign in
        </Link>
      </p>
    </AuthShell>
  );
}
