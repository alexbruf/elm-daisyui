# Demo findings

Things the three demo apps (`demo/src/Demo/Admin.elm`, `Demo/Analytics.elm`,
`Demo/Settings.elm`) wanted and `Daisy.Tree` could not express, per SPEC.md
step 7: "If a demo needs something the tree cannot express, that is a finding to
report, not a reason to add an escape hatch."

Nothing here was added to the tree. Each entry says what the demo did instead.

## 1. No heading leaf, so a page has no document outline

`Block.Prose` renders a `prose` div and `Leaf.Text` renders a bare text node,
so "Revenue overview" and "Most recent orders" are paragraphs, not `<h1>`/`<h2>`.
Tailwind's typography plugin styles headings, and it has nothing to style. The
a11y spec will see a page with no heading structure.

*Workaround:* section titles are plain `Prose [ Text ... ]`. A `Leaf.Heading`
(or a `title : Maybe String` on `Section`) would be the fix, but that is a tree
change.

## 2. `Section.Stack` has no stretch alignment

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

## 4. `Leaf.ThemeSelect` renders one control per theme, with no compact form

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
dashboard sidebars pass their route path. This was one of the two refinements
the Tier C `keyboard` spec required — see "Refinements from e2e" in
`docs/tree-decisions.md`. The original finding follows.

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
apply. `Demo.Settings` wires `onClose = ModalCancelled`. Second of the two
refinements the Tier C `keyboard` spec required — see "Refinements from e2e" in
`docs/tree-decisions.md`. The original finding follows.

The renderer drew a modal as a `div.modal` plus a hidden `modal-toggle`
checkbox and a `modal-backdrop` label. There is no `<dialog>`, no `Escape`
handler and no focus trap, so the Tier C keyboard spec's "modal traps focus and
closes on Escape" cannot pass with anything the tree can express. Visibility is
controlled from Elm by adding/removing `SModal.Open`.

*Workaround:* `Demo.Settings` renders the modal unconditionally and toggles
`SModal.Open` from `Model.modalOpen`; its Cancel button fires `ModalCancelled`.
Escape does nothing.

## 7. `Block.Card` cannot contain a chart or a table

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

## 9. `Field.validate` renders `validator` but never invalid

`Field { validate = True }` puts daisyUI's `validator` class on the control and
`validator-hint` on the hint paragraph. daisyUI shows the hint through
`:user-invalid`, which needs a real constraint (`type="email"`, `required`,
`pattern`) on the input. `InputConfig` has no `type`/`required`/`pattern` field,
so the hint is never revealed.

*Workaround:* the "Contact email" field is marked `validate = True` and carries
a hint; it renders the classes the spec asks for, but the hint stays hidden.

## Not a finding, just a note

`Block.Stacked` (daisyUI `stack`) is unused in all three demos: it overlaps its
children by design, which the Tier C overlap spec forbids. That is already
recorded in `docs/tree-decisions.md` / `fixtures/rejected.md`.
