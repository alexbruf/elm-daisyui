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

import BasePath
import Daisy.Chart as DChart
import Daisy.Icon as Icon
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Card as SCard
import Daisy.Schema.Mask as SMask
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
        , IndicatorPayload(..)
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
    { basePath : String
    , theme : Theme
    , lastMsg : String
    , dateRange : String
    , dateRangeCaption : String
    , calendar : CalendarState
    , today : Date
    , onNavigate : String -> msg
    , onRangeSelect : String -> msg
    , onCalendarMsg : CalendarMsg -> msg
    , onCalendarChange : CalendarValue -> msg
    , onNotifications : msg
    , onDownload : msg
    }


{-| The whole analytics dashboard as one `Page`.
-}
page : Config msg -> Page msg
page config =
    Page
        { header = Just (headerBar config)
        , shell =
            Dashboard
                { brand = Just { icon = Icon.ChartBar, name = "Acme" }
                , sidebar = sidebar config
                , sidebarFooter = Just sidebarUser
                , navbar = navbar config
                }
        , sections =
            Sections3
                (statsSection config)
                breakdownSection
                (trafficSection config)
        , cta = downloadCta config
        , overlays = []
        , theme = config.theme
        , dock = Nothing
        , fab = Nothing
        }



-- SHELL ---------------------------------------------------------------------


sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = defaultMenu
    , items =
        [ sectionTitle "Dashboards"
        , navItem "Overview" Icon.Home (href config "/") (config.onNavigate "/") False
        , navItem "Analytics" Icon.ChartBar (href config "/analytics") (config.onNavigate "/analytics") True
        , sectionTitle "Workspace"
        , navItem "Settings" Icon.Cog (href config "/settings") (config.onNavigate "/settings") False
        , docsItem config
        ]
    }


{-| A `menu-title` row: it labels the group under it and is not a link. The
same two groups `Demo.Admin` uses, so the shell is identical on both
dashboards.
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
    MenuItem
        { label = "Docs"
        , icon = Just Icon.Document
        , badge = Nothing
        , active = False
        , disabled = False
        , focus = False
        , title = False
        , href = Just (href config "/docs/")
        , onClick = Nothing
        , submenu = []
        }


defaultMenu : Tree.MenuConfig
defaultMenu =
    Tree.defaultMenuConfig


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
-}
navItem : String -> Icon.Icon -> String -> msg -> Bool -> MenuItem msg
navItem label icon path onClick active =
    MenuItem
        { label = label
        , icon = Just icon
        , badge = Nothing
        , active = active
        , disabled = False
        , focus = False
        , title = False
        , href = Just path
        , onClick = Just onClick
        , submenu = []
        }


{-| The same dashboard chrome `Demo.Admin` carries, with the date-range switcher
in place of the theme dropdown: notifications, the signed-in user, and then
`Page.cta` ("Download CSV"), which `Daisy.Render` appends after `navbar-end`.

`navbar-center` stays empty on purpose — daisyUI fixes the two halves at 50%
each, so anything between them has no width to shrink into at 375.

-}
navbar : Config msg -> NavbarParts msg
navbar config =
    { start = []
    , center = []
    , end = [ notificationsButton config, navbarUser ]
    }


