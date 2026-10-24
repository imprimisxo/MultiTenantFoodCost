"use server";

import { redirect } from "next/navigation";

import { errorRedirect, publicErrorMessage } from "@/lib/errors";
import { formString } from "@/lib/forms";
import { asRoute, safeInternalPath } from "@/lib/navigation";
import { getApplicationUrl } from "@/lib/supabase/config";
import { createClient } from "@/lib/supabase/server";
import {
  passwordRecoverySchema,
  passwordUpdateSchema,
  signInSchema,
  signUpSchema,
} from "@/lib/validation";

export async function signUp(formData: FormData): Promise<never> {
  const parsed = signUpSchema.safeParse({
    displayName: formString(formData, "displayName"),
    email: formString(formData, "email"),
    password: formString(formData, "password"),
  });

  if (!parsed.success) {
    redirect(
      errorRedirect(
        "/auth/sign-up",
        "Enter a valid name, email, and password of at least 12 characters.",
      ),
    );
  }

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email: parsed.data.email,
    password: parsed.data.password,
    options: {
      data: { display_name: parsed.data.displayName },
      emailRedirectTo: `${getApplicationUrl()}/auth/callback?next=/onboarding`,
    },
  });

  if (error) {
    redirect(
      errorRedirect(
        "/auth/sign-up",
        publicErrorMessage(
          error,
          "We couldn't create that account. Try again.",
        ),
      ),
    );
  }

  if (data.session) {
    redirect("/onboarding");
  }

  redirect(
    asRoute(
      `/auth/verify-email?email=${encodeURIComponent(parsed.data.email)}`,
    ),
  );
}

export async function signIn(formData: FormData): Promise<never> {
  const parsed = signInSchema.safeParse({
    email: formString(formData, "email"),
    password: formString(formData, "password"),
  });

  if (!parsed.success) {
    redirect(
      errorRedirect("/auth/sign-in", "Enter a valid email and password."),
    );
  }

  const next = safeInternalPath(formString(formData, "next"), "/dashboard");
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);

  if (error) {
    const destination = `/auth/sign-in?next=${encodeURIComponent(next)}`;
    redirect(
      errorRedirect(
        destination,
        publicErrorMessage(error, "We couldn't sign you in. Try again."),
      ),
    );
  }

  redirect(next);
}

export async function signOut(): Promise<never> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/auth/sign-in");
}

export async function requestPasswordReset(formData: FormData): Promise<never> {
  const parsed = passwordRecoverySchema.safeParse({
    email: formString(formData, "email"),
  });

  if (!parsed.success) {
    redirect(errorRedirect("/auth/recover", "Enter a valid email address."));
  }

  const supabase = await createClient();
  await supabase.auth.resetPasswordForEmail(parsed.data.email, {
    redirectTo: `${getApplicationUrl()}/auth/callback?next=/auth/update-password`,
  });

  redirect("/auth/recover?sent=true");
}

export async function updatePassword(formData: FormData): Promise<never> {
  const parsed = passwordUpdateSchema.safeParse({
    password: formString(formData, "password"),
  });

  if (!parsed.success) {
    redirect(
      errorRedirect(
        "/auth/update-password",
        "Use a password of at least 12 characters.",
      ),
    );
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect(
      errorRedirect("/auth/recover", "Request a new password recovery link."),
    );
  }

  const { error } = await supabase.auth.updateUser({
    password: parsed.data.password,
  });

  if (error) {
    redirect(
      errorRedirect(
        "/auth/update-password",
        publicErrorMessage(
          error,
          "We couldn't update your password. Try again.",
        ),
      ),
    );
  }

  redirect("/dashboard?notice=password-updated");
}
