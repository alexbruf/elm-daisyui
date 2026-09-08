/**
 * Browser-side collectors. Every export is passed whole to `page.evaluate`,
 * so each one must be self-contained: no imports, no references to module
 * scope, all helpers declared inside the function body.
 */

export type Box = {
  index: number;
  path: string;
  rect: { x: number; y: number; w: number; h: number };
  depth: number;
};

export type OverlapHit = {
  a: string;
  b: string;
  rectA: Box["rect"];
  rectB: Box["rect"];
  overlap: { w: number; h: number };
};

/**
 * Pairwise `getBoundingClientRect` overlap over every element carrying a
 * daisyUI class. Hidden elements are dropped first (`display:none`,
 * `visibility:hidden|collapse`, `opacity:0`, zero area, `aria-hidden`,
 * `inert`) — which is also what removes a closed drawer side (daisyUI paints
 * it `invisible opacity-0`) and a toast that is not on the page.
 *
 * Ancestor/descendant pairs are exempt by definition, and so is any pair whose
 * intersection is under `tol` on either axis: that is the "same Grid/Stack
 * cell, zero-area intersection" case, plus sub-pixel layout rounding.
 *
 * One structural exemption beyond those: a daisyUI `indicator-item` and its
 * siblings inside the same `.indicator`. Overlapping is that part's entire
 * definition - daisyUI positions it `absolute` and translates it 50% onto the
 * corner of the element it annotates, which is what a notification count on a
 * bell button *is*. It is scoped to one `.indicator` subtree, so an
 * `indicator-item` still may not overlap anything else on the page.
 */
export function findOverlaps(input: { classes: string[]; tol: number }) {
  const { classes, tol } = input;
  const selector = classes.map((c) => "." + CSS.escape(c)).join(",");

  function indicatorPair(a: Element, b: Element): boolean {
    const annotates = (item: Element, other: Element) => {
      if (!item.classList.contains("indicator-item")) return false;
      const box = item.closest(".indicator");
      return !!box && box.contains(other);
    };
    return annotates(a, b) || annotates(b, a);
  }

  function visible(el: Element): boolean {
    for (let n: Element | null = el; n; n = n.parentElement) {
      const s = getComputedStyle(n);
      if (s.display === "none") return false;
      if (s.visibility === "hidden" || s.visibility === "collapse") return false;
      if (parseFloat(s.opacity) === 0) return false;
      if (n.getAttribute("aria-hidden") === "true") return false;
      if (n.hasAttribute("inert")) return false;
      if (s.contentVisibility === "hidden") return false;
    }
    const r = el.getBoundingClientRect();
    return r.width > 0.5 && r.height > 0.5;
  }

  function label(el: Element): string {
    const bits: string[] = [];
    for (let n: Element | null = el; n && bits.length < 3; n = n.parentElement) {
      const cls =
        typeof n.className === "string" && n.className.trim()
          ? "." + n.className.trim().split(/\s+/).join(".")
          : "";
      bits.unshift(n.tagName.toLowerCase() + cls);
    }
    return bits.join(" > ");
  }

  const els = [...document.querySelectorAll(selector)].filter(visible);
  const hits: OverlapHit[] = [];
  for (let i = 0; i < els.length; i++) {
    const a = els[i];
    const ra = a.getBoundingClientRect();
    for (let j = i + 1; j < els.length; j++) {
      const b = els[j];
      if (a.contains(b) || b.contains(a)) continue;
      if (indicatorPair(a, b)) continue;
      const rb = b.getBoundingClientRect();
      const w = Math.min(ra.right, rb.right) - Math.max(ra.left, rb.left);
      const h = Math.min(ra.bottom, rb.bottom) - Math.max(ra.top, rb.top);
      if (w > tol && h > tol) {
        hits.push({
          a: label(a),
          b: label(b),
          rectA: { x: ra.x, y: ra.y, w: ra.width, h: ra.height },
          rectB: { x: rb.x, y: rb.y, w: rb.width, h: rb.height },
          overlap: { w, h },
        });
      }
    }
  }
  return hits;
}