{-| An icon-only button: its accessible name is `ariaLabel`, because the `Bell`
glyph beside it is `aria-hidden` by design. The unread count rides along as the
button's `indicator`.
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


defaultButton : Tree.ButtonConfig msg
defaultButton =
    Tree.defaultButtonConfig


defaultBadge : Tree.BadgeConfig
defaultBadge =
    Tree.defaultBadgeConfig


{-| The signed-in user. The portrait is an inline `data:` URI so the 105 theme
screenshots are byte-identical everywhere: no network, no fonts.
-}
navbarUser : Leaf msg
navbarUser =
    UserChip
        defaultUserChip
        { avatar = avatarSrc, name = "Denish N", subtitle = "Team" }


{-| The same person, boxed, pinned to the bottom of the sidebar panel.
-}
sidebarUser : Leaf msg
sidebarUser =
    UserChip
        { defaultUserChip | boxed = True }
        { avatar = avatarSrc, name = "Denish N", subtitle = "@withden" }


defaultUserChip : Tree.UserChipConfig msg
defaultUserChip =
    Tree.defaultUserChipConfig


defaultAvatar : Tree.AvatarConfig msg
defaultAvatar =
    Tree.defaultAvatarConfig


defaultMask : Tree.MaskConfig
defaultMask =
    Tree.defaultMaskConfig


avatarSrc : String
avatarSrc =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2040%2040'%3E"
        ++ "%3Crect%20width='40'%20height='40'%20fill='slateblue'/%3E"
        ++ "%3Ccircle%20cx='20'%20cy='16'%20r='7'%20fill='white'/%3E"
        ++ "%3Cpath%20d='M7%2040c0-7.2%205.8-12%2013-12s13%204.8%2013%2012z'%20fill='white'/%3E%3C/svg%3E"


{-| The page CTA, with a leading `Download` glyph.
-}
downloadCta : Config msg -> Tree.Cta msg
downloadCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Download CSV" config.onDownload
    in
    { base | icon = Just Icon.Download, size = Just SButton.Sm }


{-| The card header has no `Field` to label it, so the select names itself with
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


{-| Title on the left, trail on the right — the same band `Demo.Admin` carries,
rendered by the shell above the sections rather than costing one.
-}
headerBar : Config msg -> Tree.PageHeader msg
headerBar _ =
    let
        base : Tree.PageHeader msg
        base =
            Tree.pageHeader "Acquisition"
    in
    { base
        | breadcrumbs =
            [ Link { defaultLink | href = "#" } "Acme"
            , Text "Dashboards"
            , Text "Acquisition"
            ]
    }


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig


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
        [ Stat { direction = Responsive }
            [ statItem Icon.Users "Sessions" "486,204" "9.1% week over week"
            , statItem Icon.ArrowTrendingUp "Conversion" "3.24%" "0.31 points above plan"
            , statItem Icon.CurrencyDollar "Cost per acquisition" "$14.80" "$1.20 cheaper than Q2"
            , statItem Icon.ChartBar "Assisted revenue" "$91,470" "31% of total revenue"
            ]
        , dateRangeCard config
        ]


{-| The `Leaf.Calendar` range picker, in a card of its own.

It is the real thing, not a picture of one: `alexbruf/elm-cally` renders the
markup and `part` attributes daisyUI's `cally` class styles, `Main` keeps the
`CalendarState` and forwards `onCalendarMsg` to
`Daisy.Render.updateCalendar`, and the caption below echoes whatever
`onCalendarChange` last reported.

`TwoMonths`, which is what a range picker wants: the second grid sits beside
the first from `sm` up (the card is 686px wide at 768 and 1102px at 1440, and
two grids plus the gap need 520px) and drops under it at 375, where the card
has 293px. `Daisy.Render` gives `[part~="months"]` that layout — neither
elm-cally nor daisyUI styles it.

-}
dateRangeCard : Config msg -> Block msg
dateRangeCard config =
    Card borderedCard
        { emptyCard
            | title = Just "Date range"
            , titleIcon = Just Icon.Calendar
            , headerActions = [ dateRangeSelect config ]
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
    let
        base : CalendarConfig msg
        base =
            Tree.defaultCalendarConfig
                { id = "analytics-range"
                , today = given.today
                , toMsg = given.toMsg
                , onChange = given.onChange
                }
    in
    { base | months = Tree.TwoMonths }


statItem : Icon.Icon -> String -> String -> String -> StatItem msg
statItem icon title value desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    { base | desc = Just desc, figure = Just (figureIcon icon) }


{-| A `stat-figure` glyph: the largest icon size, and decorative — the tile's
`stat-title` already names the number.
-}
figureIcon : Icon.Icon -> Leaf msg
figureIcon icon =
    Icon { defaultIcon | size = Tree.IconMd } icon


defaultIcon : Tree.IconConfig
defaultIcon =
    Tree.defaultIconConfig


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


{-| `card-border`. `Daisy.Render` paints every card `bg-base-100 shadow-sm` on
the `bg-base-200` content ground, so the panel already reads as raised; the
border is what daisyUI's own dashboard examples add on top.
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
        [ chartCard ("Sessions and signups — " ++ config.dateRange)
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
