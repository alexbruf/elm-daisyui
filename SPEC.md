# daisyUI → Elm typed composition layer

Handoff spec. Do the steps in order. Do not skip to implementation before the schema generator (step 2) passes.

## Goal

An Elm package that lets a developer compose daisyUI views only through a closed view tree, such that the compiler and a test suite together guarantee:

- no contradictory modifiers on one element (`btn-sm` + `btn-lg`, two colors)
- no invalid nesting (card inside card, section inside block)
- no visual overlap: overlays (modal, drawer, toast, dropdown, tooltip) live in one fixed layer managed by the renderer
- a page content budget: max 5 sections, exactly one primary CTA per page

The proof that it works is a set of demo apps in the style of daisyUI's dashboard templates (step 8), built only through the tree. If a demo needs something the tree cannot express, that is a finding to report, not a reason to add an escape hatch.

daisyUI's CSS is used unchanged. Nothing in `packages/daisyui/src` is modified or rewritten.

## Source of truth

Repo: `https://github.com/saadeghi/daisyui` (v5.7.x, Tailwind 4, bun workspace).

| What | Where | Notes |
|---|---|---|
| Component CSS | `packages/daisyui/src/components/*.css` | 61 files, flat, one per component |
| Class schema | `packages/docs/src/routes/(routes)/components/<name>/+page.md` frontmatter, `classnames:` key | 68 pages. Groups: `component`, `part`, `color`, `style`, `size`, `direction`, `placement`, `modifier`, `behavior`, `variant`; ignore `safari`, `iossafari`, `firefox`, `chrome` |
| Example corpus | Same files, body | Each example: `### ~Title` heading, raw HTML, then a ```` ```html ```` block where daisyUI classes are prefixed `$$` and Tailwind utilities are not |
| Per-component class list | `packages/daisyui/components/<name>/class.json` | Only exists after `bun run build`; produced by `functions/extractClasses.js` |
| Existing tests | `packages/daisyui/functions/*.test.js` | 35 files, all test the CSS build pipeline. None test composition. Do not port them. |

Exclusivity rule derived from the schema: within one component, groups `color`, `style`, `size`, `direction`, `placement`, `variant` are pick-at-most-one. `modifier` and `behavior` are sets. `part` classes are children of the component, never standalone.

## Deliverables

```
elm-daisyui/
  elm.json
  src/
    Daisy/Schema.elm        generated, do not hand edit
    Daisy/Tree.elm          the closed ADT (step 3)
    Daisy/Render.elm        Tree -> Html msg (step 4)
    Daisy/Chart.elm         chart config types; renderer calls elm-charts (step 4)
  demo/
    elm.json                separate app, depends on ../elm-daisyui
    src/Demo/Admin.elm      dashboard: sidebar, navbar, stats, chart, table
    src/Demo/Analytics.elm  chart-heavy: line, bar, donut, stat cards
    src/Demo/Settings.elm   form-heavy: fieldsets, toggles, selects, modal confirm
    src/Main.elm            router + theme switcher
    index.html, vite.config.js, app.css   Tailwind 4 + daisyUI + elm
  tests/
    CoverageTest.elm
    ExclusivityTest.elm
    PartsTest.elm
    CorpusTest.elm
    RenderPurityTest.elm
  review/                   elm-review config + custom rules + rule tests
  e2e/
    overlap.spec.ts
    layers.spec.ts
    responsive.spec.ts
    themes.spec.ts
    a11y.spec.ts
    contrast.spec.ts
    keyboard.spec.ts
    snapshots/              committed baseline screenshots
  tools/
    gen-schema.js           frontmatter -> Schema.elm + schema.json
    extract-corpus.js       docs -> fixtures/corpus/*.json
    should-not-compile/     one .elm file per rejected nesting, plus runner
  fixtures/
    schema.json
    corpus/
    rejected.md             corpus entries the tree refuses, each with a reason
```

## Steps

### 1. Vendor the oracle

Clone daisyUI at a pinned commit into `vendor/daisyui` (git submodule or a recorded SHA in `fixtures/DAISYUI_SHA`). Run `bun install && bun run build` inside it once so `class.json` files exist.

### 2. Generate the schema

`tools/gen-schema.js` reads every `+page.md` frontmatter and emits:

- `fixtures/schema.json`: `{ component: { group: [class...] } }`
- `src/Daisy/Schema.elm`: for each component, one `type` per exclusive group (`ButtonColor = Neutral | Primary | ...`) with a `toClass` function, plus a `Set String` of modifiers. Include `allClasses : Set String`.

Acceptance: the union of all classes in `schema.json` equals the union of all `class.json` files, minus classes that only appear in browser-specific groups. Print the diff; it must be empty or every difference listed in `fixtures/schema-diff.md` with a one-line reason. Fail otherwise.

### 3. Define the tree

`src/Daisy/Tree.elm`. Four levels, one constructor per component at the level it belongs to. No constructor accepts a child of its own level or above.

```elm
type Page msg
    = Page
        { shell : Shell msg                  -- Plain | Dashboard { sidebar : Menu msg, navbar : Navbar msg }
        , sections : Sections msg            -- fixed arity, see below
        , cta : Cta msg                      -- mandatory, the only primary CTA on the page
        , overlays : List (Overlay msg)      -- modal, drawer, toast, only here
        , theme : Theme
        }

type Sections msg
    = Sections1 (Section msg)
    | Sections2 (Section msg) (Section msg)
    | Sections3 (Section msg) (Section msg) (Section msg)
    | Sections4 (Section msg) (Section msg) (Section msg) (Section msg)
    | Sections5 (Section msg) (Section msg) (Section msg) (Section msg) (Section msg)

type Section msg
    = Hero HeroConfig (List (Block msg))
    | Navbar NavbarConfig (List (Leaf msg))
    | Footer FooterConfig (List (Block msg))
    | Grid GridConfig (List (Block msg))
    | Stack StackConfig (List (Block msg))

type Block msg
    = Card CardConfig (CardParts msg)         -- parts are a record, not free children
    | Stat StatConfig (List (Leaf msg))
    | Table TableConfig (List (Row msg))
    | Form FormConfig (List (Leaf msg))
    | Alert AlertConfig (List (Leaf msg))
    | Prose (List (Leaf msg))
    | Chart ChartConfig ChartData             -- see Charts below

type Leaf msg
    = Button ButtonConfig String
    | Badge BadgeConfig String
    | Input InputConfig
    | Text String
    | Link LinkConfig String
    ...

type Overlay msg
    = Modal ModalConfig (List (Block msg))
    | Drawer DrawerConfig (List (Section msg))
    | Toast ToastConfig (List (Leaf msg))
```

Rules:

- Every `XConfig` is a record whose fields are the exclusive groups as `Maybe` values from `Schema.elm` plus `modifiers : List XModifier`. No `String` class field anywhere.
- Components with `part` classes (card, chat, stat, timeline, steps, etc.) take a record of parts, so a part cannot appear outside its component or twice.
- `dropdown` and `tooltip` are properties on `Leaf` (`Button` gets `tooltip : Maybe Tooltip`), not nodes.
- `Leaf` has no primary-CTA constructor. The only primary button on a page is `Page.cta`; the renderer places it where `Shell` dictates. A `Button` leaf cannot take `Primary` color (its `ButtonColor` type omits it). This makes "more than five sections" and "zero or two CTAs" unrepresentable, so no runtime budget check exists.
- `Shell.Dashboard` renders as daisyUI `drawer` (`drawer-open` at `lg:`) with `menu` in the side and `navbar` on top. This is the only place `drawer` appears outside `Overlay`.
- No `Raw Html` escape hatch. If a docs example cannot be expressed, it goes in `rejected.md`, not in the type.

Place every one of the 68 components at a level before writing any code. Record the placement table in `docs/placement.md`. Ask if a component's level is unclear rather than guessing.

### Charts

Use `terezka/elm-charts`. `Daisy/Chart.elm` exposes a closed config, not the elm-charts API:

```elm
type ChartConfig = Line | Bar | StackedBar | Donut | Area
type alias ChartData = { series : List Series, xLabels : List String }
type alias Series = { name : String, color : SemanticColor, points : List Float }
```

`SemanticColor` is the daisyUI palette (`Primary | Secondary | Accent | Info | Success | Warning | Error | Neutral`) and renders as `var(--color-primary)` etc. so charts follow the active theme. The renderer maps this to elm-charts calls inside `Render.elm`; elm-charts is a dependency of the library, never of demo code. Height is fixed per `Block` size token. No free-form elm-charts config leaks through.

### 4. Renderer

`src/Daisy/Render.elm`: `page : Page msg -> Html msg`. Only place daisyUI class strings are emitted. Overlays render after sections in a fixed order (drawer, modal, toast) with a fixed wrapper so z-order is set once. Spacing between sections and blocks uses fixed Tailwind gap tokens from a single constant table; no per-call override.

### 5. Static rules (elm-review)

`review/` with `jfmengels/elm-review`. Custom rules, each with a test:

- `NoClassOutsideRender`: `Html.Attributes.class`, `classList`, `attribute "class"` allowed only in `src/Daisy/Render.elm`
- `NoHtmlInDemo`: no `Html`, `Html.Attributes`, `Svg` imports under `demo/src`
- `NoRawSchemaStrings`: no string literal matching a class in `schema.json` outside `Schema.elm` and `Render.elm`

`elm-review` runs in CI and fails the build.

### 6. Tests

Rule: everything that is not guaranteed by the type checker gets a test. Three tiers.

**Tier A: unit and property (elm-test)**

| Test | Asserts | Oracle |
|---|---|---|
| CoverageTest | Set of classes emitted across all constructors == `Schema.allClasses` | `schema.json` |
| ExclusivityTest | Fuzz every config; no rendered element has two classes from one exclusive group | `schema.json` groups |
| PartsTest | Every element with a `part` class has a parent with the matching `component` class | `schema.json` `part` |
| RenderPurityTest | `render` of equal trees gives equal Html; render never emits a class outside `schema.json` or the fixed Tailwind layout token table | `schema.json`, `Render.tokens` |
| CorpusTest | For each fixture in `fixtures/corpus`: a hand-written `Tree` renders to the same daisyUI class set per element (compare `$$` classes only), or the id is in `rejected.md` with a reason | docs examples |

**Tier B: static (compile and lint)**

| Test | Asserts |
|---|---|
| should-not-compile | Each file in `tools/should-not-compile/` fails `elm make`. Minimum fixtures: card in card, section in block, six sections, two primary buttons, `modal` inside a `Block`, `card-body` outside `Card`, `btn-sm` and `btn-lg` on one button |
| elm-review | All three custom rules pass on `src/` and `demo/src`; each rule has positive and negative rule tests |
| css-coverage | Built demo CSS contains every class in `Schema.allClasses` (grep after Vite build) |

**Tier C: browser (Playwright, headless Chromium, run against the built demos)**

Run every spec across the matrix: 3 demos × viewports `375, 768, 1440` × themes `light, dark` (themes.spec runs all 35).

| Spec | Asserts | Method |
|---|---|---|
| overlap | No two visible elements intersect unless one is an ancestor of the other or both are inside the same `Stack`/`Grid` cell and the intersection is zero-area | `getBoundingClientRect` on every element with a daisyUI class; pairwise check; tolerance 1px |
| overflow | No element's box exceeds its scroll container; no horizontal scrollbar on `body` | `scrollWidth <= clientWidth`, rect containment |
| layers | With a modal open, every non-overlay element is either hidden or has a lower stacking order than the modal; toast is above modal; drawer below modal | `elementFromPoint` at each overlay corner returns the overlay or its descendant |
| responsive | At 375 the dashboard drawer is closed and a toggle exists; at 1440 it is open; stat cards wrap without overlap | rect checks per viewport |
| themes | Screenshot of each demo in each of the 35 themes matches committed baseline; chart series colors equal the computed `--color-primary` etc. of that theme | `toHaveScreenshot`, `getComputedStyle` on chart paths |
| contrast | Every visible text node has WCAG contrast ≥ 4.5 against its effective background, in every theme | computed color vs. nearest painted ancestor background; skip elements daisyUI marks disabled |
| a11y | Zero serious or critical axe violations per demo per theme | `@axe-core/playwright` |
| keyboard | Tab order reaches every `Leaf` control in tree order; modal traps focus and closes on Escape; menu items reachable | `page.keyboard`, focused element sequence |
| interaction | Toast appears and auto-dismisses; modal confirm fires the expected `msg` (assert via a debug pane in the demo showing last msg) | click, wait, read pane |

Baselines: first run generates `e2e/snapshots`; commit them. Any later diff fails and needs a human decision.

**What is deliberately not tested**

- Aesthetic judgment ("looks nice"). Covered indirectly by the corpus test (matches daisyUI's own examples) and the screenshot baseline (does not drift).
- daisyUI theme contrast in isolation: daisyUI's `contrast.test.js` already does that; Tier C contrast tests the rendered result instead.

### 7. Demo apps

Three demos in `demo/`, each a single `Page` value. Build only through `Daisy.Tree`; the demo `elm.json` must not depend on `elm/html` attributes directly (lint: no `Html.Attributes` import in `demo/src`).

| Demo | Must include |
|---|---|
| Admin | Dashboard shell, 4 `Stat` cards, one `Chart Line`, one `Table` with badges and a row action button, one `Toast` overlay, theme switcher in navbar |
| Analytics | Dashboard shell, `Chart Bar`, `Chart Donut`, `Chart Area`, `Stat` row, date-range `Select` in navbar |
| Settings | Plain shell, `Form` blocks with `fieldset`, `toggle`, `select`, `input` with `validator`, one primary CTA, a `Modal` confirm overlay |

Visual reference (look, not source): https://daisyui.com/skills/daisyui-dashboard/ and the Nexus template post at `packages/docs/src/routes/(routes)/blog/(posts)/nexus-dashboard-template`. Do not copy template HTML; express the layouts in the tree.

Build: Vite + `@tailwindcss/vite` + `daisyui` plugin + `vite-plugin-elm`. `app.css` is `@import "tailwindcss"; @plugin "daisyui" { themes: all; }` plus a `@source` pointing at the compiled Elm output so class names are detected. Confirm the final CSS contains every class `Render.elm` emits (grep the built CSS against `Schema.allClasses`); add this as a build-time check.

Acceptance: all three demos compile, pass every Tier C spec on the full matrix, and switching all 35 themes changes chart colors along with components.

### 8. Report

Final message to Alex contains:

- schema diff result (step 2)
- placement table (step 3)
- test counts per tier: passing, corpus accepted vs rejected by reason, Tier C matrix size and pass rate
- screenshots of the three demos in `light`, `dark`, and one other theme
- anything the demos needed that the tree could not express (do not add it; list it)
- any component whose level you were unsure about

## Constraints

- Elm 0.19.1. Library deps: `elm/html`, `elm/core`, `terezka/elm-charts`, `elm-explorations/test`. Node/bun only in `tools/`, `review/`, `e2e/`, and `demo/` build.
- CI order: gen-schema diff → elm make → elm-review → elm-test → should-not-compile → demo build → css-coverage → Playwright. Any failure stops the pipeline.
- No `Html.Attributes.class` call outside `Render.elm`.
- Do not modify anything under `vendor/daisyui`.
- Keep `Schema.elm` generated; if it needs a change, change the generator.
- One question at a time when blocked; prefer stating an assumption inline and continuing when the cost of being wrong is low.

