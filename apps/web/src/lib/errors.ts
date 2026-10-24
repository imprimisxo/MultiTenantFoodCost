const knownMessages: ReadonlyArray<readonly [string, string]> = [
  ["Invalid login credentials", "Email or password is incorrect."],
  ["Email not confirmed", "Verify your email before signing in."],
  ["User already registered", "An account already exists for that email."],
  ["organization_slug_key", "That organization address is already in use."],
  [
    "locations_organization_id_code_key",
    "That location code is already in use.",
  ],
  [
    "active location entitlement limit reached",
    "Your plan's active location limit has been reached.",
  ],
  [
    "pending invitation already exists",
    "A pending invitation already exists for that recipient.",
  ],
  [
    "different recipient",
    "This invitation belongs to a different email address.",
  ],
  ["no longer available", "This invitation has already been used or revoked."],
  ["invitation has expired", "This invitation has expired."],
  ["membership is not eligible", "This membership is suspended or revoked."],
];

export function publicErrorMessage(
  error: { message: string } | null,
  fallback: string,
): string {
  if (!error) {
    return fallback;
  }

  const match = knownMessages.find(([needle]) =>
    error.message.includes(needle),
  );
  return match?.[1] ?? fallback;
}

export function errorRedirect(path: string, message: string): Route {
  const separator = path.includes("?") ? "&" : "?";
  return `${path}${separator}error=${encodeURIComponent(message)}` as Route;
}
import type { Route } from "next";
