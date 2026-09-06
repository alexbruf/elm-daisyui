# Tree and Render decisions

Every point below either deviates from `SPEC.md` step 3/4 or refines
`docs/placement.md`. Anything not listed here follows the spec and the placement
table as written.

## Naming

- **`Section.Navbar` has no `NavbarConfig`, and `Shell.Dashboard.navbar` is a
  bare `NavbarParts msg`.** `navbar` declares no class group at all, so a config
  record would have had zero fields. A `type alias Navbar msg` was impossible
  anyway: Elm puts record-alias constructors and custom-type constructors in one
  namespace, and `Section.Navbar` already owns that name.
- **`Shell.Dashboard.sidebar : MenuSpec msg`, not `Menu msg`.** Same namespace
  clash: `Block.Menu` owns `Menu`. `MenuSpec` is the `{ config, items }` pair the
  spec sketch calls `Menu msg`, referenced (not re-placed) by the shell and by
  the `dropdown` property, exactly as placement.md requires.
- **`Block.ListBlock`, not `Block.List`.** A constructor named `List` is legal
  Elm but collides visually with `List a` at every use site in demos that
  `import Daisy.Tree exposing (..)`.
- **`Block.Stacked` keeps placement.md's name** for daisyUI `stack`;
  `Section.Stack` is the fixed-gap band.

## Configs

- **A component with no class group and no extra data gets no `XConfig`.**
  `Block.Breadcrumbs`, `Block.Chat`, `Block.Diff`, `Block.Form`,
  `Block.MockupCode`, `Block.MockupPhone`, `Block.MockupWindow`,
  `Block.MockupBrowser`, `Leaf.Countdown`, `Leaf.HoverGallery`,
  `Leaf.RadialProgress`, `Leaf.TextRotate`, `Leaf.Filter`, `Leaf.ThemeSelect`
  take their parts record or data record directly. An empty record alias would
  have documented nothing. `HeroConfig` is kept because it carries the
  `overlay : Bool` flag that drives the `hero-overlay` part.
