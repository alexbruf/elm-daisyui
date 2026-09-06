#!/usr/bin/env bun
// Generates fixtures/schema.json, src/Daisy/Schema/*.elm and src/Daisy/Schema.elm
// from the pinned daisyUI docs frontmatter in vendor/daisyui.
//
// Run: bun tools/gen-schema.js
//
// Exits 1 if the class union of schema.json differs from the union of
// vendor/daisyui/packages/daisyui/components/*/class.json in any way that is
// not explained in fixtures/schema-diff.md.

import { parse as parseYaml } from "yaml";
import {
  readdirSync,
  readFileSync,
  writeFileSync,
  existsSync,
  mkdirSync,
  rmSync,
} from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DOCS = join(ROOT, "vendor/daisyui/packages/docs/src/routes/(routes)/components");
const CSS_COMPONENTS = join(ROOT, "vendor/daisyui/packages/daisyui/components");
const SCHEMA_JSON = join(ROOT, "fixtures/schema.json");
const DIFF_MD = join(ROOT, "fixtures/schema-diff.md");
const SCHEMA_DIR = join(ROOT, "src/Daisy/Schema");
const SCHEMA_ELM = join(ROOT, "src/Daisy/Schema.elm");
const ELM_JSON = join(ROOT, "elm.json");

// The ten documented class groups. Browser-support keys (safari, iossafari,
// firefox, chrome) leak into `classnames:` in some pages because their
// `browserSupport:` key is commented out; they are dropped here.
const GROUPS = [
  "component",
  "part",
  "color",
  "style",
  "size",
  "direction",
  "placement",
  "modifier",
  "behavior",
  "variant",
];
// Pick-at-most-one groups become one Elm custom type each.
const EXCLUSIVE_GROUPS = ["color", "style", "size", "direction", "placement", "variant"];
// Set-valued groups become Modifier / Behavior.
const SET_GROUPS = ["modifier", "behavior"];

const TYPE_NAME = {
  color: "Color",
  style: "Style",
  size: "Size",
  direction: "Direction",
  placement: "Placement",
  variant: "Variant",
  modifier: "Modifier",
  behavior: "Behavior",
};
const TO_CLASS = {
  color: "colorToClass",
  style: "styleToClass",
  size: "sizeToClass",
  direction: "directionToClass",
  placement: "placementToClass",
  variant: "variantToClass",
  modifier: "modifierToClass",
  behavior: "behaviorToClass",
};
const ALL_LIST = {
  color: "allColors",
  style: "allStyles",
  size: "allSizes",
  direction: "allDirections",
  placement: "allPlacements",
  variant: "allVariants",
  modifier: "allModifiers",
  behavior: "allBehaviors",
};

// ---------------------------------------------------------------------------
// naming helpers
// ---------------------------------------------------------------------------

function pascal(s) {
  return String(s)
    .split(/[^A-Za-z0-9]+/)
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join("");
}

function startsWithLetter(s) {
  return /^[A-Za-z]/.test(s);
}

/** Constructor name for `cls`, stripping the longest matching component/part prefix. */
function preferredName(cls, prefixes) {
  for (const p of prefixes) {
    if (cls.startsWith(p + "-") && cls.length > p.length + 1) {
      const n = pascal(cls.slice(p.length + 1));
      if (n && startsWithLetter(n)) return n;
    }
  }
  const full = pascal(cls);
  if (full && startsWithLetter(full)) return full;
  // Nothing usable starts with a letter (e.g. a bare "1"); prefix a letter.
  return "N" + (full || "Unnamed");
}

function fullName(cls) {
  const full = pascal(cls);
  return full && startsWithLetter(full) ? full : "N" + (full || "Unnamed");
}

// ---------------------------------------------------------------------------
// read the oracle
// ---------------------------------------------------------------------------

if (!existsSync(DOCS)) {
  console.error(`missing docs directory: ${DOCS}`);
  process.exit(1);
}

const slugs = readdirSync(DOCS)
  .filter((d) => existsSync(join(DOCS, d, "+page.md")))
  .sort();

/** slug -> { group -> [class] } */
const schema = {};
for (const slug of slugs) {
  const raw = readFileSync(join(DOCS, slug, "+page.md"), "utf8");
  const m = raw.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) throw new Error(`no frontmatter in ${slug}/+page.md`);
  const fm = parseYaml(m[1]) || {};
  const cn = fm.classnames || {};
  const out = {};
  for (const g of GROUPS) {
    const entries = cn[g];
    if (!Array.isArray(entries)) continue; // drops the scalar browser-support keys
    const classes = entries
      .map((e) => (e && typeof e === "object" ? e.class : e))
      .filter((c) => typeof c === "string" && c.length > 0);
    if (classes.length) out[g] = classes;
  }
  if (!out.component) throw new Error(`${slug}: no component group`);
  schema[slug] = out;
}

