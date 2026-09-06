# Tier C findings

What the Playwright suite (`e2e/`, SPEC.md step 6 Tier C) asserts that cannot
be made green, and why. Everything else it found was a real defect and was
fixed at its root; those fixes are listed under "Refinements from e2e" in
`docs/tree-decisions.md`.

Rule followed throughout: no assertion was weakened to make a run pass. Where a
row of the SPEC table cannot hold, the assertion stays in the file under
`test.fixme` with the reason next to it, and is listed here.

## 1. `contrast`: daisyUI's own colour pairs do not all reach 4.5:1

**Spec row:** "Every visible text node has WCAG contrast >= 4.5 against its
effective background, in every theme."

**Status:** `test.fixme` in `e2e/contrast.spec.ts`, one per demo — the tests
named *"all text reaches 4.5:1, daisyUI's own colour pairs included"*.

Some of the colour pairs daisyUI's themes define are below 4.5:1 when they are
rendered. Measured with the canvas-based collector in `e2e/lib/browser.ts`:

| Pair | Where it shows | Worst measured |
|---|---|---|
| `--color-primary` under `--color-primary-content` | the page's single primary CTA (`btn-primary`) | 3.62:1 (`winter`), 3.67:1 (`valentine`), 3.84:1 (`garden`), 4.13:1 (`dark`, `corporate`) |
| `--color-base-content` at 60% opacity over a base surface | `.stat-title`, `.stat-desc`, `<th>`, `.label` | 2.98:1 (`retro`), 3.04:1 (`silk`), 3.05:1 (`winter`) — under 4.5:1 in 20 of the 35 themes |
| `--color-error` under `--color-error-content` | table status badges | 3.32:1 (`retro`), 3.53:1 (`bumblebee`) |
| `--color-warning` / `--color-success` under their `-content` | badges, `alert-warning` | 3.05:1 (`pastel`) |
| `--color-neutral` under `--color-neutral-content` | `menu-active` in the sidebar | 3.81:1 (`pastel`) |

Nothing in the tree, the renderer or a demo changes those numbers. The CTA has
to be `btn-primary` (the tree allows exactly one primary CTA and that is what
it renders), the de-emphasised text is what daisyUI paints `.stat-title` and
`.label` with, and the badge and alert colours already use daisyUI's own
`-content` foreground — the "correct" pairing. The only fix is editing
`vendor/daisyui`, which the SPEC forbids.

SPEC.md's own "what is deliberately not tested" anticipates this: "daisyUI
theme contrast in isolation: daisyUI's `contrast.test.js` already does that;
Tier C contrast tests the rendered result instead." So the running test asserts
the row for every pair the *composition* chooses, and the `test.fixme` beside
it asserts the row as literally written.

"daisyUI's own pair" is decided mechanically rather than from a list of
selectors, so the exemption cannot quietly grow: the foreground has to be
exactly `--color-X-content` over a `--color-X` background, or a translucent
`--color-base-content`. A `color-mix` background (`badge-soft`) or a `-content`
colour over the wrong surface (`btn-neutral btn-ghost`) is *not* a daisyUI
pair, and both of those were caught and fixed by the running test.

## 2. `layers`: "toast is above modal" is not what daisyUI's CSS does

**Spec row:** "With a modal open, every non-overlay element is either hidden or
has a lower stacking order than the modal; toast is above modal; drawer below
modal."

**Status:** the spec was corrected rather than fixme'd — `e2e/layers.spec.ts`
asserts the renderer's contract instead. Recorded here because it is a
deviation from the SPEC table.

Three facts:

- `.drawer-side` is `z-index: 10` and `.modal` is `z-index: 999`, so "drawer
  below modal" holds and is asserted numerically.
- `.toast` sets no `z-index` at all. Inside `Daisy.Render`'s one fixed overlay
  wrapper it is therefore an `auto` element, and an open modal — `z-index: 999`
  and, once `showModal()` has run, in the browser's **top layer** — paints
  above it. "Toast above modal" is false as stated.
- The demos never show both at once anyway: the toast belongs to Admin and the
  modal to Settings.

What the library actually guarantees is emission order: overlays are rendered
into one fixed wrapper, always drawer, then modal, then toast, so an
application never picks a stacking order. That is what the spec asserts, on
both overlay-bearing demos, together with the direct `elementFromPoint` check
at every corner of the open modal. **Assumption stated in the spec file:** with
equal `z-index` inside one stacking context, later DOM order paints on top, so
the emission order is the stacking order — which is exactly the guarantee, and
is why the toast would be on top if `.modal` did not raise itself.

## 3. Screenshot baselines are taken at one viewport, on purpose

`e2e/themes.spec.ts` takes its 105 baselines (3 demos x 35 themes) in the
`desktop-light` project only. Running them in all six projects would be 630
images for the same information: a theme is a set of colours, and the three
viewports are already covered pixel-for-pixel by `overlap`, `overflow` and
`responsive`, which measure geometry rather than photograph it. The 35-theme
chart-colour and contrast sweeps are gated to the same project for the same
reason — neither depends on the viewport.

## 4. Things the demos still cannot express

Not Tier C failures, but the specs ran into them and they are worth keeping
next to the findings above. All are in `docs/demo-findings.md`:

- **No heading leaf** (item 1). axe reports `page-has-heading-one` and `region`
  as *moderate* on every demo. The `a11y` spec asserts zero serious/critical,
  which is the row as written, so these do not fail it — but a `Leaf.Heading`
  would clear them.
- **`.stats` has no responsive direction** (new). daisyUI's `.stats` is
  `grid-flow-col overflow-x-auto`, and `StatConfig.direction` is a single value
  with no breakpoint, so a multi-item `Stat` block is a row that scrolls
  sideways on a phone rather than wrapping. daisyUI's own idiom is
  `stats-vertical lg:stats-horizontal`, which the tree cannot say.
  *Worked around* by giving `Demo.Analytics` one `Stat` block per tile inside a
  `Grid`, which wraps with the grid.
- **A form control outside a `Field` cannot be named** (new). `SelectConfig`,
  `InputConfig` and friends have no label field, so a bare control in a navbar
  is an unnamed form control (axe `select-name`, critical). `Daisy.Render` now
  falls back to the control's `Tooltip` text as its `aria-label`, which is the
  only description the tree lets such a control carry; an `ariaLabel` field
  would be the real fix, but that is a tree change.