/**
 * Overflow: nothing spills out of a box that is not deliberately scrollable,
 * and no element's rect escapes its nearest clipping ancestor.
 * `overflow-x: auto|scroll` marks a container the composition means to scroll
 * (the renderer's `overflow-x-auto` table wrapper is the only one), so those
 * are the exception and everything else must fit.
 */
export function findOverflows(input: { classes: string[]; tol: number }) {
  const { classes, tol } = input;
  const selector = classes.map((c) => "." + CSS.escape(c)).join(",");

  function visible(el: Element): boolean {
    for (let n: Element | null = el; n; n = n.parentElement) {
      const s = getComputedStyle(n);
      if (s.display === "none") return false;
      if (s.visibility === "hidden" || s.visibility === "collapse") return false;
      if (parseFloat(s.opacity) === 0) return false;
      if (n.getAttribute("aria-hidden") === "true") return false;
    }
    const r = el.getBoundingClientRect();
    return r.width > 0.5 && r.height > 0.5;
  }

  function label(el: Element): string {
    const cls =
      typeof el.className === "string" && el.className.trim()
        ? "." + el.className.trim().split(/\s+/).join(".")
        : "";
    return el.tagName.toLowerCase() + cls;
  }

  const scrolls: { el: string; scrollWidth: number; clientWidth: number }[] = [];
  const escapes: { el: string; container: string; by: number }[] = [];

  for (const el of document.querySelectorAll(selector)) {
    if (!visible(el)) continue;
    const s = getComputedStyle(el);
    const scrollable = s.overflowX === "auto" || s.overflowX === "scroll";
    // An `.indicator` is a box whose `indicator-item` child is placed outside
    // it on purpose (`position: absolute` plus a 50% translate onto the
    // corner), so its scrollWidth is always wider than its clientWidth. That
    // is the component's definition, not an overflow.
    const indicatorBox = el.classList.contains("indicator");
    // ...and the same fact one level up. A box that *contains* an
    // `.indicator` inherits that overhang in its own `scrollWidth`: at 375 the
    // notification badge on the last control of a wrapped `navbar-end` is 10px
    // past that half's content edge. It is not an overflow either — nothing is
    // clipped (the box does not clip), nothing overlaps (`overlap.spec.ts`
    // owns that), the document does not scroll (asserted separately), and the
    // badge lands inside the navbar's own `p-4` gutter.
    //
    // Scoped as tightly as the fact allows: the box must not clip, and the
    // excess must be no more than the furthest an `indicator-item` inside it
    // reaches past its content edge. One pixel more and it is reported.
    const indicatorOverhang = (box: Element): number => {
      const right = box.getBoundingClientRect().right;
      let max = 0;
      for (const item of box.querySelectorAll(".indicator-item")) {
        max = Math.max(max, item.getBoundingClientRect().right - right);
      }
      return max;
    };
    const excess = el.scrollWidth - el.clientWidth;
    const fromIndicator =
      !indicatorBox && excess > tol && excess <= indicatorOverhang(el) + tol;
    if (
      !scrollable &&
      !indicatorBox &&
      !fromIndicator &&
      el.scrollWidth > el.clientWidth + tol &&
      el.clientWidth > 0
    ) {
      scrolls.push({
        el: label(el),
        scrollWidth: el.scrollWidth,
        clientWidth: el.clientWidth,
      });
    }

    // Nearest ancestor that clips horizontally: the element's rect must sit
    // inside it (a scrollable ancestor is allowed to be scrolled instead).
    let clipper: Element | null = null;
    for (let n = el.parentElement; n; n = n.parentElement) {
      const cs = getComputedStyle(n);
      if (cs.overflowX === "hidden" || cs.overflowX === "clip") {
        clipper = n;
        break;
      }
      if (cs.overflowX === "auto" || cs.overflowX === "scroll") break;
    }
    if (clipper) {
      const r = el.getBoundingClientRect();
      const c = clipper.getBoundingClientRect();
      const by = Math.max(c.left - r.left, r.right - c.right);
      if (by > tol) escapes.push({ el: label(el), container: label(clipper), by });
    }
  }

  const doc = document.documentElement;
  return {
    scrolls,
    escapes,
    documentScrollWidth: doc.scrollWidth,
    documentClientWidth: doc.clientWidth,
    bodyScrollWidth: document.body.scrollWidth,
    bodyClientWidth: document.body.clientWidth,
  };
}

