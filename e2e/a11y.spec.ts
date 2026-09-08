import AxeBuilder from "@axe-core/playwright";
import { test, expect } from "./fixtures";
import { DEMOS, open } from "./lib/daisy";

/**
 * SPEC.md step 6, Tier C, row "a11y": "Zero serious or critical axe violations
 * per demo per theme." Moderate and minor findings are reported in the failure
 * message when there is one, but do not fail the run — the row is explicit
 * about the two impacts that matter.
 *
 * The Settings demo is scanned twice, once with its confirm modal open, since
 * a native `<dialog>` in the top layer is a different accessibility tree.
 *
 * The moderate/minor count is printed for every scan (`moderate=<n>`) so the
 * effect of a composition change on the findings the row does not fail on is
 * visible in the run output. It is reported, never asserted.
 */
function moderateLine(
  label: string,
  results: Awaited<ReturnType<AxeBuilder["analyze"]>>,
): string {
  const soft = waived(results).filter(
    (v) => v.impact === "moderate" || v.impact === "minor",
  );
  const ids = soft.map((v) => `${v.id}[${v.impact}]x${v.nodes.length}`);
  return `axe ${label}: moderate=${soft.filter((v) => v.impact === "moderate").length} minor=${soft.filter((v) => v.impact === "minor").length}${ids.length ? " " + ids.join(" ") : ""}`;
}

/**
 * The de-emphasised colour pairs daisyUI itself ships, waived for the
 * `color-contrast` rule and for nothing else. Three daisyUI classes reach one:
 *
 *   - `menu-title`: `color-mix(in oklab, var(--color-base-content) 40%,
 *     transparent)` — daisyUI's own section label inside a `menu`.
 *   - `tab` (not the active one): the same recipe at 50% — daisyUI's own
 *     unselected tab, which is what makes `tabs-box` read as a segmented
 *     control.
 *   - any `*-outline` / `*-dash` / `*-soft` variant: `var(--color-X)` over the
 *     surface behind it (`badge-soft`, `alert-outline`, `alert-dash`,
 *     `alert-soft`) — daisyUI's own three style variants, matched by the
 *     class-name pattern `DAISY_STYLE_VARIANT` rather than by name.
 *
 * None of those colours is reachable through `Daisy.Tree`: the tree hands
 * daisyUI a `MenuItem.title` flag, a `Tab.active` flag and a `Badge.Soft`
 * style, and daisyUI picks the paint — exactly as it does in the Nexus
 * dashboard template it ships, in these same three places (a sidebar section
 * label, a `Day | Month | Year` switch, a status pill). Changing any of them
 * would mean editing `vendor/daisyui`, which is forbidden.
 *
 * A second waiver, `daisyPalettePairTargets` below, covers daisyUI's *emphasised*
 * pair — `--color-X` under `--color-X-content` — and is decided in the browser
 * rather than from a class list.
 *
 * The waiver is a node filter rather than an `AxeBuilder.exclude()`: excluding
 * the elements would take them out of *every* rule, and they still have to
 * answer for their roles, names and structure. It matches on the offending
 * node's own **class list**, not on the selector axe happened to print — axe
 * picks a minimal unique selector, so a `badge badge-info badge-sm badge-soft`
 * is reported as `.badge-info` and a selector match would silently miss it.
 * `e2e/contrast.spec.ts` classifies the same pairs as daisyUI's own by a
 * mechanical rule, and `docs/e2e-findings.md` records both halves.
 */
const DAISY_DEEMPHASIS_CLASSES = ["menu-title", "tab"];

/**
 * daisyUI's three style variants, as a class-*name* pattern rather than a list.
 *
 * `<component>-outline`, `<component>-dash` and `<component>-soft` all paint
 * `color: var(--color-X)` over a surface the component does not paint — a pair
 * daisyUI's own rule chooses, exactly like `--color-X-content` over
 * `--color-X`. The theme generator's alert block shows all four treatments of
 * the four state colours at once, which is the whole point of the block, and
 * daisyUI's own generator uses the same four.
 *
 * `badge-soft` used to be spelled out in the list above; it is this pattern.
 * `e2e/contrast.spec.ts` applies the same rule with the colours as well as the
 * name (`styleVariantOf` in `lib/browser.ts`), so the stricter of the two is
 * the one that would catch a variant class on a pair daisyUI did not choose.
 */
const DAISY_STYLE_VARIANT = /^[a-z][a-z0-9]*-(outline|dash|soft)$/;

function isDaisyDeemphasis(node: { html?: string }): boolean {
  const match = /\sclass="([^"]*)"/.exec(node.html ?? "");
  if (!match) return false;
  const classes = match[1].split(/\s+/);
  return (
    DAISY_DEEMPHASIS_CLASSES.some((c) => classes.includes(c)) ||
    classes.some((c) => DAISY_STYLE_VARIANT.test(c))
  );
}

