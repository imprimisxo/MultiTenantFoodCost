export interface SupabasePublicConfig {
  publishableKey: string;
  url: string;
}

export function getSupabasePublicConfig(): SupabasePublicConfig {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !publishableKey) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY are required.",
    );
  }

  return { publishableKey, url };
}

export function getApplicationUrl(): string {
  const applicationUrl = process.env.NEXT_PUBLIC_APP_URL;

  if (!applicationUrl) {
    throw new Error("NEXT_PUBLIC_APP_URL is required.");
  }

  return applicationUrl.replace(/\/$/, "");
}
