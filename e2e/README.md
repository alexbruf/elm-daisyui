# e2e

Playwright (headless system Google Chrome, `channel: "chrome"`, no browser
download) against the built `demo/` app, served by `vite preview`.

## Running

```
bun install                # once, at repo root and in e2e/ (bun add already ran)
cd demo && bun install && bun run build   # build the demo first
cd e2e && bunx playwright test
```

or from the repo root: `bun run e2e` (see root `package.json`).

The config's `webServer` will also build... no — it only *runs* `bun run
preview` in `../demo`; it does **not** build the demo for you. Run `bun run
build` in `demo/` (or `bun run demo:build` at the repo root) before `bunx
playwright test`, otherwise `vite preview` serves a stale or missing
`demo/dist`.

## Port

The preview server's port is allocated once via `devports allocate elm-daisyui
e2e-preview --type app -q` (see https://github.com/bendechrai/devports) so it
won't collide with other local dev servers on this machine. If `devports`
isn't on `PATH` (e.g. a minimal CI image), the config falls back to Vite's
own default preview port, `4173`.

## Base path

The specs navigate with absolute paths (`/`, `/analytics`, `/settings`), which
is what the demo serves locally: `demo/vite.config.js` defaults Vite's `base`
to `/` and only `.github/workflows/pages.yml` overrides it (to `/elm-daisyui/`,
for the project site). `vite preview` reads the same config, so the built
`demo/dist` the `webServer` serves is a `/`-based build. Nothing here needs to
know about the prefix; see CLAUDE.md's "GitHub Pages" section for the
mechanism.

## Viewport x theme project matrix

SPEC.md's Tier C runs every spec across 3 demos x viewports `375, 768, 1440`
x themes `light, dark` (`themes.spec` additionally sweeps all 35 daisyUI
themes on its own, outside this matrix).

This config expresses that as 6 Playwright **projects**, named
`<viewport>-<theme>`:

- `mobile-light`, `mobile-dark` (375x667)
- `tablet-light`, `tablet-dark` (768x1024)
- `desktop-light`, `desktop-dark` (1440x900)

Viewport is a real Playwright `use.viewport`. Theme is **not** a native
Playwright context option, so it's a custom test-option fixture (`theme`,
declared in `fixtures.ts` and set per-project in `playwright.config.ts`).
Every spec should import `test`/`expect` from `./fixtures` (not
`@playwright/test` directly) and use the `theme` fixture to build the URL:

```ts
import { test, expect } from "./fixtures";

test("...", async ({ page, theme }) => {
  await page.goto(`/?theme=${theme}`);
  // ...
});
```

The demo (`demo/src/main.js`) is responsible for reading `?theme=` off the
URL at boot (e.g. passing it in as an Elm flag) and applying daisyUI's
`data-theme` attribute accordingly — this file does not do that wiring
itself, only the harness/convention.

`?theme=` remains the only way the specs set a theme. What changed on the
demo side is the *switcher*: the Admin navbar now renders
`ThemePresentation.ThemeAsDropdown` over all 35 `Daisy.Tree.allThemes`
values instead of four sibling `btn`s. It is one `role="button"` trigger
labelled "Theme" plus a `dropdown-content` `<ul>` of `theme-controller`
radios that daisyUI keeps at `display:none` until the wrapper is
`:focus-within`. Two consequences for anything written against it:

- to reach a radio, activate the trigger first
  (`page.getByRole("button", { name: "Theme" }).click()`), then
  `page.locator('input.theme-controller[value="nord"]')`;
- `lib/browser.ts`'s `collectFocusables` adds daisyUI's own `dropdown-open`
  class to every `.dropdown` for the length of the collection (and removes
  it again), because the panel's controls *are* keyboard-reachable — tabbing
  to the trigger is what opens it. Without that the expected tab order would
  be short by one stop and `keyboard.spec.ts` would be asserting less, not
  more.

## Determinism

Every spec navigates through `open()` in `lib/daisy.ts`, which is the only
place a page is loaded. It emulates `prefers-reduced-motion: reduce` (daisyUI's
own CSS honours it — the toast animation, for one), injects a stylesheet that
kills transitions, animations, smooth scrolling and the text caret *before*
first paint, waits for the demo's `last-msg:` pane, and awaits
`document.fonts.ready`. `deviceScaleFactor` is pinned to 1 per project.

### Fonts

The demo bundles its text face rather than inheriting one from the OS.
`demo/package.json` depends on `@fontsource-variable/inter`; `demo/app.css`
imports its stylesheet and sets Tailwind 4's font theme variable:

```css
@import "@fontsource-variable/inter";