export type ContrastHit = {
  text: string;
  selector: string;
  color: string;
  fontSize: number;
  ratio: number;
  fg: number[];
  bg: number[];
  /** true when both colours are a pair daisyUI's own theme defines. */
  daisyPalettePair: boolean;
  pairing: string;
};

/**
 * WCAG 2.x contrast for every visible text node, against the background that
 * is actually painted behind it.
 *
 * Colours are resolved by *painting* them: every value goes through a 1x1
 * canvas, so whatever syntax Chrome 146 hands back — `rgb()`, `rgba()`,
 * `color(srgb ...)`, `oklch(...)` — comes out as sRGB bytes with alpha
 * composited exactly as the browser composites it. The background is the whole
 * ancestor chain painted outermost-first over white, which is what "the first
 * non-transparent background-color up the tree" means once translucent layers
 * are involved.
 *
 * Each failure is classified: `daisyPalettePair` is true when the pair is one
 * daisyUI's own themes define — a `--color-X` background under its
 * `--color-X-content` foreground, a translucent `--color-base-content`
 * de-emphasis (`.stat-title`, `.stat-desc`, `.label`, `.menu-title`, table
 * headers), the "soft" pattern (`--color-X` as the *foreground* over a
 * `color-mix()` of the same `--color-X` with `--color-base-100`, which is how
 * daisyUI paints `.badge-soft`, `.btn-soft` and `.alert-soft`), or
 * `--color-base-content` over `--color-base-300` — a surface the renderer's
 * token table cannot paint, so both sides came from a daisyUI component rule
 * (`.chat-bubble`), or one of daisyUI's three *style variants*
 * (`*-outline`, `*-dash`, `*-soft`: `var(--color-X)` as the foreground over a
 * base surface, decided from the class-name shape and nothing else — see
 * `styleVariantOf`). Those pairs are what daisyUI's `contrast.test.js` owns; a
 * failure outside them is ours.
 */
