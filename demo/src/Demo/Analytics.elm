module Demo.Analytics exposing (Config, calendarConfig, dateRanges, page)

{-| The chart-heavy demo (SPEC.md step 7, row "Analytics").

Dashboard shell, one responsive `Stat` row of four tiles, a `Chart Bar` and a
`Chart Donut` side by side and a full-width `Chart Area` — each chart in its
own `Card` with a `card-title` — a `Leaf.Calendar` range picker in a "Date
range" card, and a date-range `Select` in the navbar.

Section titles are `Leaf.Heading` leaves inside `Prose`, plus the `card-title`
of each chart card (daisyUI renders `card-title` as an `<h2>`), so the page has
one `H1` and a heading per band.

Like every `Demo.*` module this imports no `Html`: the page is a `Daisy.Tree`
value and `Daisy.Render` owns every class.

@docs Config, calendarConfig, dateRanges, page

-}

import Daisy.Chart as DChart
import Daisy.Schema.Card as SCard
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Select as SSelect
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , CalendarConfig
        , CalendarMsg
        , CalendarState
        , CalendarValue
        , CardChild(..)
        , HeadingLevel(..)
        , Leaf(..)
        , MenuItem(..)
        , MenuSpec
        , NavbarParts
        , Page(..)
        , Section(..)
        , Sections(..)
        , Shell(..)
        , StatDirection(..)
        , StatItem
        , Theme
        )
import Date exposing (Date)


{-| What the analytics page needs from the router.
-}
type alias Config msg =
    { theme : Theme
    , lastMsg : String
    , dateRange : String
    , dateRangeCaption : String
    , calendar : CalendarState
    , today : Date
    , onNavigate : String -> msg
    , onRangeSelect : String -> msg
    , onCalendarMsg : CalendarMsg -> msg
    , onCalendarChange : CalendarValue -> msg
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
                (statsSection config)
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
    { start = [ Text "Acme Console" ]
    , center = []
    , end = [ dateRangeSelect config ]
    }


{-| The navbar has no `Field` to label it, so the select names itself with
`ariaLabel`. It used to borrow the name from a `Tooltip` it did not otherwise
want — `SelectConfig` had no label field at all — and that workaround is gone.
-}
dateRangeSelect : Config msg -> Leaf msg
dateRangeSelect config =
    Select
        { defaultSelect
            | size = Just SSelect.Sm
            , ariaLabel = Just "Date range"
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
            [ Heading H1 "Acquisition"
            , Text "Where sessions come from, what they cost, and how many of them convert."
            ]
        ]


{-| One `Stat` block holding all four tiles, with `direction = Responsive`.

`Responsive` is daisyUI's own `stats-vertical lg:stats-horizontal` idiom: a
column on a phone, a row from `lg` up. A `Fixed` horizontal row would scroll
sideways at 375 instead of wrapping, because `.stats` is `grid-flow-col
overflow-x-auto` — which is why this used to be four separate blocks in a
`Grid Cols4`. The one-column `Grid` is what makes the block fill the band.

-}
statsSection : Config msg -> Section msg
statsSection config =
    Grid { columns = Tree.Cols1 }
        [ Prose [ Heading H2 "Key metrics" ]
        , Stat { direction = Responsive }
            [ statItem "Sessions" "486,204" "9.1% week over week"
            , statItem "Conversion" "3.24%" "0.31 points above plan"
            , statItem "Cost per acquisition" "$14.80" "$1.20 cheaper than Q2"
            , statItem "Assisted revenue" "$91,470" "31% of total revenue"
            ]
        , dateRangeCard config
        ]


{-| The `Leaf.Calendar` range picker, in a card of its own.

It is the real thing, not a picture of one: `alexbruf/elm-cally` renders the
markup and `part` attributes daisyUI's `cally` class styles, `Main` keeps the
`CalendarState` and forwards `onCalendarMsg` to
`Daisy.Render.updateCalendar`, and the caption below echoes whatever
`onCalendarChange` last reported.

One month, not two: daisyUI's `calendar.css` gives `part="months"` no layout
of its own, so a second grid would stack under the first and make the card
twice as tall for no extra information.

-}
dateRangeCard : Config msg -> Block msg
dateRangeCard config =
    Card borderedCard
        { emptyCard
            | title = Just "Date range"
            , body =
                [ CardLeaf
                    (Calendar
                        (calendarConfig
                            { today = config.today
                            , toMsg = config.onCalendarMsg
                            , onChange = config.onCalendarChange
                            }
                        )
                        config.calendar
                    )
                , CardLeaf (Text config.dateRangeCaption)
                ]
        }


{-| The picker's config, shared with `Main`.

`Main` needs the very same value to build the state with
`Daisy.Render.initCalendarRange` and to advance it with
`Daisy.Render.updateCalendar` — the DOM id prefix and the month count have to
agree between the three or focus management and paging would disagree with
what is on screen — so it is written once, here, and taken by whichever
messages the caller has.

-}
calendarConfig :
    { today : Date
    , toMsg : CalendarMsg -> msg
    , onChange : CalendarValue -> msg
    }
    -> CalendarConfig msg
calendarConfig given =
    Tree.defaultCalendarConfig
        { id = "analytics-range"
        , today = given.today
        , toMsg = given.toMsg
        , onChange = given.onChange
        }


statItem : String -> String -> String -> StatItem msg
statItem title value desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    { base | desc = Just desc }


{-| Two chart cards side by side. Their `card-title`s are the band's headings:
`Daisy.Render` draws `card-title` as an `<h2>`, so a `Prose` heading on top of
them would only repeat the same rank — and a `Prose` block in a two-column grid
would take one of the two cells.
-}
breakdownSection : Section msg
breakdownSection =
    Grid { columns = Tree.Cols2 }
        [ chartCard "Sessions by channel" (CardChart DChart.Bar channelSeries)
        , chartCard "Sessions by device" (CardChart DChart.Donut deviceSeries)
        ]


chartCard : String -> CardChild msg -> Block msg
chartCard title child =
    Card borderedCard
        { emptyCard | title = Just title, body = [ child ] }


emptyCard : Tree.CardParts msg
emptyCard =
    Tree.emptyCardParts


{-| `card-border` — without a style a `card` paints nothing of its own, so on a
`base-100` page it is invisible and "the chart is in a card" does not read.
-}
borderedCard : Tree.CardConfig
borderedCard =
    { defaultCard | style = Just SCard.Border }


defaultCard : Tree.CardConfig
defaultCard =
    Tree.defaultCardConfig


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


{-| `AlignStretch`, so the card fills the band rather than shrinking to its
content. The shell is `Dashboard`, so the page CTA sits in the navbar and
stretching the last section cannot reach it.
-}
trafficSection : Config msg -> Section msg
trafficSection config =
    Stack { align = AlignStretch }
        [ Prose [ Heading H2 "Traffic" ]
        , chartCard ("Sessions and signups — " ++ config.dateRange)
            (CardChart DChart.Area trafficSeries)
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
