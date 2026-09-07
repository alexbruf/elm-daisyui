# Rejected corpus examples

Docs examples the closed tree cannot express, or has not been mapped to a tree
yet. Every id here is one that `CorpusTest` does not require a hand-written tree
for; every other id in `fixtures/corpus` has one in `tests/Corpus/Trees.elm`.

Reasons use two categories:

- `inexpressible: <what the tree cannot say>` — the closed tree genuinely cannot
  produce this markup, and producing it would need an escape hatch or a change
  to `Daisy.Tree`.
- `unmapped: not yet hand-written` — expressible in principle, but no tree has
  been written for it yet.

Regenerate `tests/Corpus/Rejected.elm` from this table with
`bun tools/gen-corpus-elm.js`.

| id | reason |
|---|---|
| accordion--04 | inexpressible: a `collapse` carrying `join-item`; `JoinItem` is a closed list of button, input, select and text, so a block cannot be joined |
| calendar--00 | inexpressible: the `cally` / `react-day-picker` / `vc` classes are theming hooks for third-party calendar widgets, which need foreign markup (calendar is Excluded in docs/placement.md) |
| calendar--01 | inexpressible: the `cally` / `react-day-picker` / `vc` classes are theming hooks for third-party calendar widgets, which need foreign markup (calendar is Excluded in docs/placement.md) |
| card--15 | inexpressible: a `card` carrying `join-item`; `JoinItem` is a closed list of button, input, select and text, so a block cannot be joined |
| drawer--01 | inexpressible: a `navbar` and a horizontal `menu` inside `drawer-content`; `Overlay.Drawer` holds sections in `drawer-side` only, and its toggle button is `btn drawer-button` with no further classes |
| drawer--03 | inexpressible: the `is-drawer-open:` / `is-drawer-close:` selector prefixes; they are Tailwind variants, not classes an element can carry (see Render.unreachableClasses) |
| drawer--04 | inexpressible: a `btn-primary` drawer button; `btn-primary` is reserved for `Page.cta`, which the shell places, and the drawer's own button is `btn drawer-button` |
| dropdown--01 | inexpressible: `dropdown` and `menu` on one element (popover API); the renderer always wraps the anchor in its own `dropdown` element |
| dropdown--07 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--08 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--10 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--11 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--13 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--14 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--16 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--17 | inexpressible: two `dropdown` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one, so `DropdownConfig.placement` holds one and ExclusivityTest forbids two |
| dropdown--21 | inexpressible: a `card` as `dropdown-content`; `Dropdown` holds a `MenuSpec`, so the content of a dropdown is always a menu |
| dropdown--23 | inexpressible: a `card` as `dropdown-content`; `Dropdown` holds a `MenuSpec`, so the content of a dropdown is always a menu |
| fab--00 | inexpressible: the fab's main action is a `btn-primary`; `btn-primary` is reserved for `Page.cta` |
| fab--05 | inexpressible: the fab's main action is a `btn-primary`; `btn-primary` is reserved for `Page.cta` |
| fab--06 | inexpressible: the fab's main action is a `btn-primary`; `btn-primary` is reserved for `Page.cta` |
| fab--08 | inexpressible: the fab's main action is a `btn-primary`; `btn-primary` is reserved for `Page.cta` |
| fab--09 | inexpressible: the fab's main action is a `btn-primary`; `btn-primary` is reserved for `Page.cta` |
| footer--02 | inexpressible: a `btn-primary` inside a `join`; `btn-primary` is reserved for `Page.cta`, which the shell places outside any join |
| indicator--03 | inexpressible: `indicator` on the `tab` element itself; the renderer always emits its own `indicator` wrapper around the anchor |
| indicator--04 | inexpressible: `indicator` on the `avatar` element itself; the renderer wraps the avatar in its own `indicator` element |
| indicator--06 | inexpressible: a button as the `indicator-item`; `IndicatorPayload` is a badge or a status |
| indicator--07 | inexpressible: two `indicator` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| indicator--11 | inexpressible: two `indicator` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| indicator--12 | inexpressible: two `indicator` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| indicator--14 | inexpressible: two `indicator` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| indicator--15 | inexpressible: two `indicator` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| indicator--17 | inexpressible: two `indicator` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| input--15 | inexpressible: `validator` on one input inside a `join`; `Field.validate` marks the whole control, which here is the join |
| menu--05 | inexpressible: a tooltip on a menu item; `tooltip` is a field on leaf configs and `MenuItem` is not a leaf |
| menu--06 | inexpressible: a tooltip on a menu item; `tooltip` is a field on leaf configs and `MenuItem` is not a leaf |
| menu--16 | inexpressible: `menu-dropdown-show` on an item's toggle and submenu, but `MenuConfig.modifiers` puts menu modifiers on the `menu` container |
| navbar--03 | inexpressible: a horizontal `menu` inside a `navbar`; `Section.Navbar` holds leaves and `Menu` is a block (a known gap recorded in docs/placement.md) |
| navbar--04 | inexpressible: `avatar` and `btn` on one element; `Leaf.Avatar` always renders its own `avatar` element |
| navbar--05 | inexpressible: `avatar` and `btn` on one element; `Leaf.Avatar` always renders its own `avatar` element |
| navbar--07 | inexpressible: a horizontal `menu` inside a `navbar`; `Section.Navbar` holds leaves and `Menu` is a block (a known gap recorded in docs/placement.md) |
| navbar--08 | inexpressible: a `navbar` carrying `collapse-title`; `collapse` parts belong to `Block.Collapse` and a section cannot sit inside a block |
| stack--02 | inexpressible: `card` blocks inside a `stack`; `Block.Stacked` holds leaves, and a block cannot contain another block |
| stack--03 | inexpressible: `card` blocks inside a `stack`; `Block.Stacked` holds leaves, and a block cannot contain another block |
| stack--04 | inexpressible: `card` blocks inside a `stack`; `Block.Stacked` holds leaves, and a block cannot contain another block |
| stack--05 | inexpressible: `card` blocks inside a `stack`; `Block.Stacked` holds leaves, and a block cannot contain another block |
| stack--06 | inexpressible: `card` blocks inside a `stack`; `Block.Stacked` holds leaves, and a block cannot contain another block |
| stack--07 | inexpressible: `card` blocks inside a `stack`; `Block.Stacked` holds leaves, and a block cannot contain another block |
| swap--03 | inexpressible: `swap` and `btn` on one element; `Leaf.Swap` always renders its own `swap` label |
| theme-controller--02 | inexpressible: a `theme-controller` swap with `swap-on` / `swap-off` faces; `ThemeSelect` renders the controller as one input per theme, with no faces |
| theme-controller--05 | inexpressible: `theme-controller` and `toggle` on separate elements; `ThemeSelect` emits both classes on one input |
| theme-controller--07 | inexpressible: a sized `radio theme-controller`; `ThemeSelectData` has no size field |
| theme-controller--08 | inexpressible: a `theme-controller` carrying `join-item`; `ThemeSelect` is a leaf of its own and cannot be a `JoinItem` |
| toast--01 | inexpressible: a horizontal and a vertical `toast` placement on one element (a corner); the schema declares `placement` as pick-at-most-one |
| toast--02 | inexpressible: a horizontal and a vertical `toast` placement on one element (a corner); the schema declares `placement` as pick-at-most-one |
| toast--03 | inexpressible: a horizontal and a vertical `toast` placement on one element (a corner); the schema declares `placement` as pick-at-most-one |
| toast--04 | inexpressible: a horizontal and a vertical `toast` placement on one element (a corner); the schema declares `placement` as pick-at-most-one |
| toast--05 | inexpressible: a horizontal and a vertical `toast` placement on one element (a corner); the schema declares `placement` as pick-at-most-one |
| toast--06 | inexpressible: a horizontal and a vertical `toast` placement on one element (a corner); the schema declares `placement` as pick-at-most-one |
| tooltip--03 | inexpressible: two `tooltip` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| tooltip--04 | inexpressible: two `tooltip` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| tooltip--05 | inexpressible: two `tooltip` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
| tooltip--06 | inexpressible: two `tooltip` placement classes on one element (a corner); the schema declares `placement` as pick-at-most-one |
