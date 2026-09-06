#!/usr/bin/env bun
// tools/extract-corpus.js
//
// Reads every daisyUI docs component page body
// (vendor/daisyui/packages/docs/src/routes/(routes)/components/<slug>/+page.md)
// and writes one JSON fixture per docs example to fixtures/corpus/<slug>--<nn>.json,
// plus an fixtures/corpus/index.json summary.
//
// Format learned from the docs source (see SPEC.md "Source of truth" and the
// CorpusTest row): each example is a `### ~Title` heading, followed by a raw
// HTML preview (ignored), followed by a fenced ```html block where daisyUI
// classes are prefixed `$$` and Tailwind utilities are not. Some examples also
// carry a paired ```jsx (or similar) fence for framework variants; only the
// ```html fence is used. `$$` sometimes also appears outside `class` (e.g. in
// `style="--$$value:...`), which is stripped from the emitted "html" verbatim
// text but is not treated as a daisyUI class.
//
// Run with: bun tools/extract-corpus.js

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseHtml } from "node-html-parser";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const COMPONENTS_DIR = path.join(
  ROOT,
  "vendor/daisyui/packages/docs/src/routes/(routes)/components"
);
const CORPUS_DIR = path.join(ROOT, "fixtures/corpus");
const SKIPPED_PATH = path.join(ROOT, "fixtures/corpus-skipped.md");

const HEADING_RE = /^#{1,3}\s/;
const TILDE_HEADING_RE = /^###\s+~(.*)$/;

/** List component slugs: directories under COMPONENTS_DIR containing a +page.md, sorted. */
function listComponentSlugs() {
  const entries = fs.readdirSync(COMPONENTS_DIR, { withFileTypes: true });
  const slugs = [];
  for (const entry of entries) {
    if (!entry.isDirectory()) continue; // skips +layout.svelte, +page.server.js, +page.svelte
    const pageMd = path.join(COMPONENTS_DIR, entry.name, "+page.md");
    if (fs.existsSync(pageMd)) slugs.push(entry.name);
  }
  slugs.sort();
  return slugs;
}

/**
 * Split a page body into example sections. Each section starts at a
 * `### ~Title` heading line and ends right before the next heading of level
 * 1-3 (so `####` sub-headings inside an example do not end it).
 */
function findExampleSections(lines) {
  const headingIdxs = [];
  for (let i = 0; i < lines.length; i++) {
    if (HEADING_RE.test(lines[i])) headingIdxs.push(i);
  }
  const sections = [];
  for (const idx of headingIdxs) {
    const m = lines[idx].match(TILDE_HEADING_RE);
    if (!m) continue;
    const title = m[1].trim();
    const next = headingIdxs.find((h) => h > idx);
    const end = next === undefined ? lines.length : next;
    sections.push({ title, startLine: idx, endLine: end });
  }
  return sections;
}

/**
 * Find the first ```html fenced block strictly inside [startLine, endLine).
 * Returns the raw block text (lines between the fences, joined with \n),
 * verbatim as authored, or null with a reason if none/malformed.
 */
function extractHtmlFence(lines, startLine, endLine) {
  let openIdx = -1;
  for (let i = startLine; i < endLine; i++) {
    if (lines[i].trim() === "```html") {
      openIdx = i;
      break;
    }
  }
  if (openIdx === -1) {
    return { html: null, reason: "no ```html fence found in example section" };
  }
  let closeIdx = -1;
  for (let i = openIdx + 1; i < endLine; i++) {
    if (lines[i].trim() === "```") {
      closeIdx = i;
      break;
    }
  }
  if (closeIdx === -1) {
    return { html: null, reason: "```html fence never closed before next heading" };
  }
  const raw = lines.slice(openIdx + 1, closeIdx).join("\n");
  return { html: raw, reason: null };
}

