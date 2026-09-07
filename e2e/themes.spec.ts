import { test, expect } from "./fixtures";
import { haveBaselines, noBaselinesReason } from "./lib/snapshot-tag";
import { ALL_THEMES, DEMOS, open } from "./lib/daisy";
import { collectChartColors } from "./lib/browser";

/**
 * SPEC.md step 6, Tier C, row "themes": "Screenshot of each demo in each of
 * the 35 themes matches committed baseline; chart series colours equal the
 * computed `--color-primary` etc. of that theme."
 *
 * ## Where the baselines are taken
 *
 * Screenshots are taken in the `desktop-light` project only: 3 demos x 35
 * themes = **105 baselines** in `e2e/snapshots/`. Taking them in all six
 * projects would mean 630 images for the same information — a theme is a set
 * of colours, and the three viewports are already covered pixel-for-pixel by
 * `overlap`, `overflow` and `responsive`, which measure geometry rather than
 * photograph it. The project's own `theme` option is ignored here, since the
 * sweep sets the theme itself through `?theme=`.
 *
 * Determinism: reduced motion is emulated and transitions/animations/caret are
 * killed before first paint (`lib/daisy.ts`), `deviceScaleFactor` is pinned to
 * 1 in `playwright.config.ts`, the demo bundles its own font (`Inter Variable`
 * via `@fontsource-variable/inter`, so no OS font is in the picture), and
 * `document.fonts.ready` is awaited.
 *
 * ## Environment tag
 *
 * Baselines are still machine-specific below the font layer (Chrome build,
 * rasteriser), and `maxDiffPixels` is 0, so they are committed per environment
 * under `e2e/snapshots/<tag>/` — `local` by default, `ci` on GitHub Actions
 * (`SNAPSHOT_TAG`, see `playwright.config.ts`). A tag whose directory does not
 * exist yet has never been generated: the comparison then *skips* with the
 * command to generate it rather than writing 105 new baselines into a run that
 * would then trivially pass. The chart-colour sweep below is unaffected — it
 * measures computed colours, not pixels, and runs under every tag.
 *
 * ## Chart colours
 *
 * `Daisy.Render` writes chart series colours as `var(--color-primary)` and
 * friends onto the SVG `stroke`/`fill` attribute. The check reads the computed
 * value back off the same element — which is what resolves the `var()` — and
 * compares it with the theme's own custom property, both painted through a
 * canvas so the comparison is in sRGB bytes whatever colour syntax the theme
 * is written in. `data-theme` sits on the page root that `Daisy.Render.page`
 * emits, not on `<html>`, so the properties are read from that element.
 */
const SWEEP_PROJECT = "desktop-light";

/**
 * Whether this environment's baselines have been generated at all. Resolved
 * once, at collection time, so the reason is identical on all 105 tests.
 * `playwright.config.ts` prints the same sentence once at the top of the run.
 */
const HAVE_BASELINES = haveBaselines();
const NO_BASELINES_REASON = noBaselinesReason(SWEEP_PROJECT);

for (const themeName of ALL_THEMES) {
  for (const demo of DEMOS) {
    test(`${demo.name} in ${themeName} matches its baseline`, async ({
      page,
    }, testInfo) => {
      test.skip(
        testInfo.project.name !== SWEEP_PROJECT,
        `screenshot baselines are taken in ${SWEEP_PROJECT} only`,
      );
      test.skip(!HAVE_BASELINES, NO_BASELINES_REASON);
      await open(page, demo.path, themeName);
      await expect(page).toHaveScreenshot(`${demo.name}-${themeName}.png`, {
        fullPage: true,
      });
    });
  }
}

test("chart series colours follow the theme in all 35 themes", async ({
  page,
}, testInfo) => {
  test.skip(
    testInfo.project.name !== SWEEP_PROJECT,
    `theme sweeps run once, in ${SWEEP_PROJECT}`,
  );
  test.setTimeout(300_000);

  const charted = DEMOS.filter((d) => d.name !== "settings");
  const failures: string[] = [];
  let checked = 0;

  for (const themeName of ALL_THEMES) {
    for (const demo of charted) {
      await open(page, demo.path, themeName);
      const { theme, rows } = await page.evaluate(collectChartColors);
      expect(theme, "the page root carries the requested theme").toBe(themeName);
      expect(
        rows.length,
        `${demo.name} draws chart series through --color-* variables`,
      ).toBeGreaterThan(0);
      for (const row of rows) {
        checked++;
        const same =
          row.computed &&
          row.expected &&
          row.computed.every((v, i) => Math.abs(v - row.expected![i]) <= 1);
        if (!same) {
          failures.push(
            `${themeName} ${demo.name} <${row.tag} ${row.property}=var(${row.token})>: ` +
              `computed ${row.computed} != ${row.token} ${row.expected}`,
          );
        }
      }
    }
  }

  expect(failures).toEqual([]);
  // 35 themes x (2 line series + 3 bar series x 4 bars + 2 area series x 2
  // paints + 3 donut arcs): a regression that stopped emitting `var()` would
  // show up as a collapse in this count, not as a passing run.
  expect(checked).toBeGreaterThan(35 * 10);
});
