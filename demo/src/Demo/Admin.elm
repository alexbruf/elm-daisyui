module Demo.Admin exposing
    ( Config, page
    , ChartRange(..), allChartRanges, chartRangeLabel
    )

{-| The admin dashboard demo (SPEC.md step 7, row "Admin").

It is a recreation of daisyUI's own **Nexus** e-commerce dashboard
(<https://nexus.daisyui.com/dashboards/ecommerce>), composed entirely out of
`Daisy.Tree`: the same sidebar (brand row, `menu-title` sections, a soft badge,
a user card pinned to the bottom), the same navbar (drawer toggle, a search
field with a leading glyph, icon-only controls and a user chip), the same page
header (title left, `breadcrumbs` right), the same four metric tiles (label,
number with a soft delta badge, "vs. last period" caption, glyph in a shaded
tile), the same two chart panels and the same orders table (checkbox column,
squircle thumbnail, soft status badges, icon-only row actions).

Where Nexus reaches for its own CSS this reaches for a `Daisy.Render` token
instead; `docs/tree-decisions.md` ("Nexus design pass") lists what that costs.

Built only from `Daisy.Tree` / `Daisy.Chart` / `Daisy.Schema.*` constructors —
this module imports no `Html`, so every class on the page comes from
`Daisy.Render`.

The page is parameterised by the caller's `msg` type rather than importing
`Main`, which would be a cycle. [`Config`](#Config) carries the slice of the
router's model this page reads plus the constructors it fires.

@docs Config, page


# The revenue chart's range

The `Day | Month | Year` switch in the Revenue Statistics card header picks one
of three datasets. It is a closed type owned by this module and kept by the
router, exactly like every other piece of demo state.

@docs ChartRange, allChartRanges, chartRangeLabel

-}

import BasePath
import Daisy.Chart as DChart
import Daisy.Icon as Icon
import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Chat as SChat
import Daisy.Schema.Checkbox as SCheckbox
import Daisy.Schema.Input as SInput
import Daisy.Schema.Mask as SMask
import Daisy.Schema.Stat as SStat
import Daisy.Schema.Tab as STab
import Daisy.Schema.Table as STable
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , CardChild(..)
        , ChatMessage
        , DashboardShell
        , IndicatorPayload(..)
        , InputType(..)
        , Leaf(..)
        , MenuGlyph(..)
        , MenuItem(..)
        , MenuSpec
        , NavbarParts
        , Overlay(..)
        , Page(..)
        , Row
        , Section(..)
        , Sections(..)
        , Shell(..)
        , StatItem
        , Tab
        , Theme
        , ThemePresentation(..)
        )


{-| What the admin page needs from the router.
-}
type alias Config msg =
    { basePath : String
    , theme : Theme
    , lastMsg : String
    , toastVisible : Bool
    , search : String
    , chartRange : ChartRange
    , hoveredBar : Maybe Int
    , onNavigate : String -> msg
    , onTheme : Theme -> msg
    , onSearch : String -> msg
    , onNotifications : msg
    , onExport : msg
    , onRowAction : String -> msg
    , onChartRange : ChartRange -> msg
    , onChartHover : Maybe Int -> msg
    }


{-| Which revenue dataset the chart is showing.
-}
type ChartRange
    = Day
    | Month
    | Year


{-| Every [`ChartRange`](#ChartRange), in the order the segmented control shows
them.
-}
allChartRanges : List ChartRange
allChartRanges =
    [ Day, Month, Year ]


{-| The label on a range's tab.
-}
chartRangeLabel : ChartRange -> String
chartRangeLabel range =
    case range of
        Day ->
            "Day"

        Month ->
            "Month"

        Year ->
            "Year"


{-| The whole admin dashboard as one `Page`.
-}
page : Config msg -> Page msg
page config =
    Page
        { header = Just headerBar
        , shell = Dashboard (dashboard config)
        , sections =
            Sections4
                (metricsSection config)
                (chartsSection config)
                (activitySection config)
                (debugSection config)
        , cta = exportCta config
        , overlays =
            if config.toastVisible then
                [ toastOverlay ]

            else
                []
        , theme = config.theme
        , dock = Nothing
        , fab = Nothing
        }



-- SHELL ---------------------------------------------------------------------


dashboard : Config msg -> DashboardShell msg
dashboard config =
    { brand = Just { icon = Icon.ChartBar, name = "Acme" }
    , sidebar = sidebar config
    , sidebarFooter = Just (sidebarUser config)
    , navbar = navbar config

    -- Nexus draws a 1px hairline under its navbar and down the right edge of
    -- its sidebar, measured in the browser at 1440: `border-*-width: 1px`,
    -- colour = the theme's third surface. `Daisy.Render` owns both.
    , edges = True
    }


{-| The sidebar, in the two labelled groups Nexus splits its own into.

The five entries are the demo's five real destinations: four routes plus the
generated documentation site. Nexus lists about twenty; the rest of its list
would be dead links here, and a dead link in a demo is worse than a short one
(`docs/tree-decisions.md`).

-}
sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = sidebarMenuConfig
    , items =
        [ sectionTitle "Dashboards"
        , navItem "Overview" Icon.Home (href config "/") (config.onNavigate "/") True Nothing
        , navItem "Analytics" Icon.ChartBar (href config "/analytics") (config.onNavigate "/analytics") False (Just "New")
        , sectionTitle "Workspace"
        , navItem "Settings" Icon.Cog (href config "/settings") (config.onNavigate "/settings") False Nothing
        , sectionTitle "Tools"
        , navItem "Theme generator" Icon.Sun (href config "/theme") (config.onNavigate "/theme") False Nothing
        , docsItem config
        ]
    }


{-| The sidebar menu's own configuration: everything default except the active
row, which is `TintedActive`.

Measured off Nexus at 1440, its active entry is `background-color` = the theme's
base-200, `font-weight: 500`, `color` = base-content — a row one surface step up
from the panel, not daisyUI's solid `--color-neutral` slab. `menu-active` stays
reachable through `SolidActive`, which is still the default.

-}
sidebarMenuConfig : Tree.MenuConfig
sidebarMenuConfig =
    { defaultMenu | activeStyle = Tree.TintedActive }


defaultMenu : Tree.MenuConfig
defaultMenu =
    Tree.defaultMenuConfig


{-| A `menu-title` row. It labels the group under it and is not a link.
-}
sectionTitle : String -> MenuItem msg
sectionTitle label =
    let
        (MenuItem base) =
            Tree.menuItem label
    in
    MenuItem { base | title = True }


{-| The generated documentation site, which lives beside the demo in
`dist/docs/` rather than being an Elm route. It is a plain link with no
`onClick`: `Main.step` sees the `UrlRequest` for a path that is not one of the
three routes and answers with `Browser.Navigation.load`, so the browser leaves
the single-page app instead of routing inside it.
-}
docsItem : Config msg -> MenuItem msg
docsItem config =
    let
        (MenuItem base) =
            Tree.menuItem "Docs"
    in
    MenuItem
        { base
            | glyph = Just (MenuIcon Icon.Document)
            , href = Just (href config "/docs/")
        }


{-| A route as it must appear in an `href`: the demo's own path with the
deployment's base path in front of it (`/` locally, `/elm-daisyui/` on GitHub
Pages). The `onClick` beside it keeps the base-free route, because `Main`
prefixes it on the way into `pushUrl`.
-}
href : Config msg -> String -> String
href config path =
    BasePath.join config.basePath path


