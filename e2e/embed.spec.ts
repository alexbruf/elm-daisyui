import { test, expect } from "./fixtures";
import { daisyClasses, open } from "./lib/daisy";

/**
 * `Daisy.Tree.Leaf.Embed` — the one place a caller's own `Html` reaches the
 * page (`docs/tree-decisions.md`, "Embed").
 *
 * An embed is opaque to every check that reads classes back off the markup:
 * `CoverageTest`, the corpus and `render-class-audit` all see a box with
 * nothing in it. What is *not* opaque is what the browser paints, so the
 * guarantees an embed still has to keep are the ones this file measures, on
 * the real page:
 *
 *   1. **It follows the theme.** The demo's funnel (`demo/src/Viz/Funnel.elm`)
 *      paints itself with the `var(--color-*)` strings
 *      `Daisy.Tree.ThemeContext` hands it, so its bands' computed `fill` must
 *      equal the theme's own `--color-primary` / `--color-secondary` /
 *      `--color-accent`. Checked in four themes including `acme`, the demo's
 *      `Theme.Custom`, whose variables exist only as inline properties on the
 *      page root — so this also proves an embed reaches a theme no stylesheet
 *      declares. `themes.spec.ts`'s sweep covers the same fills in all 36
 *      themes, because it reads every `svg *` with a `var(--color-*)`
 *      stroke/fill and the funnel is now among them; this file is the narrow,
 *      fast statement of the same claim plus the box invariants below.
 *   2. **It is boxed.** Fixed height (`EmbedMd` = 256px), `overflow: hidden`,
 *      `position: relative`, full width. Nothing the embed draws may leave
 *      that rectangle, which is what stops a custom view from overlapping the
 *      block under it — the guarantee the tree cannot make by typing.
 *   3. **It announces itself.** `role="figure"` with the config's label as
 *      `aria-label`, because nothing else on the page can name what was drawn.
 *   4. **It carries no daisyUI class.** `NoClassOutsideRender` forbids the
 *      `class` attribute inside an embed statically; this is the same claim
 *      measured on the painted page, so a class that arrived some other way
 *      (a copied `Html.Attributes.attribute`, a library) would still be
 *      caught.
 */

const FUNNEL = '[role="figure"][aria-label="Conversion funnel"]';

/** Light, dark, a heavily-tinted built-in, and the demo's own custom theme. */
const THEMES = ["light", "dark", "nord", "acme"] as const;

/** Which `ThemeContext.color` each band of the funnel asked for, in order. */
const BAND_TOKENS = [
  "--color-primary",
  "--color-secondary",
  "--color-accent",
] as const;

test.describe("Leaf.Embed on /analytics", () => {
  for (const themeName of THEMES) {
    test(`the funnel's bands are the theme's own colours in ${themeName}`, async ({
      page,
    }) => {
      await open(page, "/analytics", themeName);
      const result = await page.evaluate((selector) => {
        const cv = document.createElement("canvas");
        cv.width = cv.height = 1;
        const ctx = cv.getContext("2d", { willReadFrequently: true })!;
        const rgb = (color: string): number[] | null => {
          if (!color || color === "none") return null;
          ctx.clearRect(0, 0, 1, 1);
          ctx.fillStyle = "#000000";
          ctx.fillStyle = color;
          ctx.fillRect(0, 0, 1, 1);
          const d = ctx.getImageData(0, 0, 1, 1).data;
          return [d[0], d[1], d[2]];
        };
        const box = document.querySelector(selector);
        if (!box) return { theme: null, bands: [] as unknown[] };
        const root =
          document.querySelector("[data-theme]") ?? document.documentElement;
        const rootStyle = getComputedStyle(root);
        const bands = [...box.querySelectorAll("path")]
          .map((el) => ({
            token: (el.getAttribute("fill") ?? "").slice(4, -1).trim(),
            raw: el.getAttribute("fill"),
            computed: rgb(getComputedStyle(el).fill),
          }))
          .filter((row) => (row.raw ?? "").startsWith("var(--color-"))
          .map((row) => ({
            ...row,
            expected: rgb(rootStyle.getPropertyValue(row.token).trim()),
          }));
        return { theme: root.getAttribute("data-theme"), bands };
      }, FUNNEL);

      expect(result.theme, "the page root carries the requested theme").toBe(
        themeName,
      );
      expect(
        result.bands.map((b) => b.token),
        "the three bands ask for primary, secondary and accent",
      ).toEqual([...BAND_TOKENS]);
      for (const band of result.bands) {
        expect(band.computed, `${band.token} resolves to a colour`).not.toBeNull();
        expect(band.expected, `${band.token} is defined by the theme`).not.toBeNull();
        expect(
          band.computed!.every(
            (v, i) => Math.abs(v - band.expected![i]) <= 1,
          ),
          `${themeName}: fill=${band.raw} computed ${band.computed} != ${band.token} ${band.expected}`,
        ).toBe(true);
      }
    });
  }

  test("the renderer's box clips the embed and cannot be escaped", async ({
    page,
    theme,
  }) => {
    await open(page, "/analytics", theme);
    const geometry = await page.evaluate((selector) => {
      const box = document.querySelector(selector);
      if (!box) return null;
      const s = getComputedStyle(box);
      const b = box.getBoundingClientRect();
      let worst = 0;
      for (const el of box.querySelectorAll("*")) {
        const r = el.getBoundingClientRect();
        if (r.width < 0.5 && r.height < 0.5) continue;
        worst = Math.max(
          worst,
          b.left - r.left,
          r.right - b.right,
          b.top - r.top,
          r.bottom - b.bottom,
        );
      }
      return {
        height: s.height,
        overflow: s.overflow,
        position: s.position,
        rect: { w: b.width, h: b.height },
        worstEscape: worst,
        role: box.getAttribute("role"),
        label: box.getAttribute("aria-label"),
      };
    }, FUNNEL);

    expect(geometry, "the analytics page renders the funnel embed").not.toBeNull();
    // `EmbedMd` is `h-64`, 16rem at the demo's 16px root.
    expect(geometry!.height).toBe("256px");
    expect(geometry!.rect.h).toBeCloseTo(256, 1);
    expect(geometry!.overflow).toBe("hidden");
    expect(geometry!.position).toBe("relative");
    expect(geometry!.role).toBe("figure");
    expect(geometry!.label).toBe("Conversion funnel");
    // Sub-pixel layout rounding only: nothing the embed drew is outside the
    // box the renderer gave it.
    expect(geometry!.worstEscape).toBeLessThanOrEqual(1);
  });

  test("nothing inside the embed carries a daisyUI class", async ({
    page,
    theme,
  }) => {
    await open(page, "/analytics", theme);
    const found = await page.evaluate(
      ({ selector, classes }) => {
        const box = document.querySelector(selector);
        if (!box) return ["the funnel embed is not on the page"];
        const daisy = new Set(classes);
        const hits: string[] = [];
        for (const el of box.querySelectorAll("*")) {
          const raw =
            typeof el.className === "string"
              ? el.className
              : (el.getAttribute("class") ?? "");
          for (const cls of raw.split(/\s+/)) {
            if (cls && daisy.has(cls)) {
              hits.push(`<${el.tagName.toLowerCase()}> carries ${cls}`);
            }
          }
        }
        return hits;
      },
      { selector: FUNNEL, classes: daisyClasses() },
    );
    expect(found).toEqual([]);
  });
});
