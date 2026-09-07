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
import Daisy.Schema.Input as SInput
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Progress as SProgress
import Daisy.Schema.Select as SSelect
import Daisy.Schema.Stat as SStat
import Daisy.Schema.Status as SStatus
import Daisy.Schema.Steps as SSteps
import Daisy.Schema.Tab as STab
import Daisy.Schema.Table as STable
import Daisy.Schema.Timeline as STimeline
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
    , lastMsg : String
    , generatorUrl : String
    , hoveredSales : Maybe Int
    , onSalesHover : Maybe Int -> msg
    , onNavigate : String -> msg
    , onEdit : ThemeEdit -> msg
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
            [ Tree.span Tree.Span2 (themesMenu config)
            , Tree.spanColumn Tree.Span3 (editorColumn config)
            , Tree.spanGrid Tree.Span7 Tree.CellThree (previewCards config)
            ]
        )



-- (a) THE THEME LIST ----------------------------------------------------------


{-| daisyUI's left rail: `My themes` above `daisyUI themes`, every name a row
with a palette glyph, the current one marked. A bare `Block.Menu`, not a card —
theirs is a list on the page ground too.

Clicking a row **is** the "start from" control — it fires the same `StartFrom`
edit the `<select>` used to, which is why that select is gone. `Block.Menu` is
the component daisyUI uses there too, and `MenuActiveStyle.TintedActive` is the
quiet marked row it draws.

The glyph is daisyUI's own four-colour tile: that theme's `base-100` with its
`base-content`, `primary`, `secondary` and `accent` on it. It is a
`MenuGlyph.MenuThemeDots`, which carries a whole `Theme` rather than an
[`Icon`](Daisy-Icon) — a row of the list _is_ a theme, and none of its four
colours can be a class, because the class would paint the theme being edited
instead of the theme the row is offering. `Daisy.Render` reads the values out of
the generated `Daisy.Themes` and writes them inline, exactly as it writes a
`Theme.Custom` onto the page root.

There is no "Hold to add theme" button. daisyUI's saves a theme into the
browser's local storage, which is a `Cmd` and a port; this page keeps `acme` at
the top of `My themes` and edits it in place.

-}
themesMenu : Config msg -> Block msg
themesMenu config =
    Menu
        { defaultMenu | size = Just SMenu.Xs }
        (groupTitle "Themes"
            :: groupTitle "My themes"
            :: themeRow config (Custom DemoThemes.acme)
            :: groupTitle "daisyUI themes"
            :: List.map (themeRow config) Tree.allThemes
        )


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
    [ nameCard config
    , changeColorsCard config
    , radiusCard config
    , sizeCard config
    , paletteCard config
    ]


{-| The top of daisyUI's editor: the theme's `Name`, then `Random` and `CSS`
side by side.
-}
nameCard : Config msg -> Block msg
nameCard config =
    Card previewCard
        { emptyCard
            | body =
                [ CardForm
                    [ { legend = Nothing
                      , columns = Tree.OneColumn
                      , fields = [ Tree.field "Name" (nameInput config) ]
                      }
                    ]
                , CardLeaf
                    (Join Tree.defaultJoinConfig
                        [ JoinButton
                            { defaultButton
                                | icon = Just Icon.Plus
                                , size = Just SButton.Sm
                                , onClick = Just (config.onEdit Randomize)
                            }
                            "Random"
                        , JoinButton
                            { defaultButton
                                | color = Just Neutral
                                , size = Just SButton.Sm
                                , onClick = Just config.onExport
                            }
                            "CSS"
                        ]
                    )
                ]
            , actions = [ generatorLink config ]
        }


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
changeColorsCard : Config msg -> Block msg
changeColorsCard config =
    Card previewCard
        { emptyCard
            | title = Just "Change Colors"
            , titleIcon = Just Icon.Swatch
            , body = [ CardLeaf (ColorChips (colorGroups config)) ]
        }


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


