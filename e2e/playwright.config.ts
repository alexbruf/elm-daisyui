import { defineConfig } from "@playwright/test";
import { execSync } from "node:child_process";
import type { DaisyOptions } from "./fixtures";

// Fixed port for the built demo's `vite preview` server. We ask `devports`
// (https://github.com/bendechrai/devports) for a stable per-project
// allocation so this doesn't collide with other local dev servers; if
// `devports` isn't on PATH (e.g. a bare CI image) we fall back to Vite
// preview's own default, 4173.
//
// `devports allocate` errors on a second call for the same project/service
// ("already allocated ... use release first") rather than being idempotent,
// so we look the allocation up first (`list --json`) and only allocate if
// it doesn't exist yet.
function resolvePreviewPort(): number {
  const project = "elm-daisy";
  const service = "e2e-preview";
  try {
    const listOut = execSync(`devports list --project ${project} --json`, {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    const parsed = JSON.parse(listOut) as {
      allocations: { port: number; service: string }[];
    };
    const existing = parsed.allocations.find((a) => a.service === service);
    if (existing) return existing.port;

    const out = execSync(
      `devports allocate ${project} ${service} --type app -q`,
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }
    ).trim();
    const port = Number(out);
    if (Number.isInteger(port) && port > 0) return port;
  } catch {
    // devports not available (or failed some other way) — fall back below.
  }
  return 4173;
}

const PORT = resolvePreviewPort();
const BASE_URL = `http://localhost:${PORT}`;

// --- Viewport x Theme project matrix -----------------------------------
//
// SPEC.md Tier C runs every spec across 3 demos x viewports 375/768/1440 x
// themes light/dark (the `themes` spec itself sweeps all 35 daisyUI themes
// separately, outside this matrix). We encode:
//   - viewport as a genuine Playwright `use.viewport` (real browser size)
//   - theme as a custom `theme` test-option fixture (see ./fixtures.ts)
//
// Convention for every spec: read the `theme` fixture and navigate with it
// as a query param, e.g.:
//
//   test("...", async ({ page, theme }) => {
//     await page.goto(`/?theme=${theme}`);
//     ...
//   });
//
// The demo's bootstrap (demo/src/main.js) is responsible for reading
// `?theme=` from the URL and applying it (e.g. via flags into Elm, which
// sets `data-theme` on <html>/<body> — daisyUI themes switch on that
// attribute). Project names are `<viewport>-<theme>`, e.g. `mobile-dark`.
const VIEWPORTS = {
  mobile: { width: 375, height: 667 },
  tablet: { width: 768, height: 1024 },
  desktop: { width: 1440, height: 900 },
} as const;

const THEMES = ["light", "dark"] as const;

const projects = [];
for (const [viewportName, viewport] of Object.entries(VIEWPORTS)) {
  for (const theme of THEMES) {
    projects.push({
      name: `${viewportName}-${theme}`,
      use: {
        viewport,
        // Screenshot baselines are device-pixel exact, so the ratio is
        // pinned rather than inherited from the host display.
        deviceScaleFactor: 1,
        channel: "chrome",
        theme,
      } as DaisyOptions & {
        viewport: typeof viewport;
        channel: string;
        deviceScaleFactor: number;
      },
    });
  }
}

export default defineConfig({
  testDir: ".",
  snapshotDir: "./snapshots",
  // Flat, project-independent snapshot names: `themes.spec.ts` takes its
  // baselines in one project only (see the file's header), so a per-project
  // path would only add noise.
  snapshotPathTemplate: "{snapshotDir}/{arg}{ext}",
  timeout: 60_000,
  expect: {
    timeout: 10_000,
    toHaveScreenshot: { maxDiffPixels: 0, animations: "disabled", scale: "css" },
  },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [["list"]],
  use: {
    baseURL: BASE_URL,
    channel: "chrome",
    headless: true,
    trace: "on-first-retry",
  },
  projects,
  webServer: {
    command: `bun run preview -- --port ${PORT} --strictPort`,
    cwd: "../demo",
    url: BASE_URL,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
});
