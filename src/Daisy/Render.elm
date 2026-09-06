module Daisy.Render exposing
    ( page
    , section, block, leaf, overlay
    , tokens, unreachableClasses
    )

{-| `Daisy.Tree` -> `Html`.

This is the only module in the package that emits a class attribute, and every
daisyUI class it emits comes from a `Daisy.Schema.*` value — a `component`, an
entry of a `parts` list, or the result of a generated `xToClass` function. No
daisyUI class name is written as a literal anywhere below.

Layout is not authorable. Every Tailwind utility the renderer may emit is a
named constant listed in [`tokens`](#tokens), so spacing, column counts and
chart height are fixed by the library rather than passed in per call.


# Rendering

@docs page


# Lower-level renderers

Exposed so tests can render one node at a time. `page` is the only entry point
an application needs.

@docs section, block, leaf, overlay


# Class budget

@docs tokens, unreachableClasses

-}

import Chart as C
import Chart.Attributes as CA
import Chart.Svg as CS
import Daisy.Chart as Chart exposing (ChartConfig(..), ChartData, Series)
import Daisy.Schema.Accordion as SAccordion
import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Aura as SAura
import Daisy.Schema.Avatar as SAvatar
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Breadcrumbs as SBreadcrumbs
import Daisy.Schema.Button as SButton
import Daisy.Schema.Calendar as SCalendar
import Daisy.Schema.Card as SCard
import Daisy.Schema.Carousel as SCarousel
import Daisy.Schema.Chat as SChat
import Daisy.Schema.Checkbox as SCheckbox
import Daisy.Schema.Collapse as SCollapse
import Daisy.Schema.Countdown as SCountdown
import Daisy.Schema.Diff as SDiff
import Daisy.Schema.Divider as SDivider
import Daisy.Schema.Dock as SDock
import Daisy.Schema.Drawer as SDrawer
import Daisy.Schema.Dropdown as SDropdown
import Daisy.Schema.Fab as SFab
import Daisy.Schema.Fieldset as SFieldset
import Daisy.Schema.FileInput as SFileInput
import Daisy.Schema.Filter as SFilter
import Daisy.Schema.Footer as SFooter
import Daisy.Schema.Hero as SHero
import Daisy.Schema.Hover3d as SHover3d
import Daisy.Schema.HoverGallery as SHoverGallery
import Daisy.Schema.Indicator as SIndicator
import Daisy.Schema.Input as SInput
import Daisy.Schema.Join as SJoin
import Daisy.Schema.Kbd as SKbd
import Daisy.Schema.Label as SLabel
import Daisy.Schema.Link as SLink
import Daisy.Schema.List as SList
import Daisy.Schema.Loading as SLoading
import Daisy.Schema.Mask as SMask
import Daisy.Schema.Megamenu as SMegamenu
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.MockupBrowser as SMockupBrowser
import Daisy.Schema.MockupCode as SMockupCode
import Daisy.Schema.MockupPhone as SMockupPhone
import Daisy.Schema.MockupWindow as SMockupWindow
import Daisy.Schema.Modal as SModal
import Daisy.Schema.Navbar as SNavbar
import Daisy.Schema.Otp as SOtp
import Daisy.Schema.Pagination as SPagination
import Daisy.Schema.Progress as SProgress
import Daisy.Schema.RadialProgress as SRadialProgress
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
import Daisy.Schema.TextRotate as STextRotate
import Daisy.Schema.Textarea as STextarea
import Daisy.Schema.ThemeController as SThemeController
import Daisy.Schema.Timeline as STimeline
import Daisy.Schema.Toast as SToast
import Daisy.Schema.Toggle as SToggle
import Daisy.Schema.Tooltip as STooltip
import Daisy.Schema.Validator as SValidator
import Daisy.Tree as Tree exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Ev
import Json.Decode as Decode
import Svg
import Svg.Attributes as SvgA



-- TOKENS --------------------------------------------------------------------


{-| Every Tailwind utility `Daisy.Render` is allowed to emit.

`RenderPurityTest` asserts that every class the renderer produces is either in
`Daisy.Schema.allClasses` or in this list. Each entry has a named constant in
this module; nothing writes a utility inline.

-}
tokens : List String
tokens =
    [ tokenFlex
    , tokenFlexCol
    , tokenFlexWrap
    , tokenGrid
    , tokenGridCols1
    , tokenGridCols2
    , tokenGridCols3
    , tokenGridCols4
    , tokenGridCols2Sm
    , tokenGridCols3Lg
    , tokenGridCols4Lg
    , tokenGapSm
    , tokenGap
    , tokenGapLg
    , tokenPaddingSm
    , tokenPadding
    , tokenItemsStart
    , tokenItemsCenter
    , tokenItemsEnd
    , tokenJustifyBetween
    , tokenWFull
    , tokenWSidebar
    , tokenMinHScreen
    , tokenChartHeight
    , tokenOverflowXAuto
    , tokenFixed
    , tokenInset0
    , tokenZOverlay
    , tokenPointerEventsNone
    , tokenPointerEventsAuto
    , tokenDrawerOpenLg
    , tokenHiddenLg
    , tokenProse
    , tokenBgBase
    , tokenTextSm
    , tokenFontBold
    , tokenSizeIcon
    ]


tokenFlex : String
tokenFlex =
    "flex"


tokenFlexCol : String
tokenFlexCol =
    "flex-col"


tokenFlexWrap : String
tokenFlexWrap =
    "flex-wrap"


tokenGrid : String
tokenGrid =
    "grid"


tokenGridCols1 : String
tokenGridCols1 =
    "grid-cols-1"


tokenGridCols2 : String
tokenGridCols2 =
    "grid-cols-2"


tokenGridCols3 : String
tokenGridCols3 =
    "grid-cols-3"


tokenGridCols4 : String
tokenGridCols4 =
    "grid-cols-4"


tokenGridCols2Sm : String
tokenGridCols2Sm =
    "sm:grid-cols-2"


tokenGridCols3Lg : String
tokenGridCols3Lg =
    "lg:grid-cols-3"


tokenGridCols4Lg : String
tokenGridCols4Lg =
    "lg:grid-cols-4"


tokenGapSm : String
tokenGapSm =
    "gap-2"


tokenGap : String
tokenGap =
    "gap-4"


tokenGapLg : String
tokenGapLg =
    "gap-8"


tokenPaddingSm : String
tokenPaddingSm =
    "p-2"


tokenPadding : String
tokenPadding =
    "p-4"


tokenItemsStart : String
tokenItemsStart =
    "items-start"


tokenItemsCenter : String
tokenItemsCenter =
    "items-center"


tokenItemsEnd : String
tokenItemsEnd =
    "items-end"


tokenJustifyBetween : String
tokenJustifyBetween =
    "justify-between"


tokenWFull : String
tokenWFull =
    "w-full"


tokenWSidebar : String
tokenWSidebar =
    "w-64"


tokenMinHScreen : String
tokenMinHScreen =
    "min-h-screen"


{-| A chart's _minimum_ height. elm-charts scales its SVG to the width of this
container and derives the drawn height from the `chartWidth : chartHeight`
ratio, so a fixed `h-` would be overflowed (and the next block overlapped) on
any container wider than that ratio allows. A `min-h-` pins the small end and
lets the box grow with the drawing.
-}
tokenChartHeight : String
tokenChartHeight =
    "min-h-64"


tokenOverflowXAuto : String
tokenOverflowXAuto =
    "overflow-x-auto"


tokenFixed : String
tokenFixed =
    "fixed"


tokenInset0 : String
tokenInset0 =
    "inset-0"


tokenZOverlay : String
tokenZOverlay =
    "z-40"


tokenPointerEventsNone : String
tokenPointerEventsNone =
    "pointer-events-none"


tokenPointerEventsAuto : String
tokenPointerEventsAuto =
    "pointer-events-auto"


tokenDrawerOpenLg : String
tokenDrawerOpenLg =
    "lg:drawer-open"


tokenHiddenLg : String
tokenHiddenLg =
    "lg:hidden"


tokenProse : String
tokenProse =
    "prose"


tokenBgBase : String
tokenBgBase =
    "bg-base-100"


tokenTextSm : String
tokenTextSm =
    "text-sm"


tokenFontBold : String
tokenFontBold =
    "font-bold"


tokenSizeIcon : String
tokenSizeIcon =
    "size-5"


{-| The daisyUI classes that no `Daisy.Tree` value can reach.

`CoverageTest` asserts that the classes emitted across all constructors equal
`Daisy.Schema.allClasses` minus this list. Keeping it short is the point: five
entries out of 554.

-}
unreachableClasses : List String
unreachableClasses =
    [ -- `calendar` is Excluded in docs/placement.md: its three component classes
      -- are theming hooks for third-party widgets (a `<calendar-date>` web
      -- component, React DayPicker, Vanilla Calendar Pro). Emitting them needs
      -- foreign markup, i.e. an escape hatch.
      classAt 0 SCalendar.componentClasses
    , classAt 1 SCalendar.componentClasses
    , classAt 2 SCalendar.componentClasses

    -- The `drawer` `variant` group is a pair of Tailwind selector *prefixes*
    -- (`is-drawer-open:` / `is-drawer-close:`), not classes an element can
    -- carry, so no element ever gets them on their own.
    , SDrawer.variantToClass SDrawer.IsDrawerOpen
    , SDrawer.variantToClass SDrawer.IsDrawerClose
    ]



-- CLASS PLUMBING ------------------------------------------------------------


classes : List String -> Html.Attribute msg
classes list =
    Attr.class (String.join " " (List.filter (\c -> c /= "") list))


{-| Pick one entry out of a schema `parts` or `componentClasses` list by
position. Every part class the renderer emits goes through this, so no part is
ever retyped as a literal.
-}
partAt : Int -> List String -> String
partAt index list =
    List.drop index list |> List.head |> Maybe.withDefault ""


classAt : Int -> List String -> String
classAt =
    partAt


opt : (a -> String) -> Maybe a -> List String
opt toClass maybe =
    case maybe of
        Just value ->
            [ toClass value ]

        Nothing ->
            []


flag : Bool -> String -> List String
flag on cls =
    if on then
        [ cls ]

    else
        []


flagAttrs : Bool -> Html.Attribute msg -> List (Html.Attribute msg)
flagAttrs on attr =
    if on then
        [ attr ]

    else
        []


maybeHtml : (a -> Html msg) -> Maybe a -> List (Html msg)
maybeHtml f maybe =
    case maybe of
        Just value ->
            [ f value ]

        Nothing ->
            []


onClickAttrs : Maybe msg -> List (Html.Attribute msg)
onClickAttrs maybe =
    case maybe of
        Just m ->
            [ Ev.onClick m ]

        Nothing ->
            []


optAttr : (a -> Html.Attribute msg) -> Maybe a -> List (Html.Attribute msg)
optAttr toAttr maybe =
    case maybe of
        Just value ->
            [ toAttr value ]

        Nothing ->
            []


{-| Fire `msg` when the browser asks to dismiss a `<dialog>`.

`cancel` (Escape, or `requestClose()`) and not `close`: `close` also fires for
a programmatic `HTMLDialogElement.close()`, which is exactly what the demo
glue does _after_ the application itself decided to close the modal, so
listening to it would overwrite the message the application just handled.
The extra `keydown` listener covers an Escape press in a dialog the browser
has not put in the top layer (no `showModal()`), where no `cancel` fires.

-}
onDismissAttrs : Maybe msg -> List (Html.Attribute msg)
onDismissAttrs maybe =
    case maybe of
        Just m ->
            [ Ev.on "cancel" (Decode.succeed m)
            , Ev.on "keydown" (escapeDecoder m)
            ]

        Nothing ->
            []


escapeDecoder : msg -> Decode.Decoder msg
escapeDecoder m =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Escape" || key == "Esc" then
                    Decode.succeed m

                else
                    Decode.fail "not Escape"
            )


