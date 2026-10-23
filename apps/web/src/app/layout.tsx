import type { Metadata } from "next";
import type { ReactNode } from "react";

import "@workspace/ui/globals.css";

export const metadata: Metadata = {
  title: {
    default: "RestaurantOS",
    template: "%s | RestaurantOS",
  },
  description:
    "A production-oriented restaurant operations platform foundation.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
