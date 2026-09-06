import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { Page } from "@playwright/test";

const here = path.dirname(fileURLToPath(import.meta.url));

/** The three demo apps of SPEC.md step 7, in route order. */
export const DEMOS = [
  { name: "admin", path: "/" },
  { name: "analytics", path: "/analytics" },
  { name: "settings", path: "/settings" },
] as const;

export type Demo = (typeof DEMOS)[number];

/** Every theme `Daisy.Tree.allThemes` offers, in the same order. */
export const ALL_THEMES = [
  "light", "dark", "cupcake", "bumblebee", "emerald", "corporate", "synthwave",
  "retro", "cyberpunk", "valentine", "halloween", "garden", "forest", "aqua",
  "lofi", "pastel", "fantasy", "wireframe", "black", "luxury", "dracula",
  "cmyk", "autumn", "business", "acid", "lemonade", "night", "coffee",
  "winter", "dim", "nord", "sunset", "caramellatte", "abyss", "silk",
] as const;

/**
 * Every class name in `fixtures/schema.json`, read from disk at test time so
 * the specs track the generated schema rather than a copy of it. The two
 * `is-drawer-*:` entries are Tailwind variant prefixes, not classes, so they
 * are dropped.
 */
export function daisyClasses(): string[] {
  const file = path.resolve(here, "..", "..", "fixtures", "schema.json");
  const schema = JSON.parse(fs.readFileSync(file, "utf8")) as Record<
    string,
    Record<string, string[]>
  >;
  const out = new Set<string>();
  for (const groups of Object.values(schema)) {
    for (const list of Object.values(groups)) {
      for (const cls of list) if (!cls.endsWith(":")) out.add(cls);
    }
  }
  return [...out];
}

/**
 * Make a page deterministic before anything is measured or photographed:
 * reduced motion (which daisyUI's own CSS honours), transitions and
 * animations off, no blinking caret, and web fonts settled. Screenshots and
 * rect maths both depend on all four.
 */
export async function open(
  page: Page,
  route: string,
  theme: string,
): Promise<void> {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.addInitScript(() => {
    // Runs before the app boots, so nothing animates even on first paint.
    const style = document.createElement("style");
    style.textContent =
      "*,*::before,*::after{transition:none!important;animation:none!important;" +
      "scroll-behavior:auto!important;caret-color:transparent!important}";
    document.addEventListener("DOMContentLoaded", () =>
      document.head.appendChild(style),
    );
  });
  const sep = route.includes("?") ? "&" : "?";
  await page.goto(`${route}${sep}theme=${theme}`, { waitUntil: "load" });
  await page.locator("text=/^last-msg: /").first().waitFor({ state: "visible" });
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
}
