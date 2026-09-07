#!/usr/bin/env bun
// tools/gen-themes.js
//
// Reads daisyUI's own theme sources out of the pinned oracle and writes
// `src/Daisy/Themes.elm`: all 35 built-in themes as `Daisy.Tree.CustomTheme`
// values, plus `builtinToCustom : Theme -> Maybe CustomTheme`.
//
// GENERATED FILE — never hand-edit `src/Daisy/Themes.elm`; change this script
// and re-run it. Same contract as `tools/gen-schema.js`.
//
//   input   vendor/daisyui/packages/daisyui/src/themes/<name>.css  (35 files)
//   output  src/Daisy/Themes.elm
//
// Why `Daisy.Themes` and not `Daisy.Schema.Themes`: `tools/gen-schema.js` owns
// `src/Daisy/Schema/` outright — it `rmSync`s the whole directory before it
// writes, and it rewrites `elm.json`'s `exposed-modules` so that every
// `Daisy.Schema*` entry comes from its own component list. A module of ours in
// there would be deleted by the next `bun tools/gen-schema.js` and dropped from
// the package. `Daisy.Themes` is also the more honest name: the `Schema.*`
// modules are class tables, and this one holds no class at all.
//
// Each theme file is a bare list of declarations (no selector), e.g.
//
//   color-scheme: light;
//   --color-base-100: oklch(100% 0 0);
//   ...
//   --noise: 0;
//
// Every value is mapped onto a closed `Daisy.Tree` constructor. An unknown
// value is a hard failure rather than a fallback: a new daisyUI radius step has
// to be added to the Elm type before this script will emit it.
//
// Run with: bun tools/gen-themes.js

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const THEMES_DIR = join(ROOT, "vendor/daisyui/packages/daisyui/src/themes");
const OUT = join(ROOT, "src/Daisy/Themes.elm");
const TREE = join(ROOT, "src/Daisy/Tree.elm");

const problems = [];
const fail = (message) => problems.push(message);

// --- the closed enums, mirrored from Daisy.Tree ----------------------------
//
// Kept here as data so a value daisyUI adds fails loudly. The lists are checked
// against `src/Daisy/Tree.elm` below, so the two cannot drift silently.

const RADIUS = {
  "0rem": "RadiusNone",
  "0": "RadiusNone",
  "0.25rem": "RadiusXs",
  "0.5rem": "RadiusSm",
  "1rem": "RadiusMd",
  "2rem": "RadiusLg",
};

const SIZE = {
  "0.1875rem": "SizeXs",
  "0.21875rem": "SizeSm",
  "0.25rem": "SizeMd",
  "0.28125rem": "SizeLg",
  "0.3125rem": "SizeXl",
};

const BORDER = {
  "0.5px": "BorderHairline",
  "1px": "BorderThin",
  "1.5px": "BorderMedium",
  "2px": "BorderThick",
};

const SCHEME = { light: "LightScheme", dark: "DarkScheme" };

/** `--color-<css name>` -> the `ThemeColors` field it fills. */
const COLORS = [
  ["base-100", "base100"],
  ["base-200", "base200"],
  ["base-300", "base300"],
  ["base-content", "baseContent"],
  ["primary", "primary"],
  ["primary-content", "primaryContent"],
  ["secondary", "secondary"],
  ["secondary-content", "secondaryContent"],
  ["accent", "accent"],
  ["accent-content", "accentContent"],
  ["neutral", "neutral"],
  ["neutral-content", "neutralContent"],
  ["info", "info"],
  ["info-content", "infoContent"],
  ["success", "success"],
  ["success-content", "successContent"],
  ["warning", "warning"],
  ["warning-content", "warningContent"],
  ["error", "error"],
  ["error-content", "errorContent"],
];

// --- parsing ---------------------------------------------------------------

