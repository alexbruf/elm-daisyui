module Demo.Admin exposing (Config, page)

{-| The admin dashboard demo (SPEC.md step 7, row "Admin").

Dashboard shell, four `Stat` tiles in a four-column `Grid`, one `Chart Line`
and one `Table` (with badges and a per-row action button) each inside a `Card`
with a `card-title`, one `Toast` overlay shown after the page CTA fires, and a
`ThemeSelect` switcher in the navbar that offers all 35 themes as a dropdown.

Section titles are `Leaf.Heading` leaves inside `Prose`: one `H1` for the page
and an `H2` per following section, which is the page's document outline.

Built only from `Daisy.Tree` / `Daisy.Chart` / `Daisy.Schema.*` constructors —
this module imports no `Html`, so every class on the page comes from
`Daisy.Render`.

The page is parameterised by the caller's `msg` type rather than importing
`Main`, which would be a cycle. [`Config`](#Config) carries the slice of the
router's model this page reads plus the constructors it fires.

@docs Config, page

-}

import BasePath
import Daisy.Chart as DChart
import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Card as SCard
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Table as STable
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , CardChild(..)
        , HeadingLevel(..)
        , Leaf(..)
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
    , onNavigate : String -> msg
    , onTheme : Theme -> msg
    , onExport : msg
    , onRowAction : String -> msg
    }


{-| The whole admin dashboard as one `Page`.
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
                chartSection
                (ordersSection config)
        , cta = Tree.cta "Export report" config.onExport
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


sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = { defaultMenu | size = Just SMenu.Lg }
    , items =
        [ navItem "Overview" (href config "/") (config.onNavigate "/") True
        , navItem "Analytics" (href config "/analytics") (config.onNavigate "/analytics") False
        , navItem "Settings" (href config "/settings") (config.onNavigate "/settings") False
        , docsItem config
        ]
    }


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
        , icon = Nothing
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
    , end = [ themeSwitcher config ]
    }


{-| Every theme `Daisy.Tree.allThemes` knows, as one control.

`ThemeAsDropdown` is the only presentation that stays one control wide: the
others render a sibling `input.theme-controller` per theme, which is 35
controls in `navbar-end`. The dropdown opens on `:focus-within`, so tabbing to
its `role="button"` trigger reveals the radio list and the next `Tab` lands on
the checked theme; clicking or activating a radio fires `onSelect`, which the
router turns into `ThemeChanged` and writes back to `Page.theme`.

-}
themeSwitcher : Config msg -> Leaf msg
themeSwitcher config =
    ThemeSelect
        { themes = Tree.allThemes
        , current = config.theme
        , presentation = ThemeAsDropdown
        , onSelect = Just config.onTheme
        }



-- SECTIONS ------------------------------------------------------------------


headerSection : Section msg
headerSection =
    Stack Tree.defaultStackConfig
        [ Prose
            [ Heading H1 "Revenue overview"
            , Text "Revenue, orders and account health across every channel, refreshed hourly."
            ]
        ]


statsSection : Section msg
statsSection =
    Grid { columns = Tree.Cols4 }
        [ statBlock "Revenue (MTD)" "$248,930" "18.2% vs last month"
        , statBlock "Orders" "3,412" "402 awaiting fulfilment"
        , statBlock "Active users" "12,847" "1,204 new this week"
        , statBlock "Refund rate" "1.8%" "0.4 points below target"
        ]


statBlock : String -> String -> String -> Block msg
statBlock title value desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    Stat Tree.defaultStatConfig [ { base | desc = Just desc } ]


{-| `AlignStretch`, so the card fills the band. The other three `Align` values
shrink every block to its content width, which is what used to force a
one-column `Grid` here.
-}
chartSection : Section msg
chartSection =
    Stack { align = AlignStretch }
        [ Prose [ Heading H2 "Revenue trend" ]
        , Card borderedCard
            { emptyCard
                | title = Just "Net revenue vs. operating cost"
                , body =
                    [ CardLeaf (Text "Last twelve months, thousands USD.")
                    , CardChart DChart.Line revenueSeries
                    ]
            }
        ]


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


revenueSeries : DChart.ChartData
revenueSeries =
    { xLabels =
        [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]
    , series =
        [ { name = "Net revenue"
          , color = DChart.Primary
          , points = [ 142, 151, 149, 168, 181, 176, 193, 205, 214, 226, 239, 249 ]
          }
        , { name = "Operating cost"
          , color = DChart.Secondary
          , points = [ 98, 101, 104, 109, 112, 115, 118, 121, 124, 128, 131, 134 ]
          }
        ]
    }


{-| An `AlignStretch` stack: the table's card fills the band, and the debug
pane sits under it. The shell is `Dashboard`, so the page CTA lives in the
navbar and stretching the last section cannot reach it.
-}
ordersSection : Config msg -> Section msg
ordersSection config =
    Stack { align = AlignStretch }
        [ Prose [ Heading H2 "Orders" ]
        , Card borderedCard
            { emptyCard
                | title = Just "Most recent orders"
                , body =
                    [ CardTable
                        { size = Nothing, modifiers = [ STable.Zebra ] }
                        (headerRow :: List.map (orderRow config) orders)
                    ]
            }
        , debugPane config
        ]


{-| The debug pane the Tier C "interaction" spec reads. Always present, always
exactly `last-msg: <constructor name of the last Msg the router handled>`.
-}
debugPane : Config msg -> Block msg
debugPane config =
    Prose [ Text ("last-msg: " ++ config.lastMsg) ]


headerRow : Row msg
headerRow =
    { header = True
    , cells =
        [ Text "Order"
        , Text "Customer"
        , Text "State"
        , Text "Total"
        , Text "Action"
        ]
    }


type alias Order =
    { reference : String
    , customer : String
    , state : String
    , tone : SBadge.Color
    , total : String
    }


orders : List Order
orders =
    [ Order "AC-10432" "Nadia Kowalski" "Paid" SBadge.Success "$1,240.00"
    , Order "AC-10431" "Bright Harbour Ltd" "Pending" SBadge.Warning "$18,905.00"
    , Order "AC-10429" "Tomás Ferreira" "Paid" SBadge.Success "$312.50"
    , Order "AC-10427" "Halcyon Studio" "Refunded" SBadge.Error "$2,180.00"
    , Order "AC-10425" "Meridian Foods" "Paid" SBadge.Success "$7,640.00"
    ]


orderRow : Config msg -> Order -> Row msg
orderRow config order =
    { header = False
    , cells =
        [ Text order.reference
        , Text order.customer
        , Badge
            { color = Just order.tone
            , style = Nothing
            , size = Nothing
            , tooltip = Nothing
            }
            order.state
        , Text order.total
        , Button
            { defaultButton
                | style = Just SButton.Ghost
                , size = Just SButton.Xs
                , onClick = Just (config.onRowAction order.reference)
            }
            "View"
        ]
    }


defaultButton : Tree.ButtonConfig msg
defaultButton =
    Tree.defaultButtonConfig



-- OVERLAY -------------------------------------------------------------------


toastOverlay : Overlay msg
toastOverlay =
    Toast Tree.defaultToastConfig
        [ Alert
            { color = Just SAlert.Success, style = Nothing, direction = Nothing }
            [ Text "Report queued — we will email the CSV when it is ready." ]
        ]
