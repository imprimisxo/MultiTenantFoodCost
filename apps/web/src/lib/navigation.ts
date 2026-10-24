import type { Route } from "next";

export function asRoute(path: string): Route {
  return path as Route;
}

export function safeInternalPath(
  candidate: string | null | undefined,
  fallback: string,
): Route {
  if (!candidate || !candidate.startsWith("/") || candidate.startsWith("//")) {
    return asRoute(fallback);
  }

  try {
    const parsed = new URL(candidate, "https://restaurantos.invalid");

    if (parsed.origin !== "https://restaurantos.invalid") {
      return asRoute(fallback);
    }

    return asRoute(`${parsed.pathname}${parsed.search}${parsed.hash}`);
  } catch {
    return asRoute(fallback);
  }
}

export function firstSearchParam(
  value: string | string[] | undefined,
): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}
