import "server-only";

import type { User } from "@supabase/supabase-js";
import { redirect } from "next/navigation";

import { asRoute, safeInternalPath } from "./navigation";
import { createClient } from "./supabase/server";

export async function requireUser(nextPath = "/dashboard"): Promise<User> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    const next = safeInternalPath(nextPath, "/dashboard");
    redirect(asRoute(`/auth/sign-in?next=${encodeURIComponent(next)}`));
  }

  return user;
}

export function isVerifiedUser(user: User): boolean {
  return Boolean(user.email_confirmed_at);
}
