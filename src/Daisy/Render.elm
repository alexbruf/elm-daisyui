module Daisy.Render exposing
    ( page
    , section, block, leaf, overlay
    , initCalendarDate, initCalendarRange, initCalendarMulti, updateCalendar
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


# The calendar picker's state

`Leaf.Calendar` is the one leaf whose state the application has to keep, and
these are the three constructors and the one `update` that go with it. They
live here rather than in `Daisy.Tree` because they need the
`alexbruf/elm-cally` `Config` record that this module builds out of
`Daisy.Tree.CalendarConfig` — the same record `Leaf.Calendar` is rendered
with, so paging and focus behave the same in `update` as they look in `view`.
`Daisy.Tree.setCalendarValue` completes the loop on the way back.

@docs initCalendarDate, initCalendarRange, initCalendarMulti, updateCalendar


# Class budget

@docs tokens, unreachableClasses

-}

import Cally.Context as CallyContext
import Cally.Date as CallyDate
import Cally.Locale as CallyLocale
import Cally.Month as CallyMonth
import Cally.Multi as CallyMulti
import Cally.Range as CallyRange
import Chart as C
import Chart.Attributes as CA
import Chart.Svg as CS
import Daisy.Chart as Chart exposing (ChartConfig(..), ChartData, Series)
import Daisy.Icon as Icon exposing (Icon)
import Daisy.Render.Icons as Icons
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
import Date exposing (Date)
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
    , tokenGridCols2Lg
    , tokenGridCols3Lg
    , tokenGridCols4Lg
    , tokenGapSm
    , tokenGap
    , tokenGapMd
    , tokenGapLg
    , tokenPaddingSm
    , tokenPadding
    , tokenPaddingLg
    , tokenItemsStart
    , tokenItemsCenter
    , tokenItemsEnd
    , tokenItemsStretch
    , tokenJustifyBetween
    , tokenJustifyCenter
    , tokenGrow
    , tokenShrink0
    , tokenMtAuto
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
    , tokenStatsHorizontalLg
    , tokenProse
    , tokenBgBase
    , tokenBgGround
    , tokenBgBase300
    , tokenTextBaseContent
    , tokenBgPrimary
    , tokenTextPrimaryContent
    , tokenBgSecondary
    , tokenTextSecondaryContent
    , tokenBgAccent
    , tokenTextAccentContent
    , tokenBgNeutral
    , tokenTextNeutralContent
    , tokenBgInfo
    , tokenTextInfoContent
    , tokenBgSuccess
    , tokenTextSuccessContent
    , tokenBgWarning
    , tokenTextWarningContent
    , tokenBgError
    , tokenTextErrorContent
    , tokenShadowSm
    , tokenRoundedLg
    , tokenTextXs
    , tokenTextSm
    , tokenTextBase
    , tokenTextMuted
    , tokenFontMedium
    , tokenFontBold
    , tokenFontSemibold
    , tokenHeading1
    , tokenHeading2
    , tokenHeading3
    , tokenSizeIconSm
    , tokenSizeIcon
    , tokenSizeIconLg
    , tokenSizeAvatar
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


tokenGridCols2Lg : String
tokenGridCols2Lg =
    "lg:grid-cols-2"


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


{-| The gap between the bands of a page: `gap-6`, 24px.

daisyUI's own dashboard templates set every vertical rhythm on a page from this
one step — between the header row and the first band, and between one band and
the next — while the blocks _inside_ a band sit at `tokenGap` (16px). `gap-8`
below is the wider rhythm a `Footer` uses, where the columns are unrelated.

-}
tokenGapMd : String
tokenGapMd =
    "gap-6"


tokenGapLg : String
tokenGapLg =
    "gap-8"


tokenPaddingSm : String
tokenPaddingSm =
    "p-2"


tokenPadding : String
tokenPadding =
    "p-4"


{-| The content column's gutter: `p-6`, 24px.

The same figure daisyUI's dashboard templates set on the region between the
navbar and the sidebar. `tokenPadding` (16px) stays the chrome's gutter — the
navbar, a mockup frame — because a 24px navbar would be taller than the 64px row
every one of those templates uses.

-}
tokenPaddingLg : String
tokenPaddingLg =
    "p-6"


tokenItemsStart : String
tokenItemsStart =
    "items-start"


tokenItemsCenter : String
tokenItemsCenter =
    "items-center"


tokenItemsEnd : String
tokenItemsEnd =
    "items-end"


tokenItemsStretch : String
tokenItemsStretch =
    "items-stretch"


tokenJustifyBetween : String
tokenJustifyBetween =
    "justify-between"


tokenJustifyCenter : String
tokenJustifyCenter =
    "justify-center"


{-| `grow`: the one flex child of a fixed-height column that takes the slack —
the sidebar's `menu` between the brand row and the footer, and the text column
of a `Leaf.UserChip` between the portrait and the edge.
-}
tokenGrow : String
tokenGrow =
    "grow"


{-| The flex child that must keep its natural width.

A `breadcrumbs` trail is `overflow-x: auto`, so a flex parent is free to shrink
it below its content and let the tail scroll out of sight — which is what the
page header's `justify-between` row did to the last crumb. `shrink-0` on the
group that holds it says the row wraps instead.

-}
tokenShrink0 : String
tokenShrink0 =
    "shrink-0"


{-| Pins the last child of the sidebar column to the bottom of the panel.
-}
tokenMtAuto : String
tokenMtAuto =
    "mt-auto"


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
container and derives the drawn height from the `chartWidth : chartViewboxHeight`
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


{-| Tailwind's `lg` variant prefix. Never emitted on its own: it only exists so
a responsive class can be built from a schema class instead of being retyped as
a literal.
-}
tokenLgPrefix : String
tokenLgPrefix =
    "lg:"


{-| daisyUI's own responsive `stats` idiom, `stats-vertical lg:stats-horizontal`
(`StatDirection.Responsive`). The class name comes from
`Daisy.Schema.Stat.directionToClass`, so widening the schema renames this too.
-}
tokenStatsHorizontalLg : String
tokenStatsHorizontalLg =
    tokenLgPrefix ++ SStat.directionToClass SStat.Horizontal


tokenProse : String
tokenProse =
    "prose"


tokenBgBase : String
tokenBgBase =
    "bg-base-100"


{-| The page ground a dashboard is drawn on: `bg-base-200`, one step darker
than the panels that sit on it.

daisyUI's dashboard examples paint the _content area_ with it and leave the
navbar, the sidebar and every card at `bg-base-100`, which is what makes a card
read as a raised panel instead of a bordered region of the same paper. It goes
on `drawer-content` under `Shell.Dashboard` and on the `<main>` under
`Shell.Plain`; the page root keeps `tokenBgBase`, so nothing behind the content
column changes colour.

-}
tokenBgGround : String
tokenBgGround =
    "bg-base-200"


{-| The eighteen utilities `Leaf.Swatch` paints a palette chip with, plus the
two above it: one `bg-*` per surface and the `text-*-content` that reads on it.

They are the only tokens in this table that are _colours_. Everywhere else the
renderer leaves colour to daisyUI's own component classes, because a component
carries its own pair; a swatch is not a component — it is a picture of a theme
variable — so the pair has to be named here. Each constant has exactly one use
site, the `swatchClasses` table below, and there is no way for a caller to reach
one: `Leaf.Swatch` takes a `Daisy.Tree.SwatchColor`, never a class.

`bg-primary` therefore left `tests/RenderPurityTest.elm`'s `forbidden` list in
this pass, by the same rule `gap-6` and `rounded-lg` left it in the Nexus pass —
it became one named constant with one job. `text-primary` did **not**: no swatch
needs it, and a `-content` colour is not the same utility.

-}
tokenBgBase300 : String
tokenBgBase300 =
    "bg-base-300"


tokenTextBaseContent : String
tokenTextBaseContent =
    "text-base-content"


tokenBgPrimary : String
tokenBgPrimary =
    "bg-primary"


tokenTextPrimaryContent : String
tokenTextPrimaryContent =
    "text-primary-content"


tokenBgSecondary : String
tokenBgSecondary =
    "bg-secondary"


tokenTextSecondaryContent : String
tokenTextSecondaryContent =
    "text-secondary-content"


tokenBgAccent : String
tokenBgAccent =
    "bg-accent"


tokenTextAccentContent : String
tokenTextAccentContent =
    "text-accent-content"