{-| A sidebar entry. It carries both a real `href` (so it is a focusable link
that `Browser.application` intercepts as a `UrlRequest`) and an `onClick` that
pushes the same url, so navigation works with either.

`badge` is the soft primary pill Nexus puts on a new section.

-}
navItem : String -> Icon.Icon -> String -> msg -> Bool -> Maybe String -> MenuItem msg
navItem label icon path onClick active badge =
    let
        (MenuItem base) =
            Tree.menuItem label
    in
    MenuItem
        { base
            | glyph = Just (MenuIcon icon)
            , active = active
            , href = Just path
            , onClick = Just onClick
            , badge = Maybe.map softBadge badge
        }


softBadge : String -> Tree.MenuBadge
softBadge label =
    { config =
        { defaultBadge
            | color = Just SBadge.Primary
            , style = Just SBadge.Soft
            , size = Just SBadge.Sm
        }
    , label = label
    }


{-| The signed-in user, as the card pinned to the bottom of the sidebar panel.
-}
sidebarUser : Config msg -> Leaf msg
sidebarUser _ =
    UserChip
        { defaultUserChip | boxed = True }
        { avatar = avatarSrc "slateblue", name = "Denish N", subtitle = "@withden" }


defaultUserChip : Tree.UserChipConfig msg
defaultUserChip =
    Tree.defaultUserChipConfig


