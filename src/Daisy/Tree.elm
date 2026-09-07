module Daisy.Tree exposing
    ( Page(..), Sections(..), Shell(..), DashboardShell, dashboardShell, Brand, Cta, cta
    , CtaPlacement(..), allCtaPlacements
    , PageHeader, pageHeader
    , Theme(..), allThemes, themeToString
    , CustomTheme, ColorScheme(..), allColorSchemes, colorSchemeToString
    , ThemeColors, Oklch
    , Radius(..), allRadii, radiusToString
    , Size(..), allSizes, sizeToString
    , Border(..), allBorders, borderToString
    , ThemeName, themeName, themeNameOf, themeNameToString
    , customThemeProperties, customThemeStyle, customThemeToCss, customThemeToJson
    , Section(..)
    , HeroConfig, defaultHeroConfig
    , NavbarParts, emptyNavbarParts
    , FooterConfig, defaultFooterConfig
    , GridSection(..), GridConfig, defaultGridConfig, GridColumns(..)
    , GridItem, Span(..), allSpans, CellColumns(..), allCellColumns, span, spanColumn, spanGrid
    , StackConfig, defaultStackConfig, Align(..)
    , Block(..)
    , AccordionConfig, defaultAccordionConfig, AccordionItem
    , AlertConfig, defaultAlertConfig
    , CardConfig, defaultCardConfig, CardPadding(..), allCardPaddings, CardParts, emptyCardParts, CardChild(..)
    , CarouselConfig, defaultCarouselConfig, CarouselItem, CarouselSnap(..)
    , ChatMessage
    , CollapseConfig, defaultCollapseConfig, CollapseParts
    , DiffParts
    , Fieldset, Field, LabelPlacement(..), field
    , ListRow, ListCell, listCell
    , MenuConfig, defaultMenuConfig, MenuActiveStyle(..), allMenuActiveStyles, MenuItem(..), MenuBadge, MenuSpec, menuItem
    , MockupBrowserParts, MockupPhoneParts, MockupWindowParts, CodeLine
    , NavConfig, defaultNavConfig
    , PaginationConfig, defaultPaginationConfig, PaginationData
    , StackedConfig, defaultStackedConfig, StackedAlign(..)
    , StatConfig, defaultStatConfig, StatDirection(..), StatItem, emptyStatItem
    , StepsConfig, defaultStepsConfig, Step
    , TableConfig, defaultTableConfig, Row, TableCell, tableCell
    , TabsConfig, defaultTabsConfig, Tab, TabsSpec
    , TimelineConfig, defaultTimelineConfig, TimelineModifier(..), allTimelineModifiers, timelineModifierToSchema, TimelineItem
    , Leaf(..), ImageSrc, HeadingLevel(..)
    , AvatarConfig, defaultAvatarConfig, AvatarItem
    , BadgeConfig, defaultBadgeConfig
    , ButtonConfig, defaultButtonConfig, ButtonColor(..), allButtonColors, buttonColorToSchema
    , CalendarConfig, defaultCalendarConfig, CalendarLocale(..), CalendarMonths(..), CalendarState(..), CalendarValue(..), CalendarMsg(..), setCalendarValue
    , CheckboxConfig, defaultCheckboxConfig
    , DividerConfig, defaultDividerConfig
    , FileInputConfig, defaultFileInputConfig
    , FilterData, FilterReset(..)
    , IconConfig, defaultIconConfig, IconSize(..)
    , ImageConfig, defaultImageConfig
    , InputConfig, defaultInputConfig, InputType(..)
    , JoinConfig, defaultJoinConfig, JoinItem(..)
    , KbdConfig, defaultKbdConfig
    , LinkConfig, defaultLinkConfig
    , LoadingConfig, defaultLoadingConfig
    , MegamenuConfig, defaultMegamenuConfig, MegamenuItem
    , OtpConfig, defaultOtpConfig, OtpData
    , ProgressConfig, defaultProgressConfig, ProgressData
    , RadialProgressData
    , RadioConfig, defaultRadioConfig, RadioData
    , RangeConfig, defaultRangeConfig, RangeData
    , RatingConfig, defaultRatingConfig, RatingModifier(..), allRatingModifiers, ratingModifierToSchema, RatingData
    , SelectConfig, defaultSelectConfig, SelectData
    , SkeletonConfig, defaultSkeletonConfig
    , StatusConfig, defaultStatusConfig
    , SwatchConfig, defaultSwatchConfig, SwatchColor(..), allSwatchColors
    , SwapConfig, defaultSwapConfig, SwapFaces
    , TextareaConfig, defaultTextareaConfig
    , ThemeSelectData, ThemePresentation(..)
    , ToggleConfig, defaultToggleConfig, ToggleData
    , UserChipConfig, defaultUserChipConfig, UserChipData
    , Tooltip, TooltipConfig, defaultTooltipConfig, tooltip
    , Dropdown, DropdownConfig, defaultDropdownConfig
    , Indicator, IndicatorConfig, defaultIndicatorConfig, IndicatorPayload(..)
    , MaskConfig, defaultMaskConfig
    , AuraConfig, defaultAuraConfig
    , Overlay(..)
    , ModalConfig, defaultModalConfig
    , DrawerConfig, defaultDrawerConfig
    , ToastConfig, defaultToastConfig
    , Dock, DockConfig, defaultDockConfig, DockItem
    , Fab, FabConfig, defaultFabConfig
    )

{-| The closed view tree.

A page is composed of exactly four nested levels — `Page` > `Section` > `Block`

> `Leaf` — plus `Overlay`, which lives only in `Page.overlays`. No constructor
> accepts a child of its own level or above, so "a card inside a card", "a section
> inside a block", "six sections" and "two primary buttons" are all
> unrepresentable rather than merely discouraged.

Every `XConfig` is a record of `Maybe <Group>` values taken straight from
`Daisy.Schema.<Component>` plus, where the component declares one,
`modifiers : List <Component>.Modifier`. There is no `String` class field
anywhere and no `Raw Html` escape hatch, so `Daisy.Render` is the only module
that can emit a class.

    import Daisy.Tree exposing (..)

    savePage : Page Msg
    savePage =
        Page
            { shell = Plain
            , sections = Sections1 (Stack defaultStackConfig [ Prose [ Text "Hello" ] ])
            , cta = cta "Save" Save
            , overlays = []
            , theme = Light
            , dock = Nothing
            , fab = Nothing
            }


# Page

@docs Page, Sections, Shell, DashboardShell, dashboardShell, Brand, Cta, cta
@docs CtaPlacement, allCtaPlacements
@docs PageHeader, pageHeader


# Theme

@docs Theme, allThemes, themeToString


# Custom themes

A `Theme` is either one of the thirty-five daisyUI ships or a `Custom` one of
the application's own, built from exactly the declarations daisyUI's own theme
format has.

@docs CustomTheme, ColorScheme, allColorSchemes, colorSchemeToString
@docs ThemeColors, Oklch
@docs Radius, allRadii, radiusToString
@docs Size, allSizes, sizeToString
@docs Border, allBorders, borderToString
@docs ThemeName, themeName, themeNameOf, themeNameToString
@docs customThemeProperties, customThemeStyle, customThemeToCss, customThemeToJson


# Sections

@docs Section
@docs HeroConfig, defaultHeroConfig
@docs NavbarParts, emptyNavbarParts
@docs FooterConfig, defaultFooterConfig
@docs GridSection, GridConfig, defaultGridConfig, GridColumns
@docs GridItem, Span, allSpans, CellColumns, allCellColumns, span, spanColumn, spanGrid
@docs StackConfig, defaultStackConfig, Align


# Blocks

@docs Block
@docs AccordionConfig, defaultAccordionConfig, AccordionItem
@docs AlertConfig, defaultAlertConfig
@docs CardConfig, defaultCardConfig, CardPadding, allCardPaddings, CardParts, emptyCardParts, CardChild
@docs CarouselConfig, defaultCarouselConfig, CarouselItem, CarouselSnap
@docs ChatMessage
@docs CollapseConfig, defaultCollapseConfig, CollapseParts
@docs DiffParts
@docs Fieldset, Field, LabelPlacement, field
@docs ListRow, ListCell, listCell
@docs MenuConfig, defaultMenuConfig, MenuActiveStyle, allMenuActiveStyles, MenuItem, MenuBadge, MenuSpec, menuItem
@docs MockupBrowserParts, MockupPhoneParts, MockupWindowParts, CodeLine
@docs NavConfig, defaultNavConfig
@docs PaginationConfig, defaultPaginationConfig, PaginationData
@docs StackedConfig, defaultStackedConfig, StackedAlign
@docs StatConfig, defaultStatConfig, StatDirection, StatItem, emptyStatItem
@docs StepsConfig, defaultStepsConfig, Step
@docs TableConfig, defaultTableConfig, Row, TableCell, tableCell
@docs TabsConfig, defaultTabsConfig, Tab, TabsSpec
@docs TimelineConfig, defaultTimelineConfig, TimelineModifier, allTimelineModifiers, timelineModifierToSchema, TimelineItem


# Leaves

@docs Leaf, ImageSrc, HeadingLevel
@docs AvatarConfig, defaultAvatarConfig, AvatarItem
@docs BadgeConfig, defaultBadgeConfig
@docs ButtonConfig, defaultButtonConfig, ButtonColor, allButtonColors, buttonColorToSchema
@docs CalendarConfig, defaultCalendarConfig, CalendarLocale, CalendarMonths, CalendarState, CalendarValue, CalendarMsg, setCalendarValue
@docs CheckboxConfig, defaultCheckboxConfig
@docs DividerConfig, defaultDividerConfig
@docs FileInputConfig, defaultFileInputConfig
@docs FilterData, FilterReset
@docs IconConfig, defaultIconConfig, IconSize
@docs ImageConfig, defaultImageConfig
@docs InputConfig, defaultInputConfig, InputType
@docs JoinConfig, defaultJoinConfig, JoinItem
@docs KbdConfig, defaultKbdConfig
@docs LinkConfig, defaultLinkConfig
@docs LoadingConfig, defaultLoadingConfig
@docs MegamenuConfig, defaultMegamenuConfig, MegamenuItem
@docs OtpConfig, defaultOtpConfig, OtpData
@docs ProgressConfig, defaultProgressConfig, ProgressData
@docs RadialProgressData
@docs RadioConfig, defaultRadioConfig, RadioData
@docs RangeConfig, defaultRangeConfig, RangeData
@docs RatingConfig, defaultRatingConfig, RatingModifier, allRatingModifiers, ratingModifierToSchema, RatingData
@docs SelectConfig, defaultSelectConfig, SelectData
@docs SkeletonConfig, defaultSkeletonConfig
@docs StatusConfig, defaultStatusConfig
@docs SwatchConfig, defaultSwatchConfig, SwatchColor, allSwatchColors
@docs SwapConfig, defaultSwapConfig, SwapFaces
@docs TextareaConfig, defaultTextareaConfig
@docs ThemeSelectData, ThemePresentation
@docs ToggleConfig, defaultToggleConfig, ToggleData
@docs UserChipConfig, defaultUserChipConfig, UserChipData


# Leaf properties

These are never nodes. They are fields on a leaf's config, so the renderer
always owns the wrapper element and the anchor can never go missing.

@docs Tooltip, TooltipConfig, defaultTooltipConfig, tooltip
@docs Dropdown, DropdownConfig, defaultDropdownConfig
@docs Indicator, IndicatorConfig, defaultIndicatorConfig, IndicatorPayload
@docs MaskConfig, defaultMaskConfig
@docs AuraConfig, defaultAuraConfig


# Overlays

@docs Overlay
@docs ModalConfig, defaultModalConfig
@docs DrawerConfig, defaultDrawerConfig
@docs ToastConfig, defaultToastConfig


# Fixed page chrome

@docs Dock, DockConfig, defaultDockConfig, DockItem
@docs Fab, FabConfig, defaultFabConfig

-}

import Cally.Date as CallyDate
import Cally.Multi as CallyMulti
import Cally.Range as CallyRange
import Daisy.Chart exposing (ChartConfig, ChartData, ChartInteraction)
import Daisy.Color as Color
import Daisy.Icon exposing (Icon)
import Daisy.Schema.Accordion as SAccordion
import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Aura as SAura
import Daisy.Schema.Avatar as SAvatar
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Card as SCard
import Daisy.Schema.Carousel as SCarousel
import Daisy.Schema.Chat as SChat
import Daisy.Schema.Checkbox as SCheckbox
import Daisy.Schema.Collapse as SCollapse
import Daisy.Schema.Divider as SDivider
import Daisy.Schema.Dock as SDock
import Daisy.Schema.Drawer as SDrawer
import Daisy.Schema.Dropdown as SDropdown
import Daisy.Schema.Fab as SFab
import Daisy.Schema.FileInput as SFileInput
import Daisy.Schema.Footer as SFooter
import Daisy.Schema.Indicator as SIndicator
import Daisy.Schema.Input as SInput
import Daisy.Schema.Join as SJoin
import Daisy.Schema.Kbd as SKbd
import Daisy.Schema.Link as SLink
import Daisy.Schema.Loading as SLoading
import Daisy.Schema.Mask as SMask
import Daisy.Schema.Megamenu as SMegamenu
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Modal as SModal
import Daisy.Schema.Otp as SOtp
import Daisy.Schema.Pagination as SPagination
import Daisy.Schema.Progress as SProgress
import Daisy.Schema.Radio as SRadio
import Daisy.Schema.Range as SRange
import Daisy.Schema.Rating as SRating
import Daisy.Schema.Select as SSelect
import Daisy.Schema.Skeleton as SSkeleton
import Daisy.Schema.Stack as SStack
import Daisy.Schema.Stat as SStat
import Daisy.Schema.Status as SStatus
import Daisy.Schema.Steps as SSteps
import Daisy.Schema.Swap as SSwap
import Daisy.Schema.Tab as STab
import Daisy.Schema.Table as STable
import Daisy.Schema.Textarea as STextarea
import Daisy.Schema.Timeline as STimeline
import Daisy.Schema.Toast as SToast
import Daisy.Schema.Toggle as SToggle
import Daisy.Schema.Tooltip as STooltip
import Date exposing (Date)



