#!/usr/bin/env bun
// tools/render-class-audit.js
//
// Static half of RenderPurityTest (SPEC.md step 6, Tier A, "RenderPurityTest").
//
// The elm-test side proves that every class *emitted while rendering the test
// fixtures* is a daisyUI class from the schema or a layout token. This script
// proves the same thing about the source, for every branch, reachable by a
// fixture or not:
//
//   1. Every entry of `Daisy.Render.tokens` is a named `token*` constant whose
//      body is a plain string literal (no token is written inline).
//   2. No token is a daisyUI class: layout tokens are Tailwind utilities, and
//      daisyUI classes must come from `Daisy.Schema.*` functions.
//   3. No *free* string literal in Render.elm - one that is not an attribute
//      value, element id or text content - is a daisyUI class from
//      fixtures/schema.json. A literal daisyUI class would be a class name that
//      bypassed the generated schema.
//   4. Every free literal that looks like a CSS class is one of the tokens.
//      A bare Tailwind variant prefix ("lg:") is not a class, so it is exempt:
//      it exists only so a responsive class can be *built* from a schema class
//      (`tokenLgPrefix ++ SStat.directionToClass SStat.Horizontal`) instead of
//      being retyped as a literal. A token defined that way is a "derived"
//      token: it has no literal of its own, and rule 1 accepts it as long as
//      its prefix is a variant prefix constant and its suffix is a
//      `Daisy.Schema.*` call.
//
// "Free" means: what is left of a line after removing `Html.text "..."`,
// `Attr.<fn> "..."`, `Attr.attribute "..." "..."`, `Attr.style "..." "..."`,
// `declaration "..."` (a CSS *property* name on its way into a `style`
// attribute - `Daisy.Render.declaration` is the only thing that builds one, and
// its first argument is never a class),
// `SvgA.<fn> "..."`, `Html.node "..."` / `Svg.node "..."` / `Keyed.node "..."` (a tag name),
// `Decode.<fn> "..."` (a JSON field name) and `String.join " "` arguments, i.e.
// literals that are not being handed to the DOM as an attribute value or as
// text. A declaration whose
// every use site is an attribute argument (`shellDrawerId`,
// `themePresentationInputType`) produces attribute values too, so its body is
// skipped as well - decided by looking at the use sites, not by naming.
//
// Run with: bun tools/render-class-audit.js

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const RENDER_PATH = path.join(ROOT, "src/Daisy/Render.elm");
const SCHEMA_PATH = path.join(ROOT, "fixtures/schema.json");

/** Every daisyUI class the schema knows about. */
function daisyClasses() {
  const schema = JSON.parse(fs.readFileSync(SCHEMA_PATH, "utf8"));
  const all = new Set();
  for (const groups of Object.values(schema)) {
    for (const classes of Object.values(groups)) {
      for (const cls of classes) all.add(cls);
    }
  }
  return all;
}

/** A bare Tailwind variant prefix, e.g. `lg:`. Not a class on its own. */
const VARIANT_PREFIX = /^(?:sm|md|lg|xl|2xl):$/;

/** Top-level `name = "literal"` constants, as a Map name -> value. */
function stringConstants(lines) {
  const constants = new Map();
  for (let i = 0; i < lines.length - 1; i++) {
    const head = /^([a-z][A-Za-z0-9_]*) =$/.exec(lines[i]);
    if (!head) continue;
    const body = /^ {4}"((?:[^"\\]|\\.)*)"$/.exec(lines[i + 1]);
    if (body) constants.set(head[1], body[1]);
  }
  return constants;
}

/**
 * Top-level `name =` constants whose body is `<prefix> ++ <Schema call>`, where
 * `<prefix>` is a constant holding a Tailwind variant prefix. These build a
 * responsive class out of a generated schema class, so they carry no class
 * literal at all. Returns a Map name -> prefix constant name.
 */
function derivedConstants(lines, constants) {
  const derived = new Map();
  for (let i = 0; i < lines.length - 1; i++) {
    const head = /^([a-z][A-Za-z0-9_]*) =$/.exec(lines[i]);
    if (!head) continue;
    const body = /^ {4}([a-z][A-Za-z0-9_]*) \+\+ (S[A-Z][A-Za-z0-9]*\.[a-z][A-Za-z0-9_]*\b.*)$/.exec(
      lines[i + 1]
    );
    if (!body) continue;
    const prefix = constants.get(body[1]);
    if (prefix === undefined || !VARIANT_PREFIX.test(prefix)) continue;
    derived.set(head[1], body[1]);
  }
  return derived;
}

/** The names listed in `tokens : List String`. */
function tokenNames(lines) {
  const start = lines.findIndex((line) => line === "tokens =");
  if (start === -1) return null;
  const names = [];
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line === "]") break;
    const match = /^[[,]\s*([a-z][A-Za-z0-9_]*)$/.exec(line);
    if (match) names.push(match[1]);
    else if (line !== "") return { error: `unexpected line in tokens list: ${lines[i]}` };
  }
  return names;
}

