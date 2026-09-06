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
 */
export function findOverlaps(input: { classes: string[]; tol: number }) {
  const { classes, tol } = input;
  const selector = classes.map((c) => "." + CSS.escape(c)).join(",");

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
    if (!scrollable && el.scrollWidth > el.clientWidth + tol && el.clientWidth > 0) {
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
 * daisyUI's own themes define — either a `--color-X` background under its
 * `--color-X-content` foreground, or a translucent `--color-base-content`
 * de-emphasis (`.stat-title`, `.label`, table headers). Those pairs are what
 * daisyUI's `contrast.test.js` owns; a failure outside them is ours.
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
  function opaqueOf(color: string): number[] | null {
    const a = alphaOf(color);
    if (a < 0.02) return null;
    const b = paint([color], "#000000");
    return [b[0] / a, b[1] / a, b[2] / a];
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
    if (!daisyPalettePair && alpha < 0.999 && near(fgOpaque, baseContent, 3)) {
      daisyPalettePair = true;
      pairing =
        "--color-base-content at " + Math.round(alpha * 100) + "% opacity";
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
 * Radio groups are the one place where "focusable" and "in the tab order"
 * differ: a group is a single tab stop — the checked radio, or the first one
 * when none is checked — and the arrow keys move inside it.
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

  function key(el: Element): string {
    const cls =
      typeof el.className === "string" && el.className.trim()
        ? "." + el.className.trim().split(/\s+/).join(".")
        : "";
    const text = (el.textContent ?? "").trim().slice(0, 24);
    const value = (el as HTMLInputElement).value ?? "";
    return `${el.tagName.toLowerCase()}${cls}|${text || value}`;
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
