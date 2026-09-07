import { test, expect } from "./fixtures";
import { ALL_THEMES, DEMOS, open } from "./lib/daisy";
import { collectContrast, type ContrastHit } from "./lib/browser";

/**
 * SPEC.md step 6, Tier C, row "contrast": "Every visible text node has WCAG
 * contrast >= 4.5 against its effective background, in every theme."
 *
 * How the numbers are produced is in `lib/browser.ts`: every colour is painted
 * through a 1x1 canvas, so `oklch()`, `color(srgb ...)` and plain `rgb()` all
 * end up as sRGB bytes with alpha composited the way the browser composites
 * it, and the background is the whole ancestor chain painted outermost-first
 * rather than "the first ancestor with a background".
 *
 * Skipped, per the row: elements marked disabled (`[disabled]`,
 * `[aria-disabled=true]`, `btn-disabled`, `menu-disabled`), anything hidden,
 * and text painted fully transparent (daisyUI's `modal-backdrop`).
 *
 * ## The one split in this file
 *
 * SPEC's "what is deliberately not tested" says daisyUI's own theme contrast
 * is daisyUI's business ("daisyUI's `contrast.test.js` already does that; Tier
 * C contrast tests the rendered result instead"). Some of daisyUI's own colour
 * pairs do not reach 4.5:1 — `--color-primary` under `--color-primary-content`
 * in `dark` is 4.13:1, and the translucent `--color-base-content` that paints
 * `.stat-title`, `.label` and table headers is under 4.5:1 in about twenty of
 * the 35 themes. Nothing the tree, the renderer or a demo can do changes those
 * numbers short of editing `vendor/daisyui`, which is forbidden.
 *
 * So the row is asserted twice:
 *
 *   - the running test asserts it for every pair the *composition* chooses —
 *     a failure there is ours (it is what caught `badge-soft` on a light
 *     background, and a `btn-neutral btn-ghost` row action in `dark`);
 *   - the `test.fixme` right after it asserts the row as written, including
 *     daisyUI's own pairs, and stays red until daisyUI's palette changes.
 *
 * "daisyUI's own pair" is decided mechanically, not by a list of selectors:
 * the foreground must be exactly `--color-X-content` over a `--color-X`
 * background, or a translucent `--color-base-content`. Anything else — a
 * `color-mix` background like `badge-soft`, or a `-content` colour over the
 * wrong surface — counts as ours. See `docs/e2e-findings.md`.
 */
const MIN_RATIO = 4.5;

function describeHit(h: ContrastHit): string {
  return (
    `${h.ratio}:1  ${h.selector}  "${h.text}"  ` +
    `fg=${h.fg.join(",")} bg=${h.bg.join(",")} ${h.fontSize}px [${h.pairing}]`
  );
}

for (const demo of DEMOS) {
  test(`${demo.name}: composed text reaches ${MIN_RATIO}:1`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const hits = await page.evaluate(collectContrast);
    expect(hits.length, "the page has visible text").toBeGreaterThan(0);
    expect(
      hits
        .filter((h) => h.ratio < MIN_RATIO && !h.daisyPalettePair)
        .map(describeHit),
    ).toEqual([]);
  });

  test.fixme(
    `${demo.name}: all text reaches ${MIN_RATIO}:1, daisyUI's own colour pairs included`,
    async ({ page, theme }) => {
      await open(page, demo.path, theme);
      const hits = await page.evaluate(collectContrast);
      expect(hits.filter((h) => h.ratio < MIN_RATIO).map(describeHit)).toEqual([]);
    },
  );
}

/**
 * The 36-theme sweep. It is the same assertion as above, run once over every
 * theme `Daisy.Tree.allThemes` offers — plus `acme`, the demo's own
 * `Theme.Custom`, whose colours reach the page only as inline custom properties
 * — rather than once per matrix row, because theme colours do not depend on the
 * viewport. It runs in `desktop-light` only; the project's own `theme` option is
 * ignored here since the sweep sets the theme itself.
 *
 * The classifier in `lib/browser.ts` needs no change for a custom theme: it
 * decides "daisyUI's own pair" by comparing computed colours against the root's
 * `--color-*` values, and `getComputedStyle` resolves an inline custom property
 * exactly as it resolves one from a stylesheet rule.
 */
test("every theme: composed text reaches 4.5:1 on all four demos", async ({
  page,
}, testInfo) => {
  test.skip(
    testInfo.project.name !== "desktop-light",
    "theme sweeps run once, in desktop-light",
  );
  test.setTimeout(300_000);

  const failures: string[] = [];
  for (const themeName of ALL_THEMES) {
    for (const demo of DEMOS) {
      await open(page, demo.path, themeName);
      const hits = await page.evaluate(collectContrast);
      for (const h of hits) {
        if (h.ratio < MIN_RATIO && !h.daisyPalettePair) {
          failures.push(`${themeName} ${demo.name}: ${describeHit(h)}`);
        }
      }
    }
  }
  expect(failures).toEqual([]);
});