onInputAttrs : Maybe (String -> msg) -> List (Html.Attribute msg)
onInputAttrs maybe =
    case maybe of
        Just f ->
            [ Ev.onInput f ]

        Nothing ->
            []


onCheckAttrs : Maybe (Bool -> msg) -> List (Html.Attribute msg)
onCheckAttrs maybe =
    case maybe of
        Just f ->
            [ Ev.onCheck f ]

        Nothing ->
            []



-- NAMED PART / COMPONENT CLASSES --------------------------------------------


collapseTitlePart : String
collapseTitlePart =
    partAt 0 SCollapse.parts


collapseContentPart : String
collapseContentPart =
    partAt 1 SCollapse.parts


accordionTitlePart : String
accordionTitlePart =
    partAt 0 SAccordion.parts


accordionContentPart : String
accordionContentPart =
    partAt 1 SAccordion.parts


avatarGroupClass : String
avatarGroupClass =
    classAt 1 SAvatar.componentClasses


cardTitlePart : String
cardTitlePart =
    partAt 0 SCard.parts


cardBodyPart : String
cardBodyPart =
    partAt 1 SCard.parts


cardActionsPart : String
cardActionsPart =
    partAt 2 SCard.parts


carouselItemPart : String
carouselItemPart =
    partAt 0 SCarousel.parts


chatImagePart : String
chatImagePart =
    partAt 0 SChat.parts


chatHeaderPart : String
chatHeaderPart =
    partAt 1 SChat.parts


chatFooterPart : String
chatFooterPart =
    partAt 2 SChat.parts


chatBubblePart : String
chatBubblePart =
    partAt 3 SChat.parts


diffItem1Part : String
diffItem1Part =
    partAt 0 SDiff.parts


diffItem2Part : String
diffItem2Part =
    partAt 1 SDiff.parts


diffResizerPart : String
diffResizerPart =
    partAt 2 SDiff.parts


dockLabelPart : String
dockLabelPart =
    partAt 0 SDock.parts


drawerTogglePart : String
drawerTogglePart =
    partAt 0 SDrawer.parts


drawerContentPart : String
drawerContentPart =
    partAt 1 SDrawer.parts


drawerSidePart : String
drawerSidePart =
    partAt 2 SDrawer.parts


drawerOverlayPart : String
drawerOverlayPart =
    partAt 3 SDrawer.parts


drawerButtonPart : String
drawerButtonPart =
    partAt 4 SDrawer.parts


dropdownContentPart : String
dropdownContentPart =
    partAt 0 SDropdown.parts


fabClosePart : String
fabClosePart =
    partAt 0 SFab.parts


fabMainActionPart : String
fabMainActionPart =
    partAt 1 SFab.parts


fieldsetLegendPart : String
fieldsetLegendPart =
    partAt 0 SFieldset.parts


filterResetPart : String
filterResetPart =
    partAt 0 SFilter.parts


footerTitlePart : String
footerTitlePart =
    partAt 0 SFooter.parts


heroContentPart : String
heroContentPart =
    partAt 0 SHero.parts


heroOverlayPart : String
heroOverlayPart =
    partAt 1 SHero.parts


indicatorItemPart : String
indicatorItemPart =
    partAt 0 SIndicator.parts


joinItemClass : String
joinItemClass =
    classAt 1 SJoin.componentClasses


labelClass : String
labelClass =
    classAt 0 SLabel.componentClasses


floatingLabelClass : String
floatingLabelClass =
    classAt 1 SLabel.componentClasses


listRowClass : String
listRowClass =
    classAt 1 SList.componentClasses


megamenuActivePart : String
megamenuActivePart =
    partAt 0 SMegamenu.parts


menuTitlePart : String
menuTitlePart =
    partAt 0 SMenu.parts


menuDropdownPart : String
menuDropdownPart =
    partAt 1 SMenu.parts


menuDropdownTogglePart : String
menuDropdownTogglePart =
    partAt 2 SMenu.parts


mockupBrowserToolbarPart : String
mockupBrowserToolbarPart =
    partAt 0 SMockupBrowser.parts


mockupPhoneCameraPart : String
mockupPhoneCameraPart =
    partAt 0 SMockupPhone.parts


mockupPhoneDisplayPart : String
mockupPhoneDisplayPart =
    partAt 1 SMockupPhone.parts


modalBoxPart : String
modalBoxPart =
    partAt 0 SModal.parts


modalActionPart : String
modalActionPart =
    partAt 1 SModal.parts


modalBackdropPart : String
modalBackdropPart =
    partAt 2 SModal.parts


modalTogglePart : String
modalTogglePart =
    partAt 3 SModal.parts


navbarStartPart : String
navbarStartPart =
    partAt 0 SNavbar.parts


navbarCenterPart : String
navbarCenterPart =
    partAt 1 SNavbar.parts


navbarEndPart : String
navbarEndPart =
    partAt 2 SNavbar.parts


paginationItemPart : String
paginationItemPart =
    partAt 0 SPagination.parts


statPart : String
statPart =
    partAt 0 SStat.parts


statTitlePart : String
statTitlePart =
    partAt 1 SStat.parts


statValuePart : String
statValuePart =
    partAt 2 SStat.parts


statDescPart : String
statDescPart =
    partAt 3 SStat.parts


statFigurePart : String
statFigurePart =
    partAt 4 SStat.parts


statActionsPart : String
statActionsPart =
    partAt 5 SStat.parts


stepPart : String
stepPart =
    partAt 0 SSteps.parts


stepIconPart : String
stepIconPart =
    partAt 1 SSteps.parts


swapOnPart : String
swapOnPart =
    partAt 0 SSwap.parts


swapOffPart : String
swapOffPart =
    partAt 1 SSwap.parts


swapIndeterminatePart : String
swapIndeterminatePart =
    partAt 2 SSwap.parts


tabPart : String
tabPart =
    partAt 0 STab.parts


tabContentPart : String
tabContentPart =
    partAt 1 STab.parts