/**
 * The *other* pair daisyUI owns: a `--color-X` background under exactly its own
 * `--color-X-content` foreground.
 *
 * SPEC.md's "what is deliberately not tested" puts those outside Tier C —
 * "daisyUI's `contrast.test.js` already does that; Tier C contrast tests the
 * rendered result instead" — and `e2e/contrast.spec.ts` has applied that rule
 * from the start, mechanically, with a `test.fixme` recording the full claim.
 * This is the same rule, so that the two specs agree about the same nodes
 * instead of one exempting what the other fails on.
 *
 * It matters here because the theme generator page's whole job is to *show* a
 * theme's colour pairs, and some of them are bad: the demo's own `acme` theme
 * (which daisyUI's generator produced) pairs `--color-secondary`
 * `oklch(76% 0.188 70.08)` with `--color-secondary-content`
 * `oklch(98% 0.022 95.277)` at 1.9:1. Nothing the tree, the renderer or the
 * page chooses is wrong there — `Leaf.Swatch SwatchSecondary` names a slot, and
 * daisyUI's own derivation picked the two colours.
 *
 * Deciding it in the browser rather than from a class list is what keeps it
 * honest: a `-content` colour over the *wrong* surface, or a `color-mix`
 * background, does not match and still fails. The comparison is on painted sRGB
 * bytes, so `oklch()` in the theme and `rgb()` from `getComputedStyle` compare
 * the same way `lib/browser.ts` compares them.
 */
async function daisyPalettePairTargets(
  page: import("@playwright/test").Page,
  targets: string[],
): Promise<Set<string>> {
  if (targets.length === 0) return new Set();
  const matched = await page.evaluate((selectors: string[]) => {
    const cv = document.createElement("canvas");
    cv.width = cv.height = 1;
    const ctx = cv.getContext("2d", { willReadFrequently: true })!;
    const paint = (color: string): number[] | null => {
      if (!color) return null;
      ctx.clearRect(0, 0, 1, 1);
      ctx.fillStyle = "#000000";
      ctx.fillStyle = color;
      ctx.fillRect(0, 0, 1, 1);
      const d = ctx.getImageData(0, 0, 1, 1).data;
      return d[3] < 250 ? null : [d[0], d[1], d[2]];
    };
    const near = (a: number[] | null, b: number[] | null) =>
      !!a && !!b && a.every((v, i) => Math.abs(v - b[i]) <= 3);

    const root = document.querySelector("[data-theme]") ?? document.documentElement;
    const rootStyle = getComputedStyle(root);
    const names = [
      "primary",
      "secondary",
      "accent",
      "neutral",
      "info",
      "success",
      "warning",
      "error",
      "base-100",
      "base-200",
      "base-300",
    ];
    const pairs = names.map((name) => ({
      name,
      bg: paint(rootStyle.getPropertyValue("--color-" + name).trim()),
      fg: paint(
        rootStyle
          .getPropertyValue(
            name.startsWith("base-") ? "--color-base-content" : "--color-" + name + "-content",
          )
          .trim(),
      ),
    }));

    /** The nearest ancestor (self included) that paints an opaque background. */
    const opaqueBackground = (el: Element): number[] | null => {
      for (let node: Element | null = el; node; node = node.parentElement) {
        const painted = paint(getComputedStyle(node).backgroundColor);
        if (painted) return painted;
      }
      return null;
    };

    const out: string[] = [];
    for (const selector of selectors) {
      const el = document.querySelector(selector);
      if (!el) continue;
      const fg = paint(getComputedStyle(el).color);
      const bg = opaqueBackground(el);
      if (pairs.some((p) => near(bg, p.bg) && near(fg, p.fg))) out.push(selector);
    }
    return out;
  }, targets);
  return new Set(matched);
}

/**
 * Violations, with the waiver above applied: a `color-contrast` violation keeps
 * only the nodes that are *not* one of daisyUI's two de-emphasised pairs, and
 * disappears entirely when that leaves it with no nodes. Every other rule is
 * untouched.
 */
function waived(
  results: Awaited<ReturnType<AxeBuilder["analyze"]>>,
  palettePairs: Set<string> = new Set(),
) {
  return results.violations
    .map((v) =>
      v.id === "color-contrast"
        ? {
            ...v,
            nodes: v.nodes.filter(
              (n) =>
                !isDaisyDeemphasis(n) && !palettePairs.has(n.target.join(" ")),
            ),
          }
        : v,
    )
    .filter((v) => v.nodes.length > 0);
}


/** Every `color-contrast` node axe reported, as its own target selector. */
function contrastTargets(
  results: Awaited<ReturnType<AxeBuilder["analyze"]>>,
): string[] {
  return results.violations
    .filter((v) => v.id === "color-contrast")
    .flatMap((v) => v.nodes.map((n) => n.target.join(" ")));
}

function serious(
  results: Awaited<ReturnType<AxeBuilder["analyze"]>>,
  palettePairs: Set<string> = new Set(),
) {
  return waived(results, palettePairs)
    .filter((v) => v.impact === "serious" || v.impact === "critical")
    .map(
      (v) =>
        `${v.id} [${v.impact}] x${v.nodes.length}: ${v.nodes
          .map((n) => n.target.join(" "))
          .join(" | ")}`,
    );
}

for (const demo of DEMOS) {
  test(`${demo.name}: no serious or critical axe violations`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const results = await new AxeBuilder({ page }).analyze();
    const palettePairs = await daisyPalettePairTargets(
      page,
      contrastTargets(results),
    );
    console.log(moderateLine(`${demo.name} ${theme}`, results));
    expect(serious(results, palettePairs)).toEqual([]);
  });
}

test("settings: no serious or critical axe violations with the modal open", async ({
  page,
  theme,
}) => {
  await open(page, "/settings", theme);
  await page.getByRole("button", { name: "Save changes" }).click();
  await expect(page.locator("dialog.modal")).toBeVisible();
  const results = await new AxeBuilder({ page }).analyze();
  console.log(moderateLine(`settings-modal ${theme}`, results));
  expect(serious(results)).toEqual([]);
});
