#!/usr/bin/env bun
//
// tools/build-docs-site.js — render the repository's committed markdown into a
// small static docs site under `<out>/docs/`, next to the built demo.
//
// Everything here is generated: the pages are the markdown files listed in
// PAGES, rendered with `marked`, wrapped in one daisyUI layout, and styled by
// the demo's own built stylesheet (the hashed `assets/*.css` Vite just wrote).
// There is no hand-written HTML content anywhere in the output.
//
// Usage:
//   bun tools/build-docs-site.js [outDir]        # default: demo/dist
//
// Environment:
//   VITE_BASE / BASE_PATH   the path the site is served from, default "/".
//                           `.github/workflows/pages.yml` sets it to
//                           "/elm-daisyui/" so navbar and stylesheet URLs are
//                           right on the project site. Same variable
//                           demo/vite.config.js reads, so the demo and the docs
//                           always agree.
//
// Run as a post-build step of `demo` (see demo/package.json), so both a local
// `bun run build` and the Pages build contain the site.

import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, posix, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Marked } from "marked";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = resolve(process.cwd(), process.argv[2] || join(ROOT, "demo", "dist"));
const DOCS_OUT = join(OUT, "docs");

const REPO = "https://github.com/alexbruf/elm-daisyui";
const BLOB = `${REPO}/blob/main`;
const PACKAGE_DOCS = "https://package.elm-lang.org/packages/alexbruf/elm-daisyui/latest/";

// The base the site is served from, always with a trailing slash.
const BASE = withTrailingSlash(process.env.VITE_BASE || process.env.BASE_PATH || "/");

// ---------------------------------------------------------------------------
// The pages
// ---------------------------------------------------------------------------

// source (repo-relative, posix) -> output name. A relative markdown link that
// resolves to a source in this table becomes a link inside the site; anything
// else becomes a link to the file on GitHub.
const PAGES = [
  { src: "README.md", name: "readme", blurb: "What the package is, how to install it, and how to compose a page." },
  { src: "docs/placement.md", name: "placement", blurb: "Every daisyUI component assigned to a tree level, with reasons." },
  { src: "docs/tree-decisions.md", name: "tree-decisions", blurb: "Where the implementation refines or deviates from the spec." },
  { src: "docs/demo-findings.md", name: "demo-findings", blurb: "What building the three demos revealed about the tree." },
  { src: "docs/e2e-findings.md", name: "e2e-findings", blurb: "What the browser tier measured, including the known fixmes." },
  { src: "fixtures/rejected.md", name: "rejected", blurb: "daisyUI docs examples the closed tree refuses, each with a reason." },
  { src: "fixtures/schema-diff.md", name: "schema-diff", blurb: "Every difference between the docs frontmatter and daisyUI's class.json." },
];

const BY_SOURCE = new Map(PAGES.map((p) => [p.src, p]));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function withTrailingSlash(path) {
  return path.endsWith("/") ? path : path + "/";
}

function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** GitHub-flavoured heading slug, so in-page `#anchor` links keep working. */
function slug(text) {
  return text
    .toLowerCase()
    .replace(/<[^>]*>/g, "")
    .replace(/[^\w\- ]+/g, "")
    .trim()
    .replace(/\s+/g, "-");
}

/**
 * Rewrite one link so it works from `<out>/docs/<name>.html`.
 *
 * - absolute, protocol-relative, `mailto:` and bare `#anchor` links: unchanged
 * - a relative path that resolves to one of PAGES: `<name>.html#anchor`
 * - anything else relative (source files, LICENSE, images): the file on GitHub
 */
