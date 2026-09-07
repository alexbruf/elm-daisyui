import { test, expect } from "./fixtures";
import { open } from "./lib/daisy";

/**
 * The theme generator page (`/theme`, `Demo.ThemeGenerator`).
 *
 * The claim under test is the one the whole custom-theme feature rests on:
 * **a theme that exists only as an Elm value, written onto the page root as
 * inline CSS custom properties, themes daisyUI's components exactly as a
 * stylesheet rule would.** Nothing in `demo/app.css` declares `acme`; if the
 * inline properties did not work, `--color-primary` would fall back to
 * daisyUI's default theme and every assertion below would read the wrong
 * colour.
 *
 * That is worth stating because it very nearly did not work.
 * `Html.Attributes.style "--color-primary" "..."` is a no-op: `elm/virtual-dom`
 * applies a style node with `element.style[key] = value`, and a
 * `CSSStyleDeclaration` ignores an assignment to a `--*` name — only
 * `setProperty` reaches it, and Elm never calls it. `Daisy.Render` therefore
 * writes one whole `style` **attribute** (`Daisy.Tree.customThemeStyle`), which
 * goes through `setAttribute` and is parsed as CSS. The first test below is
 * what would catch a regression back to the per-property form.
 *
 * The tests run in one project only. The page's behaviour is not
 * viewport-dependent (geometry is `overlap`/`overflow`/`responsive`' job and
 * colour is `contrast`'s), so running the same six assertions six times would
 * only slow the suite down.
 */
const PROJECT = "desktop-light";

const pane = /^last-msg: (\w+)$/;

/**
 * The exported CSS, which is the **last** `mockup-code` on the page: the
 * components demo carries one of its own (daisyUI's preview shows a terminal),
 * and the export band is the page's last section.
 */
function exportBlock(page: import("@playwright/test").Page) {
  return page.locator(".mockup-code").last();
}

/** daisyUI's `acme` — there is no such thing, which is the point. */
const CUSTOM = "acme";

test.beforeEach(async ({}, testInfo) => {
  test.skip(
    testInfo.project.name !== PROJECT,
    `the theme generator page is exercised once, in ${PROJECT}`,
  );
});

test("the page renders under a theme no stylesheet declares", async ({
  page,
}) => {
  await open(page, "/theme", CUSTOM);
  const root = page.locator("[data-theme]").first();
  await expect(root).toHaveAttribute("data-theme", CUSTOM);

  const painted = await root.evaluate((el) => {
    const style = getComputedStyle(el);
    return {
      // The twenty-nine declarations, spot-checked across all five kinds.
      primary: style.getPropertyValue("--color-primary").trim(),
      base100: style.getPropertyValue("--color-base-100").trim(),
      radiusBox: style.getPropertyValue("--radius-box").trim(),
      border: style.getPropertyValue("--border").trim(),
      depth: style.getPropertyValue("--depth").trim(),
      noise: style.getPropertyValue("--noise").trim(),
      colorScheme: style.colorScheme,
      // One `style` attribute, not twenty-nine style nodes: see the header.
      declarations: (el.getAttribute("style") ?? "").split(";").length,
    };
  });

  expect(painted, "Demo.Themes.acme reached the page root").toMatchObject({
    primary: "oklch(62% 0.265 303.9)",
    base100: "oklch(98% 0 0)",
    radiusBox: "0.5rem",
    border: "1px",
    depth: "0",
    noise: "0",
    colorScheme: "light",
  });
  expect(painted.declarations).toBe(29);

  // And the components read them. `--depth: 0` is the sharpest check of the
  // lot: daisyUI multiplies it into the button's box-shadow alphas, so a theme
  // that did not reach the page would paint a shadow here.
  const cta = page.getByRole("button", { name: "Copy CSS" });
  await expect(cta).toBeVisible();
  const cssOfCta = await cta.evaluate((el) => {
    const style = getComputedStyle(el);
    return { background: style.backgroundColor, shadow: style.boxShadow };
  });
  expect(cssOfCta.background).toBe("oklch(0.62 0.265 303.9)");
  expect(cssOfCta.shadow, "--depth: 0 makes every shadow alpha 0").not.toMatch(
    /0\.3\)/,
  );
});

