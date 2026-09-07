# elm-daisyui

A typed, closed composition layer over [daisyUI](https://daisyui.com) 5 for Elm 0.19.1.

You do not write HTML or class strings. You build a value of type `Daisy.Tree.Page` and hand it to
`Daisy.Render.page`. daisyUI's CSS is used unchanged; `Daisy.Render` is the only module in the
package that emits a class attribute.

- Live demos: <https://alexbruf.github.io/elm-daisyui/>
- Documentation site: <https://alexbruf.github.io/elm-daisyui/docs/> (this README and every other
  document in the repository, rendered)
- API docs: <https://package.elm-lang.org/packages/alexbruf/elm-daisyui/latest/>

## The four guarantees

The compiler and the test suite together guarantee:

1. **No contradictory modifiers on one element.** `btn-sm` and `btn-lg`, or two colours, cannot
   both be set: each exclusive class group of a component is one `Maybe` field of a generated
   type, so there is nowhere to put the second value.
2. **No invalid nesting.** A card inside a card, a section inside a block, a `card-body` outside a
   `Card` — none of them is a value the constructors can build.
3. **No visual overlap.** Modal, drawer, toast, dropdown and tooltip are not nodes you place.
   Overlays live only in `Page.overlays` and are rendered by `Daisy.Render` into one fixed layer in
   a fixed order (drawer, modal, toast); dropdown and tooltip are fields on a leaf's config.
4. **A page content budget.** `Sections` has constructors for one to five sections and no others,
   and `Page.cta` is a mandatory single field, so "six sections" and "zero or two primary CTAs" are
   type errors rather than runtime checks.

There is no `Raw Html` escape hatch, and there never will be. Markup the tree cannot express is
recorded in [`fixtures/rejected.md`](fixtures/rejected.md) with a reason.

## Install

```
elm install alexbruf/elm-daisyui
```

