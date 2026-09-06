import { test as base, expect } from "@playwright/test";

// `theme` is a custom Playwright *test option* fixture (not a browser
// context option) — it's set per-project in playwright.config.ts and read
// by specs to build the `?theme=` query string. See e2e/README.md for the
// full viewport/theme project-matrix convention.
export type DaisyOptions = {
  theme: "light" | "dark";
};

export const test = base.extend<DaisyOptions>({
  // Default only matters if a project forgets to set it; every real project
  // below sets it explicitly.
  theme: ["light", { option: true }],
});

export { expect };
