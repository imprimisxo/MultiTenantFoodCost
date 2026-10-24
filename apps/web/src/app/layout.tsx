import type { Metadata } from "next";
import type { ReactNode } from "react";

import "@workspace/ui/globals.css";

export const metadata: Metadata = {
  title: {
    default: "RestaurantOS",
    template: "%s | RestaurantOS",
  },
  description:
    "Secure multi-tenant organization access for a restaurant operations platform.",
  referrer: "same-origin",
};

export default function RootLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  return (
    <html data-scroll-behavior="smooth" lang="en">
      <body>{children}</body>
    </html>
  );
}