timelineStartPart : String
timelineStartPart =
    partAt 0 STimeline.parts


timelineMiddlePart : String
timelineMiddlePart =
    partAt 1 STimeline.parts


timelineEndPart : String
timelineEndPart =
    partAt 2 STimeline.parts


tooltipContentPart : String
tooltipContentPart =
    partAt 0 STooltip.parts


validatorHintPart : String
validatorHintPart =
    partAt 0 SValidator.parts



-- PAGE ----------------------------------------------------------------------


{-| Render a whole page.

The page root carries `data-theme`, so every daisyUI colour below it follows
`Page.theme`.

`Page.cta` is placed by the shell and nowhere else:

  - `Shell.Dashboard` puts it at the end of the navbar (`navbar-end`).
  - `Shell.Plain` puts it at the end of the last section.

Overlays render after every section, inside one fixed wrapper, always in the
order drawer, modal, toast, so stacking is decided once by the library. `dock`
and `fab` render in the same fixed layer, after the overlays.

-}
page : Page msg -> Html msg
page (Page p) =
    Html.div
        [ Attr.attribute "data-theme" (Tree.themeToString p.theme)
        , classes [ tokenMinHScreen, tokenBgBase ]
        ]
        (shell p.shell p.cta p.sections
            ++ [ overlayLayer p.overlays p.dock p.fab ]
        )


shell : Shell msg -> Cta msg -> Sections msg -> List (Html msg)
shell theShell theCta theSections =
    case theShell of
        Plain ->
            [ Html.main_
                [ classes [ tokenFlex, tokenFlexCol, tokenGapLg, tokenPadding ] ]
                (sectionList [ ctaHtml theCta ] theSections)
            ]

        Dashboard d ->
            [ Html.div
                [ classes [ SDrawer.component, tokenDrawerOpenLg ] ]
                [ -- daisyUI's state checkbox: painted `h-0 w-0 opacity-0`, but
                  -- that still leaves it focusable and announced, so it is
                  -- taken out of the tab order and hidden from assistive tech.
                  Html.input
                    [ Attr.id shellDrawerId
                    , Attr.type_ "checkbox"
                    , Attr.tabindex -1
                    , Attr.attribute "aria-hidden" "true"
                    , classes [ drawerTogglePart ]
                    ]
                    []
                , Html.div
                    [ classes [ drawerContentPart, tokenFlex, tokenFlexCol, tokenMinHScreen ] ]
                    [ navbarHtml
                        { start = d.navbar.start
                        , center = d.navbar.center
                        , end = d.navbar.end
                        }
                        [ shellDrawerButton ]
                        [ ctaHtml theCta ]
                    , Html.main_
                        [ classes [ tokenFlex, tokenFlexCol, tokenGapLg, tokenPadding ] ]
                        (sectionList [] theSections)
                    ]
                , Html.div
                    [ classes [ drawerSidePart ] ]
                    [ Html.label
                        [ Attr.for shellDrawerId, classes [ drawerOverlayPart ] ]
                        []
                    , menuHtml [ tokenWSidebar, tokenMinHScreen, tokenBgBase ] d.sidebar
                    ]
                ]
            ]


shellDrawerId : String
shellDrawerId =
    "daisy-shell-drawer"


shellDrawerButton : Html msg
shellDrawerButton =
    Html.label
        [ Attr.for shellDrawerId
        , classes [ drawerButtonPart, SButton.component, SButton.styleToClass SButton.Ghost, tokenHiddenLg ]
        ]
        [ Html.text "☰" ]


ctaHtml : Cta msg -> Html msg
ctaHtml c =
    Html.button
        (classes
            ([ SButton.component, SButton.colorToClass SButton.Primary ]
                ++ opt SButton.sizeToClass c.size
                ++ opt SButton.styleToClass c.style
                ++ List.map SButton.modifierToClass c.modifiers
                ++ List.map SButton.behaviorToClass c.behaviors
            )
            :: Ev.onClick c.onClick
            :: []
        )
        [ Html.text c.label ]
        |> withIndicator c.indicator
        |> withTooltip c.tooltip
        |> withAura c.aura


sectionList : List (Html msg) -> Sections msg -> List (Html msg)
sectionList extra theSections =
    let
        list =
            case theSections of
                Sections1 a ->
                    [ a ]

                Sections2 a b ->
                    [ a, b ]

                Sections3 a b c ->
                    [ a, b, c ]

                Sections4 a b c d ->
                    [ a, b, c, d ]

                Sections5 a b c d e ->
                    [ a, b, c, d, e ]

        last =
            List.length list - 1
    in
    List.indexedMap
        (\i s ->
            sectionWith
                (if i == last then
                    extra

                 else
                    []
                )
                s
        )
        list



-- SECTION -------------------------------------------------------------------


{-| Render one section.
-}
section : Section msg -> Html msg
section =
    sectionWith []


sectionWith : List (Html msg) -> Section msg -> Html msg
sectionWith extra theSection =
    case theSection of
        Hero config blocks ->
            Html.div
                [ classes [ SHero.component ] ]
                (flagHtml config.overlay (Html.div [ classes [ heroOverlayPart ] ] [])
                    ++ [ Html.div
                            [ classes [ heroContentPart, tokenFlex, tokenFlexCol, tokenGap ] ]
                            (List.map block blocks ++ extra)
                       ]
                )

        Navbar parts ->
            navbarHtml parts [] extra

        Footer config blocks ->
            Html.footer
                [ classes
                    ([ SFooter.component ]
                        ++ opt SFooter.directionToClass config.direction
                        ++ opt SFooter.placementToClass config.placement
                        ++ [ tokenPadding, tokenGap ]
                    )
                ]
                (List.map (blockIn InFooter) blocks ++ extra)

        Grid config blocks ->
            Html.div
                [ classes (tokenGrid :: gridColumnsTokens config.columns ++ [ tokenGap ]) ]
                (List.map block blocks ++ extra)

        Stack config blocks ->
            Html.div
                [ classes [ tokenFlex, tokenFlexCol, tokenGap, alignToken config.align ] ]
                (List.map block blocks ++ extra)


navbarHtml : NavbarParts msg -> List (Html msg) -> List (Html msg) -> Html msg
navbarHtml parts before after =
    Html.div
        [ classes [ SNavbar.component, tokenBgBase, tokenGapSm ] ]
        -- `navbar-start` and `navbar-end` are each exactly 50% wide, so their
        -- contents overlap rather than shrink once they no longer fit; they
        -- wrap inside their own half instead.
        [ Html.div
            [ classes [ navbarStartPart, tokenFlexWrap, tokenGapSm ] ]
            (before ++ List.map leaf parts.start)
        , Html.div [ classes [ navbarCenterPart ] ] (List.map leaf parts.center)
        , Html.div
            [ classes [ navbarEndPart, tokenFlexWrap, tokenGapSm ] ]
            (List.map leaf parts.end ++ after)
        ]


{-| Column tracks for a `Section.Grid`.

`grid-cols-N` on its own is `repeat(N, minmax(0, 1fr))`, so at 375px four
tracks are ~85px wide and every child wider than its track spills over its
neighbour. The counts are therefore breakpoints, not a constant: one column on
a phone, two from `sm`, the asked-for count from `lg`. `Cols1` has nothing to
step through.

-}
gridColumnsTokens : GridColumns -> List String
gridColumnsTokens columns =
    case columns of
        Cols1 ->
            [ tokenGridCols1 ]

        Cols2 ->
            [ tokenGridCols1, tokenGridCols2Sm ]

        Cols3 ->
            [ tokenGridCols1, tokenGridCols2Sm, tokenGridCols3Lg ]

        Cols4 ->
            [ tokenGridCols1, tokenGridCols2Sm, tokenGridCols4Lg ]


alignToken : Align -> String
alignToken align =
    case align of
        AlignStart ->
            tokenItemsStart

        AlignCenter ->
            tokenItemsCenter

        AlignEnd ->
            tokenItemsEnd


flagHtml : Bool -> Html msg -> List (Html msg)
flagHtml on html =
    if on then
        [ html ]

    else
        []



-- BLOCK ---------------------------------------------------------------------


{-| Where a block sits. Only `footer-title` depends on it: the `footer-title`
part is emitted for a `Nav` block only when the block is a direct child of a
`Footer` section, so the part can never escape its component.
-}
type BlockContext
    = InFooter
    | Anywhere


{-| Render one block, outside any footer.
-}
block : Block msg -> Html msg
block =
    blockIn Anywhere