tokenBgNeutral : String
tokenBgNeutral =
    "bg-neutral"


tokenTextNeutralContent : String
tokenTextNeutralContent =
    "text-neutral-content"


tokenBgInfo : String
tokenBgInfo =
    "bg-info"


tokenTextInfoContent : String
tokenTextInfoContent =
    "text-info-content"


tokenBgSuccess : String
tokenBgSuccess =
    "bg-success"


tokenTextSuccessContent : String
tokenTextSuccessContent =
    "text-success-content"


tokenBgWarning : String
tokenBgWarning =
    "bg-warning"


tokenTextWarningContent : String
tokenTextWarningContent =
    "text-warning-content"


tokenBgError : String
tokenBgError =
    "bg-error"


tokenTextErrorContent : String
tokenTextErrorContent =
    "text-error-content"


{-| The one elevation this package uses, on every `card`.

daisyUI's `.card` deliberately paints no shadow of its own — every docs example
adds `shadow-sm` as a utility beside it — so the renderer emits it rather than
leaving each caller to remember. It is a Tailwind utility, not a daisyUI class,
so a corpus fixture (which compares `$$`-prefixed daisyUI classes only) is
unaffected.

-}
tokenShadowSm : String
tokenShadowSm =
    "shadow-sm"


{-| The fixed 8px corner of the small painted surfaces the renderer draws
itself: a `stat-figure`'s tile, a `Leaf.UserChip`'s panel.

Deliberately **not** `rounded-box`. That utility resolves to `--radius-box`,
which is 1rem in daisyUI's stock themes and 2rem in a few of them, so a 36px
square would come out a circle. daisyUI's own templates override `--radius-box`
to 4px before using it there; a package cannot, so the corner is a constant.

-}
tokenRoundedLg : String
tokenRoundedLg =
    "rounded-lg"


{-| The caption step, 12px: the second line of a `Leaf.UserChip`, a chart
legend.
-}
tokenTextXs : String
tokenTextXs =
    "text-xs"


tokenTextSm : String
tokenTextSm =
    "text-sm"


{-| 16px: a `card-title` in a dashboard.

daisyUI's `.card-title` is 1.25rem/600, which is a heading for a marketing card.
Every card in daisyUI's dashboard templates is a panel in a grid of panels
instead, and titles them one step down at 1rem/500 — `tokenTextBase` with
`tokenFontMedium` — so the panel's _content_ is what the eye lands on.

-}
tokenTextBase : String
tokenTextBase =
    "text-base"


{-| De-emphasised body text: `text-base-content/60`.

This is the very colour daisyUI paints `.stat-title`, `.stat-desc` and a table
header with — `color-mix(in oklab, var(--color-base-content) 60%, transparent)`
— written as a Tailwind utility so the renderer can reach it on an element that
is not one of those parts (a chart's caption, a user chip's handle).

It carries daisyUI's own contrast trade-off with it: 60% of `--color-base-content`
is under 4.5:1 against `--color-base-100` in some themes. `e2e/contrast.spec.ts`
classifies a translucent `--color-base-content` as daisyUI's own colour pair for
exactly that reason, and it is the reason no _new_ de-emphasis level was
invented here.

-}
tokenTextMuted : String
tokenTextMuted =
    "text-base-content/60"


tokenFontMedium : String
tokenFontMedium =
    "font-medium"


tokenFontBold : String
tokenFontBold =
    "font-bold"


tokenFontSemibold : String
tokenFontSemibold =
    "font-semibold"


{-| `Leaf.Heading`'s fixed type scale (`docs/demo-findings.md` item 10): each
`HeadingLevel` gets a named size token instead of relying on `Block.Prose`'s
Tailwind Typography styling, which the demo app never loads.
-}
tokenHeading1 : String
tokenHeading1 =
    "text-3xl"


tokenHeading2 : String
tokenHeading2 =
    "text-2xl"


tokenHeading3 : String
tokenHeading3 =
    "text-xl"


{-| `IconSize.IconSm`: a glyph inside a control, where the control's own line
height is the budget (a `btn-xs` row action, a leading button icon).
-}
tokenSizeIconSm : String
tokenSizeIconSm =
    "size-4"


{-| `IconSize.IconMd`, and the fixed size of every non-`Leaf.Icon` glyph the
renderer draws: the calendar's paging arrows, an avatar's image box, a menu
item's icon.
-}
tokenSizeIcon : String
tokenSizeIcon =
    "size-5"


{-| `IconSize.IconLg`: a glyph that is the content rather than a decoration,
e.g. a `stat-figure`.
-}
tokenSizeIconLg : String
tokenSizeIconLg =
    "size-6"


{-| A portrait: 32px, the size daisyUI's own examples give an `avatar` in a
navbar, a table row or a chat bubble. It is a `size-*` utility rather than
daisyUI's `w-*`/`h-*` pair for the same reason `tokenSizeIcon` is.
-}
tokenSizeAvatar : String
tokenSizeAvatar =
    "size-8"


{-| The daisyUI classes that no `Daisy.Tree` value can reach.

`CoverageTest` asserts that the classes emitted across all constructors equal
`Daisy.Schema.allClasses` minus this list. Keeping it short is the point: four
entries out of 554.

-}
unreachableClasses : List String
unreachableClasses =
    [ -- `cally` (index 0) is reachable: `Leaf.Calendar` renders the
      -- `alexbruf/elm-cally` picker, which produces the very markup and `part`
      -- attributes daisyUI's `calendar.css` styles. The other two `calendar`
      -- component classes stay unreachable: `react-day-picker` and `vc` are
      -- theming hooks for a React component and a JavaScript library that this
      -- package does not render, so emitting them would need foreign markup.
      classAt 1 SCalendar.componentClasses
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


{-| The same, for an SVG element. `Html.Attributes.class` sets the `className`
_property_, which is read-only on an `SVGElement`, so an SVG node needs the
attribute form.
-}
svgClasses : List String -> Html.Attribute msg
svgClasses list =
    SvgA.class (String.join " " (List.filter (\c -> c /= "") list))


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


{-| The accessible name of a bare control.

A control inside a `Field` is named by the `<label>` that wraps it, but one in
a navbar or a toolbar has no label at all. `ariaLabel` is the name the author
wrote; with none, the control's tooltip text is the only description the tree
lets it carry, so it doubles as the name (which is what the a11y spec found the
Analytics navbar `select` needed).

-}
ariaLabelAttrs : Maybe String -> Maybe Tooltip -> List (Html.Attribute msg)
ariaLabelAttrs explicit tip =
    case explicit of
        Just label ->
            [ Attr.attribute "aria-label" label ]

        Nothing ->
            optAttr (\t -> Attr.attribute "aria-label" t.text) tip



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
        (Attr.attribute "data-theme" (Tree.themeToString p.theme)
            :: classes [ tokenMinHScreen, tokenBgBase ]
            :: themeAttrs p.theme
        )
        (shell p.shell p.header p.cta p.sections
            ++ [ overlayLayer p.overlays p.dock p.fab ]
        )


{-| The inline half of theming.

A built-in theme needs nothing here: daisyUI's stylesheet already carries a
`[data-theme=dark]` rule with all twenty-nine declarations in it, and the
`data-theme` attribute above selects it.

A `Theme.Custom` has no such rule — it is a value the application made up at
run time, and a stylesheet cannot be written from a value — so the same
twenty-nine declarations go on this element as inline custom properties. That is
enough, because daisyUI never reads them where they are _defined_: every use in
its component CSS is a `var(--color-primary)`, a `color-mix(... var(--color-base-content) ...)`
or a `calc(var(--depth) * 30%)` inside a declaration on the component itself,
and none of the variables is registered with `@property { inherits: false }`.
So a definition on an ancestor reaches every component below it exactly as a
`[data-theme]` rule would — `--depth` and `--noise` included.

It is **one** `style` attribute rather than a `Html.Attributes.style` per
property, and that is not a tidiness choice: `elm/virtual-dom` applies a style
node with `element.style[key] = value`, and a `CSSStyleDeclaration` silently
ignores an assignment to `"--color-primary"` — custom properties need
`setProperty`, which Elm never calls. `Attr.attribute "style"` goes through
`setAttribute` instead, so the CSS parser reads the declarations and they take
effect. `Daisy.Tree.customThemeStyle` builds the string, so no CSS variable name
is written in this module.

-}
themeAttrs : Theme -> List (Html.Attribute msg)
themeAttrs theme =
    case theme of
        Custom custom ->
            [ Attr.attribute "style" (Tree.customThemeStyle custom) ]

        _ ->
            []


shell : Shell msg -> Maybe (PageHeader msg) -> Cta msg -> Sections msg -> List (Html msg)
shell theShell theHeader theCta theSections =
    case theShell of
        Plain ->
            [ Html.main_
                [ classes
                    [ tokenFlex
                    , tokenFlexCol
                    , tokenGapMd
                    , tokenPaddingLg
                    , tokenMinHScreen
                    , tokenBgGround
                    , tokenTextSm
                    ]
                ]
                (maybeHtml pageHeaderHtml theHeader
                    ++ sectionList [ ctaHtml theCta ] theSections
                )
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
                    [ classes [ drawerContentPart, tokenFlex, tokenFlexCol, tokenMinHScreen, tokenBgGround ] ]
                    [ navbarHtml
                        { start = d.navbar.start
                        , center = d.navbar.center
                        , end = d.navbar.end
                        }
                        [ shellDrawerButton ]
                        [ ctaHtml theCta ]
                    , Html.main_
                        [ classes [ tokenFlex, tokenFlexCol, tokenGapMd, tokenPaddingLg, tokenTextSm ] ]
                        (maybeHtml pageHeaderHtml theHeader
                            ++ sectionList [] theSections
                        )
                    ]
                , Html.div
                    [ classes [ drawerSidePart ] ]
                    [ Html.label
                        [ Attr.for shellDrawerId, classes [ drawerOverlayPart ] ]
                        []
                    , sidebarHtml d
                    ]
                ]
            ]


