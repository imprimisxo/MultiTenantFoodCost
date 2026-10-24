import type { ReactNode } from "react";

import { DashboardShell } from "@/components/dashboard-shell";
import { getDashboardRequest } from "@/lib/dashboard";

export const dynamic = "force-dynamic";

export default async function DashboardLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  const { context, dashboard } = await getDashboardRequest();
  return (
    <DashboardShell context={context} dashboard={dashboard}>
      {children}
    </DashboardShell>
  );
}
