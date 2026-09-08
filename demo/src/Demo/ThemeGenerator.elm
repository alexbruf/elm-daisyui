module Demo.ThemeGenerator exposing
    ( Config, page
    , ThemeEdit, apply
    , exportCss, exportJson
    )

{-| The theme generator demo (route `/theme`).

A recreation of daisyUI's own theme generator
(<https://daisyui.com/theme-generator/>), laid out the way that page is laid
out: `Shell.Plain` with the site's navbar as a `Section.Navbar` band, then one
twelve-column `GridSection.Spans` band of a theme list (`Span2`), the editor
(`Span3`) and the components demo (`Span7`, itself a three-column grid), and the
exported CSS under them.

The whole page renders under the theme being edited, because there is nowhere
else for it to render — `Page.theme` is a `Daisy.Tree.Theme`, the router keeps
exactly one, and the editor writes to it. That is the point of the page: the
sidebar, the navbar and the editor's own controls are all repainted by the same
twenty-nine inline custom properties the preview is, so a colour that does not
work is visible in the chrome as well as in the swatch.

`data-theme` on this page is always `acme`, never `nord` or `dark`, even when
"Start from" says `nord`: [`Demo.Themes.rename`](Demo-Themes#rename) gives the
copied values the demo's own name. No stylesheet anywhere declares an `acme`
theme, so every colour on the page can only have come from
`Daisy.Render.page`'s inline properties.

Built only from `Daisy.Tree` / `Daisy.Chart` / `Daisy.Color` / `Daisy.Schema.*`
constructors — this module imports no `Html`.

@docs Config, page


# Editing

The editor's controls do not carry functions: every change is one value of the
closed [`ThemeEdit`](#ThemeEdit) type, and [`apply`](#apply) is the only thing
that turns one into a new theme. `Main` therefore needs a single `ThemeEdited`
constructor rather than one per control.

@docs ThemeEdit, apply


# Export

@docs exportCss, exportJson

-}

import BasePath
import Daisy.Chart as DChart
import Daisy.Color as Color exposing (Oklch)
import Daisy.Icon as Icon
import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Card as SCard
import Daisy.Schema.Chat as SChat
import Daisy.Schema.Checkbox as SCheckbox
import Daisy.Schema.Divider as SDivider
import Daisy.Schema.Input as SInput
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Progress as SProgress
import Daisy.Schema.Rating as SRating
import Daisy.Schema.Select as SSelect
import Daisy.Schema.Stat as SStat
import Daisy.Schema.Status as SStatus
import Daisy.Schema.Steps as SSteps
import Daisy.Schema.Tab as STab
import Daisy.Schema.Table as STable
import Daisy.Schema.Timeline as STimeline
import Daisy.Schema.Toggle as SToggle
import Daisy.Themes as Themes
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , Border(..)
        , ButtonColor(..)
        , CardChild(..)
        , ChipGlyph(..)
        , ColorScheme(..)
        , CustomTheme
        , DashboardShell
        , Field
        , Fieldset
        , InputType(..)
        , JoinItem(..)
        , LabelPlacement(..)
        , Leaf(..)
        , ListRow
        , MenuGlyph(..)
        , MenuItem(..)
        , MenuSpec
        , NavbarParts
        , Page(..)
        , RadialSize(..)
        , Radius(..)
        , Row
        , Section(..)
        , Sections(..)
        , Shell(..)
        , Size(..)
        , SwatchColor(..)
        , Tab
        , Theme(..)
        , ThemePresentation(..)
        , TimelineModifier(..)
        )
import Demo.Themes as DemoThemes


{-| What the generator page needs from the router.

`edited` is the theme the editor is showing, which is also `Page.theme`; the
router derives it once (`Demo.Themes.rename model.theme`) and hands it here so
this module never has to know how the shared theme became a `CustomTheme`.

`generatorUrl` is the answer to the last `Ports.encodeTheme` — the
`https://daisyui.com/theme-generator/#theme=<hash>` link the "Open in daisyUI
theme generator" anchor points at.

-}
type alias Config msg =
    { basePath : String
    , edited : CustomTheme
    , saved : List CustomTheme
    , lastMsg : String
    , generatorUrl : String
    , hoveredSales : Maybe Int
    , onSalesHover : Maybe Int -> msg
    , onNavigate : String -> msg
    , onEdit : ThemeEdit -> msg
    , onSaveTheme : msg
    , onExport : msg
    }


{-| The whole theme generator as one `Page`.
-}
page : Config msg -> Page msg
page config =
    Page
        { header = Nothing
        , shell = Plain
        , sections =
            Sections3
                (navbarSection config)
                (generatorSection config)
                (exportSection config)
        , cta = copyCta config
        , overlays = []
        , theme = Custom config.edited
        , dock = Nothing
        , fab = Nothing
        }



-- EDITING -------------------------------------------------------------------


{-| One change to the theme being edited.

Closed, and every payload is either another closed type or a string that comes
straight off a control the page itself rendered — a `#rrggbb` from a colour
`Input`, or one of the option labels a `Select` was given. An unparseable string
leaves the theme alone rather than throwing: [`apply`](#apply) is total.

-}
type ThemeEdit
    = StartFrom String
    | SetColor Slot String
    | SetRadius RadiusTarget String
    | SetSize SizeTarget String
    | SetBorder String
    | SetName String
    | SetScheme Bool
    | SetDepth Bool
    | SetNoise Bool
    | Randomize


{-| Apply one edit.

Total: an unrecognised payload returns the theme unchanged. The `seed` is only
read by `Randomize`; the router keeps a counter and passes it here, so the page
itself stays a pure function of the model and two identical runs of the demo
produce identical screenshots.

-}
apply : Int -> ThemeEdit -> CustomTheme -> CustomTheme
apply seed edit theme =
    case edit of
        StartFrom name ->
            case DemoThemes.named name of
                Just picked ->
                    DemoThemes.rename picked

                Nothing ->
                    theme

        SetColor slot hex ->
            case Color.hexToOklch hex of
                Just oklch ->
                    { theme | colors = setSlot slot oklch theme.colors }

                Nothing ->
                    theme

        SetRadius target label ->
            case radiusFromLabel label of
                Just radius ->
                    { theme | radius = setRadius target radius theme.radius }

                Nothing ->
                    theme

        SetSize target label ->
            case sizeFromLabel label of
                Just size ->
                    { theme | size = setSize target size theme.size }

                Nothing ->
                    theme

        SetBorder label ->
            case borderFromLabel label of
                Just border ->
                    { theme | border = border }

                Nothing ->
                    theme

        SetName name ->
            case Tree.themeName name of
                Just valid ->
                    { theme | name = valid }

                Nothing ->
                    theme

        SetScheme dark ->
            { theme
                | colorScheme =
                    if dark then
                        DarkScheme

                    else
                        LightScheme
            }

        SetDepth on ->
            { theme | depth = on }

        SetNoise on ->
            { theme | noise = on }

        Randomize ->
            randomize seed theme


{-| The theme's CSS, as `@plugin "daisyui/theme" { ... }`.
-}
exportCss : CustomTheme -> String
exportCss =
    Tree.customThemeToCss


{-| The theme in daisyUI's own generator JSON shape, which `Ports.encodeTheme`
compresses into the `#theme=` hash.
-}
exportJson : CustomTheme -> String
exportJson =
    Tree.customThemeToJson



-- COLOUR SLOTS --------------------------------------------------------------


{-| One of the twenty `--color-*` variables, as an editable slot.
-}
type Slot
    = SlotBase100
    | SlotBase200
    | SlotBase300
    | SlotBaseContent
    | SlotPrimary
    | SlotPrimaryContent
    | SlotSecondary
    | SlotSecondaryContent
    | SlotAccent
    | SlotAccentContent
    | SlotNeutral
    | SlotNeutralContent
    | SlotInfo
    | SlotInfoContent
    | SlotSuccess
    | SlotSuccessContent
    | SlotWarning
    | SlotWarningContent
    | SlotError
    | SlotErrorContent


getSlot : Slot -> Tree.ThemeColors -> Oklch
getSlot slot colors =
    case slot of
        SlotBase100 ->
            colors.base100

        SlotBase200 ->
            colors.base200

        SlotBase300 ->
            colors.base300

        SlotBaseContent ->
            colors.baseContent

        SlotPrimary ->
            colors.primary

        SlotPrimaryContent ->
            colors.primaryContent

        SlotSecondary ->
            colors.secondary

        SlotSecondaryContent ->
            colors.secondaryContent

        SlotAccent ->
            colors.accent

        SlotAccentContent ->
            colors.accentContent

        SlotNeutral ->
            colors.neutral

        SlotNeutralContent ->
            colors.neutralContent

        SlotInfo ->
            colors.info

        SlotInfoContent ->
            colors.infoContent

        SlotSuccess ->
            colors.success

        SlotSuccessContent ->
            colors.successContent

        SlotWarning ->
            colors.warning

        SlotWarningContent ->
            colors.warningContent

        SlotError ->
            colors.error

        SlotErrorContent ->
            colors.errorContent


setSlot : Slot -> Oklch -> Tree.ThemeColors -> Tree.ThemeColors
setSlot slot value colors =
    case slot of
        SlotBase100 ->
            { colors | base100 = value }

        SlotBase200 ->
            { colors | base200 = value }

        SlotBase300 ->
            { colors | base300 = value }

        SlotBaseContent ->
            { colors | baseContent = value }

        SlotPrimary ->
            { colors | primary = value }

        SlotPrimaryContent ->
            { colors | primaryContent = value }

        SlotSecondary ->
            { colors | secondary = value }

        SlotSecondaryContent ->
            { colors | secondaryContent = value }

        SlotAccent ->
            { colors | accent = value }

        SlotAccentContent ->
            { colors | accentContent = value }

        SlotNeutral ->
            { colors | neutral = value }

        SlotNeutralContent ->
            { colors | neutralContent = value }

        SlotInfo ->
            { colors | info = value }

        SlotInfoContent ->
            { colors | infoContent = value }

        SlotSuccess ->
            { colors | success = value }

        SlotSuccessContent ->
            { colors | successContent = value }

        SlotWarning ->
            { colors | warning = value }

        SlotWarningContent ->
            { colors | warningContent = value }

        SlotError ->
            { colors | error = value }

        SlotErrorContent ->
            { colors | errorContent = value }


{-| The `--color-*` name of a slot, used as the field label so the colour input
is named by the variable it edits.
-}
slotLabel : Slot -> String
slotLabel slot =
    case slot of
        SlotBase100 ->
            "base-100"

        SlotBase200 ->
            "base-200"

        SlotBase300 ->
            "base-300"

        SlotBaseContent ->
            "base-content"

        SlotPrimary ->
            "primary"

        SlotPrimaryContent ->
            "primary-content"

        SlotSecondary ->
            "secondary"

        SlotSecondaryContent ->
            "secondary-content"

        SlotAccent ->
            "accent"

        SlotAccentContent ->
            "accent-content"

        SlotNeutral ->
            "neutral"

        SlotNeutralContent ->
            "neutral-content"

        SlotInfo ->
            "info"

        SlotInfoContent ->
            "info-content"

        SlotSuccess ->
            "success"

        SlotSuccessContent ->
            "success-content"

        SlotWarning ->
            "warning"

        SlotWarningContent ->
            "warning-content"

        SlotError ->
            "error"

        SlotErrorContent ->
            "error-content"



-- SHAPE ---------------------------------------------------------------------


{-| Which of the three `--radius-*` variables a `SetRadius` edits.
-}
type RadiusTarget
    = RadiusSelector
    | RadiusField
    | RadiusBox


setRadius :
    RadiusTarget
    -> Radius
    -> { selector : Radius, field : Radius, box : Radius }
    -> { selector : Radius, field : Radius, box : Radius }
setRadius target value radius =
    case target of
        RadiusSelector ->
            { radius | selector = value }

        RadiusField ->
            { radius | field = value }

        RadiusBox ->
            { radius | box = value }


{-| Which of the two `--size-*` variables a `SetSize` edits.
-}
type SizeTarget
    = SizeSelector
    | SizeField


setSize : SizeTarget -> Size -> { selector : Size, field : Size } -> { selector : Size, field : Size }
setSize target value size =
    case target of
        SizeSelector ->
            { size | selector = value }

        SizeField ->
            { size | field = value }


{-| A `Select` carries strings, so each closed step is offered under the CSS
length it stands for — which is also what the exported CSS shows, so the control
and the export read the same.
-}
radiusFromLabel : String -> Maybe Radius
radiusFromLabel label =
    List.head (List.filter (\r -> Tree.radiusToString r == label) Tree.allRadii)


sizeFromLabel : String -> Maybe Size
sizeFromLabel label =
    List.head (List.filter (\s -> Tree.sizeToString s == label) Tree.allSizes)


borderFromLabel : String -> Maybe Border
borderFromLabel label =
    List.head (List.filter (\b -> Tree.borderToString b == label) Tree.allBorders)



-- RANDOMIZE -----------------------------------------------------------------


{-| A new palette from one integer.

Deterministic on purpose: a screenshot baseline of this page has to be the same
on every run, and `Random.generate` would need a `Cmd` and a seed the demo does
not have. The generator is a plain linear congruential sequence — Numerical
Recipes' constants — advanced once per value, which is more than enough for
"give me a different hue".

The structure is kept rather than randomised: the eight semantic colours get a
random hue at a fixed lightness and chroma, and each `*-content` is the very
light or very dark counterpart of its own hue, so a randomised theme still has
readable pairs instead of noise.

-}
randomize : Int -> CustomTheme -> CustomTheme
randomize seed theme =
    let
        dark : Bool
        dark =
            theme.colorScheme == DarkScheme

        hue : Int -> Float
        hue index =
            toFloat (modBy 360 (lcg (seed + (index * 7919))))

        surface : Float -> Float -> Oklch
        surface lightness h =
            { l = lightness, c = 0.01, h = h }

        vivid : Int -> Oklch
        vivid index =
            { l =
                if dark then
                    72

                else
                    58
            , c = 0.19
            , h = hue index
            }

        readable : Oklch -> Oklch
        readable base =
            { l =
                if base.l > 55 then
                    18

                else
                    97
            , c = 0.02
            , h = base.h
            }

        pair : Int -> ( Oklch, Oklch )
        pair index =
            let
                base : Oklch
                base =
                    vivid index
            in
            ( base, readable base )

        ( primary, primaryContent ) =
            pair 1

        ( secondary, secondaryContent ) =
            pair 2

        ( accent, accentContent ) =
            pair 3

        ( info, infoContent ) =
            pair 4

        ( success, successContent ) =
            pair 5

        ( warning, warningContent ) =
            pair 6

        ( error, errorContent ) =
            pair 7

        neutralHue : Float
        neutralHue =
            hue 8
    in
    { theme
        | colors =
            { base100 = surface (ifDark dark 22 98) neutralHue
            , base200 = surface (ifDark dark 18 95) neutralHue
            , base300 = surface (ifDark dark 14 90) neutralHue
            , baseContent = surface (ifDark dark 95 20) neutralHue
            , primary = primary
            , primaryContent = primaryContent
            , secondary = secondary
            , secondaryContent = secondaryContent
            , accent = accent
            , accentContent = accentContent
            , neutral = surface (ifDark dark 32 24) neutralHue
            , neutralContent = surface (ifDark dark 92 96) neutralHue
            , info = info
            , infoContent = infoContent
            , success = success
            , successContent = successContent
            , warning = warning
            , warningContent = warningContent
            , error = error
            , errorContent = errorContent
            }
    }


ifDark : Bool -> Float -> Float -> Float
ifDark dark whenDark whenLight =
    if dark then
        whenDark

    else
        whenLight


{-| One step of a 32-bit linear congruential generator (Numerical Recipes:
`a = 1664525`, `c = 1013904223`), kept inside `Int` range by masking with
`modBy` rather than relying on JavaScript's 53-bit floats.
-}
lcg : Int -> Int
lcg state =
    modBy 2147483647 (abs ((1664525 * modBy 65536 state) + 1013904223 + (state // 3)))



-- SHELL ---------------------------------------------------------------------


{-| `Shell.Plain` with a `Section.Navbar` band, not `Shell.Dashboard`.

daisyUI's generator is not a dashboard: it is a page with the site's own navbar
across the top and three columns under it. A `Dashboard` shell would put a 256px
application sidebar to the left of a page whose left-hand column _is_ a list —
two rails side by side, which is the thing that made this page read as a
different one.

`Page.cta` is `InNavbar`, which under `Plain` now means the page's own navbar
band (`Daisy.Render.plainBody`).

-}
navbarSection : Config msg -> Section msg
navbarSection config =
    Navbar
        { start = [ brandLink config ]
        , center = []
        , end = List.map (navLink config) navDestinations
        }


brandLink : Config msg -> Leaf msg
brandLink config =
    Link
        { defaultLink
            | href = href config "/"
            , onClick = Just (config.onNavigate "/")
        }
        "Acme"


navDestinations : List ( String, String )
navDestinations =
    [ ( "Overview", "/" ), ( "Analytics", "/analytics" ), ( "Settings", "/settings" ) ]


navLink : Config msg -> ( String, String ) -> Leaf msg
navLink config ( label, path ) =
    Link
        { defaultLink
            | href = href config path
            , onClick = Just (config.onNavigate path)
        }
        label


{-| A route as it must appear in an `href`: the demo's own path with the
deployment's base path in front of it.
-}
href : Config msg -> String -> String
href config path =
    BasePath.join config.basePath path


{-| The page's one primary button, which the shell puts at the end of the navbar
band. The editor column carries its own `CSS` button firing the same message —
daisyUI's generator has one there, beside `Random`, and this page has to keep a
`Page.cta` besides.
-}
copyCta : Config msg -> Tree.Cta msg
copyCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Copy CSS" config.onExport
    in
    { base | icon = Just Icon.Document, size = Just SButton.Sm }


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig


defaultButton : Tree.ButtonConfig msg
defaultButton =
    Tree.defaultButtonConfig


defaultBadge : Tree.BadgeConfig
defaultBadge =
    Tree.defaultBadgeConfig


defaultInput : Tree.InputConfig msg
defaultInput =
    Tree.defaultInputConfig


defaultSelect : Tree.SelectConfig msg
defaultSelect =
    Tree.defaultSelectConfig


defaultToggle : Tree.ToggleConfig msg
defaultToggle =
    Tree.defaultToggleConfig


emptyCard : Tree.CardParts msg
emptyCard =
    Tree.emptyCardParts


defaultCheckbox : Tree.CheckboxConfig msg
defaultCheckbox =
    Tree.defaultCheckboxConfig


defaultIcon : Tree.IconConfig
defaultIcon =
    Tree.defaultIconConfig


defaultTextarea : Tree.TextareaConfig msg
defaultTextarea =
    Tree.defaultTextareaConfig


defaultProgress : Tree.ProgressConfig
defaultProgress =
    Tree.defaultProgressConfig


defaultRange : Tree.RangeConfig msg
defaultRange =
    Tree.defaultRangeConfig


defaultRating : Tree.RatingConfig msg
defaultRating =
    Tree.defaultRatingConfig


baseCard : Tree.CardConfig
baseCard =
    Tree.defaultCardConfig


defaultTable : Tree.TableConfig
defaultTable =
    Tree.defaultTableConfig


{-| Every panel on this page, and it is daisyUI's own class list rather than an
approximation of it.

Read off <https://daisyui.com/theme-generator/>, every preview block is
`card bg-base-100 card-border border-base-300 card-sm` — so this is
`SCard.Border` plus `SCard.Sm`, and `CardPadding.PaddingDefault`, which leaves
`card-sm`'s own `--card-p` (1rem) and its 0.875rem body text alone.

It used to be `PaddingDashboard` with no size: a 20px gutter and 1rem text in a
258px card, which is where the loose preview came from. The dashboards keep
`PaddingDashboard` — that is Nexus's figure, and this page is reproducing a
different reference.

-}
previewCard : Tree.CardConfig
previewCard =
    { baseCard | style = Just SCard.Border, size = Just SCard.Sm }


{-| The editor rail's and the theme list's own "card", which is no card at all.

daisyUI's editor column is `bg-base-100 flex flex-col gap-4 p-6` straight on the
page, with `divider`s where a card would have had a title — read off the same
page as `previewCard`'s class list. `CardSurface.SurfaceBare` is that: the same
`CardParts`, no panel, and not one `card-*` class emitted.

-}
bareCard : Tree.CardConfig
bareCard =
    { baseCard | surface = Tree.SurfaceBare }



-- THE GENERATOR BAND ----------------------------------------------------------


{-| The three columns daisyUI's generator has, as one twelve-column band.

Measured on <https://daisyui.com/theme-generator/> at 1440: a theme list of
191px, an editor of 224px in a 272px rail, and a preview of 879px laid out
`grid gap-6 xl:grid-cols-3` in 277px columns.

In a `Shell.Plain` content column of 1392px, twelve tracks are 101.33px each
with 16px gutters, so a cell of N tracks is `101.33N + 16(N-1)`:
2 : 3 : 7 is 218.7 : 336 : 805.3, and the preview cell divides itself into three
257.8px columns (`CellColumns.CellThree`).

**That split is forced, not chosen.** The theme list needs ~112px of row
(`caramellatte` at the `menu-xs` step behind an 18px palette tile), so `Span2`
is its floor. The editor holds a 224px chip grid _and_ a 280px radius row inside
a `p-5` card body, so `Span3` (296px inner) is its floor — `Span2` would be
178.7px inner. That leaves `Span7`, and 3 x 277 + 2 x 16 = 863px of preview is
between `Span7` (805.3) and `Span8` (922.7), so no split gives daisyUI's card
width. Ours is 19.2px narrower; `docs/tree-decisions.md`, "The generator's
editor column", section 4 has the arithmetic.

-}
generatorSection : Config msg -> Section msg
generatorSection config =
    Grid
        (Tree.Spans
            [ Tree.spanColumn Tree.Span2 (themesColumn config)
            , Tree.spanColumn Tree.Span3 (editorColumn config)
            , Tree.spanLead Tree.Span7 Tree.CellThree [ previewHeader ] (previewCards config)
            ]
        )



-- (a) THE THEME LIST ----------------------------------------------------------


{-| daisyUI's left rail, block for block: a bold `Themes` heading with a `…`
menu button beside it, the "Hold to add theme" button under it, then `My
themes` and `daisyUI themes` as two lists with a rule between them.

Measured on <https://daisyui.com/theme-generator/>: the heading is
`font-semibold` at the body step in `--color-base-content`, the `…` is a
`btn btn-ghost btn-square btn-sm`, the list is a plain `menu` (not `menu-xs` —
their rows are 33px, ours were 26px), the rows are `gap-3 px-2` with a
four-dot palette tile, and the current one is tinted `bg-base-content/10`.

The tint is why `MenuActiveStyle.TintedActive` changed in this pass: it used to
be `bg-base-200`, and a menu on the page ground **is** `bg-base-200`, so with
`?theme=light` (base-100 100%, base-200 98%) the current row was invisible. See
`Daisy.Render.tokenTintActive`.

Clicking a row **is** the "start from" control — it fires the same `StartFrom`
edit the `<select>` used to, which is why that select is gone.

The glyph is daisyUI's own four-colour tile: that theme's `base-100` with its
`base-content`, `primary`, `secondary` and `accent` on it. It is a
`MenuGlyph.MenuThemeDots`, which carries a whole `Theme` rather than an
[`Icon`](Daisy-Icon) — a row of the list _is_ a theme, and none of its four
colours can be a class, because the class would paint the theme being edited
instead of the theme the row is offering.

-}
themesColumn : Config msg -> List (Block msg)
themesColumn config =
    [ themesHeader config
    , myThemesMenu config
    , listRule
    , daisyThemesMenu config
    ]


{-| The heading row and the add button, on the page ground rather than in a
card: `CardSurface.SurfaceBare`.
-}
themesHeader : Config msg -> Block msg
themesHeader config =
    Card bareCard
        { emptyCard
            | title = Just "Themes"
            , headerActions = [ themeListOptionsButton ]
            , body = [ CardLeaf (holdToAddButton config) ]
        }


{-| daisyUI's `…` button beside the heading. Theirs opens a two-item dropdown
("Remove my themes", "Reset daisyUI themes"), both of which write to the
browser's local storage; ours has nothing to remove that a reload would not,
so it is the same control with no menu behind it.
-}
themeListOptionsButton : Leaf msg
themeListOptionsButton =
    Button
        { defaultButton
            | icon = Just Icon.EllipsisHorizontal
            , ariaLabel = Just "Theme list options"
            , style = Just SButton.Ghost
            , size = Just SButton.Sm
            , modifiers = [ SButton.Square ]
        }
        ""


{-| daisyUI's "**Hold** to add theme".

Theirs is held rather than clicked because the press writes to local storage;
ours is a plain click, and what it saves is a copy of the theme being edited
into `My themes` **in the model** — one `ThemeSaved` message, no port, no
storage. The label keeps their wording because the button keeps their job.

The glyph is `Icon.Sparkles` (heroicons `sparkles`); daisyUI draws a magic wand
of its own, which is not in the closed twenty-five-turned-thirty-eight set.

-}
holdToAddButton : Config msg -> Leaf msg
holdToAddButton config =
    Button
        { defaultButton
            | icon = Just Icon.Sparkles
            , style = Just SButton.Soft
            , size = Just SButton.Sm
            , onClick = Just config.onSaveTheme
        }
        "Hold to add theme"


{-| The rule daisyUI draws between the two groups. Two menus with a divider
between them, rather than one menu with a divider row: a `menu` holds `<li>`s,
and a horizontal rule is not one of them.
-}
listRule : Block msg
listRule =
    Prose [ Divider Tree.defaultDividerConfig Nothing ]


myThemesMenu : Config msg -> Block msg
myThemesMenu config =
    Menu defaultMenu
        (groupTitle "My themes"
            :: List.map (themeRow config << Custom) (config.saved ++ [ DemoThemes.acme ])
        )


daisyThemesMenu : Config msg -> Block msg
daisyThemesMenu config =
    Menu defaultMenu
        (groupTitle "daisyUI themes" :: List.map (themeRow config) Tree.allThemes)


{-| daisyUI's list is a plain `menu`: no `menu-xs`. Their rows measure 33px,
which is `menu`'s own step, and `menu-xs` made ours 26px — the single biggest
reason the two rails did not line up.
-}
defaultMenu : Tree.MenuConfig
defaultMenu =
    { baseMenu | activeStyle = Tree.TintedActive }


baseMenu : Tree.MenuConfig
baseMenu =
    Tree.defaultMenuConfig


groupTitle : String -> MenuItem msg
groupTitle label =
    let
        (MenuItem base) =
            Tree.menuItem label
    in
    MenuItem { base | title = True }


themeRow : Config msg -> Theme -> MenuItem msg
themeRow config theme =
    let
        name : String
        name =
            case theme of
                Custom custom ->
                    Tree.themeNameToString custom.name

                builtin ->
                    Tree.themeToString builtin

        (MenuItem base) =
            Tree.menuItem name
    in
    MenuItem
        { base
            | glyph = Just (MenuThemeDots theme)
            , active = name == startingPoint config.edited
            , onClick = Just (config.onEdit (StartFrom name))
        }



-- (b) THE EDITOR --------------------------------------------------------------


editorColumn : Config msg -> List (Block msg)
editorColumn config =
    [ nameBlock config
    , changeColorsBlock config
    , radiusBlock config
    , sizeBlock config
    , paletteBlock config
    ]


{-| The top of daisyUI's editor: the theme's `Name` with a pencil beside it,
then `Random` and `CSS` as two halves of the rail's width.

No card. Theirs is `<label class="input input-ghost input-sm flex items-center
gap-2 font-semibold"><span class="text-xs opacity-60">Name</span><input/><svg
pencil/></label>` followed by `<div class="grid grid-cols-2 gap-2">` of two
buttons — which is `InputConfig.prefix` / `InputConfig.trailingIcon` and a
`JoinConfig.stretch` here, and `CardSurface.SurfaceBare` around both.

The "Open in daisyUI theme generator" link moved out of the middle of the
editor and onto this row as `actions`, where it reads as a footnote to the name
rather than as a control between two sections.

-}
nameBlock : Config msg -> Block msg
nameBlock config =
    Card bareCard
        { emptyCard
            | body =
                [ CardLeaf (nameInput config)
                , CardLeaf
                    (Join
                        { defaultJoin | stretch = True }
                        [ JoinButton
                            { defaultButton
                                | icon = Just Icon.ArrowPath
                                , onClick = Just (config.onEdit Randomize)
                            }
                            "Random"
                        , JoinButton
                            { defaultButton
                                | icon = Just Icon.CodeBracket
                                , color = Just Neutral
                                , onClick = Just config.onExport
                            }
                            "CSS"
                        ]
                    )
                ]
        }


defaultJoin : Tree.JoinConfig
defaultJoin =
    Tree.defaultJoinConfig


{-| The theme's own name, editable.

`ThemeName` is opaque and validated (`[a-z][a-z0-9-]*`, and none of daisyUI's
thirty-five reserved names), so [`apply`](#apply) simply leaves the theme alone
when what was typed is not one — which is why this can be a plain text field
rather than a form with an error state.

-}
nameInput : Config msg -> Leaf msg
nameInput config =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , style = Just SInput.Ghost
            , prefix = Just "Name"
            , trailingIcon = Just Icon.Pencil
            , ariaLabel = Just "Theme name"
            , value = Tree.themeNameToString config.edited.name
            , onInput = Just (config.onEdit << SetName)
        }


{-| daisyUI's "Change Colors" grid: `base` across the top, then each brand and
state colour beside its own `-content` partner.

One `Leaf.ColorChips`, not twenty `Field` rows and not five cards of four
`Join`ed colour inputs, which is what this was. The chips are exactly daisyUI's:
44x40 rounded squares painted in the colour they edit, `100` / `200` / `300` on
the three base surfaces, and a bold `A` on every chip whose _content_ colour it
is — so the pair shows the letter it is responsible for making readable. The
`A` chip of `base` sits on `base-300` rather than on `base-content`, again as
daisyUI's does: `base-content` is a text colour, and a chip filled with it would
be a black square in every light theme.

Each square opens the browser's own colour picker, because the input lies over
it invisible; the name a screen reader and a test read is the `--color-*`
variable the chip edits (`primary`, `primary-content`), which is what
`e2e/theme-generator.spec.ts` asks for by label.

-}
changeColorsBlock : Config msg -> Block msg
changeColorsBlock config =
    Card bareCard
        { emptyCard
            | body =
                [ CardLeaf (sectionHeader Icon.Swatch "Change Colors")
                , CardLeaf (ColorChips (colorGroups config))
                ]
        }


{-| daisyUI's section heading in that rail: `<h3 class="divider divider-start
text-xs"><span class="flex gap-1.5"><svg/> Change Colors</span></h3>`.

A rule that runs off to the right of a labelled glyph — which is `Leaf.Divider`
with `Placement.Start`, the `icon` this pass added to `DividerConfig`, and
`caption = True` for the `text-xs` step. It replaces five `card-title`s: a
card title says "this is a panel", and the rail is not panels.

-}
sectionHeader : Icon.Icon -> String -> Leaf msg
sectionHeader icon label =
    Divider
        { defaultDivider
            | placement = Just SDivider.Start
            , icon = Just icon
            , caption = True
        }
        (Just label)


defaultDivider : Tree.DividerConfig
defaultDivider =
    Tree.defaultDividerConfig


{-| daisyUI's own grouping, in its order: the four base slots as one group, then
eight pairs.
-}
colorGroups : Config msg -> List (Tree.ColorChipGroup msg)
colorGroups config =
    baseGroup config
        :: List.map (pairGroup config)
            [ ( SlotPrimary, SlotPrimaryContent )
            , ( SlotSecondary, SlotSecondaryContent )
            , ( SlotAccent, SlotAccentContent )
            , ( SlotNeutral, SlotNeutralContent )
            , ( SlotInfo, SlotInfoContent )
            , ( SlotSuccess, SlotSuccessContent )
            , ( SlotWarning, SlotWarningContent )
            , ( SlotError, SlotErrorContent )
            ]


baseGroup : Config msg -> Tree.ColorChipGroup msg
baseGroup config =
    let
        colors : Tree.ThemeColors
        colors =
            config.edited.colors

        ink : Oklch
        ink =
            colors.baseContent
    in
    { label = "base"
    , chips =
        [ chip config SlotBase100 (ChipLabel "100") colors.base100 ink
        , chip config SlotBase200 (ChipLabel "200") colors.base200 ink
        , chip config SlotBase300 (ChipLabel "300") colors.base300 ink
        , chip config SlotBaseContent ChipSpecimen colors.base300 ink
        ]
    }


pairGroup : Config msg -> ( Slot, Slot ) -> Tree.ColorChipGroup msg
pairGroup config ( surface, content ) =
    let
        background : Oklch
        background =
            getSlot surface config.edited.colors

        foreground : Oklch
        foreground =
            getSlot content config.edited.colors
    in
    { label = slotLabel surface
    , chips =
        [ chip config surface ChipBlank background foreground
        , chip config content ChipSpecimen background foreground
        ]
    }


{-| One chip: painted `background` with its `glyph` in `foreground`, editing
whichever of the two `slot` names.
-}
chip : Config msg -> Slot -> ChipGlyph -> Oklch -> Oklch -> Tree.ColorChip msg
chip config slot glyph background foreground =
    { color = background
    , contentColor = foreground
    , value = getSlot slot config.edited.colors
    , glyph = glyph
    , ariaLabel = slotLabel slot
    , onChange = Just (config.onEdit << SetColor slot)
    }


{-| daisyUI's `Radius` block: three groups of five tiles, each headed by what
it shapes and, in faint italic under it, which components that reaches.

Each row is a `Leaf.RadiusTiles` — a real radio group whose five steps are drawn
as the corner each one sets. The _look_ is daisyUI's, and it changed in this
pass: a `rounded-field bg-base-200` frame with the corner inset from two sides,
the corner stroked `--color-base-content/20` over `bg-base-300`, and the
current step stroked `--color-primary` with no fill. It used to be a `join` of
`btn`s with the marked step `btn-neutral` — a filled black slab, which is a
different control from the one daisyUI ships.

The two-line heading is part of the leaf (`RadiusTilesConfig.label` /
`.caption`) rather than a `Leaf.Text` beside it, because a `<label>` around
five radios would make clicking the heading press the first of them.

-}
radiusBlock : Config msg -> Block msg
radiusBlock config =
    Card bareCard
        { emptyCard
            | body =
                [ CardLeaf (sectionHeader Icon.Squares2x2 "Radius")
                , CardLeaf (radiusChoice config "Boxes" "card, modal, alert" RadiusBox config.edited.radius.box)
                , CardLeaf (radiusChoice config "Fields" "button, input, select, tab" RadiusField config.edited.radius.field)
                , CardLeaf (radiusChoice config "Selectors" "checkbox, toggle, badge" RadiusSelector config.edited.radius.selector)
                ]
        }


{-| daisyUI's `Sizes`, `Border` and `Effects` blocks, under one heading.
-}
sizeBlock : Config msg -> Block msg
sizeBlock config =
    Card bareCard
        { emptyCard
            | body =
                [ CardLeaf (sectionHeader Icon.Cog "Sizes and effects")
                , CardLeaf (groupLabel "Field base size (rem)")
                , CardLeaf (sizeChoice config "Field base size" SizeField config.edited.size.field)
                , CardLeaf (groupLabel "Selector base size (rem)")
                , CardLeaf (sizeChoice config "Selector base size" SizeSelector config.edited.size.selector)
                , CardLeaf (groupLabel "Border width (px)")
                , CardLeaf (borderChoice config)
                , CardForm
                    [ { legend = Nothing
                      , columns = Tree.OneColumn
                      , fields =
                            [ Tree.field "Dark color scheme" (schemeToggle config)
                            , Tree.field "Depth effect" (effectToggle config SetDepth config.edited.depth)
                            , Tree.field "Noise effect" (effectToggle config SetNoise config.edited.noise)
                            ]
                      }
                    ]
                ]
        }


{-| The heading above a segmented control.

It is a `Leaf.Text`, not a `Field` label: a `Field` wraps its control in the
`<label>` itself, and a `<label>` around five buttons would make clicking the
heading press the first of them.

-}
groupLabel : String -> Leaf msg
groupLabel text =
    Text text


lengthChoice : Config msg -> String -> (String -> ThemeEdit) -> List String -> String -> Leaf msg
lengthChoice config group toEdit options current =
    Join Tree.defaultJoinConfig
        (List.map
            (\option ->
                JoinButton
                    { defaultButton
                        | size = Just SButton.Xs
                        , ariaLabel = Just (group ++ " " ++ option)
                        , color =
                            if option == current then
                                Just Neutral

                            else
                                Nothing
                        , onClick = Just (config.onEdit (toEdit option))
                    }
                    (withoutUnit option)
            )
            options
        )


{-| A CSS length with its unit taken off: `0.25rem` -> `0.25`.

Six of these controls sit in a 330px rail, and five chips reading `0.28125rem`
do not fit in it. The unit is constant within a control, so it moves to the
group's heading and the chips carry only what differs. The button's _accessible_
name keeps the whole length (`Field base size 0.28125rem`), which still contains
the visible text — so the two never disagree, and a test can still ask for the
control by the value it sets.

-}
withoutUnit : String -> String
withoutUnit length =
    length
        |> String.replace "rem" ""
        |> String.replace "px" ""


radiusChoice : Config msg -> String -> String -> RadiusTarget -> Radius -> Leaf msg
radiusChoice config group caption target current =
    RadiusTiles
        { ariaLabel = Just (group ++ " radius")
        , label = Just group
        , caption = Just caption
        , onSelect = Just (\radius -> config.onEdit (SetRadius target (Tree.radiusToString radius)))
        }
        { group = group, current = current }


sizeChoice : Config msg -> String -> SizeTarget -> Size -> Leaf msg
sizeChoice config group target current =
    lengthChoice config
        group
        (SetSize target)
        (List.map Tree.sizeToString Tree.allSizes)
        (Tree.sizeToString current)


borderChoice : Config msg -> Leaf msg
borderChoice config =
    lengthChoice config
        "Border width"
        SetBorder
        (List.map Tree.borderToString Tree.allBorders)
        (Tree.borderToString config.edited.border)


{-| Which theme row the list marks, and which option the editor started from.

It is _derived_, not remembered. Every theme the editor holds is named `acme`
unless the name field says otherwise, so remembering the pick would be a second
source of truth for something the theme already says: if the edited theme's
declarations are still exactly one built-in's, that built-in is what it started
from; the first edit makes it stop matching and the mark falls back to `acme`.

-}
startingPoint : CustomTheme -> String
startingPoint edited =
    let
        sameValues : CustomTheme -> Bool
        sameValues candidate =
            Tree.customThemeStyle { candidate | name = edited.name }
                == Tree.customThemeStyle edited
    in
    Themes.all
        |> List.filter sameValues
        |> List.head
        |> Maybe.map (.name >> Tree.themeNameToString)
        |> Maybe.withDefault (Tree.themeNameToString DemoThemes.acmeName)


schemeToggle : Config msg -> Leaf msg
schemeToggle config =
    Toggle
        { defaultToggle | onCheck = Just (config.onEdit << SetScheme) }
        { checked = config.edited.colorScheme == DarkScheme }


effectToggle : Config msg -> (Bool -> ThemeEdit) -> Bool -> Leaf msg
effectToggle config toEdit on =
    Toggle
        { defaultToggle | onCheck = Just (config.onEdit << toEdit) }
        { checked = on }


{-| The palette readout: every surface the theme names, painted with itself and
labelled with the content colour that is supposed to read on it.

That is what `Leaf.Swatch` is for. daisyUI has no component whose job is "show
me this colour" — every colour class it ships belongs to a control — so the
renderer paints the chip from a named token pair per
[`SwatchColor`](Daisy-Tree#SwatchColor), and the caller only names the slot.

-}
paletteBlock : Config msg -> Block msg
paletteBlock config =
    Card bareCard
        { emptyCard
            | body = CardLeaf (sectionHeader Icon.Eye "Palette") :: List.map swatchRow swatches
            , actions = [ ThemeDots (Custom config.edited) ]
        }


swatches : List ( SwatchColor, String )
swatches =
    [ ( SwatchBase100, "base-100" )
    , ( SwatchBase200, "base-200" )
    , ( SwatchBase300, "base-300" )
    , ( SwatchPrimary, "primary" )
    , ( SwatchSecondary, "secondary" )
    , ( SwatchAccent, "accent" )
    , ( SwatchNeutral, "neutral" )
    , ( SwatchInfo, "info" )
    , ( SwatchSuccess, "success" )
    , ( SwatchWarning, "warning" )
    , ( SwatchError, "error" )
    ]


swatchRow : ( SwatchColor, String ) -> CardChild msg
swatchRow ( color, label ) =
    CardLeaf (Swatch Tree.defaultSwatchConfig color label)


{-| The link back into daisyUI's own generator, carrying this theme in its
`#theme=` hash.

It is a plain `link`, not `link-primary`: `--color-primary` as a _foreground_
over `--color-base-100` falls under 4.5:1 in several themes, and this page draws
itself under whatever theme is being edited, including deliberately bad ones.

-}
generatorLink : Config msg -> Leaf msg
generatorLink config =
    Link { defaultLink | href = config.generatorUrl } "Open in daisyUI theme generator"



-- (c) THE COMPONENTS DEMO -----------------------------------------------------


{-| The title bar over the preview columns: `Components Demo` on the left and a
three-way layout switch on the right.

daisyUI's is a `tabs tabs-box tabs-sm` of three icon-only tabs. `Daisy.Tree`'s
`Tab` carries a `String` label and no glyph, so this is the same three-button
segmented control said the way the tree can say it: a `join` of three
icon-only `btn-sm`s, the first marked. It is **decorative** — daisyUI's
switches between three preview pages this demo does not have — so none of the
three carries an `onClick`, and each one's accessible name says which layout it
stands for.

It reaches the page through `Tree.spanLead`, which is what this pass added to
`GridItem`: a title bar belongs to the _cell_, above its three columns, and
without it the only place to put it was inside column one.

-}
previewHeader : Block msg
previewHeader =
    Card bareCard
        { emptyCard
            | title = Just "Components Demo"
            , headerActions =
                [ Join Tree.defaultJoinConfig
                    [ layoutButton True Icon.Squares2x2 "Components demo"
                    , layoutButton False Icon.ListBullet "Component variants"
                    , layoutButton False Icon.Swatch "Colour palette"
                    ]
                ]
        }


layoutButton : Bool -> Icon.Icon -> String -> JoinItem msg
layoutButton current icon label =
    JoinButton
        { defaultButton
            | icon = Just icon
            , ariaLabel = Just label
            , size = Just SButton.Sm
            , modifiers = [ SButton.Square ]
            , color =
                if current then
                    Just Neutral

                else
                    Nothing
        }
        ""


{-| daisyUI's own preview grid, card for card and in its order.

Their three columns are `flex flex-col gap-4` stacks inside one
`grid xl:grid-cols-3`, and so are ours: `CellColumns.CellThree` deals a cell's
blocks into three columns, so nineteen cards become `7 + 7 + 5` and pack per
column exactly as theirs do — which is the three groups this list is already
written in. The set and the order are theirs; `docs/tree-decisions.md` lists the
two blocks that could not be reproduced and why.

-}
previewCards : Config msg -> List (Block msg)
previewCards config =
    [ -- column one
      filterPreviewCard
    , weekCard config
    , tabsCard
    , priceRangeCard
    , productCard
    , searchCard config
    , signUpCard config

    -- column two
    , salesVolumeCard config
    , pageScoreCard
    , recentOrdersCard
    , revenueCard
    , composerCard
    , chatCard
    , adminPanelCard

    -- column three
    , playerCard
    , terminalBlock
    , alertsCard
    , timelineBlock
    , pricingCard
    ]


{-| Their first card: a `Preview` header with a `more` link, two removable tag
badges **above** the rows, then four checkbox rows each with a count badge.

Read off their DOM: the chips are `badge badge-soft` with a `size-3` cross
inside, and they sit in a row of their own directly under the title — not in
`card-actions` at the bottom, which is where this had them. That row is
`CardChild.CardRow`, added in this pass, because a `card-body` is a column and
two badges side by side need an element.

The rows are a `CardList` at `ListStyle.ListRules`: daisyUI's markup there
carries no `list` class at all — each row is `py-2` with a dashed hairline
under it — and `list-row`'s fixed `1rem` gutter is what made ours a third
taller than theirs.

The count badge is `badge-xs` and **solid** (`badge-neutral`, `badge-warning`),
as theirs is.

-}
filterPreviewCard : Block msg
filterPreviewCard =
    Card previewCard
        { emptyCard
            | title = Just "Preview"
            , titleIcon = Just Icon.Eye
            , headerActions = [ Link defaultLink "more" ]
            , body =
                [ CardRow Tree.RowWrap [ tagBadge "Shoes", tagBadge "Bags" ]
                , CardList { defaultList | style = Tree.ListRules }
                    [ checkRow "Hoodies" True (Just SBadge.Neutral) "25"
                    , checkRow "Bags" True (Just SBadge.Neutral) "3"
                    , checkRow "Shoes" False (Just SBadge.Warning) "0"
                    , checkRow "Accessories" False (Just SBadge.Neutral) "4"
                    ]
                ]
        }


defaultList : Tree.ListConfig
defaultList =
    Tree.defaultListConfig


checkRow : String -> Bool -> Maybe SBadge.Color -> String -> Tree.ListRow msg
checkRow label checked tone count =
    { cells =
        [ Tree.listCell
            (Checkbox
                { defaultCheckbox
                    | size = Just SCheckbox.Sm
                    , checked = checked
                    , ariaLabel = Just label
                }
            )
        , { content = Text label, grow = True, wrap = False }
        , Tree.listCell
            (Badge { defaultBadge | color = tone, size = Just SBadge.Xs } count)
        ]
    }


{-| A removable tag chip: `badge badge-soft` with the `x` after the word, which
is `BadgeConfig.trailingIcon` — a leading `icon` would put the cross in front
of the label, which is not the control daisyUI draws.
-}
tagBadge : String -> Leaf msg
tagBadge label =
    Badge
        { defaultBadge
            | style = Just SBadge.Soft
            , size = Just SBadge.Sm
            , trailingIcon = Just Icon.X
        }
        label


{-| Their second card: a week strip, an event search field, an all-day toggle
and one highlighted event.

Three things changed to theirs in this pass:

  - the strip is seven **two-line** cells — the day number over the weekday
    letter — with the current day filled `--color-primary`. That second line is
    `ButtonConfig.sublabel`: a `btn` is a flex row, so two text nodes come out
    side by side and there was no way to say it before.
  - the search field carries a leading magnifying glass (`InputConfig.icon`),
    and the toggle sits on one line with its own label
    (`LabelPlacement.LabelEnd`) rather than under a label above it.
  - the event is a `bg-base-300` block spanning the card, with a title, a
    two-line description and a `1h` neutral badge. daisyUI draws it edge to
    edge under a dashed rule; ours is the same row inside the body.

-}
weekCard : Config msg -> Block msg
weekCard config =
    Card previewCard
        { emptyCard
            | body =
                [ CardRow Tree.RowEven (List.map (dayButton config) weekDays)
                , CardForm
                    [ { legend = Nothing
                      , columns = Tree.OneColumn
                      , fields =
                            [ unlabelledField (searchInput "Search for events")
                            , inlineField "Show all day events"
                                (Toggle
                                    { defaultToggle | color = Just SToggle.Primary, size = Just SToggle.Sm }
                                    { checked = True }
                                )
                            ]
                      }
                    ]
                , CardList { defaultList | style = Tree.ListRules }
                    [ { cells =
                            [ { content = Text "Team Sync Meeting", grow = True, wrap = False }
                            , Tree.listCell
                                (Badge { defaultBadge | color = Just SBadge.Neutral, size = Just SBadge.Sm } "1h")
                            ]
                      }
                    ]
                ]
        }


{-| A control on the same line as its label, which is what daisyUI does with
every toggle in that preview.
-}
inlineField : String -> Leaf msg -> Field msg
inlineField label control =
    let
        base : Field msg
        base =
            Tree.field label control
    in
    { base | labelPlacement = LabelEnd }


{-| A field whose control names itself. daisyUI's event search is a field with
a magnifying glass and a placeholder and no label above it; the accessible name
comes from the input's own `aria-label`, so the visible label would be a second
copy of the same words.
-}
unlabelledField : Leaf msg -> Field msg
unlabelledField control =
    let
        base : Field msg
        base =
            Tree.field "" control
    in
    { base | label = Nothing }


searchInput : String -> Leaf msg
searchInput placeholder =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , icon = Just Icon.Search
            , placeholder = placeholder
            , ariaLabel = Just placeholder
        }


weekDays : List ( String, String, Bool )
weekDays =
    [ ( "12", "M", False )
    , ( "13", "T", False )
    , ( "14", "W", True )
    , ( "15", "T", False )
    , ( "16", "F", False )
    , ( "17", "S", False )
    , ( "18", "S", False )
    ]


dayButton : Config msg -> ( String, String, Bool ) -> Leaf msg
dayButton _ ( label, weekday, today ) =
    Button
        { defaultButton
            | size = Just SButton.Xs
            , sublabel = Just weekday
            , style =
                if today then
                    Nothing

                else
                    Just SButton.Ghost
            , color =
                if today then
                    Just Neutral

                else
                    Nothing
        }
        label


{-| Their tabs block, and the one thing on this page that is deliberately _not_
daisyUI's own class.

Theirs is `tabs tabs-lift`. `tabs-lift` puts a border on the **active** tab and
none on the others, so with `box-sizing: border-box` that tab's content box is
2px narrower than the identical inactive one beside it — measured here as
`scrollWidth 63px in a 59px box`, which `e2e/overflow.spec.ts` reads as content
escaping its box, correctly.

daisyUI never hits it because their tab carries no text: their generator writes
`<input type="radio" role="tab" class="tab" aria-label="Tab 2">`, a control
whose label is an attribute. `Daisy.Tree.Tab` is `{ label, content, ... }` — a
tab has a name and a panel — so its name is a text node, and a text node in a
2px-narrower box overflows. Expressing daisyUI's version would mean a tab that
cannot hold its own panel.

So it stays `tabs-box`, which puts the same border on every tab and reads as
the same segmented control. `docs/e2e-findings.md` records the measurement.

-}
tabsCard : Block msg
tabsCard =
    Card previewCard
        { emptyCard
            | headerTabs = Just { config = segmentedConfig, tabs = previewTabs }
            , body = [ CardLeaf (Text "Tab content 2") ]
        }


segmentedConfig : Tree.TabsConfig
segmentedConfig =
    { style = Just STab.Box, size = Just STab.Xs, placement = Nothing }


previewTabs : List (Tab msg)
previewTabs =
    [ { label = "Tab 1", active = False, disabled = False, content = [], onClick = Nothing }
    , { label = "Tab 2", active = True, disabled = False, content = [], onClick = Nothing }
    , { label = "Tab 3", active = False, disabled = False, content = [], onClick = Nothing }
    ]


priceRangeCard : Block msg
priceRangeCard =
    Card previewCard
        { emptyCard
            | title = Just "Price range"
            , titleIcon = Just Icon.CurrencyDollar
            , body =
                [ CardLeaf (Heading Tree.H1 "50")
                , CardLeaf
                    (Range
                        { defaultRange | ariaLabel = Just "Price range" }
                        { min = 0, max = 100, value = 50 }
                    )
                ]
        }


{-| Their product card: a picture, a name with a `SALE` badge, a rating, a
review count and the price.
-}
productCard : Block msg
productCard =
    Card previewCard
        { emptyCard
            | figure = Just (Image Tree.defaultImageConfig productImage)
            , title = Just "Nike Shoes"
            , headerActions =
                [ Badge { defaultBadge | color = Just SBadge.Accent, size = Just SBadge.Sm } "SALE" ]
            , body =
                [ CardRow Tree.RowWrap
                    [ Rating { defaultRating | size = Just SRating.Xs }
                        { name = "preview-rating", count = 5, value = 5, clearable = False }
                    , Text "420 reviews"
                    ]
                , CardRow Tree.RowWrap [ Heading Tree.H3 "$120" ]
                ]
        }


{-| A flat two-tone product picture as an inline `data:` URI, so it is painted
on the first frame with no network involved and the theme baselines stay
byte-stable — the same reason the other demos draw their avatars that way.
-}
productImage : String
productImage =
    -- 240x142, the 1.7:1 the product photo in daisyUI's own preview card has
    -- (259x153 measured at 1440). A 2:1 placeholder made the card 24px shorter
    -- than theirs on its own.
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20240%20142'%3E"
        ++ "%3Crect%20width='240'%20height='142'%20fill='%23c6f24e'/%3E"
        ++ "%3Cpath%20d='M20%20112c40-36%2080-48%20200-66v54z'%20fill='white'%20fill-opacity='0.75'/%3E%3C/svg%3E"


searchCard : Config msg -> Block msg
searchCard config =
    Card previewCard
        { emptyCard
            | body =
                [ CardLeaf
                    (Join Tree.defaultJoinConfig
                        [ JoinInput
                            { defaultInput
                                | size = Just SInput.Sm
                                , icon = Just Icon.Search
                                , inputType = InputSearch
                                , placeholder = "Search"
                                , ariaLabel = Just "Search the preview"
                            }
                        , JoinButton
                            { defaultButton | color = Just Neutral, size = Just SButton.Sm }
                            "Find"
                        ]
                    )
                ]
        }


{-| Their sign-up card: every control a theme reshapes, in one form.
-}
signUpCard : Config msg -> Block msg
signUpCard config =
    Card previewCard
        { emptyCard
            | title = Just "Create new account"
            , titleIcon = Just Icon.User
            , body =
                [ CardLeaf (Text "Registration is free and only takes a minute")
                , CardForm
                    [ { legend = Nothing
                      , columns = Tree.OneColumn
                      , fields =
                            [ Tree.field "Username" (iconInput Icon.User "Username")
                            , Tree.field "Password" (passwordInput config)
                            , Tree.field "Plan" (planSelect config)
                            , inlineField "Accept terms without reading"
                                (Toggle { defaultToggle | size = Just SToggle.Xs } { checked = False })
                            , inlineField "Subscribe to spam emails"
                                (Toggle { defaultToggle | size = Just SToggle.Xs } { checked = False })
                            ]
                      }
                    ]
                ]
            , actions =
                [ Button { defaultButton | color = Just Accent, size = Just SButton.Sm } "Register"
                , Link defaultLink "Or login"
                ]
        }


iconInput : Icon.Icon -> String -> Leaf msg
iconInput icon placeholder =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , icon = Just icon
            , placeholder = placeholder
            , ariaLabel = Just placeholder
        }


passwordInput : Config msg -> Leaf msg
passwordInput _ =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , icon = Just Icon.LockClosed
            , inputType = InputPassword
            , placeholder = "password"
            , ariaLabel = Just "Password"
        }


planSelect : Config msg -> Leaf msg
planSelect _ =
    Select { defaultSelect | size = Just SSelect.Sm }
        { options = [ "Starter", "Team", "Enterprise" ], selected = Just "Team" }


{-| Their sales card: a bar chart, a sentence about it, and two buttons.

The chart is also what proves a theme's semantic colours reach an SVG:
`Daisy.Render` writes them as `var(--color-primary)` and friends onto the
`fill`/`stroke` attribute, and `e2e/themes.spec.ts` reads the computed value
back off the same element in all thirty-six themes.

-}
salesVolumeCard : Config msg -> Block msg
salesVolumeCard config =
    Card previewCard
        { emptyCard
            | body =
                [ CardChart
                    (DChart.Bar { stacked = False, track = False, rounded = True })
                    DChart.ChartCompact
                    previewSeries
                    (Just { hovered = config.hoveredSales, onHover = config.onSalesHover })
                , CardLeaf (Text "Sales volume reached $12,450 this week, showing a 15% increase from the previous period.")
                ]
            , actions =
                [ Button { defaultButton | size = Just SButton.Sm } "Charts"
                , Button { defaultButton | color = Just Neutral, size = Just SButton.Sm } "Details"
                ]
        }


{-| daisyUI's sparkline, value for value: sixteen thin bars in
`--color-base-content`, rising left to right, with no axis and no legend.

`DChart.Neutral` and not `Primary`: theirs is `*:bg-base-content`, a strip of
ink rather than a coloured series, and `ChartSize.ChartCompact` is the `h-24`
that matches the `flex h-24 items-end` their markup uses.

-}
previewSeries : DChart.ChartData
previewSeries =
    { xLabels = List.map String.fromInt (List.range 1 16)
    , series =
        [ DChart.series "Volume"
            DChart.Neutral
            [ 10, 20, 10, 25, 22, 15, 20, 35, 40, 45, 30, 35, 60, 65, 80, 90 ]
        ]
    }


{-| Their score card: a dial and a `stat`.

daisyUI puts the `radial-progress` in the `stat-figure`, beside the number, and
so does this — but only since the dial gained a size. A 5rem dial plus its
`stat-figure` tile is a 96px grid column, and 96px of figure beside 168px of
text does not fit a 256px preview card: `.stats` is `overflow-x: auto`, so it
became a scrollable region and therefore a tab stop of its own
(`e2e/keyboard.spec.ts`), and the dial spent a pass sitting above the `stat`
instead. `RadialSize.RadialCompact` is what closed that: a 3rem
dial in its `stat-figure` tile is 64px beside 85px of `stat-value`, which fits
the 178px a `stat` has inside a 258px preview card, so the dial is back where
daisyUI puts it.

-}
pageScoreCard : Block msg
pageScoreCard =
    Card previewCard
        { emptyCard
            | body =
                [ CardStat
                    { direction = Tree.Fixed (Just SStat.Vertical)
                    , figureStyle = Tree.FigureBare
                    }
                    [ pageScoreStat ]
                ]
        }


{-| Their score card, now theirs in three more ways: the number is `91` with a
small `/100` after it (`StatItem.valueSuffix`), the caption carries a
success-coloured shield-check (`StatItem.descIcon`), and the dial sits in a
**bare** `stat-figure` (`StatFigureStyle.FigureBare`) instead of the renderer's
`bg-base-200` tile — a dial inside a grey square reads as two nested boxes, and
daisyUI draws it with nothing behind it.
-}
pageScoreStat : Tree.StatItem msg
pageScoreStat =
    let
        base : Tree.StatItem msg
        base =
            Tree.emptyStatItem "Page Score" "91"
    in
    { base
        | valueSuffix = Just "/100"
        , desc = Just "All good"
        , descIcon = Just ( Tree.ToneSuccess, Icon.ShieldCheck )
        , figure =
            Just
                (RadialProgress
                    { value = 91
                    , label = "91"
                    , size = RadialCompact
                    , ariaLabel = Just "Page score"
                    }
                )
    }


{-| Their orders card: one row per order, the name on the left and its state as
a **solid** `badge-xs` on the right, rows separated by a dashed hairline.

Their DOM: `<div class="border-t-base-content/5 flex items-center
justify-between gap-2 border-t border-dashed py-2">Charlie Chapman <span
class="badge badge-xs badge-info">Send</span></div>`. So this is a `CardList` at
`ListStyle.ListRules` — not the `table table-sm` it was, and not the `list`
before that.

The badges lost `badge-soft` in the same pass. A soft badge is `var(--color-X)`
over a `color-mix()` of the same colour with `--color-base-100`, which is a pair
the _composition_ derives; solid is the plain `--color-X` / `--color-X-content`
pair, which is the pair this page exists to show and which the contrast
classifier attributes to daisyUI rather than to us.

The title carries daisyUI's own trending-up glyph rather than a cart.

-}
recentOrdersCard : Block msg
recentOrdersCard =
    Card previewCard
        { emptyCard
            | title = Just "Recent orders"
            , titleIcon = Just Icon.ArrowTrendingUp
            , body =
                [ CardList { defaultList | style = Tree.ListRules } (List.map orderRow orders)
                ]
        }


orders : List ( String, ( SBadge.Color, String ) )
orders =
    [ ( "Charlie Chapman", ( SBadge.Info, "Send" ) )
    , ( "Howard Hudson", ( SBadge.Error, "Failed" ) )
    , ( "Fiona Fisher", ( SBadge.Warning, "In progress" ) )
    , ( "Nick Nelson", ( SBadge.Success, "Completed" ) )
    , ( "Amanda Anderson", ( SBadge.Success, "Completed" ) )
    ]


orderRow : ( String, ( SBadge.Color, String ) ) -> Tree.ListRow msg
orderRow ( name, ( tone, state ) ) =
    { cells =
        [ { content = Text name, grow = True, wrap = False }
        , Tree.listCell
            (Badge { defaultBadge | color = Just tone, size = Just SBadge.Xs } state)
        ]
    }


revenueCard : Block msg
revenueCard =
    Card previewCard
        { emptyCard
            | body =
                [ CardStat { direction = Tree.Fixed (Just SStat.Vertical), figureStyle = Tree.FigureTile }
                    [ revenueStat ]
                ]
        }


revenueStat : Tree.StatItem msg
revenueStat =
    let
        base : Tree.StatItem msg
        base =
            Tree.emptyStatItem "September Revenue" "$32,400"
    in
    { base
      -- daisyUI's line is "21% more than last month". `.stat-desc` is
      -- `white-space: nowrap` (their rule, not ours), and that sentence needs
      -- 192px inside a 184px tile — our preview card is 258px where theirs is
      -- 277px, the 19.2px the twelve-column split cannot close (see section 4
      -- of "The generator's editor column"). An overflowing `.stats` is
      -- `overflow-x: auto`, so it becomes a scrollable region and therefore a
      -- tab stop of its own, which `e2e/keyboard.spec.ts` catches. Same
      -- sentence, fewer words.
        | desc = Just "+21% vs. last month"
        , descIcon = Just ( Tree.ToneSuccess, Icon.ArrowTrendingUp )
    }


{-| Their composer: a `join` of formatting buttons, a textarea, a character
count and two actions.
-}
composerCard : Block msg
composerCard =
    Card previewCard
        { emptyCard
            | title = Just "Write a new post"
            , titleIcon = Just Icon.Pencil
            , body =
                [ CardLeaf
                    (Join Tree.defaultJoinConfig
                        [ formatButton "B", formatButton "I", formatButton "U" ]
                    )
                , CardLeaf
                    (Textarea
                        { defaultTextarea
                            | placeholder = "What's happening?"
                            , ariaLabel = Just "Post body"
                        }
                    )
                , CardLeaf (Text "1200 characters remaining")
                ]
            , actions =
                [ Button { defaultButton | style = Just SButton.Outline, size = Just SButton.Sm } "Draft"
                , Button { defaultButton | color = Just Accent, size = Just SButton.Sm } "Publish"
                ]
        }


formatButton : String -> JoinItem msg
formatButton label =
    JoinButton { defaultButton | size = Just SButton.Sm } label


chatCard : Block msg
chatCard =
    Card previewCard
        { emptyCard
            | title = Just "Messages"
            , body = [ CardChat previewMessages ]
        }


{-| Both bubbles are `chat-start`, not one of each.

daisyUI draws the bubble's tail with an absolutely positioned `::before`; on a
`chat-end` bubble it sits 12px past the bubble's right edge, which is 12px of
scrollable overflow that `e2e/overflow.spec.ts` reads as content escaping its
box. On a `chat-start` bubble the same tail is on the left, where a negative
offset contributes nothing to `scrollWidth`.

-}
previewMessages : List (Tree.ChatMessage msg)
previewMessages =
    [ { placement = SChat.Start
      , color = Nothing
      , image = Nothing
      , header = Just "Obi-Wan Kenobi · 12:45"
      , bubble = [ Text "It's over Anakin" ]
      , footer = Nothing
      }
    , { placement = SChat.Start
      , color = Just SChat.Primary
      , image = Nothing
      , header = Nothing
      , bubble = [ Text "I have the high ground" ]
      , footer = Just "Seen at 12:46"
      }
    ]


{-| Their `Admin panel` menu, as a `CardList` rather than a `Block.Menu`: the
rows are a glyph, a label and a count badge, and a `card-body` cannot hold a
`Block`.
-}
adminPanelCard : Block msg
adminPanelCard =
    Card previewCard
        { emptyCard
            | title = Just "Admin panel"
            , titleIcon = Just Icon.Cog
            , body =
                [ CardList defaultList
                    [ panelRow Icon.Document "Databases" (Just "7")
                    , panelRow Icon.ShoppingCart "Products" Nothing
                    , panelRow Icon.Bell "Messages" (Just "29")
                    , panelRow Icon.Check "Access tokens" Nothing
                    , panelRow Icon.Users "Users" Nothing
                    , panelRow Icon.Cog "Settings" Nothing
                    ]
                ]
        }


panelRow : Icon.Icon -> String -> Maybe String -> Tree.ListRow msg
panelRow icon label count =
    { cells =
        Tree.listCell (Icon { defaultIcon | size = Tree.IconSm } icon)
            :: { content = Text label, grow = True, wrap = False }
            :: (case count of
                    Just value ->
                        [ Tree.listCell
                            (Badge { defaultBadge | color = Just SBadge.Neutral, size = Just SBadge.Xs } value)
                        ]

                    Nothing ->
                        []
               )
    }


{-| Their media player, as their DOM has it: three square `btn-neutral`
transport keys with the middle one a size larger, the title and its subtitle
under them, then a progress bar with a `13:39` tooltip badge above the thumb and
the elapsed and total times under it, then four square icon buttons.

Every glyph is now the right one: `Backward`, `Play`, `Forward`, then
`SpeakerWave`, `ArrowsRightLeft` (shuffle), `ArrowPath` (repeat) and
`SpeakerWave` again for the headphone key — thirteen icons entered the closed
set in this pass and heroicons has no headphone outline.

-}
playerCard : Block msg
playerCard =
    Card previewCard
        { emptyCard
            | body =
                [ CardRow Tree.RowWrap
                    [ transportButton SButton.Sm Icon.Backward "Previous track"
                    , transportButton SButton.Lg Icon.Play "Play"
                    , transportButton SButton.Sm Icon.Forward "Next track"
                    ]
                , CardRow Tree.RowWrap [ Text "PM Zoomcall ASMR" ]
                , CardRow Tree.RowWrap [ Text "Project Manager talking for 2 hours" ]
                , CardLeaf
                    (Progress
                        { defaultProgress
                            | color = Just SProgress.Neutral
                            , tooltip = Just (Tree.tooltip "13:39")
                        }
                        { value = Just 11, max = 100 }
                    )
                , CardRow Tree.RowSpread [ Text "13:39", Text "120:00" ]
                , CardRow Tree.RowWrap (List.map transportLeaf playerControls)
                ]
        }



{- daisyUI draws the `13:39` bubble over the progress thumb with
   `tooltip tooltip-open`, inside a `relative mt-6` box that reserves the room
   for it. A daisyUI tooltip is absolutely positioned *outside* its anchor's
   box, so with no reserved room it lands on whatever is above — in a `gap-4`
   `card-body` that is the subtitle, which it covered outright. `Daisy.Tree`
   has no per-block margin and is not getting one, so the bubble is an ordinary
   `Tooltip`: the same text, on the same control, revealed by a pointer.
-}


playerControls : List ( Icon.Icon, String )
playerControls =
    [ ( Icon.SpeakerWave, "Volume" )
    , ( Icon.ArrowsRightLeft, "Shuffle" )
    , ( Icon.ArrowPath, "Repeat" )
    , ( Icon.ListBullet, "Queue" )
    ]


transportButton : SButton.Size -> Icon.Icon -> String -> Leaf msg
transportButton size icon label =
    Button
        { defaultButton
            | icon = Just icon
            , ariaLabel = Just label
            , color = Just Neutral
            , size = Just size
            , modifiers = [ SButton.Square ]
        }
        ""


transportLeaf : ( Icon.Icon, String ) -> Leaf msg
transportLeaf ( icon, label ) =
    Button
        { defaultButton
            | icon = Just icon
            , ariaLabel = Just ("Player control " ++ label)
            , size = Just SButton.Sm
            , modifiers = [ SButton.Square ]
        }
        ""


{-| Their terminal, and one of the two preview blocks that is not a card —
daisyUI puts a bare `mockup-code` in the grid, which a `Spans` cell holding a
list of blocks reproduces exactly.
-}
terminalBlock : Block msg
terminalBlock =
    MockupCode
        [ { prefix = Just "$", text = "npm i daisyui" }
        , { prefix = Just ">", text = "installing..." }
        , { prefix = Just ">", text = "Done!" }
        ]


{-| Their four alerts, in daisyUI's own four variants: `alert-info` solid,
`alert-outline alert-success`, `alert-dash alert-warning`, `alert-soft
alert-error`. Read straight off their DOM, and the point of the block is that a
theme's four state colours are shown in four different treatments at once.

This used to be four **solid** alerts, because the outline/dash/soft three
paint `var(--color-X)` as a foreground over a base surface — a pair neither
daisyUI's `contrast.test.js` nor our classifier attributed to daisyUI, so axe
and `e2e/contrast.spec.ts` failed them as ours. They are daisyUI's: the rule
that paints them is `.alert-outline { color: var(--color-X) }` and nothing the
tree, the renderer or this page chooses is involved. Both classifiers were
extended in this pass to say so, mechanically, from the class-name pattern
`*-outline` / `*-dash` / `*-soft` plus "foreground is exactly `--color-X` over a
base surface". `docs/e2e-findings.md` records it.

-}
alertsCard : Block msg
alertsCard =
    Card previewCard
        { emptyCard
            | body =
                [ CardAlert (alertConfig SAlert.Info Nothing) [ Text "There are 9 new messages" ]
                , CardAlert (alertConfig SAlert.Success (Just SAlert.Outline)) [ Text "Verification process completed" ]
                , CardAlert (alertConfig SAlert.Warning (Just SAlert.Dash)) [ Text "Click to verify your email" ]
                , CardAlert (alertConfig SAlert.Error (Just SAlert.Soft)) [ Text "Access denied" ]
                ]
        }


alertConfig : SAlert.Color -> Maybe SAlert.Style -> Tree.AlertConfig
alertConfig color style =
    { color = Just color, style = style, direction = Nothing }


{-| Their reading list, as the second block that is not a card.
-}
timelineBlock : Block msg
timelineBlock =
    Timeline
        { direction = Just STimeline.Vertical, modifiers = [ Tree.TimelineCompact ] }
        (List.map timelineItem
            [ ( "Sorcerer's Stack", True )
            , ( "Chamber of Servers", True )
            , ( "Prisoner of Azure", True )
            , ( "Goblet of Firebase", True )
            , ( "Elixir of Phoenix", False )
            , ( "Half-Deployed App", False )
            , ( "Deathly Frameworks", False )
            ]
        )


timelineItem : ( String, Bool ) -> Tree.TimelineItem msg
timelineItem ( label, done ) =
    { start = Nothing
    , startBox = False
    , middle =
        Just
            (Icon
                { defaultIcon
                    | tone =
                        if done then
                            Just Tree.TonePrimary

                        else
                            Nothing
                }
                (if done then
                    Icon.Check

                 else
                    Icon.ChevronRight
                )
            )
    , end = Just ("Harry Potter and the " ++ label)
    , endBox = True
    }


{-| Their pricing card: a `Monthly | Yearly` switch with a `SALE` badge, the
plan, the price, what is in it and what is not, and one button.
-}
pricingCard : Block msg
pricingCard =
    Card previewCard
        { emptyCard
            | title = Just "Starter Plan"
            , headerTabs = Just { config = segmentedConfig, tabs = billingTabs }
            , headerActions =
                [ Badge { defaultBadge | color = Just SBadge.Warning, size = Just SBadge.Xs } "SALE" ]
            , body =
                [ CardLeaf (Heading Tree.H2 "$200")
                , CardLeaf (Text "per month")
                , CardList { defaultList | style = Tree.ListRules }
                    [ planRow "20 Tokens per day" True
                    , planRow "10 Projects" True
                    , planRow "API Access" True
                    , planRow "Priority Support" False
                    ]
                ]
            , actions =
                [ Button { defaultButton | color = Just Accent, size = Just SButton.Sm } "Buy Now" ]
        }


billingTabs : List (Tab msg)
billingTabs =
    [ { label = "Monthly", active = False, disabled = False, content = [], onClick = Nothing }
    , { label = "Yearly", active = True, disabled = False, content = [], onClick = Nothing }
    ]


planRow : String -> Bool -> Tree.ListRow msg
planRow feature included =
    { cells =
        [ Tree.listCell
            (Icon
                { defaultIcon
                    | size = Tree.IconSm
                    , tone =
                        Just
                            (if included then
                                Tree.ToneSuccess

                             else
                                Tree.ToneError
                            )
                }
                (if included then
                    Icon.Check

                 else
                    Icon.X
                )
            )
        , { content = Text feature, grow = True, wrap = False }
        ]
    }



-- THE EXPORT BAND -------------------------------------------------------------


{-| The CSS itself, and the debug pane, as the page's last band.

`AlignStretch`, not the `Stack` default. daisyUI's `.mockup-code` is
`overflow-x: auto` and its `<pre>` is `width: max-content`, so a block sized to
its content is as wide as the longest declaration — about 500px, which is wider
than a 375 viewport and gave the _document_ a horizontal scrollbar
(`e2e/overflow.spec.ts`). Stretched to the column it is the container that
scrolls, which is what daisyUI built it to do.

-}
exportSection : Config msg -> Section msg
exportSection config =
    Stack { align = AlignStretch }
        [ Prose [ generatorLink config ]
        , MockupCode (cssLines config)
        , Prose [ Text ("last-msg: " ++ config.lastMsg) ]
        ]


cssLines : Config msg -> List Tree.CodeLine
cssLines config =
    exportCss config.edited
        |> String.lines
        |> List.map (\line -> { prefix = Nothing, text = line })