{-| The sidebar panel: an optional brand row, the menu, and an optional footer
pinned to the bottom of the column.

The panel, not the `menu`, is what carries the width and the surface now: with a
brand row above the menu and a user chip below it, the three have to share one
`bg-base-100` column of a fixed width, which is how daisyUI's own dashboard
templates build it.

-}
sidebarHtml : DashboardShell msg -> Html msg
sidebarHtml d =
    Html.div
        [ classes
            [ tokenFlex
            , tokenFlexCol
            , tokenWSidebar
            , tokenMinHScreen
            , tokenBgBase
            , tokenTextSm
            ]
        ]
        (maybeHtml brandHtml d.brand
            ++ [ menuHtml [ tokenWFull, tokenGrow ] d.sidebar ]
            ++ maybeHtml
                (\f -> Html.div [ classes [ tokenPaddingSm, tokenMtAuto ] ] [ leaf f ])
                d.sidebarFooter
        )


brandHtml : Brand -> Html msg
brandHtml b =
    Html.div
        [ classes [ tokenFlex, tokenItemsCenter, tokenGapSm, tokenPadding ] ]
        [ iconHtml [] brandIconConfig b.icon
        , Html.span [ classes [ tokenHeading3, tokenFontSemibold ] ] [ Html.text b.name ]
        ]


brandIconConfig : IconConfig
brandIconConfig =
    { size = IconLg, label = Nothing }


{-| The page's title bar: the name on the left, the `breadcrumbs` trail and any
`actions` on the right.

It is rendered by the shell, above the sections and inside the same content
column, so it lands in the same place whichever shell the page uses and it costs
none of the five-section budget.

-}
pageHeaderHtml : PageHeader msg -> Html msg
pageHeaderHtml h =
    Html.div
        [ classes
            [ tokenFlex
            , tokenFlexWrap
            , tokenItemsCenter
            , tokenJustifyBetween
            , tokenGap
            ]
        ]
        (Html.h1
            [ classes [ tokenTextBase, tokenFontSemibold ] ]
            [ Html.text h.title ]
            :: (if List.isEmpty h.actions then
                    -- With nothing beside it, the trail is a direct child of
                    -- the row. daisyUI gives `.breadcrumbs` `margin-inline-
                    -- start: -.25rem` and its `<ul>` a matching
                    -- `padding-inline-start`, so the element's *outer* width is
                    -- 4px less than its content — and since it is also
                    -- `max-width: 100%; overflow-x: auto`, a parent sized to
                    -- that outer width clips the last 4px of the last crumb.
                    -- A parent that is the whole row cannot.
                    breadcrumbsHtml h.breadcrumbs

                else
                    [ Html.div
                        [ classes
                            [ tokenFlex
                            , tokenFlexWrap
                            , tokenItemsCenter
                            , tokenGap
                            , tokenShrink0
                            ]
                        ]
                        (breadcrumbsHtml h.breadcrumbs ++ List.map leaf h.actions)
                    ]
               )
        )


shellDrawerId : String
shellDrawerId =
    "daisy-shell-drawer"


{-| daisyUI's `drawer-button`, offered at every width.

It used to be `lg:hidden`, on the grounds that `lg:drawer-open` docks the
sidebar from `lg` up so the control has nothing left to do there. daisyUI's own
dashboard templates keep it in the navbar at every width anyway — it is the
left-most control of the row, and the row reads as broken without it — so it
stays visible and is simply inert once the sidebar is docked.

-}
shellDrawerButton : Html msg
shellDrawerButton =
    Html.label
        [ Attr.for shellDrawerId
        , classes
            [ drawerButtonPart
            , SButton.component
            , SButton.styleToClass SButton.Ghost
            , SButton.sizeToClass SButton.Sm
            , SButton.modifierToClass SButton.Square
            ]
        ]
        -- The name is on the glyph, not on the `<label>`: a `<label>` has no
        -- implicit ARIA role, so `aria-label` on it is `aria-prohibited-attr`
        -- (serious) — the label takes its name from its content instead.
        [ iconHtml [] { size = IconMd, label = Just "Toggle navigation" } Icon.Menu ]


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
        (maybeHtml (iconHtml [] buttonIconConfig) c.icon ++ [ Html.text c.label ])
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


{-| The navbar, with the page's own gutter.

daisyUI's `.navbar` pads itself by `0.5rem`, which is less than the overhang of
an `indicator-item`: daisyUI translates that part 50% of its own width past the
corner of the element it annotates, so a notification badge on the last control
of a wrapped `navbar-end` hung ~3px past the viewport at 768 and gave the
document a horizontal scrollbar (`e2e/overflow.spec.ts`). `tokenPadding` is the
same `p-4` the `<main>` content column already uses, so the chrome and the
content now share one gutter and an out-of-flow decoration has room to sit in.

The gutter _between_ the controls of a part is `tokenGap` (16px) for the same
reason, one scale down: an `indicator-item` reaches half its own width past the
corner of the control it annotates — about 8px for a `badge-xs` — so an 8px gap
let a notification badge sit on top of the next control in the row
(`e2e/overlap.spec.ts`, which exempts an `indicator-item` only _inside its own_
`.indicator`).

-}
navbarHtml : NavbarParts msg -> List (Html msg) -> List (Html msg) -> Html msg
navbarHtml parts before after =
    Html.div
        [ classes [ SNavbar.component, tokenBgBase, tokenGapSm, tokenPadding ] ]
        -- `navbar-start` and `navbar-end` are each exactly 50% wide, so their
        -- contents overlap rather than shrink once they no longer fit; they
        -- wrap inside their own half instead.
        [ Html.div
            [ classes [ navbarStartPart, tokenFlexWrap, tokenGap ] ]
            (before ++ List.map leaf parts.start)
        , Html.div [ classes [ navbarCenterPart ] ] (List.map leaf parts.center)
        , Html.div
            [ classes [ navbarEndPart, tokenFlexWrap, tokenGap ] ]
            (List.map leaf parts.end ++ after)
        ]


{-| Column tracks for a `Section.Grid`.

`grid-cols-N` on its own is `repeat(N, minmax(0, 1fr))`, so at 375px four
tracks are ~85px wide and every child wider than its track spills over its
neighbour. The counts are therefore breakpoints, not a constant: one column on
a phone, and the asked-for count from `sm` (`Cols3`/`Cols4`, whose cells are
tiles) or from `lg` (`Cols2`, whose cells are panels). `Cols1` has nothing to
step through.

-}
gridColumnsTokens : GridColumns -> List String
gridColumnsTokens columns =
    case columns of
        Cols1 ->
            [ tokenGridCols1 ]

        Cols2 ->
            -- `lg`, not `sm`. A two-column band is two *panels* — a card with a
            -- table in it, a form group — and at 768 a half of the content
            -- column is 304px of card body, which is narrower than the
            -- min-content width of a six-column table (checkbox, thumbnail and
            -- name, price, date, status, two row actions). The table then
            -- renders wider than its own card and reaches over the panel
            -- beside it (`e2e/overlap.spec.ts`). Cols3 and Cols4 step through
            -- `sm` because their cells are tiles, not panels.
            [ tokenGridCols1, tokenGridCols2Lg ]

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

        AlignStretch ->
            tokenItemsStretch


