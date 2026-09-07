# Demo findings

Things the three demo apps (`demo/src/Demo/Admin.elm`, `Demo/Analytics.elm`,
`Demo/Settings.elm`) wanted and `Daisy.Tree` could not express, per SPEC.md
step 7: "If a demo needs something the tree cannot express, that is a finding to
report, not a reason to add an escape hatch."

Each entry says what the demo did instead. Nothing here was added to the tree
*at the time*; the struck entries were fixed later, each in one closed, typed
addition recorded in `docs/tree-decisions.md`.

## ~~1. No heading leaf, so a page has no document outline~~ — fixed

**Struck.** `Daisy.Tree` gained `Leaf.Heading HeadingLevel String`
(`H1 | H2 | H3`), rendered as a bare `<h1>`/`<h2>`/`<h3>` and emitting no
daisyUI class. See "Expressibility refinements (2026-09-07)" in
`docs/tree-decisions.md`.

**What the demos do now.** Every demo opens with a `Prose` block holding one
`Heading H1` (`"Revenue overview"`, `"Acquisition"`, `"Workspace settings"`)
and gives each following band an `H2` where the band has no `card-title` of its
own — Admin `"Revenue trend"` / `"Orders"`, Analytics `"Key metrics"` /
`"Traffic"`. The bands that *are* cards use the `card-title`, which
`Daisy.Render` already draws as an `<h2>`, rather than repeating the rank. axe's
`page-has-heading-one` is gone from all three demos (see item 10 for what the
headings still do *not* get). The original finding follows.

`Block.Prose` renders a `prose` div and `Leaf.Text` renders a bare text node,
so "Revenue overview" and "Most recent orders" are paragraphs, not `<h1>`/`<h2>`.
Tailwind's typography plugin styles headings, and it has nothing to style. The
a11y spec will see a page with no heading structure.

*Workaround:* section titles are plain `Prose [ Text ... ]`. A `Leaf.Heading`
(or a `title : Maybe String` on `Section`) would be the fix, but that is a tree
change.

## ~~2. `Section.Stack` has no stretch alignment~~ — fixed

**Struck.** `Align` gained `AlignStretch` (`items-stretch`).
`defaultStackConfig` deliberately keeps `AlignStart`: making stretch the
default would stretch `Page.cta` across the whole page under `Shell.Plain`,
which is the second effect this very finding describes.

**What the demos do now.** Admin's chart and orders bands and Analytics'
traffic band are `Stack { align = AlignStretch }`, so their cards fill the
width — the one-column-`Grid` workaround is gone from both dashboards.
`Demo.Settings` keeps its *last* section an `AlignStart` `Stack` and moved the
warning `Alert` into a fourth, stretched section of its own (`Sections5`): the
alert now fills the band it used to be clipped in, and the CTA the renderer
appends to the last section is still its own width. The second effect this
finding describes is therefore unchanged and still load-bearing. The original
finding follows.

`Align = AlignStart | AlignCenter | AlignEnd` maps onto `items-start` /
`-center` / `-end` on a flex column, so a `Table`, `Alert` or `Card` in a
`Stack` shrinks to its content width and can never fill the band. Only blocks
the renderer marks `w-full` itself (charts) span the section.

*Workaround:* bands that must be full width use `Grid { columns = Cols1 }`,
whose children stretch. This has a second, unrelated effect worth knowing:
under `Shell.Plain` the renderer appends `Page.cta` to the last section's
container, so a one-column grid as the last section stretches the CTA across
the whole page. `Demo.Settings` therefore keeps its last section a `Stack`.

## 3. `GridConfig` column counts are not responsive

`Cols1..Cols4` emit fixed `grid-cols-N`; there is no breakpoint story. Four stat
tiles at 375 px are four ~85 px columns rather than a 2×2 or a single column.
Nothing overflows (grid tracks shrink), but the small viewport is cramped.

*Workaround:* accepted as is. **Since fixed**: the Tier C `overlap` spec showed
that the tracks do not merely shrink, they let every tile spill over its
neighbour at 375. `Daisy.Render.gridColumnsTokens` now emits `grid-cols-1`,
`sm:grid-cols-2` and `lg:grid-cols-{3,4}`.

## ~~4. `Leaf.ThemeSelect` renders one control per theme, with no compact form~~ — fixed

**Struck.** `ThemePresentation` gained `ThemeAsDropdown`, which renders
daisyUI's documented `dropdown` + `dropdown-content` radio list: one control
wide no matter how many themes it offers.