export function collectContrast(): ContrastHit[] {
  const cv = document.createElement("canvas");
  cv.width = cv.height = 1;
  const ctx = cv.getContext("2d", { willReadFrequently: true })!;

  function paint(colors: string[], backdrop: string): number[] {
    ctx.clearRect(0, 0, 1, 1);
    ctx.fillStyle = backdrop;
    ctx.fillRect(0, 0, 1, 1);
    for (const c of colors) {
      ctx.fillStyle = "#000000";
      ctx.fillStyle = c; // an unparsable value leaves the previous one in place
      ctx.fillRect(0, 0, 1, 1);
    }
    const d = ctx.getImageData(0, 0, 1, 1).data;
    return [d[0], d[1], d[2]];
  }
  function over(colors: string[]): number[] {
    return paint(colors, "#ffffff");
  }
  function alphaOf(color: string): number {
    const w = paint([color], "#ffffff");
    const b = paint([color], "#000000");
    return 1 - (w[0] - b[0]) / 255;
  }
  /**
   * The opaque colour behind a translucent one: paint it over black (which
   * premultiplies it) and divide the alpha back out.
   *
   * The division amplifies the canvas's 8-bit rounding by `1 / alpha` — at
   * `alpha = 0.4` a one-unit rounding becomes 2.5 — and a channel that was
   * already at the top of the gamut then lands *above* 255. `.menu-title` is
   * `--color-base-content` at 40%, and in `dark` its blue channel came back as
   * 267.5 against a stored 255, which is why the result is clamped: an sRGB
   * colour the canvas composited cannot be outside [0, 255], so anything
   * outside it is reconstruction error and nothing else.
   */
  function opaqueOf(color: string): number[] | null {
    const a = alphaOf(color);
    if (a < 0.02) return null;
    const b = paint([color], "#000000");
    const clamp = (v: number) => Math.min(255, Math.max(0, v / a));
    return [clamp(b[0]), clamp(b[1]), clamp(b[2])];
  }
  function near(a: number[] | null, b: number[] | null, tol: number): boolean {
    if (!a || !b) return false;
    return (
      Math.abs(a[0] - b[0]) <= tol &&
      Math.abs(a[1] - b[1]) <= tol &&
      Math.abs(a[2] - b[2]) <= tol
    );
  }
  function lum(c: number[]): number {
    const f = (v: number) => {
      v /= 255;
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]);
  }
  function ratio(a: number[], b: number[]): number {
    const x = lum(a);
    const y = lum(b);
    const hi = Math.max(x, y);
    const lo = Math.min(x, y);
    return (hi + 0.05) / (lo + 0.05);
  }

  const root =
    document.querySelector("[data-theme]") ?? document.documentElement;
  const rootStyle = getComputedStyle(root);
  const NAMES = [
    "primary", "secondary", "accent", "neutral",
    "info", "success", "warning", "error",
  ];
  const pairs = NAMES.map((n) => ({
    name: n,
    bg: opaqueOf(rootStyle.getPropertyValue("--color-" + n).trim()),
    fg: opaqueOf(rootStyle.getPropertyValue("--color-" + n + "-content").trim()),
  })).filter((p) => p.bg && p.fg);
  const baseContent = opaqueOf(
    rootStyle.getPropertyValue("--color-base-content").trim(),
  );

  /**
   * daisyUI's `*-soft` recipe, painted rather than parsed: the background is
   * `color-mix(in oklab, var(--color-X) 8%, var(--color-base-100))` and the
   * foreground is `var(--color-X)` itself. Mixing it here through the same 1x1
   * canvas means the comparison survives whatever colour space Chrome hands
   * back, exactly like every other colour in this file.
   *
   * The two mix ratios daisyUI uses are 8% (`badge-soft`, `btn-soft`) and 10%
   * (their border), so both are accepted.
   */
  /**
   * `--color-base-300`: a surface `Daisy.Render.tokens` cannot paint.
   *
   * The renderer's whole surface vocabulary is `bg-base-100` (panels) and
   * `bg-base-200` (the content ground); `bg-base-300` is not a token and never
   * will be one, so every base-300 background on the page was painted by a
   * daisyUI component rule — `.chat-bubble` is the one the demos reach. When
   * daisyUI also picks the foreground (`.chat-bubble` sets
   * `color: var(--color-base-content)` in the same declaration), both sides of
   * the pair are daisyUI's, exactly as they are for `--color-X` /
   * `--color-X-content`, and the pair belongs to daisyUI's own contrast tests.
   *
   * Deliberately *not* extended to base-100 or base-200: those are the
   * surfaces the composition itself chooses, so base-content over either of
   * them is the pairing this spec exists to check.
   */
  const base300 = opaqueOf(rootStyle.getPropertyValue("--color-base-300").trim());

  /**
   * daisyUI's three *style variants* — `*-outline`, `*-dash`, `*-soft` — as one
   * mechanical rule rather than a list of components.
   *
   * All three paint the same pair: `color: var(--color-X)` on a surface the
   * component does not paint at all (`-outline` and `-dash` are transparent
   * over whatever is behind them; `-soft` adds an 8% `color-mix()` of the same
   * colour). The rule that picks both sides is daisyUI's own
   * (`.alert-outline { color: var(--color-X) }`), exactly as `.alert-info`'s
   * `--color-info-content` over `--color-info` is, so the pair belongs to
   * daisyUI's `contrast.test.js` and not to this spec.
   *
   * It is decided from three things, all of them mechanical:
   *
   *   1. the element (or the nearest ancestor that has one) carries a class
   *      matching `<component>-outline|dash|soft` — a name shape, never a
   *      selector list;
   *   2. its foreground is *exactly* one of the theme's `--color-X`;
   *   3. its background is one of the three base surfaces, or the `-soft` mix
   *      of that same X (the `softBackgrounds` table below).
   *
   * A `-content` colour over the wrong surface, a colour the composition mixed
   * itself, or an ordinary element that merely sits on base-100 still fails.
   */
  const VARIANT = /^[a-z][a-z0-9]*-(outline|dash|soft)$/;
  function styleVariantOf(el: Element): string | null {
    for (let n: Element | null = el; n; n = n.parentElement) {
      const list = n.classList;
      if (!list) continue;
      for (const c of Array.from(list)) if (VARIANT.test(c)) return c;
    }
    return null;
  }
  const surfaces = ["base-100", "base-200", "base-300"]
    .map((n) => opaqueOf(rootStyle.getPropertyValue("--color-" + n).trim()))
    .filter((c): c is number[] => c !== null);
  const brandForegrounds = pairs.map((p) => ({ name: p.name, fg: p.bg }));

  const softBackgrounds = pairs.flatMap((p) =>
    [8, 10].map((pct) => ({
      name: p.name,
      fg: p.bg,
      bg: over([
        "#ffffff",
        `color-mix(in oklab, ${rootStyle.getPropertyValue("--color-" + p.name).trim()} ${pct}%, ${rootStyle.getPropertyValue("--color-base-100").trim()})`,
      ]),
      pct,
    })),
  );


  function visible(el: Element): boolean {
    for (let n: Element | null = el; n; n = n.parentElement) {
      const s = getComputedStyle(n);
      if (s.display === "none") return false;
      if (s.visibility === "hidden" || s.visibility === "collapse") return false;
      if (parseFloat(s.opacity) === 0) return false;
      if (n.getAttribute("aria-hidden") === "true") return false;
      if (n.hasAttribute("inert")) return false;
    }
    const r = el.getBoundingClientRect();
    return r.width > 0.5 && r.height > 0.5;
  }
  function disabled(el: Element): boolean {
    for (let n: Element | null = el; n; n = n.parentElement) {
      if (n.hasAttribute("disabled")) return true;
      if (n.getAttribute("aria-disabled") === "true") return true;
      const cl = n.classList;
      if (cl && (cl.contains("btn-disabled") || cl.contains("menu-disabled")))
        return true;
    }
    return false;
  }
  function label(el: Element): string {
    const bits: string[] = [];
    for (let n: Element | null = el; n && bits.length < 3; n = n.parentElement) {
      const cls =
        typeof n.className === "string" && n.className.trim()
          ? "." + n.className.trim().split(/\s+/).join(".")
          : "";
      bits.unshift(n.tagName.toLowerCase() + cls);
    }
    return bits.join(" > ");
  }

  const out: ContrastHit[] = [];
  for (const el of document.querySelectorAll("*")) {
    if (el.closest("svg")) continue; // chart chrome; themes.spec owns its colours
    let text = "";
    for (const n of el.childNodes) if (n.nodeType === 3) text += n.nodeValue;
    text = text.trim();
    if (!text) continue;
    if (!visible(el) || disabled(el)) continue;
    const cs = getComputedStyle(el);
    const alpha = alphaOf(cs.color);
    if (alpha < 0.05) continue; // deliberately transparent text (modal-backdrop)

    const chain: string[] = [];
    for (let n: Element | null = el; n; n = n.parentElement)
      chain.unshift(getComputedStyle(n).backgroundColor);
    const bg = over(chain);
    const fg = over([...chain, cs.color]);
    const r = ratio(fg, bg);

    let daisyPalettePair = false;
    let pairing = "composed";
    const fgOpaque = opaqueOf(cs.color);
    for (const p of pairs) {
      if (near(bg, p.bg, 3) && near(fgOpaque, p.fg, 3)) {
        daisyPalettePair = true;
        pairing = "--color-" + p.name + " / --color-" + p.name + "-content";
        break;
      }
    }
    // The tolerance grows as the alpha shrinks, for the same reconstruction
    // reason `opaqueOf` clamps: dividing an 8-bit value by 0.4 turns a
    // half-unit rounding into a 1.25-unit one on every channel.
    const translucentTolerance = Math.max(3, Math.ceil(2 / Math.max(alpha, 0.05)));
    if (
      !daisyPalettePair &&
      alpha < 0.999 &&
      near(fgOpaque, baseContent, translucentTolerance)
    ) {
      daisyPalettePair = true;
      pairing =
        "--color-base-content at " + Math.round(alpha * 100) + "% opacity";
    }
    if (
      !daisyPalettePair &&
      alpha > 0.999 &&
      near(fgOpaque, baseContent, 3) &&
      near(bg, base300, 3)
    ) {
      daisyPalettePair = true;
      pairing = "--color-base-content / --color-base-300";
    }
    if (!daisyPalettePair) {
      for (const s of softBackgrounds) {
        if (near(bg, s.bg, 3) && near(fgOpaque, s.fg, 3)) {
          daisyPalettePair = true;
          pairing =
            "--color-" + s.name + " over color-mix(" + s.pct + "%, base-100)";
          break;
        }
      }
    }
    if (!daisyPalettePair) {
      const variant = styleVariantOf(el);
      if (variant && surfaces.some((s) => near(bg, s, 3))) {
        for (const b of brandForegrounds) {
          if (near(fgOpaque, b.fg, 3)) {
            daisyPalettePair = true;
            pairing = "." + variant + ": --color-" + b.name + " over a base surface";
            break;
          }
        }
      }
    }

    out.push({
      text: text.slice(0, 48),
      selector: label(el),
      color: cs.color,
      fontSize: parseFloat(cs.fontSize),
      ratio: Math.round(r * 100) / 100,
      fg,
      bg,
      daisyPalettePair,
      pairing,
    });
  }
  return out;
}

