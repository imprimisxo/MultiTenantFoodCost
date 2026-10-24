import { Badge } from "@workspace/ui/components/badge";
import { Button, buttonVariants } from "@workspace/ui/components/button";
import { cn } from "@workspace/ui/lib/utils";
import Link from "next/link";
import type { ReactNode } from "react";

import { signOut } from "@/app/auth/actions";
import { switchContext } from "@/app/dashboard/actions";
import type { DashboardData, OrganizationContext } from "@/lib/organizations";

import { SelectInput } from "./form-controls";

export function DashboardShell({
  children,
  context,
  dashboard,
}: Readonly<{
  children: ReactNode;
  context: OrganizationContext;
  dashboard: DashboardData;
}>) {
  const permissions = new Set(dashboard.permissions);

  return (
    <main className="bg-muted/35 min-h-screen">
      <header className="border-border bg-background border-b">
        <div className="mx-auto flex max-w-7xl flex-col gap-4 px-6 py-4 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-center gap-3">
            <Link
              className="bg-primary text-primary-foreground grid size-9 place-items-center rounded-lg text-sm font-semibold"
              href="/dashboard"
            >
              R
            </Link>
            <div>
              <p className="font-semibold">{context.organization.name}</p>
              <p className="text-muted-foreground text-xs">
                {dashboard.planName ?? "No plan"} ·{" "}
                {dashboard.subscriptionStatus}
              </p>
            </div>
          </div>
          <form
            action={switchContext}
            className="flex flex-wrap items-end gap-2"
          >
            <label className="grid gap-1 text-xs font-medium">
              Organization
              <SelectInput
                className="min-w-48"
                defaultValue={context.organization.id}
                name="organizationId"
              >
                {context.organizations.map((organization) => (
                  <option key={organization.id} value={organization.id}>
                    {organization.name}
                  </option>
                ))}
              </SelectInput>
            </label>
            <label className="grid gap-1 text-xs font-medium">
              Location
              <SelectInput
                className="min-w-44"
                defaultValue={context.location?.id ?? ""}
                name="locationId"
              >
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
            <Button variant="outline" type="submit">
              Switch
            </Button>
          </form>
        </div>
      </header>
      <div className="mx-auto grid max-w-7xl gap-8 px-6 py-8 lg:grid-cols-[13rem_1fr]">
        <aside>
          <nav aria-label="Organization" className="grid gap-1">
            <Link
              className={cn(
                buttonVariants({ variant: "ghost" }),
                "justify-start",
              )}
              href="/dashboard"
            >
              Overview
            </Link>
            {permissions.has("locations.read") ? (
              <Link
                className={cn(
                  buttonVariants({ variant: "ghost" }),
                  "justify-start",
                )}
                href="/dashboard/locations"
              >
                Locations
              </Link>
            ) : null}
            {permissions.has("memberships.read") ? (
              <Link
                className={cn(
                  buttonVariants({ variant: "ghost" }),
                  "justify-start",
                )}
                href="/dashboard/team"
              >
                Team & invitations
              </Link>
            ) : null}
          </nav>
          {!dashboard.analyticsEnabled ? (
            <div className="border-border bg-background mt-6 rounded-lg border p-3">
              <Badge variant="outline">Plan locked</Badge>
              <p className="text-muted-foreground mt-2 text-xs leading-5">
                Analytics is not included in the current entitlement set.
              </p>
            </div>
          ) : null}
          <form action={signOut} className="mt-6">
            <Button className="w-full" variant="outline" type="submit">
              Sign out
            </Button>
          </form>
        </aside>
        <div>{children}</div>
      </div>
    </main>
  );
}
