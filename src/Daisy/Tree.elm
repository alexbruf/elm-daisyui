module Daisy.Tree exposing
    ( Page(..), Sections(..), Shell(..), Cta, cta
    , Theme(..), allThemes, themeToString
    , Section(..)
    , HeroConfig, defaultHeroConfig
    , NavbarParts, emptyNavbarParts
    , FooterConfig, defaultFooterConfig
    , GridConfig, defaultGridConfig, GridColumns(..)
    , StackConfig, defaultStackConfig, Align(..)
    , Block(..)
    , AccordionConfig, defaultAccordionConfig, AccordionItem
    , AlertConfig, defaultAlertConfig
    , CardConfig, defaultCardConfig, CardParts, emptyCardParts
    , CarouselConfig, defaultCarouselConfig, CarouselItem, CarouselSnap(..)
    , ChatMessage
    , CollapseConfig, defaultCollapseConfig, CollapseParts
    , DiffParts
    , Fieldset, Field, LabelPlacement(..), field
    , ListConfig, defaultListConfig, ListRow
    , MenuConfig, defaultMenuConfig, MenuItem(..), MenuBadge, MenuSpec, menuItem
    , MockupBrowserParts, MockupPhoneParts, MockupWindowParts, CodeLine
    , NavConfig, defaultNavConfig
    , PaginationConfig, defaultPaginationConfig, PaginationData
    , StackedConfig, defaultStackedConfig, StackedAlign(..)
    , StatConfig, defaultStatConfig, StatItem, emptyStatItem
    , StepsConfig, defaultStepsConfig, Step
    , TableConfig, defaultTableConfig, Row
    , TabsConfig, defaultTabsConfig, Tab
    , TimelineConfig, defaultTimelineConfig, TimelineItem
    , Leaf(..), ImageSrc
    , AvatarConfig, defaultAvatarConfig, AvatarItem
    , BadgeConfig, defaultBadgeConfig
    , ButtonConfig, defaultButtonConfig, ButtonColor(..), allButtonColors, buttonColorToSchema
    , CheckboxConfig, defaultCheckboxConfig
    , DividerConfig, defaultDividerConfig
    , FileInputConfig, defaultFileInputConfig
    , FilterData
    , ImageConfig, defaultImageConfig
    , InputConfig, defaultInputConfig
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
    , RatingConfig, defaultRatingConfig, RatingData
    , SelectConfig, defaultSelectConfig, SelectData
    , SkeletonConfig, defaultSkeletonConfig
    , StatusConfig, defaultStatusConfig
    , SwapConfig, defaultSwapConfig, SwapFaces
    , TextareaConfig, defaultTextareaConfig
    , ThemeSelectData, ThemePresentation(..)
    , ToggleConfig, defaultToggleConfig, ToggleData
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

@docs Page, Sections, Shell, Cta, cta


# Theme

@docs Theme, allThemes, themeToString


# Sections

@docs Section
@docs HeroConfig, defaultHeroConfig
@docs NavbarParts, emptyNavbarParts
@docs FooterConfig, defaultFooterConfig
@docs GridConfig, defaultGridConfig, GridColumns
@docs StackConfig, defaultStackConfig, Align


# Blocks

@docs Block
@docs AccordionConfig, defaultAccordionConfig, AccordionItem
@docs AlertConfig, defaultAlertConfig
@docs CardConfig, defaultCardConfig, CardParts, emptyCardParts
@docs CarouselConfig, defaultCarouselConfig, CarouselItem, CarouselSnap
@docs ChatMessage
@docs CollapseConfig, defaultCollapseConfig, CollapseParts
@docs DiffParts
@docs Fieldset, Field, LabelPlacement, field
@docs ListConfig, defaultListConfig, ListRow
@docs MenuConfig, defaultMenuConfig, MenuItem, MenuBadge, MenuSpec, menuItem
@docs MockupBrowserParts, MockupPhoneParts, MockupWindowParts, CodeLine
@docs NavConfig, defaultNavConfig
@docs PaginationConfig, defaultPaginationConfig, PaginationData
@docs StackedConfig, defaultStackedConfig, StackedAlign
@docs StatConfig, defaultStatConfig, StatItem, emptyStatItem
@docs StepsConfig, defaultStepsConfig, Step
@docs TableConfig, defaultTableConfig, Row
@docs TabsConfig, defaultTabsConfig, Tab
@docs TimelineConfig, defaultTimelineConfig, TimelineItem


# Leaves

@docs Leaf, ImageSrc
@docs AvatarConfig, defaultAvatarConfig, AvatarItem
@docs BadgeConfig, defaultBadgeConfig
@docs ButtonConfig, defaultButtonConfig, ButtonColor, allButtonColors, buttonColorToSchema
@docs CheckboxConfig, defaultCheckboxConfig
@docs DividerConfig, defaultDividerConfig
@docs FileInputConfig, defaultFileInputConfig
@docs FilterData
@docs ImageConfig, defaultImageConfig
@docs InputConfig, defaultInputConfig
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
@docs RatingConfig, defaultRatingConfig, RatingData
@docs SelectConfig, defaultSelectConfig, SelectData
@docs SkeletonConfig, defaultSkeletonConfig
@docs StatusConfig, defaultStatusConfig
@docs SwapConfig, defaultSwapConfig, SwapFaces
@docs TextareaConfig, defaultTextareaConfig
@docs ThemeSelectData, ThemePresentation
@docs ToggleConfig, defaultToggleConfig, ToggleData


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

import Daisy.Chart exposing (ChartConfig, ChartData)
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
import Daisy.Schema.List as SList
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
        , sections : Sections msg
        , cta : Cta msg
        , overlays : List (Overlay msg)
        , theme : Theme
        , dock : Maybe (Dock msg)
        , fab : Maybe (Fab msg)
        }


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
    | Dashboard { sidebar : MenuSpec msg, navbar : NavbarParts msg }


