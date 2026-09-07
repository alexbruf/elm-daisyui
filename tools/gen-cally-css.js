#!/usr/bin/env bun
// tools/gen-cally-css.js
//
// Generates the two stylesheets the demo needs for `Leaf.Calendar`:
//
//   demo/cally-daisy.css  daisyUI's own `.cally` block, rewritten from
//                         `::part()` (shadow DOM only) to light-DOM attribute
//                         selectors, so it actually styles the markup
//                         `alexbruf/elm-cally` renders.
//   demo/cally-base.css   elm-cally's own base stylesheet, wrapped in
//                         `@layer base`.
//
// Both files are committed (they are small and deterministic), but this script
// stays authoritative: regenerate rather than hand-edit. `vendor/daisyui` is
// read-only and is never written to.
//
// ## Why the rewrite is needed
//
// daisyUI styles the Cally *web component*, whose internals live in a shadow
// root, so its selectors are `.cally::part(container)` and friends.
// `alexbruf/elm-cally` renders the same markup and the same `part` attributes
// in the light DOM (no custom element, no shadow root), where `::part()` never
// matches anything. The mechanical translation — the same one elm-cally's own
// `docs/migrate-css.md` documents — is:
//
//   ::part(a)     ->  [part~="a"]
//   ::part(a b)   ->  [part~="a"][part~="b"]
//   &::part(a)    ->  [part~="a"]      (nested: still a descendant of `.cally`,
//                                       because `::part()` matched a *shadow*
//                                       descendant of the element, not itself)
//
// Any `:hover` / `:focus-visible` suffix after the `::part()` is kept, the
// nesting inside `.cally { @layer daisyui.l1.l2.l3 { ... } }` is kept verbatim,
// and nothing else in the block is touched.
//
// ## Why cally-base.css gets a layer
//
// elm-cally's stylesheet is unlayered, and unlayered rules beat *every* layered
// rule in the cascade. daisyUI's `.cally` block lives in `@layer
// daisyui.l1.l2.l3`, so without this the picker's own `background: transparent`
// and `background: var(--color-accent)` would win over daisyUI's
// `--color-primary` / `--color-base-content` day colours and the calendar would
// not look like daisyUI at all. Wrapping the copy in `@layer base` puts it
// below every daisyUI layer (Tailwind registers `base` first) while still
// beating nothing the demo relies on.
//
// Usage: bun tools/gen-cally-css.js

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

const CALLY_PACKAGE = "alexbruf/elm-cally";
const CALLY_VERSION = "1.0.0";

const DAISY_CSS = join(
  REPO_ROOT,
  "vendor/daisyui/packages/daisyui/src/components/calendar.css",
);
const OUT_DAISY = join(REPO_ROOT, "demo/cally-daisy.css");
const OUT_BASE = join(REPO_ROOT, "demo/cally-base.css");

// elm-cally ships `cally.css` at its repository root. The Elm package registry
// only distributes `src/`, `elm.json`, `README.md` and `LICENSE`, so the file
// is not inside ~/.elm; these are the places it can actually be, in order.
const BASE_CANDIDATES = [
  join(
    homedir(),
    ".elm/0.19.1/packages",
    CALLY_PACKAGE,
    CALLY_VERSION,
    "cally.css",
  ),
  join(REPO_ROOT, "../elm-calendar/elm-cally/cally.css"),
  join(homedir(), "elm-calendar/elm-cally/cally.css"),
];

/** The `.cally { ... }` block of daisyUI's calendar.css, braces balanced. */
function extractCallyBlock(css) {
  const start = css.indexOf(".cally {");
  if (start === -1) throw new Error(`no '.cally {' block in ${DAISY_CSS}`);
  let depth = 0;
  for (let i = start; i < css.length; i++) {
    if (css[i] === "{") depth++;
    else if (css[i] === "}") {
      depth--;
      if (depth === 0) return css.slice(start, i + 1);
    }
  }
  throw new Error(`unbalanced braces in the '.cally' block of ${DAISY_CSS}`);
}

/**
 * `::part(a b)` -> `[part~="a"][part~="b"]`, with or without a leading `&`.
 * Everything else on the line (a trailing `:hover`, the ` {`) is untouched.
 */
function rewritePartSelectors(block) {
  // `/* ... */` comments are left alone: daisyUI's own comment inside the block
  // talks *about* `::part()`, and rewriting prose is not the job.
  return block.replace(/\/\*[\s\S]*?\*\/|(&?)::part\(([^)]*)\)/g, (match, _amp, names) => {
    if (match.startsWith("/*")) return match;
    return names
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .map((name) => `[part~="${name}"]`)
      .join("");
  });
}

function header(lines) {
  return ["/*", ...lines.map((l) => ` * ${l}`.trimEnd()), " */", ""].join("\n");
}

function findBaseStylesheet() {
  for (const candidate of BASE_CANDIDATES) {
    if (existsSync(candidate)) return candidate;
  }
  throw new Error(
    `could not find elm-cally's cally.css. Looked in:\n  ` +
      BASE_CANDIDATES.join("\n  ") +
      `\nIt is at the root of the ${CALLY_PACKAGE} repository; the Elm package ` +
      `registry does not distribute it.`,
  );
}

/** Indent every non-empty line by two spaces, for the `@layer base` wrapper. */
function indent(text) {
  return text
    .split("\n")
    .map((line) => (line.trim() === "" ? "" : "  " + line))
    .join("\n");
}

function main() {
  // --- demo/cally-daisy.css ------------------------------------------------
  const daisyCss = readFileSync(DAISY_CSS, "utf8");
  const rewritten = rewritePartSelectors(extractCallyBlock(daisyCss));
  writeFileSync(
    OUT_DAISY,
    header([
      "GENERATED by tools/gen-cally-css.js. Do not edit.",
      "",
      "Source: vendor/daisyui/packages/daisyui/src/components/calendar.css,",
      "the `.cally { ... }` block, with every `::part(a b)` selector rewritten",
      'to the light-DOM form `[part~="a"][part~="b"]`. daisyUI targets the Cally',
      "web component's shadow parts; `alexbruf/elm-cally` renders the same",
      "`part` attributes in the light DOM, where `::part()` matches nothing.",
      "",
      "Declaration order, values and the `@layer daisyui.l1.l2.l3` wrapper are",
      "kept exactly as daisyUI wrote them.",
    ]) +
      "\n" +
      rewritten.trimEnd() +
      "\n",
  );

  // --- demo/cally-base.css -------------------------------------------------
  const basePath = findBaseStylesheet();
  const baseCss = readFileSync(basePath, "utf8");
  writeFileSync(
    OUT_BASE,
    header([
      "GENERATED by tools/gen-cally-css.js. Do not edit.",
      "",
      `Source: ${basePath.replace(homedir(), "~")}`,
      `Package: ${CALLY_PACKAGE} ${CALLY_VERSION}`,
      "",
      "elm-cally's own base stylesheet, copied verbatim and wrapped in",
      "`@layer base`. The copy is unlayered upstream, and unlayered rules beat",
      "every layered rule; daisyUI's `.cally` styles live in",
      "`@layer daisyui.l1.l2.l3`, so without the wrapper the picker's default",
      "greys would win over daisyUI's theme colours.",
    ]) +
      "\n@layer base {\n" +
      indent(baseCss.trimEnd()) +
      "\n}\n",
  );

  console.log(`[gen-cally-css] wrote ${OUT_DAISY}`);
  console.log(`[gen-cally-css] wrote ${OUT_BASE} (from ${basePath})`);
}

main();
