import { Badge } from "@workspace/ui/components/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@workspace/ui/components/card";

import { ErrorMessage } from "@/components/form-controls";
import { getDashboardRequest } from "@/lib/dashboard";
import { firstSearchParam } from "@/lib/navigation";

export default async function DashboardPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const { context, dashboard } = await getDashboardRequest();
  const query = await searchParams;
  const limit = dashboard.locationLimit ?? "0";

  return (
    <div className="grid gap-6">
      <div>
        <p className="text-primary text-sm font-semibold tracking-[0.16em] uppercase">
          Organization dashboard
        </p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight">
          {context.organization.name}
        </h1>
        <p className="text-muted-foreground mt-2">
          {context.location
            ? `Viewing ${context.location.name}`
            : "Organization-wide view"}
        </p>
      </div>
      <ErrorMessage message={firstSearchParam(query.error)} />
      {firstSearchParam(query.notice) ? (
        <p
          className="border-primary/20 bg-accent rounded-md border px-3 py-2 text-sm"
          role="status"
        >
          Your account and organization context are up to date.
        </p>
      ) : null}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader>
            <CardDescription>Subscription</CardDescription>
            <CardTitle>{dashboard.planName ?? "No active plan"}</CardTitle>
          </CardHeader>
          <CardContent>
            <Badge
              variant={
                dashboard.subscriptionStatus === "active"
                  ? "default"
                  : "secondary"
              }
            >
              {dashboard.subscriptionStatus}
            </Badge>
            {dashboard.currentPeriodEnd ? (
              <p className="text-muted-foreground mt-3 text-xs">
                Current period ends{" "}
                {new Date(dashboard.currentPeriodEnd).toLocaleDateString(
                  "en-US",
                )}
              </p>
            ) : null}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardDescription>Active locations</CardDescription>
            <CardTitle>
              {dashboard.activeLocationCount} / {limit}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-sm">
              Enforced by the active subscription entitlement.
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardDescription>Analytics</CardDescription>
            <CardTitle>
              {dashboard.analyticsEnabled ? "Enabled" : "Not included"}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-sm">
              Navigation and server capabilities reflect the effective
              entitlement.
            </p>
          </CardContent>
        </Card>
      </div>
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Authorized capabilities</CardTitle>
          <CardDescription>
            Calculated on the server for this organization and location context.
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          {dashboard.permissions.length > 0 ? (
            dashboard.permissions.map((permission) => (
              <Badge key={permission} variant="outline">
                {permission}
              </Badge>
            ))
          ) : (
            <p className="text-muted-foreground text-sm">
              No capabilities are granted in this context.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
