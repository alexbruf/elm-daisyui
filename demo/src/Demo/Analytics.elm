module Demo.Analytics exposing (Config, dateRanges, page)

{-| The chart-heavy demo (SPEC.md step 7, row "Analytics").

Dashboard shell, a horizontal `Stat` row, a `Chart Bar` and a `Chart Donut`
side by side, a full-width `Chart Area`, and a date-range `Select` in the
navbar.

Like every `Demo.*` module this imports no `Html`: the page is a `Daisy.Tree`
value and `Daisy.Render` owns every class.

@docs Config, dateRanges, page

-}

import Daisy.Chart as DChart
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Select as SSelect
import Daisy.Tree as Tree
    exposing
        ( Block(..)
        , Leaf(..)
        , MenuItem(..)
        , MenuSpec
        , NavbarParts
        , Page(..)
        , Section(..)
        , Sections(..)
        , Shell(..)
        , StatItem
        , Theme
        )


{-| What the analytics page needs from the router.
-}
type alias Config msg =
    { theme : Theme
    , lastMsg : String
    , dateRange : String
    , onNavigate : String -> msg
    , onRangeSelect : String -> msg
    , onDownload : msg
    }


{-| The whole analytics dashboard as one `Page`.
-}
page : Config msg -> Page msg
page config =
    Page
        { shell =
            Dashboard
                { sidebar = sidebar config
                , navbar = navbar config
                }
        , sections =
            Sections4
                headerSection
                statsSection
                breakdownSection
                (trafficSection config)
        , cta = Tree.cta "Download CSV" config.onDownload
        , overlays = []
        , theme = config.theme
        , dock = Nothing
        , fab = Nothing
        }



-- SHELL ---------------------------------------------------------------------


sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = { defaultMenu | size = Just SMenu.Lg }
    , items =
        [ navItem "Overview" "/" (config.onNavigate "/") False
        , navItem "Analytics" "/analytics" (config.onNavigate "/analytics") True
        , navItem "Settings" "/settings" (config.onNavigate "/settings") False
        ]
    }


defaultMenu : Tree.MenuConfig
defaultMenu =
    Tree.defaultMenuConfig


{-| A sidebar entry. It carries both a real `href` (so it is a focusable link
that `Browser.application` intercepts as a `UrlRequest`) and an `onClick` that
pushes the same url, so navigation works with either.
-}
navItem : String -> String -> msg -> Bool -> MenuItem msg
navItem label path onClick active =
    MenuItem
        { label = label
        , icon = Nothing
        , badge = Nothing
        , active = active
        , disabled = False
        , focus = False
        , title = False
        , href = Just path
        , onClick = Just onClick
        , submenu = []
        }


navbar : Config msg -> NavbarParts msg
navbar config =
    { start = [ Text "Acquisition" ]
    , center = []
    , end = [ dateRangeSelect config ]
    }


{-| The navbar has no `Field` to label it, so the select carries a `Tooltip`.
`Daisy.Render` uses the tooltip text as the control's accessible name, which
is what keeps the navbar select from being an unnamed form control.
-}
dateRangeSelect : Config msg -> Leaf msg
dateRangeSelect config =
    Select
        { defaultSelect
            | size = Just SSelect.Sm
            , tooltip = Just { text = "Date range", config = Tree.defaultTooltipConfig }
            , onSelect = Just config.onRangeSelect
        }
        { options = dateRanges, selected = Just config.dateRange }


defaultSelect : Tree.SelectConfig msg
defaultSelect =
    Tree.defaultSelectConfig


{-| The date ranges the navbar switcher offers. `Main` uses the head of this
list as the initial value.
-}
dateRanges : List String
dateRanges =
    [ "Last 7 days", "Last 30 days", "Last 90 days", "Year to date" ]



-- SECTIONS ------------------------------------------------------------------


headerSection : Section msg
headerSection =
    Stack Tree.defaultStackConfig
        [ Prose
            [ Text "Where sessions come from, what they cost, and how many of them convert." ]
        ]


{-| One `Stat` block per tile rather than one block holding four items.
daisyUI's `.stats` is `grid-flow-col overflow-x-auto`, so a four-item block is
a single row that scrolls sideways at 375px instead of wrapping; four blocks in
a `Grid` wrap with the grid. Recorded in `docs/e2e-findings.md`.
-}
statsSection : Section msg
statsSection =
    Grid { columns = Tree.Cols4 }
        [ statBlock "Sessions" "486,204" "9.1% week over week"
        , statBlock "Conversion" "3.24%" "0.31 points above plan"
        , statBlock "Cost per acquisition" "$14.80" "$1.20 cheaper than Q2"
        , statBlock "Assisted revenue" "$91,470" "31% of total revenue"
        ]


statBlock : String -> String -> String -> Block msg
statBlock title value desc =
    Stat Tree.defaultStatConfig [ statItem title value desc ]


statItem : String -> String -> String -> StatItem msg
statItem title value desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    { base | desc = Just desc }


breakdownSection : Section msg
breakdownSection =
    Grid { columns = Tree.Cols2 }
        [ Chart DChart.Bar channelSeries
        , Chart DChart.Donut deviceSeries
        ]


channelSeries : DChart.ChartData
channelSeries =
    { xLabels = [ "Q1", "Q2", "Q3", "Q4" ]
    , series =
        [ { name = "Paid search"
          , color = DChart.Primary
          , points = [ 82, 91, 104, 118 ]
          }
        , { name = "Organic"
          , color = DChart.Success
          , points = [ 64, 71, 76, 88 ]
          }
        , { name = "Referral"
          , color = DChart.Accent
          , points = [ 28, 31, 30, 37 ]
          }
        ]
    }


deviceSeries : DChart.ChartData
deviceSeries =
    { xLabels = []
    , series =
        [ { name = "Desktop", color = DChart.Primary, points = [ 54 ] }
        , { name = "Mobile", color = DChart.Secondary, points = [ 38 ] }
        , { name = "Tablet", color = DChart.Warning, points = [ 8 ] }
        ]
    }


trafficSection : Config msg -> Section msg
trafficSection config =
    Stack Tree.defaultStackConfig
        [ Prose [ Text ("Sessions and signups — " ++ config.dateRange) ]
        , Chart DChart.Area trafficSeries
        , debugPane config
        ]


trafficSeries : DChart.ChartData
trafficSeries =
    { xLabels = [ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ]
    , series =
        [ { name = "Sessions"
          , color = DChart.Info
          , points = [ 68, 74, 81, 79, 92, 61, 55 ]
          }
        , { name = "Signups"
          , color = DChart.Success
          , points = [ 12, 14, 17, 15, 21, 9, 8 ]
          }
        ]
    }


{-| The debug pane the Tier C "interaction" spec reads. Same convention on
every demo: exactly `last-msg: <constructor name of the last Msg handled>`.
-}
debugPane : Config msg -> Block msg
debugPane config =
    Prose [ Text ("last-msg: " ++ config.lastMsg) ]