/**
 * Chart series colours. `Daisy.Render` writes them as `var(--color-primary)`
 * and friends straight onto the SVG `stroke`/`fill` attribute; this reads the
 * *computed* value back off the same element (which is how the `var()` gets
 * resolved) and compares it with the theme's own custom property, both painted
 * through a canvas so the comparison happens in sRGB bytes whatever colour
 * syntax the theme uses.
 */
export function collectChartColors() {
  const cv = document.createElement("canvas");
  cv.width = cv.height = 1;
  const ctx = cv.getContext("2d", { willReadFrequently: true })!;
  function rgb(color: string): number[] | null {
    if (!color || color === "none") return null;
    ctx.clearRect(0, 0, 1, 1);
    ctx.fillStyle = "#000000";
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, 1, 1);
    const d = ctx.getImageData(0, 0, 1, 1).data;
    return [d[0], d[1], d[2]];
  }
  const root =
    document.querySelector("[data-theme]") ?? document.documentElement;
  const rootStyle = getComputedStyle(root);

  const rows: {
    token: string;
    property: "stroke" | "fill";
    computed: number[] | null;
    expected: number[] | null;
    tag: string;
  }[] = [];
  for (const el of document.querySelectorAll("svg *")) {
    for (const property of ["stroke", "fill"] as const) {
      const raw = el.getAttribute(property);
      if (!raw || !raw.startsWith("var(--color-")) continue;
      const token = raw.slice(4, -1).trim(); // var(--color-primary) -> --color-primary
      rows.push({
        token,
        property,
        computed: rgb(getComputedStyle(el)[property] as string),
        expected: rgb(rootStyle.getPropertyValue(token).trim()),
        tag: el.tagName.toLowerCase(),
      });
    }
  }
  return { theme: root.getAttribute("data-theme"), rows };
}

