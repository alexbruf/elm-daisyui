# Component placement

Every one of the 68 daisyUI docs components (`vendor/daisyui/packages/docs/src/routes/(routes)/components/*/+page.md`)
is assigned to exactly one level of `Daisy.Tree` before any Elm is written. Nothing may be placed twice; a
component that is referenced from more than one place (e.g. `menu`) is *placed* once and *referenced* elsewhere
by its named type.

## Level definitions

| Level | Meaning |
|---|---|
| **Page** | Page shell, theme (a built-in name or a whole `CustomTheme`), the page header, or the single primary CTA. Chrome that lives outside the section flow. Rendered by `Daisy.Render` from fields on `Page`/`Shell`, never as a `Section`/`Block`/`Leaf`. `Page.header : Maybe (PageHeader msg)` (`{ title, breadcrumbs, actions }`) is here rather than at Section for exactly that reason: a dashboard's title bar is chrome, and the five-section budget is content. `Shell.Dashboard` carries `DashboardShell = { brand, sidebar, sidebarFooter, navbar }`. |
| **Section** | A top-level band of the page. Constructors are exactly `Hero`, `Navbar`, `Footer`, `Grid`, `Stack`. `Navbar` contains Leaves; `Hero`, `Footer`, `Grid`, `Stack` contain Blocks. Max 5 per page (`Sections1`..`Sections5`). |
| **Block** | A self-contained content container that sits directly inside a Section. Contains Leaves, or a closed record/list of its own part records. Never contains another Block. |
| **Leaf** | A terminal control or piece of content. Contains only data (`String`, `Float`, config), never another node. Leaves live inside Blocks, inside `Navbar`, or inside `Toast`/`Modal` via a Block. |
| **Overlay** | `Modal`, `Drawer`, `Toast` only. Lives exclusively in `Page.overlays` and is rendered after all sections in one fixed wrapper (order: drawer, modal, toast). |
| **Property** | Not a node at all: a field on another node's config (like `tooltip` and `dropdown`). The renderer emits the wrapper element and the classes; the author cannot place it standalone. |
| **Parts-of** | Only exists as a part record inside one named parent (e.g. `card-body` inside `Card`). Has no constructor of its own, so it is unrepresentable outside its parent. |
| **Excluded** | Cannot be placed without an escape hatch. Its classes must be listed as expected-uncovered in `CoverageTest`, and its docs examples go in `fixtures/rejected.md`. **Now empty** — see the Excluded section. |

Two support types are not daisyUI components and appear in the tree anyway: `Block.Prose` (Tailwind typography)
and `Block.Chart` (`Daisy.Chart` over `terezka/elm-charts`). `Leaf.Image` is also not a daisyUI component but is
required by `card` (figure), `carousel`, `diff`, `stack`, `avatar` and `hover-gallery`; it emits no daisyUI class
of its own, only the `mask` / `hover-3d` properties. `Leaf.Heading` is the third: it renders a bare
`<h1>`/`<h2>`/`<h3>` and emits no class at all, so that a page has a document outline for Tailwind typography
(inside `Block.Prose`) and for assistive technology to read. `Leaf.Icon` is the fourth, for the same reason
`Image` is there: daisyUI's own dashboard examples draw an inline `<svg>` inside a `menu` item, a `stat-figure`
and a `btn`, and there is no daisyUI component for one. It emits no daisyUI class either — only a `size-*`
token — and its drawing comes from the closed `Daisy.Icon` set, never from a caller-supplied path.

`Section.Stack` (a fixed-gap vertical layout band) is **not** the daisyUI `stack` component. The daisyUI `stack`
component (overlapping children) is placed at Block as `Block.Stacked`. See Unsure.

## Placement table