{-| The dashboard chrome. `Daisy.Render` puts the drawer toggle before
`navbar-start` and `Page.cta` after `navbar-end`, so the row reads: toggle,
search, then the theme switcher, notifications, the user chip and "Export".

Nothing goes in `navbar-center`: daisyUI fixes `navbar-start` and `navbar-end`
at 50% each, so a centre section has no width of its own to shrink into and its
contents would overlap the two halves at 375.

-}
navbar : Config msg -> NavbarParts msg
navbar config =
    { start = [ searchInput config ]
    , center = []
    , end = [ themeSwitcher config, notificationsButton config, navbarUser ]
    }


{-| A real `type="search"` control with a leading glyph, which switches
`Daisy.Render` to the `label`-wrapped shape daisyUI's docs use for a decorated
field. It is named by `ariaLabel` because a navbar has no `Field` to label it
(the same reason `Demo.Analytics`' date-range `Select` has one).
-}
searchInput : Config msg -> Leaf msg
searchInput config =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , icon = Just Icon.Search
            , inputType = InputSearch
            , placeholder = "Search"
            , value = config.search
            , ariaLabel = Just "Search orders"
            , onInput = Just config.onSearch
        }


defaultInput : Tree.InputConfig msg
defaultInput =
    Tree.defaultInputConfig


{-| An icon-only button, so its name comes from `ariaLabel` rather than from
text (axe's `button-name` is critical, and an unlabelled icon is `aria-hidden`
by design). The unread count is the button's `indicator`, which daisyUI puts on
the badge itself.
-}
notificationsButton : Config msg -> Leaf msg
notificationsButton config =
    Button
        { defaultButton
            | icon = Just Icon.Bell
            , ariaLabel = Just "Notifications"
            , style = Just SButton.Ghost
            , size = Just SButton.Sm
            , modifiers = [ SButton.Circle ]
            , indicator =
                Just
                    { config = Tree.defaultIndicatorConfig
                    , payload =
                        IndicatorBadge
                            { defaultBadge | color = Just SBadge.Error, size = Just SBadge.Xs }
                            "3"
                    }
            , onClick = Just config.onNotifications
        }
        ""


defaultBadge : Tree.BadgeConfig
defaultBadge =
    Tree.defaultBadgeConfig


{-| The same person as the sidebar card, unboxed, at the end of the navbar —
which is where Nexus puts theirs as well.
-}
navbarUser : Leaf msg
navbarUser =
    UserChip
        defaultUserChip
        { avatar = avatarSrc "slateblue", name = "Denish N", subtitle = "Team" }


{-| A flat vector portrait, one colour per person. No text, so it renders
identically wherever the suite runs.

The image is an inline `data:` URI rather than a file or a remote photo:
`e2e/themes.spec.ts` compares 105 full-page screenshots byte for byte, so the
avatar has to be there on the first paint, in every environment, with no
network and no font metrics involved.

-}
avatarSrc : String -> String
avatarSrc fill =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2040%2040'%3E"
        ++ "%3Crect%20width='40'%20height='40'%20fill='"
        ++ fill
        ++ "'/%3E%3Ccircle%20cx='20'%20cy='16'%20r='7'%20fill='white'/%3E"
        ++ "%3Cpath%20d='M7%2040c0-7.2%205.8-12%2013-12s13%204.8%2013%2012z'%20fill='white'/%3E%3C/svg%3E"