/** `light.css` -> `{ "color-scheme": "light", "--color-base-100": "oklch(...)" }`. */
function parseTheme(file, source) {
  const declarations = new Map();
  for (const raw of source.split("\n")) {
    const line = raw.trim();
    if (line === "" || line.startsWith("/*")) continue;
    const match = /^([-a-zA-Z0-9]+)\s*:\s*(.+?);$/.exec(line);
    if (!match) {
      fail(`${file}: cannot parse declaration ${JSON.stringify(line)}`);
      continue;
    }
    declarations.set(match[1], match[2].trim());
  }
  return declarations;
}

/** `oklch(62% 0.265 303.9)` -> `{ l: 62, c: 0.265, h: 303.9 }`. */
function parseOklch(file, property, value) {
  const match = /^oklch\(\s*([0-9.]+)%\s+([0-9.]+)\s+([0-9.]+)\s*\)$/.exec(value);
  if (!match) {
    fail(`${file}: ${property} is ${JSON.stringify(value)}, which is not oklch(L% C H)`);
    return { l: 0, c: 0, h: 0 };
  }
  return { l: Number(match[1]), c: Number(match[2]), h: Number(match[3]) };
}

function lookup(table, file, property, value, what) {
  const constructor = table[value];
  if (constructor === undefined) {
    fail(
      `${file}: ${property} is ${JSON.stringify(value)}, which is not one of the ` +
        `${what} steps Daisy.Tree knows (${Object.keys(table).join(", ")}). ` +
        `Add it to the Elm type first, then to this script.`
    );
    return "??";
  }
  return constructor;
}

function required(declarations, file, property) {
  const value = declarations.get(property);
  if (value === undefined) {
    fail(`${file}: no ${property} declaration`);
    return "";
  }
  return value;
}

function switchOf(file, property, value) {
  if (value === "0") return "False";
  if (value === "1") return "True";
  fail(`${file}: ${property} is ${JSON.stringify(value)}; daisyUI only ever writes 0 or 1`);
  return "False";
}

// --- Elm emission ----------------------------------------------------------

/**
 * A `Float` literal Elm accepts and `String.fromFloat` prints back the same
 * way. daisyUI writes `0`, `62`, `11.784`, `303.9`.
 */
function elmFloat(n) {
  const printed = String(n);
  return printed.startsWith("-") ? `(${printed})` : printed;
}

function elmOklch({ l, c, h }) {
  return `{ l = ${elmFloat(l)}, c = ${elmFloat(c)}, h = ${elmFloat(h)} }`;
}

/** `caramellatte` -> `Caramellatte` (the `Daisy.Tree.Theme` constructor). */
function constructorName(slug) {
  return slug
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join("");
}

/** `caramellatte` -> `caramellatte` (the Elm value name); never a keyword. */
function valueName(slug) {
  const camel = slug
    .split("-")
    .map((part, i) => (i === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1)))
    .join("");
  return camel === "type" || camel === "let" || camel === "in" ? camel + "Theme" : camel;
}

function themeValue(slug, theme) {
  const fields = COLORS.map(([cssName, field], i) => {
    const lead = i === 0 ? "{ " : ", ";
    return `        ${lead}${field} = ${elmOklch(theme.colors[cssName])}`;
  }).join("\n");
  return `{-| daisyUI's \`${slug}\` theme, exactly as
\`vendor/daisyui/packages/daisyui/src/themes/${slug}.css\` declares it.
-}
${valueName(slug)} : CustomTheme
${valueName(slug)} =
    { name = themeNameOf ${constructorName(slug)}
    , colorScheme = ${theme.colorScheme}
    , colors =
${fields}
        }
    , radius = { selector = ${theme.radius.selector}, field = ${theme.radius.field}, box = ${theme.radius.box} }
    , size = { selector = ${theme.size.selector}, field = ${theme.size.field} }
    , border = ${theme.border}
    , depth = ${theme.depth}
    , noise = ${theme.noise}
    }`;
}

// --- main ------------------------------------------------------------------

if (!existsSync(THEMES_DIR)) {
  console.error(`gen-themes: ${THEMES_DIR} not found — run tools/vendor.sh first`);
  process.exit(1);
}

