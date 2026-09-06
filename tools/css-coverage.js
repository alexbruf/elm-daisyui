#!/usr/bin/env bun
// tools/css-coverage.js
//
// Confirms every daisyUI class the schema knows about actually made it into
// the built demo CSS (i.e. Tailwind's `@source` scan of the Elm source
// actually found it — see demo/app.css for the mechanism). Deterministic:
// same inputs always produce the same sorted output and same exit code.
//
// Usage: bun tools/css-coverage.js [path/to/built.css ...]
// With no args, greps demo/dist/assets/*.css (the `bun run build` output).

import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

function collectClassesFromSchemaJson(path) {
  const data = JSON.parse(readFileSync(path, "utf8"));
  const classes = new Set();
  for (const componentSlug of Object.keys(data).sort()) {
    const groups = data[componentSlug];
    for (const groupName of Object.keys(groups).sort()) {
      for (const cls of groups[groupName]) {
        classes.add(cls);
      }
    }
  }
  return classes;
}

function collectClassesFromVendorFallback(componentsDir) {
  const classes = new Set();
  const entries = readdirSync(componentsDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();
  for (const dir of entries) {
    const classJsonPath = join(componentsDir, dir, "class.json");
    if (!existsSync(classJsonPath)) continue;
    const list = JSON.parse(readFileSync(classJsonPath, "utf8"));
    for (const cls of list) {
      classes.add(cls);
    }
  }
  return classes;
}

function loadExpectedClasses() {
  const schemaJsonPath = join(REPO_ROOT, "fixtures", "schema.json");
  if (existsSync(schemaJsonPath)) {
    return { classes: collectClassesFromSchemaJson(schemaJsonPath), source: schemaJsonPath };
  }

  const componentsDir = join(
    REPO_ROOT,
    "vendor",
    "daisyui",
    "packages",
    "daisyui",
    "components"
  );
  console.warn(
    `[css-coverage] WARNING: ${schemaJsonPath} does not exist yet. ` +
      `Falling back to vendor/daisyui/packages/daisyui/components/*/class.json as a stand-in oracle. ` +
      `This is broader than the real schema (it includes selector-referenced classes from other ` +
      `components) so it is only useful as a smoke check until fixtures/schema.json is generated.`
  );
  return { classes: collectClassesFromVendorFallback(componentsDir), source: componentsDir };
}

function findBuiltCssFiles(explicitPaths) {
  if (explicitPaths.length > 0) {
    return explicitPaths;
  }
  const assetsDir = join(REPO_ROOT, "demo", "dist", "assets");
  if (!existsSync(assetsDir)) {
    return [];
  }
  return readdirSync(assetsDir)
    .filter((f) => f.endsWith(".css"))
    .sort()
    .map((f) => join(assetsDir, f));
}

// Escape a class name for use as a literal CSS class selector, per CSS.escape
// rules for the characters daisyUI class names actually use (`:` and `/` are
// the ones that show up, e.g. `md:btn-wide`-style variants are not part of
// the base class names, but modifiers like `mask-squircle` don't need it;
// this still guards against any future class containing `:`, `/`, `.`, `%`,
// or a leading digit).
function escapeCssClass(cls) {
  return cls.replace(/([^a-zA-Z0-9_-])/g, "\\$1").replace(/^(\d)/, "\\3$1 ");
}

function main() {
  const explicitPaths = process.argv.slice(2);
  const { classes: expected, source } = loadExpectedClasses();
  const cssFiles = findBuiltCssFiles(explicitPaths);

  if (cssFiles.length === 0) {
    console.error(
      "[css-coverage] No built CSS found. Expected demo/dist/assets/*.css " +
        "(run `cd demo && bun run build` first) or pass explicit CSS file paths."
    );
    process.exit(1);
  }

  let css = "";
  for (const f of cssFiles) {
    css += readFileSync(f, "utf8");
  }

  // A handful of schema entries are Tailwind *variants*, not classes, e.g.
  // daisyUI's drawer defines `is-drawer-open:`/`is-drawer-close:` via
  // addVariant() (vendor/daisyui/packages/daisyui/index.js). They only ever
  // appear composed with another utility (`is-drawer-open:block`) and never
  // as a standalone `.is-drawer-open` selector, so grepping for them as a
  // class is a category error, not a coverage gap. Recognize them by the
  // trailing `:` schema.json already encodes and report them separately.
  const sortedExpected = [...expected].sort();
  const variantTokens = sortedExpected.filter((cls) => cls.endsWith(":"));
  const classTokens = sortedExpected.filter((cls) => !cls.endsWith(":"));

  const missing = [];
  for (const cls of classTokens) {
    const needle = "." + escapeCssClass(cls);
    if (!css.includes(needle)) {
      missing.push(cls);
    }
  }

  console.log(`[css-coverage] oracle: ${source}`);
  console.log(`[css-coverage] built CSS: ${cssFiles.join(", ")}`);
  console.log(`[css-coverage] expected classes: ${classTokens.length}`);
  if (variantTokens.length > 0) {
    console.log(
      `[css-coverage] skipped ${variantTokens.length} Tailwind variant token(s) (not classes): ` +
        variantTokens.join(", ")
    );
  }
  console.log(`[css-coverage] missing: ${missing.length}`);

  if (missing.length > 0) {
    console.log("[css-coverage] MISSING CLASSES:");
    for (const cls of missing) {
      console.log(`  .${cls}`);
    }
    process.exit(1);
  }

  console.log("[css-coverage] OK: every expected class is present in the built CSS.");
}

main();