{-| A product thumbnail: a flat two-tone square, same reasoning as `avatarSrc`.
-}
productSrc : String -> String
productSrc fill =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2040%2040'%3E"
        ++ "%3Crect%20width='40'%20height='40'%20fill='"
        ++ fill
        ++ "'/%3E%3Crect%20x='10'%20y='12'%20width='20'%20height='16'%20rx='3'%20fill='white'"
        ++ "%20fill-opacity='0.75'/%3E%3C/svg%3E"


{-| The page CTA, with a leading `Download` glyph.

`InHeader` and `btn-sm`, which is where Nexus puts a page's action: its navbar
carries only search, notifications and the signed-in user, and the title row
carries what the page is _for_. The tree still allows exactly one primary
button, and `Daisy.Render` still decides its markup — `Cta.placement` only says
which piece of chrome it lands in.

-}
exportCta : Config msg -> Tree.Cta msg
exportCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Export report" config.onExport
    in
    { base
        | icon = Just Icon.Download
        , size = Just SButton.Sm
        , placement = Tree.InHeader
    }


{-| Every theme `Daisy.Tree.allThemes` knows, as one control.

`ThemeAsIconDropdown`, which is Nexus's own: a `btn btn-ghost btn-circle` around
a palette glyph, the same size and shape as the notification button beside it,
rather than a full-width button reading "Theme". Both dropdowns stay one control
wide — the other five presentations render a sibling `input.theme-controller`
per theme, which is 35 controls in `navbar-end`.

The dropdown opens on `:focus-within`, so tabbing to its `role=button` trigger
reveals the radio list and the next `Tab` lands on the checked theme; clicking
or activating a radio fires `onSelect`, which the router turns into
`ThemeChanged` and writes back to `Page.theme`.

-}
themeSwitcher : Config msg -> Leaf msg
themeSwitcher config =
    ThemeSelect
        { themes = Tree.allThemes
        , current = config.theme
        , presentation = ThemeAsIconDropdown
        , onSelect = Just config.onTheme
        }



-- PAGE HEADER ---------------------------------------------------------------


{-| Title on the left, trail on the right, in one row above the first section.
-}
headerBar : Tree.PageHeader msg
headerBar =
    let
        base : Tree.PageHeader msg
        base =
            Tree.pageHeader "Business Overview"
    in
    { base
        | breadcrumbs =
            [ Link { defaultLink | href = "#" } "Acme"
            , Text "Dashboards"
            , Text "Ecommerce"
            ]
    }


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig



-- SECTIONS ------------------------------------------------------------------


{-| The metric row: four `stats` panels across, one tile each.

One `Stat` block per tile inside a `Grid`, not one block of four tiles:
daisyUI's `.stats` is `grid-flow-col overflow-x-auto`, so a single block would
scroll sideways at 375 rather than wrap.

-}
metricsSection : Config msg -> Section msg
metricsSection _ =
    Grid
        (Tree.Columns { columns = Tree.Cols4 }
            [ metric Icon.CurrencyDollar "Revenue" "$587.54" (up "10.8%") "vs. $494.16 last period"
            , metric Icon.ShoppingCart "Sales" "4,500" (up "21.2%") "vs. 3,845 last period"
            , metric Icon.Users "Customers" "2,242" (down "6.8%") "vs. 2,448 last period"
            , metric Icon.Pencil "Spending" "$112.54" (up "8.5%") "vs. $98.14 last period"
            ]
        )


metric : Icon.Icon -> String -> String -> Leaf msg -> String -> Block msg
metric icon title value trend desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    -- `Fixed Vertical`, not the default. `.stats` is `grid-flow-col
    -- overflow-x-auto`, so a one-tile row whose contents are wider than its
    -- 269px cell becomes a scrollable region — and a scrollable region is a tab
    -- stop of its own (`e2e/keyboard.spec.ts`), which the arrow glyph inside
    -- the delta badge was enough to trigger. One tile looks identical either
    -- way; only the flow direction changes.
    Stat { direction = Tree.Fixed (Just SStat.Vertical) }
        [ { base | trend = Just trend, desc = Just desc, figure = Just (figureIcon icon) } ]