flagHtml : Bool -> Html msg -> List (Html msg)
flagHtml on html =
    if on then
        [ html ]

    else
        []



-- BLOCK ---------------------------------------------------------------------


{-| Where a block sits.

Two things depend on it. The `footer-title` part is emitted for a `Nav` block
only when the block is a direct child of a `Footer` section, so the part can
never escape its component. And a `stats` container paints its own panel
(`bg-base-100 shadow-sm`) everywhere except `InCard`, where the card is already
that panel.

-}
type BlockContext
    = InFooter
    | InCard
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
            alertHtml config leaves

        Breadcrumbs leaves ->
            breadcrumbsBlock leaves

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
            chatHtml messages

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
            formHtml fieldsets

        ListBlock rows ->
            Html.ul
                [ classes [ SList.component ] ]
                (List.map
                    (\row -> Html.li [ classes [ listRowClass ] ] (List.map listCellHtml row.cells))
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
            -- `tabindex="0"` on the frame, not decoration: daisyUI's
            -- `.mockup-code` is `overflow-x: auto` around a `<pre>` of
            -- `width: max-content`, so any line longer than the container
            -- makes it a scrollable region — and a scrollable region no
            -- keyboard can reach is axe's `scrollable-region-focusable`
            -- (serious). The block holds only text, so there is nothing else
            -- inside it to receive that focus. The `group` role names what the
            -- stop is for, which keeps the added tab stop from being an
            -- unexplained one.
            Html.div
                [ classes [ SMockupCode.component ]
                , Attr.tabindex 0
                , Attr.attribute "role" "group"
                , Attr.attribute "aria-label" "Code"
                ]
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
            statsHtml Anywhere config items

        Steps config steps ->
            Html.ul
                [ classes ([ SSteps.component ] ++ opt SSteps.directionToClass config.direction) ]
                (List.map stepHtml steps)

        Table config rows ->
            tableHtml config rows

        Tabs config tabs ->
            tabsHtml config tabs

        Timeline config items ->
            Html.ul
                [ classes
                    ([ STimeline.component ]
                        ++ opt STimeline.directionToClass config.direction
                        ++ List.map
                            (STimeline.modifierToClass << Tree.timelineModifierToSchema)
                            config.modifiers
                    )
                ]
                (List.map timelineItemHtml items)


breadcrumbsBlock : List (Leaf msg) -> Html msg
breadcrumbsBlock leaves =
    Html.div
        [ classes [ SBreadcrumbs.component, tokenTextSm ] ]
        [ Html.ul [] (List.map (\l -> Html.li [] [ leaf l ]) leaves) ]


{-| The same trail, or nothing at all when there is none — what the page header
needs, where an empty `breadcrumbs` would still paint its own padding.
-}
breadcrumbsHtml : List (Leaf msg) -> List (Html msg)
breadcrumbsHtml leaves =
    if List.isEmpty leaves then
        []

    else
        [ breadcrumbsBlock leaves ]


navTitleHtml : BlockContext -> String -> Html msg
navTitleHtml context title =
    case context of
        InFooter ->
            Html.h6 [ classes [ footerTitlePart ] ] [ Html.text title ]

        _ ->
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
                -- daisyUI's `.card` paints neither a background nor a shadow:
                -- every docs example adds `bg-base-100 shadow-sm` beside it,
                -- which is what makes a card read as a panel raised off the
                -- `bg-base-200` content ground rather than a bordered region of
                -- the same paper.
                ++ [ tokenBgBase, tokenShadowSm ]
            )
        ]
        (maybeHtml (\f -> Html.figure [] [ leaf f ]) parts.figure
            ++ [ Html.div
                    [ classes [ cardBodyPart ] ]
                    (cardHeaderHtml parts
                        ++ List.map cardChildHtml parts.body
                        ++ [ Html.div [ classes [ cardActionsPart ] ] (List.map leaf parts.actions) ]
                    )
               ]
        )
        |> withHover3d config.hover3d
        |> withAura config.aura


{-| The card's header row: `titleIcon` and `card-title` on the left,
`headerTabs` and `headerActions` on the right.

The row exists only when something is in it, and it is a plain row when the only
thing in it is the title — so a card with nothing but a `title` renders the
`card-title` heading it always did, byte for byte.

`card-title` is sized down here (`tokenTextBase` + `tokenFontMedium`) from
daisyUI's own 1.25rem/600. daisyUI's dashboard templates title every panel that
way, because a grid of panels wants the numbers inside them to be the loudest
thing on the page.

-}
cardHeaderHtml : CardParts msg -> List (Html msg)
cardHeaderHtml parts =
    let
        titleHtml =
            maybeHtml
                (\t ->
                    Html.h2
                        [ classes [ cardTitlePart, tokenTextBase, tokenFontMedium ] ]
                        (maybeHtml (iconHtml [] defaultIconConfig) parts.titleIcon
                            ++ [ Html.text t ]
                        )
                )
                parts.title

        rightHtml =
            maybeHtml (\spec -> tabsHtml spec.config spec.tabs) parts.headerTabs
                ++ List.map leaf parts.headerActions
    in
    if List.isEmpty rightHtml then
        titleHtml

    else
        [ Html.div
            [ classes [ tokenFlex, tokenFlexWrap, tokenItemsCenter, tokenJustifyBetween, tokenGap ] ]
            (titleHtml
                ++ [ Html.div
                        [ classes [ tokenFlex, tokenItemsCenter, tokenGapSm ] ]
                        rightHtml
                   ]
            )
        ]


{-| One child of a `card-body`.

Each block-shaped child goes through the very same helper `blockIn` uses for
the bare block, so "a chart in a card" and "a chart in a section" are the same
markup. There is no `CardCard` to render: a card cannot hold a card.

-}
cardChildHtml : CardChild msg -> Html msg
cardChildHtml child =
    case child of
        CardLeaf value ->
            leaf value

        CardAlert config leaves ->
            alertHtml config leaves

        CardChart config data ->
            chartHtml config data

        CardChat messages ->
            chatHtml messages

        CardTable config rows ->
            tableHtml config rows

        CardStat config items ->
            statsHtml InCard config items

        CardForm fieldsets ->
            formHtml fieldsets


alertHtml : AlertConfig -> List (Leaf msg) -> Html msg
alertHtml config leaves =
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


formHtml : List (Fieldset msg) -> Html msg
formHtml fieldsets =
    Html.form
        [ classes [ tokenFlex, tokenFlexCol, tokenGap ] ]
        (List.map fieldsetHtml fieldsets)


statsHtml : BlockContext -> StatConfig -> List (StatItem msg) -> Html msg
statsHtml context config items =
    Html.div
        [ classes
            (SStat.component
                :: statDirectionClasses config.direction
                -- `.stats` is `rounded-box` but paints nothing; daisyUI's own
                -- examples write `stats bg-base-100 border ...` / `stats
                -- shadow`, which is what makes a tile row a panel on the
                -- `bg-base-200` content ground instead of four numbers loose
                -- on the page. Same pair a `card` gets, for the same reason —
                -- and for the same reason it is left off inside a card, which
                -- is already that panel. A second one nested in it reads as a
                -- box in a box.
                ++ surfaceFor context
            )
        ]
        (List.map statItemHtml items)


surfaceFor : BlockContext -> List String
surfaceFor context =
    case context of
        InCard ->
            []

        _ ->
            [ tokenBgBase, tokenShadowSm ]


{-| `stats-vertical lg:stats-horizontal` is daisyUI's own responsive idiom:
`.stats` is `grid-flow-col overflow-x-auto`, so a fixed horizontal row of tiles
scrolls sideways on a phone instead of wrapping. The `lg` class is built from
the schema class (see `tokenStatsHorizontalLg`), never typed out.
-}
statDirectionClasses : StatDirection -> List String
statDirectionClasses direction =
    case direction of
        Fixed value ->
            opt SStat.directionToClass value

        Responsive ->
            [ SStat.directionToClass SStat.Vertical, tokenStatsHorizontalLg ]