- **`modifiers : List X.Modifier` only where the schema declares a `modifier`
  group** (placement.md's inventory), not on every config as CLAUDE.md's summary
  line says. Several components have no `Modifier` type to list.
- **Per-item modifiers live on the item, not the container.** `menu-active` /
  `-disabled` / `-focus` are `Bool` flags on `MenuItem`; `tab-active` /
  `tab-disabled` are flags on `Tab`; `dock-active` is a flag on `DockItem`;
  `step-*` colours are a field on `Step`. Putting them in the container's
  `modifiers` list would emit them on the wrong element. `MenuConfig` still has
  `modifiers` for the genuinely container-level `menu-dropdown-show` /
  `menu-paged`.
- **Configs are parameterised by `msg` where they carry a handler or a
  `Dropdown`.** `ButtonConfig msg`, `LinkConfig msg`, `InputConfig msg`,
  `AvatarConfig msg`, `CheckboxConfig msg`, `RadioConfig msg`, `RangeConfig msg`,
  `RatingConfig msg`, `SelectConfig msg`, `TextareaConfig msg`,
  `FileInputConfig msg`, `OtpConfig msg`, `SwapConfig msg`, `ToggleConfig msg`,
  `ModalConfig msg`, `ImageConfig msg`. The rest are `msg`-free.
- **Events sit in the config, not as extra constructor arguments**, so
  `Button defaultButtonConfig "Save"` stays the shape the spec sketch shows.
- **`Indicator` is not `msg`-parameterised.** Its payload is a closed
  `IndicatorPayload = IndicatorBadge … | IndicatorStatus …`, which is data.
- **`Dropdown` holds a `MenuSpec msg` only**, not `MenuSpec | List (Leaf msg)`
  as placement.md offers. `List (Leaf msg)` would make `Leaf` recursive through
  a property, which contradicts "a leaf holds only data".
- **`tooltip : Maybe Tooltip` is on every leaf config that exists**, per
  placement.md. Leaves with no config (`Text`, `Countdown`, `HoverGallery`,
  `RadialProgress`, `TextRotate`) therefore cannot carry one.
- **`Row msg` gained `header : Bool`** so a table's `<thead>` is expressible
  without a separate header field on `TableConfig`.
- **`AccordionConfig` gained `name : String`** — the shared radio group name is
  the only thing that distinguishes an accordion from a set of collapses.
- **`DrawerConfig` / `ModalConfig` gained `id : String`** for the
  `for`/`id` pairing of the toggle. Defaults are `"daisy-drawer"` and
  `"daisy-modal"`; plain `"drawer"`/`"modal"` are daisyUI class names and the
  `NoRawSchemaStrings` elm-review rule rejects them outside Schema/Render.
- **`DrawerConfig` has no `variant` field.** The `drawer` `variant` group is the
  Tailwind selector prefixes `is-drawer-open:` / `is-drawer-close:`, not classes
  an element can carry.

## Approved deviations from the spec sketch (already in placement.md)

- `Block.Stat` holds `List (StatItem msg)` parts records, not `List (Leaf msg)`.
- `Section.Navbar` holds `NavbarParts msg` (start/center/end), not a flat list.
- `Overlay.Toast` holds `List (Block msg)`, not `List (Leaf msg)`.
- `Block.Form` holds `List (Fieldset msg)`, not `List (Leaf msg)`; `label` and
  `validator` are fields on `Field`.

## Page-level additions

- **`Page` gained `dock : Maybe (Dock msg)` and `fab : Maybe (Fab msg)`**, which
  placement.md places at Page. They render in the same fixed chrome layer as the
  overlays, after them.
- **`Cta` is `{ label, onClick, size, style, modifiers, behaviors, tooltip,
  aura, indicator }`** — every button group except `color`, which is pinned to
  `btn-primary`.

## Render

- **CTA placement.** `Shell.Dashboard` renders it into `navbar-end`;
  `Shell.Plain` renders it at the end of the last section's content container
  (inside the section, not after it). Documented on `Daisy.Render.page`.
- **Overlay layer.** One `fixed inset-0 z-40 pointer-events-none` wrapper; each
  overlay re-enables pointer events. Order is always drawer, modal, toast,
  regardless of the order in `Page.overlays`.
- **`footer-title` is context-dependent.** `Block.Nav` emits the `footer-title`
  part only when it is a direct child of `Section.Footer`; elsewhere its title is
  a plain bold heading. `Daisy.Render.block` therefore renders in the
  non-footer context; `Daisy.Render.section` supplies the footer one.
- **No part class is ever a literal.** Every part comes from a named helper of
  the form `partAt <n> <Module>.parts`, and every extra component class from
  `classAt <n> <Module>.componentClasses`.
- **Donut charts are hand-rolled SVG.** elm-charts 5.0.0 has no pie or donut
  element. The ring is drawn with stroked `<circle>` elements and
  `stroke-dasharray`, which needs no arc-path maths. Each *series* is one
  segment, sized by the sum of its points; `ChartData.xLabels` is ignored for
  donuts.
- **Area charts use `CA.opacity`, not `CA.area`.** In elm-charts 5.0.0 `CA.area`
  does not apply to `CS.Interpolation`; opacity is what fills under the curve.
- **`elm/svg` was added to `elm.json` dependencies.** The donut needs real SVG
  elements, and `Html.node "svg"` produces the wrong namespace. Apps that depend
  on this package (the demo included) must list `elm/svg` as a *direct*
  dependency.

## Coverage

`Daisy.Render.unreachableClasses` has five entries out of 554:

| Class | Why |
|---|---|
| `cally`, `react-day-picker`, `vc` | `calendar` is Excluded in placement.md: theming hooks for a web component and two JS libraries, which need foreign markup. |
| `is-drawer-open:`, `is-drawer-close:` | Tailwind selector prefixes, not classes an element can carry. |

Everything else — every `component` class, every `part`, every value of every
exclusive group, every modifier and behavior — is reachable from some
`Daisy.Tree` value. Verified statically: every generated `xToClass` function is
called by `Daisy.Render`, and every `parts` / `componentClasses` entry has a
named helper that the renderer uses.

## Nothing from placement.md was left unimplemented

All 67 non-excluded components are placed and rendered. The known gaps
placement.md already records (horizontal `menu` inside a `Navbar`; `join` of
arbitrary leaves; corner placements for `toast`/`dropdown`/`indicator`/`modal`;
`Block.Stacked` overlapping by design) are unchanged — they belong in
`fixtures/rejected.md`, not in the types.

## Fixes from demos

Three defects that only show up once a real page is rendered in a browser
(SPEC.md step 7). All three are `Daisy.Render` changes; `Daisy.Tree` is
untouched.

- **`tokenChartHeight` is `min-h-64`, not `h-64`.** elm-charts scales its SVG
  to the *width* of the container and derives the drawn height from the
  `chartWidth : chartHeight` ratio (8:3). In a 1152 px wide dashboard column
  that is 432 px of SVG inside a 256 px box, which `overflow: visible` then
  painted straight over the next block — the admin demo's revenue chart sat on
  top of its orders table. A `min-h-` keeps the fixed small end that the size
  token is for and lets the box grow with the drawing.
- **Every `C.chart` passes `CA.margin chartMargin`.** elm-charts' default
  margin is zero on all four sides, so axis labels are laid out *outside* the
  SVG box and spill over whatever is beside the chart (the y labels were being
  clipped by the page edge). `chartMargin` reserves room for them inside.
- **The donut's SVG height is `chartHeight`, not `100%`.** A square viewBox
  with `height="100%"` against an auto-height parent falls back to the
  intrinsic 1:1 ratio, so the donut rendered as tall as its column was wide
  (≈530 px in the analytics grid) and dragged the whole row with it.

Not fixed, deliberately: elm-charts scales label text along with the SVG, so
labels are larger on a wide chart than on a narrow one. Fixing that needs a
container query or a non-scaling text layer, neither of which is a tree or
token concern.

## Fixes from tests

Three problems the Tier A suite found in `src/Daisy/Render.elm`, each fixed
there (nothing in `Daisy.Tree` changed):

- **`validator-hint` was not a sibling of the control under `LabelFloating`.**
  daisyUI styles the hint as `.validator ~ .validator-hint`, so the hint only
  ever shows when it directly follows the element carrying `validator`. With a
  floating label the renderer put the control inside the `<label>` and the hint
  outside it, so the selector could never match. `fieldHtml` now renders the
  hint inside the floating label, after the control. Found by `PartsTest`
  ("sibling parts follow their component").
- **`indicator-item` was on a wrapper instead of on the badge.** Every one of
  the 19 `indicator` docs examples puts the part on the badge or status itself
  (`<span class="indicator-item badge badge-primary">`), and the part is what
  positions the element it is on. `withIndicator` now passes
  `indicator-item` (plus the placement class) into `badgeHtml` / `statusHtml`
  as extra classes and no longer emits a wrapper `<span>`. Found by
  `CorpusTest` (`navbar--06`, and every `indicator--*` fixture).
- **`tools/render-class-audit.js` was added** as the static half of
  `RenderPurityTest`: the elm-test side can only see the branches the fixtures
  reach, so the audit checks the source instead — every `tokens` entry is a
  named constant, no token is a daisyUI class, and no free string literal in
  `Render.elm` (one that is not an attribute value, tag name, decoder field or
  text) is a daisyUI class or an unlisted utility. It runs in `tools/ci.sh`
  right after `elm-test`.

### Found, not fixed

Three more misplacements have the same shape — a class daisyUI puts on a child
sits on the container instead — but fixing them means changing a `Daisy.Tree`
record, not just the renderer, so they are recorded in `fixtures/rejected.md`
(as `inexpressible`) and listed here instead:

| Class | Where the tree puts it | Where daisyUI wants it |
|---|---|---|
| `timeline-box` | `TimelineConfig.modifiers`, on the `timeline` container | on one side of an item (`timeline-start` / `timeline-end`); needs `box : Bool` on `TimelineItem` |
| `list-col-grow`, `list-col-wrap` | `ListConfig.modifiers`, on the `list` container | on one cell of a `list-row`; needs a per-cell flag on `ListRow` |
| `rating-hidden` | `RatingConfig.modifiers`, on the `rating` container | on the first (blank) radio of the rating |

`CoverageTest` cannot see these: the classes are emitted, just on the wrong
element. `CorpusTest` is what exposes them, because the docs examples put them
where daisyUI does.

## Refinements from e2e

Two closed, typed additions the Tier C `keyboard` spec could not pass without,
plus the root-cause fixes the other Tier C specs turned up. Nothing here is an
escape hatch: every addition is a `Maybe` field with a `Nothing` default, so
every existing tree value keeps its meaning.

### 1. `MenuItem.href : Maybe String`

`MenuItem` carried only `onClick`, so `Daisy.Render` emitted `<a>` with no
`href`. An anchor without an `href` is not focusable and has no `link` role, so
a dashboard's primary navigation could not be reached from the keyboard at all
(`docs/demo-findings.md` item 5).

- `Daisy.Tree.MenuItem` gains `href : Maybe String`; `menuItem` defaults it to
  `Nothing`.
- `Daisy.Render.menuItemHtml` renders it as the anchor's `href`.
- `Demo.Admin` / `Demo.Analytics` sidebars pass the route path, keeping
  `onClick -> NavigateTo` alongside it. `Browser.application` intercepts the
  click as a `UrlRequest` either way, so both paths lead to the same `pushUrl`.

### 2. `ModalConfig.onClose : Maybe msg`, and the modal is a `<dialog>`

`Overlay.Modal` rendered a `div.modal` with a hidden `modal-toggle` checkbox:
no `Escape`, no focus trap, nothing to close it from the keyboard
(`docs/demo-findings.md` item 6).

- `Daisy.Tree.ModalConfig` gains `onClose : Maybe msg`, `Nothing` by default.
- `Daisy.Render` emits daisyUI's recommended dialog markup — `<dialog
  class="modal" id=...>` with the `open` attribute while `SModal.Open` is in
  the modifiers, and `aria-label` from the modal's title.
- `onClose` is wired to the dialog's **`cancel`** event plus a `keydown`
  listener filtered to `Escape`, deliberately *not* to `close`: `close` also
  fires for a programmatic `HTMLDialogElement.close()`, which is what the demo
  glue does right after the application itself closed the modal, so listening
  to it would overwrite the message the application just handled
  (`last-msg: ModalConfirmed` would become `ModalCancelled`).
- The focus trap needs `showModal()`, a DOM method Elm's view cannot call, so
  `demo/src/main.js` carries a generic `MutationObserver`: any `dialog.modal`
  that has `open` but is not yet `:modal` is re-opened with `showModal()`, and
  any `:modal` dialog whose `open` attribute Elm removed is `close()`d. (The
  attribute is put back for the length of that call, because `close()` returns
  early on a dialog with no `open` attribute and the dialog would otherwise
  stay in the top layer, keeping the page inert.)
- `Demo.Settings` wires `onClose = ModalCancelled`.
- `elm.json` gains `elm/json`: `Html.Events.on` needs a `Json.Decode.Decoder`,
  and the package had no way to build one.

### 3. Root-cause fixes the other Tier C specs forced

| Spec | Symptom | Fix, in the smallest place |
|---|---|---|
| overlap | At 375, four `grid-cols-4` tracks are ~85px and every `.stats` tile spilled over its neighbour | `Daisy.Render.gridColumnsTokens` makes the count a breakpoint: `grid-cols-1`, `sm:grid-cols-2`, then `lg:grid-cols-{3,4}`. Closes `docs/demo-findings.md` item 3 |
| overlap | At 375, `navbar-start` and `navbar-end` overlapped: daisyUI fixes both at `width: 50%`, so their contents collide rather than shrink | `navbarHtml` adds `flex-wrap` (and `gap-2`) to both halves, so each wraps inside its own half |
| responsive | Analytics' four stat tiles were one `Stat` block; daisyUI's `.stats` is `grid-flow-col overflow-x-auto`, so at 375 the row scrolled sideways instead of wrapping | Demo composition: `Demo.Analytics` uses one `Stat` block per tile inside a `Grid Cols4`, like `Demo.Admin` |
| contrast | `badge-soft` in the Admin table: 1.7–2.6:1 in `light` (soft paints the raw colour on a near-white mix) | Demo composition: solid badges, whose `-content` foreground daisyUI guarantees |
| contrast | `btn-neutral btn-ghost` row action: 1.19:1 in `dark` (ghost drops the background, the neutral foreground stays) | Demo composition: `btn-ghost` with no colour |
| contrast | `menu-title` in both sidebars: 2.52:1 in `light`, and daisyUI paints it at ~40% `base-content` by design | Demo composition: the sidebars drop the title row; the brand already sits in the navbar |
| a11y | Every `Field` control was an unnamed form control: the label was a *sibling* `<label>` with no `for` | `Daisy.Render.fieldHtml` makes the field's own `<label>` the wrapper and moves the daisyUI `label` class onto a `<span>` inside it — which is how daisyUI writes controls itself, and leaves the layout identical (`label` is `inline-flex`) |
| a11y | The Analytics navbar `select` has no `Field` to name it | `selectHtml` uses the select's `Tooltip` text as its `aria-label`, and `Demo.Analytics` gives it one ("Date range") |
| a11y, keyboard | daisyUI's `drawer-toggle` / `modal-toggle` state checkboxes are painted `h-0 w-0 opacity-0`, which still leaves them focusable and announced | Both get `tabindex="-1"` and `aria-hidden="true"` in `Daisy.Render` |

What is *not* fixed, because it cannot be without editing `vendor/daisyui`, is
in `docs/e2e-findings.md`.