{-| The delta pill beside a number: a soft badge with a leading arrow, exactly
what Nexus puts there — `\u{2191} 10.8%` in green, `\u{2193} 6.8%` in red. The arrow is
`BadgeConfig.icon`, decorative, with the percentage as the badge's text.
-}
up : String -> Leaf msg
up value =
    trendBadge SBadge.Success Icon.ArrowTrendingUp value


down : String -> Leaf msg
down value =
    trendBadge SBadge.Error Icon.ArrowTrendingDown value


trendBadge : SBadge.Color -> Icon.Icon -> String -> Leaf msg
trendBadge color icon value =
    Badge
        { defaultBadge
            | icon = Just icon
            , color = Just color
            , style = Just SBadge.Soft
            , size = Just SBadge.Xs
        }
        value


{-| A `stat-figure` glyph. `Daisy.Render` paints the shaded tile around it and
pins it to the top of the tile (`self-start`), which is where Nexus's sits.
-}
figureIcon : Icon.Icon -> Leaf msg
figureIcon icon =
    Icon { defaultIcon | size = Tree.IconMd } icon


defaultIcon : Tree.IconConfig
defaultIcon =
    Tree.defaultIconConfig


{-| The two chart panels, in Nexus's own 7:5 split.

`GridSection.Spans` is the twelve-column grid; the seven-track cell is the
revenue chart and the five-track cell the acquisition one. Measured off Nexus at
1440: `grid-template-columns: repeat(12, 72.66px)`, `gap: 24px`, the first panel
spanning seven tracks and the second five.

-}
chartsSection : Config msg -> Section msg
chartsSection config =
    Grid
        (Tree.Spans
            [ Tree.span Tree.Span7 (revenueCard config)
            , Tree.span Tree.Span5 (acquisitionCard config)
            ]
        )


{-| Nexus's Revenue Statistics panel: a headline number, then stacked
`Orders`/`Revenue` columns on a full-height track with rounded caps, a hover
tooltip and a legend. The `Day | Month | Year` strip in the header picks the
dataset.
-}
revenueCard : Config msg -> Block msg
revenueCard config =
    Card dashboardCard
        { emptyCard
            | title = Just "Revenue Statistics"
            , headerTabs = Just { config = segmentedConfig, tabs = periodTabs config }
            , body =
                [ CardStat Tree.defaultStatConfig
                    [ totalIncome (revenueTotal config.chartRange) (up "3.24%") (revenueCaption config.chartRange) ]
                , CardChart revenueChartConfig
                    (revenueSeries config.chartRange)
                    (Just
                        { hovered = config.hoveredBar
                        , onHover = config.onChartHover
                        }
                    )
                ]
        }


{-| Nexus's bars, as a `BarStyle`: the two series stacked into one column, a
`base-200` track behind every column, and both caps rounded.
-}
revenueChartConfig : DChart.ChartConfig
revenueChartConfig =
    DChart.Bar { stacked = True, track = True, rounded = True }


