import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import HomePage from "./page";

describe("home page", () => {
  it("describes the foundation without presenting deferred modules as active", () => {
    render(<HomePage />);

    expect(
      screen.getByRole("heading", {
        name: "Operational clarity starts with a secure foundation.",
      }),
    ).toBeInTheDocument();
    expect(screen.getByText("Milestone 1")).toBeInTheDocument();
    expect(screen.getAllByText("Planned")).toHaveLength(6);
    expect(
      screen.getByText(
        "No database, authentication, or tenant data is active yet.",
      ),
    ).toBeInTheDocument();
  });
});
