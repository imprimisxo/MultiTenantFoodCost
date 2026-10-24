import { describe, expect, it } from "vitest";

import { slugify } from "./forms";
import { safeInternalPath } from "./navigation";
import {
  invitationSchema,
  invitationTokenSchema,
  onboardingSchema,
  signUpSchema,
} from "./validation";

describe("security boundary helpers", () => {
  it("allows internal callback paths and blocks external redirects", () => {
    expect(safeInternalPath("/dashboard?notice=ready", "/fallback")).toBe(
      "/dashboard?notice=ready",
    );
    expect(safeInternalPath("//attacker.example/path", "/fallback")).toBe(
      "/fallback",
    );
    expect(safeInternalPath("https://attacker.example/path", "/fallback")).toBe(
      "/fallback",
    );
  });

  it("normalizes user-entered slugs without admitting path separators", () => {
    expect(slugify("  North Star / Downtown  ")).toBe("north-star-downtown");
  });

  it("requires a strong signup password and normalized email", () => {
    expect(
      signUpSchema.safeParse({
        displayName: "Jordan Owner",
        email: "OWNER@EXAMPLE.TEST",
        password: "short",
      }).success,
    ).toBe(false);

    const result = signUpSchema.parse({
      displayName: "Jordan Owner",
      email: "OWNER@EXAMPLE.TEST",
      password: "a-long-local-password",
    });
    expect(result.email).toBe("owner@example.test");
  });

  it("rejects malformed onboarding identifiers", () => {
    expect(
      onboardingSchema.safeParse({
        defaultCurrency: "usd",
        locationCode: "../downtown",
        locationName: "Downtown",
        locationTimeZone: "America/Chicago",
        organizationName: "North Star",
        organizationSlug: "North Star",
      }).success,
    ).toBe(false);
  });

  it("accepts only full 256-bit hexadecimal invitation secrets", () => {
    expect(invitationTokenSchema.safeParse("abc").success).toBe(false);
    expect(invitationTokenSchema.safeParse("a".repeat(64)).success).toBe(true);
  });

  it("accepts canonical PostgreSQL UUIDs without requiring RFC version bits", () => {
    expect(
      invitationSchema.safeParse({
        email: "staff@example.test",
        expiresInHours: "72",
        locationId: "30000000-0000-0000-0000-000000000001",
        organizationId: "20000000-0000-0000-0000-000000000001",
        roleId: "50000000-0000-0000-0000-000000000002",
      }).success,
    ).toBe(true);
  });
});
