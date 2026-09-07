module Demo.ThemeGenerator exposing
    ( Config, page
    , ThemeEdit, apply
    , exportCss, exportJson
    )

{-| The theme generator demo (route `/theme`).

A recreation of daisyUI's own theme generator
(<https://daisyui.com/theme-generator/>) in the same Dashboard shell the other
two dashboards use: an editor card on the left, a live preview beside it, and an
export card under both.

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
import Daisy.Schema.Input as SInput
import Daisy.Schema.Select as SSelect
import Daisy.Schema.Tab as STab
import Daisy.Schema.Table as STable
import Daisy.Themes as Themes
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , Border(..)
        , ButtonColor(..)
        , CardChild(..)
        , ColorScheme(..)
        , CustomTheme
        , DashboardShell
        , Field
        , Fieldset
        , InputType(..)
        , Leaf(..)
        , MenuItem(..)
        , MenuSpec
        , NavbarParts
        , Page(..)
        , Radius(..)
        , Row
        , Section(..)
        , Sections(..)
        , Shell(..)
        , Size(..)
        , SwatchColor(..)
        , Tab
        , Theme(..)
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
    , onNavigate : String -> msg
    , onEdit : ThemeEdit -> msg
    , onExport : msg
    }


{-| The whole theme generator as one `Page`.
-}
page : Config msg -> Page msg
page config =
    Page
        { header = Just headerBar
        , shell = Dashboard (dashboard config)
        , sections =
            Sections4
                (colorsSection config)
                (shapeSection config)
                (dataSection config)
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


dashboard : Config msg -> DashboardShell msg
dashboard config =
    { brand = Just { icon = Icon.ChartBar, name = "Acme" }
    , sidebar = sidebar config
    , sidebarFooter = Just sidebarUser
    , navbar = navbar config
    }


{-| The same sidebar the two dashboards carry, plus the `Tools` group this page
lives in. All three demos gained that group, so the shell is identical on every
route.
-}
sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = Tree.defaultMenuConfig
    , items =
        [ sectionTitle "Dashboards"
        , navItem "Overview" Icon.Home (href config "/") (config.onNavigate "/") False
        , navItem "Analytics" Icon.ChartBar (href config "/analytics") (config.onNavigate "/analytics") False
        , sectionTitle "Workspace"
        , navItem "Settings" Icon.Cog (href config "/settings") (config.onNavigate "/settings") False
        , sectionTitle "Tools"
        , navItem "Theme generator" Icon.Sun (href config "/theme") (config.onNavigate "/theme") True
        , docsItem config
        ]
    }


sectionTitle : String -> MenuItem msg
sectionTitle label =
    let
        (MenuItem base) =
            Tree.menuItem label
    in
    MenuItem { base | title = True }


docsItem : Config msg -> MenuItem msg
docsItem config =
    let
        (MenuItem base) =
            Tree.menuItem "Docs"
    in
    MenuItem { base | icon = Just Icon.Document, href = Just (href config "/docs/") }


navItem : String -> Icon.Icon -> String -> msg -> Bool -> MenuItem msg
navItem label icon path onClick active =
    let
        (MenuItem base) =
            Tree.menuItem label
    in
    MenuItem
        { base
            | icon = Just icon
            , active = active
            , href = Just path
            , onClick = Just onClick
        }


href : Config msg -> String -> String
href config path =
    BasePath.join config.basePath path


sidebarUser : Leaf msg
sidebarUser =
    UserChip
        { defaultUserChip | boxed = True }
        { avatar = avatarSrc, name = "Denish N", subtitle = "@withden" }


defaultUserChip : Tree.UserChipConfig msg
defaultUserChip =
    Tree.defaultUserChipConfig


{-| The same flat vector portrait the other demos use — an inline `data:` URI,
so it is painted on the first frame with no network involved and the theme
baselines stay byte-stable.
-}
avatarSrc : String
avatarSrc =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2040%2040'%3E"
        ++ "%3Crect%20width='40'%20height='40'%20fill='slateblue'/%3E"
        ++ "%3Ccircle%20cx='20'%20cy='16'%20r='7'%20fill='white'/%3E"
        ++ "%3Cpath%20d='M7%2040c0-7.2%205.8-12%2013-12s13%204.8%2013%2012z'%20fill='white'/%3E%3C/svg%3E"


navbar : Config msg -> NavbarParts msg
navbar config =
    { start = []
    , center = []
    , end = [ randomizeButton config, navbarUser ]
    }


navbarUser : Leaf msg
navbarUser =
    UserChip defaultUserChip { avatar = avatarSrc, name = "Denish N", subtitle = "Team" }


{-| "Randomize", the same control daisyUI's generator puts at the top of its
editor. It carries no seed: the router keeps the counter and hands it to
[`apply`](#apply), so the button is one constant value and the sequence is
reproducible.
-}
randomizeButton : Config msg -> Leaf msg
randomizeButton config =
    Button
        { defaultButton
            | icon = Just Icon.Plus
            , style = Just SButton.Outline
            , size = Just SButton.Sm
            , onClick = Just (config.onEdit Randomize)
        }
        "Randomize"


defaultButton : Tree.ButtonConfig msg
defaultButton =
    Tree.defaultButtonConfig


{-| The page's one primary button, placed by the shell at the end of the navbar.
-}
copyCta : Config msg -> Tree.Cta msg
copyCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Copy CSS" config.onExport
    in
    { base | icon = Just Icon.Document, size = Just SButton.Sm }


headerBar : Tree.PageHeader msg
headerBar =
    let
        base : Tree.PageHeader msg
        base =
            Tree.pageHeader "Theme generator"
    in
    { base
        | breadcrumbs =
            [ Link { defaultLink | href = "#" } "Acme"
            , Text "Tools"
            , Text "Theme"
            ]
    }


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig



-- SECTION 1: COLOURS + PALETTE --------------------------------------------


{-| The twenty colours on the left, what they look like on the right.
-}
colorsSection : Config msg -> Section msg
colorsSection config =
    Grid { columns = Tree.Cols2 }
        [ colorsCard config
        , paletteCard config
        ]


{-| The colour half of the editor: one `Select` to start from, then every
`--color-*` variable as a `type="color"` input.

`InputType.InputColor` is a real native picker, so the browser's own colour
dialog is what edits the theme. Its value is a `#rrggbb`, and `Daisy.Color` is
what turns that into the `oklch()` daisyUI wants and back again — a round trip
through OKLab on every keystroke of the picker.

-}
colorsCard : Config msg -> Block msg
colorsCard config =
    Card Tree.defaultCardConfig
        { emptyCard
            | title = Just "Colors"
            , titleIcon = Just Icon.Pencil
            , body =
                [ CardForm
                    [ { legend = Just "Theme"
                      , fields =
                            [ Tree.field "Start from" (startFromSelect config)
                            , Tree.field "Dark color scheme" (schemeToggle config)
                            ]
                      }
                    , colorFieldset config "Base" [ SlotBase100, SlotBase200, SlotBase300, SlotBaseContent ]
                    , colorFieldset config
                        "Brand"
                        [ SlotPrimary, SlotPrimaryContent, SlotSecondary, SlotSecondaryContent, SlotAccent, SlotAccentContent, SlotNeutral, SlotNeutralContent ]
                    , colorFieldset config
                        "State"
                        [ SlotInfo, SlotInfoContent, SlotSuccess, SlotSuccessContent, SlotWarning, SlotWarningContent, SlotError, SlotErrorContent ]
                    ]
                ]
        }


{-| The shape half of the editor: the three radii, the two base sizes, the
border width and the two effect switches — the nine measurements that are not
colours.
-}
shapeCard : Config msg -> Block msg
shapeCard config =
    Card Tree.defaultCardConfig
        { emptyCard
            | title = Just "Shape and effects"
            , titleIcon = Just Icon.Cog
            , body =
                [ CardForm
                    [ { legend = Just "Radius"
                      , fields =
                            [ radiusField config "Boxes" RadiusBox config.edited.radius.box
                            , radiusField config "Fields" RadiusField config.edited.radius.field
                            , radiusField config "Selectors" RadiusSelector config.edited.radius.selector
                            ]
                      }
                    , { legend = Just "Sizes and border"
                      , fields =
                            [ sizeField config "Field base size" SizeField config.edited.size.field
                            , sizeField config "Selector base size" SizeSelector config.edited.size.selector
                            , borderField config
                            ]
                      }
                    , { legend = Just "Effects"
                      , fields =
                            [ Tree.field "Depth effect" (effectToggle config SetDepth config.edited.depth)
                            , Tree.field "Noise effect" (effectToggle config SetNoise config.edited.noise)
                            ]
                      }
                    ]
                , -- `Responsive` is daisyUI's `stats-vertical
                  -- lg:stats-horizontal`. A `Fixed` horizontal pair is
                  -- `grid-flow-col overflow-x-auto`, so at 375 it becomes a
                  -- scrollable region no keyboard can reach — axe's
                  -- `scrollable-region-focusable`, serious. Same fix as
                  -- `Demo.Admin`'s two-tile card.
                  CardStat { direction = Tree.Responsive }
                    [ statItem "Color scheme" (schemeLabel config.edited) "the UI the browser paints itself"
                    , statItem "Box radius" (Tree.radiusToString config.edited.radius.box) "--radius-box"
                    ]
                ]
        }


emptyCard : Tree.CardParts msg
emptyCard =
    Tree.emptyCardParts


startFromSelect : Config msg -> Leaf msg
startFromSelect config =
    Select
        { defaultSelect
            | size = Just SSelect.Sm
            , onSelect = Just (config.onEdit << StartFrom)
        }
        { options = List.map Tree.themeToString DemoThemes.startingPoints
        , selected = Just (startingPoint config.edited)
        }


{-| Which option the "Start from" `Select` shows.

It is _derived_, not remembered. Every theme the editor holds is named `acme`
(see the module comment), so showing the name would make the control snap back
to `acme` the moment you picked `nord` — and holding the base in the model
would be a second source of truth for something the theme already says.

Instead: if the edited theme's declarations are still exactly one built-in's,
that built-in is what it started from and is what the control shows; the first
edit makes it stop matching and the control falls back to `acme`. `acme` itself
matches no built-in, which is why it is the fallback rather than a special case.

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


defaultSelect : Tree.SelectConfig msg
defaultSelect =
    Tree.defaultSelectConfig


colorFieldset : Config msg -> String -> List Slot -> Fieldset msg
colorFieldset config legend slots =
    { legend = Just legend
    , fields = List.map (colorField config) slots
    }


{-| One colour row: the variable's name as the label, a native colour picker as
the control, and the value it currently holds as `#rrggbb`.
-}
colorField : Config msg -> Slot -> Field msg
colorField config slot =
    Tree.field (slotLabel slot)
        (Input
            { defaultInput
                | inputType = InputColor
                , size = Just SInput.Sm
                , value = Color.oklchToHex (getSlot slot config.edited.colors)
                , onInput = Just (config.onEdit << SetColor slot)
            }
        )


defaultInput : Tree.InputConfig msg
defaultInput =
    Tree.defaultInputConfig


radiusField : Config msg -> String -> RadiusTarget -> Radius -> Field msg
radiusField config label target current =
    Tree.field label
        (Select
            { defaultSelect
                | size = Just SSelect.Sm
                , onSelect = Just (config.onEdit << SetRadius target)
            }
            { options = List.map Tree.radiusToString Tree.allRadii
            , selected = Just (Tree.radiusToString current)
            }
        )


sizeField : Config msg -> String -> SizeTarget -> Size -> Field msg
sizeField config label target current =
    Tree.field label
        (Select
            { defaultSelect
                | size = Just SSelect.Sm
                , onSelect = Just (config.onEdit << SetSize target)
            }
            { options = List.map Tree.sizeToString Tree.allSizes
            , selected = Just (Tree.sizeToString current)
            }
        )


borderField : Config msg -> Field msg
borderField config =
    Tree.field "Border width"
        (Select
            { defaultSelect
                | size = Just SSelect.Sm
                , onSelect = Just (config.onEdit << SetBorder)
            }
            { options = List.map Tree.borderToString Tree.allBorders
            , selected = Just (Tree.borderToString config.edited.border)
            }
        )


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


defaultToggle : Tree.ToggleConfig msg
defaultToggle =
    Tree.defaultToggleConfig


{-| The palette readout: every surface the theme names, painted with itself and
labelled with the content colour that is supposed to read on it, plus a row of
badges under them.

That is what `Leaf.Swatch` is for. daisyUI has no component whose job is "show
me this colour" — every colour class it ships belongs to a control — so the
renderer paints the chip from a named token pair per
[`SwatchColor`](Daisy-Tree#SwatchColor), and the caller only names the slot.

The badges sit in `card-actions`, which daisyUI lays out as `flex flex-wrap`:
a `card-body` is a column, so a leaf put in the body would stretch to the full
width of the card, and a row of pills is what a palette wants.

-}
paletteCard : Config msg -> Block msg
paletteCard _ =
    Card Tree.defaultCardConfig
        { emptyCard
            | title = Just "Palette"
            , titleIcon = Just Icon.Eye
            , body = List.map swatchRow swatches
            , actions = List.map colorBadge badgeColors
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



-- SECTION 2: LIVE PREVIEW ---------------------------------------------------


{-| The shape half of the editor, and the components it reshapes.
-}
shapeSection : Config msg -> Section msg
shapeSection config =
    Grid { columns = Tree.Cols2 }
        [ shapeCard config
        , componentsCard config
        ]


{-| The chart and the table beside the export card.
-}
dataSection : Config msg -> Section msg
dataSection config =
    Grid { columns = Tree.Cols2 }
        [ dataCard config
        , exportCard config
        ]


componentsCard : Config msg -> Block msg
componentsCard config =
    Card Tree.defaultCardConfig
        { emptyCard
            | title = Just "Components"
            , titleIcon = Just Icon.Check
            , headerTabs = Just { config = segmentedConfig, tabs = previewTabs }
            , actions = List.map colorButton Tree.allButtonColors
            , body =
                [ CardAlert (alertConfig SAlert.Info) [ Text "Info: this alert is painted by the theme." ]
                , CardAlert (alertConfig SAlert.Success) [ Text "Success: the pair reads at 4.5:1." ]
                , CardAlert (alertConfig SAlert.Warning) [ Text "Warning: check the content colour." ]
                , CardAlert (alertConfig SAlert.Error) [ Text "Error: something needs attention." ]
                , CardForm
                    [ { legend = Just "Controls"
                      , fields =
                            [ Tree.field "Workspace" (previewInput config)
                            , Tree.field "Notifications" (Toggle defaultToggle { checked = True })
                            , Tree.field "Include drafts" (Checkbox Tree.defaultCheckboxConfig)
                            , Tree.field "Weekly" (Radio Tree.defaultRadioConfig { name = "preview-cadence", checked = True })
                            , Tree.field "Opacity" (Range Tree.defaultRangeConfig { min = 0, max = 100, value = 60 })
                            ]
                      }
                    ]
                ]
        }


segmentedConfig : Tree.TabsConfig
segmentedConfig =
    { style = Just STab.Box, size = Just STab.Xs, placement = Nothing }


previewTabs : List (Tab msg)
previewTabs =
    [ { label = "Light", active = False, disabled = False, content = [] }
    , { label = "Dark", active = True, disabled = False, content = [] }
    ]


colorButton : ButtonColor -> Leaf msg
colorButton color =
    Button { defaultButton | color = Just color, size = Just SButton.Sm } (buttonLabel color)


buttonLabel : ButtonColor -> String
buttonLabel color =
    case color of
        Neutral ->
            "Neutral"

        Secondary ->
            "Secondary"

        Accent ->
            "Accent"

        Info ->
            "Info"

        Success ->
            "Success"

        Warning ->
            "Warning"

        Error ->
            "Error"


badgeColors : List ( SBadge.Color, String )
badgeColors =
    [ ( SBadge.Primary, "Primary" )
    , ( SBadge.Secondary, "Secondary" )
    , ( SBadge.Accent, "Accent" )
    , ( SBadge.Info, "Info" )
    , ( SBadge.Success, "Success" )
    , ( SBadge.Warning, "Warning" )
    , ( SBadge.Error, "Error" )
    ]


colorBadge : ( SBadge.Color, String ) -> Leaf msg
colorBadge ( color, label ) =
    Badge { defaultBadge | color = Just color, size = Just SBadge.Sm } label


defaultBadge : Tree.BadgeConfig
defaultBadge =
    Tree.defaultBadgeConfig


{-| A solid `alert-<color>`, not `alert-soft`.

daisyUI paints a soft alert as `var(--color-X)` text over a `color-mix()` of the
same colour with `--color-base-100` — a pair _it_ derives, which axe reports as a
contrast failure on a light ground and which `e2e/contrast.spec.ts` has to
classify specially. A solid alert is the plain `--color-X` / `--color-X-content`
pair instead, which is the pair this page exists to show.

-}
alertConfig : SAlert.Color -> Tree.AlertConfig
alertConfig color =
    { color = Just color, style = Nothing, direction = Nothing }


previewInput : Config msg -> Leaf msg
previewInput _ =
    Input { defaultInput | size = Just SInput.Sm, placeholder = "Acme Inc", value = "Acme Inc" }


{-| The second preview panel: a chart and a table, which is where a theme's
semantic colours have to hold up next to each other.

The chart's series colours are `var(--color-primary)` and friends written onto
the SVG, so they follow the inline custom properties exactly as a component
class does — which is what `e2e/themes.spec.ts` measures.

-}
dataCard : Config msg -> Block msg
dataCard _ =
    Card Tree.defaultCardConfig
        { emptyCard
            | title = Just "Data"
            , titleIcon = Just Icon.ChartBar
            , body =
                [ CardChart DChart.Line previewSeries
                , CardTable { size = Just STable.Sm, modifiers = [] } (tableHeader :: tableRows)
                ]
        }


schemeLabel : CustomTheme -> String
schemeLabel theme =
    case theme.colorScheme of
        LightScheme ->
            "Light"

        DarkScheme ->
            "Dark"


statItem : String -> String -> String -> Tree.StatItem msg
statItem title value desc =
    let
        base : Tree.StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    { base | desc = Just desc }


previewSeries : DChart.ChartData
previewSeries =
    { xLabels = [ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ]
    , series =
        [ { name = "Primary", color = DChart.Primary, points = [ 12, 19, 15, 27, 24, 31, 29 ] }
        , { name = "Accent", color = DChart.Accent, points = [ 8, 11, 14, 12, 18, 17, 22 ] }
        ]
    }


tableHeader : Row msg
tableHeader =
    { header = True
    , cells = List.map Tree.tableCell [ Text "Token", Text "Role", Text "State" ]
    }


tableRows : List (Row msg)
tableRows =
    [ tableRow "primary" "Calls to action" SBadge.Success "Pass"
    , tableRow "secondary" "Supporting" SBadge.Info "Check"
    , tableRow "error" "Destructive" SBadge.Error "Review"
    ]


tableRow : String -> String -> SBadge.Color -> String -> Row msg
tableRow token role tone state =
    { header = False
    , cells =
        [ Tree.tableCell (Text token)
        , Tree.tableCell (Text role)
        , Tree.tableCell
            (Badge
                { defaultBadge | color = Just tone, style = Just SBadge.Soft, size = Just SBadge.Sm }
                state
            )
        ]
    }



-- SECTION 3/4: EXPORT -----------------------------------------------------


{-| The export card: the two ways out of the page.

"Copy CSS" is the page's `Page.cta`, which the Dashboard shell places at the end
of the navbar; it sends `Daisy.Tree.customThemeToCss` down
`Ports.copyToClipboard`.

The link's `href` is whatever `Ports.themeEncoded` last sent: daisyUI's own
generator URL with this theme deflated into its `#theme=` hash, so the page
hands the theme back to the tool it came from. Until the first answer arrives
(the compression is a stream, so it cannot be synchronous) it is the bare
generator URL — a working link either way.

-}
exportCard : Config msg -> Block msg
exportCard config =
    Card Tree.defaultCardConfig
        { emptyCard
            | title = Just "Export"
            , titleIcon = Just Icon.Download
            , body =
                [ CardLeaf (Text "Paste the block below into a stylesheet next to `@plugin \"daisyui\"`, or open the theme in daisyUI's own generator.")
                ]
            , actions = [ generatorLink config ]
        }


{-| The link is a plain `link` — underlined, in the surrounding text colour —
not `link-primary`.

`link-primary` paints `--color-primary` as a _foreground_ over `--color-base-100`,
which is a pair the composition chooses rather than one daisyUI pairs, and it
falls under 4.5:1 in several themes (`dark`'s primary on `dark`'s base is
3.6:1). Since this page draws itself under whatever theme is being edited,
including deliberately bad ones, the one link on it has to be readable from the
theme's own text colour.

-}
generatorLink : Config msg -> Leaf msg
generatorLink config =
    Link { defaultLink | href = config.generatorUrl } "Open in daisyUI theme generator"


{-| The CSS itself, and the debug pane, as the page's last band.

A `MockupCode` is a `Block`, and `CardChild` has no constructor for one, so it
cannot live inside the export card — it is the block beside it. That is also the
better shape: thirty-four lines of CSS want the full content width, not half of
it.

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