listCellHtml : ListCell msg -> Html msg
listCellHtml cell =
    let
        marks =
            flag cell.grow (SList.modifierToClass SList.ColGrow)
                ++ flag cell.wrap (SList.modifierToClass SList.ColWrap)
    in
    if List.isEmpty marks then
        leaf cell.content

    else
        -- `list-col-grow` / `list-col-wrap` mark one cell of a `list-row`, so
        -- they need an element of their own around that cell's content.
        Html.div [ classes marks ] [ leaf cell.content ]


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


chatHtml : List (ChatMessage msg) -> Html msg
chatHtml messages =
    Html.div
        [ classes [ tokenFlex, tokenFlexCol, tokenGapSm ] ]
        (List.map chatMessageHtml messages)


chatMessageHtml : ChatMessage msg -> Html msg
chatMessageHtml message =
    Html.div
        [ classes [ SChat.component, SChat.placementToClass message.placement ] ]
        (maybeHtml
            (\src ->
                Html.div
                    [ classes [ chatImagePart, SAvatar.component ] ]
                    [ Html.img [ Attr.src src, Attr.alt "", classes [ tokenSizeAvatar ] ] [] ]
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
            maybeHtml (iconHtml [] defaultIconConfig) item.icon
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


{-| One `stat` tile.

Three departures from daisyUI's stock `stat`, all of them what daisyUI's own
dashboard templates do to it:

  - the type scale. `.stat-title`/`.stat-desc` are 0.75rem and `.stat-value` is
    2rem/800, which is a hero number. A tile in a four-across metric row reads at
    `text-sm` / `text-2xl font-semibold` instead. The de-emphasised _colour_
    stays daisyUI's, because it is the one those two parts already paint.
  - `trend` shares the `stat-value` line, so the number and its delta badge are
    one baseline rather than two rows.
  - `stat-figure` is a painted tile — `bg-base-200` and a fixed 8px corner around
    the glyph — instead of a bare icon floating at the edge.

-}
statItemHtml : StatItem msg -> Html msg
statItemHtml item =
    Html.div
        [ classes [ statPart ] ]
        (maybeHtml
            (\f ->
                Html.div
                    [ classes [ statFigurePart, tokenBgGround, tokenRoundedLg, tokenPaddingSm ] ]
                    [ leaf f ]
            )
            item.figure
            ++ [ Html.div
                    [ classes [ statTitlePart, tokenTextSm, tokenFontMedium ] ]
                    [ Html.text item.title ]
               , Html.div
                    [ classes
                        [ statValuePart
                        , tokenHeading2
                        , tokenFontSemibold
                        , tokenFlex
                        , tokenItemsCenter
                        , tokenGapSm
                        ]
                    ]
                    (Html.text item.value :: maybeHtml leaf item.trend)
               ]
            ++ maybeHtml
                (\d -> Html.div [ classes [ statDescPart, tokenTextSm ] ] [ Html.text d ])
                item.desc
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
                (List.map
                    (\r ->
                        Html.tr []
                            (List.map (\c -> Html.th [] (tableCellHtml c)) r.cells)
                    )
                    headers
                )
            , Html.tbody []
                (List.map
                    (\r ->
                        Html.tr []
                            (List.map (\c -> Html.td [] (tableCellHtml c)) r.cells)
                    )
                    body
                )
            ]
        ]


{-| One `<th>`/`<td>`'s content.

A cell with no `leading` leaf is the bare leaf, byte for byte what a table cell
has always rendered. A cell that has one gets the flex wrapper daisyUI's own
"table with visual elements" example uses around an `avatar` and a name — no
part class is involved, so nothing can leak onto an element that is not a cell.

-}
tableCellHtml : TableCell msg -> List (Html msg)
tableCellHtml cell =
    case cell.leading of
        Nothing ->
            [ leaf cell.content ]

        Just leading ->
            [ Html.div
                [ classes [ tokenFlex, tokenItemsCenter, tokenGapSm ] ]
                [ leaf leading, leaf cell.content ]
            ]


tabsHtml : TabsConfig -> List (Tab msg) -> Html msg
tabsHtml config tabs =
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


{-| One tab, and the `tab-content` panel it owns — if it owns one.

daisyUI shows the panel that follows the active tab (`.tab-active +
.tab-content { display: block }`), so an empty panel behind the active tab of a
`tabs-box` segmented control would open an empty block inside the row it sits
in. A tab with no content therefore emits no panel at all.

-}
tabHtml : Tab msg -> List (Html msg)
tabHtml tab =
    Html.a
        [ classes
            ([ tabPart ]
                ++ flag tab.active (STab.modifierToClass STab.Active)
                ++ flag tab.disabled (STab.modifierToClass STab.Disabled)
            )
        , Attr.attribute "role" "tab"
        ]
        [ Html.text tab.label ]
        :: (if List.isEmpty tab.content then
                []

            else
                [ Html.div [ classes [ tabContentPart ] ] (List.map leaf tab.content) ]
           )


timelineItemHtml : TimelineItem msg -> Html msg
timelineItemHtml item =
    let
        -- `timeline-box` sits on one *side* of one item, never on the
        -- `timeline` container, so it is a flag per side here.
        boxed on =
            flag on (STimeline.modifierToClass STimeline.Box)
    in
    Html.li []
        (maybeHtml
            (\s -> Html.div [ classes (timelineStartPart :: boxed item.startBox) ] [ Html.text s ])
            item.start
            ++ maybeHtml (\m -> Html.div [ classes [ timelineMiddlePart ] ] [ leaf m ]) item.middle
            ++ maybeHtml
                (\e -> Html.div [ classes (timelineEndPart :: boxed item.endBox) ] [ Html.text e ])
                item.end
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

        Calendar config state ->
            calendarHtml extra config state

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
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onCheckAttrs config.onCheck
                       )
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
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onInputAttrs config.onInput
                       )
                )
                []
                |> withTooltip config.tooltip

        Filter data ->
            filterHtml extra data

        Heading level text ->
            headingHtml extra level text

        HoverGallery srcs ->
            Html.figure
                [ classes (SHoverGallery.component :: extra) ]
                (List.map (\src -> Html.img [ Attr.src src, Attr.alt "" ] []) srcs)

        Icon config icon ->
            iconHtml extra config icon

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
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onCheckAttrs config.onCheck
                       )
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
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onInputAttrs config.onInput
                       )
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

        Swatch config color label ->
            swatchHtml extra config color label

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
                    :: Attr.required config.required
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onInputAttrs config.onInput
                       )
                )
                []
                |> withTooltip config.tooltip

        ThemeSelect data ->
            themeSelectHtml extra data

        UserChip config data ->
            userChipHtml extra config data

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
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onCheckAttrs config.onCheck
                       )
                )
                []
                |> withTooltip config.tooltip