{-| daisyUI's `Radius` block: three rows of five tiles, labelled `Boxes`,
`Fields` and `Selectors`.

Each row is a `Leaf.RadiusTiles` — a real radio group whose five steps are drawn
as the corner each one sets, which is what daisyUI's own generator shows. The
tile is two sides of a box at that `border-radius`, so the control says what it
does without naming a length; the length is still the step's accessible name
(`Boxes 2rem`), prefixed by the group so `2rem` here and `2rem` in the next
group are two different controls.

`Daisy.Render` marks the current step `btn-neutral` and leaves the tile's border
at `currentColor`, so the marked corner comes out `--color-neutral-content` and
no colour is chosen by this page at all. `btn-neutral` and not `btn-active`:
`.btn-active` derives its background from the button's own colour with a
`color-mix()`, so the pair it paints is one the _composition_ chose — 4.28:1 in
`valentine`, which `e2e/contrast.spec.ts` refuses. `--color-neutral` over
`--color-neutral-content` is a pair daisyUI itself declares, in every theme.

-}
radiusCard : Config msg -> Block msg
radiusCard config =
    Card previewCard
        { emptyCard
            | title = Just "Radius"
            , body =
                [ CardLeaf (groupLabel "Boxes")
                , CardLeaf (radiusChoice config "Boxes" RadiusBox config.edited.radius.box)
                , CardLeaf (groupLabel "Fields")
                , CardLeaf (radiusChoice config "Fields" RadiusField config.edited.radius.field)
                , CardLeaf (groupLabel "Selectors")
                , CardLeaf (radiusChoice config "Selectors" RadiusSelector config.edited.radius.selector)
                ]
        }


