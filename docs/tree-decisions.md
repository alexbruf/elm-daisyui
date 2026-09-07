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
- **`chartWidth`/`chartViewboxHeight` widened from `640 x 240` to
  `800 x 300`.** elm-charts sets no `width`/`height` attribute on its `<svg>`,
  only a `viewBox`, so the browser stretches it to the container's width and
  every SVG length inside — including the inherited axis-label font-size —
  scales by `containerPx / chartWidth`. At `640`, a full-width (`Cols1`)
  ~1120 px block scaled labels up ~1.75x on top of the library's already
  large default, reading as roughly 3x too big ("Jan", "200" dwarfing the
  page's own text); a half-width (`Cols2`, ~536 px) block was fine at that
  same setting. `800 x 300` (still `chartWidth`'s 8:3 ratio, matching
  `tokenChartHeight`'s `min-h-64`) was chosen by screenshotting `/` and
  `/analytics` at 1440 px and 375 px and comparing label bounding-box heights:
  it brings the full-width case down to ~25 px (from ~31 px) and only costs
  the half-width case ~12 px (from ~15 px) and the mobile single-column case
  ~7 px (from ~9 px) — legible everywhere, and no longer 3x oversized on the
  case that was actually broken. The donut is unaffected: its fixed pixel
  height now comes from its own `chartHeight` (240, unchanged) so widening
  the line/bar/area viewBox doesn't also inflate it. Changing the viewBox
  changes only internal SVG scaling, not the rendered chart's on-page size
  (still `containerPx * 3 / 8`, per `tokenChartHeight`), so this carries no
  layout/overlap risk.

Not fixed, deliberately: a single shared viewBox can't scale to exactly 1x
for every container width a chart might render at (full-width, half-width,
and single-column-on-mobile are ~3.6x apart), so `800 x 300` is a compromise,
not a perfect fit for any one of them. A real fix needs a container query or
a non-scaling text layer, neither of which is a tree or token concern.

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

### ~~Found, not fixed~~ — fixed

Three more misplacements had the same shape — a class daisyUI puts on a child
sat on the container instead. All three are now fixed at the `Daisy.Tree`
level; see "Expressibility refinements (2026-09-07)" below.

| Class | Where the tree used to put it | Where it goes now |
|---|---|---|
| `timeline-box` | `TimelineConfig.modifiers`, on the `timeline` container | `startBox` / `endBox` on `TimelineItem`, on that side of that item |
| `list-col-grow`, `list-col-wrap` | `ListConfig.modifiers`, on the `list` container | `grow` / `wrap` on `ListCell`, on that one cell |
| `rating-hidden` | `RatingConfig.modifiers`, on the `rating` container | `clearable` on `RatingData`, on the blank first radio |

`CoverageTest` could not see any of them: the classes were emitted, just on the
wrong element. `CorpusTest` is what exposed them, because the docs examples put
them where daisyUI does — and it is what now holds them in place.

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

## Expressibility refinements (2026-09-07)

Ten closed, typed additions. Every one is a field or constructor with a
sensible default, so no tree gains an escape hatch and nothing became
authorable that the exclusivity, parts or one-primary-CTA rules forbid. Each
closes a `docs/demo-findings.md` or `docs/e2e-findings.md` entry, or one of the
"Found, not fixed" rows above.

### 1. `Leaf.Heading HeadingLevel String`

`HeadingLevel = H1 | H2 | H3`, rendered as a bare `<h1>`/`<h2>`/`<h3>`.
Heading is not a daisyUI component and emits **no** daisyUI class: Tailwind
typography styles it when it sits inside `Block.Prose`. Without it a page had
no document outline at all (`demo-findings` item 1; axe's
`page-has-heading-one` and `region` on every demo, `e2e-findings` §4).

### 2. `CardParts.body : List (CardChild msg)`

`CardChild = CardLeaf (Leaf msg) | CardChart ChartConfig ChartData | CardTable
TableConfig (List (Row msg)) | CardStat StatConfig (List (StatItem msg)) |
CardForm (List (Fieldset msg))`. "A chart in a card" is the single most common
dashboard idiom and was inexpressible (`demo-findings` item 7).

There is deliberately **no** `CardCard`, and `CardLeaf` takes a `Leaf`, so a
card still cannot contain a card:
`tools/should-not-compile/Reject/CardInCard.elm` still fails, and
`Reject/CardInCardBody.elm` was added to fail on the new slot too.
`Daisy.Render.cardChildHtml` dispatches to the very same helpers `blockIn`
uses (`chartHtml`, `tableHtml`, and the new `statsHtml` / `formHtml`), so a
chart in a card and a bare chart are identical markup rather than a second
implementation. Corpus effect: `hero--03` (a fieldset in a card in a hero) is
now expressible.

### 3. `Align.AlignStretch`, but not as the default

`AlignStretch` emits `items-stretch`, which is what lets a `Table`, `Alert` or
`Card` fill a `Section.Stack` band (`demo-findings` item 2).

`defaultStackConfig` keeps `AlignStart`. Making stretch the default *would*
change how `Page.cta` is stretched under `Shell.Plain`: the renderer appends
the CTA to the last section's own container, so a stretched last `Stack` would
stretch the page's single primary button across the full page width — exactly
the effect `demo-findings` item 2 records for a one-column `Grid`, and the
reason `Demo.Settings` keeps its last section a `Stack`. Documented on
`defaultStackConfig`.

### 4. `ThemePresentation.ThemeAsDropdown`

Renders daisyUI's documented "Using a dropdown" markup from
`components/theme-controller/+page.md`: a `dropdown` wrapper, a
`tabindex="0" role="button"` `btn` trigger, and a `dropdown-content` `<ul>` of
`<li>` radios carrying `theme-controller btn btn-sm btn-block btn-ghost`. The
`<ul>` also gets `bg-base-100` and `p-2` from the existing token table, which
is what makes the floating panel readable; no new Tailwind token was needed.

This is the only presentation that stays one control wide regardless of how
many themes it offers — every other one is a sibling input per theme, i.e. 35
controls with `allThemes` (`demo-findings` item 4). Corpus effect:
`theme-controller--09` is now expressible; `--08` (a `theme-controller` with
`join-item`) still is not, and its `rejected.md` reason was narrowed to say so.

### 5. `StatConfig.direction : StatDirection`

`StatDirection = Fixed (Maybe SStat.Direction) | Responsive`, replacing
`direction : Maybe SStat.Direction`. `Responsive` emits daisyUI's own
`stats-vertical lg:stats-horizontal` idiom.

The type-level version was chosen over a `responsive : Bool` beside the old
field precisely so there is no combination where one silently wins over the
other. `.stats` is `grid-flow-col overflow-x-auto`, so a fixed horizontal row
of tiles scrolls sideways on a phone instead of wrapping — the finding
`e2e-findings` §4 records as new.

The `lg:` class is built, not typed: `Daisy.Render.tokenStatsHorizontalLg` is
`tokenLgPrefix ++ SStat.directionToClass SStat.Horizontal`, so renaming the
schema class renames it too and no daisyUI literal appears in `Render.elm`.
`tools/render-class-audit.js` gained two narrow rules for it: a bare Tailwind
variant prefix (`sm:`/`md:`/`lg:`/`xl:`/`2xl:`) is not a class and is exempt
from the "looks like a class, must be a token" check, and a `tokens` entry may
be a *derived* constant of the form `<variant prefix constant> ++ <Schema
call>` instead of a plain literal. `RenderPurityTest` needs no change: the
derived constant is in `Render.tokens`, so the emitted class is in budget.

### 6. `ariaLabel : Maybe String` on every bare control config

`SelectConfig`, `InputConfig`, `TextareaConfig`, `CheckboxConfig`,
`RadioConfig`, `ToggleConfig`, `RangeConfig`, `FileInputConfig` and
`RatingConfig`. Rendered by one helper, `Daisy.Render.ariaLabelAttrs`, which
keeps the existing behaviour when it is `Nothing`: the control's tooltip text
becomes its accessible name. A control inside a `Field` is named by its
wrapping `<label>`; one in a navbar or toolbar had nothing at all
(`e2e-findings` §4, axe `select-name`, critical).

### 7. Real validation constraints on `InputConfig`

`inputType : InputType` (`InputText | InputEmail | InputPassword | InputNumber
| InputUrl | InputTel | InputSearch | InputDate`, default `InputText`),
`required : Bool`, `pattern : Maybe String` (an HTML regex, never a class),
`minLength` / `maxLength : Maybe Int`. `TextareaConfig` gains `required`.

All render as the plain HTML attributes. daisyUI styles `validator` /
`validator-hint` through `:user-invalid`, which needs a real constraint on the
control, so before this a `Field { validate = True }` emitted both classes and
could never reveal the hint (`demo-findings` item 9).

### 8. Class-on-child misplacements

- **`timeline-box`.** `TimelineItem` gains `startBox : Bool` and `endBox :
  Bool`; the class goes on that side's `timeline-start` / `timeline-end`
  element. The container can no longer carry it at all:
  `TimelineConfig.modifiers` is now `List TimelineModifier`
  (`TimelineSnapIcon | TimelineCompact`), a narrowed type in the same style as
  `ButtonColor` omitting `Primary`, with `timelineModifierToSchema` widening it
  for the renderer. Closes 13 corpus rows (`timeline--00`..`--12`).
- **`list-col-grow` / `list-col-wrap`.** `ListRow.cells` is now `List (ListCell
  msg)` = `{ content : Leaf msg, grow : Bool, wrap : Bool }`, with a `listCell`
  helper for the plain case; a flagged cell gets its own wrapper element, an
  unflagged one renders as the bare leaf, so `list--00` is unchanged. Both of
  `list`'s modifiers were per-cell, which left `ListConfig` with no fields, so
  it is gone and `Block.ListBlock` takes only its rows — the same rule the
  "Configs" section above already applies to `Block.Form` and friends. Closes
  `list--01`, `list--02`.
- **`rating-hidden`.** `RatingData` gains `clearable : Bool`, which emits
  daisyUI's blank first radio. `RatingConfig.modifiers` narrows to `List
  RatingModifier` (`RatingHalf` only), so the container cannot carry the
  hidden class.
- **Rating star shape.** `RatingConfig` gains `shape : Maybe SMask.Style`
  (`Nothing` = the renderer's existing `mask-star-2`), and with `RatingHalf`
  the renderer alternates `mask-half-1` / `mask-half-2` across the radios,
  which is the only way daisyUI's half-star rating works. Closes `rating--00`,
  `--01`, `--03`, `--06`, `--07`.
- **`fab-main-action`.** `Fab` gains `mainAction : Maybe (Leaf msg)`, and the
  part class goes on that leaf itself (`leafWith [ fabMainActionPart ]`), which
  is where every daisyUI example puts it. The renderer no longer draws
  `Fab.main` twice: `main` is the trigger, `mainAction` is the button that
  stays put once the speed dial is open — two different elements in daisyUI's
  own markup. Closes `fab--07`, `fab--10`; `fab--09` stays rejected, its reason
  corrected to the real one (its main action is a `btn-primary`).
- **The filter's reset control.** `FilterData.reset` is now `Maybe
  FilterReset`, where `FilterReset = ResetPart | ResetButton (List
  SButton.Modifier)`. daisyUI has two idioms with different class sets: outside
  a `<form>` the reset carries the `filter-reset` part; inside one it is a
  plain `btn btn-square` and the browser's form reset does the work. Closes
  `filter--00`, `filter--02`.

### 9. Deliberately still inexpressible

Unchanged, and still in `fixtures/rejected.md`: corner placements (two
placement classes on one element — the spec's exclusivity rule forbids it),
`btn-primary` anywhere but `Page.cta`, cards inside `stack`, a card as
`dropdown-content`, `join-item` on a block, ~~`calendar`~~, `dropdown`+`menu`
on one element (the popover API), and a navbar inside `drawer-content`.

`calendar` is struck through: it became expressible on 2026-09-07, see
"Calendar via elm-cally" below. Its second docs example is still rejected, but
for the *dropdown-content* reason above rather than for being a calendar.

### 10. Corpus and test effect

`fixtures/rejected.md` went from 89 rows to 63; 587 corpus fixtures, 524 now
accepted. `tools/should-not-compile/` went from 20 to 21 fixtures.

### 11. What the demos do with them, and the one spec they moved

The three demos were recomposed onto the additions above (SPEC.md step 7 rows
unchanged: same shells, same block inventory, one `Page` each, five sections at
most, `last-msg: <Msg>` verbatim).

| Demo | Now |
|---|---|
| Admin | `Heading H1 "Revenue overview"` + `H2` per band; the line chart in a `Card` (`CardLeaf` caption + `CardChart`) and the orders table in a `Card` (`CardTable`), both with a `card-title`; the two card bands are `Stack { align = AlignStretch }`; the navbar switcher is `ThemeAsDropdown` over `Tree.allThemes` |
| Analytics | `Heading H1 "Acquisition"` + `H2`; one `Stat { direction = Responsive }` block of four items in a `Grid Cols1` (was four blocks in a `Grid Cols4`); bar, donut and area charts each in a `Card` with a `card-title`; the navbar select carries `ariaLabel = Just "Date range"` and the `Tooltip` workaround is gone |
| Settings | `Heading H1 "Workspace settings"`; the two form groups in `Card`s (`CardForm`) titled "General" and "Privacy"; contact email is `inputType = InputEmail, required = True` and workspace name `required = True, minLength = 2, maxLength = 60`, so `validator` / `validator-hint` can finally fire; the warning `Alert` moved to its own `Stack { align = AlignStretch }` section (`Sections5`) so it fills the band |

Three things worth recording:

- **`AlignStretch` and the CTA still do not mix.** `Demo.Settings` gained a
  fifth section rather than stretching its last one: under `Shell.Plain` the
  renderer appends `Page.cta` to the last section's container, so the warning
  band and the footer had to be two sections. The behaviour `demo-findings`
  item 2 describes is unchanged and is what the split works around —
  `docs/screenshots/demo-settings.png` shows the alert full width and the
  "Save changes" button still at its content width.
- **A `card` with no style paints nothing.** `defaultCardConfig` emits bare
  `card` + `card-body`, which on a `base-100` page is invisible: "the chart is
  in a card" did not read at all in the first regenerated screenshots. Every
  demo card therefore asks for `style = Just SCard.Border`. Composition only —
  no renderer or token change.
- **`Leaf.Heading` gives the outline, not the type scale.** The headings clear
  axe's `page-has-heading-one` on all three demos, which is what the leaf was
  added for, but they render at body size: `Block.Prose` emits `prose`, and the
  demo's Tailwind build has no `@tailwindcss/typography` plugin, so `.prose h1`
  has no rule and Preflight has already reset the heading. Not fixed here on
  purpose — the plugin also repaints `.prose` descendants with its own
  `--tw-prose-*` greys, which are not theme colours and would put the `contrast`
  spec's own assertion at risk in the dark themes. Recorded in
  `docs/demo-findings.md` as a new finding rather than papered over in `Render`.
  **Superseded by item 12 below**: the type scale is now fixed in `Render`
  instead.

### 12. `Leaf.Heading` gets a fixed type scale from `tokens`

Follow-up to item 1 and `docs/demo-findings.md` item 10 (now struck through).
`Leaf.Heading` still emits **no** daisyUI class — that part of the original
decision stands — but `Daisy.Render.headingHtml` now pairs each `HeadingLevel`
with a named size/weight token from `tokens` instead of leaving the rank to
`Block.Prose`'s Tailwind Typography styling, which the demo's Tailwind build
never loads: `H1` → `tokenHeading1` (`text-3xl`) + `tokenFontBold`
(`font-bold`), `H2` → `tokenHeading2` (`text-2xl`) + `tokenFontBold`, `H3` →
`tokenHeading3` (`text-xl`) + `tokenFontSemibold` (`font-semibold`, new). No
tree change, no new escape hatch — the fix is entirely inside the renderer's
closed token budget, and `RenderPurityTest`'s forbidden-utility list and
`tools/render-class-audit.js` both still pass. `docs/screenshots/demo-admin.png`
now shows "Revenue trend" and "Orders" ranked visibly above body copy.

#### The one Tier C fix the dropdown forced

| Spec | Symptom | Fix, in the smallest place |
|---|---|---|
| keyboard | `admin: Tab reaches every control in tree order` failed in all six projects: the expected sequence was collected from the closed page, but daisyUI hides `dropdown-content` with `display:none` until `:focus-within`, so tabbing to the trigger reveals the panel and the *next* Tab lands on the checked `theme-controller` radio — one stop the expectation did not have | `e2e/lib/browser.ts`: `collectFocusables` now adds daisyUI's own `dropdown-open` class to every `.dropdown` for the length of the collection and removes it again, so the expectation is the sequence a keyboard user actually walks. This **strengthens** the assertion — a dropdown whose panel could not be tabbed into now fails it — and no assertion was relaxed. Nothing in `Daisy.Tree` or `Daisy.Render` changed |

`e2e/interaction.spec.ts` gained `admin: the theme dropdown changes the page
theme`, which opens the trigger, clicks the `nord` radio and asserts both
`last-msg: ThemeChanged` and `data-theme="nord"` on the page root — the
`ThemeSelect` -> `onSelect` -> `Page.theme` round trip that `ThemeAsDropdown`
had no coverage for.

## Calendar via elm-cally (2026-09-07)

`calendar` was the one component `docs/placement.md` listed as **Excluded**,
on the grounds that its `component` classes are theming hooks for third-party
JS widgets. That was true of `react-day-picker` and `vc`, and it is still true
of them. It was not true of `cally`: `alexbruf/elm-cally` 1.0.0 is a pure-Elm
port of the Cally web component that renders the same element names and the
same `part` attributes in the **light DOM** — no ports, no custom element
registration, no shadow root. `Leaf.Calendar` therefore puts `cally` on a real
picker rather than on foreign markup, and the tree gained no escape hatch.

### 1. The tree

```elm
Leaf.Calendar (CalendarConfig msg) CalendarState

type alias CalendarConfig msg =
    { id : String
    , today : Date              -- justinmimbs/date, now a direct dependency
    , locale : CalendarLocale   -- EnGB | EnUS
    , months : CalendarMonths   -- OneMonth | TwoMonths
    , toMsg : CalendarMsg -> msg
    , onChange : CalendarValue -> msg
    }

type CalendarState                       -- the picker's own state, opaque
    = SelectDate CallyDate.Value CallyDate.Model
    | SelectRange CallyRange.Value CallyRange.Model
    | SelectMulti CallyMulti.Value CallyMulti.Model

type CalendarValue                        -- what onChange reports
    = PickedDate (Maybe Date)
    | PickedRange (Maybe ( Date, Date ))
    | PickedDates (List Date)

type CalendarMsg                          -- the picker's own traffic
    = CalendarDateMsg CallyDate.Msg
    | CalendarRangeMsg CallyRange.Msg
    | CalendarMultiMsg CallyMulti.Msg
```

Four shape decisions, and why each one is not the obvious alternative:

- **One leaf, three pickers.** `CalendarSelection` is not a field on the config
  — it *is* the state, because date/range/multi differ in what they remember as
  well as in what they select. A single closed variant type means the pair
  ("a range message applied to a multi picker") that would need a runtime error
  is simply not constructible from one `Leaf.Calendar`.
- **`onChange` is on the config, not on the state.** It has one type,
  `CalendarValue -> msg`, so the config stays a plain closed record and the
  state stays free of functions — which also keeps `CalendarState` comparable
  and storable.
- **`months : CalendarMonths`, not `Int`.** `months = 13` is not a calendar,
  and an `Int` would make the renderer decide what to do with it. Same rule as
  `GridColumns`.
- **elm-cally's `Config` is never exposed.** `Daisy.Render` builds it from
  `CalendarConfig`, exactly as it builds `terezka/elm-charts` attributes from
  `Daisy.Chart`. That is what keeps the `previous` / `next` slots — daisyUI's
  own chevrons — out of the author's hands.

`defaultCalendarConfig` is the one `defaultXConfig` that is a **function**
rather than a value: a picker has no meaning without an `id`, a `today` and
somewhere to send its messages. It takes the same four fields elm-cally's own
`defaultConfig` takes, and fills in `EnGB` / `OneMonth`.

### 2. The update flow, and where it lives

`Leaf.Calendar` is the second stateful leaf after `ThemeSelect`, and the first
whose state the application must actually keep (which day holds the roving
`tabindex`, which month is on screen). The four functions that go with it are
in `Daisy.Render`, not `Daisy.Tree`:

```elm
Daisy.Render.initCalendarDate  : CalendarConfig msg -> Maybe Date -> CalendarState
Daisy.Render.initCalendarRange : CalendarConfig msg -> Maybe ( Date, Date ) -> CalendarState
Daisy.Render.initCalendarMulti : CalendarConfig msg -> List Date -> CalendarState
Daisy.Render.updateCalendar    : CalendarConfig msg -> CalendarMsg -> CalendarState -> ( CalendarState, Cmd msg )
Daisy.Tree.setCalendarValue    : CalendarValue -> CalendarState -> CalendarState
```

`init` and `update` need the *same* elm-cally `Config` the view uses — the id
prefix drives `Browser.Dom.focus`, and `months` drives paging — and that record
holds `Html msg` in its `previous` / `next` slots. Building it in `Daisy.Tree`
would mean `Daisy.Tree` importing `Html`, which is exactly the layering the
package is built to avoid. `setCalendarValue` is pure data and stays in
`Daisy.Tree`.

### 3. Rendering, and where the class goes

daisyUI writes `.cally::part(container)`, `.cally ::part(day)` and so on.
`::part()` only matches a shadow tree; against elm-cally's light DOM both forms
mean the same descendant selector, `.cally [part~="x"]`. So the `cally` class
goes on a `<div>` **around** `<calendar-date>` rather than on it — which is
also where the docs example's `bg-base-100 border rounded-box` utilities sit,
so the corpus comparison is unaffected. `Daisy.Render` puts exactly one class
attribute on that wrapper and none anywhere inside; the picker's markup is all
`part` attributes.

The `previous` / `next` slots are filled with daisyUI's own chevron `<svg>`,
carrying an image role and the label elm-cally would otherwise have written as
text, so the two paging buttons keep an accessible name (axe's `button-name` is
clean on all six projects).

`TwoMonths` puts its two grids side by side. That took a container of the
renderer's own; section 7 below has the whole story.

### 4. Styling: two generated stylesheets

`tools/gen-cally-css.js` (bun) writes both, and both are **committed** —
small, deterministic outputs — with the generator authoritative. It runs in
`tools/ci.sh` between `should-not-compile` and `demo-build`, so drift from
`vendor/daisyui` or from the pinned elm-cally version shows up as a diff.
`vendor/` is never written to.

| File | What it is |
|---|---|
| `demo/cally-daisy.css` | daisyUI's `.cally { @layer daisyui.l1.l2.l3 { ... } }` block with every `::part(a b)` rewritten to `[part~="a"][part~="b"]`. Nesting, `:hover` suffixes, declaration order, values and the `@layer` are kept byte for byte; `/* ... */` comments are skipped, because daisyUI's own comment inside the block talks *about* `::part()`. |
| `demo/cally-base.css` | elm-cally's stylesheet, copied verbatim and wrapped in `@layer base`. Since elm-cally 1.1.0 the bytes come out of the package itself — see section 8 — and the source path, package version and the byte-comparison that verified them are in the header comment. |

The `@layer base` wrapper is the one non-mechanical thing the generator does,
and it is load-bearing: elm-cally's stylesheet is unlayered upstream, and
**unlayered rules beat every layered rule**. Without the wrapper elm-cally's
`background: transparent` and `background: var(--color-accent)` would win over
daisyUI's `--color-primary` "today" and `--color-base-content` "selected", and
the picker would keep its own black-and-white look inside a themed page. With
it, the built CSS orders the layers `properties, theme, base, components,
utilities, daisyui.*`, so daisyUI wins — verified in
`demo/dist/assets/*.css`, and visible in
`docs/screenshots/report/analytics-{light,dark,nord}.png`.

### 5. Tests

- **CoverageTest.** `unreachableClasses` went from five entries to four:
  `cally` is now emitted, `react-day-picker` and `vc` are not. Three
  `Leaf.Calendar` fixtures (one per picker kind, two locales, both month
  counts) were added to `tests/Helpers/Fixtures.elm`, on the fixed date
  `2026-09-07` — a fixture that rendered "today" would change what it emits
  every midnight, and `RenderPurityTest` compares two renders for equality.
- **RenderPurityTest.** elm-cally emits exactly two class names of its own,
  `vh` (visually hidden) and `num` (tabular numerals), and nothing else — the
  rest of its markup is `part` attributes. They are **not** added to
  `Render.tokens`: `tokens` is the list of utilities `Daisy.Render` itself may
  choose to emit, each with a named constant in `Render.elm`, and these two are
  the picker's, exactly like `elm-charts__*` inside `Block.Chart`. The existing
  chart exemption was therefore generalised to `fromLibrary`, and a third test,
  *"elm-cally contributes exactly the two classes it is exempted for"*, pins the
  exemption to that literal pair so a third name could not slip in behind it.
  The wrapper itself is still checked by the ordinary rule: it carries `cally`
  and nothing else.
- **ExclusivityTest.** `calendar` has no exclusive group at all, so there is
  nothing to contradict; a fuzzer entry was added anyway because the harness is
  one entry per leaf constructor, and it sweeps both closed fields across all
  three picker kinds so the row stays honest if `calendar` ever grows a group.
- **PartsTest.** Untouched — `Daisy.Schema.Calendar.parts` is empty.
- **CorpusTest.** `calendar--00` (daisyUI's Cally example) is now a tree.
  `calendar--01` stays rejected, with a corrected reason: the picker itself is
  expressible, but that example puts it inside a `dropdown` popover, and a
  dropdown's content is a closed `MenuSpec` — the same rule that already
  rejects a card as `dropdown-content`. 587 fixtures, 62 rejected (was 63),
  525 accepted.

### 6. One demo fix the picker forced

`Demo.Analytics` gained a "Date range" `Card` in the "Key metrics" band holding
a `SelectRange` calendar and a caption that echoes the picked range; `Main`
keeps the `CalendarState`, forwards `CalendarMsg` to
`Daisy.Render.updateCalendar` and writes the value back with
`Daisy.Tree.setCalendarValue`. `today` is the fixed date `2026-09-07`, not
`Time.now`, so the 105 theme baselines stay byte-identical from one day to the
next. The navbar `Select` stays, as SPEC requires.

| Spec | Symptom | Fix, in the smallest place |
|---|---|---|
| interaction | `analytics: picking a range sets last-msg: DateRangeChanged` failed in four of six projects | elm-cally's `update` batches the `onChange` callback with the `Browser.Dom.focus` call the roving `tabindex` needs, and that focus task comes back as *another* `CalendarMsg`. It lands after `DateRangeChanged` about half the time, so the debug pane raced between the two. `demo/src/Main.elm` now stamps the pane from `paneName : Msg -> Maybe String`, which returns `Nothing` for `CalendarMsg` alone: the pane reports the last message the *application* acted on rather than the last one the runtime delivered. Nothing in `Daisy.Tree` or `Daisy.Render` changed, and no assertion was relaxed — the test still requires the exact string. |

`e2e/lib/browser.ts` needed **no** behaviour change for the roving tabindex:
`collectFocusables` already filters `tabIndex >= 0`, and elm-cally gives
exactly one in-month day `tabindex="0"` and every other day `tabindex="-1"`.
Measured on `/analytics`: 30 day buttons, 1 tab stop, plus the two paging
buttons. The only edit is a comment recording that, so the next reader does not
"fix" the filter. The `keyboard`, `a11y` (zero serious/critical), `contrast`,
`overlap`, `overflow`, `responsive` and `layers` specs all pass unchanged; the
`contrast` classifier already exempts `[part~=head]`, whose `opacity: 0.5` sits
on the element rather than on the colour, so the collector measures the opaque
pair and it passes on its own merits.

### 7. `TwoMonths` side by side, and where that layout has to come from

The original decision above said `TwoMonths` stacks, on the grounds that
"daisyUI's `calendar.css` gives `part="months"` no layout of its own". That is
true, and it is not the whole reason. Measured on the built demo at 1440, the
`[part~=months]` element computes `display: block`, `width: 252px`, and its two
`calendar-month` children sit at the same `x` with 222px between their `y`s:

```
months        display: block   width: 252px
  calendar-month  x 313  y 467  w 252
  calendar-month  x 313  y 689  w 252
```

Nothing was fighting anything. Every candidate cause was checked and cleared:

- **Not the `@layer base` wrapping.** A layer can only change which of two
  competing declarations wins. There is no competing declaration: no rule in
  either generated stylesheet, in daisyUI's `calendar.css` or in elm-cally's
  `cally.css` selects `months` at all.
- **Not the `::part()` rewrite.** The rewrite is faithful; there is no
  `::part(months)` in daisyUI's `.cally` block to rewrite. Upstream Cally does
  not style it either — `calendar-base.tsx`'s `styles` covers `container`,
  `header`, `heading` and `button` and stops. Cally's *own docs* write
  `::part(months) { display: flex; gap: 1rem }`, in the example page's CSS.
  Multi-month layout is, upstream, the page's job.
- **Not the `.cally` wrapper width** (1102px at 1440, 293px at 375) and **not
  daisyUI's `.cally { font-size: 0.7rem }`**. Both leave a 252px grid at 252px.
- **Not a missing `flex-wrap`.** There is no flex container to wrap in.

So the layout is the renderer's to supply, and `Daisy.Render.calendarMonths`
supplies it — without a new escape hatch, and without inventing a daisyUI rule
that `vendor/daisyui` does not contain. elm-cally's picker `view` takes children
of type `Context msg -> Html msg` precisely so a consumer can wrap the grids in
its own DOM (that is the decision recorded in elm-cally's own `CLAUDE.md`), so
`TwoMonths` now passes **one** child: a `<div>` holding both `Month.view`s.

The div carries four tokens that were already in `Daisy.Render.tokens` —
`tokenGrid`, `tokenGridCols1`, `tokenGridCols2Sm`, `tokenGap` (`grid
grid-cols-1 sm:grid-cols-2 gap-4`). No token was added, no CSS rule was written
into either generated stylesheet, and `OneMonth` still renders the bare grid
with no wrapper at all.

**Grid, not flex, and that is forced.** daisyUI's own
`.cally calendar-month { width: 100% }` beats elm-cally's `inline-size:
fit-content`, so each grid is as wide as the line it is on. As *flex* items with
`flex-wrap`, each would claim a whole line and they would never sit side by
side — the wrap rule would guarantee the stacking it was added to fix. As *grid*
items they fill their track instead, and `grid-cols-1` below `sm` is what keeps
two 252px grids off a 375px viewport.

Measured after the change, same three viewports the Tier C matrix uses:

| Viewport | `.cally` width | Columns | `calendar-month` boxes | `scrollWidth` |
|---|---|---|---|---|
| 375 | 293px | 1 | x 57 y 874, x 57 y 1112 | 375 (no overflow) |
| 768 | 686px | 2 | x 57 y 850, x 325 y 850 | 768 |
| 1440 | 1102px | 2 | x 313 y 467, x 581 y 467 | 1440 |

`Demo.Analytics`'s "Date range" card therefore asks for `TwoMonths`, which is
what a range picker wants, and `docs/screenshots/demo-analytics.png` shows
September and October beside each other. The 35 `analytics-*` theme baselines
were regenerated (the other 70 are byte-identical); `overflow`, `overlap`,
`responsive`, `keyboard`, `a11y`, `contrast` and `layers` all pass unchanged, at
293 Playwright tests.

### 8. The stylesheet now comes out of the package

`demo/cally-base.css` used to be copied from `cally.css` at the root of the
elm-cally *checkout*, because the Elm registry publishes only `src/`,
`elm.json`, `README.md` and `LICENSE` and that file is none of them. elm-cally
1.1.0 fixes this at its own end: it exposes `Cally.Css`, whose
`stylesheet : String` is `cally.css` byte for byte, generated and staleness-
checked by that repo's `scripts/gen-css-module.mjs`.

`tools/gen-cally-css.js` now prefers that module, in this order:

1. `~/.elm/0.19.1/packages/alexbruf/elm-cally/<newest>/src/Cally/Css.elm` — the
   very code the demo compiles against. Only the newest installed version is
   considered: falling back to an *older* version that happens to have the
   module would style the picker with bytes the build does not use.
2. `~/elm-calendar/elm-cally/src/Cally/Css.elm` — where it is today, since
   1.1.0 is committed but not published.
3. `cally.css` from the cache or a checkout, so the script still works against
   elm-cally 1.0.0.

The Elm literal is decoded back to CSS by inverting elm-cally's escaping
(`\\` → `\`, `\"` → `"`, left to right), and when the checkout is present the
result is byte-compared against its `cally.css` — a stale generated module
fails the run instead of quietly changing the demo. Whichever source won is
recorded in the generated header, so the committed file says where its bytes
came from:

```
 * Source: ~/elm-calendar/elm-cally/src/Cally/Css.elm
 *         (checkout, `Cally.Css.stylesheet` decoded back to CSS)
 * Package: alexbruf/elm-cally 1.1.0 (local checkout)
 * Verified byte-identical to ~/elm-calendar/elm-cally/cally.css
```

The CSS body of `demo/cally-base.css` did not change by one byte; only those
header lines did. `elm.json` still asks for `alexbruf/elm-cally 1.x` and was
**not** bumped: 1.1.0 is not on the registry yet. Once it is published,
`elm install alexbruf/elm-cally` puts it in `~/.elm` and source 1 takes over on
its own, with no edit to this script — the header will then read
`(package cache, ...)` and name the installed version.

## Icons and surface tokens (2026-09-07)

The demos were meant to look like daisyUI's dashboard templates (SPEC.md step
7) and did not: no glyph anywhere, every panel the same white as the page, and
a table of bare strings. Three changes close that, and none of them opens the
tree.

### 1. `Daisy.Icon` and `Leaf.Icon`

`Daisy.Icon` is a **closed** set of 25 drawings (`Icon(..)`, `allIcons`,
`name`) and holds no path data, no markup and no class — the same split
`Daisy.Chart` has with `terezka/elm-charts`. The `d` attributes live in
`Daisy.Render.Icons`, which is **not** in `elm.json`'s `exposed-modules`, so an
application cannot reach them; `Daisy.Render.iconHtml` writes the five shared
`<svg>` attributes once and the size class comes from `tokens`.

The drawings are heroicons 2.2.0 **outline**, MIT, (c) Tailwind Labs, copied at
build time out of `demo/node_modules/heroicons/24/outline/<name>.svg`
(`Daisy.Icon.name` is that file name). heroicons is a `devDependency` of the
demo only: nothing at runtime, and `elm.json` gained no dependency.

An open `Icon String` — a path or an svg body from the caller — would have been
an escape hatch straight into the renderer's markup, which is the one thing
this package does not have. A closed set is why `Leaf.Icon` can be a leaf at
all.

- `Leaf.Icon IconConfig Icon`, where `IconConfig = { size : IconSize, label :
  Maybe String }` and `IconSize = IconSm | IconMd | IconLg` (`size-4` /
  `size-5` / `size-6`).
- **Accessibility is in the type.** `label = Nothing` renders `aria-hidden`,
  which is right for a glyph beside its own text; `Just` renders an image
  `role` plus that `aria-label`. Nothing else in the tree can produce a named
  icon, and nothing can produce an unnamed one that claims to be content.
- Icons where the templates put them: `MenuItem.icon` changed from `Maybe
  String` to `Maybe Icon` (it used to render the string in a `<span>`),
  `ButtonConfig.icon` and `Cta.icon` are new leading-icon fields, and
  `StatItem.figure` already took a `Leaf`, so `Leaf.Icon` works there with no
  change at all. Every new field is a `Maybe` defaulting to `Nothing`.
- `ButtonConfig.ariaLabel : Maybe String` came with them. An icon-only button
  (`icon = Just Eye`, label `""`) has no accessible name otherwise, and axe
  reports that as a **critical** `button-name` violation. It is the same field,
  with the same meaning, that `SelectConfig`, `InputConfig` and the other bare
  controls got in "Expressibility refinements" item 6.
- `Leaf.Icon` emits **no** daisyUI class, so `CoverageTest` is unchanged: the
  emitted set is still exactly `Schema.allClasses` minus the four unreachable
  entries.

### 2. Four surface tokens

`Daisy.Render.tokens` went from 43 to 47 entries. `rounded-box` was
considered and dropped: it is on `RenderPurityTest`'s forbidden list (and
daisyUI already rounds `.card`, `.stats` and `.navbar` itself). Opacity
variants such as `text-base-content/60` were dropped too — those are exactly
the pairs the `contrast` spec fails on.

| Token | Value | Where |
|---|---|---|
| `tokenBgGround` | `bg-base-200` | `drawer-content` under `Shell.Dashboard`, and the `<main>` under `Shell.Plain`. The page root keeps `bg-base-100`. |
| `tokenShadowSm` | `shadow-sm` | every `card` and every `stats` block |
| `tokenSizeIconSm` | `size-4` | `IconSm`, and the leading icon of every button |
| `tokenSizeIconLg` | `size-6` | `IconLg`, which is what a `stat-figure` uses |

Two existing tokens moved as well: `card` and `stats` now also carry
`tokenBgBase` (`bg-base-100`), and `navbarHtml` carries `tokenPadding`
(`p-4`).

**Why the renderer and not the demos.** daisyUI's `.card` paints neither a
background nor a shadow, and `.stats` paints nothing either — every docs
example writes `card bg-base-100 shadow-sm` and `stats bg-base-100 border ...`
/ `stats shadow` as utilities beside them. Leaving that to each caller means
every dashboard re-derives the same pair, and a caller cannot emit a class at
all in this package. Corpus fixtures compare `$$`-prefixed **daisyUI** classes
only, so adding Tailwind utilities to those two elements changes no corpus row.

**Why `p-4` on the navbar.** daisyUI pads `.navbar` by `0.5rem`, which is less
than the overhang of an `indicator-item`: daisyUI translates that part 50% of
its own width past the corner of the element it annotates. With a notification
badge on the last control of a wrapped `navbar-end`, that hung ~3px past the
viewport at 768 and gave the document a horizontal scrollbar
(`e2e/overflow.spec.ts`). `tokenPadding` is the gutter the `<main>` content
column already uses, so the chrome and the content now share one and an
out-of-flow decoration has room to sit in. Found by the spec, fixed in the
renderer, not worked around in a demo.

### 3. `CardChild.CardAlert` and `Row.cells : List (TableCell msg)`

Two typed additions the dashboard composition needed, both in the shape the
existing ones already have.

- **`CardAlert AlertConfig (List (Leaf msg))`** joins `CardLeaf`, `CardChart`,
  `CardTable`, `CardStat` and `CardForm`. "A warning inside a card" is the
  danger-zone idiom and was inexpressible. `Daisy.Render.cardChildHtml`
  dispatches to the very same `alertHtml` that `Block.Alert` uses (it was
  extracted out of `blockIn` for this), so an alert in a card and a bare alert
  are one markup rather than two. There is still no `CardCard`.
- **`TableCell msg = { leading : Maybe (Leaf msg), content : Leaf msg }`**, with
  a `tableCell` helper for the plain case. A cell with `leading = Nothing`
  renders as the bare leaf inside the `<td>` — byte for byte what a table cell
  always produced, so every corpus `table--*` row is unchanged — and only a
  cell that has one gets the flex wrapper daisyUI's own "table with visual
  elements" example puts around an `avatar` and a name. This is exactly the
  rule `ListCell` follows for `list-col-grow`: the flag is on the cell, and an
  unflagged cell is invisible in the output.

### 4. What the demos do with them

| Demo | Now |
|---|---|
| Admin | Sidebar items carry `Home` / `ChartBar` / `Cog` / `Document`. `navbar-start` is the brand plus a `type="search"` `Input` (`ariaLabel = "Search orders"`); `navbar-end` is an icon-only `Bell` button with an `error` `indicator` badge, the user `Avatar`, the theme dropdown, then the CTA, which now carries a `Download` glyph. The four stat tiles have `CurrencyDollar` / `ShoppingCart` / `Users` / `ArrowTrendingDown` figures and keep their `stat-desc` lines. Each orders row puts an `Avatar` in the customer cell's `leading` slot and an icon-only `Eye` button (`ariaLabel = "View order AC-…"`) in the action cell. |
| Analytics | Same sidebar icons; `navbar-end` is the date-range `Select`, the `Bell` button and the user `Avatar`, then a `Download` CTA. The four `Responsive` stat tiles gained `Users` / `ArrowTrendingUp` / `CurrencyDollar` / `ChartBar` figures. The three charts and the range picker stay in `Card`s. |
| Settings | `Sections5` is unchanged in count: the warning band became a **Danger zone** `Card` holding an `error` `CardAlert`, a line of prose and a `Trash` `btn-error` in `card-actions` — deliberately not primary, which the type system enforces (`Leaf.Button`'s colour type has no `Primary`). The CTA carries a `Check` glyph. |

Avatar portraits are inline `data:image/svg+xml` URIs, not files and not remote
photos: `e2e/themes.spec.ts` compares 105 full-page screenshots byte for byte,
so the image has to be present on first paint in every environment, with no
network and no font metrics involved (the drawing is pure geometry, no text).

### 5. `menu-title` is still out, and why

SPEC's dashboard look wants a section header above the sidebar navigation. It
was composed in, and then removed again: with it, `e2e/a11y.spec.ts` fails on
**admin** and **analytics** in both `light` and `dark` with
`color-contrast [serious] x1: .menu-title`. daisyUI paints `menu-title` at
`text-base-content/40` by design, which is the same reason
"Refinements from e2e" dropped it the first time. The sidebars therefore have
no title row; the brand still sits in the navbar. This is a daisyUI palette
decision, not a composition one, and fixing it would mean either editing
`vendor/daisyui` or emitting an opacity override from `Render` — the first is
forbidden, and the second is the contrast-fixme pair the token list
deliberately does not carry. Recorded in `docs/e2e-findings.md`.

### 6. One e2e exemption, and two new e2e tests

`e2e/lib/browser.ts` gained a **structural** exemption, in the same register as
the ancestor/descendant one it already had: a daisyUI `indicator-item` may
overlap the siblings inside its own `.indicator`, and an `.indicator` box may
have a `scrollWidth` wider than its `clientWidth`. Overlapping its sibling is
that part's entire definition — daisyUI positions it `absolute` and translates
it 50% onto the corner of the element it annotates, which is what a
notification count on a bell button *is*. The exemption is scoped to one
`.indicator` subtree, so an `indicator-item` still may not overlap anything
else on the page, and no other assertion was relaxed. (The *page-level*
consequence of that overhang was a real defect and was fixed in `Render`; see
"Why `p-4` on the navbar" above.)

`e2e/interaction.spec.ts` gained two tests, 12 across the six projects:
the notifications button is found **by role and accessible name**, shows `3` on
its `indicator-item` and fires `NotificationsOpened`; the row action is found
by its per-order name and fires `OrderViewed`. Both look the control up the way
axe's `button-name` rule does, so an icon-only button that lost its name would
fail them before it failed the a11y sweep.
