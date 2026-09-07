import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/**
 * Screenshot baselines are environment-tagged.
 *
 * A `toHaveScreenshot` baseline is only comparable against the environment
 * that took it. The font is no longer part of that: `demo/app.css` bundles
 * `Inter Variable` (`@fontsource-variable/inter`) and sets Tailwind 4's
 * `--font-sans` to it, so no OS font is in the picture. What is still
 * environment-specific is everything below the font — the Chrome build and
 * its rasteriser. `maxDiffPixels` is 0 on purpose, so rather than loosening
 * the comparison we commit one set of baselines per environment:
 *
 *   e2e/snapshots/local/*.png   taken on a developer machine (the default)
 *   e2e/snapshots/ci/*.png      taken on ubuntu-latest by
 *                               .github/workflows/update-snapshots.yml
 *
 * `SNAPSHOT_TAG` selects the set. `.github/workflows/ci.yml` sets it to `ci`;
 * anything else defaults to `local`. Adding a tag is running the sweep with
 * `SNAPSHOT_TAG=<tag> ... --update-snapshots` and committing the directory.
 *
 * This lives in its own module rather than in `playwright.config.ts` so that
 * `themes.spec.ts` can read it without importing the config (which resolves
 * the preview port through `devports` at import time).
 */
export const SNAPSHOT_TAG = process.env.SNAPSHOT_TAG || "local";

/** `e2e/snapshots` — the config's `snapshotDir`, resolved absolutely. */
export const SNAPSHOT_ROOT = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "snapshots",
);

/**
 * Directory holding the current tag's baselines. `themes.spec.ts` skips the
 * screenshot comparison when it does not exist yet, because a tag that has
 * never been generated would otherwise have 144 baselines written by the very
 * run that is supposed to check them.
 */
export const SNAPSHOT_TAG_DIR = path.join(SNAPSHOT_ROOT, SNAPSHOT_TAG);

/** Has this tag's set of baselines ever been generated? */
export function haveBaselines(): boolean {
  return fs.existsSync(SNAPSHOT_TAG_DIR);
}

/** One line telling the reader how to produce the missing baselines. */
export function noBaselinesReason(sweepProject: string): string {
  const how =
    SNAPSHOT_TAG === "ci"
      ? "run the `Update screenshot baselines` workflow (Actions -> update-snapshots -> Run workflow) on this branch, then re-run CI"
      : "generate them with `cd e2e && SNAPSHOT_TAG=" +
        SNAPSHOT_TAG +
        " bunx playwright test themes.spec.ts --project=" +
        sweepProject +
        " --update-snapshots`";
  return (
    `no screenshot baselines for SNAPSHOT_TAG=${SNAPSHOT_TAG} ` +
    `(${SNAPSHOT_TAG_DIR} does not exist) — ${how}`
  );
}

/**
 * Print that line once, from `playwright.config.ts`. The config is evaluated
 * in the runner's main process exactly once, so the instruction lands at the
 * top of the run's output (and so in the CI log) instead of once per worker.
 * The per-test `test.skip` reason carries the same text into the report.
 */
export function warnIfNoBaselines(sweepProject: string): void {
  // Playwright re-imports the config in every worker; `TEST_WORKER_INDEX` is
  // set there and unset in the runner, so this stays one line per run.
  if (process.env.TEST_WORKER_INDEX !== undefined) return;
  if (!haveBaselines()) {
    console.warn(`[snapshots] ${noBaselinesReason(sweepProject)}`);
  }
}
