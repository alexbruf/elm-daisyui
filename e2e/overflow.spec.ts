import { test, expect } from "./fixtures";
import { DEMOS, daisyClasses, open } from "./lib/daisy";
import { findOverflows } from "./lib/browser";

/**
 * SPEC.md step 6, Tier C, row "overflow": "No element's box exceeds its scroll
 * container; no horizontal scrollbar on `body`."
 *
 * Three assertions:
 *
 *   1. the document does not scroll horizontally at any viewport;
 *   2. no daisyUI element has content wider than its own box, unless it is a
 *      container the composition deliberately made scrollable
 *      (`overflow-x: auto|scroll` — the renderer's `overflow-x-auto` table
 *      wrapper is the only one in these demos);
 *   3. no daisyUI element's rect escapes the nearest ancestor that clips
 *      horizontally.
 */
const TOLERANCE_PX = 1;

for (const demo of DEMOS) {
  test(`${demo.name}: nothing overflows its container`, async ({
    page,
    theme,
  }) => {
    await open(page, demo.path, theme);
    const r = await page.evaluate(findOverflows, {
      classes: daisyClasses(),
      tol: TOLERANCE_PX,
    });

    expect(
      {
        documentScrollWidth: r.documentScrollWidth,
        documentClientWidth: r.documentClientWidth,
      },
      "the document must not scroll horizontally",
    ).toEqual({
      documentScrollWidth: r.documentClientWidth,
      documentClientWidth: r.documentClientWidth,
    });
    expect(r.bodyScrollWidth, "body must not scroll horizontally").toBeLessThanOrEqual(
      r.bodyClientWidth + TOLERANCE_PX,
    );

    expect(
      r.scrolls.map(
        (s) => `${s.el} content ${s.scrollWidth}px in a ${s.clientWidth}px box`,
      ),
    ).toEqual([]);
    expect(
      r.escapes.map(
        (e) => `${e.el} escapes ${e.container} by ${e.by.toFixed(1)}px`,
      ),
    ).toEqual([]);
  });
}