@theme {
  --font-sans: "Inter Variable", ui-sans-serif, system-ui, sans-serif;
}
```

Tailwind's `theme.css` feeds `--font-sans` into `--default-font-family`, which
preflight sets on `html`, and daisyUI declares no `font-family` of its own — so
every component inherits it. The woff2 files are emitted into
`demo/dist/assets/` by the Vite build and served from there: self-hosted, no
CDN, nothing fetched from the network during a run.

Why it matters: before this, text was drawn in whatever the browser resolved
the generic `sans-serif` to — DejaVu Sans on a Debian workstation, something
else on a GitHub Actions runner. Every glyph in all 105 baselines differed
between the two while the layout was identical, which is what made the CI
screenshot comparisons fail. `open()` already awaited `document.fonts.ready`,
so the bundled face is loaded before anything is photographed.

## Snapshots

`snapshotDir` is `e2e/snapshots`, and the path template is
`{snapshotDir}/<tag>/{arg}{ext}` — flat filenames under one **environment
tag**. `themes.spec.ts` owns all of them: **105 baselines**, 3 demos x 35
themes, per tag, and they are committed. A later diff fails the run and needs a
human decision (see SPEC.md step 6 Tier C, "themes").

### The tag convention

`toHaveScreenshot` here is exact — `maxDiffPixels: 0`, no tolerance — so a
baseline is only comparable against the environment that took it. Bundling the
font (above) removed the OS font from the picture; the Chrome build and its
rasteriser are still environment-specific. Rather than loosen the comparison,
one committed set of baselines per environment:

| Tag | Directory | Taken by |
|---|---|---|
| `local` (default) | `e2e/snapshots/local/` | a developer machine |
| `ci` | `e2e/snapshots/ci/` | `ubuntu-latest`, via `.github/workflows/update-snapshots.yml` |

`SNAPSHOT_TAG` selects the set (`lib/snapshot-tag.ts`, read by
`playwright.config.ts` for the path template and by `themes.spec.ts` for the
gate). `.github/workflows/ci.yml` sets `SNAPSHOT_TAG: ci` for the whole job;
everything else defaults to `local`.

Regenerate the local set deliberately:

```
cd e2e && bunx playwright test themes.spec.ts --project=desktop-light --update-snapshots
```

Add a tag by running that same command with `SNAPSHOT_TAG=<tag>` and committing
the directory it writes.

### When a tag has no baselines yet

A tag whose directory does not exist has never been generated. The 105
screenshot comparisons then **skip** with the reason

```
[snapshots] no screenshot baselines for SNAPSHOT_TAG=ci (…/e2e/snapshots/ci does not exist) — run the `Update screenshot baselines` workflow (Actions -> update-snapshots -> Run workflow) on this branch, then re-run CI
```

printed once at the top of the run (from `playwright.config.ts`, so it lands in
the CI log) and attached to every skipped test. Skipping is the point: without
it, `--update-snapshots` semantics would have the very run that is supposed to
check the baselines write all 105 of them and pass. Nothing else is affected —
the chart-colour sweep in `themes.spec.ts` and the contrast sweep in
`contrast.spec.ts` measure computed values, not pixels, and run under every
tag.

### Generating the CI baselines

`.github/workflows/update-snapshots.yml`, `workflow_dispatch` only (Actions ->
*Update screenshot baselines* -> Run workflow, on the branch you want them
for). It shares `.github/actions/setup` with `ci.yml`, so the environment that
takes the baselines is the environment that later compares against them; then
it builds the demo, runs

```
SNAPSHOT_TAG=ci bunx playwright test themes.spec.ts --project=desktop-light --update-snapshots
```

and commits `e2e/snapshots/ci/**` back to the same branch as
`github-actions[bot]` (`permissions: contents: write`, default `GITHUB_TOKEN`).
It commits nothing when nothing changed.

**A push made with `GITHUB_TOKEN` does not trigger other workflows.** CI will
not start itself off that commit — start it by hand: Actions -> *CI* -> Run
workflow (`ci.yml` carries a `workflow_dispatch` trigger for exactly this).

They are taken in the `desktop-light` project only. Doing it in all six would
be 630 images for the same information: a theme is a set of colours, and the
three viewports are already covered pixel-for-pixel by `overlap`, `overflow`
and `responsive`, which measure geometry rather than photograph it. The two
other 35-theme sweeps (chart colours in `themes.spec.ts`, contrast in
`contrast.spec.ts`) are gated to the same project, for the same reason.

## The specs

| File | SPEC.md Tier C row | Runs |
|---|---|---|
| `smoke.spec.ts` | — (harness self-check) | full matrix |
| `overlap.spec.ts` | overlap | full matrix, 3 demos |
| `overflow.spec.ts` | overflow | full matrix, 3 demos |
| `layers.spec.ts` | layers | full matrix |
| `responsive.spec.ts` | responsive | full matrix, 2 dashboards |
| `themes.spec.ts` | themes | `desktop-light`, 35 themes (screenshots skip when the tag has no baselines) |
| `contrast.spec.ts` | contrast | full matrix + a 35-theme sweep in `desktop-light` |
| `a11y.spec.ts` | a11y | full matrix, 3 demos + the modal-open state |
| `keyboard.spec.ts` | keyboard | full matrix |
| `interaction.spec.ts` | interaction | full matrix |

`a11y.spec.ts` asserts zero serious/critical axe violations, which is the
SPEC row, and additionally **prints** the moderate/minor tally for every scan
as `axe <demo> <theme>: moderate=<n> minor=<n> <rule>[<impact>]x<nodes>`. It
is reported, never asserted, so a composition change's effect on the findings
the row does not fail on is visible in the run output. Since the demos gained
`Leaf.Heading`, `page-has-heading-one` is gone from all three; what is left is
`region` (2 nodes on Admin, 3 on Analytics, 0 on Settings) — the `Dashboard`
shell's navbar sits outside `<main>`, which is a `Daisy.Render` shape, not a
demo one.

`lib/daisy.ts` holds the demo list, the theme list, the `fixtures/schema.json`
reader (the daisyUI class list is read from the generated schema at test time,
not copied) and `open()`. `lib/browser.ts` holds the collectors that run inside
the page; each one is passed whole to `page.evaluate`, so each is
self-contained by construction.

## Known `fixme`s

`contrast.spec.ts` carries three `test.fixme`s — one per demo — for the version
of the contrast row that includes daisyUI's own theme colour pairs, which are
below 4.5:1 in about twenty themes and cannot be changed without editing
`vendor/daisyui`. The running tests assert the same row for every pair the
composition chooses. `docs/e2e-findings.md` has the measurements and the rest
of the reasoning, including why `layers.spec.ts` asserts the renderer's fixed
overlay order rather than SPEC's "toast is above modal".

Re-measured after the 2026-09-07 demo recomposition: in the `light` projects
all three would now pass (0 text nodes under 4.5:1, daisyUI's own pairs
included), but in the `dark` projects each demo still has exactly one — the
page's single `btn-primary` CTA, `--color-primary` under
`--color-primary-content` at 4.13:1. That pair is daisyUI's, the tree allows
exactly one primary CTA and that is what `Daisy.Render` emits, so the three
`fixme`s stay as they are rather than being un-fixme'd into a per-project
flake.

## `compare.mjs`

Not a test. It composites `docs/screenshots/nexus-vs-admin.png`: the daisyUI
Nexus e-commerce dashboard on the left, `Demo.Admin` on the right, both at
1440x900, so the recreation can be judged side by side. It renders a small local
page in the same Chrome the suite uses and photographs it, so there is no image
library to install.

```
cd e2e
bunx tsx compare.mjs <reference.png> <ours.png> ../docs/screenshots/nexus-vs-admin.png
```

The right-hand image is `snapshots/<tag>/admin-light.png` cropped to the fold,
or any 1440x900 capture of `/?theme=light`. The reference is a 1440x900
screenshot of <https://nexus.daisyui.com/dashboards/ecommerce>.
