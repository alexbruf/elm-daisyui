import { test, expect } from "./fixtures";

/**
 * The package's own stylesheet (`Daisy.Css` -> `tools/gen-daisy-css.js` ->
 * `demo/daisy-motion.css`), and the one guarantee it has to make: **every rule
 * in it is inside `@media (prefers-reduced-motion: no-preference)`.**
 *
 * That matters twice over. It is the accessibility promise — a reader who has
 * asked for less motion gets the plain, undecorated page rather than an
 * animation that was turned off afterwards. And it is what keeps the rest of
 * this suite deterministic: `lib/daisy.ts`'s `open()` emulates
 * `reducedMotion: "reduce"`, so the 144 theme baselines photograph a page with
 * no animation in it at all.
 *
 * These tests therefore do **not** go through `open()` — they are the one place
 * that has to control the media query itself, and the one place that must not
 * have `open()`'s "kill every animation" stylesheet injected.
 *
 * They run in one project. Whether an animation exists is not a function of the
 * viewport or the theme.
 */
const PROJECT = "desktop-light";

/** The bar group elm-charts draws, which `daisy-anim-bars` grows from its baseline. */
const BAR_SERIES = ".elm-charts__bar-series";

test.beforeEach(async ({}, testInfo) => {
  test.skip(
    testInfo.project.name !== PROJECT,
    `the motion stylesheet is exercised once, in ${PROJECT}`,
  );
});

/** How many animations the browser has attached to the chart's bar groups. */
async function barAnimations(page: import("@playwright/test").Page) {
  return page.evaluate(
    (selector) =>
      [...document.querySelectorAll(selector)].map(
        (el) => el.getAnimations().length,
      ),
    BAR_SERIES,
  );
}

test("with motion allowed, the bar group is animated", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.goto("/?theme=light", { waitUntil: "load" });
  await page.locator("text=/^last-msg: /").first().waitFor({ state: "visible" });
  await page.locator(BAR_SERIES).first().waitFor();

  // `animation-fill-mode: both`, so the animation stays attached after it
  // finishes: this reads the same whether the assertion lands during the
  // 0.55s run or after it, which is what makes it not a race.
  const counts = await barAnimations(page);
  expect(counts.length, "the revenue chart draws two stacked series").toBe(2);
  expect(counts.every((n) => n > 0), `bar groups animated: ${counts}`).toBe(true);

  // And it is the rule from `Daisy.Css`, not some other one.
  const names = await page.evaluate(
    (selector) =>
      [...document.querySelectorAll(selector)].flatMap((el) =>
        el.getAnimations().map((a) => (a as CSSAnimation).animationName),
      ),
    BAR_SERIES,
  );
  expect(new Set(names)).toEqual(new Set(["daisy-bar-grow"]));
});

test("with reduced motion, nothing is animated", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/?theme=light", { waitUntil: "load" });
  await page.locator("text=/^last-msg: /").first().waitFor({ state: "visible" });
  await page.locator(BAR_SERIES).first().waitFor();

  const counts = await barAnimations(page);
  expect(counts.length).toBe(2);
  expect(counts.every((n) => n === 0), `bar groups animated: ${counts}`).toBe(
    true,
  );

  // Nothing anywhere on the page, not just the bars — the whole stylesheet is
  // inside the one media query.
  const anyAnimation = await page.evaluate(() =>
    document.getAnimations().length,
  );
  expect(anyAnimation).toBe(0);
});

test("switching the dataset replays the animation", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.goto("/?theme=light", { waitUntil: "load" });
  await page.locator("text=/^last-msg: /").first().waitFor({ state: "visible" });

  const chart = page.locator(".card", { hasText: "Revenue Statistics" }).first();
  await chart.locator(BAR_SERIES).first().waitFor();

  // Let the entry animation finish, so a still-running one cannot be mistaken
  // for a replayed one.
  await expect
    .poll(() =>
      page.evaluate(
        (selector) =>
          [...document.querySelectorAll(selector)].every((el) =>
            el.getAnimations().every((a) => a.playState === "finished"),
          ),
        BAR_SERIES,
      ),
    )
    .toBe(true);

  await chart.getByRole("tab", { name: "Month" }).click();

  // `Daisy.Render` keys the drawing by the dataset (`Html.Keyed`), so a new
  // dataset **remounts** the SVG rather than diffing it — and a CSS animation
  // runs when its element is created. A diffed chart would keep the finished
  // animation above and this would still be `finished`.
  await expect
    .poll(() =>
      page.evaluate(
        (selector) =>
          [...document.querySelectorAll(selector)].some((el) =>
            el.getAnimations().some((a) => a.playState === "running"),
          ),
        BAR_SERIES,
      ),
    )
    .toBe(true);
});