/** Depth-first (pre-order) walk collecting every element with >=1 `$$` class. */
function collectElements(root) {
  const out = [];
  function walk(node, parentPath) {
    const elementChildren = node.childNodes.filter((n) => n.nodeType === 1);
    elementChildren.forEach((el, i) => {
      const p = parentPath === "" ? String(i) : `${parentPath}/${i}`;
      const classAttr = el.getAttribute("class");
      if (classAttr) {
        const tokens = classAttr.split(/\s+/).filter(Boolean);
        const daisy = [];
        const tailwind = [];
        for (const t of tokens) {
          if (t.startsWith("$$")) {
            daisy.push(t.slice(2));
          } else {
            tailwind.push(t);
          }
        }
        if (daisy.length > 0) {
          out.push({
            path: p,
            tag: (el.rawTagName || el.tagName || "").toLowerCase(),
            daisy: [...daisy].sort(),
            tailwind,
          });
        }
      }
      walk(el, p);
    });
  }
  walk(root, "");
  return out;
}

function main() {
  fs.mkdirSync(CORPUS_DIR, { recursive: true });
  // Clean previously generated fixtures so removed/renamed examples don't
  // leave stale files behind (keeps re-runs deterministic and diff-free).
  for (const f of fs.readdirSync(CORPUS_DIR)) {
    if (f.endsWith(".json")) fs.unlinkSync(path.join(CORPUS_DIR, f));
  }

  const slugs = listComponentSlugs();

  let pagesProcessed = 0;
  let examplesExtracted = 0;
  const skipped = []; // { id, reason }
  const indexEntries = []; // { id, component, title, elementCount, daisyClassSet }
  const allDaisyClasses = new Set();
  const surprises = [];

  for (const slug of slugs) {
    pagesProcessed++;
    const pageMdPath = path.join(COMPONENTS_DIR, slug, "+page.md");
    const text = fs.readFileSync(pageMdPath, "utf8");
    const lines = text.split("\n");
    const sections = findExampleSections(lines);

    sections.forEach((section, i) => {
      const nn = String(i).padStart(2, "0");
      const id = `${slug}--${nn}`;
      const { html: rawHtml, reason } = extractHtmlFence(
        lines,
        section.startLine,
        section.endLine
      );
      if (rawHtml === null) {
        skipped.push({ id, title: section.title, reason });
        return;
      }

      let root;
      try {
        root = parseHtml(rawHtml, { comment: true });
      } catch (err) {
        skipped.push({
          id,
          title: section.title,
          reason: `html parse error: ${err.message}`,
        });
        return;
      }

      const elements = collectElements(root);
      const cleanedHtml = rawHtml.split("$$").join("");

      const fixture = {
        id,
        component: slug,
        title: section.title,
        html: cleanedHtml,
        elements,
      };

      fs.writeFileSync(
        path.join(CORPUS_DIR, `${id}.json`),
        JSON.stringify(fixture, null, 2) + "\n"
      );

      const daisyClassSet = [
        ...new Set(elements.flatMap((e) => e.daisy)),
      ].sort();
      for (const c of daisyClassSet) allDaisyClasses.add(c);

      indexEntries.push({
        id,
        component: slug,
        title: section.title,
        elementCount: elements.length,
        daisyClassSet,
      });

      examplesExtracted++;
    });
  }

  indexEntries.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  fs.writeFileSync(
    path.join(CORPUS_DIR, "index.json"),
    JSON.stringify(indexEntries, null, 2) + "\n"
  );

  // Skipped log
  const skippedLines = ["# Corpus extraction: skipped examples", ""];
  if (skipped.length === 0) {
    skippedLines.push("None.");
  } else {
    skipped.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
    for (const s of skipped) {
      skippedLines.push(`- \`${s.id}\` ("${s.title}"): ${s.reason}`);
    }
  }
  skippedLines.push("");
  fs.writeFileSync(SKIPPED_PATH, skippedLines.join("\n"));

  console.log(`Pages processed: ${pagesProcessed}`);
  console.log(`Examples extracted: ${examplesExtracted}`);
  console.log(`Examples skipped: ${skipped.length}`);
  console.log(`Distinct daisyUI ($$) classes seen: ${allDaisyClasses.size}`);
  if (skipped.length > 0) {
    console.log("Skipped (see fixtures/corpus-skipped.md):");
    for (const s of skipped) {
      console.log(`  - ${s.id}: ${s.reason}`);
    }
  }
  if (surprises.length > 0) {
    console.log("Surprises:");
    for (const s of surprises) console.log(`  - ${s}`);
  }
}

main();
