import { z } from "zod";

const email = z.string().trim().toLowerCase().email().max(254);
const password = z.string().min(12).max(128);
const name = z.string().trim().min(1).max(120);
const slug = z
  .string()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
  .max(80);
const code = z
  .string()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
  .max(40);
export const databaseUuidSchema = z
  .string()
  .regex(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
const uuid = databaseUuidSchema;

export const signUpSchema = z.object({
  displayName: name,
  email,
  password,
});

export const signInSchema = z.object({ email, password: z.string().min(1) });
export const passwordRecoverySchema = z.object({ email });
export const passwordUpdateSchema = z.object({ password });

export const onboardingSchema = z.object({
  organizationName: name,
  organizationSlug: slug,
  defaultCurrency: z
    .string()
    .trim()
    .toUpperCase()
    .regex(/^[A-Z]{3}$/),
  locationName: name,
  locationCode: code,
  locationTimeZone: z.string().trim().min(1).max(100),
});

export const contextSchema = z.object({
  organizationId: uuid,
  locationId: z.union([uuid, z.literal("")]).optional(),
});

export const locationSchema = z.object({
  organizationId: uuid,
  locationId: uuid.optional(),
  name,
  code,
  timeZone: z.string().trim().min(1).max(100),
  isActive: z.boolean(),
});

export const invitationSchema = z.object({
  organizationId: uuid,
  email,
  roleId: uuid,
  locationId: z.union([uuid, z.literal("")]).optional(),
  expiresInHours: z.coerce.number().int().min(1).max(168),
});

export const invitationTokenSchema = z.string().regex(/^[a-f0-9]{64}$/);

export const revokeInvitationSchema = z.object({
  organizationId: uuid,
  invitationId: uuid,
});