| Component | Level | Tree constructor | Children | Reason |
|---|---|---|---|---|
| accordion | Block | `Block.Accordion` | `List (AccordionItem msg)`, each a parts record `{ title : String, content : List (Leaf msg) }` | Radio-grouped set of `collapse` items; a self-contained content container that sits in a Grid/Stack cell. |
| alert | Block | `Block.Alert` | `List (Leaf msg)` | Fixed by the spec sketch; an alert is a container of text/buttons, and it is what a `toast` holds. |
| aura | Property | field `aura : Maybe AuraConfig` on `CardConfig`, `ButtonConfig`, `Page.cta` | none | A decorative border-light wrapper with no content of its own; daisyUI wraps one existing element ("aura around a button", "aura around a pricing card"). |
| avatar | Leaf | `Leaf.Avatar`, `Leaf.AvatarGroup` | `Leaf.Avatar AvatarConfig ImageSrc`; `Leaf.AvatarGroup (List AvatarConfig)` (data, not nodes) | A terminal thumbnail. `avatar-group` is in the `component` group, not `part`, so it is a second constructor over plain config data. |
| badge | Leaf | `Leaf.Badge` | `String` | Fixed by the spec sketch; a terminal status label, used inside table rows, menu items and card bodies. |
| breadcrumbs | Block | `Block.Breadcrumbs` | `List (Leaf msg)` (Link/Text leaves) | A `<div class="breadcrumbs">` wrapping a `<ul>` of links: it holds multiple leaves, so it cannot be a Leaf. |
| button | Leaf | `Leaf.Button` | `String` label | Fixed by the spec sketch. `ButtonColor` omits `Primary`; the only primary button is `Page.cta`. |
| calendar | Leaf | `Leaf.Calendar` | `CalendarConfig msg` + `CalendarState` (data, not nodes) | A terminal control. `cally` is the theming hook for the Cally *web component*, and `alexbruf/elm-cally` is a pure-Elm port of it that renders the same markup and the same `part` attributes in the light DOM — so the class lands on a real picker and no foreign markup or JS mount is needed. `react-day-picker` and `vc` stay unreachable (see Excluded). Moved here 2026-09-07; see `docs/tree-decisions.md`, "Calendar via elm-cally". |
| card | Block | `Block.Card` | `CardParts msg` = `{ figure : Maybe (Leaf msg), title : Maybe String, titleIcon : Maybe Icon, headerTabs : Maybe (TabsSpec msg), headerActions : List (Leaf msg), body : List (CardChild msg), actions : List (Leaf msg) }` | Fixed by the spec sketch; `card-title`/`card-body`/`card-actions` are `part` classes, so a parts record makes `card-body` outside a card unrepresentable. `CardChild` is `CardLeaf`/`CardAlert`/`CardChart`/`CardChat`/`CardTable`/`CardStat`/`CardForm` — the block shapes a dashboard card is made of, with no `CardCard`, so a card still cannot hold a card. `titleIcon`/`headerTabs`/`headerActions` are the card's **header row** (glyph and title left, segmented control and controls right): every dashboard card in daisyUI's templates has one, and keeping it in the parts record means the renderer owns the alignment rather than each caller inventing a flex container (2026-09-07). |
| carousel | Block | `Block.Carousel` | `List (CarouselItem msg)`, each `{ content : List (Leaf msg) }` (the `carousel-item` part) | A scroll-snap container of items; sits directly in a Section like any other content container. |
| chat | Block | `Block.Chat` | `List (ChatMessage msg)`, each a parts record `{ placement, image, header, footer, bubble }` | `chat-image`/`chat-header`/`chat-footer`/`chat-bubble` are `part` classes and repeat per message, so one parts record per message inside a Block-level list. |
| checkbox | Leaf | `Leaf.Checkbox` | `CheckboxConfig` only | A terminal form control; used both inside a `Form` field and standalone inside a table row header. |
| collapse | Block | `Block.Collapse` | parts record `{ title : String, content : List (Leaf msg) }` | Single collapsible container with `collapse-title`/`collapse-content` parts. Shares CSS with `accordion`; the two constructors differ only in whether the renderer emits a grouping radio `name`. |
| countdown | Leaf | `Leaf.Countdown` | `Float`/`Int` value | `<span class="countdown">` holding numeric spans; terminal content. |
| diff | Block | `Block.Diff` | parts record `{ item1 : Leaf msg, item2 : Leaf msg }` (`diff-resizer` emitted by the renderer) | `diff-item-1`/`diff-item-2`/`diff-resizer` are `part` classes; the whole figure is a content container in a Section. |
| divider | Leaf | `Leaf.Divider` | `Maybe String` label | Appears between leaves inside a card body, form or prose block. Spacing between Blocks/Sections is handled by `Render.tokens`, not by this component. |
| dock | Page | field `dock : Maybe (Dock msg)` on `Page` (rendered in the fixed chrome layer) | `Dock` holds `List DockItem` (`{ icon, label, active }`, `dock-label` part) | Viewport-fixed bottom navigation. Placed in a Section it would intersect content and break `overlap.spec`; it is shell chrome, like the navbar. |
| drawer | Overlay | `Overlay.Drawer` | `List (Section msg)` | Fixed by the spec. Also referenced (not re-placed) by `Shell.Dashboard`, which renders `drawer` + `drawer-open` at `lg:` with the sidebar `menu` and the `navbar`; that is the only `drawer` outside `Overlay`. |
| dropdown | Property | field `dropdown : Maybe (Dropdown msg)` on `ButtonConfig`, `LinkConfig`, `AvatarConfig` | `Dropdown` holds a `Menu msg` or `List (Leaf msg)` (the `dropdown-content` part) | Fixed by the spec: dropdown is a property on a Leaf, not a node, so it always has an anchor and lands in the renderer-managed overlay layer. |
| fab | Page | field `fab : Maybe (Fab msg)` on `Page` (fixed chrome layer) | `Fab` holds `{ main : Leaf msg, mainAction : Maybe (Leaf msg), actions : List (Leaf msg), close : Maybe (Leaf msg) }` (`fab-main-action` goes on the `mainAction` leaf itself, `fab-close` on a wrapper) | Viewport-fixed floating action button that overlaps page content by design; same argument as `dock`. |
| fieldset | Parts-of | part record inside `Block.Form`: `Fieldset msg = { legend : Maybe String, fields : List (Field msg) }` | `List (Field msg)` | `fieldset-legend` is a `part`, and a fieldset only ever means something inside a form. Making it a record makes a stray legend unrepresentable. |
| file-input | Leaf | `Leaf.FileInput` | `FileInputConfig` only | Terminal form control, used as a `Field.control`. |
| filter | Leaf | `Leaf.Filter` | `{ name : String, options : List String, selected : Maybe String, reset : Maybe FilterReset }` (data) | A `<form class="filter">` of radio inputs styled as buttons plus an optional reset input: one logical control, all of whose content is plain data. `FilterReset` is `ResetPart` (the `filter-reset` part) or `ResetButton` (the plain `btn btn-square` the `<form>` idiom uses). |
| footer | Section | `Section.Footer` | `List (Block msg)` — in practice `Block.Nav` columns | Fixed by the spec. `footer-title` is emitted only when a `Block.Nav` is a direct child of a Footer, so the part never escapes its component. |
| hero | Section | `Section.Hero` | `List (Block msg)` | Fixed by the spec. `hero-content` wraps the blocks and `hero-overlay` comes from `HeroConfig.overlay`; both parts are renderer-emitted. |
| (heading) | Leaf | `Leaf.Heading` | `HeadingLevel` (`H1`/`H2`/`H3`) + `String` | Not a daisyUI component and emits no daisyUI class. A page otherwise has no `<h1>`: `Leaf.Text` is a text node and `Block.Prose` is a `<div>`, so Tailwind typography had nothing to style and axe reported `page-has-heading-one` on every demo. |
| (icon) | Leaf | `Leaf.Icon` | `IconConfig` (`size : IconSize`, `label : Maybe String`) + `Daisy.Icon.Icon` | Not a daisyUI component and emits no daisyUI class, like `Leaf.Heading` and `Leaf.Image`. A closed set of 25 heroicons outline drawings; the path data lives in the internal `Daisy.Render.Icons`, so `Daisy.Icon` stays pure data and no caller can hand the renderer markup. Also reachable as `MenuItem.icon`, `ButtonConfig.icon` and `Cta.icon`, which is where daisyUI's dashboard templates put glyphs. |
| (swatch) | Leaf | `Leaf.Swatch` | `SwatchConfig` + `SwatchColor` + `String` label | Not a daisyUI component and emits no daisyUI class, like `Leaf.Heading` and `Leaf.Icon` — but unlike them it emits *colour*. A theme editor has to show the colour it is editing, and daisyUI ships no component whose job is that: every colour class it has belongs to a control. `SwatchColor` is a closed eleven-value slot name (three base surfaces plus the eight semantic colours), and `Daisy.Render.swatchClasses` maps each to one `bg-*` / `text-*-content` token pair — the only colour tokens in the table, each with exactly one use site. The caller names a slot, never a class. Added 2026-09-07; see `docs/tree-decisions.md`, "Custom themes and the generator page". |
| hover-3d | Property | field `hover3d : Bool` on `ImageConfig` and `CardConfig` | none | Decoration only: a wrapper plus eight empty divs the renderer emits. It has no authorable content. |
| hover-gallery | Leaf | `Leaf.HoverGallery` | `List ImageSrc` (data) | A `<figure class="hover-gallery">` whose children are only `<img>` tags: terminal content with no nodes inside. |
| indicator | Property | field `indicator : Maybe (Indicator msg)` on Leaf configs (Button, Avatar, Input, Link) | `Indicator` holds `IndicatorConfig` + a `Badge`/`Status` payload (the `indicator-item` part) | Same shape as `tooltip`/`dropdown`: a wrapper that decorates exactly one anchor element. Placing it as a node would let `indicator-item` appear without an anchor. |
| input | Leaf | `Leaf.Input` | `InputConfig` only | Fixed by the spec sketch; the canonical terminal form control. `InputConfig` also carries the HTML validation constraints (`inputType`, `required`, `pattern`, `minLength`, `maxLength`) daisyUI's `validator` / `validator-hint` pair needs to ever fire, plus `ariaLabel`, plus `icon : Maybe Icon` (2026-09-07). `icon` selects between daisyUI's two documented shapes for a field: without one it is a plain `<input class="input">`, with one the component class moves to a `<label>` and the glyph sits inside beside a bare growing `<input>`. |
| join | Leaf | `Leaf.Join` | `List (JoinItem msg)`, a closed non-recursive type (`JoinButton`/`JoinInput`/`JoinSelect`/`JoinText`) | It groups adjacent *controls* into one unit and must be usable as a `Field.control` (docs: "Fieldset with multiple join items") and inside a Navbar, both of which only accept Leaves. `JoinItem` being a separate type keeps `Leaf` non-recursive. |
| kbd | Leaf | `Leaf.Kbd` | `String` | Terminal inline content. |
| label | Parts-of | fields on `Field msg`: `{ label : Maybe String, labelPlacement : Start \| End \| Floating }` | none | `label` and `floating-label` only wrap or precede a control; as a record field the label cannot exist without its input. |
| link | Leaf | `Leaf.Link` | `String` | Fixed by the spec sketch. |
| list | Block | `Block.ListBlock` (no config) | `List (ListRow msg)`, each `{ cells : List (ListCell msg) }`, a cell being `{ content : Leaf msg, grow : Bool, wrap : Bool }` | A `<ul class="list">` of `list-row` items holding images, text and buttons: structurally a Table-like Block. `list-col-grow` / `list-col-wrap` mark one *cell*, so they are flags there and the block has no config left at all. |
| loading | Leaf | `Leaf.Loading` | `LoadingConfig` only | Terminal spinner glyph. |
| mask | Property | field `mask : Maybe Mask` on `ImageConfig` and `AvatarConfig` | none | A clip-path shape applied to one existing element ("Avatar with mask"); it has no children and cannot stand alone. |
| megamenu | Leaf | `Leaf.Megamenu` | `List MegamenuItem` where `MegamenuItem = { label : String, menu : Menu msg }` (data) | It belongs in a `Navbar`, which accepts Leaves only. All its content is a closed list of labelled menus; the renderer generates the `popover`/`popovertarget` ids and the `megamenu-active` part. |
| menu | Block | `Block.Menu MenuConfig (List (MenuItem msg))`; the same `Menu msg` type is *referenced* by `Shell.Dashboard.sidebar` and by the `dropdown` property | `List (MenuItem msg)` where `MenuItem = { label, icon, badge, active, disabled, submenu : List MenuItem }` (`menu-title`, `menu-dropdown*` parts) | Placed at Block because a menu is a content container of links that must be usable as page content (nav card, file tree, in-page navigation). Defining it as a named type lets `Shell.Dashboard` reuse it for the sidebar without a second placement. See Unsure for the navbar case. |
| mockup-browser | Block | `Block.MockupBrowser` | parts record `{ toolbar : Maybe String, content : List (Leaf msg) }` (`mockup-browser-toolbar`) | A framing container for content; sits in a Section like a Card. |
| mockup-code | Block | `Block.MockupCode` | `List CodeLine` (`{ prefix : Maybe String, text : String }`) | A framing container whose content is plain lines of text. |
| mockup-phone | Block | `Block.MockupPhone` | parts record `{ content : List (Leaf msg) }` (`mockup-phone-camera`, `mockup-phone-display` emitted by the renderer) | Framing container, same as the other mockups. |
| mockup-window | Block | `Block.MockupWindow` | parts record `{ title : Maybe String, content : List (Leaf msg) }` | Framing container, same as the other mockups. |
| modal | Overlay | `Overlay.Modal` | `List (Block msg)` | Fixed by the spec. `modal-box`/`modal-action`/`modal-backdrop`/`modal-toggle` are parts emitted by the renderer, so a modal can never appear inside a Block. |
| navbar | Section | `Section.Navbar` | `NavbarParts msg = { start : List (Leaf msg), center : List (Leaf msg), end : List (Leaf msg) }` | Fixed by the spec (Navbar contains Leaves). The three `navbar-*` classes are `part` classes, so the Leaves are held in a parts record rather than one flat list. See Unsure. |
| otp | Leaf | `Leaf.Otp` | `OtpConfig` + `{ digits : Int }` | A single logical input control made of N boxes; all content is data. |
| pagination | Block | `Block.Pagination` | `{ pages : List String, active : Int }` (data) | It is a page-navigation element that sits as a *sibling* of a `Table` or `List` block, and neither Table rows nor Card parts can hold it. Uses the same `join`/`join-item` CSS as `join`. |
| progress | Leaf | `Leaf.Progress` | `{ value : Maybe Float, max : Float }` | Terminal `<progress>` element. |
| radial-progress | Leaf | `Leaf.RadialProgress` | `{ value : Float, label : String }` | Terminal element; its size/thickness are CSS variables, not classes. |
| radio | Leaf | `Leaf.Radio` | `RadioConfig` + `{ name : String }` | Terminal form control. |
| range | Leaf | `Leaf.Range` | `RangeConfig` + `{ min, max, value }` | Terminal form control. |
| rating | Leaf | `Leaf.Rating` | `RatingConfig` (`shape : Maybe SMask.Style`, `modifiers : List RatingModifier`) + `{ name, count, value, clearable }` | Terminal form control; its stars are `mask` shapes, chosen by `shape` (default `mask-star-2`). `rating-hidden` belongs on the blank first radio, so it is `clearable` on the data, not a container modifier. |
| select | Leaf | `Leaf.Select` | `SelectConfig` + `{ options : List String, selected : Maybe String }` | Terminal form control. Required as a Navbar Leaf by the Analytics demo (date range). |
| skeleton | Leaf | `Leaf.Skeleton` | `SkeletonConfig` only | A placeholder shape with no content. |
| stack | Block | `Block.Stacked` | `List (Leaf msg)` | daisyUI `stack` overlaps its children; it is a content container in a Section, so Block is its level. Named `Stacked` because `Section.Stack` already exists and is a different thing. See Unsure. |
| stat | Block | `Block.Stat` | `StatConfig` (`direction : StatDirection` = `Fixed (Maybe Direction)` or `Responsive`) + `List (StatItem msg)`, each a parts record `{ figure, title, value, trend, desc, actions }` (`trend` is a `Leaf` on the `stat-value` line — the delta badge every dashboard metric carries, 2026-09-07) | The component class is `stats`; `stat`, `stat-title`, `stat-value`, `stat-desc`, `stat-figure`, `stat-actions` are `part` classes that repeat per tile, so the Block holds a list of part records. See Unsure. |
| status | Leaf | `Leaf.Status` | `StatusConfig` only | A terminal coloured dot, typically used as the payload of an `indicator` or inside a table cell. |
| steps | Block | `Block.Steps` | `List (Step msg)`, each `{ label : String, color : Maybe StepColor, icon : Maybe String }` (`step`, `step-icon` parts) | Progress container placed in a Section; its per-step colour lives on the `step` part, not the container. |
| swap | Leaf | `Leaf.Swap` | `{ on : String, off : String, indeterminate : Maybe String }` (the three part classes) | One checkbox-driven control with exactly two/three fixed faces: terminal. |
| tab | Block | `Block.Tabs` | `List (Tab msg)`, each `{ label : String, content : List (Leaf msg) }` (`tab`, `tab-content` parts) | A content container that owns its panels; sits in a Section like a Card. |
| table | Block | `Block.Table TableConfig (List (Row msg))` | `List (Row msg)` where `Row = { cells : List (Leaf msg) }` | Fixed by the spec. Rows hold Leaves, which is what the Admin demo's badge + row-action button needs. |
| textarea | Leaf | `Leaf.Textarea` | `TextareaConfig` only | Terminal form control. |
| text-rotate | Leaf | `Leaf.TextRotate` | `List String` | Terminal animated text; its children are only words. |
| theme-controller | Leaf | `Leaf.ThemeSelect` | `{ themes : List Theme, current : Theme, presentation : ThemePresentation }` (data) | The class only ever sits on a checkbox/radio/select input whose `value` is a theme name. `ThemeAsDropdown` is the compact presentation (daisyUI's documented `dropdown` + `dropdown-content` radios); every other one is a sibling control per theme, which is 35 controls wide with `allThemes`. As a Leaf it can go in the Navbar (Admin demo). `Page.theme` sets the initial `data-theme` on the shell; `ThemeSelect` is the control that changes it. `ThemeSelectData.themes` is a `List Theme`, so it can offer a `Theme.Custom` beside the thirty-five built-ins — the control writes the whole `Theme`, and `Daisy.Render.page` decides whether that means a `data-theme` name alone or a name plus twenty-nine inline custom properties. See Unsure. |
| timeline | Block | `Block.Timeline` | `TimelineConfig` (`modifiers : List TimelineModifier`, which omits `timeline-box`) + `List (TimelineItem msg)`, each a parts record `{ start, startBox, middle, end, endBox }` | `timeline-start`/`-middle`/`-end` are `part` classes repeating per item; the container is a content block in a Section. `timeline-box` sits on one *side of one item*, so it is `startBox` / `endBox` there. |
| toast | Overlay | `Overlay.Toast` | `List (Block msg)` (in practice `Block.Alert`) | Fixed by the spec as an Overlay. Children changed from `List Leaf` to `List Block` because every daisyUI toast example contains `alert`. See Unsure. |
| toggle | Leaf | `Leaf.Toggle` | `ToggleConfig` + `{ checked : Bool }` | Terminal form control; required by the Settings demo as a `Field.control`. |
| (user chip) | Leaf | `Leaf.UserChip` | `UserChipConfig msg` + `UserChipData` = `{ avatar, name, subtitle }` (data, not nodes) | **Not a daisyUI component**, like `Leaf.Icon` and `Leaf.Heading`: it is the portrait-plus-two-lines composite daisyUI's dashboard templates put in a navbar and in a sidebar footer, and it is the one shape the tree could not otherwise express — a `Leaf` is terminal, so stacking two lines of text beside an image needs either a container leaf (which hands arbitrary layout back to the caller) or one named composite. It emits `avatar` and `mask mask-squircle` plus tokens, nothing else. Added 2026-09-07; see `docs/tree-decisions.md`, "Nexus design pass". |
| tooltip | Property | field `tooltip : Maybe Tooltip` on every Leaf config | `Tooltip = { text : String, config : TooltipConfig }` (`tooltip-content` part) | Fixed by the spec: tooltip is a property on a Leaf, not a node. |
| validator | Parts-of | fields on `Field msg`: `{ validate : Bool, hint : Maybe String }` | none | `validator` goes on the input itself and `validator-hint` must be the immediately following sibling; only a record keeps the two adjacent and makes an orphan hint unrepresentable. |

## Unsure

Every placement below was a real decision, not a guess. The level is stated in the table; here is the rejected
alternative and why.

1. **stat — children shape.** Chosen: `Block.Stat StatConfig (List (StatItem msg))` with a parts record per tile.
   Rejected: the spec sketch's `Stat StatConfig (List (Leaf msg))`. `stat-title`/`stat-value`/`stat-desc` are `part`
   classes and there is no Leaf that can carry them, so `List Leaf` would either need three new Leaf constructors
   holding part classes (breaking `PartsTest`, which requires every part to have a matching component ancestor —
   it would pass, but the part could then be placed outside `stats`) or lose the parts entirely. Level is Block
   either way.
2. **navbar — children shape.** Chosen: `Section.Navbar NavbarConfig (NavbarParts msg)` with `start`/`center`/`end`
   lists of Leaves. Rejected: the spec sketch's flat `List (Leaf msg)`, because `navbar-start`/`-center`/`-end` are
   `part` classes and the same rule that forbids `card-body` outside a `Card` applies here; a flat list would force
   the renderer to invent a distribution rule. Still "Navbar contains Leaves" as the spec requires.
3. **toast — children shape.** Chosen: `Overlay.Toast ToastConfig (List (Block msg))`. Rejected: `List (Leaf msg)`,
   because all four docs examples wrap the message in `alert`, which is a Block. `Modal` already takes `List Block`,
   so this keeps the two overlays consistent and needs no new level rule.
4. **menu — Block vs Page-only.** Chosen: placed at Block (`Block.Menu`) with the named type `Menu msg` referenced
   by `Shell.Dashboard.sidebar` and by the `dropdown` property. Rejected: placing it at Page (sidebar only), which
   would make daisyUI's own standalone menu, file-tree and in-card menu examples inexpressible, and rejected
   defining two constructors (one per location), which would place one component twice. Consequence: a horizontal
   `menu` **inside a Navbar is not expressible** — Navbar accepts Leaves and `Block.Menu` is a Block. Navbar
   navigation is expressed as `Leaf.Link` items (visually identical to daisyUI's `menu menu-horizontal` of links)
   or as `Leaf.Megamenu`. Navbar-with-menu docs examples go in `rejected.md`.
5. **theme-controller — how it maps.** Chosen: `Leaf.ThemeSelect` (a dropdown of `theme-controller` radio inputs),
   with `Page.theme` supplying the initial `data-theme`. Rejected: making it a *property* of `Page.theme` only
   (no control renderable, so the Admin demo's "theme switcher in navbar" would be inexpressible), and rejected a
   `Leaf.ThemeToggle` variant per docs example (toggle/checkbox/swap/radio/dropdown are five presentations of one
   control; one Leaf with a `presentation` field in its config covers them without five constructors).
   Note `theme-controller` has no group classes at all — its whole config is data.
6. **stack (daisyUI) — name and level.** Chosen: `Block.Stacked`. Rejected: mapping daisyUI `stack` onto
   `Section.Stack`, which is a different thing (a fixed-gap vertical band) and would make every section's children
   overlap. Flag for the e2e author: `Block.Stacked` overlaps its children *by design*, so `overlap.spec` needs the
   `stack` class as an exempted ancestor, or `Block.Stacked` must not appear in the demos.
7. **join vs pagination — split levels.** Chosen: `join` at Leaf (with a closed `JoinItem` type) and `pagination`
   at Block. Rejected: both at Block (then `join` cannot be a `Field.control` or a Navbar item, losing the
   fieldset-with-join and navbar-search examples) and both at Leaf (then a pagination bar under a `Table` would
   have no Block to live in, since `Table` holds Rows and `Card` parts hold Leaves only). They share CSS
   (`join`, `join-item`); the schema generator produces two modules for it, which is expected.
8. **divider — Leaf vs Block.** Chosen: Leaf, so it can separate controls inside a card body, form or prose block.
   Rejected: Block, which would let a divider sit between Blocks but forbid the far more common in-card use;
   between-Block spacing is already owned by `Render.tokens`.
9. **breadcrumbs — Block vs Leaf.** Chosen: Block, because it holds a list of Link leaves and Leaves may not
   contain Leaves. Rejected: Leaf with `List String` data, which loses per-crumb `msg` handlers and icons.
10. **dock and fab — Page vs Overlay.** Chosen: Page (fields on the shell, rendered in the fixed chrome layer).
    Rejected: Overlay, because the spec fixes `Overlay` to exactly Modal, Drawer and Toast. Both are viewport-fixed
    and would break `overlap.spec` if placed in a Section.
11. **megamenu — Leaf vs Property of Navbar.** Chosen: `Leaf.Megamenu`, so it composes into the Navbar's Leaf lists
    like any other navbar item. Rejected: a `megamenu : Maybe (Megamenu msg)` field on `NavbarConfig`, which would
    allow at most one per navbar and could not express the standalone-megamenu docs examples.
12. **aura and hover-3d — Property vs Excluded.** Chosen: Property. Rejected: Excluded — both are pure wrappers
    (`aura` a rotating-border div, `hover-3d` a div plus eight empty divs) that the renderer can emit
    deterministically around exactly one child, so no escape hatch is needed.
13. **accordion vs collapse — two constructors over one CSS component.** Chosen: `Block.Accordion` and
    `Block.Collapse`, differing only in whether the renderer emits a shared radio `name`. Rejected: one constructor
    with a `grouped : Bool` field, which would be smaller but makes the two docs pages map to the same tree node
    and complicates the corpus test's per-page mapping.
14. **`placement` groups that are really two axes.** `toast`, `dropdown`, `indicator` and `modal` each declare one
    `placement` group that in daisyUI combines freely along two axes (`toast-top` + `toast-end`,
    `dropdown-bottom` + `dropdown-end`, `indicator-middle` + `indicator-start`, `modal-bottom` + `modal-start`).
    A single `Maybe Placement` field satisfies `ExclusivityTest` (which treats the whole declared group as
    pick-at-most-one) but makes corner placements inexpressible. Chosen: one `Maybe Placement` field, staying
    faithful to the schema and the test. Consequence: corner-placement docs examples go in `rejected.md`.
    `chat` (`chat-start`/`chat-end`) and `divider` (`divider-start`/`divider-end`) are genuinely single-axis and
    are unaffected.
15. **`carousel` modifier group is really exclusive.** `carousel-start`/`-center`/`-end` are declared under
    `modifier` (a set) but are mutually exclusive snap positions. Chosen: keep the generated
    `modifiers : List Carousel.Modifier` as the schema declares, and have `CarouselConfig` expose a single
    `snap : Maybe Snap` convenience that the renderer expands into one modifier. Same situation for
    `stack` (`stack-top`/`-bottom`/`-start`/`-end`).

## Excluded

No component is excluded any more. `calendar` was the only one, and it moved to
Leaf on 2026-09-07 (see the row above): `alexbruf/elm-cally` is a pure-Elm port
of the Cally web component, so `Leaf.Calendar` produces the very markup and
`part` attributes `cally` styles, with no ports, no custom element and no
shadow DOM.

Two of `calendar`'s three `component` classes are still **unreachable**, which
is a narrower thing than an excluded component and is recorded in
`Daisy.Render.unreachableClasses` rather than here:

| Class | Reason |
|---|---|
| `react-day-picker` | The theming hook for the React DayPicker *component*. This package renders Elm, not React, so there is nothing for the class to sit on. |
| `vc` | The theming hook for Vanilla Calendar Pro, a JavaScript library that builds its own DOM after mounting. Emitting the class without mounting it would style nothing. |

`CoverageTest` lists exactly those two (plus the drawer's two Tailwind variant
prefixes) as expected-uncovered. All 68 components are placed.

## Config field inventory

For each placed component, the exclusive-group fields its `XConfig` record needs (each `Maybe <Group>` from
`Daisy.Schema.<Component>`) plus whether the `modifier` / `behavior` set fields are present. Every config also
gets `modifiers : List X.Modifier` **only if** the modifier column says yes; components with no groups at all get
a config that is either a type alias for `{}` or is omitted entirely (noted in the last column). Every config needs
a `defaultXConfig`.

Legend for the group columns: `-` = group absent in frontmatter, otherwise the number of classes in that group.

| Component | color | style | size | direction | placement | variant | modifier | behavior | Notes |
|---|---|---|---|---|---|---|---|---|---|
| accordion | - | - | - | - | - | - | 4 | - | parts: collapse-title, collapse-content |
| alert | 4 | 3 | - | 2 | - | - | - | - | |
| aura | - | 6 | 5 | - | - | - | - | - | property config |
| avatar | - | - | - | - | - | - | 3 | - | `component` has 2 classes: `avatar`, `avatar-group` |
| badge | 8 | 4 | 5 | - | - | - | - | - | |
| breadcrumbs | - | - | - | - | - | - | - | - | no groups; config may be omitted |
| button | 8 (Tree omits `btn-primary`) | 5 | 5 | - | - | - | 4 | 2 | Tree's `ButtonColor` has 7 constructors; `Page.cta` uses the schema type with `Primary` |
| card | - | 2 | 5 | - | - | - | 2 | - | parts: card-title, card-body, card-actions |
| carousel | - | - | - | 2 | - | - | 3 | - | part: carousel-item; modifier group is really exclusive (see Unsure 15) |
| chat | 8 | - | - | - | 2 | - | - | - | colour applies to the `chat-bubble` part, not the container |
| checkbox | 8 | - | 5 | - | - | - | - | - | |
| collapse | - | - | - | - | - | - | 4 | - | parts: collapse-title, collapse-content |
| countdown | - | - | - | - | - | - | - | - | no groups |
| diff | - | - | - | - | - | - | - | - | parts only: diff-item-1, diff-item-2, diff-resizer |
| divider | 8 | - | - | 2 | 2 | - | - | - | |
| dock | - | - | 5 | - | - | - | 1 | - | part: dock-label |
| drawer | - | - | - | - | 1 | 2 | 1 | - | variant classes are the `is-drawer-open:`/`is-drawer-close:` selector prefixes; parts: drawer-toggle/-content/-side/-overlay/-button |
| dropdown | - | - | - | - | 7 | - | 3 | - | part: dropdown-content; placement is two axes (Unsure 14) |
| fab | - | - | - | - | - | - | 1 | - | parts: fab-close, fab-main-action |
| fieldset | - | - | - | - | - | - | - | - | part: fieldset-legend; `component` has 2 classes: `fieldset`, `label` |
| file-input | 8 | 1 | 5 | - | - | - | - | - | |
| filter | - | - | - | - | - | - | - | - | part: filter-reset |
| footer | - | - | - | 2 | 1 | - | - | - | part: footer-title |
| hero | - | - | - | - | - | - | - | - | parts: hero-content, hero-overlay |
| hover-3d | - | - | - | - | - | - | - | - | no groups; boolean property |
| hover-gallery | - | - | - | - | - | - | - | - | no groups |
| indicator | - | - | - | - | 6 | - | - | - | part: indicator-item; placement is two axes (Unsure 14) |
| input | 8 | 1 | 5 | - | - | - | - | - | |
| join | - | - | - | 2 | - | - | - | - | `component` has 2 classes: `join`, `join-item` |
| kbd | - | - | 5 | - | - | - | - | - | |
| label | - | - | - | - | - | - | - | - | `component` has 2 classes: `label`, `floating-label`; drives `Field.labelPlacement` |
| link | 8 | 1 | - | - | - | - | - | - | |
| list | - | - | - | - | - | - | 2 | - | `component` has 2 classes: `list`, `list-row`; both modifiers are per-cell flags |
| loading | - | 6 | 5 | - | - | - | - | - | |
| mask | - | 14 | - | - | - | - | 2 | - | property config on Image/Avatar |
| megamenu | - | - | 5 | 1 | - | - | 2 | - | part: megamenu-active; `direction` has only `megamenu-vertical` |
| menu | - | - | 5 | 2 | - | - | 5 | - | parts: menu-title, menu-dropdown, menu-dropdown-toggle; `menu-active`/`-disabled`/`-focus` belong on the item, not the container |
| mockup-browser | - | - | - | - | - | - | - | - | part: mockup-browser-toolbar |
| mockup-code | - | - | - | - | - | - | - | - | no groups |
| mockup-phone | - | - | - | - | - | - | - | - | parts: mockup-phone-camera, mockup-phone-display |
| mockup-window | - | - | - | - | - | - | - | - | no groups |
| modal | - | - | - | - | 5 | - | 1 | - | parts: modal-box, modal-action, modal-backdrop, modal-toggle; placement is two axes (Unsure 14) |
| navbar | - | - | - | - | - | - | - | - | parts: navbar-start, navbar-center, navbar-end |
| otp | 8 | - | 5 | - | - | - | 1 | - | |
| pagination | - | - | - | 2 | - | - | - | - | reuses `join`/`join-item` |
| progress | 8 | - | - | - | - | - | - | - | |
| radial-progress | - | - | - | - | - | - | - | - | no groups; value/size are CSS variables |
| radio | 8 | - | 5 | - | - | - | - | - | |
| range | 8 | - | 5 | 1 | - | - | - | - | `direction` has only `range-vertical` |
| rating | - | - | 5 | - | - | - | 2 | - | `rating-hidden` is `RatingData.clearable`, not a container modifier |
| select | 8 | 1 | 5 | - | - | - | - | - | |
| skeleton | - | - | - | - | - | - | 1 | - | |
| stack (Block.Stacked) | - | - | - | - | - | - | 4 | - | modifier group is really exclusive (Unsure 15) |
| stat | - | - | - | 2 | - | - | - | - | parts: stat, stat-title, stat-value, stat-desc, stat-figure, stat-actions; container class is `stats` |
| status | 8 | - | 5 | - | - | - | - | - | |
| steps | 8 | - | - | 2 | - | - | - | - | colour classes are `step-*` and belong on the `step` part, not the `steps` container |
| swap | - | 2 | - | - | - | - | 1 | - | parts: swap-on, swap-off, swap-indeterminate |
| tab | - | 3 | 5 | - | 2 | - | 2 | - | parts: tab, tab-content; `tab-active`/`tab-disabled` belong on the `tab` part |
| table | - | - | 5 | - | - | - | 3 | - | |
| textarea | 8 | 1 | 5 | - | - | - | - | - | |
| text-rotate | - | - | - | - | - | - | - | - | no groups |
| theme-controller | - | - | - | - | - | - | - | - | no groups; config is pure data (`themes`, `current`, `presentation`, incl. `ThemeAsDropdown`) |
| timeline | - | - | - | 2 | - | - | 3 | - | parts: timeline-start, timeline-middle, timeline-end; `timeline-box` is a per-side flag on the item |
| toast | - | - | - | - | 6 | - | - | - | placement is two axes (Unsure 14) |
| toggle | 8 | - | 5 | - | - | - | - | - | |
| tooltip | 7 | - | - | - | 7 | - | 1 | - | part: tooltip-content; property config on every Leaf; placement is two axes (Unsure 14) |
| validator | - | - | - | - | - | - | - | - | part: validator-hint; drives `Field.validate` / `Field.hint` |

Components with **no** group at all and therefore no `XConfig` beyond parts/data: breadcrumbs, countdown, diff,
hero, hover-3d, hover-gallery, mockup-code, mockup-window, navbar, radial-progress, text-rotate,
theme-controller, validator, fieldset, label, filter, mockup-browser, mockup-phone, calendar (its config is
pure data: `id`, `today`, `locale`, `months`, `toMsg`, `onChange`).

## Demo expressibility

Every element the three demos require (SPEC step 7) maps to a placement above.

**Admin**

| Requirement | Placement |
|---|---|
| Dashboard shell | `Page.shell = Shell.Dashboard (DashboardShell msg)` = `{ brand, sidebar, sidebarFooter, navbar }` → `drawer` + `drawer-open` at `lg:` (drawer placed at Overlay, referenced here) |
| Sidebar menu | the `MenuSpec msg` named type placed at Block, referenced by `Shell.Dashboard.sidebar`; section labels are `MenuItem.title = True` (`menu-title`) and the "New" pill is `MenuItem.badge` |
| Sidebar brand row and user card | `DashboardShell.brand : Maybe Brand` and `.sidebarFooter : Maybe (Leaf msg)` (a `Leaf.UserChip`) |
| Page title + breadcrumbs in one row | `Page.header : Maybe (PageHeader msg)` — not a section |
| Metric tile with a delta badge and a glyph tile | `Block.Stat` with `StatItem.trend : Maybe (Leaf msg)`; `Daisy.Render` paints the `stat-figure` tile |
| Card header row (`Day \| Month \| Year`, a "Report" button) | `CardParts.headerTabs : Maybe (TabsSpec msg)` and `.headerActions : List (Leaf msg)` |
| Navbar search field with a leading glyph | `Leaf.Input` with `icon = Just Search` |
| Navbar user chip | `Leaf.UserChip` in `NavbarParts.end` |
| Chat panel inside a card | `CardChild.CardChat` |
| Navbar | `Section.Navbar` with `NavbarParts` of Leaves |
| 4 Stat cards | `Section.Grid [ Block.Stat cfg [ StatItem, StatItem, StatItem, StatItem ] ]` |
| Chart Line | `Block.Chart Line data` (`Daisy.Chart`, not a daisyUI component) |
| Table with badges and a row action | `Block.Table cfg (List Row)`; `Row.cells : List (TableCell msg)`, a cell being `{ leading : Maybe (Leaf msg), content : Leaf msg }`, holds `Leaf.Badge`, an icon-only `Leaf.Button`, and the avatar-and-name pair in the customer cell |
| Toast overlay | `Overlay.Toast cfg [ Block.Alert ... ]` |
| Theme switcher in navbar | `Leaf.ThemeSelect` in `NavbarParts.end` |

**Analytics**

| Requirement | Placement |
|---|---|
| Dashboard shell | as above |
| Chart Bar / Donut / Area | `Block.Chart` ×3 inside `Section.Grid` |
| Stat row | `Block.Stat` with a `List StatItem` |
| Date-range Select | `Leaf.Select` in `CardParts.headerActions` of the "Date range" card. It was in `NavbarParts.end` until 2026-09-07: daisyUI's `.select` is `width: clamp(3rem, 20rem, 100%)`, whose max-content contribution is indeterminate, so in a `flex-wrap` row it takes a line of its own — which is what it did to the navbar. In a card header there is room for it. |

**Settings**

| Requirement | Placement |
|---|---|
| Plain shell | `Shell.Plain` |
| `Form` blocks with `fieldset` | `Block.Form cfg (List (Fieldset msg))`; `fieldset` is Parts-of Form |
| `toggle`, `select`, `input` | `Leaf.Toggle`, `Leaf.Select`, `Leaf.Input` as `Field.control` |
| `input` with `validator` | `validator` is Parts-of the `Field` record (`validate : Bool`, `hint : Maybe String`), so `validator-hint` is always the sibling immediately after its input |
| Labels | `label` is Parts-of the `Field` record |
| One primary CTA | `Page.cta` — the only `btn-primary` on the page |
| Modal confirm overlay | `Overlay.Modal cfg [ Block.Prose ..., Block.Alert ... ]`, confirm/cancel rendered from `ModalConfig` into the `modal-action` part |

**Theme generator** (added 2026-09-07)

| Requirement | Placement |
|---|---|
| Dashboard shell, page header, debug pane | as Admin |
| The page renders under the theme being edited | `Page.theme = Theme.Custom (CustomTheme)`; `Daisy.Render.page` writes the twenty-nine declarations onto the page root as one inline `style` attribute |
| "Start from" any built-in or `acme` | `Leaf.Select` over `List.map themeToString Demo.Themes.startingPoints`; `Daisy.Themes.builtinToCustom` supplies the values behind a built-in's name |
| One picker per `--color-*` variable | `Leaf.Input` with `inputType = InputColor` as a `Field.control`, so the native picker is named by the variable it edits; `Daisy.Color` converts `#rrggbb` <-> `oklch()` |
| Radius / size / border steps | `Leaf.Select` over `allRadii` / `allSizes` / `allBorders`, offered under the CSS length each step stands for |
| `--depth` / `--noise` / dark scheme | `Leaf.Toggle` — a `Bool` in the tree, a `0`/`1` in the CSS |
| The palette readout | `Leaf.Swatch` per `SwatchColor` in `CardParts.body`, badges in `CardParts.actions` (`card-actions` is `flex flex-wrap`; a `card-body` child would stretch to the full width) |
| Live preview | ordinary `Leaf.Button` / `Leaf.Badge` / `CardAlert` / `CardForm` / `CardChart` / `CardTable` — the whole page is the preview |
| The exported CSS | `Block.MockupCode` of `String.lines (customThemeToCss ...)`, in a `Stack` with `align = AlignStretch` |
| "Copy CSS" | `Page.cta` -> a port (`Ports.copyToClipboard`) |
| "Open in daisyUI theme generator" | `Leaf.Link` whose `href` is the answer to `Ports.encodeTheme (customThemeToJson ...)` |

**Known gaps** (record in `fixtures/rejected.md`, do not add an escape hatch):

- A horizontal `menu` inside a `Navbar` (Navbar takes Leaves; use `Leaf.Link` items or `Leaf.Megamenu`).
- A `join`ed search input + button inside a `Navbar` is expressible (`Leaf.Join`), but a `join` of arbitrary
  Leaves is not — `JoinItem` is a closed list of button/input/select/text.
- Corner placements for `toast`, `dropdown`, `indicator`, `modal` (one `placement` field, two axes; Unsure 14).
- `Block.Stacked` (daisyUI `stack`) overlaps by design and must be excluded from the demos unless
  `overlap.spec` exempts it.