mkdirSync(dirname(SCHEMA_JSON), { recursive: true });
writeFileSync(SCHEMA_JSON, JSON.stringify(schema, null, 2) + "\n");

// ---------------------------------------------------------------------------
// build the Elm module models
// ---------------------------------------------------------------------------

const modules = [];
const seenModuleNames = new Map();

for (const slug of slugs) {
  const groups = schema[slug];
  const moduleName = pascal(slug);
  if (seenModuleNames.has(moduleName)) {
    throw new Error(
      `module name collision: ${slug} and ${seenModuleNames.get(moduleName)} both map to ${moduleName}`
    );
  }
  seenModuleNames.set(moduleName, slug);

  const componentClasses = groups.component;
  const parts = groups.part || [];
  const prefixes = [...componentClasses, ...parts].sort((a, b) => b.length - a.length);

  // Every constructor in the module shares one namespace, so names are made
  // unique across all of the module's types at once.
  const pending = [];
  for (const g of [...EXCLUSIVE_GROUPS, ...SET_GROUPS]) {
    for (const cls of groups[g] || []) pending.push({ group: g, cls });
  }
  const counts = new Map();
  for (const p of pending) {
    p.pref = preferredName(p.cls, prefixes);
    counts.set(p.pref, (counts.get(p.pref) || 0) + 1);
  }
  const used = new Set();
  for (const p of pending) {
    let name = counts.get(p.pref) === 1 ? p.pref : fullName(p.cls);
    if (used.has(name)) {
      // Last resort: qualify by group, then by index.
      let candidate = name + pascal(p.group);
      let i = 2;
      while (used.has(candidate)) candidate = name + pascal(p.group) + i++;
      name = candidate;
    }
    used.add(name);
    p.name = name;
  }

  const types = [];
  for (const g of [...EXCLUSIVE_GROUPS, ...SET_GROUPS]) {
    const members = pending.filter((p) => p.group === g);
    if (!members.length) continue;
    types.push({
      group: g,
      typeName: TYPE_NAME[g],
      toClass: TO_CLASS[g],
      allList: ALL_LIST[g],
      exclusive: EXCLUSIVE_GROUPS.includes(g),
      members: members.map((m) => ({ name: m.name, cls: m.cls })),
    });
  }

  modules.push({
    slug,
    moduleName,
    component: componentClasses[0],
    componentClasses,
    parts,
    types,
  });
}

// ---------------------------------------------------------------------------
// emit Elm
// ---------------------------------------------------------------------------

const HEADER = "-- GENERATED by tools/gen-schema.js. Do not edit.\n\n\n";

function elmString(s) {
  return '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
}

function elmList(items) {
  if (!items.length) return "[]";
  return "[ " + items.join("\n    , ") + "\n    ]";
}

function renderModule(mod) {
  const exposed = [];
  for (const t of mod.types) exposed.push(t.typeName + "(..)");
  const values = ["component", "componentClasses", "parts"];
  for (const t of mod.types) values.push(t.allList, t.toClass);
  values.sort();
  const exposing = [...exposed.sort(), ...values];

  let out = HEADER;
  out += `module Daisy.Schema.${mod.moduleName} exposing (${exposing.join(", ")})\n\n`;
  out += `{-| Generated schema for the daisyUI \`${mod.slug}\` component.\n\n`;
  if (exposed.length) {
    out += `@docs ${mod.types.map((t) => t.typeName).sort().join(", ")}\n\n`;
  }
  out += `@docs ${values.join(", ")}\n\n-}\n\n\n`;

  out += `{-| The main daisyUI class of the \`${mod.slug}\` component.\n-}\n`;
  out += `component : String\ncomponent =\n    ${elmString(mod.component)}\n\n\n`;

  out += `{-| Every class in the \`component\` group of \`${mod.slug}\`.\n-}\n`;
  out += `componentClasses : List String\ncomponentClasses =\n    ${elmList(
    mod.componentClasses.map(elmString)
  )}\n\n\n`;

  out += `{-| Every class in the \`part\` group of \`${mod.slug}\`. A part is only valid\ninside an element carrying \`component\`.\n-}\n`;
  out += `parts : List String\nparts =\n    ${elmList(mod.parts.map(elmString))}\n`;

  for (const t of mod.types) {
    const kind = t.exclusive
      ? `The \`${t.group}\` group of \`${mod.slug}\`. At most one value may be applied.`
      : `The \`${t.group}\` group of \`${mod.slug}\`. Any number of values may be applied.`;
    out += `\n\n{-| ${kind}\n-}\n`;
    out += `type ${t.typeName}\n    = ${t.members.map((m) => m.name).join("\n    | ")}\n\n\n`;
    out += `{-| Every [\`${t.typeName}\`](#${t.typeName}) value.\n-}\n`;
    out += `${t.allList} : List ${t.typeName}\n${t.allList} =\n    ${elmList(
      t.members.map((m) => m.name)
    )}\n\n\n`;
    out += `{-| The daisyUI class for a [\`${t.typeName}\`](#${t.typeName}).\n-}\n`;
    out += `${t.toClass} : ${t.typeName} -> String\n${t.toClass} value =\n    case value of\n`;
    out += t.members
      .map((m) => `        ${m.name} ->\n            ${elmString(m.cls)}\n`)
      .join("\n");
  }
  return out;
}

