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
//                         `@layer base`. Read out of the package itself
//                         (`Cally.Css.stylesheet`, 1.1.0+) where possible; see
//                         "Where the base stylesheet comes from" below.
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
// ## Where the base stylesheet comes from
//
// elm-cally 1.0.0 kept its stylesheet in `cally.css` at the repository root,
// and the Elm registry publishes only `src/`, `elm.json`, `README.md` and
// `LICENSE` — so `elm install` never delivered it and this script had to reach
// into a checkout. 1.1.0 adds the exposed module `Cally.Css`, whose
// `stylesheet : String` is that file byte for byte, inside `src/`. Preferred
// order is therefore:
//
//   1. `src/Cally/Css.elm` of the newest elm-cally in `~/.elm` — the very code
//      the demo compiles against — if that version has the module,
//   2. `src/Cally/Css.elm` from `~/elm-calendar/elm-cally` (which is where it
//      is today: 1.1.0 is committed there but not published yet),
//   3. `cally.css` from the cache or a checkout, for elm-cally 1.0.0.
//
// The Elm literal is decoded back to CSS (`\\` -> `\`, `\"` -> `"`, exactly
// inverting elm-cally's `scripts/gen-css-module.mjs`), and when the checkout is
// present the result is byte-compared against its `cally.css` so a stale
// generated module cannot slip into the demo unnoticed. Whichever source won is
// recorded in the generated header, so the committed file says where its bytes
// came from.
//
// Usage: bun tools/gen-cally-css.js

import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

const CALLY_PACKAGE = "alexbruf/elm-cally";

const DAISY_CSS = join(
  REPO_ROOT,
  "vendor/daisyui/packages/daisyui/src/components/calendar.css",
);
const OUT_DAISY = join(REPO_ROOT, "demo/cally-daisy.css");
const OUT_BASE = join(REPO_ROOT, "demo/cally-base.css");

const ELM_PACKAGES = join(homedir(), ".elm/0.19.1/packages");
const CALLY_CHECKOUT = join(homedir(), "elm-calendar/elm-cally");

// Where the stylesheet can come from, best first.
//
// elm-cally 1.1.0 exposes `Cally.Css`, whose `stylesheet : String` holds
// `cally.css` byte for byte. That module lives in `src/`, which is exactly what
// the Elm package registry *does* distribute — so from 1.1.0 on the stylesheet
// arrives with `elm install` and the package cache is the honest source: it is
// the very code the demo compiles against.
//
// Before 1.1.0 there was no such module, and `cally.css` (a repository-root
// file the registry drops) had to be read out of a checkout. Those paths stay
// as fallbacks so this script keeps working against elm-cally 1.0.0.
//
// `~/.elm` is scanned for the newest installed version rather than a pinned
// constant, so `elm install` bumping the dependency is picked up on its own.

/** Semver-descending list of the versions of `pkg` in the local Elm cache. */
function installedCallyVersions() {
  const dir = join(ELM_PACKAGES, CALLY_PACKAGE);
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((name) => /^\d+\.\d+\.\d+$/.test(name))
    .sort((a, b) => {
      const [aa, ab, ac] = a.split(".").map(Number);
      const [ba, bb, bc] = b.split(".").map(Number);
      return ba - aa || bb - ab || bc - ac;
    });
}

/**
 * The sources to try, in order:
 *   1. `Cally/Css.elm` from the newest version in the package cache — but only
 *      that one version. If the newest installed elm-cally predates the module,
 *      an *older* version that happens to have it would be the wrong bytes to
 *      style the picker the demo actually compiles against.
 *   2. `Cally/Css.elm` from the local checkout (how this works before 1.1.0 is
 *      published and `elm install`ed).
 *   3. `cally.css` itself, from the cache (never there today) or the checkout.
 */
function baseCandidates() {
  const newest = installedCallyVersions()[0];
  const candidates = [];

  if (newest) {
    candidates.push({
      kind: "module",
      version: newest,
      origin: "package cache",
      path: join(ELM_PACKAGES, CALLY_PACKAGE, newest, "src/Cally/Css.elm"),
    });
  }
  candidates.push({
    kind: "module",
    version: null,
    origin: "checkout",
    path: join(CALLY_CHECKOUT, "src/Cally/Css.elm"),
  });
  if (newest) {
    candidates.push({
      kind: "css",
      version: newest,
      origin: "package cache",
      path: join(ELM_PACKAGES, CALLY_PACKAGE, newest, "cally.css"),
    });
  }
  candidates.push({
    kind: "css",
    version: null,
    origin: "checkout",
    path: join(REPO_ROOT, "../elm-calendar/elm-cally/cally.css"),
  });
  candidates.push({
    kind: "css",
    version: null,
    origin: "checkout",
    path: join(CALLY_CHECKOUT, "cally.css"),
  });
  return candidates;
}

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

