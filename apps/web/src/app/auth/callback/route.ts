import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

import { safeInternalPath } from "@/lib/navigation";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest): Promise<NextResponse> {
  const code = request.nextUrl.searchParams.get("code");
  const next = safeInternalPath(
    request.nextUrl.searchParams.get("next"),
    "/dashboard",
  );

  if (!code) {
    return NextResponse.redirect(
      new URL(
        "/auth/sign-in?error=Authentication%20link%20is%20invalid.",
        request.url,
      ),
    );
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(
      new URL(
        "/auth/sign-in?error=Authentication%20link%20has%20expired.",
        request.url,
      ),
    );
  }

  return NextResponse.redirect(new URL(next, request.url));
}