{-| The page's single primary call to action. Rendered as `btn btn-primary`.
-}
type alias Cta msg =
    { label : String
    , onClick : msg
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
    , size = Nothing
    , style = Nothing
    , modifiers = []
    , behaviors = []
    , tooltip = Nothing
    , aura = Nothing
    , indicator = Nothing
    }



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


{-| All 35 themes, in daisyUI's own order.
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



-- SECTION -------------------------------------------------------------------


{-| A top-level band of the page.

`Navbar` holds leaves in three named part lists; the others hold blocks.

-}
type Section msg
    = Hero HeroConfig (List (Block msg))
    | Navbar (NavbarParts msg)
    | Footer FooterConfig (List (Block msg))
    | Grid GridConfig (List (Block msg))
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


{-| How many columns a `Grid` section has. Spacing is fixed by
`Daisy.Render.tokens`; only the column count is authorable.
-}
type GridColumns
    = Cols1
    | Cols2
    | Cols3
    | Cols4


{-| Configuration of a `Grid` section.
-}
type alias GridConfig =
    { columns : GridColumns }


{-| A four-column grid.
-}
defaultGridConfig : GridConfig
defaultGridConfig =
    { columns = Cols4 }


{-| Cross-axis alignment of a `Stack` section.
-}
type Align
    = AlignStart
    | AlignCenter
    | AlignEnd


{-| Configuration of a `Stack` section. This is a fixed-gap vertical band, not
the daisyUI `stack` component — that one is [`Stacked`](#Block).
-}
type alias StackConfig =
    { align : Align }


{-| A stack whose blocks stretch from the start edge.
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
    | Chart ChartConfig ChartData
    | Chat (List (ChatMessage msg))
    | Collapse CollapseConfig (CollapseParts msg)
    | Diff (DiffParts msg)
    | Form (List (Fieldset msg))
    | ListBlock ListConfig (List (ListRow msg))
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
    , modifiers : List SCard.Modifier
    , aura : Maybe AuraConfig
    , hover3d : Bool
    }


{-| A plain card.
-}
defaultCardConfig : CardConfig
defaultCardConfig =
    { style = Nothing
    , size = Nothing
    , modifiers = []
    , aura = Nothing
    , hover3d = False
    }


{-| The `card-*` parts. A part record makes `card-body` outside a card
unrepresentable.
-}
type alias CardParts msg =
    { figure : Maybe (Leaf msg)
    , title : Maybe String
    , body : List (Leaf msg)
    , actions : List (Leaf msg)
    }


{-| A card with nothing in it.
-}
emptyCardParts : CardParts msg
emptyCardParts =
    { figure = Nothing, title = Nothing, body = [], actions = [] }


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


{-| Groups of the daisyUI `list` component.
-}
type alias ListConfig =
    { modifiers : List SList.Modifier }


{-| A list with no column modifiers.
-}
defaultListConfig : ListConfig
defaultListConfig =
    { modifiers = [] }


{-| One `list-row`.
-}
type alias ListRow msg =
    { cells : List (Leaf msg) }


{-| Groups of the daisyUI `menu` component. `menu-active`, `menu-disabled` and
`menu-focus` belong on an item, so they are flags on [`MenuItem`](#MenuItem),
not entries here.
-}
type alias MenuConfig =
    { size : Maybe SMenu.Size
    , direction : Maybe SMenu.Direction
    , modifiers : List SMenu.Modifier
    }


{-| A vertical menu at the default size.
-}
defaultMenuConfig : MenuConfig
defaultMenuConfig =
    { size = Nothing, direction = Nothing, modifiers = [] }


{-| One menu entry. `title = True` renders it as the `menu-title` part; a
non-empty `submenu` renders the `menu-dropdown` parts.

`href` becomes the anchor's `href`. A menu item without one is a bare `<a>`,
which is not focusable and carries no `link` role, so navigation items should
always set it; `onClick` may still be set alongside (a `Browser.application`
turns the click into an `onUrlRequest` on its own).

-}
type MenuItem msg
    = MenuItem
        { label : String
        , icon : Maybe String
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
    { direction : Maybe SStat.Direction }


{-| A stats container with no direction class.
-}
defaultStatConfig : StatConfig
defaultStatConfig =
    { direction = Nothing }


{-| One tile: the `stat`, `stat-figure`, `stat-title`, `stat-value`,
`stat-desc` and `stat-actions` parts.
-}
type alias StatItem msg =
    { figure : Maybe (Leaf msg)
    , title : String
    , value : String
    , desc : Maybe String
    , actions : List (Leaf msg)
    }


{-| A titled tile with a value and nothing else.
-}
emptyStatItem : String -> String -> StatItem msg
emptyStatItem title value =
    { figure = Nothing, title = title, value = value, desc = Nothing, actions = [] }


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
    , cells : List (Leaf msg)
    }


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


{-| One tab and the panel it owns.
-}
type alias Tab msg =
    { label : String
    , active : Bool
    , disabled : Bool
    , content : List (Leaf msg)
    }


{-| Groups of the daisyUI `timeline` component.
-}
type alias TimelineConfig =
    { direction : Maybe STimeline.Direction
    , modifiers : List STimeline.Modifier
    }


{-| A timeline with no direction class.
-}
defaultTimelineConfig : TimelineConfig
defaultTimelineConfig =
    { direction = Nothing, modifiers = [] }


{-| The `timeline-start`, `timeline-middle` and `timeline-end` parts of one
entry.
-}
type alias TimelineItem msg =
    { start : Maybe String
    , middle : Maybe (Leaf msg)
    , end : Maybe String
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
    | Checkbox (CheckboxConfig msg)
    | Countdown Float
    | Divider DividerConfig (Maybe String)
    | FileInput (FileInputConfig msg)
    | Filter (FilterData msg)
    | HoverGallery (List ImageSrc)
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
    | Swap (SwapConfig msg) SwapFaces
    | Text String
    | TextRotate (List String)
    | Textarea (TextareaConfig msg)
    | ThemeSelect (ThemeSelectData msg)
    | Toggle (ToggleConfig msg) ToggleData


{-| The `src` of an image. `Leaf.Image` is not a daisyUI component; it exists
because `card`, `carousel`, `diff`, `stack`, `avatar` and `hover-gallery` all
need one.
-}
type alias ImageSrc =
    String


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


{-| Groups of the daisyUI `badge` component.
-}
type alias BadgeConfig =
    { color : Maybe SBadge.Color
    , style : Maybe SBadge.Style
    , size : Maybe SBadge.Size
    , tooltip : Maybe Tooltip
    }


{-| A badge with no colour, style or size class.
-}
defaultBadgeConfig : BadgeConfig
defaultBadgeConfig =
    { color = Nothing, style = Nothing, size = Nothing, tooltip = Nothing }


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
-}
type alias ButtonConfig msg =
    { color : Maybe ButtonColor
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


{-| Groups of the daisyUI `checkbox` component.
-}
type alias CheckboxConfig msg =
    { color : Maybe SCheckbox.Color
    , size : Maybe SCheckbox.Size
    , checked : Bool
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| An unchecked checkbox with no colour or size class.
-}
defaultCheckboxConfig : CheckboxConfig msg
defaultCheckboxConfig =
    { color = Nothing, size = Nothing, checked = False, tooltip = Nothing, onCheck = Nothing }


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
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| A file input with no colour, style or size class.
-}
defaultFileInputConfig : FileInputConfig msg
defaultFileInputConfig =
    { color = Nothing, style = Nothing, size = Nothing, tooltip = Nothing, onInput = Nothing }


{-| A `filter`: a radio group styled as buttons, plus an optional
`filter-reset`. daisyUI's `filter` declares no class groups, so this is all
data.
-}
type alias FilterData msg =
    { name : String
    , options : List String
    , selected : Maybe String
    , reset : Bool
    , onSelect : Maybe (String -> msg)
    }


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


{-| Groups of the daisyUI `input` component.
-}
type alias InputConfig msg =
    { color : Maybe SInput.Color
    , style : Maybe SInput.Style
    , size : Maybe SInput.Size
    , placeholder : String
    , value : String
    , indicator : Maybe Indicator
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| An empty input with no colour, style or size class.
-}
defaultInputConfig : InputConfig msg
defaultInputConfig =
    { color = Nothing
    , style = Nothing
    , size = Nothing
    , placeholder = ""
    , value = ""
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
are CSS variables, not classes, so there is no config.
-}
type alias RadialProgressData =
    { value : Float
    , label : String
    }


{-| Groups of the daisyUI `radio` component.
-}
type alias RadioConfig msg =
    { color : Maybe SRadio.Color
    , size : Maybe SRadio.Size
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| A radio with no colour or size class.
-}
defaultRadioConfig : RadioConfig msg
defaultRadioConfig =
    { color = Nothing, size = Nothing, tooltip = Nothing, onCheck = Nothing }


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
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| A range with no colour, size or direction class.
-}
defaultRangeConfig : RangeConfig msg
defaultRangeConfig =
    { color = Nothing, size = Nothing, direction = Nothing, tooltip = Nothing, onInput = Nothing }


{-| The bounds and value of a range.
-}
type alias RangeData =
    { min : Float
    , max : Float
    , value : Float
    }


{-| Groups of the daisyUI `rating` component.
-}
type alias RatingConfig msg =
    { size : Maybe SRating.Size
    , modifiers : List SRating.Modifier
    , tooltip : Maybe Tooltip
    , onRate : Maybe (Int -> msg)
    }


{-| A rating with no size class.
-}
defaultRatingConfig : RatingConfig msg
defaultRatingConfig =
    { size = Nothing, modifiers = [], tooltip = Nothing, onRate = Nothing }


{-| The group name, number of stars and current value of a rating.
-}
type alias RatingData =
    { name : String
    , count : Int
    , value : Int
    }


{-| Groups of the daisyUI `select` component.
-}
type alias SelectConfig msg =
    { color : Maybe SSelect.Color
    , style : Maybe SSelect.Style
    , size : Maybe SSelect.Size
    , tooltip : Maybe Tooltip
    , onSelect : Maybe (String -> msg)
    }


{-| A select with no colour, style or size class.
-}
defaultSelectConfig : SelectConfig msg
defaultSelectConfig =
    { color = Nothing, style = Nothing, size = Nothing, tooltip = Nothing, onSelect = Nothing }


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
    , tooltip : Maybe Tooltip
    , onInput : Maybe (String -> msg)
    }


{-| An empty textarea with no colour, style or size class.
-}
defaultTextareaConfig : TextareaConfig msg
defaultTextareaConfig =
    { color = Nothing
    , style = Nothing
    , size = Nothing
    , placeholder = ""
    , value = ""
    , tooltip = Nothing
    , onInput = Nothing
    }


{-| How a `theme-controller` is presented. daisyUI's five docs examples
(toggle, checkbox, radio group, select, swap) are five presentations of one
control, not five components.
-}
type ThemePresentation
    = ThemeAsSelect
    | ThemeAsRadios
    | ThemeAsToggle
    | ThemeAsCheckbox
    | ThemeAsSwap


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
    , tooltip : Maybe Tooltip
    , onCheck : Maybe (Bool -> msg)
    }


{-| A toggle with no colour or size class.
-}
defaultToggleConfig : ToggleConfig msg
defaultToggleConfig =
    { color = Nothing, size = Nothing, tooltip = Nothing, onCheck = Nothing }


{-| Whether a toggle is on.
-}
type alias ToggleData =
    { checked : Bool }



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
-}
type alias Fab msg =
    { config : FabConfig
    , main : Leaf msg
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