const CLASS_LIKE = /^[a-z0-9][a-z0-9:_-]*$/;

/** Remove literals that are attribute values or text content. */
function stripAttributeContexts(line) {
  return line
    .replace(/Attr\.attribute\s+"(?:[^"\\]|\\.)*"\s+"(?:[^"\\]|\\.)*"/g, "")
    .replace(/Attr\.style\s+"(?:[^"\\]|\\.)*"\s+"(?:[^"\\]|\\.)*"/g, "")
    .replace(/\bdeclaration\s+"(?:[^"\\]|\\.)*"/g, "")
    .replace(/(?:Attr|SvgA|Ev|Decode)\.[A-Za-z0-9_]+\s+"(?:[^"\\]|\\.)*"/g, "")
    .replace(/(?:Html|Svg|Keyed)\.node\s+"(?:[^"\\]|\\.)*"/g, "")
    .replace(/Html\.text\s+"(?:[^"\\]|\\.)*"/g, "")
    .replace(/String\.join\s+"(?:[^"\\]|\\.)*"/g, "");
}

function literalsIn(text) {
  return [...text.matchAll(/"((?:[^"\\]|\\.)*)"/g)].map((match) => match[1]);
}

/**
 * Line numbers belonging to declarations whose every use site is an argument to
 * an `Attr.*` / `SvgA.*` function, so whose string literals are attribute
 * values rather than classes.
 */
function attributeValuedDeclarationLines(lines) {
  const starts = [];
  lines.forEach((line, index) => {
    const match = /^([a-z][A-Za-z0-9_]*) :/.exec(line);
    if (match) starts.push({ name: match[1], from: index });
  });
  const declarations = starts.map((start, i) => ({
    name: start.name,
    from: start.from,
    to: i + 1 < starts.length ? starts[i + 1].from : lines.length,
  }));

  const attributeLines = new Set();
  for (const declaration of declarations) {
    const uses = [];
    lines.forEach((line, index) => {
      if (index >= declaration.from && index < declaration.to) return;
      const pattern = new RegExp(`\\b${declaration.name}\\b`, "g");
      for (const match of line.matchAll(pattern)) {
        uses.push(line.slice(0, match.index));
      }
    });
    if (uses.length === 0) continue;
    const everyUseIsAnAttributeArgument = uses.every((before) =>
      /(?:Attr|SvgA)\.[A-Za-z0-9_]+\s*\(?\s*$|Attr\.attribute\s+"(?:[^"\\]|\\.)*"\s*\(?\s*$/.test(before)
    );
    if (everyUseIsAnAttributeArgument) {
      for (let i = declaration.from; i < declaration.to; i++) attributeLines.add(i);
    }
  }
  return attributeLines;
}

function main() {
  const source = fs.readFileSync(RENDER_PATH, "utf8");
  const lines = source.split("\n");
  const daisy = daisyClasses();
  const constants = stringConstants(lines);
  const derived = derivedConstants(lines, constants);
  const problems = [];

  const names = tokenNames(lines);
  if (names === null) {
    problems.push("no `tokens : List String` definition found in Render.elm");
  } else if (names.error) {
    problems.push(names.error);
  }

  const tokenValues = new Set();
  for (const name of names && !names.error ? names : []) {
    if (!constants.has(name)) {
      if (derived.has(name)) {
        // A variant prefix applied to a generated schema class: no literal to
        // check, and by construction the class half cannot be retyped.
        continue;
      }
      problems.push(`tokens lists ${name}, which is not a top-level string constant`);
      continue;
    }
    const value = constants.get(name);
    tokenValues.add(value);
    if (daisy.has(value)) {
      problems.push(`token ${name} = "${value}" is a daisyUI class; it must come from Daisy.Schema`);
    }
  }

  const attributeLines = attributeValuedDeclarationLines(lines);

  lines.forEach((line, index) => {
    if (line.trimStart().startsWith("--")) return;
    if (attributeLines.has(index)) return;
    for (const literal of literalsIn(stripAttributeContexts(line))) {
      if (literal === "" || literal === " ") continue;
      if (VARIANT_PREFIX.test(literal)) continue;
      if (daisy.has(literal)) {
        problems.push(
          `${RENDER_PATH}:${index + 1}: literal "${literal}" is a daisyUI class; ` +
            `daisyUI classes must come from a Daisy.Schema function`
        );
      } else if (CLASS_LIKE.test(literal) && !tokenValues.has(literal)) {
        problems.push(
          `${RENDER_PATH}:${index + 1}: literal "${literal}" looks like a CSS class ` +
            `but is not one of Daisy.Render.tokens`
        );
      }
    }
  });

  if (problems.length > 0) {
    console.error("render-class-audit: FAIL");
    for (const problem of problems) console.error("  " + problem);
    process.exit(1);
  }
  console.log(
    `render-class-audit: OK (${tokenValues.size} layout tokens, ` +
      `${derived.size} derived from a schema class, ` +
      `${daisy.size} daisyUI classes, no class literal in Render.elm)`
  );
}

main();