**What the demo does now.** The Admin navbar switcher is
`presentation = ThemeAsDropdown` over `Tree.allThemes` — all 35, behind one
`Theme` trigger. It is keyboard-reachable (the panel opens on `:focus-within`,
so `Tab` to the trigger then `Tab` again lands on the checked radio) and
clicking a theme fires `onSelect` -> `ThemeChanged` -> `Page.theme`, which
`e2e/interaction.spec.ts` now asserts end to end. The original finding
follows.

`ThemeSelectData.themes : List Theme` becomes one sibling `input.theme-controller`
per entry. With `allThemes` that is 35 buttons in `navbar-end`, which does not
fit any viewport. `ThemePresentation` offers select/radios/toggle/checkbox/swap,
but `ThemeAsSelect` is still N buttons, not a `<select>`. A `Dropdown` cannot
hold it either: `Dropdown` takes a `MenuSpec msg`, and a `MenuItem` cannot carry
a leaf.

*Workaround:* the Admin navbar's switcher lists four themes (light, dark,
corporate, nord). All 35 are still reachable through `?theme=<name>` in the URL,
which is what the Tier C themes sweep uses.

## ~~5. `MenuItem` has no `href`~~ — fixed

**Struck.** `Daisy.Tree.MenuItem` now carries `href : Maybe String` (default
`Nothing`) and `Daisy.Render` emits it as the anchor's `href`; the two
dashboard sidebars pass their route path and keep `onClick -> NavigateTo`
beside it, which is still exactly what they do. This was one of the two
refinements the Tier C `keyboard` spec required — see "Refinements from e2e"
in `docs/tree-decisions.md`. The original finding follows.

The dashboard sidebar is the app's primary navigation, but `MenuItem` carries
only `onClick : Maybe msg`, so the renderer emits `<a>` with no `href`. Two
consequences:

- The item is not in the tab order and has no `link` role, so a keyboard user
  cannot reach or activate it and `getByRole("link")` does not find it. The
  Tier C keyboard spec's "menu items reachable" will need `getByText`, and it
  will find them unfocusable.
- `Browser.application`'s link interception does not apply, so navigation has to
  go through `onClick` → `Nav.pushUrl`.

*Workaround:* sidebar items use `onClick` → `NavigateTo path` → `pushUrl`.
`Demo.Settings` (a `Plain` shell with no sidebar) uses `Leaf.Link` instead,
which does carry `href` and is a real, focusable link.

## ~~6. `Overlay.Modal` cannot be closed from the keyboard~~ — fixed

**Struck.** `ModalConfig` now carries `onClose : Maybe msg` (default
`Nothing`), `Daisy.Render` emits daisyUI's recommended `<dialog class="modal">`
markup, and `demo/src/main.js` carries a generic `MutationObserver` that calls
`showModal()`/`close()` so the browser's own focus trap and `Escape` handling
apply. `Demo.Settings` wires `onClose = ModalCancelled`, which is unchanged.
Second of the two refinements the Tier C `keyboard` spec required — see
"Refinements from e2e" in `docs/tree-decisions.md`. The original finding
follows.

The renderer drew a modal as a `div.modal` plus a hidden `modal-toggle`
checkbox and a `modal-backdrop` label. There is no `<dialog>`, no `Escape`
handler and no focus trap, so the Tier C keyboard spec's "modal traps focus and
closes on Escape" cannot pass with anything the tree can express. Visibility is
controlled from Elm by adding/removing `SModal.Open`.

*Workaround:* `Demo.Settings` renders the modal unconditionally and toggles
`SModal.Open` from `Model.modalOpen`; its Cancel button fires `ModalCancelled`.
Escape does nothing.

## ~~7. `Block.Card` cannot contain a chart or a table~~ — fixed

**Struck.** `CardParts.body` is now `List (CardChild msg)`, where `CardChild`
is `CardLeaf | CardChart | CardTable | CardStat | CardForm`. There is no
`CardCard`, so a card still cannot contain a card.

**What the demos do now.** Admin puts its line chart in a card
(`CardLeaf` caption + `CardChart`, titled "Net revenue vs. operating cost") and
its orders table in another (`CardTable`, titled "Most recent orders");
Analytics puts the bar, donut and area charts in three titled cards; Settings
puts each form group in a card (`CardForm`, "General" and "Privacy"). The
`Prose`-caption-above-a-bare-block workaround is gone from all three. Every
demo card also asks for `style = Just SCard.Border`, because a card with no
style paints nothing on a `base-100` page. The original finding follows.