test("a built-in can be opened as an editable theme of our own", async ({
  page,
}) => {
  // `?theme=nord` on `/theme` means "start the editor on nord's values". The
  // page still renders `acme`, so nothing daisyUI ships is painting it.
  await open(page, "/theme", "nord");
  const root = page.locator("[data-theme]").first();
  await expect(root).toHaveAttribute("data-theme", CUSTOM);
  await expect(root).toHaveAttribute("style", /--color-primary/);

  const primary = await root.evaluate((el) =>
    getComputedStyle(el).getPropertyValue("--color-primary").trim(),
  );
  // daisyUI's own nord.css, via the generated `Daisy.Themes.nord`.
  expect(primary).toBe("oklch(59.435% 0.077 254.027)");
});

test("changing the primary colour repaints the root, the CTA and the export", async ({
  page,
}) => {
  await open(page, "/theme", CUSTOM);
  const root = page.locator("[data-theme]").first();
  const cta = page.getByRole("button", { name: "Copy CSS" });

  const before = await root.evaluate((el) =>
    getComputedStyle(el).getPropertyValue("--color-primary").trim(),
  );
  expect(before).toBe("oklch(62% 0.265 303.9)");

  // The colour chips are one `Leaf.ColorChips`: painted 44x40 squares laid out
  // in daisyUI's own rows, each with a native `type="color"` picker lying over
  // it invisible. The picker's `aria-label` is the `--color-*` variable it
  // edits, which is the only name it has. A colour input cannot be typed into,
  // and `fill()` refuses it, so the value is set the way the picker would and
  // the `input` event is dispatched — which is the event `Daisy.Render` listens
  // for.
  const primaryInput = page.getByLabel("primary", { exact: true });
  await expect(primaryInput).toHaveAttribute("type", "color");
  // The square under it is painted from the theme, not by a class: a colour
  // being edited is not `--color-primary` yet, so no utility could paint it.
  const chip = primaryInput.locator("xpath=..");
  await expect
    .poll(() => chip.evaluate((el) => getComputedStyle(el).backgroundColor))
    .toBe("oklch(0.62 0.265 303.9)");
  await primaryInput.evaluate((el: HTMLInputElement) => {
    el.value = "#ff0000";
    el.dispatchEvent(new Event("input", { bubbles: true }));
  });

  await expect(page.getByText(pane)).toHaveText("last-msg: ThemeEdited");

  // sRGB red is oklch(62.79554% 0.25768 29.234) — Ottosson's worked example, and
  // what `Daisy.Color.hexToOklch` must produce for the theme to hold it. Five
  // decimals of lightness and chroma and three of hue, because four and two are
  // not enough to make `hex -> OKLCH -> hex` the identity: at high chroma a
  // hundredth of a degree is more than half an 8-bit channel step.
  await expect
    .poll(() =>
      root.evaluate((el) =>
        getComputedStyle(el).getPropertyValue("--color-primary").trim(),
      ),
    )
    .toBe("oklch(62.79554% 0.25768 29.234)");

  // The CTA follows, which is the `var(--color-primary)` half of the loop.
  await expect
    .poll(() => cta.evaluate((el) => getComputedStyle(el).backgroundColor))
    .toMatch(/^oklch\(0\.627955 0\.25768 29\.234/);

  // And so does the exported CSS.
  await expect(exportBlock(page)).toContainText(
    "--color-primary: oklch(62.79554% 0.25768 29.234);",
  );
});

test("the shape controls reach daisyUI's own measurements", async ({ page }) => {
  await open(page, "/theme", CUSTOM);
  const root = page.locator("[data-theme]").first();

  // The three radius controls are `Leaf.RadiusTiles`: a real radio group whose
  // five steps are *drawn* as the corner each one sets, which is what daisyUI's
  // own generator shows. The step's accessible name is the length prefixed by
  // the group, which is what keeps `2rem` in one control distinguishable from
  // `2rem` in the next; the visible content is a picture, not a word.
  // The radio itself is `sr-only` — the visible control is the tile in the
  // `<label>` around it, which is what a pointer hits and what a screen reader
  // announces through the radio's own name.
  const boxes2rem = page.getByRole("radio", { name: "Boxes 2rem" });
  const boxes2remStep = boxes2rem.locator("xpath=..");
  await boxes2remStep.click();
  await expect(boxes2rem).toBeChecked();
  await expect
    .poll(() =>
      root.evaluate((el) =>
        getComputedStyle(el).getPropertyValue("--radius-box").trim(),
      ),
    )
    .toBe("2rem");
  // The tile really is drawn at the radius it sets, from an inline declaration:
  // a `border-radius` out of a five-member set is not a utility.
  const tile = boxes2rem.locator("xpath=following-sibling::div[1]");
  await expect
    .poll(() => tile.evaluate((el) => getComputedStyle(el).borderStartEndRadius))
    .toBe("32px");
  // The chosen step is the marked one, and it is the only one in its group.
  // `btn-neutral`, not `btn-active`: `.btn-active`'s background is a
  // `color-mix()` the composition chose, which is 4.28:1 in `valentine`, while
  // `--color-neutral` / `--color-neutral-content` is a pair daisyUI declares in
  // every theme.
  await expect(boxes2remStep).toHaveClass(/btn-neutral/);
  const markedBoxSteps = await page
    .getByRole("radio", { name: /^Boxes / })
    .evaluateAll(
      (els) =>
        els.filter((el) =>
          el.parentElement!.classList.contains("btn-neutral"),
        ).length,
    );
  expect(markedBoxSteps, "one step of `Boxes` is marked").toBe(1);

  await page.getByRole("button", { name: "Border width 2px" }).click();
  await expect
    .poll(() =>
      root.evaluate((el) =>
        getComputedStyle(el).getPropertyValue("--border").trim(),
      ),
    )
    .toBe("2px");

  // The two effect switches are `--depth` / `--noise`, which daisyUI reads as
  // 0 or 1 inside `calc()`; a Bool in the tree, a digit in the CSS.
  await page.getByLabel("Depth effect").check();
  await page.getByLabel("Noise effect").check();
  await expect
    .poll(() =>
      root.evaluate((el) => {
        const style = getComputedStyle(el);
        return [
          style.getPropertyValue("--depth").trim(),
          style.getPropertyValue("--noise").trim(),
        ].join(",");
      }),
    )
    .toBe("1,1");

  await expect(exportBlock(page)).toContainText("--depth: 1;");
  await expect(exportBlock(page)).toContainText("--radius-box: 2rem;");
});

test("the generator link's hash decodes to daisyUI's own theme JSON", async ({
  page,
}) => {
  await open(page, "/theme", CUSTOM);

  const link = page.getByRole("link", {
    name: "Open in daisyUI theme generator",
  });
  await expect(link).toBeVisible();
  // The hash is produced by `CompressionStream`, which is asynchronous, so the
  // anchor starts on the bare generator URL and gains the theme a tick later.
  await expect
    .poll(() => link.getAttribute("href"))
    .toMatch(/^https:\/\/daisyui\.com\/theme-generator\/#theme=[\w-]+$/);

  const href = (await link.getAttribute("href"))!;
  const hash = href.split("#theme=")[1];

  // Inflate it back in the page, with the browser's own DecompressionStream:
  // `deflate` there is the zlib wrapper (RFC 1950), which is what daisyUI's
  // own hashes are — every one of them starts `eJx`, i.e. 0x78 0x9c.
  const decoded = await page.evaluate(async (encoded: string) => {
    const binary = atob(encoded.replace(/-/g, "+").replace(/_/g, "/"));
    const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
    const stream = new Blob([bytes])
      .stream()
      .pipeThrough(new DecompressionStream("deflate"));
    return await new Response(stream).text();
  }, hash);

  // Byte for byte the shape daisyUI's generator round-trips: `name`,
  // `color-scheme`, the twenty-nine declarations in daisyUI's order, then
  // `default` and `prefersdark`. Checked against a hash the live generator
  // produced for its own `light` theme.
  expect(JSON.parse(decoded)).toEqual({
    name: "acme",
    "color-scheme": "light",
    "--color-base-100": "oklch(98% 0 0)",
    "--color-base-200": "oklch(97% 0 0)",
    "--color-base-300": "oklch(92% 0 0)",
    "--color-base-content": "oklch(20% 0 0)",
    "--color-primary": "oklch(62% 0.265 303.9)",
    "--color-primary-content": "oklch(98% 0.031 120.757)",
    "--color-secondary": "oklch(76% 0.188 70.08)",
    "--color-secondary-content": "oklch(98% 0.022 95.277)",
    "--color-accent": "oklch(71% 0.203 305.504)",
    "--color-accent-content": "oklch(98% 0.031 120.757)",
    "--color-neutral": "oklch(20% 0 0)",
    "--color-neutral-content": "oklch(98% 0 0)",
    "--color-info": "oklch(58% 0.158 241.966)",
    "--color-info-content": "oklch(97% 0.013 236.62)",
    "--color-success": "oklch(62% 0.194 149.214)",
    "--color-success-content": "oklch(98% 0.018 155.826)",
    "--color-warning": "oklch(64% 0.222 41.116)",
    "--color-warning-content": "oklch(98% 0.016 73.684)",
    "--color-error": "oklch(57% 0.245 27.325)",
    "--color-error-content": "oklch(97% 0.013 17.38)",
    "--radius-selector": "0.25rem",
    "--radius-field": "0.25rem",
    "--radius-box": "0.5rem",
    "--size-selector": "0.25rem",
    "--size-field": "0.25rem",
    "--border": "1px",
    "--depth": "0",
    "--noise": "0",
    default: false,
    prefersdark: false,
  });

  // The key order is part of the contract, not just the key set.
  expect(Object.keys(JSON.parse(decoded)).slice(0, 3)).toEqual([
    "name",
    "color-scheme",
    "--color-base-100",
  ]);
});

test("the palette shows every theme surface with its content colour on it", async ({
  page,
}) => {
  await open(page, "/theme", CUSTOM);

  // `Leaf.Swatch` emits no daisyUI class at all — the chip is
  // `Daisy.Render`'s own box, painted from one named token pair per
  // `SwatchColor`. Those eighteen tokens are the only *colour* utilities in
  // `Daisy.Render.tokens`, and `bg-primary` is on `tests/RenderPurityTest.elm`'s
  // `forbidden` list no longer precisely because it became one of them, so
  // finding the chip by that class is the point rather than a shortcut.
  const surfaces = [
    "bg-base-100",
    "bg-base-200",
    "bg-base-300",
    "bg-primary",
    "bg-secondary",
    "bg-accent",
    "bg-neutral",
    "bg-info",
    "bg-success",
    "bg-warning",
    "bg-error",
  ];
  const palette = page.locator(".card", { hasText: "Palette" }).first();
  for (const surface of surfaces) {
    await expect(palette.locator(`.${surface}`)).toHaveCount(1);
  }

  const primarySwatch = palette.locator(".bg-primary");
  await expect(primarySwatch).toHaveText("primary");
  const paint = await primarySwatch.evaluate((el) => {
    const style = getComputedStyle(el);
    return { bg: style.backgroundColor, fg: style.color };
  });
  // The surface is the theme's `--color-primary`, and the text on it is the
  // `--color-primary-content` daisyUI pairs with it — both from the inline
  // properties, neither named by the caller.
  expect(paint.bg).toBe("oklch(0.62 0.265 303.9)");
  expect(paint.fg).toBe("oklch(0.98 0.031 120.757)");
});

test("Copy CSS fires its msg and the export block is the exported theme", async ({
  page,
}) => {
  await open(page, "/theme", CUSTOM);

  await expect(page.getByText(pane)).toHaveText("last-msg: none");
  await page.getByRole("button", { name: "Copy CSS" }).click();
  await expect(page.getByText(pane)).toHaveText("last-msg: ThemeExported");

  const css = await exportBlock(page).innerText();
  expect(css).toContain('@plugin "daisyui/theme" {');
  expect(css).toContain('name: "acme";');
  expect(css).toContain("--color-primary: oklch(62% 0.265 303.9);");
  expect(css).toContain("--noise: 0;");
  // The block daisyUI documents: the four keys plus the twenty-nine
  // declarations, in one `@plugin` body.
  expect(css.split("\n").filter((line) => line.trim() !== "")).toHaveLength(34);
});

test("the theme list loads a built-in, and Randomize replaces it", async ({
  page,
}) => {
  await open(page, "/theme", CUSTOM);
  const root = page.locator("[data-theme]").first();
  const primary = () =>
    root.evaluate((el) =>
      getComputedStyle(el).getPropertyValue("--color-primary").trim(),
    );

  // daisyUI's generator has no "start from" select: its left rail lists every
  // theme and clicking one loads it. That rail is a `Block.Menu`, so the rows
  // are buttons (a `MenuItem` with an `onClick` and no `href` is a `<button>`,
  // see `Daisy.Render.clickableHtml`), and the loaded one is marked.
  const rail = page.locator(".menu").first();
  const marked = () =>
    rail.locator("li > .bg-base-200").first().innerText();

  // `acme` is marked, because `acme`'s declarations are not any built-in's.
  // It is derived from the theme, not remembered — see
  // `Demo.ThemeGenerator.startingPoint`.
  expect((await marked()).trim()).toBe("acme");

  await rail.getByRole("button", { name: "nord", exact: true }).click();
  await expect(page.getByText(pane)).toHaveText("last-msg: ThemeEdited");
  // daisyUI's own nord.css, through the generated `Daisy.Themes.nord`.
  await expect.poll(primary).toBe("oklch(59.435% 0.077 254.027)");
  // And now the rail says so, because the theme still *is* nord's values.
  await expect.poll(async () => (await marked()).trim()).toBe("nord");

  // Randomize is a deterministic LCG over a counter the router keeps, so the
  // sequence is reproducible and the screenshot baselines stay byte-stable —
  // but each click really does move.
  const seen = new Set<string>();
  for (let i = 0; i < 3; i++) {
    await page.getByRole("button", { name: "Random" }).click();
    await expect(page.getByText(pane)).toHaveText("last-msg: ThemeEdited");
    seen.add(await primary());
  }
  expect(seen.size, "three clicks give three different palettes").toBe(3);
  // A randomised theme is nobody's built-in any more.
  await expect.poll(async () => (await marked()).trim()).toBe("acme");
});

test("an edited theme survives navigation to another demo", async ({ page }) => {
  await open(page, "/theme", CUSTOM);

  await page.getByRole("radio", { name: "Boxes 2rem" }).locator("xpath=..").click();
  await expect(page.getByText(pane)).toHaveText("last-msg: ThemeEdited");

  await page.getByRole("link", { name: "Overview" }).click();
  await expect(page.getByRole("heading", { name: "Business Overview" })).toBeVisible();

  // `Model.theme` is shared across the routes, so the dashboard is drawn under
  // the theme the generator was left on.
  const root = page.locator("[data-theme]").first();
  await expect(root).toHaveAttribute("data-theme", CUSTOM);
  await expect
    .poll(() =>
      root.evaluate((el) =>
        getComputedStyle(el).getPropertyValue("--radius-box").trim(),
      ),
    )
    .toBe("2rem");
});