if (existsSync(SCHEMA_DIR)) rmSync(SCHEMA_DIR, { recursive: true, force: true });
mkdirSync(SCHEMA_DIR, { recursive: true });
for (const mod of modules) {
  writeFileSync(join(SCHEMA_DIR, `${mod.moduleName}.elm`), renderModule(mod));
}

// -- aggregate ---------------------------------------------------------------

function renderAggregate(mods) {
  const q = (m, name) => `Daisy.Schema.${m.moduleName}.${name}`;

  let out = HEADER;
  out += `module Daisy.Schema exposing (allClasses, componentClasses, exclusiveGroups, parts)\n\n`;
  out += `{-| Generated aggregate view of the daisyUI class schema.\n\n`;
  out += `@docs allClasses, componentClasses, exclusiveGroups, parts\n\n-}\n\n`;
  for (const m of mods) out += `import Daisy.Schema.${m.moduleName}\n`;
  out += `import Set exposing (Set)\n\n\n`;

  out += `{-| Every daisyUI class the schema knows about.\n-}\n`;
  out += `allClasses : Set String\nallClasses =\n    Set.fromList\n        (componentClasses\n`;
  out += `            ++ List.map .part parts\n`;
  out += `            ++ List.concatMap .classes exclusiveGroups\n`;
  out += `            ++ setClasses\n        )\n\n\n`;

  out += `{-| Every class in a \`component\` group, across all components.\n-}\n`;
  out += `componentClasses : List String\ncomponentClasses =\n    List.concat\n        ${elmList(
    mods.map((m) => q(m, "componentClasses"))
  ).replace(/\n    /g, "\n        ")}\n\n\n`;

  out += `{-| Pick-at-most-one class groups: within one entry, at most one class may\nbe applied to an element.\n-}\n`;
  out += `exclusiveGroups : List { component : String, group : String, classes : List String }\nexclusiveGroups =\n    `;
  const exclusiveEntries = [];
  for (const m of mods) {
    for (const t of m.types) {
      if (!t.exclusive) continue;
      exclusiveEntries.push(
        `{ component = ${q(m, "component")}\n      , group = ${elmString(t.group)}\n      , classes = List.map ${q(
          m,
          t.toClass
        )} ${q(m, t.allList)}\n      }`
      );
    }
  }
  out += elmList(exclusiveEntries) + "\n\n\n";

  out += `{-| Every \`part\` class paired with the \`component\` class it must sit inside.\n-}\n`;
  out += `parts : List { component : String, part : String }\nparts =\n    List.concat\n        ${elmList(
    mods
      .filter((m) => m.parts.length)
      .map((m) => `List.map (withComponent ${q(m, "component")}) ${q(m, "parts")}`)
  ).replace(/\n    /g, "\n        ")}\n\n\n`;

  out += `withComponent : String -> String -> { component : String, part : String }\n`;
  out += `withComponent c p =\n    { component = c, part = p }\n\n\n`;

  const setEntries = [];
  for (const m of mods) {
    for (const t of m.types) {
      if (t.exclusive) continue;
      setEntries.push(`List.map ${q(m, t.toClass)} ${q(m, t.allList)}`);
    }
  }
  out += `setClasses : List String\nsetClasses =\n    List.concat\n        ${elmList(setEntries).replace(
    /\n    /g,
    "\n        "
  )}\n`;
  return out;
}

writeFileSync(SCHEMA_ELM, renderAggregate(modules));

// ---------------------------------------------------------------------------
// elm.json exposed-modules
// ---------------------------------------------------------------------------