-- PAGE ----------------------------------------------------------------------


{-| A whole page.

`sections` is a fixed-arity type, so a page has between one and five sections.
`cta` is mandatory and is the page's only `btn-primary`; the shell decides where
it goes. `overlays` is the only place a modal, drawer or toast can appear.
`dock` and `fab` are viewport-fixed chrome rendered in the same layer.

-}
type Page msg
    = Page
        { shell : Shell msg
        , header : Maybe (PageHeader msg)
        , sections : Sections msg
        , cta : Cta msg
        , overlays : List (Overlay msg)
        , theme : Theme
        , dock : Maybe (Dock msg)
        , fab : Maybe (Fab msg)
        }


{-| The band above the first section: the page's name on the left, a
[`Breadcrumbs`](#Block) trail and any number of leaves on the right.

It is **not** a [`Section`](#Section). The section budget is five, fixed by the
SPEC, and a dashboard's title bar is chrome rather than content — the same
argument that keeps the navbar and the sidebar out of the budget. Putting it
here also means the shell owns its placement, so the title sits in the same
place under `Plain` and under `Dashboard` instead of depending on which section
the author happened to put it in.

`breadcrumbs` holds the leaves of one `breadcrumbs` trail (daisyUI wraps each
in its own `<li>`); `actions` holds right-aligned controls after it.

-}
type alias PageHeader msg =
    { title : String
    , breadcrumbs : List (Leaf msg)
    , actions : List (Leaf msg)
    }


{-| A page header with a title and nothing beside it.

    pageHeader "Business Overview"

-}
pageHeader : String -> PageHeader msg
pageHeader title =
    { title = title, breadcrumbs = [], actions = [] }


{-| One to five sections. There is no constructor for zero or six, so the page
content budget is a type error rather than a runtime check.
-}
type Sections msg
    = Sections1 (Section msg)
    | Sections2 (Section msg) (Section msg)
    | Sections3 (Section msg) (Section msg) (Section msg)
    | Sections4 (Section msg) (Section msg) (Section msg) (Section msg)
    | Sections5 (Section msg) (Section msg) (Section msg) (Section msg) (Section msg)


{-| The page frame.

`Plain` is a single column of sections. `Dashboard` renders as a daisyUI
`drawer` that is open from `lg:` up, with the sidebar `menu` in `drawer-side`
and the navbar on top of `drawer-content`.

-}
type Shell msg
    = Plain
    | Dashboard (DashboardShell msg)


{-| The parts of a [`Shell.Dashboard`](#Shell).

`brand` is the row above the sidebar menu — a glyph and the product's name, the
way every daisyUI dashboard template opens its sidebar. `sidebarFooter` is the
leaf pinned to the bottom of the same panel, which is where those templates put
the signed-in user ([`Leaf.UserChip`](#Leaf)).

`edges` draws the hairline daisyUI's own dashboard templates put under the
navbar and down the sidebar's right edge (1px, `--color-base-300`). It is a
switch rather than always-on because a shell whose content ground is
`base-100` — no tonal step between panel and page — has nothing for the line to
separate, and a line drawn there reads as a box. `dashboardShell` turns it on,
because the ground this package paints (`bg-base-200`) is the case that wants
it.

-}
type alias DashboardShell msg =
    { brand : Maybe Brand
    , sidebar : MenuSpec msg
    , sidebarFooter : Maybe (Leaf msg)
    , navbar : NavbarParts msg
    , edges : Bool
    }


{-| A dashboard shell with a sidebar menu and nothing else.

    dashboardShell { config = defaultMenuConfig, items = [ menuItem "Home" ] }

-}
dashboardShell : MenuSpec msg -> DashboardShell msg
dashboardShell sidebar =
    { brand = Nothing
    , sidebar = sidebar
    , sidebarFooter = Nothing
    , navbar = emptyNavbarParts
    , edges = True
    }


{-| The product mark at the top of a dashboard sidebar: one
[`Daisy.Icon.Icon`](Daisy-Icon#Icon) and the name beside it.
-}
type alias Brand =
    { icon : Icon
    , name : String
    }


{-| The page's single primary call to action. Rendered as `btn btn-primary`,
with `icon` as an optional leading [`Daisy.Icon.Icon`](Daisy-Icon#Icon).

`placement` says which piece of chrome it lands in; the shell still owns the
markup, so there is still exactly one primary button and still no way to put it
inside a section.

-}
type alias Cta msg =
    { label : String
    , onClick : msg
    , icon : Maybe Icon
    , placement : CtaPlacement
    , size : Maybe SButton.Size
    , style : Maybe SButton.Style
    , modifiers : List SButton.Modifier
    , behaviors : List SButton.Behavior
    , tooltip : Maybe Tooltip
    , aura : Maybe AuraConfig
    , indicator : Maybe Indicator
    }


{-| A [`Cta`](#Cta) with default styling.

    cta "Save" Save

-}
cta : String -> msg -> Cta msg
cta label onClick =
    { label = label
    , onClick = onClick
    , icon = Nothing
    , placement = InNavbar
    , size = Nothing
    , style = Nothing
    , modifiers = []
    , behaviors = []
    , tooltip = Nothing
    , aura = Nothing
    , indicator = Nothing
    }


{-| Where the shell draws [`Page.cta`](#Cta).

  - `InNavbar` is the end of `navbar-end` under `Shell.Dashboard` and the end
    of the last section under `Shell.Plain` — the placement this package has
    always had.
  - `InHeader` puts it in [`Page.header`](#PageHeader)'s right-hand group,
    after the breadcrumbs. daisyUI's own dashboard templates keep their navbar
    to search, notifications and the signed-in user, and put the page's action
    on the title row; this is that arrangement.
  - `InSidebarFooter` puts it above `DashboardShell.sidebarFooter`, which is
    where a tool with one standing action (“New project”) puts it.

`InHeader` needs a header to land in and `InSidebarFooter` needs a dashboard
sidebar. Neither is a type-level guarantee, so both fall back to `InNavbar`
rather than dropping the button: a page always renders its one CTA.

-}
type CtaPlacement
    = InNavbar
    | InHeader
    | InSidebarFooter


{-| Every [`CtaPlacement`](#CtaPlacement) value.
-}
allCtaPlacements : List CtaPlacement
allCtaPlacements =
    [ InNavbar, InHeader, InSidebarFooter ]



-- THEME ---------------------------------------------------------------------


{-| Every theme daisyUI 5 ships. `Daisy.Render.page` writes the chosen one to
`data-theme` on the page root.
-}
type Theme
    = Light
    | Dark
    | Cupcake
    | Bumblebee
    | Emerald
    | Corporate
    | Synthwave
    | Retro
    | Cyberpunk
    | Valentine
    | Halloween
    | Garden
    | Forest
    | Aqua
    | Lofi
    | Pastel
    | Fantasy
    | Wireframe
    | Black
    | Luxury
    | Dracula
    | Cmyk
    | Autumn
    | Business
    | Acid
    | Lemonade
    | Night
    | Coffee
    | Winter
    | Dim
    | Nord
    | Sunset
    | Caramellatte
    | Abyss
    | Silk
    | Custom CustomTheme


{-| All 35 themes, in daisyUI's own order.

`Custom` is deliberately absent: there is no list of every custom theme,
because a custom theme is a value the application makes up. This is the list a
[`Leaf.ThemeSelect`](#Leaf) offers when it offers "everything daisyUI ships".

-}
allThemes : List Theme
allThemes =
    [ Light
    , Dark
    , Cupcake
    , Bumblebee
    , Emerald
    , Corporate
    , Synthwave
    , Retro
    , Cyberpunk
    , Valentine
    , Halloween
    , Garden
    , Forest
    , Aqua
    , Lofi
    , Pastel
    , Fantasy
    , Wireframe
    , Black
    , Luxury
    , Dracula
    , Cmyk
    , Autumn
    , Business
    , Acid
    , Lemonade
    , Night
    , Coffee
    , Winter
    , Dim
    , Nord
    , Sunset
    , Caramellatte
    , Abyss
    , Silk
    ]


{-| The `data-theme` value for a [`Theme`](#Theme).

    themeToString Caramellatte --> "caramellatte"

-}
themeToString : Theme -> String
themeToString theme =
    case theme of
        Light ->
            "light"

        Dark ->
            "dark"

        Cupcake ->
            "cupcake"

        Bumblebee ->
            "bumblebee"

        Emerald ->
            "emerald"

        Corporate ->
            "corporate"

        Synthwave ->
            "synthwave"

        Retro ->
            "retro"

        Cyberpunk ->
            "cyberpunk"

        Valentine ->
            "valentine"

        Halloween ->
            "halloween"

        Garden ->
            "garden"

        Forest ->
            "forest"

        Aqua ->
            "aqua"

        Lofi ->
            "lofi"

        Pastel ->
            "pastel"

        Fantasy ->
            "fantasy"

        Wireframe ->
            "wireframe"

        Black ->
            "black"

        Luxury ->
            "luxury"

        Dracula ->
            "dracula"

        Cmyk ->
            "cmyk"

        Autumn ->
            "autumn"

        Business ->
            "business"

        Acid ->
            "acid"

        Lemonade ->
            "lemonade"

        Night ->
            "night"

        Coffee ->
            "coffee"

        Winter ->
            "winter"

        Dim ->
            "dim"

        Nord ->
            "nord"

        Sunset ->
            "sunset"

        Caramellatte ->
            "caramellatte"

        Abyss ->
            "abyss"

        Silk ->
            "silk"

        Custom custom ->
            themeNameToString custom.name



-- CUSTOM THEME --------------------------------------------------------------


{-| A theme of the application's own: the same twenty-nine declarations
daisyUI's own themes are written from, and nothing else.

Every field is a closed type, so the record cannot say anything daisyUI's theme
format cannot express — there is no `String` here except inside
[`ThemeName`](#ThemeName), which is opaque and validated.

`depth` and `noise` are daisyUI's two effect switches (`--depth` / `--noise`),
which its component CSS reads as `0` or `1`; a `Bool` is the honest type for a
variable whose only two documented values are those.

`Daisy.Render.page` writes every one of these onto the page root as an inline
CSS custom property, so a custom theme needs no stylesheet registration at all.
[`customThemeToCss`](#customThemeToCss) produces the `@plugin "daisyui/theme"`
block for the case where a _stylesheet_ is what is wanted.

-}
type alias CustomTheme =
    { name : ThemeName
    , colorScheme : ColorScheme
    , colors : ThemeColors
    , radius : { selector : Radius, field : Radius, box : Radius }
    , size : { selector : Size, field : Size }
    , border : Border
    , depth : Bool
    , noise : Bool
    }


{-| `color-scheme`, the CSS property that tells the browser which way round to
paint the UI it draws itself — scrollbars, form controls, the canvas behind the
page.
-}
type ColorScheme
    = LightScheme
    | DarkScheme


{-| Every [`ColorScheme`](#ColorScheme).
-}
allColorSchemes : List ColorScheme
allColorSchemes =
    [ LightScheme, DarkScheme ]


{-| The `color-scheme` value for a [`ColorScheme`](#ColorScheme).

    colorSchemeToString DarkScheme --> "dark"

-}
colorSchemeToString : ColorScheme -> String
colorSchemeToString scheme =
    case scheme of
        LightScheme ->
            "light"

        DarkScheme ->
            "dark"


{-| A colour in OKLCH, the space daisyUI writes every theme colour in. This is
[`Daisy.Color.Oklch`](Daisy-Color#Oklch) under a local name, so a caller
building a theme does not have to import two modules; `l` is lightness in
percent (`0` to `100`), matching the `62%` daisyUI prints.
-}
type alias Oklch =
    Color.Oklch


{-| The twenty colour variables a daisyUI theme declares: three base surfaces
and the content colour that reads on them, then eight semantic colours each
paired with the content colour that reads on _it_.

The list is daisyUI's, in daisyUI's own order, and it is exhaustive — every
`--color-*` variable `vendor/daisyui/packages/daisyui/src/themes/*.css`
declares appears here exactly once.

-}
type alias ThemeColors =
    { base100 : Oklch
    , base200 : Oklch
    , base300 : Oklch
    , baseContent : Oklch
    , primary : Oklch
    , primaryContent : Oklch
    , secondary : Oklch
    , secondaryContent : Oklch
    , accent : Oklch
    , accentContent : Oklch
    , neutral : Oklch
    , neutralContent : Oklch
    , info : Oklch
    , infoContent : Oklch
    , success : Oklch
    , successContent : Oklch
    , warning : Oklch
    , warningContent : Oklch
    , error : Oklch
    , errorContent : Oklch
    }


{-| One corner radius, as one of the five steps daisyUI's own theme generator
offers. There is no free `Float`: daisyUI's generator is a five-position slider
and its thirty-five stock themes only ever use these values, so an open number
would let a theme say something no daisyUI theme says.

`RadiusNone` is `0rem`, `RadiusXs` `0.25rem`, `RadiusSm` `0.5rem`, `RadiusMd`
`1rem`, `RadiusLg` `2rem`.

-}
type Radius
    = RadiusNone
    | RadiusXs
    | RadiusSm
    | RadiusMd
    | RadiusLg


{-| Every [`Radius`](#Radius), smallest first.
-}
allRadii : List Radius
allRadii =
    [ RadiusNone, RadiusXs, RadiusSm, RadiusMd, RadiusLg ]


{-| The CSS length for a [`Radius`](#Radius).

    radiusToString RadiusSm --> "0.5rem"

-}
radiusToString : Radius -> String
radiusToString radius =
    case radius of
        RadiusNone ->
            "0rem"

        RadiusXs ->
            "0.25rem"

        RadiusSm ->
            "0.5rem"

        RadiusMd ->
            "1rem"

        RadiusLg ->
            "2rem"


{-| The base size a control is built from, as one of the five steps daisyUI's
generator offers: 3px, 3.5px, 4px, 4.5px and 5px, written in `rem`.

daisyUI multiplies it by a per-size factor, so `SizeMd` (`0.25rem`, the value
every stock theme uses) is what makes a `btn` 40px tall and a `btn-xs` 24px.

-}
type Size
    = SizeXs
    | SizeSm
    | SizeMd
    | SizeLg
    | SizeXl


{-| Every [`Size`](#Size), smallest first.
-}
allSizes : List Size
allSizes =
    [ SizeXs, SizeSm, SizeMd, SizeLg, SizeXl ]


{-| The CSS length for a [`Size`](#Size).

    sizeToString SizeMd --> "0.25rem"

-}
sizeToString : Size -> String
sizeToString size =
    case size of
        SizeXs ->
            "0.1875rem"

        SizeSm ->
            "0.21875rem"

        SizeMd ->
            "0.25rem"

        SizeLg ->
            "0.28125rem"

        SizeXl ->
            "0.3125rem"


{-| The border width every bordered component shares (`--border`), as one of
the four steps daisyUI's generator offers.

`BorderHairline` is `0.5px`, `BorderThin` `1px`, `BorderMedium` `1.5px`,
`BorderThick` `2px`.

-}
type Border
    = BorderHairline
    | BorderThin
    | BorderMedium
    | BorderThick


{-| Every [`Border`](#Border), thinnest first.
-}
allBorders : List Border
allBorders =
    [ BorderHairline, BorderThin, BorderMedium, BorderThick ]


{-| The CSS length for a [`Border`](#Border).

    borderToString BorderThin --> "1px"

-}
borderToString : Border -> String
borderToString border =
    case border of
        BorderHairline ->
            "0.5px"

        BorderThin ->
            "1px"

        BorderMedium ->
            "1.5px"

        BorderThick ->
            "2px"


{-| The name a custom theme answers to: what `data-theme` carries, what
`@plugin "daisyui/theme"` declares, and what `?theme=` selects.

It is opaque, and [`themeName`](#themeName) is the only way to build one, so an
invalid name is unrepresentable rather than a runtime surprise.

-}
type ThemeName
    = ThemeName String


{-| Build a [`ThemeName`](#ThemeName), or refuse.

Two rules, both of them daisyUI's:

1.  The name must match `[a-z][a-z0-9-]*`. It ends up inside a CSS attribute
    selector (`[data-theme="x"]`), inside an `@plugin` block and inside a URL
    query, and daisyUI's own thirty-five names are all of this shape.
2.  The name must not be one of the thirty-five built-ins. A custom theme that
    called itself `light` would collide with the stylesheet daisyUI already
    ships under that selector, and `themeToString` would stop being injective.

```
themeName "acme" --> Just (themeName-of "acme")

themeName "Acme" --> Nothing

themeName "1acme" --> Nothing

themeName "acme corp" --> Nothing

themeName "light" --> Nothing
```

-}
themeName : String -> Maybe ThemeName
themeName raw =
    let
        reserved : Bool
        reserved =
            List.any (\theme -> themeToString theme == raw) allThemes
    in
    if reserved || not (wellFormedThemeName raw) then
        Nothing

    else
        Just (ThemeName raw)


wellFormedThemeName : String -> Bool
wellFormedThemeName raw =
    case String.uncons raw of
        Nothing ->
            False

        Just ( first, rest ) ->
            Char.isLower first
                && Char.isAlpha first
                && String.all (\c -> (Char.isLower c && Char.isAlpha c) || Char.isDigit c || c == '-') rest


{-| The name of any theme at all, built-in or custom.

This is the one way to get a [`ThemeName`](#ThemeName) for a built-in, which
[`themeName`](#themeName) refuses on purpose. It is what
`Daisy.Themes.builtinToCustom` uses to turn a stock theme into an editable
[`CustomTheme`](#CustomTheme): the reserved names are reserved against _new_
themes, not against reading the built-in ones back out.

    themeNameToString (themeNameOf Caramellatte) --> "caramellatte"

-}
themeNameOf : Theme -> ThemeName
themeNameOf theme =
    ThemeName (themeToString theme)


{-| The string inside a [`ThemeName`](#ThemeName).
-}
themeNameToString : ThemeName -> String
themeNameToString (ThemeName raw) =
    raw


{-| Every declaration a [`CustomTheme`](#CustomTheme) stands for, as
`( property, value )` pairs in daisyUI's own order: `color-scheme`, the twenty
colours, three radii, two sizes, the border width, and the two effect switches.
Twenty-nine pairs, always.

`Daisy.Render.page` maps this straight onto `Html.Attributes.style` on the page
root. Nothing in daisyUI's component CSS reads these variables at _definition_
time — every use is a `var(--color-primary)` or a `calc(var(--depth) * 30%)` in
a declaration on the component itself — so an inline definition on an ancestor
themes the whole subtree exactly as a stylesheet rule would.

-}
customThemeProperties : CustomTheme -> List ( String, String )
customThemeProperties custom =
    let
        colors : ThemeColors
        colors =
            custom.colors

        color : String -> (ThemeColors -> Oklch) -> ( String, String )
        color name get =
            ( "--color-" ++ name, Color.oklchToCss (get colors) )
    in
    [ ( "color-scheme", colorSchemeToString custom.colorScheme )
    , color "base-100" .base100
    , color "base-200" .base200
    , color "base-300" .base300
    , color "base-content" .baseContent
    , color "primary" .primary
    , color "primary-content" .primaryContent
    , color "secondary" .secondary
    , color "secondary-content" .secondaryContent
    , color "accent" .accent
    , color "accent-content" .accentContent
    , color "neutral" .neutral
    , color "neutral-content" .neutralContent
    , color "info" .info
    , color "info-content" .infoContent
    , color "success" .success
    , color "success-content" .successContent
    , color "warning" .warning
    , color "warning-content" .warningContent
    , color "error" .error
    , color "error-content" .errorContent
    , ( "--radius-selector", radiusToString custom.radius.selector )
    , ( "--radius-field", radiusToString custom.radius.field )
    , ( "--radius-box", radiusToString custom.radius.box )
    , ( "--size-selector", sizeToString custom.size.selector )
    , ( "--size-field", sizeToString custom.size.field )
    , ( "--border", borderToString custom.border )
    , ( "--depth", switchToString custom.depth )
    , ( "--noise", switchToString custom.noise )
    ]


{-| The twenty-nine declarations as one `style` attribute value.

    customThemeStyle myTheme
    --> "color-scheme:light;--color-base-100:oklch(98% 0 0);..."

This exists rather than `Daisy.Render` writing one `Html.Attributes.style` per
property because **`Html.Attributes.style` cannot set a CSS custom property**:
`elm/virtual-dom` applies a style node with `element.style[key] = value`, and a
`CSSStyleDeclaration` ignores an assignment to `"--color-primary"` — only
`setProperty` works there, and Elm never calls it. Setting the whole `style`
attribute goes through `setAttribute`, which the CSS parser reads, so the
custom properties land. Verified in Chrome against the built demo: with one
`style` node per property the page root's computed `--color-primary` stayed
daisyUI's default; with this one attribute it is the theme's.

-}
customThemeStyle : CustomTheme -> String
customThemeStyle custom =
    customThemeProperties custom
        |> List.map (\( property, value ) -> property ++ ":" ++ value)
        |> String.join ";"


switchToString : Bool -> String
switchToString on =
    if on then
        "1"

    else
        "0"


{-| A [`CustomTheme`](#CustomTheme) as the `@plugin "daisyui/theme"` block
daisyUI's documentation asks for — a plain string of CSS, no classes involved.

Paste it into a stylesheet next to `@plugin "daisyui"` and the theme is
registered the way a built-in is, which is what a `<link>`ed page or a
Tailwind build wants. An application that renders through `Daisy.Render.page`
needs none of it: the same declarations go on the page root inline.

    customThemeToCss myTheme
    --> "@plugin \"daisyui/theme\" {\n  name: \"mytheme\";\n  ... }"

-}
customThemeToCss : CustomTheme -> String
customThemeToCss custom =
    let
        declaration : ( String, String ) -> String
        declaration ( property, value ) =
            "  " ++ property ++ ": " ++ value ++ ";"
    in
    String.join "\n"
        ([ "@plugin \"daisyui/theme\" {"
         , "  name: \"" ++ themeNameToString custom.name ++ "\";"
         , "  default: false;"
         , "  prefersdark: false;"
         ]
            ++ List.map declaration (customThemeProperties custom)
            ++ [ "}" ]
        )


{-| A [`CustomTheme`](#CustomTheme) in the exact JSON shape daisyUI's own theme
generator round-trips through its URL: `name`, `color-scheme`, the twenty-nine
declarations, then `default` and `prefersdark`, in that order.

It is here rather than in an application because the key names and the ordering
are the same facts [`customThemeToCss`](#customThemeToCss) is written from, and
two copies of them would drift.

Every value is a plain string with no character needing an escape (a theme name
is `[a-z][a-z0-9-]*`, a colour is `oklch(...)`, a length is digits and letters),
so this builds the document directly instead of pulling in a JSON encoder.

-}
customThemeToJson : CustomTheme -> String
customThemeToJson custom =
    let
        pair : ( String, String ) -> String
        pair ( key, value ) =
            "\"" ++ key ++ "\":\"" ++ value ++ "\""
    in
    "{"
        ++ String.join ","
            (pair ( "name", themeNameToString custom.name )
                :: List.map pair (customThemeProperties custom)
                ++ [ "\"default\":false", "\"prefersdark\":false" ]
            )
        ++ "}"



-- SECTION -------------------------------------------------------------------


{-| A top-level band of the page.

`Navbar` holds leaves in three named part lists; the others hold blocks.

-}
type Section msg
    = Hero HeroConfig (List (Block msg))
    | Navbar (NavbarParts msg)
    | Footer FooterConfig (List (Block msg))
    | Grid (GridSection msg)
    | Stack StackConfig (List (Block msg))


{-| `hero` has no class groups; `overlay` decides whether the renderer emits the
`hero-overlay` part.
-}
type alias HeroConfig =
    { overlay : Bool }


{-| A hero with no overlay.
-}
defaultHeroConfig : HeroConfig
defaultHeroConfig =
    { overlay = False }


{-| The three `navbar-*` parts. Each holds leaves, never blocks.
-}
type alias NavbarParts msg =
    { start : List (Leaf msg)
    , center : List (Leaf msg)
    , end : List (Leaf msg)
    }


{-| An empty navbar.
-}
emptyNavbarParts : NavbarParts msg
emptyNavbarParts =
    { start = [], center = [], end = [] }


{-| Groups of the daisyUI `footer` component.
-}
type alias FooterConfig =
    { direction : Maybe SFooter.Direction
    , placement : Maybe SFooter.Placement
    }


{-| A footer with no direction or placement class.
-}
defaultFooterConfig : FooterConfig
defaultFooterConfig =
    { direction = Nothing, placement = Nothing }


{-| What a `Grid` section holds.

Two shapes, and the split is the point. `Columns` is a grid of equal tracks and
its children are plain blocks — there is nothing to say about a cell, because
every cell is the same width. `Spans` is the twelve-column grid, and _every_
child of it must say how many of the twelve it takes.

Putting the choice in the payload type rather than in a `Cols12` member of
[`GridColumns`](#GridColumns) is what makes the two mistakes unrepresentable
instead of merely wrong: a [`GridItem`](#GridItem) inside a `Columns` grid and
a bare `Block` inside a `Spans` grid are both a `TYPE MISMATCH`
(`tools/should-not-compile/Reject/SpanOutsideTwelveGrid.elm`). `Section` also
stays at the five constructors the SPEC fixes it at.

    Grid (Columns { columns = Cols4 } [ tile, tile, tile, tile ])

    Grid (Spans [ span Span7 chartCard, span Span5 sideCard ])

-}
type GridSection msg
    = Columns GridConfig (List (Block msg))
    | Spans (List (GridItem msg))


{-| How many equal columns a `Columns` grid has. Spacing is fixed by
`Daisy.Render.tokens`; only the column count is authorable.
-}
type GridColumns
    = Cols1
    | Cols2
    | Cols3
    | Cols4


{-| Configuration of a `Columns` grid.
-}
type alias GridConfig =
    { columns : GridColumns }


{-| A four-column grid.
-}
defaultGridConfig : GridConfig
defaultGridConfig =
    { columns = Cols4 }


{-| One cell of a `Spans` grid: the number of the twelve tracks it takes, and
the blocks stacked inside it.

`blocks` is a list rather than one block because a twelve-column band is where a
page puts _columns_, and a column is normally more than one panel — an editor
rail beside two columns of preview cards, a form beside a stack of summaries.
`Daisy.Render` lays the cell out as one fixed-gap vertical column, so a cell of
one block is byte-identical to a cell that held only that block; there is still
no layout decision for the caller to make.

-}
type alias GridItem msg =
    { span : Span
    , columns : CellColumns
    , blocks : List (Block msg)
    }


{-| How a `Spans` cell lays its own blocks out.

`CellOne` is the column every cell was before this: one fixed-gap stack. The
other two are the shape a _preview_ has — daisyUI's own theme generator lays its
component demo out as `grid xl:grid-cols-3` of small cards inside the region
beside its editor, and that is a grid **inside a cell**, not a nesting level of
the tree: the children are still blocks, and a block still never contains a
block.

Both step down to one column on a phone and two at `sm`, for the same reason
`Section.Grid`'s counts are breakpoints rather than constants.

-}
type CellColumns
    = CellOne
    | CellTwo
    | CellThree


{-| Every [`CellColumns`](#CellColumns) value.
-}
allCellColumns : List CellColumns
allCellColumns =
    [ CellOne, CellTwo, CellThree ]


{-| A [`GridItem`](#GridItem) holding one block.

    span Span7 (Card defaultCardConfig parts)

-}
span : Span -> Block msg -> GridItem msg
span width block =
    { span = width, columns = CellOne, blocks = [ block ] }


{-| A [`GridItem`](#GridItem) holding a column of blocks.

    spanColumn Span3 [ toolbarCard, coloursCard, shapeCard ]

-}
spanColumn : Span -> List (Block msg) -> GridItem msg
spanColumn width blocks =
    { span = width, columns = CellOne, blocks = blocks }


{-| A [`GridItem`](#GridItem) whose blocks are laid out as a grid of their own.

    spanGrid Span7 CellThree previewCards

-}
spanGrid : Span -> CellColumns -> List (Block msg) -> GridItem msg
spanGrid width columns blocks =
    { span = width, columns = columns, blocks = blocks }


{-| How many of twelve tracks a [`GridItem`](#GridItem) takes.

All twelve, including the two narrow ones. A single track is ~94px in a 1392px
content column, which is too little for a panel — but it is exactly right for
the _rail_ kinds of cell a twelve-column page has: daisyUI's own theme
generator puts its theme list in 190px and its editor in 250px, which is two
tracks and three.

The splits daisyUI's own templates use are all expressible: 7:5 for a chart
beside a panel, 8:4 for content beside a rail, 6:6 for halves, 2:3:7 for the
generator's list, editor and preview.

-}
type Span
    = Span1
    | Span2
    | Span3
    | Span4
    | Span5
    | Span6
    | Span7
    | Span8
    | Span9
    | Span10
    | Span11
    | Span12


{-| Every [`Span`](#Span) value.
-}
allSpans : List Span
allSpans =
    [ Span1, Span2, Span3, Span4, Span5, Span6, Span7, Span8, Span9, Span10, Span11, Span12 ]


{-| Cross-axis alignment of a `Stack` section.

`AlignStretch` (`items-stretch`) is the one that lets a `Table`, `Alert` or
`Card` fill the band; the other three shrink every block to its content width.

-}
type Align
    = AlignStart
    | AlignCenter
    | AlignEnd
    | AlignStretch


{-| Configuration of a `Stack` section. This is a fixed-gap vertical band, not
the daisyUI `stack` component — that one is [`Stacked`](#Block).
-}
type alias StackConfig =
    { align : Align }


{-| A stack whose blocks sit at the start edge.

The default is deliberately **not** `AlignStretch`, even though stretching is
what most bands want: under `Shell.Plain` the renderer appends `Page.cta` to
the last section's container, so a stretched last `Stack` would stretch the
page's single primary button across the whole page. Ask for `AlignStretch`
where you want it instead.

-}
defaultStackConfig : StackConfig
defaultStackConfig =
    { align = AlignStart }



-- BLOCK ---------------------------------------------------------------------


{-| A self-contained content container inside a section. A block never contains
another block.
-}
type Block msg
    = Accordion AccordionConfig (List (AccordionItem msg))
    | Alert AlertConfig (List (Leaf msg))
    | Breadcrumbs (List (Leaf msg))
    | Card CardConfig (CardParts msg)
    | Carousel CarouselConfig (List (CarouselItem msg))
    | Chart ChartConfig ChartData (Maybe (ChartInteraction msg))
    | Chat (List (ChatMessage msg))
    | Collapse CollapseConfig (CollapseParts msg)
    | Diff (DiffParts msg)
    | Form (List (Fieldset msg))
    | ListBlock (List (ListRow msg))
    | Menu MenuConfig (List (MenuItem msg))
    | MockupBrowser (MockupBrowserParts msg)
    | MockupCode (List CodeLine)
    | MockupPhone (MockupPhoneParts msg)
    | MockupWindow (MockupWindowParts msg)
    | Nav NavConfig (List (Leaf msg))
    | Pagination PaginationConfig PaginationData
    | Prose (List (Leaf msg))
    | Stacked StackedConfig (List (Leaf msg))
    | Stat StatConfig (List (StatItem msg))
    | Steps StepsConfig (List Step)
    | Table TableConfig (List (Row msg))
    | Tabs TabsConfig (List (Tab msg))
    | Timeline TimelineConfig (List (TimelineItem msg))


{-| Groups of the daisyUI `collapse` component, plus the radio group name that
turns a set of collapses into an accordion.
-}
type alias AccordionConfig =
    { modifiers : List SAccordion.Modifier
    , name : String
    }


{-| An accordion whose items share the group name `"accordion"`.
-}
defaultAccordionConfig : AccordionConfig
defaultAccordionConfig =
    { modifiers = [], name = "accordion" }


{-| One `collapse` inside an [`Accordion`](#Block).
-}
type alias AccordionItem msg =
    { title : String
    , content : List (Leaf msg)
    }


{-| Groups of the daisyUI `alert` component.
-}
type alias AlertConfig =
    { color : Maybe SAlert.Color
    , style : Maybe SAlert.Style
    , direction : Maybe SAlert.Direction
    }


{-| An alert with no colour, style or direction class.
-}
defaultAlertConfig : AlertConfig
defaultAlertConfig =
    { color = Nothing, style = Nothing, direction = Nothing }


{-| Groups of the daisyUI `card` component plus the `aura` and `hover-3d`
decoration properties.
-}
type alias CardConfig =
    { style : Maybe SCard.Style
    , size : Maybe SCard.Size
    , padding : CardPadding
    , modifiers : List SCard.Modifier
    , aura : Maybe AuraConfig
    , hover3d : Bool
    }


{-| The inside gutter of a `card-body`.

`PaddingDefault` leaves daisyUI's own `--card-p` alone: 1.5rem, or 1rem at
`card-sm`. `PaddingDashboard` is the 20px every daisyUI dashboard template sets
instead — halfway between those two steps, which is the figure a grid of panels
wants and which neither `card` size offers.

It is a closed pair rather than a length because a length is a spacing decision
and spacing is `Daisy.Render.tokens`' job; this names the two the library will
make.

-}
type CardPadding
    = PaddingDefault
    | PaddingDashboard


{-| Both [`CardPadding`](#CardPadding) values.
-}
allCardPaddings : List CardPadding
allCardPaddings =
    [ PaddingDefault, PaddingDashboard ]


{-| A plain card.
-}
defaultCardConfig : CardConfig
defaultCardConfig =
    { style = Nothing
    , size = Nothing
    , padding = PaddingDefault
    , modifiers = []
    , aura = Nothing
    , hover3d = False
    }


{-| The `card-*` parts. A part record makes `card-body` outside a card
unrepresentable.

`title`, `titleIcon`, `headerTabs` and `headerActions` are one row: the glyph
and the `card-title` on the left, then the segmented control and the controls on
the right. Every dashboard card in daisyUI's own templates is built that way (a
"Report" button, a `Day | Month | Year` switch), and keeping the row in the part
record means the renderer owns the alignment instead of each caller inventing a
flex container.

`actions` is unrelated: it is daisyUI's `card-actions` part, at the _bottom_ of
the body.

-}
type alias CardParts msg =
    { figure : Maybe (Leaf msg)
    , title : Maybe String
    , titleIcon : Maybe Icon
    , headerTabs : Maybe (TabsSpec msg)
    , headerActions : List (Leaf msg)
    , body : List (CardChild msg)
    , actions : List (Leaf msg)
    }


{-| What a `card-body` may hold: leaves, plus the five block shapes a
dashboard card is actually made of.

There is deliberately no `CardCard`: a card can never contain a card, which is
what `tools/should-not-compile/Reject/CardInCard.elm` and
`Reject/CardInCardBody.elm` pin down. Every constructor here takes exactly the
arguments its `Block` counterpart takes, and `Daisy.Render` renders it through
the same helper, so a chart in a card and a bare chart are the same markup.

-}
type CardChild msg
    = CardLeaf (Leaf msg)
    | CardAlert AlertConfig (List (Leaf msg))
    | CardChart ChartConfig ChartData (Maybe (ChartInteraction msg))
    | CardChat (List (ChatMessage msg))
    | CardTable TableConfig (List (Row msg))
    | CardList (List (ListRow msg))
    | CardStat StatConfig (List (StatItem msg))
    | CardForm (List (Fieldset msg))


{-| A card with nothing in it.
-}
emptyCardParts : CardParts msg
emptyCardParts =
    { figure = Nothing
    , title = Nothing
    , titleIcon = Nothing
    , headerTabs = Nothing
    , headerActions = []
    , body = []
    , actions = []
    }


{-| Where a carousel snaps its items. daisyUI declares these under `modifier`
but they are mutually exclusive, so the tree offers one field and the renderer
expands it into a single modifier class.
-}
type CarouselSnap
    = SnapStart
    | SnapCenter
    | SnapEnd


{-| Groups of the daisyUI `carousel` component.
-}
type alias CarouselConfig =
    { direction : Maybe SCarousel.Direction
    , modifiers : List SCarousel.Modifier
    , snap : Maybe CarouselSnap
    }


{-| A carousel with no direction or snap class.
-}
defaultCarouselConfig : CarouselConfig
defaultCarouselConfig =
    { direction = Nothing, modifiers = [], snap = Nothing }


{-| One `carousel-item`.
-}
type alias CarouselItem msg =
    { content : List (Leaf msg) }


{-| One chat message. The colour applies to the `chat-bubble` part, which is
where daisyUI puts it.
-}
type alias ChatMessage msg =
    { placement : SChat.Placement
    , color : Maybe SChat.Color
    , image : Maybe ImageSrc
    , header : Maybe String
    , footer : Maybe String
    , bubble : List (Leaf msg)
    }


{-| Groups of the daisyUI `collapse` component.
-}
type alias CollapseConfig =
    { modifiers : List SCollapse.Modifier }


{-| A closed collapse with no arrow or plus icon.
-}
defaultCollapseConfig : CollapseConfig
defaultCollapseConfig =
    { modifiers = [] }


{-| The `collapse-title` and `collapse-content` parts.
-}
type alias CollapseParts msg =
    { title : String
    , content : List (Leaf msg)
    }


{-| The `diff-item-1` and `diff-item-2` parts. `diff-resizer` is emitted by the
renderer.
-}
type alias DiffParts msg =
    { item1 : Leaf msg
    , item2 : Leaf msg
    }


{-| A `fieldset` inside a `Form` block. `fieldset-legend` cannot exist without
its fieldset.
-}
type alias Fieldset msg =
    { legend : Maybe String
    , fields : List (Field msg)
    }


{-| One labelled, optionally validated control.

`label` and `validator-hint` are held here rather than as leaves, so a stray
legend, label or hint is unrepresentable and the hint is always the sibling
immediately after its input.

-}
type alias Field msg =
    { label : Maybe String
    , labelPlacement : LabelPlacement
    , control : Leaf msg
    , validate : Bool
    , hint : Maybe String
    }


{-| Where a field's label sits: before the control, after it, or floating over
it (`floating-label`).
-}
type LabelPlacement
    = LabelStart
    | LabelEnd
    | LabelFloating


{-| A labelled field with no validation.

    field "Email" (Input defaultInputConfig)

-}
field : String -> Leaf msg -> Field msg
field label control =
    { label = Just label
    , labelPlacement = LabelStart
    , control = control
    , validate = False
    , hint = Nothing
    }


{-| One `list-row`.
-}
type alias ListRow msg =
    { cells : List (ListCell msg) }


{-| One cell of a `list-row`.

`list-col-grow` and `list-col-wrap` mark a single cell, not the whole list, so
they are flags here rather than modifiers on the block. A cell with neither
flag is rendered as its bare leaf.

-}
type alias ListCell msg =
    { content : Leaf msg
    , grow : Bool
    , wrap : Bool
    }


{-| A plain cell that neither grows nor wraps.

    listCell (Text "Cy Ganderton")

-}
listCell : Leaf msg -> ListCell msg
listCell content =
    { content = content, grow = False, wrap = False }


{-| Groups of the daisyUI `menu` component. `menu-active`, `menu-disabled` and
`menu-focus` belong on an item, so they are flags on [`MenuItem`](#MenuItem),
not entries here.
-}
type alias MenuConfig =
    { size : Maybe SMenu.Size
    , direction : Maybe SMenu.Direction
    , activeStyle : MenuActiveStyle
    , modifiers : List SMenu.Modifier
    }


{-| A vertical menu at the default size, with daisyUI's own active row.
-}
defaultMenuConfig : MenuConfig
defaultMenuConfig =
    { size = Nothing
    , direction = Nothing
    , activeStyle = SolidActive
    , modifiers = []
    }


{-| How the active row of a menu is painted.

`SolidActive` is daisyUI's `menu-active`: `.menu` sets
`--menu-active-bg: var(--color-neutral)`, so the row is a solid slab of the
neutral colour with `--color-neutral-content` on it.

`TintedActive` is what daisyUI's own dashboard templates use instead — the row
is one surface step up from the panel (`bg-base-200`) at `font-medium`, in the
page's ordinary text colour. It is a quieter mark, which is what a sidebar of
twenty entries needs; a slab of neutral in a `bg-base-100` sidebar reads as a
button.

It emits **no** `menu-active`, because daisyUI offers no class for this: the
active background is a custom property with one value. `SolidActive` therefore
stays the default and is the only way to reach `menu-active` — it is not
deprecated by the tinted style, it is the other half of a pair.

-}
type MenuActiveStyle
    = SolidActive
    | TintedActive


{-| Both [`MenuActiveStyle`](#MenuActiveStyle) values.
-}
allMenuActiveStyles : List MenuActiveStyle
allMenuActiveStyles =
    [ SolidActive, TintedActive ]


{-| One menu entry. `title = True` renders it as the `menu-title` part; a
non-empty `submenu` renders the `menu-dropdown` parts.

`icon` is a [`Daisy.Icon.Icon`](Daisy-Icon#Icon) drawn before the label at
`size-5`. It is decorative — the label beside it is the accessible name — so the
`<svg>` is `aria-hidden`.

`href` becomes the anchor's `href`. A menu item without one is a bare `<a>`,
which is not focusable and carries no `link` role, so navigation items should
always set it; `onClick` may still be set alongside (a `Browser.application`
turns the click into an `onUrlRequest` on its own).

-}
type MenuItem msg
    = MenuItem
        { label : String
        , icon : Maybe Icon
        , badge : Maybe MenuBadge
        , active : Bool
        , disabled : Bool
        , focus : Bool
        , title : Bool
        , href : Maybe String
        , onClick : Maybe msg
        , submenu : List (MenuItem msg)
        }


{-| A badge shown at the end of a menu item.
-}
type alias MenuBadge =
    { config : BadgeConfig
    , label : String
    }


{-| A plain menu entry.

    menuItem "Dashboard"

-}
menuItem : String -> MenuItem msg
menuItem label =
    MenuItem
        { label = label
        , icon = Nothing
        , badge = Nothing
        , active = False
        , disabled = False
        , focus = False
        , title = False
        , href = Nothing
        , onClick = Nothing
        , submenu = []
        }


{-| A menu referenced from somewhere other than `Block.Menu`, namely
`Shell.Dashboard.sidebar` and the `dropdown` property.
-}
type alias MenuSpec msg =
    { config : MenuConfig
    , items : List (MenuItem msg)
    }


{-| The `mockup-browser-toolbar` part plus the framed content.
-}
type alias MockupBrowserParts msg =
    { toolbar : Maybe String
    , content : List (Leaf msg)
    }


{-| The framed content. `mockup-phone-camera` and `mockup-phone-display` are
emitted by the renderer.
-}
type alias MockupPhoneParts msg =
    { content : List (Leaf msg) }


{-| A window title bar plus the framed content.
-}
type alias MockupWindowParts msg =
    { title : Maybe String
    , content : List (Leaf msg)
    }


{-| One line of a `MockupCode` block.
-}
type alias CodeLine =
    { prefix : Maybe String
    , text : String
    }


{-| A navigation column. Its `title` becomes the `footer-title` part when the
column is a direct child of a `Footer` section.
-}
type alias NavConfig =
    { title : Maybe String }


{-| An untitled navigation column.
-}
defaultNavConfig : NavConfig
defaultNavConfig =
    { title = Nothing }


{-| Groups of the daisyUI `pagination` component, which reuses `join`.
-}
type alias PaginationConfig =
    { direction : Maybe SPagination.Direction }


{-| A pagination bar with no direction class.
-}
defaultPaginationConfig : PaginationConfig
defaultPaginationConfig =
    { direction = Nothing }


{-| The pages of a pagination bar and the index of the active one.
-}
type alias PaginationData =
    { pages : List String
    , active : Int
    }


{-| Where a daisyUI `stack` aligns its overlapping children. Declared under
`modifier` but mutually exclusive; see `snap` on [`CarouselConfig`](#CarouselConfig).
-}
type StackedAlign
    = StackedTop
    | StackedBottom
    | StackedStart
    | StackedEnd


{-| Groups of the daisyUI `stack` component.
-}
type alias StackedConfig =
    { modifiers : List SStack.Modifier
    , align : Maybe StackedAlign
    }


{-| A stack with no alignment class.
-}
defaultStackedConfig : StackedConfig
defaultStackedConfig =
    { modifiers = [], align = Nothing }


{-| Groups of the daisyUI `stat` component. The container class is `stats`.
-}
type alias StatConfig =
    { direction : StatDirection }


{-| How a `stats` container lays its tiles out.

`Fixed` is the schema `direction` group: one class, or none. `Responsive` is
daisyUI's own `stats-vertical lg:stats-horizontal` idiom — a column on a phone,
a row from `lg` up. It is a separate constructor rather than a flag beside
`direction` so there is no combination where one silently wins over the other.

-}
type StatDirection
    = Fixed (Maybe SStat.Direction)
    | Responsive


{-| A stats container with no direction class.
-}
defaultStatConfig : StatConfig
defaultStatConfig =
    { direction = Fixed Nothing }


{-| One tile: the `stat`, `stat-figure`, `stat-title`, `stat-value`,
`stat-desc` and `stat-actions` parts.

`trend` sits on the same line as `value`, inside `stat-value`. It is the delta
badge every dashboard metric carries (`+10.8%` beside `$587.54`); a `Leaf`
rather than a string so it can be the soft `Badge` with a leading arrow that
daisyUI's own templates use.

-}
type alias StatItem msg =
    { figure : Maybe (Leaf msg)
    , title : String
    , value : String
    , trend : Maybe (Leaf msg)
    , desc : Maybe String
    , actions : List (Leaf msg)
    }


{-| A titled tile with a value and nothing else.
-}
emptyStatItem : String -> String -> StatItem msg
emptyStatItem title value =
    { figure = Nothing
    , title = title
    , value = value
    , trend = Nothing
    , desc = Nothing
    , actions = []
    }


{-| Groups of the daisyUI `steps` component. The colour classes are `step-*` and
belong on a [`Step`](#Step), not here.
-}
type alias StepsConfig =
    { direction : Maybe SSteps.Direction }


{-| Steps with no direction class.
-}
defaultStepsConfig : StepsConfig
defaultStepsConfig =
    { direction = Nothing }


{-| One `step`, optionally coloured and with a `step-icon`.
-}
type alias Step =
    { label : String
    , color : Maybe SSteps.Color
    , icon : Maybe String
    }


{-| Groups of the daisyUI `table` component.
-}
type alias TableConfig =
    { size : Maybe STable.Size
    , modifiers : List STable.Modifier
    }


{-| A table with no size or zebra class.
-}
defaultTableConfig : TableConfig
defaultTableConfig =
    { size = Nothing, modifiers = [] }


{-| One table row. `header = True` renders its cells as `<th>` inside `<thead>`.
-}
type alias Row msg =
    { header : Bool
    , cells : List (TableCell msg)
    }


{-| One cell of a [`Row`](#Row).

`content` is the cell. `leading` is an optional second leaf drawn **before** it
on the same line, which is the "avatar and name in one cell" idiom every
dashboard table uses (daisyUI's own "Table with visual elements" example writes
it as a flex `div` wrapping an `avatar` and the name).

A cell with `leading = Nothing` renders as the bare leaf inside the `<td>`, i.e.
exactly the markup a plain cell has always produced; only a cell that really has
a leading leaf gets a wrapper. That is the rule [`ListCell`](#ListCell) already
follows for `list-col-grow`.

-}
type alias TableCell msg =
    { leading : Maybe (Leaf msg)
    , content : Leaf msg
    }


{-| A plain table cell.

    tableCell (Text "Cy Ganderton")

-}
tableCell : Leaf msg -> TableCell msg
tableCell content =
    { leading = Nothing, content = content }


{-| Groups of the daisyUI `tab` component. `tab-active` and `tab-disabled`
belong on a [`Tab`](#Tab), not here.
-}
type alias TabsConfig =
    { style : Maybe STab.Style
    , size : Maybe STab.Size
    , placement : Maybe STab.Placement
    }


{-| Tabs with no style, size or placement class.
-}
defaultTabsConfig : TabsConfig
defaultTabsConfig =
    { style = Nothing, size = Nothing, placement = Nothing }


{-| A tab strip referenced from somewhere other than `Block.Tabs`, namely
[`CardParts.headerTabs`](#CardParts). The same pair of fields
[`MenuSpec`](#MenuSpec) uses, for the same reason: the block constructor takes
the config and the items as two arguments, and a field cannot.
-}
type alias TabsSpec msg =
    { config : TabsConfig
    , tabs : List (Tab msg)
    }


{-| One tab and the panel it owns.

A tab with an empty `content` owns no panel: `Daisy.Render` then emits the
`tab` alone, with no `tab-content` sibling. That is what makes `tabs-box` usable
as a segmented control (`Day | Month | Year`), where the tabs pick a shape for
something already on the page rather than swapping panels.

`onClick` is what such a control needs and a panel-swapping tab set does not:
daisyUI's own tab CSS shows the panel that follows the active tab with no
JavaScript at all, but a segmented control changes something _outside_ the strip
and has to say so. It is a `Maybe`, so a plain tab set stays exactly what it was.

-}
type alias Tab msg =
    { label : String
    , active : Bool
    , disabled : Bool
    , content : List (Leaf msg)
    , onClick : Maybe msg
    }


{-| The container-level modifiers of the daisyUI `timeline` component.

This deliberately omits `timeline-box`, the way [`ButtonColor`](#ButtonColor)
omits `btn-primary`: daisyUI puts that class on one _side of one item_, so it
is `startBox` / `endBox` on [`TimelineItem`](#TimelineItem) and cannot be
listed here.

-}
type TimelineModifier
    = TimelineSnapIcon
    | TimelineCompact


{-| Every [`TimelineModifier`](#TimelineModifier) value.
-}
allTimelineModifiers : List TimelineModifier
allTimelineModifiers =
    [ TimelineSnapIcon, TimelineCompact ]


{-| Widen a [`TimelineModifier`](#TimelineModifier) to the generated schema
type.
-}
timelineModifierToSchema : TimelineModifier -> STimeline.Modifier
timelineModifierToSchema modifier =
    case modifier of
        TimelineSnapIcon ->
            STimeline.SnapIcon

        TimelineCompact ->
            STimeline.Compact


{-| Groups of the daisyUI `timeline` component.
-}
type alias TimelineConfig =
    { direction : Maybe STimeline.Direction
    , modifiers : List TimelineModifier
    }


{-| A timeline with no direction class.
-}
defaultTimelineConfig : TimelineConfig
defaultTimelineConfig =
    { direction = Nothing, modifiers = [] }


{-| The `timeline-start`, `timeline-middle` and `timeline-end` parts of one
entry.

`startBox` / `endBox` put `timeline-box` on that side of this item, which is
where daisyUI puts it.

-}
type alias TimelineItem msg =
    { start : Maybe String
    , startBox : Bool
    , middle : Maybe (Leaf msg)
    , end : Maybe String
    , endBox : Bool
    }



-- LEAF ----------------------------------------------------------------------


{-| A terminal control or piece of content. A leaf holds only data, never
another node.
-}
type Leaf msg
    = Avatar (AvatarConfig msg) ImageSrc
    | AvatarGroup (List (AvatarItem msg))
    | Badge BadgeConfig String
    | Button (ButtonConfig msg) String
    | Calendar (CalendarConfig msg) CalendarState
    | Checkbox (CheckboxConfig msg)
    | Countdown Float
    | Divider DividerConfig (Maybe String)
    | FileInput (FileInputConfig msg)
    | Filter (FilterData msg)
    | HoverGallery (List ImageSrc)
    | Heading HeadingLevel String
    | Icon IconConfig Icon
    | Image (ImageConfig msg) ImageSrc
    | Input (InputConfig msg)
    | Join JoinConfig (List (JoinItem msg))
    | Kbd KbdConfig String
    | Link (LinkConfig msg) String
    | Loading LoadingConfig
    | Megamenu MegamenuConfig (List (MegamenuItem msg))
    | Otp (OtpConfig msg) OtpData
    | Progress ProgressConfig ProgressData
    | RadialProgress RadialProgressData
    | Radio (RadioConfig msg) RadioData
    | Range (RangeConfig msg) RangeData
    | Rating (RatingConfig msg) RatingData
    | Select (SelectConfig msg) SelectData
    | Skeleton SkeletonConfig
    | Status StatusConfig
    | Swatch SwatchConfig SwatchColor String
    | Swap (SwapConfig msg) SwapFaces
    | Text String
    | TextRotate (List String)
    | Textarea (TextareaConfig msg)
    | ThemeSelect (ThemeSelectData msg)
    | Toggle (ToggleConfig msg) ToggleData
    | UserChip (UserChipConfig msg) UserChipData


{-| The `src` of an image. `Leaf.Image` is not a daisyUI component; it exists
because `card`, `carousel`, `diff`, `stack`, `avatar` and `hover-gallery` all
need one.
-}
type alias ImageSrc =
    String


{-| The rank of a [`Leaf.Heading`](#Leaf).

`Heading` is not a daisyUI component and emits no daisyUI class: it renders a
bare `<h1>` / `<h2>` / `<h3>`, which Tailwind typography styles when the
heading sits inside a `Block.Prose`. It exists because a page otherwise has no
document outline at all — `Leaf.Text` is a text node and `Prose` is a `<div>`.

-}
type HeadingLevel
    = H1
    | H2
    | H3


{-| Groups of the daisyUI `avatar` component plus the `mask`, `dropdown`,
`indicator` and `tooltip` properties.
-}
type alias AvatarConfig msg =
    { modifiers : List SAvatar.Modifier
    , mask : Maybe MaskConfig
    , dropdown : Maybe (Dropdown msg)
    , indicator : Maybe Indicator
    , tooltip : Maybe Tooltip
    }


{-| An avatar with no status dot or mask.
-}
defaultAvatarConfig : AvatarConfig msg
defaultAvatarConfig =
    { modifiers = []
    , mask = Nothing
    , dropdown = Nothing
    , indicator = Nothing
    , tooltip = Nothing
    }


{-| One member of an `avatar-group`.
-}
type alias AvatarItem msg =
    { config : AvatarConfig msg
    , src : ImageSrc
    }


{-| Groups of the daisyUI `badge` component, plus an optional leading glyph.

`icon` is drawn before the label at `size-4`, which is the delta pill every
dashboard puts beside a number (`\u{2191} 10.8%`). It is decorative — the label
beside it is what the badge says — so the `<svg>` is `aria-hidden`, exactly as
a `ButtonConfig.icon` is.

-}
type alias BadgeConfig =
    { icon : Maybe Icon
    , color : Maybe SBadge.Color
    , style : Maybe SBadge.Style
    , size : Maybe SBadge.Size
    , tooltip : Maybe Tooltip
    }


{-| A badge with no glyph, colour, style or size class.
-}
defaultBadgeConfig : BadgeConfig
defaultBadgeConfig =
    { icon = Nothing, color = Nothing, style = Nothing, size = Nothing, tooltip = Nothing }


{-| The colour of a `Button` leaf.

This deliberately omits `Primary`: the only `btn-primary` on a page is
[`Page.cta`](#Page), which uses the schema type directly.

-}
type ButtonColor
    = Neutral
    | Secondary
    | Accent
    | Info
    | Success
    | Warning
    | Error


{-| Every [`ButtonColor`](#ButtonColor) value.
-}
allButtonColors : List ButtonColor
allButtonColors =
    [ Neutral, Secondary, Accent, Info, Success, Warning, Error ]


{-| Widen a [`ButtonColor`](#ButtonColor) to the generated schema type.
-}
buttonColorToSchema : ButtonColor -> SButton.Color
buttonColorToSchema color =
    case color of
        Neutral ->
            SButton.Neutral

        Secondary ->
            SButton.Secondary

        Accent ->
            SButton.Accent

        Info ->
            SButton.Info

        Success ->
            SButton.Success

        Warning ->
            SButton.Warning

        Error ->
            SButton.Error


{-| Groups of the daisyUI `button` component, with the tree's narrowed colour
type, plus the `tooltip`, `dropdown`, `indicator` and `aura` properties and the
click handler.

`icon` is an optional leading [`Daisy.Icon.Icon`](Daisy-Icon#Icon), drawn at
`size-4` before the label and `aria-hidden`, because the label beside it is
already the button's accessible name.

`ariaLabel` is for the **icon-only** button — `Button { defaultButtonConfig |
icon = Just Icon.Eye, ariaLabel = Just "View order" } ""`. Without it such a
button has no accessible name at all, which axe reports as a critical
`button-name` violation. It is the same field, with the same meaning, that
`SelectConfig`, `InputConfig` and the other bare controls carry.

-}
type alias ButtonConfig msg =
    { color : Maybe ButtonColor
    , icon : Maybe Icon
    , ariaLabel : Maybe String
    , style : Maybe SButton.Style
    , size : Maybe SButton.Size
    , modifiers : List SButton.Modifier
    , behaviors : List SButton.Behavior
    , tooltip : Maybe Tooltip
    , dropdown : Maybe (Dropdown msg)
    , indicator : Maybe Indicator
    , aura : Maybe AuraConfig
    , onClick : Maybe msg
    }


{-| A plain button.

    Button defaultButtonConfig "Save"

-}
defaultButtonConfig : ButtonConfig msg
defaultButtonConfig =
    { color = Nothing
    , icon = Nothing
    , ariaLabel = Nothing
    , style = Nothing
    , size = Nothing
    , modifiers = []
    , behaviors = []
    , tooltip = Nothing
    , dropdown = Nothing
    , indicator = Nothing
    , aura = Nothing
    , onClick = Nothing
    }


{-| Everything the calendar picker needs that is not its own state.

The leaf is a typed front for the pure-Elm package `alexbruf/elm-cally`, a
port of the Cally web component that renders the same markup and the same
`part` attributes in the light DOM — which is exactly what daisyUI's
`calendar.css` styles through its `cally` class. No ports, no custom element
registration, no shadow DOM.

`Daisy.Render` builds elm-cally's own `Config` record from this one; it is
never exposed raw, the same way `Daisy.Chart` hides `terezka/elm-charts`.

**The update flow.** A calendar is the second stateful leaf after
[`ThemeSelect`](#Leaf), and the only one whose state the application must
store, because a date picker remembers which day holds the roving `tabindex`
and which month is on screen:

1.  Keep a [`CalendarState`](#CalendarState) in your `Model`, built once with
    `Daisy.Render.initCalendarRange` (or `initCalendarDate` /
    `initCalendarMulti`).
2.  Give `toMsg` a constructor of your own `Msg` that carries a
    [`CalendarMsg`](#CalendarMsg), and forward it in `update` to
    `Daisy.Render.updateCalendar`, storing the state it returns and running
    the `Cmd` it returns (that command carries the picker's own
    `Browser.Dom.focus` call, so keyboard navigation needs it).
3.  `onChange` fires with a [`CalendarValue`](#CalendarValue) whenever the
    selection changes; store that too if you want to show it.
4.  Rebuild `Leaf.Calendar config state` from the model on every `view`. The
    leaf is data, so nothing is retained between renders.

`id` prefixes every DOM id the picker renders (day buttons, the two paging
buttons), so it must be unique on the page and stable across renders.

-}
type alias CalendarConfig msg =
    { id : String
    , today : Date
    , locale : CalendarLocale
    , months : CalendarMonths
    , toMsg : CalendarMsg -> msg
    , onChange : CalendarValue -> msg
    }


{-| A calendar in `EnGB` showing one month.

Unlike every other `defaultXConfig` this is a function, not a value: a picker
cannot exist without an `id`, a `today` and somewhere to send its messages,
and elm-cally's own `defaultConfig` takes the same four.

-}
defaultCalendarConfig :
    { id : String
    , today : Date
    , toMsg : CalendarMsg -> msg
    , onChange : CalendarValue -> msg
    }
    -> CalendarConfig msg
defaultCalendarConfig given =
    { id = given.id
    , today = given.today
    , locale = EnGB
    , months = OneMonth
    , toMsg = given.toMsg
    , onChange = given.onChange
    }


{-| The two locales `alexbruf/elm-cally` bundles. Elm has no `Intl`, so a
locale is a table of formatting functions rather than a language tag, and the
package ships exactly these two; a closed type keeps an unbuildable one from
being asked for.
-}
type CalendarLocale
    = EnGB
    | EnUS


{-| How many month grids the picker shows, and therefore how far its previous
and next buttons page.

This is a closed pair rather than an `Int` for the usual reason: `months = 13`
is not a calendar anyone means, and the renderer would have to decide what to
do with it. `TwoMonths` puts the two grids side by side from `sm` up and in one
column below it: elm-cally's `[part~="months"]` is a bare `<div>` and daisyUI's
`calendar.css` has no `months` rule, so the layout comes from `Daisy.Render`'s
own token table (see `Daisy.Render.calendarMonths`).

-}
type CalendarMonths
    = OneMonth
    | TwoMonths


{-| What the picker selects, and everything it remembers for itself.

The three constructors are the three pickers elm-cally provides, and each one
carries that picker's `Value` and `Model` as opaque data — the same way
`Leaf.ThemeSelect` carries the current `Theme`. Build one with
`Daisy.Render.initCalendarDate` / `initCalendarRange` / `initCalendarMulti`
and hand it back to `Daisy.Render.updateCalendar`; nothing else can construct
the `Model` inside, so the picker's invariants stay elm-cally's business.

-}
type CalendarState
    = SelectDate CallyDate.Value CallyDate.Model
    | SelectRange CallyRange.Value CallyRange.Model
    | SelectMulti CallyMulti.Value CallyMulti.Model


{-| The selection `CalendarConfig.onChange` reports, one constructor per
[`CalendarState`](#CalendarState) constructor. A range is always sorted.
-}
type CalendarValue
    = PickedDate (Maybe Date)
    | PickedRange (Maybe ( Date, Date ))
    | PickedDates (List Date)


{-| One of the picker's own messages, on its way back to
`Daisy.Render.updateCalendar`. The payloads are elm-cally's opaque `Msg`
types, so an application can route one but cannot invent one.
-}
type CalendarMsg
    = CalendarDateMsg CallyDate.Msg
    | CalendarRangeMsg CallyRange.Msg
    | CalendarMultiMsg CallyMulti.Msg


{-| Write the selection `CalendarConfig.onChange` reported back into the
state, so the next render draws it.

`Daisy.Render.updateCalendar` advances everything the picker remembers for
_itself_ (the focused day and the page on screen); the value is the
application's, which is why it comes back as its own message and goes back in
through this function. A value of a different kind than the state is a no-op:
one `Leaf.Calendar` only ever produces one kind.

-}
setCalendarValue : CalendarValue -> CalendarState -> CalendarState
setCalendarValue value state =
    case ( value, state ) of
        ( PickedDate new, SelectDate _ model ) ->
            SelectDate new model

        ( PickedRange new, SelectRange _ model ) ->
            SelectRange new model

        ( PickedDates new, SelectMulti _ model ) ->
            SelectMulti new model

        _ ->
            state


{-| Groups of the daisyUI `checkbox` component.
-}
type alias CheckboxConfig msg =
    { color : Maybe SCheckbox.Color
    , size : Maybe SCheckbox.Size
    , checked : Bool
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| An unchecked checkbox with no colour or size class.
-}
defaultCheckboxConfig : CheckboxConfig msg
defaultCheckboxConfig =
    { color = Nothing
    , size = Nothing
    , checked = False
    , ariaLabel = Nothing
    , tooltip = Nothing
    , onCheck = Nothing
    }


{-| Groups of the daisyUI `divider` component.
-}
type alias DividerConfig =
    { color : Maybe SDivider.Color
    , direction : Maybe SDivider.Direction
    , placement : Maybe SDivider.Placement
    , tooltip : Maybe Tooltip
    }


{-| A divider with no colour, direction or placement class.
-}
defaultDividerConfig : DividerConfig
defaultDividerConfig =
    { color = Nothing, direction = Nothing, placement = Nothing, tooltip = Nothing }


{-| Groups of the daisyUI `file-input` component.
-}
type alias FileInputConfig msg =
    { color : Maybe SFileInput.Color
    , style : Maybe SFileInput.Style
    , size : Maybe SFileInput.Size
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| A file input with no colour, style or size class.
-}
defaultFileInputConfig : FileInputConfig msg
defaultFileInputConfig =
    { color = Nothing
    , style = Nothing
    , size = Nothing
    , ariaLabel = Nothing
    , tooltip = Nothing
    , onInput = Nothing
    }


{-| A `filter`: a radio group styled as buttons, plus an optional reset
control. daisyUI's `filter` declares no class groups, so this is all data.
-}
type alias FilterData msg =
    { name : String
    , options : List String
    , selected : Maybe String
    , reset : Maybe FilterReset
    , onSelect : Maybe (String -> msg)
    }


{-| How a `filter`'s reset control is drawn.

daisyUI has two idioms and the class set differs between them. `ResetPart`
carries the `filter-reset` part, which is what a filter outside a `<form>`
needs. `ResetButton` is the plain `btn` a filter _inside_ a real `<form>` uses
(daisyUI's own examples make it `btn-square`), where the browser's form reset
does the work and no part class is involved.

-}
type FilterReset
    = ResetPart
    | ResetButton (List SButton.Modifier)


{-| How big a [`Leaf.Icon`](#Leaf) is drawn.

Three fixed steps, not a free length: an icon's size is a layout decision and
`Daisy.Render` owns those. They map to the `size-4` / `size-5` / `size-6`
entries of `Daisy.Render.tokens`.

-}
type IconSize
    = IconSm
    | IconMd
    | IconLg


{-| Everything a [`Leaf.Icon`](#Leaf) needs beyond the drawing itself.

`label` is the icon's accessible name. With `Nothing` the `<svg>` is
`aria-hidden`, which is right for an icon that sits beside its own text (a
sidebar entry, a labelled button). With `Just` it becomes `role="img"` plus
that `aria-label`, which is what gives an **icon-only** control a name — a
`Leaf.Button` whose label is empty has no accessible name otherwise, and axe
reports that as a critical `button-name` violation.

`Icon` is not a daisyUI component and emits no daisyUI class, exactly like
[`Leaf.Heading`](#HeadingLevel) and [`Leaf.Image`](#Leaf).

-}
type alias IconConfig =
    { size : IconSize
    , label : Maybe String
    }


{-| A decorative icon at the middle size: `size-5`, `aria-hidden`.
-}
defaultIconConfig : IconConfig
defaultIconConfig =
    { size = IconMd, label = Nothing }


{-| The `mask` and `hover-3d` properties of an image, plus its alt text.
-}
type alias ImageConfig msg =
    { alt : String
    , mask : Maybe MaskConfig
    , hover3d : Bool
    , tooltip : Maybe Tooltip
    , onClick : Maybe msg
    }


{-| A plain image with empty alt text.
-}
defaultImageConfig : ImageConfig msg
defaultImageConfig =
    { alt = "", mask = Nothing, hover3d = False, tooltip = Nothing, onClick = Nothing }


{-| What an `input` accepts. Rendered as the `type` attribute, which is half
of what makes daisyUI's `validator` class do anything: the styling hangs off
`:user-invalid`, and only a real constraint can make a control invalid.
-}
type InputType
    = InputText
    | InputEmail
    | InputPassword
    | InputNumber
    | InputUrl
    | InputTel
    | InputSearch
    | InputDate
    | InputColor


{-| Groups of the daisyUI `input` component, plus the HTML validation
constraints daisyUI's `validator` / `validator-hint` pair needs.

`inputType`, `required`, `pattern`, `minLength` and `maxLength` are rendered as
the matching HTML attributes. Without at least one of them a `Field` marked
`validate = True` can never become `:user-invalid`, so its hint would never
show.

`pattern` is a regular expression (the HTML `pattern` attribute), never a class.

`icon` is a leading [`Daisy.Icon.Icon`](Daisy-Icon#Icon). It switches the
renderer to the wrapper form daisyUI's own docs use for a decorated field —
`<label class="input"><svg/><input/></label>` — where the component class is on
the label and the `<input>` inside it is bare. Without an icon the markup is the
plain `<input class="input">` it has always been.

-}
type alias InputConfig msg =
    { color : Maybe SInput.Color
    , style : Maybe SInput.Style
    , size : Maybe SInput.Size
    , icon : Maybe Icon
    , placeholder : String
    , value : String
    , inputType : InputType
    , required : Bool
    , pattern : Maybe String
    , minLength : Maybe Int
    , maxLength : Maybe Int
    , ariaLabel : Maybe String
    , indicator : Maybe Indicator
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| An empty, unconstrained text input with no colour, style or size class.
-}
defaultInputConfig : InputConfig msg
defaultInputConfig =
    { color = Nothing
    , style = Nothing
    , size = Nothing
    , icon = Nothing
    , placeholder = ""
    , value = ""
    , inputType = InputText
    , required = False
    , pattern = Nothing
    , minLength = Nothing
    , maxLength = Nothing
    , ariaLabel = Nothing
    , indicator = Nothing
    , tooltip = Nothing
    , onInput = Nothing
    }


{-| Groups of the daisyUI `join` component.
-}
type alias JoinConfig =
    { direction : Maybe SJoin.Direction
    , tooltip : Maybe Tooltip
    }


{-| A join with no direction class.
-}
defaultJoinConfig : JoinConfig
defaultJoinConfig =
    { direction = Nothing, tooltip = Nothing }


{-| What a `join` may group. A closed list, so `Leaf` stays non-recursive.
-}
type JoinItem msg
    = JoinButton (ButtonConfig msg) String
    | JoinInput (InputConfig msg)
    | JoinSelect (SelectConfig msg) SelectData
    | JoinText String


{-| Groups of the daisyUI `kbd` component.
-}
type alias KbdConfig =
    { size : Maybe SKbd.Size
    , tooltip : Maybe Tooltip
    }


{-| A kbd with no size class.
-}
defaultKbdConfig : KbdConfig
defaultKbdConfig =
    { size = Nothing, tooltip = Nothing }


{-| Groups of the daisyUI `link` component.
-}
type alias LinkConfig msg =
    { color : Maybe SLink.Color
    , style : Maybe SLink.Style
    , href : String
    , dropdown : Maybe (Dropdown msg)
    , indicator : Maybe Indicator
    , tooltip : Maybe Tooltip
    , onClick : Maybe msg
    }


{-| A link to `"#"` with no colour or style class.
-}
defaultLinkConfig : LinkConfig msg
defaultLinkConfig =
    { color = Nothing
    , style = Nothing
    , href = "#"
    , dropdown = Nothing
    , indicator = Nothing
    , tooltip = Nothing
    , onClick = Nothing
    }


{-| Groups of the daisyUI `loading` component.
-}
type alias LoadingConfig =
    { style : Maybe SLoading.Style
    , size : Maybe SLoading.Size
    , tooltip : Maybe Tooltip
    }


{-| A loading indicator with no style or size class.
-}
defaultLoadingConfig : LoadingConfig
defaultLoadingConfig =
    { style = Nothing, size = Nothing, tooltip = Nothing }


{-| Groups of the daisyUI `megamenu` component.
-}
type alias MegamenuConfig =
    { size : Maybe SMegamenu.Size
    , direction : Maybe SMegamenu.Direction
    , modifiers : List SMegamenu.Modifier
    , tooltip : Maybe Tooltip
    }


{-| A megamenu with no size, direction or width class.
-}
defaultMegamenuConfig : MegamenuConfig
defaultMegamenuConfig =
    { size = Nothing, direction = Nothing, modifiers = [], tooltip = Nothing }


{-| One labelled panel of a megamenu. `active = True` emits the
`megamenu-active` part.
-}
type alias MegamenuItem msg =
    { label : String
    , active : Bool
    , menu : MenuSpec msg
    }


{-| Groups of the daisyUI `otp` component.
-}
type alias OtpConfig msg =
    { color : Maybe SOtp.Color
    , size : Maybe SOtp.Size
    , modifiers : List SOtp.Modifier
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| A one-time-code input with no colour or size class.
-}
defaultOtpConfig : OtpConfig msg
defaultOtpConfig =
    { color = Nothing, size = Nothing, modifiers = [], tooltip = Nothing, onInput = Nothing }


{-| How many boxes an `otp` has.
-}
type alias OtpData =
    { digits : Int }


{-| Groups of the daisyUI `progress` component.
-}
type alias ProgressConfig =
    { color : Maybe SProgress.Color
    , tooltip : Maybe Tooltip
    }


{-| A progress bar with no colour class.
-}
defaultProgressConfig : ProgressConfig
defaultProgressConfig =
    { color = Nothing, tooltip = Nothing }


{-| The value of a progress bar. `Nothing` renders the indeterminate state.
-}
type alias ProgressData =
    { value : Maybe Float
    , max : Float
    }


{-| The value and centre label of a `radial-progress`. Its size and thickness
are CSS variables, not classes, so there is no config — which is why the
accessible name is a field here rather than on one.

`ariaLabel` is that name. `Daisy.Render` gives the element
`role="progressbar"`, and a `progressbar` takes **no** name from its content,
so a dial with only a number in it is an unnamed control (axe's
`aria-progressbar-name`, serious). `Nothing` falls back to `label`, which is at
least the value the dial shows; a real page says what is being measured.

-}
type alias RadialProgressData =
    { value : Float
    , label : String
    , ariaLabel : Maybe String
    }


{-| Groups of the daisyUI `radio` component.
-}
type alias RadioConfig msg =
    { color : Maybe SRadio.Color
    , size : Maybe SRadio.Size
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| A radio with no colour or size class.
-}
defaultRadioConfig : RadioConfig msg
defaultRadioConfig =
    { color = Nothing, size = Nothing, ariaLabel = Nothing, tooltip = Nothing, onCheck = Nothing }


{-| The group name of a radio and whether it is selected.
-}
type alias RadioData =
    { name : String
    , checked : Bool
    }


{-| Groups of the daisyUI `range` component.
-}
type alias RangeConfig msg =
    { color : Maybe SRange.Color
    , size : Maybe SRange.Size
    , direction : Maybe SRange.Direction
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| A range with no colour, size or direction class.
-}
defaultRangeConfig : RangeConfig msg
defaultRangeConfig =
    { color = Nothing
    , size = Nothing
    , direction = Nothing
    , ariaLabel = Nothing
    , tooltip = Nothing
    , onInput = Nothing
    }


{-| The bounds and value of a range.
-}
type alias RangeData =
    { min : Float
    , max : Float
    , value : Float
    }


{-| The container-level modifiers of the daisyUI `rating` component.

This omits `rating-hidden` the way [`TimelineModifier`](#TimelineModifier)
omits `timeline-box`: daisyUI puts it on the rating's _first, blank_ radio, so
it is `clearable` on [`RatingData`](#RatingData).

`RatingHalf` also drives the item masks: with it the renderer alternates
`mask-half-1` / `mask-half-2` across the radios, which is the only way daisyUI's
half-star rating works.

-}
type RatingModifier
    = RatingHalf


{-| Every [`RatingModifier`](#RatingModifier) value.
-}
allRatingModifiers : List RatingModifier
allRatingModifiers =
    [ RatingHalf ]


{-| Widen a [`RatingModifier`](#RatingModifier) to the generated schema type.
-}
ratingModifierToSchema : RatingModifier -> SRating.Modifier
ratingModifierToSchema modifier =
    case modifier of
        RatingHalf ->
            SRating.Half


{-| Groups of the daisyUI `rating` component.

`shape` is the `mask-*` clip-path each radio wears. `Nothing` keeps the
renderer's default (`mask-star-2`), which is what daisyUI's own rating examples
use most.

-}
type alias RatingConfig msg =
    { size : Maybe SRating.Size
    , modifiers : List RatingModifier
    , shape : Maybe SMask.Style
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onRate : Maybe (Int -> msg)
    }


{-| A rating of default-shaped stars with no size class.
-}
defaultRatingConfig : RatingConfig msg
defaultRatingConfig =
    { size = Nothing
    , modifiers = []
    , shape = Nothing
    , ariaLabel = Nothing
    , tooltip = Nothing
    , onRate = Nothing
    }


{-| The group name, number of stars and current value of a rating.

`clearable = True` puts daisyUI's blank `rating-hidden` radio first, so the
rating can be set back to "no stars".

-}
type alias RatingData =
    { name : String
    , count : Int
    , value : Int
    , clearable : Bool
    }


{-| Groups of the daisyUI `select` component.
-}
type alias SelectConfig msg =
    { color : Maybe SSelect.Color
    , style : Maybe SSelect.Style
    , size : Maybe SSelect.Size
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onSelect : Maybe (String -> msg)
    }


{-| A select with no colour, style or size class.
-}
defaultSelectConfig : SelectConfig msg
defaultSelectConfig =
    { color = Nothing
    , style = Nothing
    , size = Nothing
    , ariaLabel = Nothing
    , tooltip = Nothing
    , onSelect = Nothing
    }


{-| The options of a select and which one is chosen.
-}
type alias SelectData =
    { options : List String
    , selected : Maybe String
    }


{-| Groups of the daisyUI `skeleton` component.
-}
type alias SkeletonConfig =
    { modifiers : List SSkeleton.Modifier
    , tooltip : Maybe Tooltip
    }


{-| A block skeleton.
-}
defaultSkeletonConfig : SkeletonConfig
defaultSkeletonConfig =
    { modifiers = [], tooltip = Nothing }


{-| Groups of the daisyUI `status` component.
-}
type alias StatusConfig =
    { color : Maybe SStatus.Color
    , size : Maybe SStatus.Size
    , tooltip : Maybe Tooltip
    }


{-| A status dot with no colour or size class.
-}
defaultStatusConfig : StatusConfig
defaultStatusConfig =
    { color = Nothing, size = Nothing, tooltip = Nothing }


{-| One slot of a theme's palette, as a filled chip.

A theme editor has to _show_ the colour it is editing, and daisyUI has no
component for that: every one of its colour classes belongs to a control. The
chip is therefore painted with the two Tailwind utilities that read the theme's
own variables — `bg-primary` and `text-primary-content` for
[`SwatchPrimary`](#SwatchColor), and so on — which `Daisy.Render` holds as named
tokens like every other utility it emits. Nothing here is a class the caller
chooses: the constructor names the slot, and the renderer knows the pair.

`label` is the text drawn on the chip (daisyUI's own generator draws an `A`, to
show the content colour reading on the surface colour). It may be empty.

-}
type alias SwatchConfig =
    { ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    }


{-| A swatch with no accessible name of its own — right when the chip sits
inside a `Field` that already labels it, or beside text that names the colour.
-}
defaultSwatchConfig : SwatchConfig
defaultSwatchConfig =
    { ariaLabel = Nothing, tooltip = Nothing }


{-| Which of a theme's twenty colour variables a [`Leaf.Swatch`](#Leaf) paints.

Eleven slots, not twenty: a swatch shows a _surface_ and puts its matching
content colour on top, so `base-content` and the eight `*-content` colours are
reached as the foreground of the surface they belong to rather than as surfaces
of their own. `base-100`, `base-200` and `base-300` share `base-content`, which
is exactly what daisyUI's palette says.

-}
type SwatchColor
    = SwatchBase100
    | SwatchBase200
    | SwatchBase300
    | SwatchPrimary
    | SwatchSecondary
    | SwatchAccent
    | SwatchNeutral
    | SwatchInfo
    | SwatchSuccess
    | SwatchWarning
    | SwatchError


{-| Every [`SwatchColor`](#SwatchColor), in daisyUI's palette order.
-}
allSwatchColors : List SwatchColor
allSwatchColors =
    [ SwatchBase100
    , SwatchBase200
    , SwatchBase300
    , SwatchPrimary
    , SwatchSecondary
    , SwatchAccent
    , SwatchNeutral
    , SwatchInfo
    , SwatchSuccess
    , SwatchWarning
    , SwatchError
    ]


{-| Groups of the daisyUI `swap` component.
-}
type alias SwapConfig msg =
    { style : Maybe SSwap.Style
    , modifiers : List SSwap.Modifier
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| A swap with no rotate or flip class.
-}
defaultSwapConfig : SwapConfig msg
defaultSwapConfig =
    { style = Nothing, modifiers = [], tooltip = Nothing, onCheck = Nothing }


{-| The `swap-on`, `swap-off` and `swap-indeterminate` faces.
-}
type alias SwapFaces =
    { on : String
    , off : String
    , indeterminate : Maybe String
    }


{-| Groups of the daisyUI `textarea` component.
-}
type alias TextareaConfig msg =
    { color : Maybe STextarea.Color
    , style : Maybe STextarea.Style
    , size : Maybe STextarea.Size
    , placeholder : String
    , value : String
    , required : Bool
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| An empty, optional textarea with no colour, style or size class.
-}
defaultTextareaConfig : TextareaConfig msg
defaultTextareaConfig =
    { color = Nothing
    , style = Nothing
    , size = Nothing
    , placeholder = ""
    , value = ""
    , required = False
    , ariaLabel = Nothing
    , tooltip = Nothing
    , onInput = Nothing
    }


{-| How a `theme-controller` is presented. daisyUI's docs examples (toggle,
checkbox, radio group, select, swap, dropdown) are presentations of one
control, not separate components.

`ThemeAsDropdown` and `ThemeAsIconDropdown` are the compact ones: every other
presentation renders one sibling control per theme, which is 35 controls wide
with `allThemes`.

`ThemeAsDropdown` renders daisyUI's documented "Using a dropdown" markup — a
bare `btn` trigger reading "Theme" and a `dropdown-content` list of
`theme-controller` radios — and `tests/CorpusTest` compares that trigger with
the docs example class for class, so it cannot be restyled.

`ThemeAsIconDropdown` is the same dropdown with the trigger daisyUI's own
dashboard templates use: `btn btn-ghost btn-circle` around a palette glyph, named
by `aria-label` because it carries no text. It is a second constructor rather
than a field on the first for exactly that reason — the corpus fixture pins one
of the two markups, and a flag would have made that fixture depend on the flag.

-}
type ThemePresentation
    = ThemeAsSelect
    | ThemeAsRadios
    | ThemeAsToggle
    | ThemeAsCheckbox
    | ThemeAsSwap
    | ThemeAsDropdown
    | ThemeAsIconDropdown


{-| A theme switcher. `theme-controller` declares no class groups, so this is
all data. `Page.theme` supplies the initial `data-theme`; this control changes
it.
-}
type alias ThemeSelectData msg =
    { themes : List Theme
    , current : Theme
    , presentation : ThemePresentation
    , onSelect : Maybe (Theme -> msg)
    }


{-| Groups of the daisyUI `toggle` component.
-}
type alias ToggleConfig msg =
    { color : Maybe SToggle.Color
    , size : Maybe SToggle.Size
    , ariaLabel : Maybe String
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| A toggle with no colour or size class.
-}
defaultToggleConfig : ToggleConfig msg
defaultToggleConfig =
    { color = Nothing, size = Nothing, ariaLabel = Nothing, tooltip = Nothing, onCheck = Nothing }


{-| Whether a toggle is on.
-}
type alias ToggleData =
    { checked : Bool }


{-| Who is signed in: a portrait, a name and one line under it.

A dashboard's navbar and its sidebar footer both show this, and it is the one
shape the tree could not express — `Leaf` is terminal, so two stacked lines of
text beside an image needs either a container leaf (which would open the tree up
to arbitrary layout) or a named composite. This is the named composite: three
strings in, one fixed piece of markup out, no layout decision left to the
caller.

-}
type alias UserChipData =
    { avatar : ImageSrc
    , name : String
    , subtitle : String
    }


{-| The properties of a [`Leaf.UserChip`](#Leaf).

`boxed` paints the chip as a panel on the surface below it — the shaded card a
sidebar footer sits in. A navbar chip leaves it `False` and reads as plain
chrome.

-}
type alias UserChipConfig msg =
    { boxed : Bool
    , onClick : Maybe msg
    , dropdown : Maybe (Dropdown msg)
    , tooltip : Maybe Tooltip
    }


{-| An unboxed, inert user chip.
-}
defaultUserChipConfig : UserChipConfig msg
defaultUserChipConfig =
    { boxed = False
    , onClick = Nothing
    , dropdown = Nothing
    , tooltip = Nothing
    }



-- LEAF PROPERTIES -----------------------------------------------------------


{-| A tooltip attached to one leaf.
-}
type alias Tooltip =
    { text : String
    , config : TooltipConfig
    }


{-| Groups of the daisyUI `tooltip` component.
-}
type alias TooltipConfig =
    { color : Maybe STooltip.Color
    , placement : Maybe STooltip.Placement
    , modifiers : List STooltip.Modifier
    }


{-| A tooltip with no colour or placement class.
-}
defaultTooltipConfig : TooltipConfig
defaultTooltipConfig =
    { color = Nothing, placement = Nothing, modifiers = [] }


{-| A [`Tooltip`](#Tooltip) with default styling.

    tooltip "Delete this row"

-}
tooltip : String -> Tooltip
tooltip text =
    { text = text, config = defaultTooltipConfig }


{-| A dropdown attached to one leaf. Its content is always a menu, so the
`dropdown-content` part can never appear without an anchor.
-}
type alias Dropdown msg =
    { config : DropdownConfig
    , menu : MenuSpec msg
    }


{-| Groups of the daisyUI `dropdown` component.
-}
type alias DropdownConfig =
    { placement : Maybe SDropdown.Placement
    , modifiers : List SDropdown.Modifier
    }


{-| A dropdown with no placement class.
-}
defaultDropdownConfig : DropdownConfig
defaultDropdownConfig =
    { placement = Nothing, modifiers = [] }


{-| An indicator attached to one leaf.
-}
type alias Indicator =
    { config : IndicatorConfig
    , payload : IndicatorPayload
    }


{-| Groups of the daisyUI `indicator` component.
-}
type alias IndicatorConfig =
    { placement : Maybe SIndicator.Placement }


{-| An indicator with no placement class.
-}
defaultIndicatorConfig : IndicatorConfig
defaultIndicatorConfig =
    { placement = Nothing }


{-| What sits in the `indicator-item`.
-}
type IndicatorPayload
    = IndicatorBadge BadgeConfig String
    | IndicatorStatus StatusConfig


{-| Groups of the daisyUI `mask` component. A clip-path shape applied to one
existing element.
-}
type alias MaskConfig =
    { style : Maybe SMask.Style
    , modifiers : List SMask.Modifier
    }


{-| A mask with no shape class.
-}
defaultMaskConfig : MaskConfig
defaultMaskConfig =
    { style = Nothing, modifiers = [] }


{-| Groups of the daisyUI `aura` component. A decorative border light around one
existing element.
-}
type alias AuraConfig =
    { style : Maybe SAura.Style
    , size : Maybe SAura.Size
    }


{-| An aura with no style or size class.
-}
defaultAuraConfig : AuraConfig
defaultAuraConfig =
    { style = Nothing, size = Nothing }



-- OVERLAY -------------------------------------------------------------------


{-| The only three components that may float over the page. They live in
`Page.overlays` and nowhere else, and the renderer draws them after every
section in one fixed wrapper, in the order drawer, modal, toast.
-}
type Overlay msg
    = Modal (ModalConfig msg) (List (Block msg))
    | Drawer DrawerConfig (List (Section msg))
    | Toast ToastConfig (List (Block msg))


{-| Groups of the daisyUI `modal` component. `actions` is rendered into the
`modal-action` part, so a modal's buttons cannot drift out of it.

`onClose` is fired when the browser closes the dialog: pressing `Escape`, or
the native `close` event. The renderer draws the modal with daisyUI's
recommended dialog method (`<dialog class="modal">`), which is what makes
`Escape` and the focus trap work at all; the application still owns
visibility through `SModal.Open`, and `onClose` is how it learns to drop it.

-}
type alias ModalConfig msg =
    { placement : Maybe SModal.Placement
    , modifiers : List SModal.Modifier
    , id : String
    , title : Maybe String
    , actions : List (Leaf msg)
    , onClose : Maybe msg
    }


{-| A closed, untitled modal with the id `"daisy-modal"` that reports nothing
when it closes.
-}
defaultModalConfig : ModalConfig msg
defaultModalConfig =
    { placement = Nothing
    , modifiers = []
    , id = "daisy-modal"
    , title = Nothing
    , actions = []
    , onClose = Nothing
    }


{-| Groups of the daisyUI `drawer` component. The `variant` group
(`is-drawer-open:` / `is-drawer-close:`) is a pair of selector prefixes, not
classes an element can carry, so it has no field here.
-}
type alias DrawerConfig =
    { placement : Maybe SDrawer.Placement
    , modifiers : List SDrawer.Modifier
    , id : String
    , toggleLabel : String
    }


{-| A closed drawer with the id `"daisy-drawer"`.
-}
defaultDrawerConfig : DrawerConfig
defaultDrawerConfig =
    { placement = Nothing, modifiers = [], id = "daisy-drawer", toggleLabel = "Open" }


{-| Groups of the daisyUI `toast` component.
-}
type alias ToastConfig =
    { placement : Maybe SToast.Placement }


{-| A toast in daisyUI's default corner.
-}
defaultToastConfig : ToastConfig
defaultToastConfig =
    { placement = Nothing }



-- FIXED CHROME --------------------------------------------------------------


{-| A viewport-fixed bottom navigation bar. It is a field on `Page` rather than
a section, because in a section it would overlap the content it sits on.
-}
type alias Dock msg =
    { config : DockConfig
    , items : List (DockItem msg)
    }


{-| Groups of the daisyUI `dock` component. Its single modifier (`dock-active`)
belongs on an item, so it is a flag on [`DockItem`](#DockItem).
-}
type alias DockConfig =
    { size : Maybe SDock.Size }


{-| A dock with no size class.
-}
defaultDockConfig : DockConfig
defaultDockConfig =
    { size = Nothing }


{-| One dock button. Its `label` becomes the `dock-label` part.
-}
type alias DockItem msg =
    { icon : Maybe String
    , label : String
    , active : Bool
    , onClick : Maybe msg
    }


{-| A viewport-fixed floating action button, with the `fab-main-action` and
`fab-close` parts.

`main` is the trigger the user sees when the fab is closed. `mainAction` is the
separate button daisyUI marks `fab-main-action`, which stays in place once the
speed dial is open; the part class goes on that leaf itself, which is where
every daisyUI example puts it.

-}
type alias Fab msg =
    { config : FabConfig
    , main : Leaf msg
    , mainAction : Maybe (Leaf msg)
    , actions : List (Leaf msg)
    , close : Maybe (Leaf msg)
    }


{-| Groups of the daisyUI `fab` component.
-}
type alias FabConfig =
    { modifiers : List SFab.Modifier }


{-| A fab with no flower class.
-}
defaultFabConfig : FabConfig
defaultFabConfig =
    { modifiers = [] }