acquisitionCard : Config msg -> Block msg
acquisitionCard _ =
    Card dashboardCard
        { emptyCard
            | title = Just "Customer Acquisition"
            , headerActions = [ predictionBadge ]
            , body =
                [ -- `Responsive` is daisyUI's `stats-vertical
                  -- lg:stats-horizontal`: two tiles side by side in a
                  -- half-width card at 1440, stacked below `lg`. A `Fixed`
                  -- horizontal pair is `grid-flow-col overflow-x-auto`, so
                  -- at 375 it becomes a scrollable region no keyboard can
                  -- reach — axe's `scrollable-region-focusable`, serious.
                  CardStat { direction = Tree.Responsive }
                    [ headline "Advertise" "$148" (up "4.78%") "spend per customer"
                    , headline "Customers" "427" (up "3.15%") "acquired this month"
                    ]
                , CardChart (DChart.Line { stepped = True }) acquisitionSeries Nothing
                ]
        }


{-| Every panel on this page is 20px-padded, which is the figure Nexus's own CSS
sets on `.card-body` (measured: `padding: 20px`). daisyUI's two card sizes are
24px and 16px, so this is `CardPadding.PaddingDashboard`.
-}
dashboardCard : Tree.CardConfig
dashboardCard =
    { defaultCard | padding = Tree.PaddingDashboard }


defaultCard : Tree.CardConfig
defaultCard =
    Tree.defaultCardConfig


{-| A labelled stat: the label above, the number with its delta beside it, and
a caption under both. The two Customer Acquisition tiles read that way in Nexus.
-}
headline : String -> String -> Leaf msg -> String -> StatItem msg
headline title value trend desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    { base | trend = Just trend, desc = Just desc }


{-| The Revenue Statistics headline: the big number, its delta inline to the
right, and one muted caption **below** — which is the order Nexus reads in, and
the opposite of a metric tile, where the label comes first.

The title is deliberately empty. `Daisy.Render` emits no `stat-title` for an
empty one (the same rule as an empty `breadcrumbs` trail and a `Tab` with no
content), so the number is the first thing in the tile and the whole label
lives in the caption.

-}
totalIncome : String -> Leaf msg -> String -> StatItem msg
totalIncome value trend caption =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem "" value
    in
    { base | trend = Just trend, desc = Just caption }


{-| `tabs tabs-box tabs-xs`, the segmented control Nexus uses to pick a period.
Every tab has an empty `content`, so `Daisy.Render` emits no `tab-content`
panel behind it and the strip stays a control rather than a tab set.
-}
segmentedConfig : Tree.TabsConfig
segmentedConfig =
    { style = Just STab.Box, size = Just STab.Xs, placement = Nothing }


periodTabs : Config msg -> List (Tab msg)
periodTabs config =
    List.map
        (\range ->
            { label = chartRangeLabel range
            , active = range == config.chartRange
            , disabled = False
            , content = []
            , onClick = Just (config.onChartRange range)
            }
        )
        allChartRanges


predictionBadge : Leaf msg
predictionBadge =
    Badge
        { defaultBadge | style = Just SBadge.Soft, size = Just SBadge.Sm }
        "Prediction"


emptyCard : Tree.CardParts msg
emptyCard =
    Tree.emptyCardParts


{-| The three revenue datasets the `Day | Month | Year` strip switches between.

They are three whole `ChartData` values rather than one sliced three ways,
because the point of the switch in a Tier C test is that the _drawing_ changes:
`Daisy.Render` keys the chart group by the dataset, so a different key remounts
the SVG and replays the grow-in animation.

-}
revenueSeries : ChartRange -> DChart.ChartData
revenueSeries range =
    case range of
        Day ->
            { xLabels = [ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ]
            , series =
                [ DChart.series "Orders" DChart.Warning [ 12, 9, 14, 11, 18, 22, 16 ]
                , DChart.series "Revenue" DChart.Primary [ 24, 21, 29, 26, 34, 41, 31 ]
                ]
            }

        Month ->
            { xLabels =
                [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]
            , series =
                [ DChart.series "Orders" DChart.Warning [ 31, 28, 36, 34, 42, 39, 47, 51, 46, 55, 62, 58 ]
                , DChart.series "Revenue" DChart.Primary [ 64, 59, 71, 68, 83, 79, 92, 98, 90, 104, 118, 111 ]
                ]
            }

        Year ->
            { xLabels =
                [ "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025" ]
            , series =
                [ DChart.series "Orders" DChart.Warning [ 42, 51, 49, 68, 81, 76, 93, 105, 114, 126 ]
                , DChart.series "Revenue" DChart.Primary [ 98, 101, 124, 129, 142, 155, 168, 181, 194, 212 ]
                ]
            }


revenueTotal : ChartRange -> String
revenueTotal range =
    case range of
        Day ->
            "$4.82K"

        Month ->
            "$62.14K"

        Year ->
            "$184.78K"


revenueCaption : ChartRange -> String
revenueCaption range =
    case range of
        Day ->
            "Total income in this week"

        Month ->
            "Total income in this year"

        Year ->
            "Total income over ten years"


{-| Nexus's Customer Acquisition chart: one stepped line for the measured series
and a dashed one for the projection beside it — the convention `Series.dashed`
exists for.
-}
acquisitionSeries : DChart.ChartData
acquisitionSeries =
    { xLabels =
        [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12" ]
    , series =
        [ DChart.series "Customer" DChart.Info [ 18, 24, 22, 31, 38, 35, 44, 47, 52, 58, 61, 67 ]
        , { name = "Prediction"
          , color = DChart.Neutral
          , points = [ 12, 15, 17, 19, 24, 26, 28, 31, 33, 36, 38, 41 ]
          , dashed = True
          }
        ]
    }


{-| The bottom band: the orders table and the message list beside it.

Nexus's own is a five-column grid split 3:2. Twelve tracks cannot say 3:2
exactly (it is 7.2 : 4.8), so this is 7:5 — 654px and 458px against Nexus's
682 and 430 at 1440, a 28px difference in a 1136px column. `Span` starts at
three of twelve for the reason its docs give, and the alternative (a second
`GridColumns` value for five equal tracks) would be a column count that exists
for one band on one page.

-}
activitySection : Config msg -> Section msg
activitySection config =
    Grid
        (Tree.Spans
            [ Tree.span Tree.Span7
                (Card dashboardCard
                    { emptyCard
                        | title = Just "Recent Orders"
                        , titleIcon = Just Icon.ShoppingCart
                        , headerActions = [ reportButton config ]
                        , body =
                            [ CardTable
                                { size = Just STable.Sm, modifiers = [] }
                                (headerRow :: List.map (orderRow config) orders)
                            ]
                    }
                )
            , Tree.span Tree.Span5
                (Card dashboardCard
                    { emptyCard
                        | title = Just "Quick Chat"
                        , titleIcon = Just Icon.User
                        , headerActions = [ chatButton config ]
                        , body = [ CardChat (List.map chatMessage messages) ]
                    }
                )
            ]
        )


reportButton : Config msg -> Leaf msg
reportButton config =
    Button
        { defaultButton
            | icon = Just Icon.Download
            , style = Just SButton.Outline
            , size = Just SButton.Sm
            , onClick = Just config.onExport
        }
        "Report"


chatButton : Config msg -> Leaf msg
chatButton config =
    Button
        { defaultButton
            | style = Just SButton.Outline
            , size = Just SButton.Sm
            , onClick = Just config.onNotifications
        }
        "Go To Chat"


{-| The debug pane the Tier C "interaction" spec reads. Always present, always
exactly `last-msg: <constructor name of the last Msg the router handled>`.
-}
debugSection : Config msg -> Section msg
debugSection config =
    Stack Tree.defaultStackConfig [ Prose [ Text ("last-msg: " ++ config.lastMsg) ] ]


headerRow : Row msg
headerRow =
    { header = True
    , cells =
        Tree.tableCell (Checkbox { defaultCheckbox | ariaLabel = Just "Select all orders" })
            :: List.map Tree.tableCell
                [ Text "Product"
                , Text "Price"
                , Text "Date"
                , Text "Status"
                , Text "Action"
                ]
    }


defaultCheckbox : Tree.CheckboxConfig msg
defaultCheckbox =
    Tree.defaultCheckboxConfig


type alias Order =
    { reference : String
    , product : String
    , swatch : String
    , price : String
    , date : String
    , state : String
    , tone : SBadge.Color
    }


orders : List Order
orders =
    [ Order "AC-10432" "Trail shoes" "seagreen" "$99" "25 Jun" "Delivered" SBadge.Success
    , Order "AC-10431" "Cocooil oil" "goldenrod" "$75" "22 Jun" "On Going" SBadge.Info
    , Order "AC-10429" "Freeze Air" "steelblue" "$47" "17 Jun" "Confirmed" SBadge.Primary
    , Order "AC-10427" "Tote bag" "sienna" "$52" "23 Jun" "Canceled" SBadge.Error
    , Order "AC-10425" "Desk lamp" "slateblue" "$120" "14 Jun" "Delivered" SBadge.Success
    ]


{-| The product cell is a `TableCell` with a `leading` thumbnail, which is the
image-and-name idiom daisyUI's "table with visual elements" example uses. The
action cell carries the two icon-only buttons the same way: `leading` is the
first, `content` the second.
-}
orderRow : Config msg -> Order -> Row msg
orderRow config order =
    { header = False
    , cells =
        [ Tree.tableCell
            (Checkbox
                { defaultCheckbox
                    | size = Just SCheckbox.Sm
                    , ariaLabel = Just ("Select order " ++ order.reference)
                }
            )
        , { leading = Just (thumbnail order.swatch)
          , content = Text order.product
          }
        , Tree.tableCell (Text order.price)
        , Tree.tableCell (Text order.date)
        , Tree.tableCell
            (Badge
                { defaultBadge
                    | color = Just order.tone
                    , style = Just SBadge.Soft
                    , size = Just SBadge.Sm
                }
                order.state
            )
        , { leading = Just (rowAction config Icon.Eye "View order " order.reference)
          , content = rowAction config Icon.Trash "Delete order " order.reference
          }
        ]
    }


{-| The product thumbnail, as an `Avatar` rather than an `Image`.

`Leaf.Image` is a bare `<img>` at its natural size — right for a `card-figure`
or a `carousel-item`, wrong for a 32px chip in a table row. `Leaf.Avatar` is the
sized, masked frame daisyUI puts around exactly this: `avatar` > a
`mask-squircle` box > the image, which is the markup Nexus's own orders table
uses for its product pictures.

-}
thumbnail : String -> Leaf msg
thumbnail swatch =
    Avatar
        { defaultAvatar | mask = Just { defaultMask | style = Just SMask.Squircle } }
        (productSrc swatch)


defaultAvatar : Tree.AvatarConfig msg
defaultAvatar =
    Tree.defaultAvatarConfig


defaultMask : Tree.MaskConfig
defaultMask =
    Tree.defaultMaskConfig


rowAction : Config msg -> Icon.Icon -> String -> String -> Leaf msg
rowAction config icon verb reference =
    Button
        { defaultButton
            | icon = Just icon
            , ariaLabel = Just (verb ++ reference)
            , style = Just SButton.Ghost
            , size = Just SButton.Xs
            , modifiers = [ SButton.Square ]
            , onClick = Just (config.onRowAction reference)
        }
        ""


defaultButton : Tree.ButtonConfig msg
defaultButton =
    Tree.defaultButtonConfig


type alias Message =
    { author : String
    , avatar : String
    , text : String
    , time : String
    }


messages : List Message
messages =
    [ Message "Mia Johnson" "teal" "It's called 'Dreamscape.' A must-watch." "11:35 AM"
    , Message "Ethan Patel" "sienna" "Shipping labels are queued for the morning." "09:58 AM"
    , Message "Ava Chen" "darkslategray" "Refund for AC-10427 has been approved." "09:12 AM"
    ]


chatMessage : Message -> ChatMessage msg
chatMessage message =
    { placement = SChat.Start
    , color = Nothing
    , image = Just (avatarSrc message.avatar)
    , header = Just (message.author ++ " · " ++ message.time)
    , bubble = [ Text message.text ]
    , footer = Nothing
    }



-- OVERLAY -------------------------------------------------------------------


toastOverlay : Overlay msg
toastOverlay =
    Toast Tree.defaultToastConfig
        [ Alert
            { color = Just SAlert.Success, style = Nothing, direction = Nothing }
            [ Text "Report queued — we will email the CSV when it is ready." ]
        ]