The package depends on `elm/html`, `elm/json`, `elm/svg`, `terezka/elm-charts`,
`justinmimbs/date` and `alexbruf/elm-cally`. You still need daisyUI's CSS in your build — see
[CSS setup](#css-setup).

## The model

A page is four levels deep and each level may only hold the level below it. `Page` carries a
`Shell` (`Plain`, or `Dashboard` with a sidebar menu and a navbar), a `Sections` value holding one
to five `Section`s (`Hero`, `Navbar`, `Footer`, `Grid`, `Stack`), a mandatory `cta` — the page's
only primary button, which the renderer places according to the shell — a list of `Overlay`s, and a
`Theme`. A `Section` holds `Block`s (`Card`, `Stat`, `Table`, `Form`, `Chart`, `Alert`, `Prose`,
`Menu`, `Steps`, `Timeline` and the rest of daisyUI's block-level components); a `Block` holds
`Leaf`s (`Button`, `Badge`, `Input`, `Select`, `Toggle`, `Calendar`, `Text`, `Heading`, `Icon`, …),
which hold only data. `Overlay` (`Modal`, `Drawer`, `Toast`) exists only as an element of
`Page.overlays`, never as a child of anything else, and a `Leaf.Button` cannot take the `Primary`
colour because `Page.cta` owns it. Where a daisyUI component has `part` classes the tree takes a
record of parts (`CardParts`, `NavbarParts`, `CollapseParts`, …) rather than free children, so a
part can neither appear outside its component nor twice.

## A complete example

`Browser.sandbox`, one section, one card, one badge, one CTA:

```elm
module Main exposing (main)

import Browser
import Daisy.Render
import Daisy.Schema.Badge as Badge
import Daisy.Tree exposing (..)
import Html exposing (Html)


type alias Model =
    { clicks : Int }


type Msg
    = Clicked


main : Program () Model Msg
main =
    Browser.sandbox { init = { clicks = 0 }, update = update, view = view }


update : Msg -> Model -> Model
update Clicked model =
    { model | clicks = model.clicks + 1 }


view : Model -> Html Msg
view model =
    let
        card =
            { emptyCardParts
                | title = Just "Clicks so far"
                , body = [ CardLeaf (Badge { defaultBadgeConfig | color = Just Badge.Secondary } (String.fromInt model.clicks)) ]
            }
    in
    Daisy.Render.page
        (Page
            { shell = Plain
            , sections =
                Sections1
                    (Stack defaultStackConfig
                        [ Prose [ Heading H1 "Clicker" ]
                        , Card defaultCardConfig card
                        ]
                    )
            , cta = cta "Click me" Clicked
            , overlays = []
            , theme = Dark
            , dock = Nothing
            , fab = Nothing
            }
        )
```

`Daisy.Render.page` returns `Html msg`, so it fits `Browser.sandbox`, `Browser.element` and
`Browser.document` alike. It writes `data-theme` on the page root itself, which is what switches
the daisyUI theme.

## Configs

Every component with class groups has an `XConfig` record and a `defaultXConfig` value. There is no
`String` class field anywhere:

- one `Maybe <Group>` field per **exclusive** group (`color`, `style`, `size`, `direction`,
  `placement`, `variant`), whose type comes from the generated module for that component —
  `Daisy.Schema.Button.Color`, `Daisy.Schema.Card.Size`, `Daisy.Schema.Input.Color`, …
- `modifiers : List <Component>.Modifier` (and `behaviors` where the component has a `behavior`
  group) for the groups that are genuinely sets.

So a config is built by updating the default:

```elm
import Daisy.Schema.Button as Button

saveButton : Leaf Msg
saveButton =
    Button
        { defaultButtonConfig
            | color = Just Secondary
            , size = Just Button.Sm
            , modifiers = [ Button.Wide ]
            , onClick = Just Save
        }
        "Save"
```

`size` and `modifiers` take the generated `Daisy.Schema.Button` types, but `color` takes
`Daisy.Tree.ButtonColor`, which is the same list of colours **without** `Primary`: the primary
button is `Page.cta` and nothing else can become one.

The `Daisy.Schema.*` modules are generated from daisyUI's own docs frontmatter by
`tools/gen-schema.js`; each exposes its types, a `<group>ToClass` function, `component`,
`componentClasses`, `parts` and an `all<Group>` list. `Daisy.Schema` aggregates them
(`allClasses`, `exclusiveGroups`, `parts`, `componentClasses`) and is what the test suite checks
the renderer against.

Per-item state lives on the item, not the container: `menu-active` is a `Bool` on a `MenuItem`,
`tab-active` on a `Tab`, `step-*` colours on a `Step`.

## Icons

`Daisy.Icon` is a closed set of 25 drawings — heroicons 2.2.0 outline, MIT, (c) Tailwind Labs —
copied into the package at build time. It is pure data: the path data lives in an internal module
that is not exposed, so nothing a caller writes can become markup. An icon is not a daisyUI
component and emits no daisyUI class, exactly like `Leaf.Heading` and `Leaf.Image`; only its size
class (`size-4` / `size-5` / `size-6`) comes from `Daisy.Render.tokens`.

```elm
import Daisy.Icon as Icon
import Daisy.Tree exposing (..)
```

Accessibility is a field, not a convention. `label = Nothing` renders the `<svg>` `aria-hidden`,
which is what you want beside a text label; `Just` renders an image `role` plus that `aria-label`,
which is what names an icon-only control:

```elm
-- decorative, next to its own text
Icon defaultIconConfig Icon.Home

-- a stat-figure, at the largest of the three sizes
Icon { defaultIconConfig | size = IconLg } Icon.CurrencyDollar

-- an icon-only button: `ariaLabel` names the button, the glyph stays hidden
Button
    { defaultButtonConfig
        | icon = Just Icon.Eye
        , ariaLabel = Just "View order"
        , style = Just SButton.Ghost
        , modifiers = [ SButton.Square ]
    }
    ""
```

The icon fields are all `Maybe` with a `Nothing` default: `MenuItem.icon` (a sidebar glyph),
`ButtonConfig.icon` and `Cta.icon` (a leading glyph), and `StatItem.figure`, which takes any `Leaf`
and therefore takes `Leaf.Icon` as it stands.

Import `Daisy.Icon` **qualified**. Three of its constructors (`Calendar`, `Menu`, `Check`) also name
a `Daisy.Tree` constructor, so `exposing (..)` on both at once is ambiguous.

## Charts

`Daisy.Chart` is a closed configuration over `terezka/elm-charts`. No elm-charts type appears in its
API, so chart code cannot reach the underlying library:

```elm
import Daisy.Chart as Chart

revenueCard : Block msg
revenueCard =
    Card defaultCardConfig
        { emptyCardParts
            | title = Just "Net revenue vs. operating cost"
            , body =
                [ CardChart Chart.Line
                    { xLabels = [ "Jan", "Feb", "Mar" ]
                    , series =
                        [ { name = "Revenue", color = Chart.Primary, points = [ 182, 201, 226 ] }
                        , { name = "Cost", color = Chart.Neutral, points = [ 120, 128, 131 ] }
                        ]
                    }
                ]
        }
```

`ChartConfig` is `Line | Bar | StackedBar | Donut | Area`. Series colours are the daisyUI semantic
palette (`Primary … Neutral`) and are emitted as `var(--color-primary)` and friends, so charts
re-colour with the theme without the renderer knowing any concrete colour. Chart height is fixed
per block size token; there is no per-call override.

## Calendar

`Leaf.Calendar` renders a date picker through [`alexbruf/elm-cally`](https://package.elm-lang.org/packages/alexbruf/elm-cally/latest/),
a pure-Elm port of the Cally web component: same markup and `part` attributes, light DOM, no ports
and no custom elements. elm-cally's own `Config` is built inside `Daisy.Render` and never exposed,
the same rule `Daisy.Chart` follows for elm-charts.

The picker has state, so it lives in your model and takes three functions from the package:

```elm
init : ( Model, Cmd Msg )
init =
    ( { calendar = Daisy.Render.initCalendarRange calendarConfig Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CalendarMsg sub ->
            Daisy.Render.updateCalendar calendarConfig sub model.calendar
                |> Tuple.mapFirst (\state -> { model | calendar = state })

        RangePicked value ->
            ( { model | calendar = Tree.setCalendarValue value model.calendar }, Cmd.none )
```

`initCalendarDate`, `initCalendarRange` and `initCalendarMulti` build the three kinds of state;
`CalendarConfig` carries `today`, `toMsg` (for `CalendarMsg`) and `onChange` (for the picked
value). `updateCalendar` returns a `Cmd` because the roving `tabindex` needs `Browser.Dom.focus`.

The picker needs two stylesheets that are not part of daisyUI: elm-cally's own base stylesheet, and
daisyUI's `.cally` block with `::part(x)` rewritten to `[part~="x"]` (elm-cally has no shadow DOM,
so `::part` never matches). `bun tools/gen-cally-css.js` writes both from
`Cally.Css.stylesheet` in the installed elm-cally package; the generated pair is committed here as
[`demo/cally-base.css`](demo/cally-base.css) and [`demo/cally-daisy.css`](demo/cally-daisy.css) and
can be copied as-is. Import them after the daisyUI plugin line so its layers are already registered.

## CSS setup

Tailwind 4 plus the daisyUI plugin, and then one thing that is specific to Elm.

Elm compilers used with Vite (`vite-plugin-elm`) compile in memory and write no `.elm.js` file, so
Tailwind's scanner has no build artifact to read class names out of. Point `@source` at the Elm
**source files** that hold the class-name literals instead — Tailwind 4's scanner is
extension-agnostic and finds `btn-primary` inside an Elm string literal as readily as inside HTML.
Two files (plus one directory) are enough, because they are the only places a daisyUI class string
exists: `Daisy/Render.elm` and the generated `Daisy/Schema*`.

`demo/app.css` in this repository does exactly that, with paths relative to the checkout:

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: all;
}

@source "../src/Daisy/Render.elm";
@source "../src/Daisy/Schema";
@source "../src/Daisy/Schema.elm";
@source "./src";
```

As a consumer the package is not in your repository, it is in the Elm package cache, so point at it
there — `@source` takes a path relative to the CSS file, and does not expand `~`, so use a real
path:

```css
@source "/home/you/.elm/0.19.1/packages/alexbruf/elm-daisyui/1.0.0/src/Daisy/Render.elm";
@source "/home/you/.elm/0.19.1/packages/alexbruf/elm-daisyui/1.0.0/src/Daisy/Schema";
@source "/home/you/.elm/0.19.1/packages/alexbruf/elm-daisyui/1.0.0/src/Daisy/Schema.elm";
@source "./src";
```

`elm-stuff/` holds compiled artifacts, not the package's sources, so it is not a substitute. If a
machine-independent path matters more than the extra files, copy `src/Daisy/Render.elm` and
`src/Daisy/Schema*` into a vendored directory in your repository and `@source` that — the check
that matters either way is that every class in `Daisy.Schema.allClasses` survives into your built
CSS (`bun tools/css-coverage.js` is that check here).

If you use `Leaf.Calendar`, add the two calendar stylesheets after the plugin line:

```css
@import "./cally-base.css";
@import "./cally-daisy.css";
```

## Demos

Three demo applications, each a single `Page` value, built only through the tree. They share one
router (`demo/src/Main.elm`) and are live at <https://alexbruf.github.io/elm-daisyui/>. The
dashboard sidebars also link to the documentation site at `/docs/`, which `tools/build-docs-site.js`
generates from the repository's markdown as part of the demo build.

**[Dashboard shell, stats and a chart card](demo/src/Demo/Admin.elm)** — `Shell.Dashboard` (a
daisyUI `drawer` that is open from `lg:` up), four `Stat` tiles with icon figures in a four-column
`Grid`, a `Chart Line` inside a `Card`, a `Table` whose customer cell pairs an `Avatar` with a name,
and a `Toast` overlay:

```elm
statsSection : Section msg
statsSection =
    Grid { columns = Tree.Cols4 }
        [ statBlock Icon.CurrencyDollar "Revenue (MTD)" "$248,930" "18.2% vs last month"
        , statBlock Icon.ShoppingCart "Orders" "3,412" "402 awaiting fulfilment"
        , statBlock Icon.Users "Active users" "12,847" "1,204 new this week"
        , statBlock Icon.ArrowTrendingDown "Refund rate" "1.8%" "0.4 points below target"
        ]


statBlock : Icon.Icon -> String -> String -> String -> Block msg
statBlock icon title value desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    Stat Tree.defaultStatConfig
        [ { base | desc = Just desc, figure = Just (Icon { defaultIcon | size = Tree.IconLg } icon) } ]
```

A row of the orders table, with the avatar-and-name cell and the icon-only row action:

```elm
orderRow : Config msg -> Order -> Row msg
orderRow config order =
    { header = False
    , cells =
        [ Tree.tableCell (Text order.reference)
        , { leading = Just (Avatar circleAvatar (avatarSrc order.avatar))
          , content = Text order.customer
          }
        , Tree.tableCell (Badge { defaultBadge | color = Just order.tone } order.state)
        , Tree.tableCell (Text order.total)
        , Tree.tableCell
            (Button
                { defaultButton
                    | icon = Just Icon.Eye
                    , ariaLabel = Just ("View order " ++ order.reference)
                    , style = Just SButton.Ghost
                    , size = Just SButton.Xs
                    , modifiers = [ SButton.Square ]
                    , onClick = Just (config.onRowAction order.reference)
                }
                ""
            )
        ]
    }
```

**[Theme switcher](demo/src/Demo/Admin.elm)** — all 35 daisyUI themes as one `Leaf.ThemeSelect` in
the navbar. `ThemeAsDropdown` is the presentation that stays one control wide; the others render a
sibling `input.theme-controller` per theme:

```elm
themeSwitcher : Config msg -> Leaf msg
themeSwitcher config =
    ThemeSelect
        { themes = Tree.allThemes
        , current = config.theme
        , presentation = ThemeAsDropdown
        , onSelect = Just config.onTheme
        }
```

**[Form with a validator and a modal](demo/src/Demo/Settings.elm)** — `Shell.Plain`, `Form` blocks
of `Fieldset`s carrying toggles, selects and inputs (one a real `type="email" required` field, so
daisyUI's `validator-hint` shows), the page's single CTA, and a `Modal` confirm overlay:

```elm
emailField : Config msg -> Field msg
emailField config =
    validatedField "Contact email"
        "Enter an address we can actually reach, e.g. ops@acme.test"
        (Input
            { defaultInput
                | color = Just SInput.Info
                , value = config.contactEmail
                , inputType = InputEmail
                , required = True
                , onInput = Just config.onContactEmail
            }
        )
```

The third demo, [Analytics](demo/src/Demo/Analytics.elm), is the chart-heavy one: `Bar`, `Donut`
and `Area` charts, a stat row and a two-month `Leaf.Calendar` range picker.

## What is deliberately inexpressible

Each of these is a consequence of one of the four guarantees, not an oversight. The full list, one
line per rejected daisyUI docs example, is in [`fixtures/rejected.md`](fixtures/rejected.md); the
tree-level reasoning is in [`docs/tree-decisions.md`](docs/tree-decisions.md).

| Not expressible | Why |
|---|---|
| Two placement classes on one dropdown (a corner, e.g. `dropdown-top dropdown-end`) | daisyUI declares `placement` as pick-at-most-one, so the config holds one value |
| A `card` or an arbitrary popover as `dropdown-content` | a dropdown's content is a `MenuSpec`, which keeps a leaf from containing blocks |
| A `btn-primary` anywhere but the page CTA (drawer buttons, FAB main actions, modal confirms) | exactly one primary CTA per page; `Leaf.Button`'s colour type omits `Primary` |
| A `card` or `collapse` carrying `join-item` | `JoinItem` is a closed list of button, input, select and text, so a block cannot be joined |
| A `modal`, `drawer` or `toast` inside a `Block` | overlays exist only in `Page.overlays`, which is what fixes the stacking order |
| A `card-body` or any other `part` class on a standalone element | parts are fields of their component's parts record |
| Tailwind variant prefixes such as `is-drawer-open:` | they are variants, not classes an element can carry |
| Per-call spacing overrides between sections or blocks | spacing comes from one constant table, `Daisy.Render.tokens` |

## Testing and CI

Everything the type checker does not guarantee has a test. `bash tools/ci.sh` runs the whole thing
in a fixed order: gen-schema diff → `elm make` → package docs → elm-review → elm-test → render
audit → should-not-compile → gen-cally-css → demo build → css-coverage → Playwright. Any failure
stops it.

| Tier | What | Count | Asserts |
|---|---|---|---|
| A | elm-test (`tests/`) | 931 | class coverage against `schema.json`, group exclusivity under fuzzing, part/parent pairing, render purity and determinism, and a hand-written tree per daisyUI docs example (`fixtures/corpus`) |
| B | elm-review rule tests (`review/tests/`) | 24 | positive and negative cases for `NoClassOutsideRender`, `NoHtmlInDemo`, `NoRawSchemaStrings` |
| B | should-not-compile (`tools/should-not-compile/`) | 21 | 20 fixtures that must fail `elm make` with the expected error, plus one control that must compile |
| B | css-coverage | — | every class in `Daisy.Schema.allClasses` is present in the built demo CSS |
| B | package docs | — | `elm make --docs` and `elm-format --validate src`, the two things `elm publish` checks |
| C | Playwright (`e2e/`) | 293 across 6 projects | overlap, overflow, stacking layers, responsive behaviour, 35-theme screenshot baselines, WCAG contrast, axe a11y, keyboard and focus trapping, interaction |

The six Playwright projects are viewports 375/768/1440 × themes light/dark; `themes.spec.ts`
sweeps all 35 daisyUI themes inside one of them. Baselines are committed in `e2e/snapshots`.

## Further reading

- [`SPEC.md`](SPEC.md) — the specification this package was built to
- [`docs/placement.md`](docs/placement.md) — every daisyUI component assigned to a tree level, with reasons
- [`docs/tree-decisions.md`](docs/tree-decisions.md) — where the implementation refines or deviates from the spec
- [`fixtures/rejected.md`](fixtures/rejected.md) — docs examples the tree refuses, each with a reason
- [`CLAUDE.md`](CLAUDE.md) — repository conventions and commands

## Licence

BSD-3-Clause. See [`LICENSE`](LICENSE).
