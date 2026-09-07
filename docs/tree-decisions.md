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

## Nexus design pass (2026-09-07)

The verdict on the previous demos was "it looks nothing like what's on
daisyUI". The reference chosen for this pass is daisyUI's own **Nexus**
e-commerce dashboard, <https://nexus.daisyui.com/dashboards/ecommerce>, at
1440. `Demo.Admin` is a deliberate recreation of that page; `Demo.Analytics`
and `Demo.Settings` follow the same shell, header, density and card rules with
their own content.

Nexus is daisyUI 5 plus a large amount of its own CSS (minified `tw-*`
utilities, a hand-written `.menu-item`/`.menu-label` sidebar, ApexCharts). What
was taken from it is the *daisyUI* half — `card`, `card-body`, `card-title`,
`stat*`, `badge badge-soft badge-<color> badge-sm`, `tabs tabs-box tabs-xs`,
`table`, `checkbox checkbox-sm`, `mask mask-squircle`, `menu` + `menu-title`,
`breadcrumbs`, `btn btn-sm btn-ghost btn-square/btn-circle`, `btn-outline`,
`drawer` — plus the measurements its own CSS produces, reproduced with
`Daisy.Render` tokens. The measurements taken off the live page: sidebar 256px,
navbar 64px, content gutter 24px, band gap 24px, card body 20px, card title
16px/500, metric label 14px/500, metric value 24px/600, metric caption 14px,
table 14px, thumbnail 30px, `tabs-box` 33px tall.

### 1. What the tree gained

Six additions, all closed, all `Maybe`/list-shaped so nothing existing had to
change its meaning.

| Addition | Shape | Why it could not be composed |
| --- | --- | --- |
| `Page.header : Maybe (PageHeader msg)` | `{ title, breadcrumbs : List (Leaf msg), actions : List (Leaf msg) }` | A title on the left and a `breadcrumbs` trail on the right is one row. `Section` is fixed at five constructors by the SPEC, and a `Grid Cols2` of `Prose` + `Breadcrumbs` renders as two equal columns with the trail floating in the middle of the second one. It is **not** a section: it is page chrome, like the navbar and the sidebar, so it costs none of the five-section budget and the shell decides where it goes — same place under `Plain` and under `Dashboard`. |
| `Shell.Dashboard (DashboardShell msg)` | `{ brand : Maybe Brand, sidebar : MenuSpec msg, sidebarFooter : Maybe (Leaf msg), navbar : NavbarParts msg }` | The sidebar is now a panel with three parts, not just a `menu`: a brand row above it and a user card pinned to the bottom. The width and the `bg-base-100` moved from the `menu` to the panel, because all three share them. `Brand = { icon : Icon, name : String }`. |
| `Leaf.UserChip (UserChipConfig msg) UserChipData` | `{ avatar, name, subtitle }`, config `{ boxed, onClick, dropdown, tooltip }` | Two stacked lines of text beside a portrait. A `Leaf` is terminal, so this needed either a container leaf — which would hand arbitrary layout back to the caller and undo the whole point of `tokens` — or one named composite. It is a named composite: three strings in, one fixed piece of markup out. `boxed` paints the `bg-base-200` panel a sidebar footer wants; a navbar chip leaves it off. |
| `CardParts.titleIcon` / `.headerTabs` / `.headerActions` | `Maybe Icon`, `Maybe (TabsSpec msg)`, `List (Leaf msg)` | Every dashboard card in Nexus has a header *row*: glyph and title left, a `Day \| Month \| Year` switch or a "Report" button right. `TabsSpec = { config : TabsConfig, tabs : List (Tab msg) }` mirrors `MenuSpec`, for the same reason: the `Block` constructor takes two arguments and a record field can only take one. A card with only a `title` still renders exactly the `card-title` heading it always did. |
| `StatItem.trend : Maybe (Leaf msg)` | rendered inside `stat-value` | The delta badge shares the number's baseline (`$587.54  +10.8%`). A `Leaf`, not a string, so it can be the soft badge daisyUI's own templates use. |
| `CardChild.CardChat` | `List (ChatMessage msg)` | Nexus's "Quick Chat" panel. `Block.Chat` already existed; this is the same renderer, reached from inside a card, like `CardTable` and `CardChart` before it. |
| `InputConfig.icon : Maybe Icon` | switches the element | daisyUI documents two shapes for a text field. Without an icon it is `<input class="input">`; with one the component class moves to a `<label>` and the glyph sits inside it beside a bare growing `<input>`. That is the navbar search field, and the `<label>` wrapper is also what keeps the control named. |

`Tab` did not change, but `Daisy.Render` now omits the `tab-content` panel for
a tab whose `content` is empty. daisyUI shows the panel that follows the active
tab, so an empty one behind the active tab of a `tabs-box` segmented control
opened an empty block inside the card header row. A tab with no content owns no
panel — which is what makes `tabs-box` usable as a control rather than a tab
set.

### 2. What `Daisy.Render` gained

Twelve tokens in, one out: 47 -> 58. Each is one decision the library makes on the caller's
behalf, not a utility the caller can reach:

