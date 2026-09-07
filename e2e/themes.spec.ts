import { test, expect } from "./fixtures";
import { haveBaselines, noBaselinesReason } from "./lib/snapshot-tag";
import { ALL_THEMES, DEMOS, open, rootThemeOf } from "./lib/daisy";
import { collectChartColors } from "./lib/browser";

/**
 * SPEC.md step 6, Tier C, row "themes": "Screenshot of each demo in each of
 * the 35 themes matches committed baseline; chart series colours equal the
 * computed `--color-primary` etc. of that theme."
 *
 * ## Where the baselines are taken
 *
 * Screenshots are taken in the `desktop-light` project only: 4 demos x 36
 * themes = **144 baselines** in `e2e/snapshots/`. Taking them in all six
 * projects would mean 864 images for the same information — a theme is a set
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
 * command to generate it rather than writing 144 new baselines into a run that
 * would then trivially pass. The chart-colour sweep below is unaffected — it
 * measures computed colours, not pixels, and runs under every tag.
 *
 * ## The 36th theme, and the 4th demo
 *
 * `acme` is not one of daisyUI's: it is the demo's own `Theme.Custom`
 * (`Demo.Themes.acme`), and no stylesheet anywhere declares it. Everything it
 * paints comes from the inline CSS custom properties `Daisy.Render.page` writes
 * onto the page root, so this sweep is what proves that path end to end — in 36
 * screenshots and in the chart-colour check below, on all four demos.
 *
 * `/theme` (the generator) is the fourth demo, and it always renders
 * `data-theme="acme"` whatever `?theme=` asked for, because it is the theme
 * *editor*: the query picks the palette the editor opens on, and the editor's
 * theme is always the demo's own. `rootThemeOf` is that rule, in one place.
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
 * once, at collection time, so the reason is identical on all 144 tests.
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
      // Skip only when there is nothing to compare against AND this run was
      // not explicitly asked to write baselines. `--update-snapshots` sets
      // updateSnapshots to "changed" (or "all"); the default is "missing",
      // which would write the file and still fail the test, so it counts as
      // "not updating" here.
      const updating =
        testInfo.config.updateSnapshots === "changed" ||
        testInfo.config.updateSnapshots === "all";
      test.skip(!HAVE_BASELINES && !updating, NO_BASELINES_REASON);
      await open(page, demo.path, themeName);
      await expect(page).toHaveScreenshot(`${demo.name}-${themeName}.png`, {
        fullPage: true,
      });
    });
  }
}

test("chart series colours follow the theme in all 36 themes", async ({
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
      expect(theme, "the page root carries the requested theme").toBe(
        rootThemeOf(demo, themeName),
      );
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
  // 36 themes x (2 line series + 3 bar series x 4 bars + 2 area series x 2
  // paints + 3 donut arcs, plus the generator page's own two-series line
  // chart): a regression that stopped emitting `var()` would show up as a
  // collapse in this count, not as a passing run.
  expect(checked).toBeGreaterThan(36 * 10);
});