blockIn : BlockContext -> Block msg -> Html msg
blockIn context theBlock =
    case theBlock of
        Accordion config items ->
            Html.div
                [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
                (List.map (accordionItemHtml config) items)

        Alert config leaves ->
            Html.div
                [ classes
                    ([ SAlert.component ]
                        ++ opt SAlert.colorToClass config.color
                        ++ opt SAlert.styleToClass config.style
                        ++ opt SAlert.directionToClass config.direction
                    )
                , Attr.attribute "role" "alert"
                ]
                (List.map leaf leaves)

        Breadcrumbs leaves ->
            Html.div
                [ classes [ SBreadcrumbs.component, tokenTextSm ] ]
                [ Html.ul [] (List.map (\l -> Html.li [] [ leaf l ]) leaves) ]

        Card config parts ->
            cardHtml config parts

        Carousel config items ->
            Html.div
                [ classes
                    ([ SCarousel.component ]
                        ++ opt SCarousel.directionToClass config.direction
                        ++ List.map SCarousel.modifierToClass config.modifiers
                        ++ opt SCarousel.modifierToClass (Maybe.map carouselSnapModifier config.snap)
                    )
                ]
                (List.map
                    (\item -> Html.div [ classes [ carouselItemPart ] ] (List.map leaf item.content))
                    items
                )

        Chart config data ->
            chartHtml config data

        Chat messages ->
            Html.div
                [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
                (List.map chatMessageHtml messages)

        Collapse config parts ->
            Html.div
                [ classes ([ SCollapse.component ] ++ List.map SCollapse.modifierToClass config.modifiers) ]
                [ Html.input [ Attr.type_ "checkbox" ] []
                , Html.div [ classes [ collapseTitlePart ] ] [ Html.text parts.title ]
                , Html.div [ classes [ collapseContentPart ] ] (List.map leaf parts.content)
                ]

        Diff parts ->
            Html.figure
                [ classes [ SDiff.component ] ]
                [ Html.div [ classes [ diffItem1Part ] ] [ leaf parts.item1 ]
                , Html.div [ classes [ diffItem2Part ] ] [ leaf parts.item2 ]
                , Html.div [ classes [ diffResizerPart ] ] []
                ]

        Form fieldsets ->
            Html.form
                [ classes [ tokenFlex, tokenFlexCol, tokenGap ] ]
                (List.map fieldsetHtml fieldsets)

        ListBlock config rows ->
            Html.ul
                [ classes ([ SList.component ] ++ List.map SList.modifierToClass config.modifiers) ]
                (List.map
                    (\row -> Html.li [ classes [ listRowClass ] ] (List.map leaf row.cells))
                    rows
                )

        Menu config items ->
            menuHtml [] { config = config, items = items }

        MockupBrowser parts ->
            Html.div
                [ classes [ SMockupBrowser.component ] ]
                (maybeHtml
                    (\toolbar ->
                        Html.div
                            [ classes [ mockupBrowserToolbarPart ] ]
                            [ Html.div [ classes [ SInput.component ] ] [ Html.text toolbar ] ]
                    )
                    parts.toolbar
                    ++ [ Html.div [ classes [ tokenPadding ] ] (List.map leaf parts.content) ]
                )

        MockupCode lines ->
            Html.div
                [ classes [ SMockupCode.component ] ]
                (List.map codeLineHtml lines)

        MockupPhone parts ->
            Html.div
                [ classes [ SMockupPhone.component ] ]
                [ Html.div [ classes [ mockupPhoneCameraPart ] ] []
                , Html.div [ classes [ mockupPhoneDisplayPart ] ] (List.map leaf parts.content)
                ]

        MockupWindow parts ->
            Html.div
                [ classes [ SMockupWindow.component ] ]
                (maybeHtml
                    (\t -> Html.div [ classes [ tokenTextSm, tokenPaddingSm, tokenFontBold ] ] [ Html.text t ])
                    parts.title
                    ++ [ Html.div [ classes [ tokenPadding ] ] (List.map leaf parts.content) ]
                )

        Nav config leaves ->
            Html.nav
                [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
                (maybeHtml (navTitleHtml context) config.title ++ List.map leaf leaves)

        Pagination config data ->
            Html.div
                [ classes ([ SPagination.component ] ++ opt SPagination.directionToClass config.direction) ]
                (List.indexedMap
                    (\i label ->
                        Html.button
                            [ classes
                                ([ paginationItemPart, SButton.component ]
                                    ++ flag (i == data.active) (SButton.behaviorToClass SButton.Active)
                                )
                            ]
                            [ Html.text label ]
                    )
                    data.pages
                )

        Prose leaves ->
            Html.div [ classes [ tokenProse ] ] (List.map leaf leaves)

        Stacked config leaves ->
            Html.div
                [ classes
                    ([ SStack.component ]
                        ++ List.map SStack.modifierToClass config.modifiers
                        ++ opt SStack.modifierToClass (Maybe.map stackedAlignModifier config.align)
                    )
                ]
                (List.map leaf leaves)

        Stat config items ->
            Html.div
                [ classes ([ SStat.component ] ++ opt SStat.directionToClass config.direction) ]
                (List.map statItemHtml items)

        Steps config steps ->
            Html.ul
                [ classes ([ SSteps.component ] ++ opt SSteps.directionToClass config.direction) ]
                (List.map stepHtml steps)

        Table config rows ->
            tableHtml config rows

        Tabs config tabs ->
            Html.div
                [ classes
                    ([ STab.component ]
                        ++ opt STab.styleToClass config.style
                        ++ opt STab.sizeToClass config.size
                        ++ opt STab.placementToClass config.placement
                    )
                , Attr.attribute "role" "tablist"
                ]
                (List.concatMap tabHtml tabs)

        Timeline config items ->
            Html.ul
                [ classes
                    ([ STimeline.component ]
                        ++ opt STimeline.directionToClass config.direction
                        ++ List.map STimeline.modifierToClass config.modifiers
                    )
                ]
                (List.map timelineItemHtml items)


navTitleHtml : BlockContext -> String -> Html msg
navTitleHtml context title =
    case context of
        InFooter ->
            Html.h6 [ classes [ footerTitlePart ] ] [ Html.text title ]

        Anywhere ->
            Html.h6 [ classes [ tokenFontBold, tokenTextSm ] ] [ Html.text title ]


accordionItemHtml : AccordionConfig -> AccordionItem msg -> Html msg
accordionItemHtml config item =
    Html.div
        [ classes ([ SAccordion.component ] ++ List.map SAccordion.modifierToClass config.modifiers) ]
        [ Html.input [ Attr.type_ "radio", Attr.name config.name ] []
        , Html.div [ classes [ accordionTitlePart ] ] [ Html.text item.title ]
        , Html.div [ classes [ accordionContentPart ] ] (List.map leaf item.content)
        ]


cardHtml : CardConfig -> CardParts msg -> Html msg
cardHtml config parts =
    Html.div
        [ classes
            ([ SCard.component ]
                ++ opt SCard.styleToClass config.style
                ++ opt SCard.sizeToClass config.size
                ++ List.map SCard.modifierToClass config.modifiers
            )
        ]
        (maybeHtml (\f -> Html.figure [] [ leaf f ]) parts.figure
            ++ [ Html.div
                    [ classes [ cardBodyPart ] ]
                    (maybeHtml (\t -> Html.h2 [ classes [ cardTitlePart ] ] [ Html.text t ]) parts.title
                        ++ List.map leaf parts.body
                        ++ [ Html.div [ classes [ cardActionsPart ] ] (List.map leaf parts.actions) ]
                    )
               ]
        )
        |> withHover3d config.hover3d
        |> withAura config.aura


carouselSnapModifier : CarouselSnap -> SCarousel.Modifier
carouselSnapModifier snap =
    case snap of
        SnapStart ->
            SCarousel.Start

        SnapCenter ->
            SCarousel.Center

        SnapEnd ->
            SCarousel.End


stackedAlignModifier : StackedAlign -> SStack.Modifier
stackedAlignModifier align =
    case align of
        StackedTop ->
            SStack.Top

        StackedBottom ->
            SStack.Bottom

        StackedStart ->
            SStack.Start

        StackedEnd ->
            SStack.End


chatMessageHtml : ChatMessage msg -> Html msg
chatMessageHtml message =
    Html.div
        [ classes [ SChat.component, SChat.placementToClass message.placement ] ]
        (maybeHtml
            (\src ->
                Html.div
                    [ classes [ chatImagePart, SAvatar.component ] ]
                    [ Html.img [ Attr.src src, Attr.alt "", classes [ tokenSizeIcon ] ] [] ]
            )
            message.image
            ++ maybeHtml (\h -> Html.div [ classes [ chatHeaderPart ] ] [ Html.text h ]) message.header
            ++ [ Html.div
                    [ classes ([ chatBubblePart ] ++ opt SChat.colorToClass message.color) ]
                    (List.map leaf message.bubble)
               ]
            ++ maybeHtml (\f -> Html.div [ classes [ chatFooterPart ] ] [ Html.text f ]) message.footer
        )


codeLineHtml : CodeLine -> Html msg
codeLineHtml line =
    Html.pre
        (maybeAttr (Attr.attribute "data-prefix") line.prefix)
        [ Html.code [] [ Html.text line.text ] ]


maybeAttr : (String -> Html.Attribute msg) -> Maybe String -> List (Html.Attribute msg)
maybeAttr f maybe =
    case maybe of
        Just v ->
            [ f v ]

        Nothing ->
            []


fieldsetHtml : Fieldset msg -> Html msg
fieldsetHtml fs =
    Html.fieldset
        [ classes [ SFieldset.component ] ]
        (maybeHtml
            (\l -> Html.legend [ classes [ fieldsetLegendPart ] ] [ Html.text l ])
            fs.legend
            ++ List.map fieldHtml fs.fields
        )


fieldHtml : Field msg -> Html msg
fieldHtml f =
    let
        control =
            leafWith (flag f.validate SValidator.component) f.control

        hint =
            maybeHtml (\h -> Html.p [ classes [ validatorHintPart ] ] [ Html.text h ]) f.hint

        labelText =
            Maybe.withDefault "" f.label
    in
    case f.labelPlacement of
        -- The field's own `<label>` is the wrapper, with the daisyUI `label`
        -- class on a `<span>` inside it. daisyUI writes controls that way
        -- itself (`<label class="label"><input class="toggle"> Remember
        -- me</label>`), and it is what associates the label text with the
        -- control: a sibling `<label>` with no `for` names nothing, so every
        -- input, select and toggle in a `Field` would otherwise be an unnamed
        -- form control. `label` is `inline-flex`, so moving the class onto the
        -- span leaves the layout exactly as it was.
        LabelStart ->
            Html.label
                [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
                (Html.span [ classes [ labelClass ] ] [ Html.text labelText ]
                    :: control
                    :: hint
                )

        LabelEnd ->
            Html.label
                [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
                (control
                    :: Html.span [ classes [ labelClass ] ] [ Html.text labelText ]
                    :: hint
                )

        LabelFloating ->
            -- The hint goes *inside* the floating label, after the control:
            -- daisyUI styles it as `.validator ~ .validator-hint`, so it only
            -- ever shows when it is a following sibling of the control itself.
            Html.div
                [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
                [ Html.label
                    [ classes [ floatingLabelClass ] ]
                    ([ Html.span [] [ Html.text labelText ], control ] ++ hint)
                ]


menuHtml : List String -> MenuSpec msg -> Html msg
menuHtml extra spec =
    Html.ul
        [ classes
            ([ SMenu.component ]
                ++ opt SMenu.sizeToClass spec.config.size
                ++ opt SMenu.directionToClass spec.config.direction
                ++ List.map SMenu.modifierToClass spec.config.modifiers
                ++ extra
            )
        ]
        (List.map menuItemHtml spec.items)


menuItemHtml : MenuItem msg -> Html msg
menuItemHtml (MenuItem item) =
    let
        stateClasses =
            flag item.active (SMenu.modifierToClass SMenu.Active)
                ++ flag item.disabled (SMenu.modifierToClass SMenu.Disabled)
                ++ flag item.focus (SMenu.modifierToClass SMenu.Focus)

        body =
            maybeHtml (\icon -> Html.span [ classes [ tokenSizeIcon ] ] [ Html.text icon ]) item.icon
                ++ [ Html.text item.label ]
                ++ maybeHtml (\b -> badgeHtml [] b.config b.label) item.badge
    in
    if item.title then
        Html.li [ classes [ menuTitlePart ] ] [ Html.text item.label ]

    else if List.isEmpty item.submenu then
        Html.li []
            [ Html.a
                (classes stateClasses
                    :: optAttr Attr.href item.href
                    ++ onClickAttrs item.onClick
                )
                body
            ]

    else
        Html.li []
            [ Html.span (classes (menuDropdownTogglePart :: stateClasses) :: onClickAttrs item.onClick) body
            , Html.ul
                [ classes [ menuDropdownPart ] ]
                (List.map menuItemHtml item.submenu)
            ]


statItemHtml : StatItem msg -> Html msg
statItemHtml item =
    Html.div
        [ classes [ statPart ] ]
        (maybeHtml (\f -> Html.div [ classes [ statFigurePart ] ] [ leaf f ]) item.figure
            ++ [ Html.div [ classes [ statTitlePart ] ] [ Html.text item.title ]
               , Html.div [ classes [ statValuePart ] ] [ Html.text item.value ]
               ]
            ++ maybeHtml (\d -> Html.div [ classes [ statDescPart ] ] [ Html.text d ]) item.desc
            ++ [ Html.div [ classes [ statActionsPart ] ] (List.map leaf item.actions) ]
        )


stepHtml : Step -> Html msg
stepHtml step =
    Html.li
        [ classes ([ stepPart ] ++ opt SSteps.colorToClass step.color) ]
        (maybeHtml (\i -> Html.span [ classes [ stepIconPart ] ] [ Html.text i ]) step.icon
            ++ [ Html.text step.label ]
        )


tableHtml : TableConfig -> List (Row msg) -> Html msg
tableHtml config rows =
    let
        ( headers, body ) =
            List.partition .header rows
    in
    Html.div
        [ classes [ tokenOverflowXAuto ] ]
        [ Html.table
            [ classes
                ([ STable.component ]
                    ++ opt STable.sizeToClass config.size
                    ++ List.map STable.modifierToClass config.modifiers
                )
            ]
            [ Html.thead []
                (List.map (\r -> Html.tr [] (List.map (\c -> Html.th [] [ leaf c ]) r.cells)) headers)
            , Html.tbody []
                (List.map (\r -> Html.tr [] (List.map (\c -> Html.td [] [ leaf c ]) r.cells)) body)
            ]
        ]


tabHtml : Tab msg -> List (Html msg)
tabHtml tab =
    [ Html.a
        [ classes
            ([ tabPart ]
                ++ flag tab.active (STab.modifierToClass STab.Active)
                ++ flag tab.disabled (STab.modifierToClass STab.Disabled)
            )
        , Attr.attribute "role" "tab"
        ]
        [ Html.text tab.label ]
    , Html.div [ classes [ tabContentPart ] ] (List.map leaf tab.content)
    ]


timelineItemHtml : TimelineItem msg -> Html msg
timelineItemHtml item =
    Html.li []
        (maybeHtml (\s -> Html.div [ classes [ timelineStartPart ] ] [ Html.text s ]) item.start
            ++ maybeHtml (\m -> Html.div [ classes [ timelineMiddlePart ] ] [ leaf m ]) item.middle
            ++ maybeHtml (\e -> Html.div [ classes [ timelineEndPart ] ] [ Html.text e ]) item.end
        )



-- LEAF ----------------------------------------------------------------------


{-| Render one leaf.
-}
leaf : Leaf msg -> Html msg
leaf =
    leafWith []


leafWith : List String -> Leaf msg -> Html msg
leafWith extra theLeaf =
    case theLeaf of
        Avatar config src ->
            avatarHtml extra config src

        AvatarGroup items ->
            Html.div
                [ classes (avatarGroupClass :: extra) ]
                (List.map (\item -> avatarHtml [] item.config item.src) items)

        Badge config label ->
            badgeHtml extra config label

        Button config label ->
            buttonHtml extra config label

        Checkbox config ->
            Html.input
                (classes
                    ([ SCheckbox.component ]
                        ++ opt SCheckbox.colorToClass config.color
                        ++ opt SCheckbox.sizeToClass config.size
                        ++ extra
                    )
                    :: Attr.type_ "checkbox"
                    :: Attr.checked config.checked
                    :: onCheckAttrs config.onCheck
                )
                []
                |> withTooltip config.tooltip

        Countdown value ->
            Html.span
                [ classes (SCountdown.component :: extra) ]
                [ Html.span
                    [ Attr.style "--value" (String.fromInt (round value)) ]
                    [ Html.text (String.fromInt (round value)) ]
                ]

        Divider config label ->
            Html.div
                [ classes
                    ([ SDivider.component ]
                        ++ opt SDivider.colorToClass config.color
                        ++ opt SDivider.directionToClass config.direction
                        ++ opt SDivider.placementToClass config.placement
                        ++ extra
                    )
                ]
                [ Html.text (Maybe.withDefault "" label) ]
                |> withTooltip config.tooltip

        FileInput config ->
            Html.input
                (classes
                    ([ SFileInput.component ]
                        ++ opt SFileInput.colorToClass config.color
                        ++ opt SFileInput.styleToClass config.style
                        ++ opt SFileInput.sizeToClass config.size
                        ++ extra
                    )
                    :: Attr.type_ "file"
                    :: onInputAttrs config.onInput
                )
                []
                |> withTooltip config.tooltip

        Filter data ->
            filterHtml extra data

        HoverGallery srcs ->
            Html.figure
                [ classes (SHoverGallery.component :: extra) ]
                (List.map (\src -> Html.img [ Attr.src src, Attr.alt "" ] []) srcs)

        Image config src ->
            Html.img
                (classes (maskClasses config.mask ++ extra)
                    :: Attr.src src
                    :: Attr.alt config.alt
                    :: onClickAttrs config.onClick
                )
                []
                |> withHover3d config.hover3d
                |> withTooltip config.tooltip

        Input config ->
            inputHtml extra config

        Join config items ->
            Html.div
                [ classes ([ SJoin.component ] ++ opt SJoin.directionToClass config.direction ++ extra) ]
                (List.map joinItemHtml items)
                |> withTooltip config.tooltip

        Kbd config label ->
            Html.kbd
                [ classes ([ SKbd.component ] ++ opt SKbd.sizeToClass config.size ++ extra) ]
                [ Html.text label ]
                |> withTooltip config.tooltip

        Link config label ->
            linkHtml extra config label

        Loading config ->
            Html.span
                [ classes
                    ([ SLoading.component ]
                        ++ opt SLoading.styleToClass config.style
                        ++ opt SLoading.sizeToClass config.size
                        ++ extra
                    )
                ]
                []
                |> withTooltip config.tooltip

        Megamenu config items ->
            Html.div
                [ classes
                    ([ SMegamenu.component ]
                        ++ opt SMegamenu.sizeToClass config.size
                        ++ opt SMegamenu.directionToClass config.direction
                        ++ List.map SMegamenu.modifierToClass config.modifiers
                        ++ extra
                    )
                ]
                (List.map megamenuItemHtml items)
                |> withTooltip config.tooltip

        Otp config data ->
            Html.div
                [ classes
                    ([ SOtp.component ]
                        ++ opt SOtp.colorToClass config.color
                        ++ opt SOtp.sizeToClass config.size
                        ++ List.map SOtp.modifierToClass config.modifiers
                        ++ extra
                    )
                ]
                (List.map
                    (\_ ->
                        Html.input
                            (Attr.type_ "text" :: Attr.maxlength 1 :: onInputAttrs config.onInput)
                            []
                    )
                    (List.range 1 data.digits)
                )
                |> withTooltip config.tooltip

        Progress config data ->
            Html.progress
                [ classes ([ SProgress.component ] ++ opt SProgress.colorToClass config.color ++ extra)
                , Attr.value (String.fromFloat (Maybe.withDefault 0 data.value))
                , Attr.max (String.fromFloat data.max)
                ]
                []
                |> withTooltip config.tooltip

        RadialProgress data ->
            Html.div
                [ classes (SRadialProgress.component :: extra)
                , Attr.style "--value" (String.fromFloat data.value)
                , Attr.attribute "role" "progressbar"
                ]
                [ Html.text data.label ]

        Radio config data ->
            Html.input
                (classes
                    ([ SRadio.component ]
                        ++ opt SRadio.colorToClass config.color
                        ++ opt SRadio.sizeToClass config.size
                        ++ extra
                    )
                    :: Attr.type_ "radio"
                    :: Attr.name data.name
                    :: Attr.checked data.checked
                    :: onCheckAttrs config.onCheck
                )
                []
                |> withTooltip config.tooltip

        Range config data ->
            Html.input
                (classes
                    ([ SRange.component ]
                        ++ opt SRange.colorToClass config.color
                        ++ opt SRange.sizeToClass config.size
                        ++ opt SRange.directionToClass config.direction
                        ++ extra
                    )
                    :: Attr.type_ "range"
                    :: Attr.min (String.fromFloat data.min)
                    :: Attr.max (String.fromFloat data.max)
                    :: Attr.value (String.fromFloat data.value)
                    :: onInputAttrs config.onInput
                )
                []
                |> withTooltip config.tooltip

        Rating config data ->
            ratingHtml extra config data

        Select config data ->
            selectHtml extra config data

        Skeleton config ->
            Html.div
                [ classes
                    ([ SSkeleton.component ]
                        ++ List.map SSkeleton.modifierToClass config.modifiers
                        ++ extra
                    )
                ]
                []
                |> withTooltip config.tooltip

        Status config ->
            statusHtml extra config

        Swap config faces ->
            Html.label
                [ classes
                    ([ SSwap.component ]
                        ++ opt SSwap.styleToClass config.style
                        ++ List.map SSwap.modifierToClass config.modifiers
                        ++ extra
                    )
                ]
                ([ Html.input (Attr.type_ "checkbox" :: onCheckAttrs config.onCheck) []
                 , Html.div [ classes [ swapOnPart ] ] [ Html.text faces.on ]
                 , Html.div [ classes [ swapOffPart ] ] [ Html.text faces.off ]
                 ]
                    ++ maybeHtml
                        (\i -> Html.div [ classes [ swapIndeterminatePart ] ] [ Html.text i ])
                        faces.indeterminate
                )
                |> withTooltip config.tooltip

        Text value ->
            Html.text value

        TextRotate words ->
            Html.div
                [ classes (STextRotate.component :: extra) ]
                (List.map (\w -> Html.span [] [ Html.text w ]) words)

        Textarea config ->
            Html.textarea
                (classes
                    ([ STextarea.component ]
                        ++ opt STextarea.colorToClass config.color
                        ++ opt STextarea.styleToClass config.style
                        ++ opt STextarea.sizeToClass config.size
                        ++ extra
                    )
                    :: Attr.placeholder config.placeholder
                    :: Attr.value config.value
                    :: onInputAttrs config.onInput
                )
                []
                |> withTooltip config.tooltip

        ThemeSelect data ->
            themeSelectHtml extra data

        Toggle config data ->
            Html.input
                (classes
                    ([ SToggle.component ]
                        ++ opt SToggle.colorToClass config.color
                        ++ opt SToggle.sizeToClass config.size
                        ++ extra
                    )
                    :: Attr.type_ "checkbox"
                    :: Attr.checked data.checked
                    :: onCheckAttrs config.onCheck
                )
                []
                |> withTooltip config.tooltip


avatarHtml : List String -> AvatarConfig msg -> ImageSrc -> Html msg
avatarHtml extra config src =
    Html.div
        [ classes
            ([ SAvatar.component ]
                ++ List.map SAvatar.modifierToClass config.modifiers
                ++ extra
            )
        ]
        [ Html.div
            [ classes (maskClasses config.mask ++ [ tokenSizeIcon ]) ]
            [ Html.img [ Attr.src src, Attr.alt "" ] [] ]
        ]
        |> withIndicator config.indicator
        |> withTooltip config.tooltip
        |> withDropdown config.dropdown


badgeHtml : List String -> BadgeConfig -> String -> Html msg
badgeHtml extra config label =
    Html.span
        [ classes
            ([ SBadge.component ]
                ++ opt SBadge.colorToClass config.color
                ++ opt SBadge.styleToClass config.style
                ++ opt SBadge.sizeToClass config.size
                ++ extra
            )
        ]
        [ Html.text label ]
        |> withTooltip config.tooltip


buttonHtml : List String -> ButtonConfig msg -> String -> Html msg
buttonHtml extra config label =
    Html.button
        (classes
            ([ SButton.component ]
                ++ opt (SButton.colorToClass << Tree.buttonColorToSchema) config.color
                ++ opt SButton.styleToClass config.style
                ++ opt SButton.sizeToClass config.size
                ++ List.map SButton.modifierToClass config.modifiers
                ++ List.map SButton.behaviorToClass config.behaviors
                ++ extra
            )
            :: onClickAttrs config.onClick
        )
        [ Html.text label ]
        |> withIndicator config.indicator
        |> withTooltip config.tooltip
        |> withDropdown config.dropdown
        |> withAura config.aura


filterHtml : List String -> FilterData msg -> Html msg
filterHtml extra data =
    Html.form
        [ classes (SFilter.component :: extra) ]
        (flagHtml data.reset
            (Html.input
                [ classes [ filterResetPart, SButton.component ]
                , Attr.type_ "radio"
                , Attr.name data.name
                , Attr.attribute "aria-label" "×"
                ]
                []
            )
            ++ List.map
                (\option ->
                    Html.input
                        (classes [ SButton.component ]
                            :: Attr.type_ "radio"
                            :: Attr.name data.name
                            :: Attr.attribute "aria-label" option
                            :: Attr.checked (data.selected == Just option)
                            :: onClickAttrs (Maybe.map (\f -> f option) data.onSelect)
                        )
                        []
                )
                data.options
        )


inputHtml : List String -> InputConfig msg -> Html msg
inputHtml extra config =
    Html.input
        (classes
            ([ SInput.component ]
                ++ opt SInput.colorToClass config.color
                ++ opt SInput.styleToClass config.style
                ++ opt SInput.sizeToClass config.size
                ++ extra
            )
            :: Attr.type_ "text"
            :: Attr.placeholder config.placeholder
            :: Attr.value config.value
            :: onInputAttrs config.onInput
        )
        []
        |> withIndicator config.indicator
        |> withTooltip config.tooltip


joinItemHtml : JoinItem msg -> Html msg
joinItemHtml item =
    case item of
        JoinButton config label ->
            buttonHtml [ joinItemClass ] config label

        JoinInput config ->
            inputHtml [ joinItemClass ] config

        JoinSelect config data ->
            selectHtml [ joinItemClass ] config data

        JoinText value ->
            Html.span
                [ classes [ joinItemClass, tokenPaddingSm, tokenTextSm ] ]
                [ Html.text value ]


linkHtml : List String -> LinkConfig msg -> String -> Html msg
linkHtml extra config label =
    Html.a
        (classes
            ([ SLink.component ]
                ++ opt SLink.colorToClass config.color
                ++ opt SLink.styleToClass config.style
                ++ extra
            )
            :: Attr.href config.href
            :: onClickAttrs config.onClick
        )
        [ Html.text label ]
        |> withIndicator config.indicator
        |> withTooltip config.tooltip
        |> withDropdown config.dropdown


megamenuItemHtml : MegamenuItem msg -> Html msg
megamenuItemHtml item =
    Html.div
        [ classes (flag item.active megamenuActivePart) ]
        [ Html.button [ classes [ SButton.component ] ] [ Html.text item.label ]
        , menuHtml [] item.menu
        ]


ratingHtml : List String -> RatingConfig msg -> RatingData -> Html msg
ratingHtml extra config data =
    Html.div
        [ classes
            ([ SRating.component ]
                ++ opt SRating.sizeToClass config.size
                ++ List.map SRating.modifierToClass config.modifiers
                ++ extra
            )
        ]
        (List.map
            (\i ->
                Html.input
                    (classes [ SMask.component, SMask.styleToClass SMask.Star2 ]
                        :: Attr.type_ "radio"
                        :: Attr.name data.name
                        :: Attr.checked (i == data.value)
                        :: onClickAttrs (Maybe.map (\f -> f i) config.onRate)
                    )
                    []
            )
            (List.range 1 data.count)
        )
        |> withTooltip config.tooltip


selectHtml : List String -> SelectConfig msg -> SelectData -> Html msg
selectHtml extra config data =
    Html.select
        ([ classes
            ([ SSelect.component ]
                ++ opt SSelect.colorToClass config.color
                ++ opt SSelect.styleToClass config.style
                ++ opt SSelect.sizeToClass config.size
                ++ extra
            )
         ]
            -- A `select` outside a `Field` has no label to be named by, so its
            -- tooltip text — the only description the tree lets it carry —
            -- doubles as its accessible name.
            ++ optAttr (\t -> Attr.attribute "aria-label" t.text) config.tooltip
            ++ onInputAttrs config.onSelect
        )
        (List.map
            (\o ->
                Html.option
                    [ Attr.value o, Attr.selected (data.selected == Just o) ]
                    [ Html.text o ]
            )
            data.options
        )
        |> withTooltip config.tooltip


statusHtml : List String -> StatusConfig -> Html msg
statusHtml extra config =
    Html.span
        [ classes
            ([ SStatus.component ]
                ++ opt SStatus.colorToClass config.color
                ++ opt SStatus.sizeToClass config.size
                ++ extra
            )
        ]
        []
        |> withTooltip config.tooltip


themeSelectHtml : List String -> ThemeSelectData msg -> Html msg
themeSelectHtml extra data =
    Html.div
        [ classes ([ tokenFlex, tokenFlexWrap, tokenGapSm ] ++ extra) ]
        (List.map
            (\theme ->
                Html.input
                    (classes (SThemeController.component :: themePresentationClasses data.presentation)
                        :: Attr.type_ (themePresentationInputType data.presentation)
                        :: Attr.name "daisy-theme"
                        :: Attr.value (Tree.themeToString theme)
                        :: Attr.attribute "aria-label" (Tree.themeToString theme)
                        :: Attr.checked (theme == data.current)
                        :: onClickAttrs (Maybe.map (\f -> f theme) data.onSelect)
                    )
                    []
            )
            data.themes
        )


themePresentationClasses : ThemePresentation -> List String
themePresentationClasses presentation =
    case presentation of
        ThemeAsSelect ->
            [ SButton.component, SButton.sizeToClass SButton.Sm ]

        ThemeAsRadios ->
            [ SRadio.component ]

        ThemeAsToggle ->
            [ SToggle.component ]

        ThemeAsCheckbox ->
            [ SCheckbox.component ]

        ThemeAsSwap ->
            [ SSwap.component ]


themePresentationInputType : ThemePresentation -> String
themePresentationInputType presentation =
    case presentation of
        ThemeAsSelect ->
            "radio"

        ThemeAsRadios ->
            "radio"

        ThemeAsToggle ->
            "checkbox"

        ThemeAsCheckbox ->
            "checkbox"

        ThemeAsSwap ->
            "checkbox"



-- LEAF PROPERTIES -----------------------------------------------------------


maskClasses : Maybe MaskConfig -> List String
maskClasses maybe =
    case maybe of
        Nothing ->
            []

        Just config ->
            [ SMask.component ]
                ++ opt SMask.styleToClass config.style
                ++ List.map SMask.modifierToClass config.modifiers


withTooltip : Maybe Tooltip -> Html msg -> Html msg
withTooltip maybe html =
    case maybe of
        Nothing ->
            html

        Just t ->
            Html.div
                [ classes
                    ([ STooltip.component ]
                        ++ opt STooltip.colorToClass t.config.color
                        ++ opt STooltip.placementToClass t.config.placement
                        ++ List.map STooltip.modifierToClass t.config.modifiers
                    )
                ]
                [ Html.div [ classes [ tooltipContentPart ] ] [ Html.text t.text ]
                , html
                ]


withDropdown : Maybe (Dropdown msg) -> Html msg -> Html msg
withDropdown maybe html =
    case maybe of
        Nothing ->
            html

        Just d ->
            Html.div
                [ classes
                    ([ SDropdown.component ]
                        ++ opt SDropdown.placementToClass d.config.placement
                        ++ List.map SDropdown.modifierToClass d.config.modifiers
                    )
                ]
                [ html
                , menuHtml [ dropdownContentPart ] d.menu
                ]


withIndicator : Maybe Indicator -> Html msg -> Html msg
withIndicator maybe html =
    case maybe of
        Nothing ->
            html

        Just i ->
            -- `indicator-item` goes on the badge or status itself, not on a
            -- wrapper around it: that is how daisyUI documents every indicator
            -- example, and the part positions the element it is on.
            Html.div
                [ classes [ SIndicator.component ] ]
                [ indicatorPayloadHtml
                    (indicatorItemPart :: opt SIndicator.placementToClass i.config.placement)
                    i.payload
                , html
                ]


indicatorPayloadHtml : List String -> IndicatorPayload -> Html msg
indicatorPayloadHtml extra payload =
    case payload of
        IndicatorBadge config label ->
            badgeHtml extra config label

        IndicatorStatus config ->
            statusHtml extra config


withAura : Maybe AuraConfig -> Html msg -> Html msg
withAura maybe html =
    case maybe of
        Nothing ->
            html

        Just a ->
            Html.div
                [ classes
                    ([ SAura.component ]
                        ++ opt SAura.styleToClass a.style
                        ++ opt SAura.sizeToClass a.size
                    )
                ]
                [ html ]


withHover3d : Bool -> Html msg -> Html msg
withHover3d on html =
    if on then
        Html.div
            [ classes [ SHover3d.component ] ]
            (html :: List.map (\_ -> Html.div [] []) (List.range 1 8))

    else
        html



-- OVERLAYS AND FIXED CHROME -------------------------------------------------


overlayLayer : List (Overlay msg) -> Maybe (Dock msg) -> Maybe (Fab msg) -> Html msg
overlayLayer overlays maybeDock maybeFab =
    let
        isDrawer o =
            case o of
                Drawer _ _ ->
                    True

                _ ->
                    False

        isModal o =
            case o of
                Modal _ _ ->
                    True

                _ ->
                    False

        isToast o =
            case o of
                Toast _ _ ->
                    True

                _ ->
                    False

        ordered =
            List.filter isDrawer overlays
                ++ List.filter isModal overlays
                ++ List.filter isToast overlays
    in
    Html.div
        [ classes [ tokenFixed, tokenInset0, tokenZOverlay, tokenPointerEventsNone ] ]
        (List.map overlay ordered
            ++ maybeHtml dockHtml maybeDock
            ++ maybeHtml fabHtml maybeFab
        )


{-| Render one overlay. `page` always renders overlays in the order drawer,
modal, toast, inside a single fixed wrapper, so an application never chooses a
stacking order.
-}
overlay : Overlay msg -> Html msg
overlay theOverlay =
    case theOverlay of
        Drawer config sections ->
            Html.div
                [ classes
                    ([ SDrawer.component ]
                        ++ opt SDrawer.placementToClass config.placement
                        ++ List.map SDrawer.modifierToClass config.modifiers
                        ++ [ tokenPointerEventsAuto ]
                    )
                ]
                [ -- daisyUI's state checkbox: painted `h-0 w-0 opacity-0`, but
                  -- that still leaves it focusable and announced, so it is
                  -- taken out of the tab order and hidden from assistive tech.
                  Html.input
                    [ Attr.id config.id
                    , Attr.type_ "checkbox"
                    , Attr.tabindex -1
                    , Attr.attribute "aria-hidden" "true"
                    , classes [ drawerTogglePart ]
                    ]
                    []
                , Html.div
                    [ classes [ drawerContentPart ] ]
                    [ Html.label
                        [ Attr.for config.id, classes [ drawerButtonPart, SButton.component ] ]
                        [ Html.text config.toggleLabel ]
                    ]
                , Html.div
                    [ classes [ drawerSidePart ] ]
                    [ Html.label [ Attr.for config.id, classes [ drawerOverlayPart ] ] []
                    , Html.div
                        [ classes [ tokenWSidebar, tokenMinHScreen, tokenBgBase, tokenPadding ] ]
                        (List.map section sections)
                    ]
                ]

        Modal config blocks ->
            Html.node "dialog"
                ([ classes
                    ([ SModal.component ]
                        ++ opt SModal.placementToClass config.placement
                        ++ List.map SModal.modifierToClass config.modifiers
                        ++ [ tokenPointerEventsAuto ]
                    )
                 , Attr.id config.id
                 ]
                    ++ flagAttrs (List.member SModal.Open config.modifiers)
                        (Attr.attribute "open" "")
                    ++ optAttr (Attr.attribute "aria-label") config.title
                    ++ onDismissAttrs config.onClose
                )
                [ Html.input
                    [ Attr.id (config.id ++ "-toggle")
                    , Attr.type_ "checkbox"
                    , Attr.tabindex -1
                    , Attr.attribute "aria-hidden" "true"
                    , classes [ modalTogglePart ]
                    ]
                    []
                , Html.div
                    [ classes [ modalBoxPart ] ]
                    (maybeHtml
                        (\t -> Html.h3 [ classes [ tokenFontBold ] ] [ Html.text t ])
                        config.title
                        ++ List.map block blocks
                        ++ [ Html.div
                                [ classes [ modalActionPart ] ]
                                (List.map leaf config.actions)
                           ]
                    )
                , Html.label
                    [ Attr.for (config.id ++ "-toggle")
                    , Attr.attribute "aria-hidden" "true"
                    , classes [ modalBackdropPart ]
                    ]
                    []
                ]

        Toast config blocks ->
            Html.div
                [ classes
                    ([ SToast.component ]
                        ++ opt SToast.placementToClass config.placement
                        ++ [ tokenPointerEventsAuto ]
                    )
                ]
                (List.map block blocks)


dockHtml : Dock msg -> Html msg
dockHtml dock =
    Html.div
        [ classes
            ([ SDock.component ]
                ++ opt SDock.sizeToClass dock.config.size
                ++ [ tokenPointerEventsAuto ]
            )
        ]
        (List.map
            (\item ->
                Html.button
                    (classes (flag item.active (SDock.modifierToClass SDock.Active))
                        :: onClickAttrs item.onClick
                    )
                    (maybeHtml
                        (\icon -> Html.span [ classes [ tokenSizeIcon ] ] [ Html.text icon ])
                        item.icon
                        ++ [ Html.span [ classes [ dockLabelPart ] ] [ Html.text item.label ] ]
                    )
            )
            dock.items
        )


fabHtml : Fab msg -> Html msg
fabHtml fab =
    Html.div
        [ classes
            ([ SFab.component ]
                ++ List.map SFab.modifierToClass fab.config.modifiers
                ++ [ tokenPointerEventsAuto ]
            )
        ]
        ([ Html.div
            [ Attr.tabindex 0, Attr.attribute "role" "button" ]
            [ leaf fab.main ]
         , Html.div [ classes [ fabMainActionPart ] ] [ leaf fab.main ]
         ]
            ++ List.map (\a -> Html.div [] [ leaf a ]) fab.actions
            ++ maybeHtml (\c -> Html.div [ classes [ fabClosePart ] ] [ leaf c ]) fab.close
        )



-- CHARTS --------------------------------------------------------------------


type alias Point =
    { x : Float
    , label : String
    , values : List Float
    }


toPoints : ChartData -> List Point
toPoints data =
    List.indexedMap
        (\i label ->
            { x = toFloat i
            , label = label
            , values = List.map (pointAt i) data.series
            }
        )
        data.xLabels


pointAt : Int -> Series -> Float
pointAt i series =
    List.drop i series.points |> List.head |> Maybe.withDefault 0


valueAt : Int -> Point -> Float
valueAt i point =
    List.drop i point.values |> List.head |> Maybe.withDefault 0


labelFor : List String -> Float -> String
labelFor labels value =
    List.drop (round value) labels |> List.head |> Maybe.withDefault ""


chartHtml : ChartConfig -> ChartData -> Html msg
chartHtml config data =
    Html.div
        [ classes [ tokenChartHeight, tokenWFull, tokenPadding ] ]
        [ case config of
            Line ->
                seriesChart [ CA.monotone ] data

            Area ->
                seriesChart [ CA.monotone, CA.opacity 0.25 ] data

            Bar ->
                barChart False data

            StackedBar ->
                barChart True data

            Donut ->
                donutChart data
        ]


seriesChart : List (CA.Attribute CS.Interpolation) -> ChartData -> Html msg
seriesChart interpolation data =
    let
        points =
            toPoints data
    in
    C.chart
        [ CA.height chartHeight, CA.width chartWidth, CA.margin chartMargin ]
        [ C.yLabels [ CA.withGrid ]
        , C.xLabels
            [ CA.amount (List.length data.xLabels)
            , CA.ints
            , CA.format (labelFor data.xLabels)
            ]
        , C.series .x
            (List.indexedMap
                (\i s ->
                    C.named s.name
                        (C.interpolated (valueAt i)
                            (CA.color (Chart.semanticColorToCss s.color) :: interpolation)
                            []
                        )
                )
                data.series
            )
            points
        ]


barChart : Bool -> ChartData -> Html msg
barChart stacked data =
    let
        points =
            toPoints data

        properties =
            List.indexedMap
                (\i s ->
                    C.named s.name
                        (C.bar (valueAt i) [ CA.color (Chart.semanticColorToCss s.color) ])
                )
                data.series
    in
    C.chart
        [ CA.height chartHeight, CA.width chartWidth, CA.margin chartMargin ]
        [ C.yLabels [ CA.withGrid ]
        , C.binLabels .label [ CA.moveDown 18 ]
        , C.bars []
            (if stacked then
                [ C.stacked properties ]

             else
                properties
            )
            points
        ]


{-| elm-charts' default margin is zero on every side, which puts the axis
labels _outside_ the SVG box (the container's `overflow: visible` then lets
them spill over whatever sits next to the chart). This reserves room for them
inside the drawing instead.
-}
chartMargin : { top : Float, bottom : Float, left : Float, right : Float }
chartMargin =
    { top = 10, bottom = 26, left = 42, right = 14 }


chartHeight : Float
chartHeight =
    240


chartWidth : Float
chartWidth =
    640


{-| elm-charts has no pie or donut element, so this one is hand-rolled SVG. It
is drawn as one ring of stroked arcs, which needs no arc-path maths and keeps
the whole thing inside this module.
-}
donutChart : ChartData -> Html msg
donutChart data =
    let
        totals =
            List.map (\s -> ( s, List.sum s.points )) data.series

        total =
            List.sum (List.map Tuple.second totals)

        circumference =
            2 * pi * donutRadius

        segment ( s, value, offset ) =
            let
                length =
                    if total <= 0 then
                        0

                    else
                        value / total * circumference
            in
            Svg.circle
                [ SvgA.cx "50"
                , SvgA.cy "50"
                , SvgA.r (String.fromFloat donutRadius)
                , SvgA.fill "none"
                , SvgA.stroke (Chart.semanticColorToCss s.color)
                , SvgA.strokeWidth "14"
                , SvgA.strokeDasharray (String.fromFloat length ++ " " ++ String.fromFloat circumference)
                , SvgA.strokeDashoffset (String.fromFloat -offset)
                , SvgA.transform "rotate(-90 50 50)"
                ]
                []

        withOffsets =
            List.foldl
                (\( s, value ) ( acc, running ) ->
                    ( acc ++ [ ( s, value, running / max total 1 * circumference ) ]
                    , running + value
                    )
                )
                ( [], 0 )
                totals
                |> Tuple.first
    in
    Svg.svg
        [ SvgA.viewBox "0 0 100 100"
        , SvgA.width "100%"

        -- A square viewBox with `height="100%"` against an auto-height parent
        -- resolves to the intrinsic 1:1 ratio, i.e. as tall as the block is
        -- wide. Pinning the height to `chartHeight` keeps a donut the same
        -- height as every other chart and inside `tokenChartHeight`.
        , SvgA.height (String.fromFloat chartHeight)
        ]
        (List.map segment withOffsets)


donutRadius : Float
donutRadius =
    40
