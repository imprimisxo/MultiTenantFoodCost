import "server-only";

import { redirect } from "next/navigation";
import { cache } from "react";

import { requireUser } from "./auth";
import {
  loadDashboard,
  resolveOrganizationContext,
  type DashboardData,
  type OrganizationContext,
} from "./organizations";

export interface DashboardRequest {
  context: OrganizationContext;
  dashboard: DashboardData;
  userId: string;
}

export const getDashboardRequest = cache(
  async (): Promise<DashboardRequest> => {
    const user = await requireUser("/dashboard");
    const context = await resolveOrganizationContext(user.id);

    if (!context) {
      redirect("/onboarding");
    }

    const dashboard = await loadDashboard(
      context.organization.id,
      context.location?.id ?? null,
    );

    return { context, dashboard, userId: user.id };
  },
);