`CardParts.body : List (Leaf msg)` takes leaves only, and `Chart` / `Table` are
blocks. "A chart in a card", the single most common dashboard idiom (and what
the Nexus template does throughout), is therefore not expressible.

*Workaround:* charts and tables are bare blocks in a section, with a `Prose`
caption above them instead of a `card-title`.

## 8. Overlay visibility is the application's job, with no timer help

Nothing in `Daisy.Tree` says "show this toast for three seconds". A toast is
present exactly when it is in `Page.overlays`.

*Workaround:* `Main.update` puts the toast in the list on `ExportClicked` and
schedules `Process.sleep 3000 |> Task.perform (\_ -> ToastDismissed)`. This is
arguably correct for a view library; recorded only because the Tier C
interaction spec asserts the auto-dismiss and the timing lives in the demo, not
the library.

## ~~9. `Field.validate` renders `validator` but never invalid~~ — fixed

**Struck.** `InputConfig` gained `inputType`, `required`, `pattern`,
`minLength` and `maxLength`, and `TextareaConfig` gained `required`; all render
as the HTML attributes, so `:user-invalid` can fire and the hint can show.

**What the demo does now.** Settings' "Contact email" is
`inputType = InputEmail, required = True` beside the `validate = True` and the
hint it already had, so a bad address really does turn the control
`:user-invalid` and reveal `validator-hint`. "Workspace name" carries
`required = True, minLength = Just 2, maxLength = Just 60`. The original
finding follows.

`Field { validate = True }` puts daisyUI's `validator` class on the control and
`validator-hint` on the hint paragraph. daisyUI shows the hint through
`:user-invalid`, which needs a real constraint (`type="email"`, `required`,
`pattern`) on the input. `InputConfig` has no `type`/`required`/`pattern` field,
so the hint is never revealed.

*Workaround:* the "Contact email" field is marked `validate = True` and carries
a hint; it renders the classes the spec asks for, but the hint stays hidden.

## ~~10. `Block.Prose` gives the outline but not the type scale~~ (fixed)

~~`Leaf.Heading` renders a bare `<h1>`/`<h2>`/`<h3>` and emits no daisyUI class,
on the stated grounds that "Tailwind typography styles it when it sits inside
`Block.Prose`". In `demo/` it does not: `app.css` loads `tailwindcss` and the
`daisyui` plugin and nothing else, so the only `.prose` rules in the built CSS
are the two compatibility selectors daisyUI ships. Tailwind Preflight has
already reset `<h1>`/`<h2>` to `font-size: inherit; font-weight: inherit`, so a
section title is the same size and weight as body copy — visible in
`docs/screenshots/demo-admin.png` ("Revenue trend", "Orders").~~

~~The semantics are right, which is what the leaf was added for: axe's
`page-has-heading-one` is gone from all three demos and the document outline is
real. Only the visual rank is missing.~~

~~*Workaround:* accepted as is. Adding `@plugin "@tailwindcss/typography"` to
`demo/app.css` would make the documented sentence true, but the plugin also
repaints every `.prose` descendant with its own `--tw-prose-*` greys, which are
not daisyUI theme colours — on the dark themes that is a contrast regression the
Tier C `contrast` spec would be right to fail on. Sizing the heading inside
`Daisy.Render` instead would mean new entries in the `tokens` table and would
contradict the recorded decision that `Heading` emits no class at all. Neither
is worth doing for a demo, so the gap is recorded rather than closed. The card
bands do not have it: `card-title` is a daisyUI class and is styled.~~

**Fixed:** `Leaf.Heading` still emits no daisyUI class — `card-title` stays the
only styled heading-like class — but `headingHtml` in `Daisy.Render` now gives
each `HeadingLevel` a fixed Tailwind type-scale pair from `tokens`, independent
of whether the heading sits inside a `Block.Prose`: H1 gets `tokenHeading1`
(`text-3xl`) + `tokenFontBold` (`font-bold`), H2 gets `tokenHeading2`
(`text-2xl`) + `tokenFontBold`, H3 gets `tokenHeading3` (`text-xl`) +
`tokenFontSemibold` (`font-semibold`).

*Since the Nexus design pass (2026-09-07) the dashboards no longer use section
headings at all:* the page's own title is `Page.header` and every band is a
titled `Card`, which is how daisyUI's dashboard templates are laid out. The type
scale above is still what `Leaf.Heading` renders wherever a page does use one.

## Not a finding, just a note

`Block.Stacked` (daisyUI `stack`) is unused in all three demos: it overlaps its
children by design, which the Tier C overlap spec forbids. That is already
recorded in `docs/tree-decisions.md` / `fixtures/rejected.md`.
