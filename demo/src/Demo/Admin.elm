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
import Daisy.Icon as Icon
import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Card as SCard
import Daisy.Schema.Input as SInput
import Daisy.Schema.Mask as SMask
import Daisy.Schema.Menu as SMenu
import Daisy.Schema.Table as STable
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , CardChild(..)
        , HeadingLevel(..)
        , IndicatorPayload(..)
        , InputType(..)
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
    , search : String
    , onNavigate : String -> msg
    , onTheme : Theme -> msg
    , onSearch : String -> msg
    , onNotifications : msg
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


sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = { defaultMenu | size = Just SMenu.Lg }
    , items =
        [ navItem "Overview" Icon.Home (href config "/") (config.onNavigate "/") True
        , navItem "Analytics" Icon.ChartBar (href config "/analytics") (config.onNavigate "/analytics") False
        , navItem "Settings" Icon.Cog (href config "/settings") (config.onNavigate "/settings") False
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


{-| The dashboard chrome: brand and search on the left, notifications, the
signed-in user and the theme switcher on the right. `Daisy.Render` appends
`Page.cta` after `navbar-end`, so "Export report" is the last control in the
row.

Nothing goes in `navbar-center`: daisyUI fixes `navbar-start` and `navbar-end`
at 50% each, so a centre section has no width of its own to shrink into and its
contents would overlap the two halves at 375.

-}
navbar : Config msg -> NavbarParts msg
navbar config =
    { start = [ Text "Acme Console", searchInput config ]
    , center = []
    , end = [ notificationsButton config, userChip, themeSwitcher config ]
    }


{-| A real `type="search"` control, named by `ariaLabel` because a navbar has no
`Field` to label it (the same reason `Demo.Analytics`' date-range `Select` has
one).
-}
searchInput : Config msg -> Leaf msg
searchInput config =
    Input
        { defaultInput
            | size = Just SInput.Sm
            , inputType = InputSearch
            , placeholder = "Search orders"
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


{-| The signed-in user, as daisyUI's own dashboard navbars draw them.

The image is an inline `data:` URI rather than a file or a remote photo:
`e2e/themes.spec.ts` compares 105 full-page screenshots byte for byte, so the
avatar has to be there on the first paint, in every environment, with no
network and no font metrics involved.

-}
userChip : Leaf msg
userChip =
    Avatar
        { defaultAvatar | mask = Just { defaultMask | style = Just SMask.Circle } }
        (avatarSrc "slateblue")


defaultAvatar : Tree.AvatarConfig msg
defaultAvatar =
    Tree.defaultAvatarConfig


defaultMask : Tree.MaskConfig
defaultMask =
    Tree.defaultMaskConfig


{-| A flat vector portrait, one colour per person. No text, so it renders
identically wherever the suite runs.
-}
avatarSrc : String -> String
avatarSrc fill =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2040%2040'%3E"
        ++ "%3Crect%20width='40'%20height='40'%20fill='"
        ++ fill
        ++ "'/%3E%3Ccircle%20cx='20'%20cy='16'%20r='7'%20fill='white'/%3E"
        ++ "%3Cpath%20d='M7%2040c0-7.2%205.8-12%2013-12s13%204.8%2013%2012z'%20fill='white'/%3E%3C/svg%3E"


{-| The page CTA, with a leading `Download` glyph.
-}
exportCta : Config msg -> Tree.Cta msg
exportCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Export report" config.onExport
    in
    { base | icon = Just Icon.Download }


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


{-| The tile row. Each tile carries a `stat-figure` icon, which is what turns
four numbers into the header band daisyUI's dashboard templates open with.

One `Stat` block per tile inside a `Grid`, not one block of four tiles:
daisyUI's `.stats` is `grid-flow-col overflow-x-auto`, so a single block would
scroll sideways at 375 rather than wrap.

-}
statsSection : Section msg
statsSection =
    Grid { columns = Tree.Cols4 }
        [ statBlock Icon.CurrencyDollar "Revenue (MTD)" "$248,930" "18.2% vs last month"
        , statBlock Icon.ShoppingCart "Orders" "3,412" "402 awaiting fulfilment"
        , statBlock Icon.Users "Active users" "12,847" "1,204 new this week"
        , statBlock Icon.ArrowTrendingDown "Refund rate" "1.8%" "0.4 points below target"
        ]


statBlock : Icon.Icon -> String -> String -> String -> Block msg
statBlock icon title value desc =
    let
        base : StatItem msg
        base =
            Tree.emptyStatItem title value
    in
    Stat Tree.defaultStatConfig
        [ { base | desc = Just desc, figure = Just (figureIcon icon) } ]


{-| A `stat-figure` glyph: the largest of the three icon sizes, and decorative
— the tile's own `stat-title` is what names the number.
-}
figureIcon : Icon.Icon -> Leaf msg
figureIcon icon =
    Icon { defaultIcon | size = Tree.IconLg } icon


defaultIcon : Tree.IconConfig
defaultIcon =
    Tree.defaultIconConfig


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


{-| `card-border`. `Daisy.Render` now paints every card `bg-base-100 shadow-sm`
on the `bg-base-200` content ground, so the card already reads as a raised
panel; the border is what daisyUI's own dashboard examples add on top of that.
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
        List.map Tree.tableCell
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
    , avatar : String
    , state : String
    , tone : SBadge.Color
    , total : String
    }


orders : List Order
orders =
    [ Order "AC-10432" "Nadia Kowalski" "slateblue" "Paid" SBadge.Success "$1,240.00"
    , Order "AC-10431" "Bright Harbour Ltd" "teal" "Pending" SBadge.Warning "$18,905.00"
    , Order "AC-10429" "Tomás Ferreira" "sienna" "Paid" SBadge.Success "$312.50"
    , Order "AC-10427" "Halcyon Studio" "darkslategray" "Refunded" SBadge.Error "$2,180.00"
    , Order "AC-10425" "Meridian Foods" "seagreen" "Paid" SBadge.Success "$7,640.00"
    ]


{-| The customer cell is a `TableCell` with a `leading` avatar, which is the
avatar-and-name idiom daisyUI's "table with visual elements" example uses. The
row action is an icon-only `Eye` button named by `ariaLabel`.
-}
orderRow : Config msg -> Order -> Row msg
orderRow config order =
    { header = False
    , cells =
        [ Tree.tableCell (Text order.reference)
        , { leading =
                Just
                    (Avatar
                        { defaultAvatar | mask = Just { defaultMask | style = Just SMask.Circle } }
                        (avatarSrc order.avatar)
                    )
          , content = Text order.customer
          }
        , Tree.tableCell
            (Badge
                { color = Just order.tone
                , style = Nothing
                , size = Nothing
                , tooltip = Nothing
                }
                order.state
            )
        , Tree.tableCell (Text order.total)
        , Tree.tableCell
            (Button
                { defaultButton
                    | icon = Just Icon.Eye
                    , ariaLabel = Just ("View order " ++ order.reference)
                    , style = Just SButton.Ghost
                    , size = Just SButton.Xs
                    , modifiers = [ SButton.Square ]
                    , onClick = Just (config.onRowAction order.reference)
                }
                ""
            )
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