{-| Who is signed in: portrait, name, and one de-emphasised line under it.

The two lines of text are what the tree could not otherwise say — a `Leaf` is
terminal, so stacking them would need a container leaf and a container leaf
would hand layout back to the caller. This is the whole composite, decided once:
an `avatar` with daisyUI's `mask-squircle`, then a column of `text-sm
font-medium` over `text-xs` in daisyUI's own de-emphasis colour.

`boxed` paints it as a panel (`bg-base-200`, the 8px corner, `p-2`) — the shape
a sidebar footer wants. Unboxed it is bare chrome, which is what a navbar wants.

-}
userChipHtml : List String -> UserChipConfig msg -> UserChipData -> Html msg
userChipHtml extra config data =
    Html.div
        (classes
            ([ tokenFlex, tokenItemsCenter, tokenGapSm ]
                ++ flag config.boxed tokenBgGround
                ++ flag config.boxed tokenRoundedLg
                ++ flag config.boxed tokenPaddingSm
                ++ extra
            )
            :: onClickAttrs config.onClick
        )
        [ Html.div
            [ classes [ SAvatar.component ] ]
            [ Html.div
                [ classes [ SMask.component, SMask.styleToClass SMask.Squircle, tokenSizeAvatar ] ]
                [ Html.img [ Attr.src data.avatar, Attr.alt "" ] [] ]
            ]
        , Html.div
            [ classes [ tokenFlex, tokenFlexCol, tokenGrow ] ]
            [ Html.span [ classes [ tokenTextSm, tokenFontMedium ] ] [ Html.text data.name ]
            , Html.span [ classes [ tokenTextXs, tokenTextMuted ] ] [ Html.text data.subtitle ]
            ]
        ]
        |> withTooltip config.tooltip
        |> withDropdown config.dropdown


headingHtml : List String -> HeadingLevel -> String -> Html msg
headingHtml extra level text =
    let
        ( tag, sizeAndWeight ) =
            case level of
                H1 ->
                    ( Html.h1, [ tokenHeading1, tokenFontBold ] )

                H2 ->
                    ( Html.h2, [ tokenHeading2, tokenFontBold ] )

                H3 ->
                    ( Html.h3, [ tokenHeading3, tokenFontSemibold ] )
    in
    tag [ classes (sizeAndWeight ++ extra) ] [ Html.text text ]


{-| One [`Daisy.Icon.Icon`](Daisy-Icon#Icon), as inline SVG.

`Leaf.Icon` emits **no** daisyUI class — an icon is not a daisyUI component,
like `Leaf.Heading` and `Leaf.Image` — so the only class on the `<svg>` is the
size token its [`IconConfig`](Daisy-Tree#IconConfig) asks for.

The five attributes every heroicons outline drawing shares — `viewBox`, an empty
`fill`, a `currentColor` `stroke`, `stroke-width` and the two rounded
`stroke-line*` joins — are written here once; `Daisy.Render.Icons` holds only the
`d` values. `currentColor` is what makes an icon follow the daisyUI theme: it
inherits the colour of whatever `btn`, `menu` or `stat-figure` it sits in.

Accessibility follows `IconConfig.label`: unlabelled it is `aria-hidden`, so a
decorative glyph beside a text label adds nothing to the accessible name;
labelled it is an image `role` plus that `aria-label`, which is how an icon-only
control gets a name.

-}
iconHtml : List String -> IconConfig -> Icon -> Html msg
iconHtml extra config icon =
    Svg.svg
        (SvgA.viewBox "0 0 24 24"
            :: SvgA.fill "none"
            :: SvgA.stroke "currentColor"
            :: SvgA.strokeWidth "1.5"
            :: svgClasses (iconSizeToken config.size :: extra)
            :: iconLabelAttrs config.label
        )
        (List.map
            (\d ->
                Svg.path
                    [ SvgA.strokeLinecap "round", SvgA.strokeLinejoin "round", SvgA.d d ]
                    []
            )
            (Icons.paths icon)
        )


iconSizeToken : IconSize -> String
iconSizeToken size =
    case size of
        IconSm ->
            tokenSizeIconSm

        IconMd ->
            tokenSizeIcon

        IconLg ->
            tokenSizeIconLg


iconLabelAttrs : Maybe String -> List (Html.Attribute msg)
iconLabelAttrs label =
    case label of
        Just text ->
            [ Attr.attribute "role" "img", Attr.attribute "aria-label" text ]

        Nothing ->
            [ Attr.attribute "aria-hidden" "true" ]


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
            [ classes (maskClasses config.mask ++ [ tokenSizeAvatar ]) ]
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
            :: (optAttr (Attr.attribute "aria-label") config.ariaLabel
                    ++ onClickAttrs config.onClick
               )
        )
        (maybeHtml (iconHtml [] buttonIconConfig) config.icon ++ [ Html.text label ])
        |> withIndicator config.indicator
        |> withTooltip config.tooltip
        |> withDropdown config.dropdown
        |> withAura config.aura


{-| A leading button icon: one step down from the standalone default, so it fits
a `btn-xs` row action, and `aria-hidden`, because the button's own label (or its
`ariaLabel`) is what names it.
-}
buttonIconConfig : IconConfig
buttonIconConfig =
    { size = IconSm, label = Nothing }


filterHtml : List String -> FilterData msg -> Html msg
filterHtml extra data =
    Html.form
        [ classes (SFilter.component :: extra) ]
        (maybeHtml (filterResetHtml data.name) data.reset
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


{-| The `filter`'s reset control.

`ResetPart` is the `filter-reset` part, which is how daisyUI writes a filter
that is not inside a real `<form>`. `ResetButton` is the plain `btn` the
`<form>` idiom uses, where the browser's own form reset does the work — no part
class is involved, so the part cannot leak onto a control that is not one.

-}
filterResetHtml : String -> FilterReset -> Html msg
filterResetHtml name reset =
    let
        marks =
            case reset of
                ResetPart ->
                    [ filterResetPart, SButton.component ]

                ResetButton modifiers ->
                    SButton.component :: List.map SButton.modifierToClass modifiers
    in
    Html.input
        [ classes marks
        , Attr.type_ "radio"
        , Attr.name name
        , Attr.attribute "aria-label" "Reset"
        ]
        []


{-| A text field, in one of daisyUI's two shapes for it.

Without an icon it is the plain `input` element it has always been. With
one it is the
wrapper form daisyUI's docs use for a decorated field: the component class moves
to a `<label>`, which `.input` lays out as a flex row, and the glyph and a bare
growing `<input>` sit inside it. The label wrapping the control is also
what keeps the field named when the glyph is the only thing beside it.

-}
inputHtml : List String -> InputConfig msg -> Html msg
inputHtml extra config =
    let
        componentClasses =
            [ SInput.component ]
                ++ opt SInput.colorToClass config.color
                ++ opt SInput.styleToClass config.style
                ++ opt SInput.sizeToClass config.size
                ++ extra

        controlAttrs own =
            classes own
                :: Attr.type_ (inputTypeAttr config.inputType)
                :: Attr.placeholder config.placeholder
                :: Attr.value config.value
                :: Attr.required config.required
                :: (optAttr Attr.pattern config.pattern
                        ++ optAttr Attr.minlength config.minLength
                        ++ optAttr Attr.maxlength config.maxLength
                        ++ ariaLabelAttrs config.ariaLabel config.tooltip
                        ++ onInputAttrs config.onInput
                   )
    in
    (case config.icon of
        Nothing ->
            Html.input (controlAttrs componentClasses) []

        Just icon ->
            Html.label
                [ classes componentClasses ]
                [ iconHtml [ tokenTextMuted ] buttonIconConfig icon
                , Html.input (controlAttrs [ tokenGrow ]) []
                ]
    )
        |> withIndicator config.indicator
        |> withTooltip config.tooltip


{-| The `type` attribute of an `input`. Every value is an HTML input type, not
a class.
-}
inputTypeAttr : InputType -> String
inputTypeAttr inputType =
    case inputType of
        InputText ->
            "text"

        InputEmail ->
            "email"

        InputPassword ->
            "password"

        InputNumber ->
            "number"

        InputUrl ->
            "url"

        InputTel ->
            "tel"

        InputSearch ->
            "search"

        InputDate ->
            "date"

        InputColor ->
            "color"


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
    let
        half =
            List.member RatingHalf config.modifiers

        shape =
            Maybe.withDefault SMask.Star2 config.shape

        -- daisyUI's half-star rating alternates `mask-half-1` / `mask-half-2`
        -- across the radios; a whole-star one has no half modifier at all.
        halfOf i =
            if not half then
                []

            else if modBy 2 i == 1 then
                [ SMask.modifierToClass SMask.Half1 ]

            else
                [ SMask.modifierToClass SMask.Half2 ]

        star i =
            Html.input
                (classes ([ SMask.component, SMask.styleToClass shape ] ++ halfOf i)
                    :: Attr.type_ "radio"
                    :: Attr.name data.name
                    :: Attr.checked (i == data.value)
                    :: (ariaLabelAttrs config.ariaLabel config.tooltip
                            ++ onClickAttrs (Maybe.map (\f -> f i) config.onRate)
                       )
                )
                []

        -- `rating-hidden` belongs on the rating's own first, blank radio: it is
        -- the "no stars" choice, not a modifier of the container.
        clear =
            Html.input
                (classes [ SRating.modifierToClass SRating.Hidden ]
                    :: Attr.type_ "radio"
                    :: Attr.name data.name
                    :: Attr.checked (data.value == 0)
                    :: onClickAttrs (Maybe.map (\f -> f 0) config.onRate)
                )
                []
    in
    Html.div
        [ classes
            ([ SRating.component ]
                ++ opt SRating.sizeToClass config.size
                ++ List.map (SRating.modifierToClass << Tree.ratingModifierToSchema) config.modifiers
                ++ extra
            )
        ]
        (flagHtml data.clearable clear ++ List.map star (List.range 1 data.count))
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
            ++ ariaLabelAttrs config.ariaLabel config.tooltip
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


{-| A palette chip: one theme surface with its content colour on it.

The box is the renderer's, not daisyUI's — a centred `rounded-lg` block the
width of its cell, at the same 8px corner and 8px padding the `stat-figure` tile
uses — because daisyUI ships no component whose job is "show me this colour".
Only the two colour tokens change from one `SwatchColor` to the next.

-}
swatchHtml : List String -> SwatchConfig -> SwatchColor -> String -> Html msg
swatchHtml extra config color label =
    let
        ( surface, content ) =
            swatchClasses color
    in
    Html.div
        (classes
            ([ surface
             , content
             , tokenRoundedLg
             , tokenPaddingSm
             , tokenWFull
             , tokenFlex
             , tokenItemsCenter
             , tokenJustifyCenter
             , tokenTextSm
             , tokenFontMedium
             ]
                ++ extra
            )
            :: ariaLabelAttrs config.ariaLabel config.tooltip
        )
        [ Html.text label ]
        |> withTooltip config.tooltip


{-| The `( background, foreground )` token pair of every `SwatchColor`. This is
the whole mapping; nothing else in the renderer emits a colour utility.
-}
swatchClasses : SwatchColor -> ( String, String )
swatchClasses color =
    case color of
        SwatchBase100 ->
            ( tokenBgBase, tokenTextBaseContent )

        SwatchBase200 ->
            ( tokenBgGround, tokenTextBaseContent )

        SwatchBase300 ->
            ( tokenBgBase300, tokenTextBaseContent )

        SwatchPrimary ->
            ( tokenBgPrimary, tokenTextPrimaryContent )

        SwatchSecondary ->
            ( tokenBgSecondary, tokenTextSecondaryContent )

        SwatchAccent ->
            ( tokenBgAccent, tokenTextAccentContent )

        SwatchNeutral ->
            ( tokenBgNeutral, tokenTextNeutralContent )

        SwatchInfo ->
            ( tokenBgInfo, tokenTextInfoContent )

        SwatchSuccess ->
            ( tokenBgSuccess, tokenTextSuccessContent )

        SwatchWarning ->
            ( tokenBgWarning, tokenTextWarningContent )

        SwatchError ->
            ( tokenBgError, tokenTextErrorContent )


themeSelectHtml : List String -> ThemeSelectData msg -> Html msg
themeSelectHtml extra data =
    let
        control theme =
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
    in
    case data.presentation of
        ThemeAsDropdown ->
            -- daisyUI's documented "Theme Controller using a dropdown": a `btn`
            -- trigger and a `dropdown-content` list of `theme-controller`
            -- radios. This is the only presentation that stays one control
            -- wide no matter how many themes it offers.
            Html.div
                [ classes (SDropdown.component :: extra) ]
                [ -- Exactly daisyUI's documented trigger: a bare `btn` with
                  -- the control's name in it. `tests/CorpusTest` compares this
                  -- against the docs example class for class, so it cannot be
                  -- restyled into the icon-only circle a dashboard navbar
                  -- would prefer (`docs/tree-decisions.md`, Nexus design pass).
                  Html.div
                    [ Attr.tabindex 0
                    , Attr.attribute "role" "button"
                    , classes [ SButton.component ]
                    ]
                    [ Html.text "Theme" ]
                , Html.ul
                    [ Attr.tabindex -1
                    , classes [ dropdownContentPart, tokenBgBase, tokenPaddingSm ]
                    ]
                    (List.map (\theme -> Html.li [] [ control theme ]) data.themes)
                ]

        _ ->
            Html.div
                [ classes ([ tokenFlex, tokenFlexWrap, tokenGapSm ] ++ extra) ]
                (List.map control data.themes)


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

        ThemeAsDropdown ->
            [ SButton.component
            , SButton.sizeToClass SButton.Sm
            , SButton.modifierToClass SButton.Block
            , SButton.styleToClass SButton.Ghost
            ]


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

        ThemeAsDropdown ->
            "radio"



-- CALENDAR ------------------------------------------------------------------
--
-- `Leaf.Calendar` is rendered by `alexbruf/elm-cally`, a pure-Elm port of the
-- Cally web component. It emits the same element names (`calendar-date`,
-- `calendar-month`, ...) and the same `part` attributes as Cally, in the light
-- DOM, which is what daisyUI's `calendar.css` styles through `.cally`. The
-- wrapper below is the only element this module puts a class on: elm-cally's
-- own markup carries `part` attributes and its two internal helper classes
-- (`vh`, `num`), never a daisyUI class.


{-| The picker, wrapped in daisyUI's `cally` element.

daisyUI's `.cally` rules are written as `::part(x)`, which only matches a real
shadow root; against elm-cally's light DOM they are the descendant selectors
`.cally [part~="x"]` (`tools/gen-cally-css.js` performs that rewrite for the
demo). Both forms are descendant selectors, so the class goes on a wrapper
around `<calendar-date>` rather than on the element itself — which is also
where the docs example's `bg-base-100 border rounded-box` utilities sit.

-}
calendarHtml : List String -> CalendarConfig msg -> CalendarState -> Html msg
calendarHtml extra config state =
    Html.div
        [ classes (SCalendar.component :: extra) ]
        [ case state of
            SelectDate value model ->
                CallyDate.view (callyDateConfig config) value model (calendarMonths config)

            SelectRange value model ->
                CallyRange.view (callyRangeConfig config) value model (calendarMonths config)

            SelectMulti value model ->
                CallyMulti.view (callyMultiConfig config) value model (calendarMonths config)
        ]


{-| One `calendar-month` grid per month the config asks for. elm-cally has no
shadow DOM, so a child is a function of the picker's `Context`.

`TwoMonths` puts the two grids in a container of this module's own, because
nothing else will: elm-cally's `[part~=months]` div is bare (upstream
Cally leaves it to the page's CSS, and its docs write
`::part(months) { display: flex }` in the _example_, not in the component), and
daisyUI's `calendar.css` has no `months` rule to translate either. A `display:
block` container stacks its two block-level grids, which is what the picker did
before. The layout is therefore the renderer's to give, and it gives it the
same way it gives every other layout: named tokens from `Render.tokens`, on a
plain element, with no daisyUI class invented for the occasion.

`grid-cols-1 sm:grid-cols-2` rather than `flex flex-wrap`: daisyUI's own
`.cally calendar-month { width: 100% }` makes each grid as wide as the line it
is on, so as flex items they would each claim a whole line and never sit side
by side. As grid items they fill their track instead, and the single column
below `sm` is what keeps two 252px grids from overflowing a 375px viewport.

-}
calendarMonths : CalendarConfig msg -> List (CallyContext.Context msg -> Html msg)
calendarMonths config =
    let
        grids : List (CallyContext.Context msg -> Html msg)
        grids =
            List.range 0 (calendarMonthCount config.months - 1)
                |> List.map (\offset -> CallyMonth.view { offset = offset })
    in
    case config.months of
        OneMonth ->
            grids

        TwoMonths ->
            [ calendarMonthsRow grids ]


{-| The `TwoMonths` layout container: one row of month grids at `sm` and wider,
one column below it. See `calendarMonths` for why it exists.
-}
calendarMonthsRow :
    List (CallyContext.Context msg -> Html msg)
    -> CallyContext.Context msg
    -> Html msg
calendarMonthsRow grids context =
    Html.div
        [ classes [ tokenGrid, tokenGridCols1, tokenGridCols2Sm, tokenGap ] ]
        (List.map (\grid -> grid context) grids)


calendarMonthCount : CalendarMonths -> Int
calendarMonthCount months =
    case months of
        OneMonth ->
            1

        TwoMonths ->
            2


callyLocale : CalendarLocale -> CallyLocale.Locale
callyLocale locale =
    case locale of
        EnGB ->
            CallyLocale.enGB

        EnUS ->
            CallyLocale.enUS


callyDateConfig : CalendarConfig msg -> CallyDate.Config msg
callyDateConfig config =
    let
        base : CallyDate.Config msg
        base =
            CallyDate.defaultConfig
                { id = config.id
                , today = config.today
                , locale = callyLocale config.locale
                , toMsg = config.toMsg << CalendarDateMsg
                , onChange = config.onChange << PickedDate
                }
    in
    { base
        | months = calendarMonthCount config.months
        , previous = calendarPreviousArrow
        , next = calendarNextArrow
    }


callyRangeConfig : CalendarConfig msg -> CallyRange.Config msg
callyRangeConfig config =
    let
        base : CallyRange.Config msg
        base =
            CallyRange.defaultConfig
                { id = config.id
                , today = config.today
                , locale = callyLocale config.locale
                , toMsg = config.toMsg << CalendarRangeMsg
                , onChange = config.onChange << PickedRange
                }
    in
    { base
        | months = calendarMonthCount config.months
        , previous = calendarPreviousArrow
        , next = calendarNextArrow
    }


callyMultiConfig : CalendarConfig msg -> CallyMulti.Config msg
callyMultiConfig config =
    let
        base : CallyMulti.Config msg
        base =
            CallyMulti.defaultConfig
                { id = config.id
                , today = config.today
                , locale = callyLocale config.locale
                , toMsg = config.toMsg << CalendarMultiMsg
                , onChange = config.onChange << PickedDates
                }
    in
    { base
        | months = calendarMonthCount config.months
        , previous = calendarPreviousArrow
        , next = calendarNextArrow
    }


{-| daisyUI's own calendar example fills Cally's `previous` / `next` slots with
a chevron. The `<svg>` is given an image role plus the label elm-cally would
otherwise have written as text, so the paging button keeps an accessible name.
-}
calendarPreviousArrow : Html msg
calendarPreviousArrow =
    calendarArrow "Previous" "M15.75 19.5 8.25 12l7.5-7.5"


calendarNextArrow : Html msg
calendarNextArrow =
    calendarArrow "Next" "m8.25 4.5 7.5 7.5-7.5 7.5"


calendarArrow : String -> String -> Html msg
calendarArrow label path =
    Svg.svg
        [ SvgA.viewBox "0 0 24 24"
        , SvgA.class tokenSizeIcon
        , Attr.attribute "role" "img"
        , Attr.attribute "aria-label" label
        ]
        [ Svg.path [ SvgA.fill "currentColor", SvgA.d path ] [] ]



-- CALENDAR STATE ------------------------------------------------------------


{-| A single-date picker's starting state, focused on the value or on
`CalendarConfig.today`.
-}
initCalendarDate : CalendarConfig msg -> Maybe Date -> CalendarState
initCalendarDate config value =
    SelectDate value (CallyDate.init (callyDateConfig config) value)


{-| A date-range picker's starting state. The pair is start-then-end and is
always kept sorted by the picker.
-}
initCalendarRange : CalendarConfig msg -> Maybe ( Date, Date ) -> CalendarState
initCalendarRange config value =
    SelectRange value (CallyRange.init (callyRangeConfig config) value)


{-| A multiple-date picker's starting state.
-}
initCalendarMulti : CalendarConfig msg -> List Date -> CalendarState
initCalendarMulti config value =
    SelectMulti value (CallyMulti.init (callyMultiConfig config) value)


{-| Advance the picker's own state.

Route every `CalendarMsg` your `CalendarConfig.toMsg` produced through here and
run the returned command: it carries both the `onChange` callback and the
`Browser.Dom.focus` call that the roving `tabindex` needs after an arrow key.
The new _selection_ arrives separately, as `CalendarConfig.onChange`; store it
with `Daisy.Tree.setCalendarValue`.

A message for one kind of picker cannot act on another kind's state — the pair
is impossible to build from a single `Leaf.Calendar` — so a mismatch is a
no-op rather than a runtime error.

-}
updateCalendar : CalendarConfig msg -> CalendarMsg -> CalendarState -> ( CalendarState, Cmd msg )
updateCalendar config msg state =
    case ( msg, state ) of
        ( CalendarDateMsg sub, SelectDate value model ) ->
            CallyDate.update (callyDateConfig config) value sub model
                |> Tuple.mapFirst (SelectDate value)

        ( CalendarRangeMsg sub, SelectRange value model ) ->
            CallyRange.update (callyRangeConfig config) value sub model
                |> Tuple.mapFirst (SelectRange value)

        ( CalendarMultiMsg sub, SelectMulti value model ) ->
            CallyMulti.update (callyMultiConfig config) value sub model
                |> Tuple.mapFirst (SelectMulti value)

        _ ->
            ( state, Cmd.none )



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
         ]
            -- `fab-main-action` goes on the button itself, which is where every
            -- daisyUI fab example puts it; it is a separate leaf from the
            -- trigger above, not the same one drawn twice.
            ++ maybeHtml (leafWith [ fabMainActionPart ]) fab.mainAction
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
        [ classes [ tokenFlex, tokenFlexCol, tokenGapSm, tokenWFull ] ]
        [ Html.div
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
        , chartLegend data
        ]


{-| The key under a chart: one `status` dot per series, in the series' own
colour, and the name beside it.

`terezka/elm-charts` can draw a legend inside the SVG, but an SVG legend cannot
be themed by a daisyUI class and cannot wrap. This is the row every dashboard
chart carries instead, built from daisyUI's `status` component — the same eight
semantic colours `Daisy.Chart.SemanticColor` offers, so the dot and the line it
labels are the same variable.

-}
chartLegend : ChartData -> Html msg
chartLegend data =
    Html.div
        [ classes
            [ tokenFlex
            , tokenFlexWrap
            , tokenItemsCenter
            , tokenJustifyCenter
            , tokenGap
            , tokenTextXs
            ]
        ]
        (List.map
            (\series ->
                Html.span
                    [ classes [ tokenFlex, tokenItemsCenter, tokenGapSm ] ]
                    [ Html.span
                        [ classes
                            [ SStatus.component
                            , SStatus.colorToClass (statusColorFor series.color)
                            ]
                        ]
                        []
                    , Html.text series.name
                    ]
            )
            data.series
        )


{-| A chart series colour as the matching `status-*` class. The two enumerations
are daisyUI's eight semantic colours, so the mapping is total and one-to-one.
-}
statusColorFor : Chart.SemanticColor -> SStatus.Color
statusColorFor color =
    case color of
        Chart.Primary ->
            SStatus.Primary

        Chart.Secondary ->
            SStatus.Secondary

        Chart.Accent ->
            SStatus.Accent

        Chart.Info ->
            SStatus.Info

        Chart.Success ->
            SStatus.Success

        Chart.Warning ->
            SStatus.Warning

        Chart.Error ->
            SStatus.Error

        Chart.Neutral ->
            SStatus.Neutral


seriesChart : List (CA.Attribute CS.Interpolation) -> ChartData -> Html msg
seriesChart interpolation data =
    let
        points =
            toPoints data
    in
    C.chart
        [ CA.height chartViewboxHeight, CA.width chartWidth, CA.margin chartMargin ]
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
        [ CA.height chartViewboxHeight, CA.width chartWidth, CA.margin chartMargin ]
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


{-| elm-charts has no way to pin axis-label font size to real pixels: it sets
no `width`/`height` attribute on the `<svg>` (only a `viewBox`), so the
browser stretches it to the container's width and derives the height from
`chartWidth : chartViewboxHeight`, and every SVG length -- including the
inherited label font-size -- is a viewBox _user unit_, scaled by
`containerPx / chartWidth`. The library's own default (`CA.width 300`) assumes
a ~300px-wide container; in a `min-h-64`/`Cols1` full-width block (~1120px
measured) that scale is ~1.4x on top of the library's own already-large
default label font, which read as roughly 3x too big. Widening the viewBox
here shrinks that scale back down for the common full-width case, at the
cost of shrinking it further for the already-fine half-width (`Cols2`,
~536px) and single-column-on-mobile (~311px) cases. `800 x 300` (still the
same 8:3 ratio `tokenChartHeight`'s `min-h-64` assumes) was picked by
screenshotting `/` and `/analytics` at both container widths, plus mobile,
and choosing the narrowest viewBox that brought the full-width labels down
to a normal size without shrinking the mobile labels past legible. This only
changes internal SVG scaling, not layout: the actual rendered chart height is
still `containerPx * 3 / 8` either way.
-}
chartWidth : Float
chartWidth =
    800


chartViewboxHeight : Float
chartViewboxHeight =
    300


{-| The donut's fixed pixel height (see `donutChart`): kept independent of
`chartViewboxHeight` above so widening that viewBox for readable line/bar/area
labels doesn't also inflate the donut, which has no labels to fix.
-}
chartHeight : Float
chartHeight =
    240


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