/**
 * Every control sequential focus navigation visits, in DOM (= tree) order.
 *
 * Two places where "focusable" and "in the tab order" differ:
 *
 *   - **Radio groups.** A group is a single tab stop — the checked radio, or
 *     the first one when none is checked — and the arrow keys move inside it.
 *   - **Roving tabindex.** `Leaf.Calendar` (`alexbruf/elm-cally`) gives exactly
 *     one in-month day button `tabindex="0"` and every other day
 *     `tabindex="-1"`; the arrow keys move the roving stop, as ARIA's grid
 *     pattern requires. The `tabIndex >= 0` filter below is what models that:
 *     a month of 30 day buttons is one tab stop, not 30, and the two paging
 *     buttons are two more. Nothing is exempted — a day the browser *would*
 *     stop at is still collected, so this neither loosens nor special-cases
 *     the assertion.
 *   - **Disclosure widgets.** daisyUI's `dropdown` hides its `dropdown-content`
 *     with `display:none` until the wrapper is `:focus-within`, so tabbing to
 *     the trigger is what reveals the panel and the *next* Tab lands inside it.
 *     Collecting the closed page would therefore under-count: the panel's
 *     controls are genuinely reachable from the keyboard. Every `.dropdown` is
 *     forced open with daisyUI's own `dropdown-open` class for the length of
 *     the collection and restored immediately, so the expectation is the
 *     sequence a keyboard user actually walks. This makes the assertion
 *     stricter — a dropdown whose panel could *not* be tabbed into would now
 *     fail it.
 */