{-| daisyUI's `Sizes`, `Border` and `Effects` blocks, in one panel.
-}
sizeCard : Config msg -> Block msg
sizeCard config =
    Card previewCard
        { emptyCard
            | title = Just "Sizes and effects"
            , body =
                [ CardLeaf (groupLabel "Field base size (rem)")
                , CardLeaf (sizeChoice config "Field base size" SizeField config.edited.size.field)
                , CardLeaf (groupLabel "Selector base size (rem)")
                , CardLeaf (sizeChoice config "Selector base size" SizeSelector config.edited.size.selector)
                , CardLeaf (groupLabel "Border width (px)")
                , CardLeaf (borderChoice config)
                , CardForm
                    [ { legend = Just "Effects"
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


radiusChoice : Config msg -> String -> RadiusTarget -> Radius -> Leaf msg
radiusChoice config group target current =
    RadiusTiles
        { ariaLabel = Just (group ++ " radius")
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
paletteCard : Config msg -> Block msg
paletteCard config =
    Card previewCard
        { emptyCard
            | title = Just "Palette"
            , titleIcon = Just Icon.Eye

            -- Beside the title, not above the swatches. A `Leaf.ThemeDots` is
            -- an 18px tile, and a `card-body` is a stretch column: as a body
            -- child it became a full-width white strip with four dots stranded
            -- at its left edge. `headerActions` is a shrink-to-fit row, which
            -- is the shape the tile was drawn for (it is what a theme-list row
            -- carries).
            , headerActions = [ ThemeDots (Custom config.edited) ]
            , body = List.map swatchRow swatches
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
badges, then four checkbox rows each with a count badge.

The rows are a `CardList`: a `list-row` holds a checkbox, a growing label and a
badge, which is exactly the shape `ListCell` was built for — and the reason
`CardChild` gained `CardList` in this pass, since a `card-body` is a column that
cannot hold a `Block`.

-}
filterPreviewCard : Block msg
filterPreviewCard =
    Card previewCard
        { emptyCard
            | title = Just "Preview"
            , titleIcon = Just Icon.Eye
            , headerActions = [ Link defaultLink "more" ]
            , body =
                [ CardList
                    [ checkRow "Hoodies" True (Just SBadge.Neutral) "25"
                    , checkRow "Bags" True (Just SBadge.Neutral) "3"
                    , checkRow "Shoes" False (Just SBadge.Warning) "0"
                    , checkRow "Accessories" False (Just SBadge.Neutral) "4"
                    ]
                ]
            , actions =
                [ tagBadge "Shoes", tagBadge "Bags" ]
        }


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


tagBadge : String -> Leaf msg
tagBadge label =
    Badge { defaultBadge | style = Just SBadge.Soft, size = Just SBadge.Sm } label


{-| Their second card: a week strip, an event search field, an all-day toggle
and one highlighted event.

The strip is a `join` of seven `btn-sm` buttons with the current day
`btn-neutral` — daisyUI's is a row of date cells with the weekday letter under
the number, which needs two lines inside one cell and so is one line here.

-}
weekCard : Config msg -> Block msg
weekCard config =
    Card previewCard
        { emptyCard
            | body =
                [ CardLeaf
                    (Join Tree.defaultJoinConfig
                        (List.map (dayButton config) weekDays)
                    )
                , CardForm
                    [ { legend = Nothing
                      , columns = Tree.OneColumn
                      , fields =
                            [ Tree.field "Search for events" (previewInput "Search for events")
                            , Tree.field "Show all day events" (Toggle defaultToggle { checked = True })
                            ]
                      }
                    ]
                , CardList
                    [ { cells =
                            [ Tree.listCell (Icon { defaultIcon | size = Tree.IconSm } Icon.Calendar)
                            , { content = Text "Team Sync Meeting", grow = True, wrap = False }
                            , Tree.listCell
                                (Badge { defaultBadge | color = Just SBadge.Neutral, size = Just SBadge.Sm } "1h")
                            ]
                      }
                    ]
                ]
        }


weekDays : List ( String, Bool )
weekDays =
    [ ( "12", False )
    , ( "13", False )
    , ( "14", True )
    , ( "15", False )
    , ( "16", False )
    , ( "17", False )
    , ( "18", False )
    ]


dayButton : Config msg -> ( String, Bool ) -> JoinItem msg
dayButton _ ( label, today ) =
    JoinButton
        { defaultButton
            | size = Just SButton.Xs
            , color =
                if today then
                    Just Neutral

                else
                    Nothing
        }
        label


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
                [ CardLeaf
                    (Rating Tree.defaultRatingConfig
                        { name = "preview-rating", count = 5, value = 5, clearable = False }
                    )
                , CardLeaf (Heading Tree.H3 "$120")
                ]
            , actions =
                [ Badge { defaultBadge | style = Just SBadge.Soft, size = Just SBadge.Sm } "420 reviews"
                , Button { defaultButton | size = Just SButton.Sm } "Add to cart"
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
                            [ Tree.field "Username" (previewInput "Username")
                            , Tree.field "Password" (passwordInput config)
                            , Tree.field "Plan" (planSelect config)
                            , Tree.field "Notes" (Textarea Tree.defaultTextareaConfig)
                            , Tree.field "Avatar" (FileInput Tree.defaultFileInputConfig)
                            , Tree.field "Accept terms without reading" (Toggle defaultToggle { checked = False })
                            , Tree.field "Subscribe to spam emails" (Toggle defaultToggle { checked = False })
                            , Tree.field "Weekly" (Radio Tree.defaultRadioConfig { name = "preview-cadence", checked = True })
                            , Tree.field "Include drafts" (Checkbox Tree.defaultCheckboxConfig)
                            ]
                      }
                    ]
                ]
            , actions =
                [ Button { defaultButton | color = Just Accent, size = Just SButton.Sm } "Register"
                , Link defaultLink "Or login"
                ]
        }


previewInput : String -> Leaf msg
previewInput placeholder =
    Input { defaultInput | size = Just SInput.Sm, placeholder = placeholder }


passwordInput : Config msg -> Leaf msg
passwordInput _ =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , inputType = InputPassword
            , placeholder = "password"
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
                [ Button { defaultButton | style = Just SButton.Outline, size = Just SButton.Sm } "Charts"
                , Button { defaultButton | color = Just Neutral, size = Just SButton.Sm } "Details"
                ]
        }


previewSeries : DChart.ChartData
previewSeries =
    { xLabels = [ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ]
    , series =
        [ DChart.series "Volume" DChart.Primary [ 12, 19, 15, 27, 24, 31, 29 ] ]
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
                [ CardStat { direction = Tree.Fixed (Just SStat.Vertical) }
                    [ pageScoreStat ]
                ]
        }


pageScoreStat : Tree.StatItem msg
pageScoreStat =
    let
        base : Tree.StatItem msg
        base =
            Tree.emptyStatItem "Page Score" "91/100"
    in
    { base
        | desc = Just "All good"
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
a soft `badge-xs` on the right.

A `table table-sm`, not the `CardList` this was. daisyUI's own rows are 8px of
padding and 12px text under a hairline, and `list-row`'s padding is a fixed
`1rem` with a `1rem` gap that no size class changes — so a `list` here was 16px
of padding and 16px text in a 258px card, which is what wrapped every name onto
two lines. `table-sm` **is** daisyUI's compact row (`padding-block: .5rem`,
`font-size: .75rem`, a `base-content/5` rule between rows), so this is their
density expressed as their class rather than as a padding override of ours.

The name cell is `truncate`, so a longer name than these five ends in an
ellipsis instead of wrapping.

-}
recentOrdersCard : Block msg
recentOrdersCard =
    Card previewCard
        { emptyCard
            | title = Just "Recent orders"
            , titleIcon = Just Icon.ShoppingCart
            , body =
                [ CardTable
                    { defaultTable | size = Just STable.Sm }
                    (List.map orderRow orders)
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


orderRow : ( String, ( SBadge.Color, String ) ) -> Tree.Row msg
orderRow ( name, ( tone, state ) ) =
    { header = False
    , cells =
        [ { leading = Nothing, content = Text name, truncate = True }
        , Tree.tableCell
            (Badge { defaultBadge | color = Just tone, style = Just SBadge.Soft, size = Just SBadge.Xs } state)
        ]
    }


revenueCard : Block msg
revenueCard =
    Card previewCard
        { emptyCard
            | body =
                [ CardStat { direction = Tree.Fixed (Just SStat.Vertical) }
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
        | desc = Just "vs. last month"
        , trend =
            Just
                (Badge
                    { defaultBadge
                        | icon = Just Icon.ArrowTrendingUp
                        , color = Just SBadge.Success
                        , style = Just SBadge.Soft
                        , size = Just SBadge.Sm
                    }
                    "21%"
                )
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
                [ CardList
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


{-| Their media player: transport buttons, a title and subtitle, a progress bar
with its elapsed and total times, and a row of square controls.
-}
playerCard : Block msg
playerCard =
    Card previewCard
        { emptyCard
            | title = Just "PM Zoomcall ASMR"
            , body =
                [ CardLeaf (Text "Project Manager talking for 2 hours")
                , CardLeaf
                    (Join Tree.defaultJoinConfig
                        [ transportButton Icon.ChevronRight
                        , transportButton Icon.Check
                        , transportButton Icon.ChevronRight
                        ]
                    )
                , CardLeaf
                    (Progress
                        { defaultProgress | color = Just SProgress.Neutral }
                        { value = Just 11, max = 100 }
                    )
                , CardLeaf (Text "13:39 / 120:00")
                ]
            , actions = List.map transportLeaf [ Icon.Bell, Icon.Search, Icon.Sun, Icon.User ]
        }


transportButton : Icon.Icon -> JoinItem msg
transportButton icon =
    JoinButton
        { defaultButton
            | icon = Just icon
            , ariaLabel = Just "Transport control"
            , color = Just Neutral
            , size = Just SButton.Sm
            , modifiers = [ SButton.Square ]
        }
        ""


transportLeaf : Icon.Icon -> Leaf msg
transportLeaf icon =
    Button
        { defaultButton
            | icon = Just icon
            , ariaLabel = Just ("Player control " ++ Icon.name icon)
            , style = Just SButton.Outline
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


{-| Their four alerts.

Solid `alert-<color>`, not daisyUI's own outline/dash/soft mix: a soft alert is
`var(--color-X)` text over a `color-mix()` of the same colour with
`--color-base-100` — a pair _it_ derives, which axe reports as a contrast
failure on a light ground. A solid alert is the plain `--color-X` /
`--color-X-content` pair, which is the pair this page exists to show.

-}
alertsCard : Block msg
alertsCard =
    Card previewCard
        { emptyCard
            | body =
                [ CardAlert (alertConfig SAlert.Info) [ Text "There are 9 new messages" ]
                , CardAlert (alertConfig SAlert.Success) [ Text "Verification process completed" ]
                , CardAlert (alertConfig SAlert.Warning) [ Text "Click to verify your email" ]
                , CardAlert (alertConfig SAlert.Error) [ Text "Access denied" ]
                ]
        }


alertConfig : SAlert.Color -> Tree.AlertConfig
alertConfig color =
    { color = Just color, style = Nothing, direction = Nothing }


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
            (Icon Tree.defaultIconConfig
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
                , CardList
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
            (Icon { defaultIcon | size = Tree.IconSm }
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
        [ MockupCode (cssLines config)
        , Prose [ Text ("last-msg: " ++ config.lastMsg) ]
        ]


cssLines : Config msg -> List Tree.CodeLine
cssLines config =
    exportCss config.edited
        |> String.lines
        |> List.map (\line -> { prefix = Nothing, text = line })