// Only the generated `Daisy.Schema*` entries are owned by this script. Every
// other exposed module (Daisy.Tree, Daisy.Render, Daisy.Chart, ...) is
// hand-written and must survive a regeneration, so it is preserved in place.
const schemaModules = ["Daisy.Schema", ...modules.map((m) => `Daisy.Schema.${m.moduleName}`)];
const isSchemaModule = (name) => name === "Daisy.Schema" || name.startsWith("Daisy.Schema.");
if (existsSync(ELM_JSON)) {
  const elmJson = JSON.parse(readFileSync(ELM_JSON, "utf8"));
  const previous = Array.isArray(elmJson["exposed-modules"]) ? elmJson["exposed-modules"] : [];
  const handWritten = previous.filter((name) => !isSchemaModule(name));
  elmJson["exposed-modules"] = [...schemaModules, ...handWritten];
  writeFileSync(ELM_JSON, JSON.stringify(elmJson, null, 4) + "\n");
} else {
  console.error("warning: elm.json not found; exposed-modules not updated");
}

// ---------------------------------------------------------------------------
// elm-format, so generated output is always format-stable
// ---------------------------------------------------------------------------

{
  const r = Bun.spawnSync(["elm-format", "--yes", SCHEMA_ELM, SCHEMA_DIR], {
    cwd: ROOT,
    stdout: "pipe",
    stderr: "pipe",
  });
  if (r.exitCode !== 0) {
    console.error("elm-format failed:");
    console.error(new TextDecoder().decode(r.stderr));
    process.exit(1);
  }
}

// ---------------------------------------------------------------------------
// acceptance diff against the built CSS class lists
// ---------------------------------------------------------------------------

const schemaClasses = new Set();
const perGroupCounts = Object.fromEntries(GROUPS.map((g) => [g, 0]));
for (const slug of slugs) {
  for (const g of GROUPS) {
    for (const cls of schema[slug][g] || []) {
      schemaClasses.add(cls);
      perGroupCounts[g] += 1;
    }
  }
}

const cssClasses = new Set();
let classJsonCount = 0;
if (existsSync(CSS_COMPONENTS)) {
  for (const d of readdirSync(CSS_COMPONENTS).sort()) {
    const p = join(CSS_COMPONENTS, d, "class.json");
    if (!existsSync(p)) continue;
    classJsonCount += 1;
    for (const c of JSON.parse(readFileSync(p, "utf8"))) cssClasses.add(c);
  }
}
if (classJsonCount === 0) {
  console.error(
    `no class.json files under ${CSS_COMPONENTS} - run 'bun install && bun run build' in vendor/daisyui first`
  );
  process.exit(1);
}

const inSchemaOnly = [...schemaClasses].filter((c) => !cssClasses.has(c)).sort();
const inCssOnly = [...cssClasses].filter((c) => !schemaClasses.has(c)).sort();

const explained = new Set();
if (existsSync(DIFF_MD)) {
  for (const line of readFileSync(DIFF_MD, "utf8").split("\n")) {
    const m = line.match(/^\s*[-*]\s+`([^`]+)`/);
    if (m) explained.add(m[1]);
  }
}

console.log("=== schema vs css class diff ===");
console.log(`in schema.json but not in class.json (${inSchemaOnly.length}):`);
for (const c of inSchemaOnly) {
  console.log(`  ${explained.has(c) ? "ok " : "!! "}${c}`);
}
console.log(`in class.json but not in schema.json (${inCssOnly.length}):`);
for (const c of inCssOnly) {
  console.log(`  ${explained.has(c) ? "ok " : "!! "}${c}`);
}

const unexplained = [...inSchemaOnly, ...inCssOnly].filter((c) => !explained.has(c));
const stale = [...explained].filter((c) => !inSchemaOnly.includes(c) && !inCssOnly.includes(c));

console.log("\n=== summary ===");
console.log(`components (docs pages): ${slugs.length}`);
console.log(`generated Elm modules:   ${modules.length + 1} (${modules.length} components + Daisy.Schema)`);
console.log(`distinct schema classes: ${schemaClasses.size}`);
console.log(`distinct css classes:    ${cssClasses.size} (from ${classJsonCount} class.json files)`);
console.log("class entries per group:");
for (const g of GROUPS) console.log(`  ${g.padEnd(10)} ${perGroupCounts[g]}`);
console.log(
  `diff: ${inSchemaOnly.length} schema-only, ${inCssOnly.length} css-only, ${unexplained.length} unexplained`
);
if (stale.length) {
  console.log(`note: ${stale.length} stale entries in fixtures/schema-diff.md: ${stale.join(", ")}`);
}

if (unexplained.length) {
  console.error(
    `\nFAIL: ${unexplained.length} class(es) differ and are not listed in fixtures/schema-diff.md:`
  );
  for (const c of unexplained) console.error(`  ${c}`);
  process.exit(1);
}
console.log("diff status: OK (every difference is explained in fixtures/schema-diff.md)");