const slugs = readdirSync(THEMES_DIR)
  .filter((name) => name.endsWith(".css"))
  .map((name) => name.slice(0, -4))
  .sort();

// The order is daisyUI's own, taken from `Daisy.Tree.allThemes` so the two
// cannot disagree; a file with no constructor (or a constructor with no file)
// is a failure.
const treeSource = readFileSync(TREE, "utf8");
const allThemesBlock = /allThemes =\n    \[([\s\S]*?)\n    \]/.exec(treeSource);
if (!allThemesBlock) {
  console.error("gen-themes: cannot find `allThemes` in src/Daisy/Tree.elm");
  process.exit(1);
}
const order = allThemesBlock[1]
  .split("\n")
  .map((line) => line.trim().replace(/^[[,]\s*/, ""))
  .filter((name) => name !== "");

const themeToStringBlock = /themeToString theme =\n    case theme of\n([\s\S]*?)\n\n\n/.exec(
  treeSource
);
const slugOf = new Map();
if (themeToStringBlock) {
  const pairs = [...themeToStringBlock[1].matchAll(/^\s{8}([A-Z][A-Za-z0-9]*) ->\n\s+"([^"]+)"$/gm)];
  for (const [, constructor, slug] of pairs) slugOf.set(constructor, slug);
}
for (const constructor of order) {
  if (!slugOf.has(constructor)) fail(`Daisy.Tree.themeToString has no branch for ${constructor}`);
}

const ordered = order.map((constructor) => slugOf.get(constructor)).filter(Boolean);
for (const slug of slugs) {
  if (!ordered.includes(slug)) fail(`${slug}.css has no Daisy.Tree.Theme constructor`);
}
for (const slug of ordered) {
  if (!slugs.includes(slug)) fail(`Daisy.Tree.Theme has ${slug}, but ${slug}.css does not exist`);
}

// Check the enum tables against the Elm types, so a step renamed in Elm fails
// here rather than producing a file that does not compile.
for (const [type, table] of [
  ["Radius", RADIUS],
  ["Size", SIZE],
  ["Border", BORDER],
  ["ColorScheme", SCHEME],
]) {
  for (const constructor of new Set(Object.values(table))) {
    if (!new RegExp(`^    [=|] ${constructor}$`, "m").test(treeSource)) {
      fail(`Daisy.Tree has no \`${constructor}\` constructor (expected in \`type ${type}\`)`);
    }
  }
}

const themes = new Map();
for (const slug of ordered) {
  const file = `${slug}.css`;
  const declarations = parseTheme(file, readFileSync(join(THEMES_DIR, file), "utf8"));

  const known = new Set([
    "color-scheme",
    ...COLORS.map(([cssName]) => `--color-${cssName}`),
    "--radius-selector",
    "--radius-field",
    "--radius-box",
    "--size-selector",
    "--size-field",
    "--border",
    "--depth",
    "--noise",
  ]);
  for (const property of declarations.keys()) {
    if (!known.has(property)) {
      fail(
        `${file}: unknown declaration ${property} — Daisy.Tree.CustomTheme has no field for it`
      );
    }
  }

  const colors = {};
  for (const [cssName] of COLORS) {
    const property = `--color-${cssName}`;
    colors[cssName] = parseOklch(file, property, required(declarations, file, property));
  }

  themes.set(slug, {
    colorScheme: lookup(
      SCHEME,
      file,
      "color-scheme",
      required(declarations, file, "color-scheme"),
      "color-scheme"
    ),
    colors,
    radius: {
      selector: lookup(
        RADIUS,
        file,
        "--radius-selector",
        required(declarations, file, "--radius-selector"),
        "radius"
      ),
      field: lookup(
        RADIUS,
        file,
        "--radius-field",
        required(declarations, file, "--radius-field"),
        "radius"
      ),
      box: lookup(
        RADIUS,
        file,
        "--radius-box",
        required(declarations, file, "--radius-box"),
        "radius"
      ),
    },
    size: {
      selector: lookup(
        SIZE,
        file,
        "--size-selector",
        required(declarations, file, "--size-selector"),
        "size"
      ),
      field: lookup(SIZE, file, "--size-field", required(declarations, file, "--size-field"), "size"),
    },
    border: lookup(BORDER, file, "--border", required(declarations, file, "--border"), "border"),
    depth: switchOf(file, "--depth", required(declarations, file, "--depth")),
    noise: switchOf(file, "--noise", required(declarations, file, "--noise")),
  });
}

if (problems.length > 0) {
  console.error("gen-themes: FAIL");
  for (const problem of problems) console.error("  " + problem);
  process.exit(1);
}

const exposed = ordered.map(valueName).join(", ");

const header = `module Daisy.Themes exposing
    ( builtinToCustom, all
    , ${exposed}
    )

{-| Every daisyUI built-in theme as an editable [\`CustomTheme\`](Daisy-Tree#CustomTheme).

**Generated by \`bun tools/gen-themes.js\` from
\`vendor/daisyui/packages/daisyui/src/themes/*.css\`. Never hand-edit.**

A [\`Daisy.Tree.Theme\`](Daisy-Tree#Theme) constructor is a *name*: it selects a
stylesheet rule daisyUI already ships, and there is nothing in it to read. A
theme editor needs the other thing — the ${COLORS.length} colours and nine
measurements behind that name — so that "start from \`nord\` and change the
primary" is one record update rather than twenty-nine values retyped by hand.

That is what this module is: the same declarations, as values.

    import Daisy.Themes as Themes
    import Daisy.Tree as Tree

    mine : Maybe Tree.CustomTheme
    mine =
        Tree.themeName "acme"
            |> Maybe.map (\\name -> { Themes.nord | name = name })

Each value's \`name\` is the built-in's own reserved name
([\`Daisy.Tree.themeNameOf\`](Daisy-Tree#themeNameOf)), so rendering one
unchanged as \`Custom nord\` produces \`data-theme="nord"\` and the very same
colours daisyUI's own \`nord\` rule paints — inline instead of from the
stylesheet. Give it a name of your own
([\`Daisy.Tree.themeName\`](Daisy-Tree#themeName)) to make it a theme daisyUI
does not have.


# Lookup

@docs builtinToCustom, all


# The ${ordered.length} themes

@docs ${exposed}

-}

import Daisy.Tree exposing (Border(..), ColorScheme(..), CustomTheme, Radius(..), Size(..), Theme(..), themeNameOf)


{-| The values behind a built-in theme's name.

\`Nothing\` for a [\`Theme.Custom\`](Daisy-Tree#Theme) — a custom theme *is* its
own \`CustomTheme\` already, and this function's job is the lookup a built-in
needs. Pattern-match if you want "the \`CustomTheme\` of any theme at all":

    editable : Theme -> Maybe CustomTheme
    editable theme =
        case theme of
            Custom custom ->
                Just custom

            builtin ->
                builtinToCustom builtin

-}
builtinToCustom : Theme -> Maybe CustomTheme
builtinToCustom theme =
    case theme of
${ordered.map((slug) => `        ${constructorName(slug)} ->\n            Just ${valueName(slug)}`).join("\n\n")}

        Custom _ ->
            Nothing


{-| All ${ordered.length} built-in themes, in \`Daisy.Tree.allThemes\` order.
-}
all : List CustomTheme
all =
    [ ${ordered.map(valueName).join("\n    , ")}
    ]
`;

const body = ordered.map((slug) => themeValue(slug, themes.get(slug))).join("\n\n\n");

mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, header + "\n\n" + body + "\n");

const formatted = Bun.spawnSync(["elm-format", "--yes", OUT], { cwd: ROOT, stdout: "pipe", stderr: "pipe" });
if (formatted.exitCode !== 0) {
  console.error("gen-themes: elm-format failed");
  console.error(new TextDecoder().decode(formatted.stderr));
  process.exit(1);
}

console.log(
  `gen-themes: wrote ${OUT} (${ordered.length} themes x ${COLORS.length} colours + 9 measurements)`
);
