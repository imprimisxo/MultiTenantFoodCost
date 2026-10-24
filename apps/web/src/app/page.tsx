import { Badge } from "@workspace/ui/components/badge";
import { buttonVariants } from "@workspace/ui/components/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@workspace/ui/components/card";
import { cn } from "@workspace/ui/lib/utils";

const foundations = [
  {
    eyebrow: "Boundaries",
    title: "Modular by default",
    description:
      "Applications, shared interface primitives, and build configuration live behind explicit workspace contracts.",
  },
  {
    eyebrow: "Security",
    title: "Tenant safety is a gate",
    description:
      "Verified Supabase sessions, server permissions, and PostgreSQL row-level security guard every tenant boundary.",
  },
  {
    eyebrow: "Delivery",
    title: "Every change is verified",
    description:
      "Formatting, linting, type checks, tests, and production builds run locally and in continuous integration.",
  },
] as const;

const plannedModules = [
  "Recipes",
  "Food costing",
  "Inventory",
  "Purchasing",
  "POS integrations",
  "Subscriptions",
] as const;

export default function HomePage() {
  return (
    <main className="bg-background min-h-screen overflow-hidden">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col px-6 sm:px-8 lg:px-12">
        <header className="border-border/80 flex items-center justify-between border-b py-6">
          <div className="flex items-center gap-3">
            <div
              aria-hidden="true"
              className="bg-primary text-primary-foreground grid size-9 place-items-center rounded-lg text-sm font-semibold"
            >
              R
            </div>
            <div>
              <p className="text-sm font-semibold tracking-tight">
                RestaurantOS
              </p>
              <p className="text-muted-foreground text-xs">
                Operations platform
              </p>
            </div>
          </div>
          <Badge variant="outline">Milestone 3</Badge>
        </header>

        <section className="relative grid flex-1 items-center gap-14 py-20 lg:grid-cols-[1.25fr_0.75fr] lg:py-28">
          <div className="relative z-10 max-w-3xl">
            <Badge className="mb-6" variant="secondary">
              Commercial SaaS foundation
            </Badge>
            <h1 className="text-5xl font-semibold tracking-[-0.045em] text-balance sm:text-6xl lg:text-7xl">
              Your restaurant organization, securely in context.
            </h1>
            <p className="text-muted-foreground mt-6 max-w-2xl text-lg leading-8 text-pretty sm:text-xl">
              Create an organization, manage authorized locations, invite your
              team, and keep every request inside its verified tenant and
              subscription boundary.
            </p>
            <div className="mt-9 flex flex-wrap items-center gap-4">
              <a
                className={cn(buttonVariants({ size: "lg" }), "rounded-full")}
                href="/auth/sign-up"
              >
                Create your organization
              </a>
              <a
                className={cn(
                  buttonVariants({ size: "lg", variant: "outline" }),
                  "rounded-full",
                )}
                href="/auth/sign-in"
              >
                Sign in
              </a>
            </div>
          </div>

          <Card className="border-primary/15 bg-card/90 relative shadow-[0_30px_80px_-45px_oklch(0.43_0.11_151_/_0.5)] backdrop-blur">
            <CardHeader>
              <div className="mb-4 flex items-center justify-between">
                <Badge variant="secondary">Roadmap</Badge>
                <span className="text-muted-foreground text-xs font-medium">
                  Architecture v1.0
                </span>
              </div>
              <CardTitle className="text-xl">Purpose-built modules</CardTitle>
              <CardDescription>
                Planned behind shared tenancy, permissions, and entitlement
                boundaries.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul
                className="grid grid-cols-2 gap-3"
                aria-label="Planned modules"
              >
                {plannedModules.map((module) => (
                  <li
                    className="border-border bg-background/70 rounded-lg border p-3"
                    key={module}
                  >
                    <p className="text-sm font-medium">{module}</p>
                    <p className="text-muted-foreground mt-1 text-xs">
                      Planned
                    </p>
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>

          <div
            aria-hidden="true"
            className="bg-accent/60 absolute top-1/2 -right-32 size-[30rem] -translate-y-1/2 rounded-full blur-3xl"
          />
        </section>

        <section className="border-border/80 border-t py-16" id="foundation">
          <div className="mb-10 max-w-2xl">
            <p className="text-primary text-sm font-semibold tracking-[0.18em] uppercase">
              Secure organization shell
            </p>
            <h2 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">
              Ready for authorized collaboration.
            </h2>
          </div>
          <div className="grid gap-5 md:grid-cols-3">
            {foundations.map((item) => (
              <Card className="bg-card/60" key={item.title}>
                <CardHeader>
                  <p className="text-primary text-xs font-semibold tracking-[0.16em] uppercase">
                    {item.eyebrow}
                  </p>
                  <CardTitle className="text-lg">{item.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground text-sm leading-6">
                    {item.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <footer className="border-border/80 text-muted-foreground flex flex-col gap-2 border-t py-8 text-xs sm:flex-row sm:items-center sm:justify-between">
          <p>RestaurantOS organization shell</p>
          <p>Operational modules remain intentionally out of scope.</p>
        </footer>
      </div>
    </main>
  );
}