function rewriteHref(href, sourceDir) {
  if (!href) return href;
  if (/^[a-z][a-z0-9+.-]*:/i.test(href) || href.startsWith("//")) return href;
  if (href.startsWith("#")) return href;

  const hash = href.indexOf("#");
  const path = hash === -1 ? href : href.slice(0, hash);
  const anchor = hash === -1 ? "" : href.slice(hash);
  if (path === "") return href;

  const resolved = posix.normalize(posix.join(sourceDir, path)).replace(/^\.\//, "");
  const page = BY_SOURCE.get(resolved);
  if (page) return `${page.name}.html${anchor}`;
  return `${BLOB}/${resolved}${anchor}`;
}

/**
 * Render markdown to HTML with headings given ids. `sourceDir` is the
 * directory the markdown lives in, relative to the repository root, and every
 * relative link is rewritten from there; pass `null` for markdown this script
 * generated, whose links already point at the output.
 */
function render(markdown, sourceDir) {
  const instance = new Marked({ gfm: true });
  if (sourceDir !== null) {
    instance.use({
      walkTokens(token) {
        if (token.type === "link" || token.type === "image") {
          token.href = rewriteHref(token.href, sourceDir);
        }
      },
    });
  }

  const html = instance.parse(markdown);
  const used = new Map();
  return html.replace(/<h([1-6])>([\s\S]*?)<\/h\1>/g, (_match, level, inner) => {
    const base = slug(inner) || "section";
    const seen = used.get(base) || 0;
    used.set(base, seen + 1);
    const id = seen === 0 ? base : `${base}-${seen}`;
    return `<h${level} id="${id}">${inner}</h${level}>`;
  });
}

/** The first `# ` heading of a markdown file, or a fallback. */
function titleOf(markdown, fallback) {
  const match = markdown.match(/^#\s+(.+)$/m);
  return match ? match[1].trim() : fallback;
}

/** The demo's built stylesheets, so the docs site is styled by daisyUI too. */
function stylesheets() {
  const assets = join(OUT, "assets");
  if (!existsSync(assets)) return [];
  return readdirSync(assets)
    .filter((f) => f.endsWith(".css"))
    .sort();
}

/**
 * The one layout every page shares: a daisyUI `navbar` plus the rendered
 * markdown inside a `prose` article. `data-theme="light"` pins the theme,
 * since these pages have no theme switcher of their own.
 */
function layout({ title, body, css }) {
  const links = css
    .map((file) => `    <link rel="stylesheet" href="${BASE}assets/${file}">`)
    .join("\n");
  return `<!doctype html>
<html lang="en" data-theme="light">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${escapeHtml(title.includes("elm-daisyui") ? title : `${title} — elm-daisyui`)}</title>
${links}
  </head>
  <body>
    <div class="navbar bg-base-100 shadow-sm">
      <div class="navbar-start">
        <a class="btn btn-ghost" href="${BASE}docs/">elm-daisyui docs</a>
      </div>
      <div class="navbar-end">
        <ul class="menu menu-horizontal">
          <li><a href="${BASE}">Demos</a></li>
          <li><a href="${PACKAGE_DOCS}">Package docs</a></li>
          <li><a href="${REPO}">GitHub</a></li>
        </ul>
      </div>
    </div>
    <article class="prose max-w-none p-8">
${body}
    </article>
  </body>
</html>
`;
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

if (!existsSync(OUT)) {
  console.error(`error: ${OUT} does not exist — run the demo build first`);
  process.exit(1);
}

const css = stylesheets();
if (css.length === 0) {
  console.error(`warning: no stylesheet found in ${join(OUT, "assets")}; docs pages will be unstyled`);
}

mkdirSync(DOCS_OUT, { recursive: true });

const written = [];
for (const page of PAGES) {
  const source = join(ROOT, page.src);
  if (!existsSync(source)) {
    console.error(`error: ${page.src} not found`);
    process.exit(1);
  }
  const markdown = readFileSync(source, "utf8");
  const title = titleOf(markdown, page.name);
  const html = layout({
    title,
    body: render(markdown, posix.dirname(page.src)),
    css,
  });
  writeFileSync(join(DOCS_OUT, `${page.name}.html`), html);
  written.push({ ...page, title });
}

// The contents page. Its markdown is assembled from the table above rather
// than written by hand, so it cannot drift from what was actually rendered.
const indexMarkdown = [
  "# elm-daisyui documentation",
  "",
  "Every markdown document in the repository, rendered. The [demos](" + BASE + ") are the",
  "same package composing three pages; the [package API](" + PACKAGE_DOCS + ") is on",
  "package.elm-lang.org.",
  "",
  ...written.map((p) => `- [${p.title}](${p.name}.html) — ${p.blurb} \`${p.src}\``),
  "",
  `Generated by \`tools/build-docs-site.js\` from the sources in [the repository](${REPO}).`,
].join("\n");

writeFileSync(
  join(DOCS_OUT, "index.html"),
  layout({
    title: "Documentation",
    // The index's links already point at the output, so they are left alone.
    body: render(indexMarkdown, null),
    css,
  })
);

console.log(`docs site: ${written.length + 1} pages -> ${DOCS_OUT}`);
for (const p of written) console.log(`  ${p.src.padEnd(28)} -> docs/${p.name}.html`);
console.log(`  ${"(contents)".padEnd(28)} -> docs/index.html`);
console.log(`  base ${BASE}, stylesheets: ${css.join(", ") || "(none)"}`);
