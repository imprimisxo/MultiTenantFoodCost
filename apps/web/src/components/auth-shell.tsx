import { Badge } from "@workspace/ui/components/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
} from "@workspace/ui/components/card";
import Link from "next/link";
import type { ReactNode } from "react";

export function AuthShell({
  children,
  description,
  title,
}: Readonly<{
  children: ReactNode;
  description: string;
  title: string;
}>) {
  return (
    <main className="bg-background grid min-h-screen place-items-center px-6 py-12">
      <div className="w-full max-w-md">
        <Link className="mb-8 flex items-center gap-3" href="/">
          <span className="bg-primary text-primary-foreground grid size-9 place-items-center rounded-lg text-sm font-semibold">
            R
          </span>
          <span>
            <span className="block text-sm font-semibold">RestaurantOS</span>
            <span className="text-muted-foreground block text-xs">
              Secure organization access
            </span>
          </span>
        </Link>
        <Card>
          <CardHeader>
            <Badge className="mb-3" variant="secondary">
              Milestone 3
            </Badge>
            <h1 className="text-2xl leading-none font-semibold">{title}</h1>
            <CardDescription>{description}</CardDescription>
          </CardHeader>
          <CardContent>{children}</CardContent>
        </Card>
      </div>
    </main>
  );
}