/**
 * The body of `Cally.Css.stylesheet`'s `"""..."""` literal, decoded back to
 * CSS.
 *
 * elm-cally's `scripts/gen-css-module.mjs` writes the literal with the minimum
 * escaping an Elm multiline string needs: every `\` doubled, and a `"` escaped
 * only where a raw run of quotes could grow into the `"""` terminator. Decoding
 * is the plain left-to-right inverse, and it must be left-to-right: scanning
 * `\\"` right-to-left (or with two independent replaces) would turn an escaped
 * backslash followed by a quote into an escaped quote.
 */
function decodeElmMultiline(literal) {
  let out = "";
  for (let i = 0; i < literal.length; i++) {
    if (literal[i] === "\\" && (literal[i + 1] === "\\" || literal[i + 1] === '"')) {
      out += literal[i + 1];
      i++;
    } else {
      out += literal[i];
    }
  }
  return out;
}

/** `stylesheet = """..."""` out of a `Cally/Css.elm` source file. */
function extractStylesheetFromModule(source, path) {
  const match = source.match(/\nstylesheet =\n {4}"""([\s\S]*?)"""\n/);
  if (!match) {
    throw new Error(
      `${path} has no \`stylesheet = """..."""\` definition. Either it is not ` +
        `elm-cally's generated Cally.Css module, or the module's shape changed ` +
        `(see elm-cally's scripts/gen-css-module.mjs).`,
    );
  }
  return decodeElmMultiline(match[1]);
}

/** Read `version = "x.y.z"` out of a `Cally/Css.elm` source file, if present. */
function extractVersionFromModule(source) {
  const match = source.match(/\nversion =\n {4}"([^"]*)"/);
  return match ? match[1] : null;
}

/**
 * The stylesheet, plus where it came from, for the generated header.
 *
 * When the checkout is present its `cally.css` is the authority the module is
 * generated from, so whatever source won gets byte-compared against it. That
 * catches a stale `Cally/Css.elm` (in the cache or in the checkout) instead of
 * silently shipping the wrong CSS into the demo.
 */
function readBaseStylesheet() {
  const candidates = baseCandidates();
  const chosen = candidates.find((candidate) => existsSync(candidate.path));
  if (!chosen) {
    throw new Error(
      `could not find elm-cally's stylesheet. Looked in:\n  ` +
        candidates.map((c) => c.path).join("\n  ") +
        `\nSince 1.1.0 it is \`Cally.Css.stylesheet\` inside the package's ` +
        `\`src/\`; before that it was only \`cally.css\` at the root of the ` +
        `${CALLY_PACKAGE} repository, which the Elm package registry does not ` +
        `distribute.`,
    );
  }

  const source = readFileSync(chosen.path, "utf8");
  const css =
    chosen.kind === "module"
      ? extractStylesheetFromModule(source, chosen.path)
      : source;
  // `Cally.Css.version` is generated from the package's own elm.json, so it is
  // the more precise of the two; the cache directory name is the fallback.
  const version =
    (chosen.kind === "module" ? extractVersionFromModule(source) : null) ||
    chosen.version;

  const checkoutCss = join(CALLY_CHECKOUT, "cally.css");
  let verifiedAgainst = null;
  if (existsSync(checkoutCss)) {
    const expected = readFileSync(checkoutCss, "utf8");
    if (expected !== css) {
      throw new Error(
        `the stylesheet from ${chosen.path} is not byte-identical to ` +
          `${checkoutCss}.\nOne of them is stale: regenerate elm-cally's ` +
          `Cally.Css module (\`bun run css:generate\` in that repo) and/or ` +
          `\`elm install\` the version you mean to build against.`,
      );
    }
    verifiedAgainst = checkoutCss;
  }

  return { ...chosen, css, version, verifiedAgainst };
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
  const base = readBaseStylesheet();
  const tilde = (path) => path.replace(homedir(), "~");
  const provenance = [
    `Source: ${tilde(base.path)}`,
    `        (${base.origin}, ` +
      (base.kind === "module"
        ? "`Cally.Css.stylesheet` decoded back to CSS)"
        : "the repository-root `cally.css`)"),
    `Package: ${CALLY_PACKAGE}` +
      (base.version ? ` ${base.version}` : "") +
      (base.origin === "checkout" ? " (local checkout)" : " (installed)"),
  ];
  if (base.verifiedAgainst) {
    provenance.push(`Verified byte-identical to ${tilde(base.verifiedAgainst)}`);
  }
  writeFileSync(
    OUT_BASE,
    header([
      "GENERATED by tools/gen-cally-css.js. Do not edit.",
      "",
      ...provenance,
      "",
      "elm-cally's own base stylesheet, copied verbatim and wrapped in",
      "`@layer base`. The copy is unlayered upstream, and unlayered rules beat",
      "every layered rule; daisyUI's `.cally` styles live in",
      "`@layer daisyui.l1.l2.l3`, so without the wrapper the picker's default",
      "greys would win over daisyUI's theme colours.",
    ]) +
      "\n@layer base {\n" +
      indent(base.css.trimEnd()) +
      "\n}\n",
  );

  console.log(`[gen-cally-css] wrote ${OUT_DAISY}`);
  console.log(`[gen-cally-css] wrote ${OUT_BASE} (from ${base.path})`);
}

main();
