import { Button } from "@workspace/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@workspace/ui/components/card";

import {
  ErrorMessage,
  labelClassName,
  TextInput,
} from "@/components/form-controls";
import { getDashboardRequest } from "@/lib/dashboard";
import { firstSearchParam } from "@/lib/navigation";

import { createLocation, updateLocation } from "../actions";

export default async function LocationsPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  const { context, dashboard } = await getDashboardRequest();
  const query = await searchParams;
  const canWrite = dashboard.permissions.includes("locations.write");
  const atLimit =
    dashboard.locationLimit !== null &&
    dashboard.activeLocationCount >= Number(dashboard.locationLimit);

  return (
    <div className="grid gap-6">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">Locations</h1>
        <p className="text-muted-foreground mt-2">
          You can only see and administer locations granted in the active scope.
        </p>
      </div>
      <ErrorMessage message={firstSearchParam(query.error)} />
      {firstSearchParam(query.notice) ? (
        <p
          className="border-primary/20 bg-accent rounded-md border px-3 py-2 text-sm"
          role="status"
        >
          Location saved.
        </p>
      ) : null}
      <div className="grid gap-4">
        {context.locations.map((location) => (
          <Card key={location.id}>
            <CardHeader>
              <CardTitle className="text-lg">{location.name}</CardTitle>
              <CardDescription>
                {location.code} · {location.timeZone}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {canWrite ? (
                <form
                  action={updateLocation}
                  className="grid gap-4 md:grid-cols-4"
                >
                  <input name="locationId" type="hidden" value={location.id} />
                  <input
                    name="organizationId"
                    type="hidden"
                    value={context.organization.id}
                  />
                  <label className={labelClassName}>
                    Name
                    <TextInput
                      defaultValue={location.name}
                      name="name"
                      required
                    />
                  </label>
                  <label className={labelClassName}>
                    Code
                    <TextInput
                      defaultValue={location.code}
                      name="code"
                      required
                    />
                  </label>
                  <label className={labelClassName}>
                    Time zone
                    <TextInput
                      defaultValue={location.timeZone}
                      name="timeZone"
                      required
                    />
                  </label>
                  <div className="flex items-end gap-3">
                    <label className="flex h-10 items-center gap-2 text-sm">
                      <input
                        defaultChecked={location.isActive}
                        name="isActive"
                        type="checkbox"
                      />{" "}
                      Active
                    </label>
                    <Button type="submit" variant="outline">
                      Save
                    </Button>
                  </div>
                </form>
              ) : (
                <p className="text-muted-foreground text-sm">
                  Read-only in this location scope.
                </p>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
      {canWrite ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Add location</CardTitle>
            <CardDescription>
              {dashboard.activeLocationCount} of{" "}
              {dashboard.locationLimit ?? "0"} active locations used.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form action={createLocation} className="grid gap-4 md:grid-cols-4">
              <input
                name="organizationId"
                type="hidden"
                value={context.organization.id}
              />
              <label className={labelClassName}>
                Name
                <TextInput disabled={atLimit} name="name" required />
              </label>
              <label className={labelClassName}>
                Code
                <TextInput disabled={atLimit} name="code" required />
              </label>
              <label className={labelClassName}>
                Time zone
                <TextInput
                  defaultValue="America/Chicago"
                  disabled={atLimit}
                  name="timeZone"
                  required
                />
              </label>
              <div className="flex items-end">
                <Button className="w-full" disabled={atLimit} type="submit">
                  Add location
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