export function collectFocusables() {
  const sel = [
    "a[href]",
    "button:not([disabled])",
    "select:not([disabled])",
    "textarea:not([disabled])",
    'input:not([disabled]):not([type="hidden"])',
    "[tabindex]:not([tabindex='-1'])",
  ].join(",");

  // `opacity: 0` is deliberately **not** a reason to drop a control here, unlike
  // in the paint-facing helpers above: a transparent element is still laid out,
  // still hit-tested and still in the tab order, so the browser focuses it on
  // Tab whether this list expects it or not. That is exactly the colour picker
  // lying over a `Leaf.ColorChips` chip, and a list that omitted it would be
  // asserting a tab order the page does not have. Everything genuinely hidden
  // on these pages is hidden with `display`, `visibility` (daisyUI's closed
  // `drawer-side`), `aria-hidden` or `inert`.
  function visible(el: Element): boolean {
    for (let n: Element | null = el; n; n = n.parentElement) {
      const s = getComputedStyle(n);
      if (s.display === "none") return false;
      if (s.visibility === "hidden" || s.visibility === "collapse") return false;
      if (n.getAttribute("aria-hidden") === "true") return false;
      if (n.hasAttribute("inert")) return false;
    }
    const r = el.getBoundingClientRect();
    return r.width > 0.5 && r.height > 0.5;
  }

  function key(el: Element): string {
    const cls =
      typeof el.className === "string" && el.className.trim()
        ? "." + el.className.trim().split(/\s+/).join(".")
        : "";
    const text = (el.textContent ?? "").trim().slice(0, 24);
    const value = (el as HTMLInputElement).value ?? "";
    return `${el.tagName.toLowerCase()}${cls}|${text || value}`;
  }

  // Reveal every closed dropdown for the length of the collection, then put
  // the DOM back exactly as it was (synchronously, before Elm can re-render).
  const opened = [...document.querySelectorAll(".dropdown")].filter((el) => {
    if (el.classList.contains("dropdown-open")) return false;
    el.classList.add("dropdown-open");
    return true;
  });

  try {
    const all = [...document.querySelectorAll(sel)]
      .filter((el) => visible(el))
      .filter((el) => (el as HTMLElement).tabIndex >= 0);

    const skip = new Set<Element>();
    const groups = new Map<string, HTMLInputElement[]>();
    for (const el of all) {
      const input = el as HTMLInputElement;
      if (input.tagName === "INPUT" && input.type === "radio" && input.name) {
        const list = groups.get(input.name) ?? [];
        list.push(input);
        groups.set(input.name, list);
      }
    }
    for (const list of groups.values()) {
      const stop = list.find((r) => r.checked) ?? list[0];
      for (const r of list) if (r !== stop) skip.add(r);
    }

    return all.filter((el) => !skip.has(el)).map((el) => key(el));
  } finally {
    for (const el of opened) el.classList.remove("dropdown-open");
  }
}

/** The key of the currently focused element, in `collectFocusables` form. */
export function focusedKey(): string {
  const el = document.activeElement;
  if (!el || el === document.body) return "<body>";
  const cls =
    typeof el.className === "string" && el.className.trim()
      ? "." + el.className.trim().split(/\s+/).join(".")
      : "";
  const text = (el.textContent ?? "").trim().slice(0, 24);
  const value = (el as HTMLInputElement).value ?? "";
  return `${el.tagName.toLowerCase()}${cls}|${text || value}`;
}
