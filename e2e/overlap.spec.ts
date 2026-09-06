import { test, expect } from "./fixtures";
import { DEMOS, daisyClasses, open } from "./lib/daisy";
import { findOverlaps } from "./lib/browser";

/**
 * SPEC.md step 6, Tier C, row "overlap".
 *
 * "No two visible elements intersect unless one is an ancestor of the other or
 * both are inside the same `Stack`/`Grid` cell and the intersection is
 * zero-area." The class list comes from `fixtures/schema.json` at test time,
 * so the spec follows the generated schema instead of a copy of it.
 *
 * Exemptions, all of them structural rather than case-by-case:
 *
 *   - ancestor/descendant pairs (an element is always inside its parent);
 *   - an intersection under 1px on either axis — that is both the "same cell,
 *     zero-area" case and sub-pixel layout rounding;
 *   - hidden elements, which is what drops a closed drawer side (daisyUI
 *     paints it `invisible opacity-0`), an `aria-hidden` node, and a toast
 *     that is not currently in `Page.overlays`.
 *
 * The page is measured in its landing state: overlays that the application
 * has not opened are not on screen, and `layers.spec.ts` owns the open ones.
 */
const TOLERANCE_PX = 1;

for (const demo of DEMOS) {
  test(`${demo.name}: no two daisyUI elements overlap`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const hits = await page.evaluate(findOverlaps, {
      classes: daisyClasses(),
      tol: TOLERANCE_PX,
    });
    expect(
      hits.map(
        (h) =>
          `${h.a}  ><  ${h.b}  (overlap ${h.overlap.w.toFixed(1)}x${h.overlap.h.toFixed(1)}px)`,
      ),
    ).toEqual([]);
  });
}
