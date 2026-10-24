import Link from "next/link";

import { AuthShell } from "@/components/auth-shell";
import { firstSearchParam } from "@/lib/navigation";

export default async function VerifyEmailPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const query = await searchParams;
  const email = firstSearchParam(query.email);

  return (
    <AuthShell
      description="Organization onboarding stays locked until Supabase confirms your email."
      title="Verify your email"
    >
      <div className="grid gap-4 text-sm">
        <p>
          We sent a verification link
          {email ? ` to ${email}` : " to your email address"}. Open it on this
          device to continue.
        </p>
        <p className="text-muted-foreground">
          The link creates a server-verified session; no organization data is
          created before that check.
        </p>
        <Link
          className="font-medium underline underline-offset-4"
          href="/auth/sign-in"
        >
          Return to sign in
        </Link>
      </div>
    </AuthShell>
  );
}
