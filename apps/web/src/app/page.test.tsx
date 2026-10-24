import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import HomePage from "./page";

describe("home page", () => {
  it("presents the secure organization shell without presenting deferred modules as active", () => {
    render(<HomePage />);

    expect(
      screen.getByRole("heading", {
        name: "Your restaurant organization, securely in context.",
      }),
    ).toBeInTheDocument();
    expect(screen.getByText("Milestone 3")).toBeInTheDocument();
    expect(screen.getAllByText("Planned")).toHaveLength(6);
    expect(
      screen.getByText(
        "Operational modules remain intentionally out of scope.",
      ),
    ).toBeInTheDocument();
  });
});
