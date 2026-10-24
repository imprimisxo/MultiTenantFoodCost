import { Button } from "@workspace/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@workspace/ui/components/card";
import { redirect } from "next/navigation";

import {
  ErrorMessage,
  labelClassName,
  TextInput,
} from "@/components/form-controls";
import { isVerifiedUser, requireUser } from "@/lib/auth";
import { firstSearchParam } from "@/lib/navigation";
import { listOrganizations } from "@/lib/organizations";

import { onboardOrganization } from "./actions";

export const dynamic = "force-dynamic";

export default async function OnboardingPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const user = await requireUser("/onboarding");
  if (!isVerifiedUser(user)) {
    redirect(
      `/auth/verify-email?email=${encodeURIComponent(user.email ?? "")}`,
    );
  }

  if ((await listOrganizations(user.id)).length > 0) {
    redirect("/dashboard");
  }

  const query = await searchParams;

  return (
    <main className="bg-muted/35 min-h-screen px-6 py-12">
      <div className="mx-auto max-w-2xl">
        <p className="text-primary text-sm font-semibold tracking-[0.16em] uppercase">
          Transactional setup
        </p>
        <h1 className="mt-3 text-4xl font-semibold tracking-tight">
          Create your organization
        </h1>
        <p className="text-muted-foreground mt-3 max-w-xl leading-7">
          Your tenant, owner membership, role, trial entitlements, and first
          location are committed together or not at all.
        </p>
        <Card className="mt-8">
          <CardHeader>
            <CardTitle>Organization and first location</CardTitle>
            <CardDescription>
              Use stable codes; they are unique within the organization.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form
              action={onboardOrganization}
              className="grid gap-5 sm:grid-cols-2"
            >
              <div className="sm:col-span-2">
                <ErrorMessage message={firstSearchParam(query.error)} />
              </div>
              <label className={labelClassName}>
                Organization name
                <TextInput name="organizationName" required />
              </label>
              <label className={labelClassName}>
                Organization address
                <TextInput
                  name="organizationSlug"
                  pattern="[a-z0-9-]+"
                  placeholder="north-star-hospitality"
                  required
                />
              </label>
              <label className={labelClassName}>
                Default currency
                <TextInput
                  defaultValue="USD"
                  maxLength={3}
                  name="defaultCurrency"
                  required
                />
              </label>
              <div />
              <label className={labelClassName}>
                First location name
                <TextInput name="locationName" required />
              </label>
              <label className={labelClassName}>
                Location code
                <TextInput
                  name="locationCode"
                  pattern="[a-z0-9-]+"
                  placeholder="downtown"
                  required
                />
              </label>
              <label className={labelClassName}>
                Time zone
                <TextInput
                  defaultValue="America/Chicago"
                  name="locationTimeZone"
                  required
                />
              </label>
              <div className="flex items-end">
                <Button className="w-full" type="submit">
                  Create organization
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
