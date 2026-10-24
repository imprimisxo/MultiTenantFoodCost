import { expect, test, type Page } from "@playwright/test";

const localPassword = "local-password-only";

async function signIn(page: Page, email: string): Promise<void> {
  await page.goto("/auth/sign-in");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(localPassword);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL((url) => url.pathname !== "/auth/sign-in");
}

test.describe.configure({ mode: "serial" });

test("redirects anonymous users away from protected organization routes", async ({
  page,
}) => {
  await page.goto("/dashboard");
  await expect(page).toHaveURL(/\/auth\/sign-in\?next=%2Fdashboard/);
});

test("holds new signups at email verification", async ({ page }) => {
  const email = `browser-${Date.now()}@example.test`;
  await page.goto("/auth/sign-up");
  await page.getByLabel("Your name").fill("Browser Signup");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill("browser-test-password");
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(page).toHaveURL(/\/auth\/verify-email/);
  await expect(
    page.getByRole("heading", { name: "Verify your email" }),
  ).toBeVisible();
});

test("signs in and loads subscription-aware tenant data", async ({ page }) => {
  await signIn(page, "owner@example.test");
  await expect(page).toHaveURL(/\/dashboard/);
  await expect(
    page.getByRole("heading", { name: "Demo Restaurant Group" }),
  ).toBeVisible();
  await expect(page.getByText("2 / 3.000000")).toBeVisible();
  await expect(page.getByText("Not included", { exact: true })).toBeVisible();
});

test("creates the organization and first location atomically", async ({
  page,
}) => {
  await signIn(page, "new-owner@example.test");
  await expect(page).toHaveURL(/\/onboarding/);
  await page.getByLabel("Organization name").fill("Browser Test Group");
  await page.getByLabel("Organization address").fill("browser-test-group");
  await page.getByLabel("First location name").fill("Test Kitchen");
  await page.getByLabel("Location code").fill("test-kitchen");
  await page.getByRole("button", { name: "Create organization" }).click();
  await expect(page).toHaveURL(/\/dashboard\?notice=organization-created/);
  await expect(
    page.getByRole("heading", { name: "Browser Test Group" }),
  ).toBeVisible();
  await expect(page.getByText("1 / 3.000000")).toBeVisible();
});

test("rejects the wrong invitation recipient and allows one use by the intended recipient", async ({
  browser,
}) => {
  const ownerContext = await browser.newContext();
  const ownerPage = await ownerContext.newPage();
  await signIn(ownerPage, "owner@example.test");
  await ownerPage.goto("/dashboard/team");
  await ownerPage.getByLabel("Recipient email").fill("invitee@example.test");
  await ownerPage
    .getByLabel("Role")
    .selectOption({ label: "Location manager" });
  await ownerPage.getByLabel("Scope").selectOption({ label: "Downtown" });
  await ownerPage.getByRole("button", { name: "Create invitation" }).click();
  const invitationLink = await ownerPage
    .getByLabel("Invitation link")
    .inputValue();
  expect(invitationLink).toMatch(/\/invitations\/accept\?token=[a-f0-9]{64}$/);

  const attackerContext = await browser.newContext();
  const attackerPage = await attackerContext.newPage();
  await signIn(attackerPage, "attacker@example.test");
  await attackerPage.goto(invitationLink);
  await attackerPage.getByRole("button", { name: "Accept invitation" }).click();
  await expect(
    attackerPage
      .getByRole("alert")
      .filter({ hasText: "different email address" }),
  ).toBeVisible();

  const inviteeContext = await browser.newContext();
  const inviteePage = await inviteeContext.newPage();
  await signIn(inviteePage, "invitee@example.test");
  await inviteePage.goto(invitationLink);
  await inviteePage.getByRole("button", { name: "Accept invitation" }).click();
  await expect(inviteePage).toHaveURL(
    /\/dashboard\?notice=invitation-accepted/,
  );
  await expect(
    inviteePage.getByRole("heading", { name: "Demo Restaurant Group" }),
  ).toBeVisible();

  await inviteePage.goto(invitationLink);
  await inviteePage.getByRole("button", { name: "Accept invitation" }).click();
  await expect(
    inviteePage
      .getByRole("alert")
      .filter({ hasText: "already been used or revoked" }),
  ).toBeVisible();
});