| Token | Value | Job |
| --- | --- | --- |
| `tokenGapMd` | `gap-6` | The single vertical rhythm between the bands of a page (24px, Nexus's figure). `tokenGap` (16px) stays the rhythm *inside* a band; `tokenGapLg` (32px) stays the footer's. |
| `tokenPaddingLg` | `p-6` | The content column's gutter, 24px. `tokenPadding` (16px) stays the chrome's, because a 24px navbar would be taller than the 64px row every dashboard template uses. |
| `tokenTextXs` | `text-xs` | The caption step: a chart legend, a user chip's handle. |
| `tokenTextBase` | `text-base` | A `card-title` in a dashboard, one step down from daisyUI's 1.25rem/600. |
| `tokenTextMuted` | `text-base-content/60` | De-emphasised body text — the very colour daisyUI paints `.stat-title` and `.stat-desc`, written as a utility so the renderer can reach it on an element that is neither. |
| `tokenFontMedium` | `font-medium` | The label weight of the whole density scale. |
| `tokenRoundedLg` | `rounded-lg` | The 8px corner of the small surfaces the renderer paints itself. |
| `tokenGridCols2Lg` | `lg:grid-cols-2` | The breakpoint a two-column `Grid` steps at (below). |
| `tokenGrow` / `tokenShrink0` / `tokenMtAuto` | `grow` / `shrink-0` / `mt-auto` | The three flex behaviours the new panels need: the menu takes the sidebar's slack, the header's right group keeps its width, the footer sits at the bottom. |
| `tokenJustifyCenter` | `justify-center` | Centres a chart legend under its chart. |
| `tokenSizeAvatar` | `size-8` | A portrait: 32px, daisyUI's own figure for an `avatar` in a navbar, a table row or a chat bubble. It replaces `size-5`, which was too small for all three. |

`tokenHiddenLg` (`lg:hidden`) was **removed** — the drawer toggle is now offered
at every width (below) and nothing else used it — so the table is 47 + 12 - 1 =
58.

One token was tried and **rejected**: `whitespace-nowrap` on table cells, to
keep a date on one line the way Nexus's table does. `Block.Table` is inside an
`overflow-x-auto` box, so the table would scroll rather than reflow — but a
table that can no longer shrink renders at its min-content width, and a *rect*
that wide reaches over the panel beside it in a two-column band even though
nothing is painted there. `e2e/overlap.spec.ts` measures rects, and it was
right to: the honest fix is a table that fits, so the demo's dates read
`25 Jun` and the cells wrap when they must.

`tests/RenderPurityTest.elm`'s `forbidden` list lost three entries — `gap-6`,
`text-xs`, `rounded-lg` — each because it became one of the named tokens above.
`rounded-box` **stays** forbidden: it resolves to `--radius-box`, which is 1rem
or more in daisyUI's stock themes, so the 36px `stat-figure` tile would come
out a circle. Nexus overrides `--radius-box` to 4px before using it there; a
package cannot. `opacity-50` also stays: a blanket `opacity-*` dims an element
*without* changing its computed `color`, which is invisible to
`e2e/contrast.spec.ts`'s classifier — a de-emphasis that fails contrast and
reads as passing. `tokenTextMuted` is the honest form of the same thing.

### 3. Renderer behaviour that changed for everyone

- **`stat` type scale.** `.stat-title`/`.stat-desc` are 0.75rem and
  `.stat-value` is 2rem/800, which is a hero number. A tile in a four-across
  metric row now reads at `text-sm font-medium` / `text-2xl font-semibold` /
  `text-sm`. The de-emphasised **colour** is left to daisyUI, which is the
  point: it stays a pair `contrast.spec.ts` classifies as daisyUI's own.
- **`stat-figure` is a tile.** `bg-base-200`, `rounded-lg`, `p-2` around the
  glyph, which is what turns four numbers into the header band the templates
  open with.
- **`stats` inside a card paints no panel.** `BlockContext` gained `InCard`;
  `CardStat` renders without `bg-base-100 shadow-sm`, because the card is
  already that panel and a second one nested in it reads as a box in a box.
- **`card-title` is 1rem/500** (above), and the header row is emitted only when
  something is in it.
- **Charts carry a legend.** A row of daisyUI `status status-<color>` dots and
  series names under the drawing, built from the same eight semantic colours
  `Daisy.Chart.SemanticColor` offers, so the dot and the line it labels are the
  same CSS variable. elm-charts can draw a legend inside the SVG, but an SVG
  legend cannot be themed by a daisyUI class and cannot wrap.
- **The drawer toggle is visible at every width.** It used to be `lg:hidden`,
  on the grounds that `lg:drawer-open` docks the sidebar from `lg` up so the
  control has nothing left to do. Every daisyUI dashboard template keeps it as
  the left-most control of the navbar anyway, and the row reads as broken
  without it. Above `lg` it is inert: `lg:drawer-open` wins over the checkbox.
  `e2e/responsive.spec.ts` asserts both halves.
- **`Section.Grid Cols2` steps at `lg`, not `sm`.** `Cols3` and `Cols4` still
  step at `sm`, because their cells are tiles. A two-column band's cells are
  *panels* — a card with a table in it, a form group — and at 768 a half of the
  content column is 304px of card body, which is narrower than the min-content
  width of a six-column orders table. The table then rendered wider than its
  own card and reached over the panel beside it.
- **The gutter between the controls of a navbar part is `gap-4`, not `gap-2`.**
  An `indicator-item` reaches half its own width past the corner of the control
  it annotates — about 8px for a `badge-xs` — so an 8px gap let the
  notification badge sit on top of the next control in the row. Same reasoning,
  one scale down, as the `p-4` on the navbar itself.
- **The page header's breadcrumbs are a direct child of the row when there are
  no actions beside them.** daisyUI gives `.breadcrumbs` `margin-inline-start:
  -.25rem` and its `<ul>` a matching `padding-inline-start`, so the element's
  outer width is 4px less than its content — and since it is also `max-width:
  100%; overflow-x: auto`, a parent sized to that outer width clips the last
  4px of the last crumb. A parent that is the whole row cannot.

### 4. Nexus residuals

Every item below was a deliberate gap at the end of this pass. All of them were
closed in the **charts and fidelity** pass that follows; the "Closed by" column
says how, and the two that were *not* closed say why.

| Residual (2026-09-07, Nexus pass) | Closed by |
| --- | --- |
| The active sidebar item is daisyUI's solid `menu-active`, not Nexus's tinted row. | `MenuConfig.activeStyle = SolidActive \| TintedActive`. Tinted emits `bg-base-200 font-medium` and no `menu-active`; measured off Nexus at 1440 (`background-color` = base-200, `font-weight: 500`, `color` = base-content). `SolidActive` stays the default and is still the only way to reach `menu-active`. |
| The theme switcher is a full-size `btn` reading "Theme"; Nexus's is an icon-only ghost circle. | `ThemePresentation.ThemeAsIconDropdown`, a second constructor rather than a flag — `tests/CorpusTest` pins `ThemeAsDropdown`'s trigger class for class, and a flag would have made that fixture depend on the flag. All three dashboards use it. |
| `Page.cta` is in the navbar; Nexus's navbar has none. | `Cta.placement : CtaPlacement = InNavbar \| InHeader \| InSidebarFooter`. Admin, Analytics, Settings and the generator all put theirs `InHeader`, beside the breadcrumbs, which is where Nexus puts a page's action. Still exactly one primary button, still placed by the shell. |
| Column splits are 50/50; Nexus's are 7:5 and 3:2. | `GridSection.Spans` — the twelve-column grid, one `Span3..Span12` per cell. Admin's chart row is 7:5, exactly Nexus's (`repeat(12, 72.66px)`, `gap: 24px`, 7 + 5). |
| Cards are 24px-padded, not Nexus's 20px. | `CardConfig.padding = PaddingDefault \| PaddingDashboard`. `PaddingDashboard` is `p-5`; measured `padding: 20px` on Nexus's `.card-body`. |
| No border on the navbar or the sidebar. | `DashboardShell.edges : Bool`, on by default. `border-b` / `border-r` + `border-base-300`, three named tokens with one use site each. `border` — all four sides on an arbitrary element — **stays** on `RenderPurityTest`'s `forbidden` list; a one-sided rule on chrome the renderer owns is a different thing. |
| `stat-figure` floats level with the number, not with its label. | `tokenSelfStart` on the figure tile. daisyUI centres it over the tile's whole height; Nexus's sits on the label's line. |
| `Demo.Settings` shows its title above its `Navbar` section. | The `Plain` shell now inserts `Page.header` **after** any leading `Section.Navbar` bands. A title above a site navbar reads as a title for the site. |
| The bottom row is 3:2 in Nexus. | **Not closed exactly.** Twelve tracks cannot express 3:2 (it is 7.2 : 4.8), so Admin's bottom band is 7:5 — 654px and 458px against Nexus's 682 and 430 at 1440, a 28px difference in a 1136px column. The alternative was a second `GridColumns` value for five equal tracks, which would exist for one band on one page. |
| The sidebar is short (five entries against Nexus's twenty). | **Not closed, and still deliberate.** The rest of Nexus's list would be dead links, and a dead link in a demo is worse than a short list. |

### 4a. The position at the end of that pass

The bullets that used to stand here are the "Residual" column of the table
above, now with their answers beside them; only the last two are still open,
and both say why. Kept as a table rather than deleted because "what a
recreation deliberately did not do" is the part of a design pass that is
otherwise lost.

### 5. What the e2e suite gained (and what it waived)

Two specs were changed to match a deliberate design change, and two exemptions
were added. Nothing was relaxed to make a run pass.

- **`e2e/responsive.spec.ts`** used to assert that the drawer toggle is *hidden*
  at `lg` and up. It now asserts that the toggle is visible at every width, that
  below `lg` it opens the sidebar, and that at `lg` and up the sidebar is docked
  and stays docked when the toggle is used. That is the changed requirement,
  asserted in both directions rather than dropped.
- **`e2e/keyboard.spec.ts`** keeps its "four sidebar links, each focusable"
  assertion; only the comment changed, to say that the count is of *links* and
  that the `menu-title` rows beside them are `<li>`s.
- **`e2e/lib/browser.ts`**'s contrast classifier learned two more shapes of
  "daisyUI's own colour pair" — the `*-soft` `color-mix` recipe, and
  `--color-base-content` over `--color-base-300` (a surface `tokens` cannot
  paint, so both sides came from a daisyUI rule) — and one bug in it was fixed:
  `opaqueOf` divided the alpha back out of an 8-bit canvas value without
  clamping, which pushed `--color-base-content` at 40% above the sRGB gamut and
  made `.menu-title` fail to classify at all. `docs/e2e-findings.md` section 1
  has all four shapes and the reasoning for each boundary.
- **`e2e/a11y.spec.ts`** waives the `color-contrast` rule, and only that rule,
  on nodes whose class list contains `menu-title`, `tab` or `badge-soft` — the
  three daisyUI de-emphasised pairs this composition reaches, in the three
  places the Nexus template itself uses them. It is a node filter, not an
  `exclude()`, so those elements still answer for every other rule.

Three defects the suite caught during the pass were fixed at the root rather
than waived:

- `aria-prohibited-attr` (serious) on the drawer toggle: a `<label>` has no
  implicit ARIA role, so `aria-label` on it is prohibited. The name moved onto
  the glyph inside it (`IconConfig.label`), which names the label by content.
- `scrollable-region-focusable` (serious) on the two-tile `stats` inside the
  "Customer Acquisition" card: `.stats` is `grid-flow-col overflow-x-auto`, so
  at 375 it became a scrollable region no keyboard could reach. It is
  `StatDirection.Responsive` now — daisyUI's own `stats-vertical
  lg:stats-horizontal` — so it stacks instead of scrolling.
- The last crumb of a `breadcrumbs` trail was clipped by 4px when it was the
  only thing in the page header's right-hand group (daisyUI's negative
  `margin-inline-start` against its `max-width: 100%`). The renderer now puts
  the trail directly in the header row when there is nothing beside it.

## Custom themes and the generator page (2026-09-07)

Until this pass `Page.theme` could only name one of the thirty-five themes
daisyUI ships. That is a real limitation: daisyUI's own theme format is a
closed list of twenty-nine declarations, an application's brand colours are
exactly such a list, and there was no way to say one. `Theme` gained a
`Custom CustomTheme` constructor, and a fourth demo — the theme generator at
`/theme` — was built to prove the whole path works.

### 1. The theme API

Nine new types in `Daisy.Tree`, all closed, and one new module beside it.

| Addition | Shape | Why this shape |
| --- | --- | --- |
| `Theme.Custom CustomTheme` | one more constructor | `allThemes` deliberately stays the thirty-five built-ins: there is no list of every custom theme, because a custom theme is a value the application makes up. `themeToString` answers with the custom name. |
| `CustomTheme` | `{ name, colorScheme, colors, radius, size, border, depth, noise }` | The same twenty-nine declarations `vendor/daisyui/packages/daisyui/src/themes/*.css` carries, and nothing else. Every one of the thirty-five files was checked: the property set is identical across all of them, so the record is exhaustive rather than a subset. |
| `ThemeColors` | twenty `Oklch` fields | daisyUI's twenty `--color-*` variables, in daisyUI's own order. |
| `Oklch` (`Daisy.Color`) | `{ l, c, h }` | `l` is **lightness in percent**, 0..100, not the 0..1 the OKLab literature uses. That is the unit daisyUI prints (`oklch(62% 0.265 303.9)`), and its own sources carry values like `11.784%` — keeping the number in the unit it is printed in is what makes a theme read out of the oracle and printed back byte-identical. `0.11784 * 100` in IEEE 754 is `11.783999999999999`. |
| `Radius` | `RadiusNone`/`Xs`/`Sm`/`Md`/`Lg` | The five steps daisyUI's own generator offers, verified by reading its radio inputs at 1440: `0rem`, `0.25rem`, `0.5rem`, `1rem`, `2rem`. The thirty-five stock themes use only these five. A free `Float` would let a theme say something no daisyUI theme says. |
| `Size` | `SizeXs`..`SizeXl` | The generator's five-position "base size" slider: 3px, 3.5px, 4px, 4.5px, 5px, written `0.1875rem` .. `0.3125rem`. Every stock theme is `SizeMd`. |
| `Border` | `BorderHairline`/`Thin`/`Medium`/`Thick` | `0.5px`, `1px`, `1.5px`, `2px`. Stock themes use `1px` and `2px`. |
| `ColorScheme` | `LightScheme`/`DarkScheme` | The `color-scheme` property, which is what the browser paints its own UI from. |
| `ThemeName` | opaque | Built by `themeName : String -> Maybe ThemeName`, which accepts `[a-z][a-z0-9-]*` and refuses all thirty-five reserved names. There is no other constructor, so an invalid name is *unrepresentable* rather than caught. `themeNameOf : Theme -> ThemeName` is the one way to reach a built-in's reserved name — reserved is reserved against *new* themes, not against reading the built-in ones back. |
| `depth` / `noise` | `Bool` | daisyUI's two effect switches. Its component CSS only ever multiplies them by something inside a `calc()`, and its own themes only ever write `0` or `1`, so a `Bool` is the honest type and the renderer prints the digit. |

Three functions turn one into text, all pure strings with no class in them:
`customThemeProperties` (the twenty-nine `( property, value )` pairs, in
daisyUI's order), `customThemeToCss` (the `@plugin "daisyui/theme" { ... }`
block daisyUI's docs ask for) and `customThemeToJson` (the exact shape
daisyUI's *own* generator round-trips through its URL). The last one is in the
package rather than in the demo because it is written from the same facts the
first two are, and two copies of the property list would drift.

`should-not-compile` gained `Reject/ThemeNameFromString.elm`: a `Custom` whose
`name` is `"acme"` is a `TYPE MISMATCH`. The fixture the task sketched — "a
`ThemeName` built from a raw string" — cannot be written at all, which is the
stronger statement; the fixture that *can* be written is the one that shows
`Custom` needs a `ThemeName` and not a `String`.

### 2. `Daisy.Themes`, generated

`tools/gen-themes.js` reads the thirty-five theme files out of the pinned
oracle and writes `src/Daisy/Themes.elm`: one `CustomTheme` value per built-in
plus `builtinToCustom : Theme -> Maybe CustomTheme` and `all`. It is a `ci.sh`
step (`gen-themes`, right after `gen-schema`) that regenerates the file and
fails on a diff, so a drift from `vendor/daisyui` shows up as a red pipeline
rather than as a stale table.

A `Theme` constructor is a *name* — it selects a rule daisyUI already ships and
there is nothing in it to read. An editor needs the other thing, so that "start
from `nord` and change the primary" is one record update rather than
twenty-nine values retyped. `tests/ThemeTest.elm` pins the round trip against
`light.css` verbatim.

**It is `Daisy.Themes`, not `Daisy.Schema.Themes`.** `tools/gen-schema.js` owns
`src/Daisy/Schema/` outright: it `rmSync`s the whole directory before writing
and rebuilds `elm.json`'s `exposed-modules` from its own component list, so a
module of ours in there would be deleted by the next regeneration and dropped
from the package. The name is also the more honest one — the `Schema.*` modules
are class tables and this one holds no class at all.

### 3. How a custom theme reaches the page, and the bug that nearly hid it

`Daisy.Render.page` writes `data-theme="<name>"` as before, and for a `Custom`
theme adds the twenty-nine declarations as inline CSS custom properties on the
same element. That is enough on its own — **no `@plugin "daisyui/theme"` block
is registered anywhere in `demo/app.css`** — because daisyUI never reads those
variables where they are *defined*: every use in its component CSS is a
`var(--color-primary)`, a `color-mix(... var(--color-base-content) ...)` or a
`calc(var(--depth) * 30%)` in a declaration on the component itself, and none of
them is registered with `@property { inherits: false }` (`src/base/properties.css`
registers exactly two properties, neither of them ours). A definition on an
ancestor therefore reaches every component below it exactly as a `[data-theme]`
rule would.

The first implementation wrote one `Html.Attributes.style "--color-primary" ...`
per property, and **it silently did nothing**. `elm/virtual-dom` applies a style
node with `element.style[key] = value` (the compiled bundle's
`function Mn(e,t){var n=e.style;for(var r in t)n[r]=t[r]}`), and a
`CSSStyleDeclaration` ignores an assignment to a `--*` name — custom properties
need `setProperty`, which Elm never calls. The page rendered `data-theme="acme"`
with `light`'s colours, which looks plausible enough to ship. `Daisy.Render`
now emits **one** `Attr.attribute "style"` built by
`Daisy.Tree.customThemeStyle`; `setAttribute` hands the string to the CSS
parser, and the declarations take effect.

Verified in Chrome against the built demo, on the page root and on the
components below it:

| Read back | `?theme=acme` | Why it is the interesting one |
| --- | --- | --- |
| `--color-primary` | `oklch(62% 0.265 303.9)` | the value `Demo.Themes.acme` holds, not `light`'s |
| `color-scheme` | `light` (and `dark` when the editor's scheme toggle is on) | a plain property, not a custom one |
| `--radius-box` | `0.5rem`, and the `.card`'s computed `border-radius` is `8px` | daisyUI consumed it |
| `--border` | `1px`, and the `.btn`'s computed `border-top-width` follows it | |
| `--depth: 0` | the CTA's `box-shadow` alphas are all `0` (`oklch(1 0 0 / 0)`, `oklab(0 0 0 / 0)`), against `dark`'s real `0.06`/`0.3` | daisyUI multiplies `--depth` into three shadow alphas, so this is the sharpest proof that an *effect* switch inherits, not just a colour |
| `--noise` | `0` / `1` through the editor's toggle | |
| `.bg-primary` swatch | background `oklch(0.62 0.265 303.9)`, colour `oklch(0.98 0.031 120.757)` | a Tailwind utility over the variable, not a daisyUI component class |

`e2e/theme-generator.spec.ts` asserts all of that, including that the root
carries exactly 29 declarations in one `style` attribute — which is what would
catch a regression back to the per-property form.

Nothing needed a static `@plugin` block. The only reason to add one would be a
page that daisyUI has to style before Elm boots, which is not this demo.

### 4. `Leaf.Swatch`, and the one entry that left `forbidden`

A theme editor has to *show* the colour it is editing, and daisyUI has no
component for that: every colour class it ships belongs to a control. So
`Leaf.Swatch SwatchConfig SwatchColor String` — `SwatchColor` is a closed
eleven-value slot name (`base-100/200/300` plus the eight semantic colours) and
`Daisy.Render.swatchClasses` maps each to one `bg-*` / `text-*-content` pair.
Eleven surfaces, not twenty: a swatch shows a surface with its matching content
colour *on* it, so the nine `-content` colours are reached as foregrounds rather
than as surfaces of their own.

That is eighteen new tokens (`bg-base-300`, `text-base-content`, and a pair per
semantic colour), the only *colour* tokens in the table: 58 -> 76. Everywhere
else the renderer leaves colour to daisyUI's component classes, because a
component carries its own pair; a swatch is not a component, so the pair has to
be named.

`tests/RenderPurityTest.elm`'s `forbidden` list therefore lost exactly one
entry, `bg-primary`, by the rule that let `gap-6`, `text-xs` and `rounded-lg`
leave it in the Nexus pass: it became one named constant with one job and one
use site, not room for a sprinkled utility. **`text-primary` did not follow it**
and stays forbidden — it is a foreground utility over an arbitrary element,
which is exactly what the list exists to prevent, and no swatch wants it: a
chip's foreground is `text-primary-content`, the colour daisyUI itself pairs
with that surface.

### 5. `Daisy.Color`

`hexToOklch` / `oklchToHex`, Björn Ottosson's two matrices with the sRGB
transfer function either side of them. It is a package module rather than a
demo one because the conversion is what any daisyUI theme editor needs and it
has nothing to do with the demo.

Two things worth recording:

- **OKLCH is much larger than sRGB.** 151 of daisyUI's own 700 theme colours are
  outside it. `oklchToHex` clamps each linear channel rather than failing, which
  is what a browser does with the same colour, and `tests/ColorTest.elm` says so.
- **The round trip is exact in one direction only.** `hex -> OKLCH -> hex` is
  the identity for all 16.7 million sRGB colours (fuzzed). *(It was not, quite,
  until the charts-and-fidelity pass: `hexToOklch` kept four decimals of
  lightness and chroma and two of hue — daisyUI's own printed precision — and at
  high chroma a hundredth of a degree of hue is more than half of one 8-bit
  channel step, so about six colours in ten thousand came back one LSB out
  (`#03defb` -> `#02defb`). The fuzzer found it as an occasional failure rather
  than never. It keeps five and three now, verified over 300k colours plus every
  grey and every 0/1/127/128/254/255 corner; the fix is precision, not a
  tolerance.)* The other direction
  loses a byte per channel, and at low chroma a byte is a large *angle*: at
  `c = 0.03` it is up to 3.5 degrees of hue. The fuzzer's box (`L` 45..75,
  `C` 0.03..0.05) was swept at a quarter-degree against an independent
  implementation to establish both that nothing in it clips and what the real
  bounds are; the greys, where hue stops meaning anything, are pinned by exact
  known-value tests instead.

### 6. The generator page

`/theme`, `Demo.ThemeGenerator`, in the same Dashboard shell as the other two
dashboards — all three sidebars gained a `Tools` group with the entry, so the
chrome is identical on every route. Four sections: colours + palette, shape and
effects + a component preview, chart and table + export, then the CSS block and
the debug pane.

Three decisions worth naming:

- **The page renders under the theme it is editing**, because there is nowhere
  else for it to render: `Page.theme` is one field and the router keeps one
  theme. The sidebar, the navbar and the editor's own controls are repainted by
  the same declarations the preview is, so a colour that does not work is
  visible in the chrome as well as in the swatch. Edits survive navigation for
  the same reason — `Model.theme` was already shared.
- **`data-theme` on this page is always `acme`**, even when "Start from" says
  `nord`: `Demo.Themes.rename` gives the copied values the demo's own name. No
  stylesheet declares `acme`, so every colour on the page can only have come
  from the inline properties. `e2e/lib/daisy.ts`'s `rootThemeOf` is that rule,
  in one place, and `themes.spec.ts` reads it rather than assuming `?theme=X`
  means `data-theme=X`.
- **Every edit is one value of a closed `ThemeEdit` type**, applied by
  `ThemeGenerator.apply`. The alternative — a `Msg` per control, or a `Msg`
  carrying a function — would have put twenty-odd constructors in `Main` for one
  page. `Main` has two: `ThemeEdited ThemeEdit` and `ThemeExported`.
  "Randomize" carries no seed; the router keeps the counter, so the page stays a
  pure function of the model and the screenshots stay byte-stable.

### 7. The port contract

Three ports, all in `demo/src/Ports.elm` (a `port module` with no `Html`
import, so `NoHtmlInDemo` applies to it unchanged) and implemented in
`demo/src/main.js`:

```
port copyToClipboard : String -> Cmd msg      -- navigator.clipboard.writeText
port encodeTheme     : String -> Cmd msg      -- the theme's JSON in
port themeEncoded    : (String -> msg) -> Sub msg   -- the generator URL back
```

`encodeTheme`/`themeEncoded` are a pair rather than a function because the
compression is a *stream*. daisyUI encodes a theme into its own URL as
`https://daisyui.com/theme-generator/#theme=<base64url(zlib-deflate(json))>`,
and `CompressionStream("deflate")` is the zlib wrapper (RFC 1950) — which is
what those hashes are: every one of them starts `eJx`, the bytes `0x78 0x9c`.
(`"deflate-raw"` would be RFC 1951 and would not decode.) A stream cannot be a
synchronous function returning a value to Elm, so the answer comes back on a
second port; the anchor shows the bare generator URL until it arrives, which is
still a working link.

Verified in both directions:

- a hash the **live** generator produced for its own `light` theme was inflated
  with `node:zlib` and is exactly `{"name":...,"color-scheme":...,29
  declarations...,"default":false,"prefersdark":false}` — which is what
  `customThemeToJson` writes, key for key and in the same order;
- the hash the demo produces for `acme` was inflated the same way and equals the
  JSON the user's generator link carried, byte for byte. `e2e/theme-generator.spec.ts`
  repeats that in the page with `DecompressionStream`, and also asserts the key
  order, not just the key set.

### 8. What the e2e suite gained, and the two root causes it found

`e2e/lib/daisy.ts` now lists four demos and thirty-six themes, so
`themes.spec.ts` is 4 x 36 = **144 baselines** (was 105) and the contrast and
chart-colour sweeps cover the custom-theme path as well.
`e2e/theme-generator.spec.ts` is new: eight tests covering the inline
properties, a built-in opened as an editable theme, a colour edit repainting the
root and the CTA and the export, the shape controls, the generator hash, the
palette chips and the edit surviving navigation.

Two defects the matrix found on the new route were fixed at the root:

- `scrollable-region-focusable` (serious) on the two-tile `stats` at 375 — the
  same one `Demo.Admin` hit, same fix: `StatDirection.Responsive`.
- `scrollable-region-focusable` (serious) on `.mockup-code`. daisyUI's
  `.mockup-code` is `overflow-x: auto` around a `<pre>` of `width: max-content`,
  so any line longer than the container makes it a scrollable region — and the
  block holds only text, so there is nothing inside it to receive focus. Fixed
  in **`Daisy.Render`**, for every user of the package, not in the demo:
  `MockupCode` now emits `tabindex="0"` with `role="group"` and a name. The
  stretch that exposed it was a second root-cause fix — the export band is
  `Stack { align = AlignStretch }`, because a `mockup-code` sized to its content
  is ~500px wide and gave the *document* a horizontal scrollbar at 375.

Two composition choices were changed rather than waived: the preview's alerts
are solid `alert-<color>` and not `alert-soft` (soft is a `color-mix` pair the
composition derives; solid is daisyUI's own `--color-X` / `--color-X-content`),
and the export link is a plain `link` and not `link-primary` (`--color-primary`
as a *foreground* over `--color-base-100` falls under 4.5:1 in several themes,
and this page draws itself under deliberately bad ones).

One waiver was added, and it is the *existing* position made consistent rather
than a new exemption. `e2e/a11y.spec.ts` already waived `color-contrast` on
daisyUI's three de-emphasised pairs by class list; it now also waives it on
daisyUI's **emphasised** pair — `--color-X` under exactly its own
`--color-X-content` — decided in the browser on painted sRGB bytes, which is the
same mechanical rule `e2e/contrast.spec.ts` has applied from the start and which
SPEC.md's "what is deliberately not tested" puts outside Tier C. It matters here
because the generator page's job is to show a theme's pairs including the bad
ones: `acme`'s own `--color-secondary` / `--color-secondary-content`, which
daisyUI's generator derived, is 1.9:1. A `-content` colour over the wrong
surface, or a `color-mix` background, still does not match and still fails.


## Charts and fidelity (2026-09-07)

The verdict on the previous pass was that the recreations have to be "basically
perfect". This pass closes the residuals table above, gives `Block.Chart` the
three things a dashboard chart actually needs — a track, a hover tooltip and an
entry animation — and rebuilds `/theme` as daisyUI's own generator is built.

### 1. `Daisy.Chart`, reshaped

| Was | Is | Why |
| --- | --- | --- |
| `Line`, `Bar`, `StackedBar`, `Area`, `Donut` | `Line LineStyle`, `Bar BarStyle`, `Area`, `Donut` | `BarStyle` is `{ stacked, track, rounded }` and `LineStyle` is `{ stepped }`. Three independent switches are eight constructors written out; as a record they are one value, and a fourth switch later does not multiply the list. `allChartConfigs` is still the exhaustive enumeration (2 + 8 + 2 = 12), built from `allLineStyles`/`allBarStyles`, so the coverage test and the fuzzers still reach every branch. |
| `Series = { name, color, points }` | `+ dashed : Bool`, and a `series` constructor for the solid case | A projection is drawn dashed, and it is one *series* of a chart rather than a property of the chart. `Chart.series "Revenue" Primary [ … ]` keeps the common case a three-argument call. |
| — | `ChartInteraction msg = { hovered : Maybe Int, onHover : Maybe Int -> msg }` | The hover state is an **x index**, not a `Chart.Item`: the application stores an `Int`, and elm-charts' item plumbing stays inside `Daisy.Render` exactly as `Chart.Attributes` does. `Block.Chart` and `CardChild.CardChart` take it as a `Maybe`, so a decorative chart is unchanged. |
| — | `trackColorToCss`, `bandColorToCss` | The track is `--color-base-200` and the hovered band `--color-base-300`, as module constants rather than two more `SemanticColor` values. That is the whole decision: `e2e/themes.spec.ts` checks *every* `var(--color-*)` on the painted SVG, so these are verified like any semantic colour — but a **series** painted `base-200` would be invisible against the `base-100` panel it is drawn on, and `contrast.spec.ts` reads base-over-base as daisyUI's own pair, so it would pass while showing nothing. Keeping them out of `SemanticColor` is what makes "a line the colour of the paper" inexpressible. |

Nexus's own chart is `Bar { stacked = True, track = True, rounded = True }`, and
`Demo.Admin` says exactly that.

### 2. How the renderer draws it

- **The track is its own `C.bars` element**, drawn before the real one, with a
  single unnamed bar per bin whose height is `trackTop` (the largest column).
  Not an extra property of the real element: a property takes a slot in the
  bin, so a two-series grouped chart would come out three bars wide. Its own
  element is one bar across the whole bin, which is what the grouped or stacked
  real bars then sit inside. Both share `barLayout` (`CA.margin 0.26`), so they
  line up exactly.
- **A tracked chart pins its y domain to `0 .. trackTop` and draws no y axis.**
  Without the domain, elm-charts pads out to the next round tick and the track
  stops short of the top of the plot, which reads as headroom the data does not
  have. Without dropping the axis there are two scales — a painted track and a
  labelled grid — saying different things. An untracked chart keeps both.
- **`C.stacked` is given the series reversed.** It puts the *first* property at
  the top of the column; a reader takes the first series in the data to be the
  base of the stack, because it is the one the legend names first. The
  reversal is in the renderer, so the tree's order is the one that shows.
- **Hover is resolved to an index and back to a group.** `CE.onMouseMove` with
  `CE.getNearest CI.any` maps the nearest item's datum to `round .x`;
  `CE.onClick` fires the same message, because a touch produces no `mousemove`
  and the tooltip has to arrive on tap; `CE.onMouseLeave` clears it.
- **The band and the tooltip come from the group elm-charts resolved**, never
  from arithmetic — `C.eachCustom` over `CI.bins` (bars) or `CI.sameX` (lines),
  and `CI.getLimits` for the extent, so the band lines up with the bars
  whatever spacing the series uses. A line chart has no bin, so its band is
  `bandHalfWidth` either side of the x: the crosshair every dashboard draws.
  The grouping is filtered with `CI.named` to the caller's own series, which is
  what excludes the track — **a tracked chart draws two `C.bars` elements at
  every x, and without the filter it painted two bands and two tooltips.**
- **The tooltip card is `tokens`, not `card`.** `Chart.tooltip`'s own 5px/8px
  box is flattened with four inline styles (it is inline styles being
  overridden, so no class could win), and the content is a `bg-base-100
  rounded-lg shadow-sm overflow-hidden` column: the bin label on a `bg-base-200`
  header row, then one row per series with its `status status-<color>` dot, its
  name and its value. `card` was not used for the same reason `tokenRoundedLg`
  exists — a `.card` corner is `--radius-box`, 1rem or more in daisyUI's stock
  themes, which would make a 120px card a pill. The content's type is
  `Html Never`: a tooltip is `pointer-events: none` and can carry no handler at
  all, and the type says so rather than a comment.

### 3. `Daisy.Css`, and why the package ships a stylesheet at all

Four class names in this package are neither daisyUI's nor Tailwind's:
`daisy-anim-bars`, `daisy-anim-line`, `daisy-anim-tooltip`, `daisy-anim-band`.
Nothing else could be. daisyUI animates its own components and nothing else, and
there is no Tailwind utility for "grow this bar out of its baseline".

`Daisy.Css.stylesheet` is those rules **as an Elm value**, for the reason
`alexbruf/elm-cally` ships `Cally.Css.stylesheet`: the Elm registry publishes
`src/`, `elm.json`, `README.md` and `LICENSE` and nothing else, so a `.css` file
at a package's root never reaches an application that installs it.
`tools/gen-daisy-css.js` decodes the literal into `demo/daisy-motion.css`, which
`demo/app.css` imports and `tools/ci.sh` regenerates and diffs — the same
contract `gen-themes` and `gen-cally-css` already have.

Three things about it are deliberate:

- **Every rule is inside `@media (prefers-reduced-motion: no-preference)`**, not
  turned off afterwards. The reduced-motion state is then the plain,
  undecorated page — which is also what the e2e suite photographs, because
  `lib/daisy.ts`'s `open()` emulates `reducedMotion: "reduce"`. The generator
  refuses to write a stylesheet that is not guarded.
- **Two selectors reach into `terezka/elm-charts`** (`.elm-charts__bar-series`,
  `.elm-charts__interpolation-section`). The renderer marks the *container* it
  owns and the rule descends, because it cannot put a class on elements
  produced inside `C.bars` / `C.series`. That is `RenderPurityTest`'s
  `chartLibraryPrefix` exemption read from the other side.
- **The line's dash pattern lives in the keyframes, and the animation has no
  fill mode.** `Series.dashed` is a `stroke-dasharray` *presentation attribute*
  on the same path, and any CSS declaration beats a presentation attribute — so
  a static `stroke-dasharray: 2400` in that rule made the dashed projection
  line solid, permanently, because the animation filled `both`. Confining the
  pattern to the keyframes gives the path back to its own attribute the moment
  the draw-in ends.

**The chart group is keyed by its dataset** (`Html.Keyed`, key =
`chartKey config data`). A CSS animation runs when its element is *created*, so
diffing a chart in place would never replay it; remounting it does. Hovering
changes only `ChartInteraction.hovered`, which leaves the key alone, so the
tooltip does not restart the animation. `e2e/animation.spec.ts` asserts all
three states: animated with motion allowed, not animated at all under
`prefers-reduced-motion: reduce`, and replayed when the `Day | Month | Year`
strip changes the dataset.

### 4. What the tree gained, beyond charts

| Addition | Shape | Why it could not be composed |
| --- | --- | --- |
| `Section.Grid (GridSection msg)` | `Columns GridConfig (List (Block msg))` \| `Spans (List (GridItem msg))` | The twelve-column grid needs a span per cell and the equal grid has nothing to say about one. Putting the choice in the *payload* type rather than in a `Cols12` member of `GridColumns` makes both mistakes a `TYPE MISMATCH` — a spanned cell in an equal grid and a bare block in the twelve — and keeps `Section` at the five constructors the SPEC fixes. Two `should-not-compile` fixtures pin exactly that. |
| `GridItem = { span : Span, blocks : List (Block msg) }` | `span` / `spanColumn` | A twelve-column band is where a page puts *columns*, and a column is normally more than one panel: an editor rail beside two columns of preview cards. The cell is laid out as one fixed-gap vertical column by the renderer, so a cell of one block is byte-identical to what a single-block cell would have been. |
| `Span = Span3 .. Span12` | ten values | Twelve tracks across a 1136px column are 73px each, so one or two of them is a cell narrower than the padding-plus-content of any block in the tree. Three is 244px, a metric tile. |
| `Tab.onClick : Maybe msg` | one field | daisyUI's tab CSS shows the panel after the active tab with no JavaScript, which is all a *tab set* needs; a **segmented control** changes something outside the strip and has to say so. |
| `CardConfig.padding : CardPadding` | `PaddingDefault \| PaddingDashboard` | 20px is between daisyUI's two card sizes (24px and 16px) and is what every one of its dashboard templates sets. A closed pair rather than a length, because a length is a spacing decision and spacing is `tokens`' job. |
| `MenuConfig.activeStyle : MenuActiveStyle` | `SolidActive \| TintedActive` | See the residuals table. `TintedActive` emits **no** `menu-active`: daisyUI's active background is a custom property with one value, so there is no second style to reach for. |
| `Cta.placement : CtaPlacement` | `InNavbar \| InHeader \| InSidebarFooter` | The shell still owns the markup and there is still exactly one primary button; only which piece of chrome it lands in is now the page's to say. `InHeader` needs a header and `InSidebarFooter` needs a dashboard sidebar; neither is expressible in the type, so `ctaPlacementFor` falls back to `InNavbar` rather than dropping the button. |
| `DashboardShell.edges : Bool` | one flag, on by default | A shell whose content ground is `base-100` has nothing for the line to separate and reads as a box; the ground this package paints is `base-200`, which is the case that wants it. |
| `ThemePresentation.ThemeAsIconDropdown` | one constructor | A flag on `ThemeAsDropdown` would have made `tests/CorpusTest`'s class-for-class fixture depend on the flag. |

### 5. Two defects found at the root, and fixed for every user

Both are the *same* elm/virtual-dom trap the custom-theme pass documented,
found in two more places.

- **`Attr.style "--value" …` is a no-op**, so `Leaf.RadialProgress` and
  `Leaf.Countdown` never worked: a radial progress drew an empty ring at every
  value. `elm/virtual-dom` applies a style node with `element.style[key] =
  value`, and a `CSSStyleDeclaration` silently ignores an assignment to a `--*`
  name. `Daisy.Render.customProperty` writes one whole `style` **attribute**
  instead, which goes through `setAttribute` and reaches the CSS parser. It was
  invisible until the generator page put a `radial-progress` on screen.
- **An `<a>` with an `onClick` and no `href` reloads the page under
  `Browser.application`.** Its document-level click listener walks up to the
  nearest `<a>`, reads the `href` *property* (the empty string), gets
  `Url.fromString "" == Nothing`, and sends `UrlRequested (External "")` — which
  a router answers with `Browser.Navigation.load ""`. It also calls
  `preventDefault`, so the control looks inert: the message it sent really was
  handled, and then the page was thrown away and rebuilt from the URL. It bit
  `Tab` (the `Day | Month | Year` strip) and `MenuItem` with an `onClick` and no
  `href`. `Daisy.Render.clickableHtml` renders both as a `<button
  type="button">` when they carry an `onClick`, which is also the focusable,
  keyboard-activatable element they should always have been; an anchor that has
  an `href` stays an anchor, so every navigation link is unchanged.

### 6. `Daisy.Render.tokens`: 76 -> 100

| Tokens | Job |
| --- | --- |
| `lg:grid-cols-12` + `lg:col-span-1` .. `lg:col-span-12` (13) | The twelve-column band and its twelve cell widths. Below `lg` the band is one column and the cells claim nothing, for the same reason `Cols2` steps at `lg`. One constant per span rather than a built string: `render-class-audit` requires every class-like literal to be a `tokens` entry, and a class assembled at run time would be invisible to Tailwind's source scan, which reads these literals out of `Render.elm` itself. |
| `p-5` | `CardPadding.PaddingDashboard`. |
| `self-start` | The `stat-figure` tile, on the label's line. |
| `border-b`, `border-r`, `border-base-300` | `DashboardShell.edges`. One use site each, in `shell`. |
| `overflow-hidden` | Clips the tooltip's painted header row to the card's corner. |
| `xl:grid-cols-3` | `CellColumns.CellThree`, the grid daisyUI's own theme generator lays its component preview out in. `xl` and not `lg`: a cell that is already only part of a twelve-column band is narrow, and three of them inside seven tracks at 1280 would be 170px each. |
| `daisy-anim-bars`, `daisy-anim-line`, `daisy-anim-tooltip`, `daisy-anim-band` | The four motion classes, whose rules are `Daisy.Css`'s. The only entries in the table that are neither daisyUI's nor Tailwind's, which is why they carry a namespace neither uses. |

`tests/RenderPurityTest.elm`'s `forbidden` list is **unchanged**: nothing left
it. `border` in particular stays — a box drawn around an arbitrary element is
what that entry exists to prevent, and `border-b` / `border-r` on a piece of
chrome the renderer owns is a different thing, with one use site each.

### 7. The theme generator, rebuilt as daisyUI builds it

`/theme` is a reproduction of <https://daisyui.com/theme-generator/> rather than
a dashboard page about the same subject. Measured on that page at 1440: a theme
list of ~190px, an editor of ~250px, and a preview of 879px laid out
`grid gap-6 xl:grid-cols-3` of 277px `card ... card-sm` panels — under the
site's own navbar, on the page ground, with no application sidebar anywhere.

| Theirs | Ours |
| --- | --- |
| The daisyUI site navbar | `Shell.Plain` + a `Section.Navbar` band (brand `Acme`, links back to the three other demos). **Not** `Shell.Dashboard`: a 256px application sidebar to the left of a page whose left-hand column *is* a list is two rails side by side, which is the single thing that made this page read as a different one. |
| Theme list, ~190px | `Span2` (212px): a bare `Block.Menu` on the page ground, `My themes` then `daisyUI themes` as `menu-title` rows, every theme a row with a glyph, the loaded one `TintedActive`. Clicking a row **is** the "start from" control — the `<select>` is gone. |
| Editor, ~250px | `Span3` (330px): `Name`, `Random` + `CSS` as a `join`, the link back into their generator, five colour cards, `Radius`, `Sizes and effects`, `Palette`. |
| Components Demo, 879px in three columns | `Span7` (802px) as a `CellColumns.CellThree` cell — three 256px columns, `items-start` so each card keeps its own height. |

**The colour chips are their chip design.** Their `Change Colors` grid is four
squares to a row — a colour, its `A` chip, the next colour, its `A` — with the
two names underneath. Ours is four `type="color"` pickers in one `Leaf.Join`
with the group's name under them: a `join`'s flex children shrink their `.input`
`width: 100%` base sizes to a quarter each, which is the only way four inputs
share a row in a `card-body` (a `card-body` is a column, and `card-actions`
wraps but does not constrain). The one thing that could not be reproduced is the
bold `A` *inside* the second square: an `<input type=color>` paints a flat
swatch and cannot carry a glyph, so the `-content` square shows the content
colour itself.

**The block-by-block preview mapping** is in section 12.

`ThemeEdit` gained `SetName`: the name field is a real text input, and
`Daisy.Tree.themeName` refuses an invalid or reserved name by returning
`Nothing`, so `apply` simply leaves the theme alone — which is why it needs no
error state.

### 8. How the rail and the preview got to those spans

The pass that produced section 7 recorded its own reasoning while the numbers
were still moving, and those measurements are why the shipped layout is what it
is. Two of them are still load-bearing; one has since been remeasured.

daisyUI's own generator at 1440 is a ~250px editor rail beside an ~880px
preview laid out as `grid gap-6 xl:grid-cols-3` of
`card bg-base-100 card-border border-base-300 card-sm` panels. `/theme` is now
the same shape, expressed as one `GridSection.Spans` band of three cells:

- **The rail** (`Span4`): a `Theme` card (name, "Start from", the light/dark
  switch, `Randomize`, the link back into daisyUI's generator), three colour
  cards, the shape card, and the palette.
- **Two preview columns** (`Span4` each): the panels daisyUI's preview shows —
  buttons, badges, tabs, a sign-up form with every control a theme reshapes, a
  product card with a rating, a chart, alerts, a radial-progress score, an
  orders table, a revenue stat, a chat, progress bars, steps, a timeline and a
  pricing card. Two of those are not cards — a `steps` and a `timeline` — which
  is what a `Spans` cell holding a *list* of blocks is for, and which daisyUI's
  own preview does too.

Three decisions inside it:

- **The colour editor is a grid of chips, not a form.** Twenty `Field` rows is
  the long single column this page used to be. The chips are grouped into
  `Surface` / `Brand` / `State` cards, which is how daisyUI's own generator
  groups them, four to a row. Each chip is a native
  `type="color"` picker named by its `--color-*` variable through `ariaLabel`
  (a `tooltip` beside it was tried and refused by two Tier C rows — section 11),
  and four of them are one `Leaf.Join`: daisyUI's `.input` is `width: 100%`, so
  four loose in a `card-body` column are four full-width rows, while a `join`'s
  flex children shrink their 100% base sizes to a quarter each. That is the
  four-across grid daisyUI's own generator shows, and it is also why
  `card-actions` was not the answer in the end — it wraps, but it does not
  constrain.
- **The six lengths are `join`s of `btn-xs` buttons, not `<select>`s.** A select
  hides both how many steps there are and which one is current. Their visible
  text is the value without its unit (`0.25`), because six five-step rows have
  to fit the rail; the unit moves to the group's heading and the button's
  accessible name keeps the whole length prefixed by the group (`Boxes 2rem`),
  which is what keeps `2rem` in one control distinguishable from `2rem` in the
  next — and the visible text is still contained in the accessible name, so
  they never disagree. The heading above each row is a `Leaf.Text`, not a
  `Field` label: a `Field` wraps its control in the `<label>`, and a `<label>`
  around six buttons makes clicking the heading press the first of them.
- **The rail is four tracks, not three.** Three (260px) would have matched
  daisyUI's rail width exactly, and the preview would then have had three
  columns like theirs — but a 260px rail cannot hold a five-step segmented
  control without overflowing it, and a control that scrolls sideways is worse
  than one column fewer. `e2e/overflow.spec.ts` measures exactly that.

`ThemeEdit` gained `SetName`: the name field is a real text input, and
`Daisy.Tree.themeName` refuses an invalid or reserved name by returning
`Nothing`, so `apply` simply leaves the theme alone — which is why it needs no
error state.

**Superseded:** “the rail is four tracks, not three” was the shape at the time
this was written. “The generator's editor column (2026-09-07)”, section 4,
remeasured the band against daisyUI's own 277px preview cards and settled on
`Span2 | Span3 | Span7`, which is what section 7 above records and what
`Demo.ThemeGenerator` builds. The colour editor described here as four
`type="color"` pickers in a `Leaf.Join` is likewise superseded by
`Leaf.ColorChips`, section 1 of that same pass. Everything else here — why a
`<select>` was refused for the six lengths, why the heading above a segmented
row is a `Leaf.Text` and not a `Field` label, why four inputs need a `join` —
still holds.

### 9. What the e2e suite gained, and the two root causes it found

`e2e/lib/daisy.ts` now lists four demos and thirty-six themes, so
`themes.spec.ts` is 4 x 36 = **144 baselines** (was 105) and the contrast and
chart-colour sweeps cover the custom-theme path as well.
`e2e/theme-generator.spec.ts` is new: eight tests covering the inline
properties, a built-in opened as an editable theme, a colour edit repainting the
root and the CTA and the export, the shape controls, the generator hash, the
palette chips and the edit surviving navigation.

Two defects the matrix found on the new route were fixed at the root:

- `scrollable-region-focusable` (serious) on the two-tile `stats` at 375 — the
  same one `Demo.Admin` hit, same fix: `StatDirection.Responsive`.
- `scrollable-region-focusable` (serious) on `.mockup-code`. daisyUI's
  `.mockup-code` is `overflow-x: auto` around a `<pre>` of `width: max-content`,
  so any line longer than the container makes it a scrollable region — and the
  block holds only text, so there is nothing inside it to receive focus. Fixed
  in **`Daisy.Render`**, for every user of the package, not in the demo:
  `MockupCode` now emits `tabindex="0"` with `role="group"` and a name. The
  stretch that exposed it was a second root-cause fix — the export band is
  `Stack { align = AlignStretch }`, because a `mockup-code` sized to its content
  is ~500px wide and gave the *document* a horizontal scrollbar at 375.

Two composition choices were changed rather than waived: the preview's alerts
are solid `alert-<color>` and not `alert-soft` (soft is a `color-mix` pair the
composition derives; solid is daisyUI's own `--color-X` / `--color-X-content`),
and the export link is a plain `link` and not `link-primary` (`--color-primary`
as a *foreground* over `--color-base-100` falls under 4.5:1 in several themes,
and this page draws itself under deliberately bad ones).

One waiver was added, and it is the *existing* position made consistent rather
than a new exemption. `e2e/a11y.spec.ts` already waived `color-contrast` on
daisyUI's three de-emphasised pairs by class list; it now also waives it on
daisyUI's **emphasised** pair — `--color-X` under exactly its own
`--color-X-content` — decided in the browser on painted sRGB bytes, which is the
same mechanical rule `e2e/contrast.spec.ts` has applied from the start and which
SPEC.md's "what is deliberately not tested" puts outside Tier C. It matters here
because the generator page's job is to show a theme's pairs including the bad
ones: `acme`'s own `--color-secondary` / `--color-secondary-content`, which
daisyUI's generator derived, is 1.9:1. A `-content` colour over the wrong
surface, or a `color-mix` background, still does not match and still fails.

### 10. What the e2e suite gained: animation, interaction, and the shape controls

- **`e2e/animation.spec.ts`** (new, 3 tests, `desktop-light`). The only spec
  that does not go through `open()`, because it is the one place that has to
  control `prefers-reduced-motion` itself and must not have `open()`'s
  kill-every-animation stylesheet injected. It asserts the animation exists and
  is `daisy-bar-grow`, that reduced motion leaves `document.getAnimations()`
  empty, and that switching the dataset replays it — which is the assertion
  that would catch the `Html.Keyed` key being dropped.
- **`e2e/interaction.spec.ts`** gained two tests: hovering 2023 opens exactly
  **one** tooltip carrying the year and both series names and exactly one band
  (the "one" is the assertion that would catch the track's bin being counted),
  and the pane still reads the message before it, because `ChartHovered` is a
  `paneName` exception for the same reason `CalendarMsg` is — it fires on every
  `mousemove`. The other test clicks `Month` and asserts the dataset changed.
- **`e2e/theme-generator.spec.ts`**'s shape test now clicks segmented buttons
  instead of choosing from selects, and additionally asserts that exactly one
  step of a group is marked.

### 11. What the suite refused, and what it found

The recomposed pages were run against the existing Tier C rows before anything
was called finished. Seven things came back; **two were renderer defects fixed
for every user, five were compositions changed rather than waived, and no row
was relaxed.**

Renderer defects:

| Row | Finding | Fixed by |
| --- | --- | --- |
| `a11y` (critical x5) | `Leaf.Rating`'s five radios had no accessible name. `RatingConfig.ariaLabel` named all five the same thing when it was set at all, and the "clear" radio had no name under any circumstances. | Each radio is named `"<group> <n>"` — the group being `ariaLabel` or `ratingDefaultLabel` — which is what daisyUI's own docs example writes (`aria-label="1 star"`). Five distinct names, always present. |
| `a11y` (serious) | `Leaf.RadialProgress` is `role="progressbar"`, and a `progressbar` takes **no** name from its content, so a dial with a number in it is an unnamed control. | `RadialProgressData.ariaLabel : Maybe String`, falling back to the visible `label`, plus `aria-valuenow`. It has no config record to put it on — its size and thickness are CSS variables — so the field is on the data. |

Compositions changed:

| Row | Finding | Changed to |
| --- | --- | --- |
| `overflow` (`admin`, 375) | The page header's trailing group is `shrink-0`, which was right when it held only a `breadcrumbs` trail; with `Cta.placement = InHeader` it also holds a `btn`, and ~380px of min-content that cannot shrink gave the *document* a 413px scroll width at 375. | The group wraps instead. The clipping the `shrink-0` was added for is the case where the trail is the group's *only* child — and in that case the renderer already puts it directly in the row. |
| `overlap` + `overflow` (`theme`) | A `Tooltip` on each colour chip. daisyUI's `.tooltip` wrapper is an `inline-block` that shrinks to fit and the `.input` inside it is `width: 100%`, so every 32px chip sat in a 24px wrapper and overlapped its neighbour by 8px; the absolutely positioned bubble put 55px of scroll content in a 32px box. | The chips are named by `ariaLabel` alone, which is what `getByLabel` and a screen reader read anyway — and four of them are one `Leaf.Join`, which is the shrink-to-fit row the tooltip was accidentally providing. |
| `overflow` (`theme`) | A `chat-end` bubble. daisyUI draws the tail with an absolutely positioned `::before` **12px past the bubble's right edge**, which is 12px of scrollable overflow; on a `chat-start` bubble the same tail is on the left, where a negative offset contributes nothing to `scrollWidth`. | Both preview messages are `chat-start`. |
| `contrast` (`valentine`) | The segmented control marked its current step with `btn-active`, whose background is a `color-mix()` the *composition* chose — 4.28:1 against the default `btn`'s foreground in that theme. | `btn-neutral`: `--color-neutral` over `--color-neutral-content`, a pair daisyUI declares in every theme. |
| `keyboard` (`theme`) | A two-tile `stats` at `Responsive` in a four-track column is 355px wide at `lg`, where `lg:stats-horizontal` applies — so `.stats` (`grid-flow-col overflow-x-auto`) became a scrollable region and therefore a tab stop of its own. | `Fixed Vertical`, which is what two tiles in a 355px column want regardless. |

And one screenshot flake, which is worth recording because it is not a bug in
anything: `Leaf.Loading` in the preview made all thirty-six `/theme` baselines
differ from run to run. `open()` kills CSS animation, but daisyUI's
`loading-spinner` is a `mask-image` whose data-URI SVG animates itself with
**SMIL**, which no CSS declaration stops. The spinner is out of the preview;
`loading` stays covered by the class-coverage fixtures, which render markup
rather than photograph it.

### 12. The generator preview, block by block

daisyUI's preview grid has nineteen blocks in three columns. Ours has the same
nineteen, in their order, flowing row-major through a `CellThree` cell.

| # | daisyUI's block | Ours |
| --- | --- | --- |
| 1 | `Preview` card: header + `more` link, two removable tag badges, four checkbox rows with count badges | `Card` with `headerActions = [Link "more"]`, a `CardList` of four `list-row`s (`Checkbox`, growing label, `Badge`), the tags in `card-actions` — theirs are under the header, ours at the foot, because `card-actions` is the only wrapping row a `card-body` has |
| 2 | Week strip, event search, all-day toggle, one highlighted event | `Join` of seven `btn-xs` day buttons (the current one `btn-neutral`), a `CardForm` of the search field and the toggle, a one-row `CardList` for the event with its `1h` badge. Theirs stacks the weekday letter under the number in each cell; a `btn` is one line, so ours shows the number only |
| 3 | Tabs + `Tab content 2` | `CardParts.headerTabs` (`tabs-box tabs-xs`) + a `CardLeaf` |
| 4 | Price range: title, big number, slider | `Card` + `Leaf.Heading H1` + `Leaf.Range` |
| 5 | Product: picture, name, `SALE`, rating, review count, price | `CardParts.figure` + `headerActions` badge + `Leaf.Rating` + `Heading H3` + `card-actions` |
| 6 | Search + `Find` | `Join [JoinInput, JoinButton]` |
| 7 | `Create new account` | `CardForm` of every control a theme reshapes — input, password, select, textarea, file input, two toggles, a radio, a checkbox — plus `Register` and `Or login` |
| 8 | Sales volume: bar chart, sentence, `Charts`/`Details` | `CardChart (Bar { rounded = True })` + `CardLeaf` + `card-actions` |
| 9 | `Page Score`: radial dial beside a `stat` | `StatItem.figure = RadialProgress { size = RadialCompact }`, which is where daisyUI puts it. It took a pass to get there: a 5rem dial plus its tile is a 96px grid column, and `.stat-title`/`-value`/`-desc` are all `white-space: nowrap`, so 96px of figure beside 170px of text turned a 218px `.stats` into a scrollable region — and a scrollable region is a tab stop of its own. `RadialSize` closed that (“The generator's editor column”, section 6); a 3rem dial in its tile is 64px beside 85px of `stat-value` |
| 10 | Recent orders | `CardList` of five rows, each a glyph, a growing name and a soft status badge |
| 11 | September Revenue | `CardStat` with a delta badge |
| 12 | `Write a new post` | `Join` of `B`/`I`/`U`, a `Textarea`, a character count, `Draft`/`Publish` |
| 13 | Chat bubbles | `CardChat` |
| 14 | `Admin panel` menu with counts | `CardList` of glyph + label + count. Theirs is a `menu`; a `card-body` cannot hold a `Block`, and `CardChild` has no `CardMenu` — a `list` row is the same three-part row |
| 15 | Media player | Title, subtitle, a `Join` of transport buttons, a `Progress`, the elapsed/total time, four square buttons in `card-actions` |
| 16 | Terminal | `Block.MockupCode`, unpanelled — theirs is too, which is what a `Spans` cell holding a *list* of blocks reproduces |
| 17 | Four alerts | `CardAlert` ×4, **solid** rather than their outline/dash/soft mix (a soft alert is a `color-mix()` pair the composition derives, which axe reports as a contrast failure on a light ground) |
| 18 | Timeline of seven items | `Block.Timeline`, unpanelled, the second non-card block |
| 19 | Pricing: `Monthly \| Yearly` + `SALE`, plan, price, four features, `Buy Now` | `headerTabs` + `headerActions` badge + `Heading H2` + a `CardList` of check/cross rows + `card-actions` |

**Two of their blocks are not there.** The `dock` (phone / chat / settings) is
`Page.dock` in this tree — viewport-fixed chrome, not something a card can hold
— so putting one in a preview card would mean inventing a second, non-fixed
dock. And their `Preview` card's tag chips sit under its header; ours are in
`card-actions` at the foot of the same card, for the reason in the table.

**The arrangement difference is closed.** It used to read: their three columns
are three independent `flex flex-col` stacks, so the cards pack per column (a
masonry), while ours was one grid, so the cards flowed row-major and a short
card left space under it. `CellColumns` now renders as daisyUI's own structure —
`Daisy.Render.cellChildren` deals the cell's blocks into two or three
`flex flex-col` columns inside the responsive grid — so the packing is theirs
too. Nineteen blocks into three columns is `7 + 7 + 5`, which is exactly how
daisyUI assigns its own nineteen cards. It took the `/theme` page from 3149px
tall to 2251px. CSS multi-column was still refused, for the reason it always
was: its children need a `mb-*` utility, and `mb-4` is on `RenderPurityTest`'s
`forbidden` list.

### 13. Two Admin measurements, and three more renderer changes

- **A tracked bar chart draws no left gutter.** `chartMargin` reserves 42 user
  units for y-axis labels; a tracked chart draws none, so those units were about
  30 device pixels of nothing at each side — half a bin. `barMargin` drops them,
  and the columns now fill the panel the way Nexus's do (measured there: bar
  27px on a 60.6px pitch; ours 30px on 57.6px). `barCornerRadius` went 0.35 ->
  0.45, which is the near-pill cap Nexus draws.
- **A headline stat has no `stat-title`.** Nexus reads `$184.78K +3.24%` with
  `Total income in this year` **under** it; a metric tile reads label-first.
  `Daisy.Render` emits no `stat-title` for an empty one — the same rule as an
  empty `breadcrumbs` trail and a `Tab` with no content — so `Demo.Admin`'s
  `totalIncome` says the whole label in the caption and the number is the first
  thing in the tile.
- **`BadgeConfig.icon`.** Nexus's delta pill is an arrow then the percentage.
  A badge could not carry a glyph; it can now, drawn at `size-4` and
  `aria-hidden`, exactly like a `ButtonConfig.icon`. `Demo.Admin`'s delta is
  `badge-xs`, not `badge-sm`, because the glyph costs 20px of a row that has to
  hold a 24px number and a figure tile as well.
- **A `stat` tile's gutter is 20px, not daisyUI's `1rem`/`1.5rem`.** 24px of
  inline padding either side of a 269px metric cell is 48px of the 221px a
  number, its delta and a figure have to share — which is why the delta wrapped
  under the number the moment it gained an arrow. Every dashboard template sets
  ~20px there, and it is the same figure `CardPadding.PaddingDashboard` uses.
  With it, all four Admin tiles read `$587.54 ↑ 10.8%` on one line, as Nexus's
  do.
- **The `stat-value` row wraps.** `.stats` is `overflow-x: auto` in *both* flow
  directions, so a tile whose number plus delta is wider than its cell became a
  scrollable region — which `e2e/keyboard.spec.ts` sees as a tab stop of its
  own. Adding the arrow to the delta badge was enough to trigger it in a 269px
  metric cell. A delta that does not fit now goes under the number.
- **`Cta.placement = InNavbar` means the navbar.** Under `Shell.Plain` it used
  to mean "the end of the last section", which is not a navbar at all. A `Plain`
  page that spends a section on `Section.Navbar` now gets its CTA there, and
  only a page with no navbar falls back to the old placement.

### 14. What the tree gained for the generator

| Addition | Why |
| --- | --- |
| `Span1`, `Span2` | A rail is one or two of twelve. daisyUI's own generator puts its theme list in 190px and its editor in 250px, which is exactly `Span2` and `Span3` of a 1392px content column. The old floor of three was written for *panels*; a rail is not one. |
| `GridItem.columns : CellColumns` (`CellOne \| CellTwo \| CellThree`), `spanGrid` | Their preview is a grid **inside** the region beside the editor. This is that, as a property of the cell rather than a nesting level: the children are still blocks, and a block still never contains a block. `CellOne` is what every cell was, so nothing existing changed. |
| `CardChild.CardList` | Half of their preview cards are a list of rows in a panel, and a `card-body` is a column that cannot hold a `Block`. Same reason `CardTable`, `CardChat` and `CardStat` exist. |
| `BadgeConfig.icon` | See section 13. |

## The generator's editor column (2026-09-07)

The verdict on the previous pass was that `/theme`'s editor rail still read as a
form beside daisyUI's, not as daisyUI's. Four things were wrong, and closing
them added three leaves, one closed glyph type on `MenuItem`, one size on
`radial-progress`, and twenty-two tokens. Measurements below are daisyUI's own
generator at 1440, read out of the live page.

### 1. Colour chips: `Leaf.ColorChips`

daisyUI's chip is a 44x40 `rounded-lg` button painted in the colour it edits,
with a bold `A` on it in the paired `-content` colour:

```html
<button class="border-base-content/10 grid h-10 w-14 rounded-lg border-1 …
        aria-label="Choose --color-primary-content: oklch(93% 0.034 272.788)"
        style="color: oklch(0.93 …); background-color: oklch(0.45 …)">A</button>
```

Ours was twenty `input input-sm` colour fields, four to a `join`, in five
cards. What replaced it is one leaf:

```elm
| ColorChips (List (ColorChipGroup msg))

type alias ColorChipGroup msg = { label : String, chips : List (ColorChip msg) }

type alias ColorChip msg =
    { color : Oklch, contentColor : Oklch, value : Oklch
    , glyph : ChipGlyph, ariaLabel : String, onChange : Maybe (String -> msg) }

type ChipGlyph = ChipBlank | ChipLabel String | ChipSpecimen
```

Five decisions in that.

- **The colours are values, not classes.** `Leaf.Swatch` shows a colour a theme
  *has*, so `bg-primary` is exactly right for it. A generator shows a colour
  that is being *edited*: it is not `--color-primary` yet, and there is no
  utility that could paint it. The chip is therefore an inline
  `background-color` / `color` pair written from `Daisy.Color.oklchToCss` — the
  same `oklch()` string the root carries, deliberately, so
  `e2e/contrast.spec.ts` and `e2e/a11y.spec.ts` recognise the painted bytes as
  daisyUI's own `--color-X` / `--color-X-content` pair with no change to either
  classifier. A hex would have gamut-mapped differently and defeated that.
- **Three colours, not two.** A pair of chips shows *one* pair of colours twice:
  daisyUI's `primary` chip and its `primary-content` chip are both a `primary`
  square with a `primary-content` `A` on it, and which of the two a click edits
  is the only difference between them. `value` is that third field; without it
  "the square that edits the letter" is unrepresentable, and the picker on the
  `-content` chip would open on the wrong colour.
- **The picker lies on top.** `<input type="color">` cannot be styled into a
  swatch — Chrome draws its own bevelled well inside whatever box it is given —
  and cannot contain the glyph. The square is a `div`, the input is
  `absolute inset-0 w-full h-full opacity-0 cursor-pointer` over it, and its
  `aria-label` is the `--color-*` name. `opacity-0` and not `hidden`: it still
  has to take the click. `ChipGlyph` is closed because daisyUI draws two
  different things at two different type sizes there — `100`/`200`/`300` at the
  body step, and the `A` at `text-2xl font-black`.
- **One leaf for the whole editor, not one per chip.** The layout is a grid of
  *groups*, and a `card-body` is a column that cannot arrange leaves in rows.
  `Daisy.Render.packedChipRows` deals the groups into rows of at most four
  chips, which reproduces daisyUI's `grid-cols-4` with a `col-span` per chip
  count — `base` (four chips) fills a row, each colour/`-content` pair takes
  half of one — without four `col-span-*` tokens, and without a `w-fit` grid's
  tracks widening to the largest group.
- **The chips are a fixed 44x40, not shrunk.** daisyUI's are `h-10 w-14` (40x56)
  squeezed to 44x40 by a 224px rail. Ours are `h-10 w-11` and `shrink-0`, so the
  chip is 44x40 whatever the rail is: the row is 4 x 44 + 3 x 16 = **224px**, the
  same number, in a 296px card body.

`e2e/theme-generator.spec.ts` gained an assertion that the square under the
`primary` picker really computes to `oklch(0.62 0.265 303.9)` — the check that
would catch the paint falling back to a class.

### 2. Theme-list dots: `MenuGlyph`

daisyUI's theme list draws a tile per row — the theme's `base-100` with four
4px dots of its `base-content`, `primary`, `secondary` and `accent`:

```html
<div class="grid grid-cols-2 gap-0.5 rounded-md p-1 shadow-sm"
     style="background-color: oklch(100% 0 0)">
  <div class="size-1 rounded-full" style="background-color: oklch(21% …)"></div> …
```

(The task sheet said "primary, secondary, accent, neutral"; the live DOM says
`base-content` first and no `neutral`, and the DOM is what was copied.)

The glyph is `MenuItem`'s, so `icon : Maybe Icon` became

```elm
type MenuGlyph = MenuIcon Icon | MenuThemeDots Theme
```

with `glyph : Maybe MenuGlyph`. A **closed pair, not a second field**: a row has
one leading glyph, and `icon = Just …, dots = Just …` would be a contradiction
the type allowed. `Leaf.ThemeDots Theme` exists as well, for the tile outside a
menu — the `Palette` card leads with the edited theme's own — and both go
through one `themeDotsHtml`.

`Daisy.Render` imports `Daisy.Themes` for this, its first dependency on the
generated theme table. It has to: `Theme` is a *name*, and the row is showing
the four colours behind somebody else's name. Every one of them is inline for
the same reason as the chips, one step sharper — `bg-primary` on that tile would
paint the theme being edited, not the theme the row is offering.

"Hold to add theme" is not reproduced. daisyUI's saves into `localStorage`,
which is a `Cmd` and a port; `My themes` keeps `acme` and the editor edits it in
place.

### 3. Radius tiles: `Leaf.RadiusTiles`

daisyUI draws each radius step as the corner it sets: a `h-6 w-8` box with only
its top and inline-end borders, at `border-start-end-radius: <step>`. Ours
were five buttons reading `0`, `0.25`, `0.5`, `1`, `2`.

```elm
| RadiusTiles (RadiusTilesConfig msg) RadiusTilesData
```

with `RadiusTilesData = { group : String, current : Radius }` and the five
options always `allRadii`. It is **one leaf and not five**, for the reason
`Leaf.Filter` is one leaf: a radio group is one control, and five loose radios
could not be made exclusive by the type. It renders as a `join` of `btn btn-sm`
`<label>`s over `sr-only` radios — a real `role="radiogroup"`, arrow-key
navigable, each step named `"<group> <length>"` so `2rem` in `Boxes` and `2rem`
in `Fields` are two different controls.

The tile's two borders are left at `currentColor`. That is the whole reason the
control needs no colour token: the marked step is `btn-neutral`, so its corner
comes out `--color-neutral-content`, and an unmarked one comes out
`--color-base-content`. `btn-neutral` and not `btn-active` for the reason the
previous pass recorded — `.btn-active`'s background is a `color-mix()` the
composition chose, 4.28:1 in `valentine`.

The radius itself is an inline declaration. A `border-radius` out of a
five-member set is a *value*; a utility would need one class per possible
length, which is not a finite set. `Daisy.Render.inlineStyle` /
`declaration` are the generalisation of `customProperty` that this and the
chips needed — an element carries one `style` attribute, so a chip that paints
both its background and its foreground has to write them together.

### 4. Preview geometry, and the numbers that did not close

| Measurement | daisyUI | ours | note |
| --- | --- | --- | --- |
| Preview grid | `grid gap-6 xl:grid-cols-3` of three `flex flex-col gap-4` columns, 879px | one `GridItem` `CellThree`, 805.3px | |
| Card width | **277px** | **257.8px** | **-19.2px (-6.9%)**. See below |
| Column gap | 24px between columns, 16px within one | 16px both | 24px would cost another 5.4px of card width |
| Card packing | per column (masonry) | per column | closed this pass, section 5 |
| Product figure | 259 x 152.9 | 257.8 x 152.5 | the placeholder's aspect went 2:1 -> 1.7:1 |
| `radial-progress` | 48px (`--size: 3rem`) | 48px | `RadialSize.RadialCompact` |
| Terminal | 277 x 128 | 257.8 x 128 | |
| `Preview` card | 277 x 258 | 257.8 x 308 | +50px: see below |
| `Page Score` card | 277 x 118 | 257.8 x 160 | +42px: the `stat-figure` tile and this package's `stat` type scale |

**Why the cards are 19px narrow, exactly.** To draw 277px cards in three
columns the preview cell needs `3 x 277 + 2 x 16 = 863px`. The band is the page's
1392px content column in twelve tracks with 16px gutters, so a track is 101.33px
and a cell of *N* tracks is `101.33N + 16(N-1)`: **Span7 = 805.3px** and
**Span8 = 922.7px**. 863 is between them, so no split gives 277.

Span8 would give 291.6px (+14.6, closer in the absolute) — but it leaves four
tracks, 453.3px, for two rails that need more than that:

- the theme list needs ~112px of row (18px tile + 12px gap + `caramellatte` at
  the `menu-xs` step + padding), so **Span2 = 218.7px** is its floor;
- the editor needs the 224px chip grid *and* the 280px radius row (5 x (32px
  tile + 2 x 12px `btn-sm` padding)) inside a `p-5` card body, so
  **Span3 = 336px** (296px inner) is its floor. Span2 would be 178.7px inner.

218.7 + 336 + two 16px gutters is 586.7px, which leaves exactly Span7. So
Span2 / Span3 / Span7 is not a preference, it is the only split the twelve
tracks allow, and −19.2px is the closest this band reaches. Widening it would
mean changing `<main>`'s 24px gutter, which is every other demo's too.

**Why the `Preview` card is 50px tall.** Its four rows are a `CardList`, and
`.list .list-row`'s padding is a hard-coded `1rem` in daisyUI's own
`list.css` — no variable, no size class — so a row with a `checkbox-sm` in it
is 52px. daisyUI's own preview does not use the `list` component there: its
rows are `flex items-center justify-between py-2` with a dashed rule, 37px.
Matching that would mean the renderer overriding a daisyUI component's padding
with a token, which is a thing it does exactly once already (`stat`, for a
documented measurement) and which is not worth a second exception for a preview
card. Four rows x 15px is the 50px.

### 5. `CellColumns` renders as columns, not as a grid

`GridItem.columns` used to put the cell's blocks straight into a
`grid … xl:grid-cols-3 items-start`. It now deals them into two or three
`flex flex-col gap-4` columns inside that same responsive grid, which is
daisyUI's own structure and gives the per-column packing §10 recorded as the one
arrangement difference. `Daisy.Render.dealIntoColumns` takes consecutive runs of
`ceil(n / count)` — nineteen into three is `7 + 7 + 5`, exactly daisyUI's own
assignment, and exactly the three groups `Demo.ThemeGenerator.previewCards`
already listed in its comments. Below the breakpoint the outer grid is one or
two tracks and the columns stack or pair up; daisyUI's behaves the same way.

`/theme` went from 3149px to 2251px tall. The three other demos do not use
`CellTwo`/`CellThree`, so none of their baselines moved.

### 6. `RadialSize`

`radial-progress` is sized by a `--size` custom property and daisyUI ships no
class for it, so `RadialProgressData` gained a closed pair rather than a length:
`RadialDefault` is daisyUI's stock 5rem and `RadialCompact` is the 3rem its
dashboard templates use when the dial sits *beside* a number. That is what let
the `Page Score` dial go back into its `stat-figure`, where daisyUI puts it: at
3rem the figure column is 64px, against 85px of `stat-value` in the 178px a
`stat` has inside a 258px card, so `.stats` is no longer wider than its cell and
`e2e/keyboard.spec.ts` no longer sees a scrollable region.

### 7. `Daisy.Render.tokens`: 100 -> 122, and one entry left `forbidden`

| Tokens | Job |
| --- | --- |
| `relative`, `absolute`, `inset-0`(existing), `opacity-0`, `cursor-pointer`, `w-full`(existing), `h-full` | The colour picker lying over a chip. |
| `w-11`, `h-10` | The chip, at daisyUI's rendered 44x40. |
| `text-2xl`, `font-black` | Its `A` specimen. `text-2xl` holds the same string as `tokenHeading2` and is a separate constant on purpose: a specimen letter is not a heading, and moving the `Leaf.Heading` scale must not resize it. |
| `gap-1` | Between a chip group's row and its caption. |
| `border` | The chip's hairline — the one entry that left `forbidden`, below. |
| `sr-only`, `w-8`, `h-6`, `border-t-2`, `border-e-2` | A `Leaf.RadiusTiles` step: the hidden radio and the two-sided corner. |
| `grid-cols-2`(existing), `gap-0.5`, `p-1`, `rounded-md`, `shadow-sm`(existing), `size-1`, `rounded-full` | The four-dot theme tile. |

`border` **left** `forbidden`, and it is the fifth entry ever to. That entry
exists to prevent "a box drawn around an arbitrary element", which is a
decoration a renderer sprinkles. A colour chip's outline is not one: a chip
painted `--color-base-100` sits on a `card-body` that is also
`--color-base-100`, so without it the control is not visible at all. It is the
same argument `border-b` / `border-r` already carry as `DashboardShell.edges`,
one step further round the box — one use site (`colorChipHtml`), the existing
`tokenBorderEdge` for its colour, and no caller can reach either, because
`Leaf.ColorChips` takes colours and labels and never a class. daisyUI's own
generator draws the same hairline on the same chip. `forbidden` is 20 entries.

### 8. Two tools extended, mechanically

- **`tools/render-class-audit.js`** strips a literal in `declaration "…"`
  position, exactly as it already strips one in `Attr.style "…" "…"` position:
  the first argument of `Daisy.Render.declaration` is a CSS *property* name on
  its way into a `style` attribute, and property names are class-shaped
  (`background-color`). Nothing else about the rule changed.
- **`e2e/lib/browser.ts`'s `collectFocusables`** no longer treats `opacity: 0`
  as hidden. It is the only one of that file's helpers that must not: a
  transparent element is still laid out, still hit-tested and still in the tab
  order, so the browser tabs to it whether the expected list contains it or not,
  and a list that omitted the twenty colour pickers was asserting a tab order
  the page does not have. The paint-facing helpers (`collectContrast`) keep the
  rule. Everything genuinely hidden on these pages is hidden with `display`,
  `visibility` (daisyUI's closed `drawer-side`), `aria-hidden` or `inert`.

Neither `e2e/a11y.spec.ts` nor `e2e/contrast.spec.ts` needed a change. Both
already decide "daisyUI's own colour pair" in the browser, on painted sRGB
bytes, against the root's `--color-*` values — so an inline-painted chip is
classified exactly like a class-painted one, which is why the chips are written
with `oklch()` rather than hex.

### 9. What the e2e suite gained

`e2e/theme-generator.spec.ts`'s colour test now also asserts the chip's painted
background, and its shape test drives the radius control as what it now is: a
radio group whose visible control is the `<label>` around an `sr-only` radio,
whose tile computes to `border-start-end-radius: 32px` at the `2rem` step, and
exactly one of whose five steps carries `btn-neutral`. All 36 `/theme`
screenshot baselines were regenerated (`e2e/snapshots/local/theme-*.png`); the
other 108 are byte-identical.

## Embed (2026-09-07)

The rule was "No `Raw Html` escape hatch. Ever." (SPEC.md step 3, CLAUDE.md
"Tree conventions"). It has been replaced, deliberately, by a narrower one:
**custom views enter the tree only through `Leaf.Embed`, boxed by the renderer,
themed through a `ThemeContext`, and unable to carry a class.** The old rule and
the new one answer different questions — the old one was about *markup* and the
new one is about *drawing* — and this section is why the swap does not cost any
of the four guarantees.

The forcing case is a conversion funnel. `Block.Chart` is a closed set of five
kinds over `terezka/elm-charts`, and a funnel is none of them: it is a run of
trapezoids whose width is a count and whose slope is the drop-off between two
stages. Every dashboard of the kind these demos reproduce has one, and the only
answers available were "add a sixth chart kind, then a seventh" or "record it in
`fixtures/rejected.md` forever".

### 1. The API

```elm
type Leaf msg
    = ...
    | Embed EmbedConfig (ThemeContext -> Html msg)

type alias EmbedConfig =
    { height : EmbedHeight     -- EmbedSm | EmbedMd | EmbedLg
    , label : String           -- role="figure" + aria-label
    }

type alias ThemeContext =
    { color : SemanticColor -> String   -- "var(--color-primary)", ...
    , surface : Surface -> String       -- Base100 | Base200 | Base300 | BaseContent
    , theme : Theme
    , radiusBox : String                -- "var(--radius-box)"
    }
```

`Daisy.Render.embedHtml` draws it as

```
<div class="relative overflow-hidden w-full h-64" role="figure" aria-label="...">
```

— every class a `Render.tokens` entry, the height one of three fixed steps
(`h-40` / `h-64` / `h-96`, 160/256/384px). `EmbedMd` is the same 16rem
`tokenChartHeight` pins, so an embed and a chart sit level in a `Cols2` grid.
The height is `h-`, not the chart's `min-h-`, and that difference is the whole
containment argument: a chart is drawn by this renderer, which knows the aspect
ratio it scales to, while an embed is drawn by the caller and this box is the
only thing bounding it. `min-h-` would let an embed grow the page and push the
next block down; a fixed height plus `overflow-hidden` cannot.

`embedConfig "Conversion funnel"` is the constructor, and there is deliberately
no `defaultEmbedConfig`: a label has no sensible default and an unlabelled
figure is the thing the config exists to prevent.

### 2. What is still guaranteed, and what is not

| Guarantee | Still holds? | How |
| --- | --- | --- |
| No contradictory modifiers | yes | An embed has no modifiers. It cannot name a daisyUI class at all. |
| No invalid nesting | yes | `Embed` is a `Leaf`. It cannot hold a block, a section or an overlay, and it cannot stand where one belongs — `tools/should-not-compile/Reject/EmbedAsBlock.elm` is both halves of that as one `TYPE MISMATCH` fixture. A modal opened from an embed is still a `Page.overlays` entry. |
| No visual overlap | yes | `relative overflow-hidden` at a fixed height. `e2e/embed.spec.ts` measures every descendant's rect against the box's and allows 1px of layout rounding; `e2e/overlap.spec.ts` and `e2e/overflow.spec.ts` see the box like any other element. |
| Page content budget | yes | Unchanged: an embed is a leaf, not a section, and cannot be a CTA. |
| **Class coverage** | **no** | `CoverageTest`, `PartsTest`, `ExclusivityTest`, the corpus and `tools/render-class-audit.js` all read classes back off markup, and an embed emits none. Nothing inside an embed is in the corpus, and nothing inside it can raise coverage. |
| Contrast, a11y, theme fidelity | yes | Those read the *painted page*, not the tree. `e2e/contrast.spec.ts` walks every text node (its `el.closest("svg")` skip already put chart chrome under `themes.spec.ts`, and the funnel's labels are SVG for the same reason), `e2e/a11y.spec.ts` runs axe over the whole document including the `role="figure"` box, and `themes.spec.ts`'s chart-colour sweep reads every `svg *` whose `stroke`/`fill` attribute is a `var(--color-*)` — which the funnel's bands now are, in all 36 themes. |

That is the trade, stated plainly: **the corpus and the class budget cannot see
inside an embed; overlap, overflow, contrast, a11y and the theme sweeps still
can.** An embed is therefore for a drawing daisyUI has no component for, never
for hand-writing markup a `Block` or a `Leaf` should express —
`docs/placement.md`'s "Known gaps" list is unchanged for exactly that reason.

### 3. No class, and how the lint says so

`NoHtmlInDemo` gained one path exemption: `demo/src/Viz/` (both spellings,
`src/Viz/` from the run inside `demo/` and `demo/src/Viz/` from a run that
reached it from the root). Modules there may import `Html`, `Html.Attributes`,
`Svg`, `Svg.Attributes` and anything else a drawing needs. `Demo.*` pages still
may not, so an embed cannot be inlined into a page and the boundary stays one
directory wide.

What the exemption does **not** relax is the class rule.
`NoClassOutsideRender` is keyed on the module name `Daisy.Render`, so a `Viz.*`
module calling `Html.Attributes.class` is reported like any other module, and
`NoRawSchemaStrings` still reports a daisyUI class written as a literal there.
Three rule tests pin all three facts (a `Viz.*` module may import
`Html.Attributes`; it may call `Attr.style`; it may not call `Attr.class`), and
a fourth pins the boundary — `Vizual.Funnel`, at `src/Vizual/Funnel.elm`, is
still reported.

The alternative considered and rejected: allow `class` with literals that are
neither schema classes nor Tailwind-looking. That needs a "Tailwind-looking"
predicate, which is a heuristic; a heuristic in a lint rule is a rule nobody can
state. "No class attribute in an embed" is one sentence, and it costs an embed
nothing — inline `style`, SVG presentation attributes and the four
`ThemeContext` fields are a complete palette for a drawing.

`RenderPurityTest` carries the same claim dynamically, on a fixed sample embed
(`Helpers.Fixtures.embedLeaf`): its markup carries no `Schema.allClasses` class
at all, everything the *box* carries is inside the budget, and the box is
`role="figure"` with the label. `e2e/embed.spec.ts` repeats the first of those
on the painted page, so a class arriving some other way would still be caught.

### 4. The one thing the tree lost: value equality

`Tree` now holds a function, so a `Page` containing an embed is not
`Expect.equal`-comparable — Elm cannot compare functions, and the comparison
crashes rather than fails. `RenderPurityTest.staticPage`, the fixture behind
"equal trees render to equal `Html`", therefore excludes `Embed` and says so in
a comment. Embeds are still covered everywhere else in that module:
`Helpers.Fixtures.leaves` holds one at each of the three heights, so the class
budget, the `forbidden` list and the "renders identically twice" check (which
compares *printed markup*, not values) all see them. What is lost is the value
equality claim, and only for trees that contain an embed.

### 5. Threading the theme

`ThemeContext.theme` is the page's real `Theme`, which meant `Daisy.Render` had
to carry it from `page` down to the leaf. About forty internal functions gained
a `Theme` parameter; the four exposed lower-level renderers (`section`,
`block`, `leaf`, `overlay`) kept their signatures and pass
`Render.standaloneTheme` = `Light`, the theme daisyUI itself falls back to when
no `data-theme` is set. Nothing the renderer *draws* depends on it — every
colour it emits is a `var(--color-*)` the browser resolves against whatever
`data-theme` is in force — so the value reaches exactly one place, and a
standalone `Render.leaf` reporting `Light` cannot make a render wrong. It is
there for the embed that has to branch on light and dark rather than on a
variable: a hatch pattern, a shadow.

### 6. The example

`demo/src/Viz/Funnel.elm`, in the Analytics page's "Conversion funnel" card as
`CardLeaf (Embed (embedConfig "Conversion funnel") Viz.Funnel.view)`. Four
stages (Visitors 12,480 -> Signups 5,120 -> Trials 2,050 -> Paid 820), three
bands. `Scale.linear` maps a count to a half-height with the domain anchored at
zero — so a band half as wide is half the conversions, not "somewhat fewer" —
and `Shape.area Shape.linearCurve` over two x positions generates each
trapezoid, rendered by `Path.element`. `gampleman/elm-visualization` 2.4.3 and
`folkertdev/one-true-path-experiment` 6.0.1 are **demo** dependencies; the
package's own `elm.json` is untouched, which is the point of the boundary.

Colours: the bands are `ctx.color Primary` / `Secondary` / `Accent`, the plate
behind them `ctx.surface Base200`, the hairline between bands
`ctx.surface Base100`, every label `ctx.surface BaseContent`. No colour value
appears in the module. `e2e/embed.spec.ts` asserts each band's computed `fill`
equals the theme's own `--color-primary` / `--color-secondary` /
`--color-accent` in `light`, `dark`, `nord` and `acme` — `acme` being the demo's
`Theme.Custom`, whose variables exist only as inline properties on the page
root, so an embed is proven to reach a theme no stylesheet declares.
`themes.spec.ts`'s chart-colour sweep covers the same fills in all 36 themes for
free, because the funnel's SVG attributes are `var(--color-*)` exactly like a
chart series'.

