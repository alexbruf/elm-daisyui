module Corpus.Trees exposing (Msg(..), Node(..), render, treeFor)

{-| One hand-written `Daisy.Tree` value per accepted docs example.

`CorpusTest` renders the node for an id and compares the daisyUI classes per
element with the fixture. An example that the closed tree cannot express is not
listed here; it goes in `fixtures/rejected.md` with a reason instead.

Adding an example is meant to be one line: pick the renderer level with
[`leaf`](#leaf) / `block` / `section` / `overlay`, and use the small helpers
below for the values the docs repeat (an image source, a menu, a card).

@docs Msg, Node, render, treeFor

-}

import Daisy.Render as Render
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
import Daisy.Schema.Progress as SProgress
import Daisy.Schema.Radio as SRadio
import Daisy.Schema.Range as SRange
import Daisy.Schema.Rating as SRating
import Daisy.Schema.Select as SSelect
import Daisy.Schema.Skeleton as SSkeleton
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
import Daisy.Tree exposing (..)
import Date
import Dict exposing (Dict)
import Html exposing (Html)
import Time


{-| Corpus trees carry no behaviour; handlers exist only where a constructor
demands one.
-}
type Msg
    = Clicked


{-| A tree value at whichever level the example belongs to.
-}
type Node
    = SectionNode (Section Msg)
    | BlockNode (Block Msg)
    | LeafNode (Leaf Msg)
    | OverlayNode (Overlay Msg)
    | PageNode (Page Msg)


{-| Render a node through the matching `Daisy.Render` entry point.
-}
render : Node -> Html Msg
render node =
    case node of
        SectionNode value ->
            Render.section value

        BlockNode value ->
            Render.block value

        LeafNode value ->
            Render.leaf value

        OverlayNode value ->
            Render.overlay value

        PageNode value ->
            Render.page value


{-| The tree for one fixture id, if one has been written.
-}
treeFor : String -> Maybe Node
treeFor id =
    Dict.get id trees


trees : Dict String Node
trees =
    Dict.fromList entries



-- HELPERS -------------------------------------------------------------------


leaf : Leaf Msg -> Node
leaf =
    LeafNode


block : Block Msg -> Node
block =
    BlockNode


section : Section Msg -> Node
section =
    SectionNode


overlay : Overlay Msg -> Node
overlay =
    OverlayNode


{-| The image the docs examples use.
-}
img : ImageSrc
img =
    "https://img.daisyui.com/images/profile/demo/1@94.webp"


{-| A `card-body` of plain leaves.
-}
cardBody : List (Leaf Msg) -> List (CardChild Msg)
cardBody =
    List.map CardLeaf


{-| Several leaves at once: a `Prose` block adds no daisyUI class of its own,
so the comparison sees exactly the leaves.
-}
leaves : List (Leaf Msg) -> Node
leaves list =
    block (Prose list)


{-| Several blocks at once, in a plain `Stack` band.
-}
blocks : List (Block Msg) -> Node
blocks list =
    section (Stack defaultStackConfig list)


{-| An example that needs `btn-primary`: the tree allows exactly one, as
`Page.cta`, so the example becomes a whole page.
-}
pageOf : Cta Msg -> List (Leaf Msg) -> Node
pageOf primary list =
    pageBlocks primary [ Prose list ]


{-| A page whose one section holds the given blocks, plus the primary CTA.
-}
pageBlocks : Cta Msg -> List (Block Msg) -> Node
pageBlocks primary list =
    PageNode
        (Page
            { header = Nothing
            , shell = Plain
            , sections = Sections1 (Stack defaultStackConfig list)
            , cta = primary
            , overlays = []
            , theme = Light
            , dock = Nothing
            , fab = Nothing
            }
        )


{-| One `fieldset` with a legend and some fields.
-}
fieldsetOf : String -> List (Field Msg) -> Block Msg
fieldsetOf legend fields =
    Form [ { legend = Just legend, columns = OneColumn, fields = fields } ]


{-| A labelled control with a `validator` class and a `validator-hint`.
-}
validated : String -> Leaf Msg -> String -> Field Msg
validated label control hint =
    { label = Just label
    , labelPlacement = LabelStart
    , control = control
    , validate = True
    , hint = Just hint
    }


btn : ButtonConfig Msg
btn =
    defaultButtonConfig


bdg : BadgeConfig
bdg =
    defaultBadgeConfig


inp : InputConfig Msg
inp =
    defaultInputConfig


sel : SelectConfig Msg
sel =
    defaultSelectConfig


selData : SelectData
selData =
    { options = [ "Pick a color", "Crimson", "Amber" ], selected = Nothing }


chk : CheckboxConfig Msg
chk =
    defaultCheckboxConfig


rad : RadioConfig Msg
rad =
    defaultRadioConfig


radData : RadioData
radData =
    { name = "corpus-radio", checked = False }


tgl : ToggleConfig Msg
tgl =
    defaultToggleConfig


txa : TextareaConfig Msg
txa =
    defaultTextareaConfig


lnk : LinkConfig Msg
lnk =
    defaultLinkConfig


crd : CardConfig
crd =
    defaultCardConfig


{-| The card the docs repeat: figure, title, body and one action.
-}
cardParts : CardParts Msg
cardParts =
    { figure = Just (Image defaultImageConfig img)
    , title = Just "Card Title"
    , titleIcon = Nothing
    , description = Nothing
    , headerTabs = Nothing
    , headerActions = []
    , body = cardBody [ Text "A card component has a figure, a body part, and inside body there are title and actions parts" ]
    , actions = []
    }


buyNow : Cta Msg
buyNow =
    cta "Buy Now" Clicked



-- ENTRIES -------------------------------------------------------------------


entries : List ( String, Node )
entries =
    alertEntries
        ++ badgeEntries
        ++ buttonEntries
        ++ cardEntries
        ++ formEntries
        ++ statEntries
        ++ tableEntries
        ++ accordionEntries
        ++ dropdownEntries
        ++ footerEntries
        ++ heroEntries
        ++ menuEntries
        ++ modalEntries
        ++ navbarEntries
        ++ tabEntries
        ++ toastEntries
        ++ avatarEntries
        ++ auraEntries
        ++ carouselEntries
        ++ chatEntries
        ++ dividerEntries
        ++ dockEntries
        ++ fabEntries
        ++ fieldsetEntries
        ++ joinEntries
        ++ maskEntries
        ++ megamenuEntries
        ++ mockupEntries
        ++ leafEntries
        ++ ratingEntries
        ++ stepsEntries
        ++ swapEntries
        ++ themeEntries
        ++ timelineEntries
        ++ tooltipEntries
        ++ validatorEntries
        ++ indicatorEntries
        ++ calendarEntries


{-| daisyUI's Cally examples. `Leaf.Calendar` renders `alexbruf/elm-cally`,
which produces the same `<calendar-date>` / `<calendar-month>` markup and the
same `part` attributes as the web component the docs load from a CDN, so the
`cally` class lands on a real picker rather than on foreign markup.

`calendar--01` is not here: it puts the picker inside a `dropdown` popover, and
`Dropdown.menu` is a closed `MenuSpec`. See `fixtures/rejected.md`.

-}
calendarEntries : List ( String, Node )
calendarEntries =
    let
        today : Date.Date
        today =
            Date.fromCalendarDate 2026 Time.Sep 7

        config : CalendarConfig Msg
        config =
            defaultCalendarConfig
                { id = "corpus-calendar"
                , today = today
                , toMsg = always Clicked
                , onChange = always Clicked
                }
    in
    [ ( "calendar--00", leaf (Calendar config (Render.initCalendarDate config Nothing)) ) ]


alertEntries : List ( String, Node )
alertEntries =
    let
        alert color style =
            Alert { defaultAlertConfig | color = color, style = style } [ Text "12 unread messages. Tap to see." ]

        colors =
            [ SAlert.Info, SAlert.Success, SAlert.Warning, SAlert.Error ]

        sweep style =
            blocks (List.map (\color -> alert (Just color) (Just style)) colors)
    in
    [ ( "alert--00", block (alert Nothing Nothing) )
    , ( "alert--01", block (alert (Just SAlert.Info) Nothing) )
    , ( "alert--02", block (alert (Just SAlert.Success) Nothing) )
    , ( "alert--03", block (alert (Just SAlert.Warning) Nothing) )
    , ( "alert--04", block (alert (Just SAlert.Error) Nothing) )
    , ( "alert--05", sweep SAlert.Soft )
    , ( "alert--06", sweep SAlert.Outline )
    , ( "alert--07", sweep SAlert.Dash )
    , ( "alert--08"
      , pageBlocks
            { buyNow | label = "Accept", size = Just SButton.Sm }
            [ Alert { defaultAlertConfig | direction = Just SAlert.Vertical }
                [ Text "we use cookies for no reason."
                , Button { btn | size = Just SButton.Sm } "Deny"
                ]
            ]
      )
    , ( "alert--09"
      , block
            (Alert { defaultAlertConfig | direction = Just SAlert.Vertical }
                [ Text "New message!"
                , Button { btn | size = Just SButton.Sm } "See"
                ]
            )
      )
    ]


badgeEntries : List ( String, Node )
badgeEntries =
    let
        sizes style color =
            leaves
                (List.map
                    (\size -> Badge { bdg | size = Just size, style = style, color = color } "Badge")
                    SBadge.allSizes
                )

        colors style =
            leaves
                (List.map
                    (\color -> Badge { bdg | color = Just color, style = style } "Badge")
                    SBadge.allColors
                )
    in
    [ ( "badge--00", leaf (Badge bdg "Badge") )
    , ( "badge--01", sizes Nothing Nothing )
    , ( "badge--02", colors Nothing )
    , ( "badge--03", colors (Just SBadge.Soft) )
    , ( "badge--04", colors (Just SBadge.Outline) )
    , ( "badge--05", colors (Just SBadge.Dash) )
    , ( "badge--06"
      , leaves
            [ Badge { bdg | color = Just SBadge.Neutral, style = Just SBadge.Outline } "Outline"
            , Badge { bdg | color = Just SBadge.Neutral, style = Just SBadge.Dash } "Dash"
            ]
      )
    , ( "badge--07", leaf (Badge { bdg | style = Just SBadge.Ghost } "ghost") )
    , ( "badge--08", sizes Nothing (Just SBadge.Primary) )
    , ( "badge--09", colors Nothing )
    , ( "badge--10", sizes Nothing Nothing )
    , ( "badge--11"
      , leaves
            [ Button btn "Inbox"
            , Badge { bdg | size = Just SBadge.Sm } "+99"
            , Badge { bdg | size = Just SBadge.Sm, color = Just SBadge.Secondary } "+99"
            ]
      )
    ]


buttonEntries : List ( String, Node )
buttonEntries =
    let
        colored style behaviors =
            pageOf
                { buyNow
                    | label = "Primary"
                    , style = style
                    , behaviors = behaviors
                }
                (List.map
                    (\color -> Button { btn | color = Just color, style = style, behaviors = behaviors } "Button")
                    allButtonColors
                    ++ [ Button { btn | style = style, behaviors = behaviors } "Default" ]
                )
    in
    [ ( "button--00", leaf (Button btn "Default") )
    , ( "button--01"
      , leaves
            (Button btn "Medium"
                :: List.map (\size -> Button { btn | size = Just size } "Button") SButton.allSizes
            )
      )
    , ( "button--02", leaf (Button { btn | size = Just SButton.Xs } "Responsive") )
    , ( "button--03", colored Nothing [] )
    , ( "button--04", colored (Just SButton.Soft) [] )
    , ( "button--05", colored (Just SButton.Outline) [] )
    , ( "button--06", colored (Just SButton.Dash) [] )
    , ( "button--07"
      , leaves
            [ Button { btn | color = Just Neutral, style = Just SButton.Outline } "Outline"
            , Button { btn | color = Just Neutral, style = Just SButton.Dash } "Dash"
            ]
      )
    , ( "button--08", colored Nothing [ SButton.Active ] )
    , ( "button--09"
      , leaves
            [ Button { btn | style = Just SButton.Ghost } "Ghost"
            , Button { btn | style = Just SButton.Link } "Link"
            ]
      )
    , ( "button--10", leaf (Button { btn | modifiers = [ SButton.Wide ] } "Wide") )
    , ( "button--11", leaves [ Button btn "Button", Link { lnk | style = Nothing } "Link" ] )
    , ( "button--12"
      , leaves
            [ Button btn "Disabled using attribute"
            , Button { btn | behaviors = [ SButton.Disabled ] } "Disabled using class name"
            ]
      )
    , ( "button--13"
      , leaves
            [ Button { btn | modifiers = [ SButton.Square ] } ""
            , Button { btn | modifiers = [ SButton.Circle ] } ""
            ]
      )
    , ( "button--14", leaves [ Button btn "Like" ] )
    , ( "button--15", leaf (Button { btn | modifiers = [ SButton.Block ] } "block") )
    , ( "button--16"
      , leaves
            [ Button { btn | modifiers = [ SButton.Square ] } ""
            , Loading { defaultLoadingConfig | style = Just SLoading.Spinner }
            , Button btn "loading"
            ]
      )
    , ( "button--17", leaves [ Button btn "Login with Email" ] )
    ]


cardEntries : List ( String, Node )
cardEntries =
    let
        withBuy config =
            pageBlocks buyNow [ Card config cardParts ]
    in
    [ ( "card--00", withBuy crd )
    , ( "card--01"
      , pageBlocks
            { buyNow | label = "Subscribe", modifiers = [ SButton.Block ] }
            [ Card crd
                { emptyCardParts
                    | title = Just "Premium"
                    , body =
                        cardBody
                            [ Badge { bdg | color = Just SBadge.Warning, size = Just SBadge.Xs } "MOST POPULAR"
                            , Text "$29 / month"
                            ]
                }
            ]
      )
    , ( "card--02"
      , pageBlocks buyNow
            (Card crd cardParts
                :: List.map (\size -> Card { crd | size = Just size } cardParts) SCard.allSizes
            )
      )
    , ( "card--03", withBuy { crd | style = Just SCard.Border } )
    , ( "card--04", withBuy { crd | style = Just SCard.Dash } )
    , ( "card--05"
      , blocks
            [ Card crd
                { cardParts
                    | body = cardBody [ Badge { bdg | color = Just SBadge.Secondary } "NEW" ]
                    , actions = [ Badge { bdg | style = Just SBadge.Outline } "Fashion" ]
                }
            ]
      )
    , ( "card--06", block (Card crd { cardParts | actions = [] }) )
    , ( "card--07", withBuy crd )
    , ( "card--08", withBuy { crd | modifiers = [ SCard.ImageFull ] } )
    , ( "card--09", withBuy crd )
    , ( "card--10", block (Card crd { cardParts | actions = [ Button btn "Buy Now" ] }) )
    , ( "card--11"
      , pageBlocks buyNow
            [ Card crd { cardParts | actions = [ Button { btn | style = Just SButton.Ghost } "Deny" ] } ]
      )
    , ( "card--12"
      , block
            (Card crd
                { emptyCardParts
                    | body = cardBody [ Text "We are using cookies for no reason." ]
                    , actions = [ Button { btn | size = Just SButton.Sm, modifiers = [ SButton.Square ] } "x" ]
                }
            )
      )
    , ( "card--13", withBuy { crd | modifiers = [ SCard.Side ] } )
    , ( "card--14", withBuy crd )
    ]


formEntries : List ( String, Node )
formEntries =
    [ ( "checkbox--00", leaf (Checkbox chk) )
    , ( "checkbox--01", block (fieldsetOf "Login" [ field "Remember me" (Checkbox chk) ]) )
    , ( "checkbox--02"
      , leaves (List.map (\size -> Checkbox { chk | size = Just size }) SCheckbox.allSizes)
      )
    , ( "checkbox--03"
      , leaves (List.map (\color -> Checkbox { chk | color = Just color }) SCheckbox.allColors)
      )
    , ( "checkbox--04", leaf (Checkbox chk) )
    , ( "checkbox--05", leaf (Checkbox chk) )
    , ( "checkbox--06", leaf (Checkbox chk) )
    , ( "input--00", leaf (Input inp) )
    , ( "input--01"
      , leaves
            [ Input inp
            , Kbd { defaultKbdConfig | size = Just SKbd.Sm } "K"
            , Badge { bdg | color = Just SBadge.Neutral, size = Just SBadge.Xs } "optional"
            ]
      )
    , ( "input--02", leaf (Input { inp | style = Just SInput.Ghost }) )
    , ( "input--03", block (fieldsetOf "Page title" [ field "What is your name?" (Input inp) ]) )
    , ( "input--04", block (fieldsetOf "What is your name?" [ field "Name" (Input inp) ]) )
    , ( "input--05", leaves (List.map (\color -> Input { inp | color = Just color }) SInput.allColors) )
    , ( "input--06", leaves (List.map (\size -> Input { inp | size = Just size }) SInput.allSizes) )
    , ( "input--07", leaf (Input inp) )
    , ( "input--08", leaf (Input inp) )
    , ( "input--09", leaf (Input inp) )
    , ( "input--10", leaf (Input inp) )
    , ( "input--11", leaf (Input inp) )
    , ( "input--12", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "Username" (Input inp) "Must be 3 to 30 characters" ] } ]) )
    , ( "input--13", leaf (Input inp) )
    , ( "input--14", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "Email" (Input inp) "Enter valid email address" ] } ]) )
    , ( "input--16", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "Password" (Input inp) "Must be more than 8 characters" ] } ]) )
    , ( "input--17", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "Number" (Input inp) "Must be between be 1 to 10" ] } ]) )
    , ( "input--18", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "Phone" (Input inp) "Must be 10 digits" ] } ]) )
    , ( "input--19", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "URL" (Input inp) "Must be valid URL" ] } ]) )
    , ( "link--00", leaf (Link lnk "Click me") )
    , ( "link--01", leaf (Link lnk "Click me") )
    , ( "link--02", leaf (Link { lnk | color = Just SLink.Primary } "Click me") )
    , ( "link--03", leaf (Link { lnk | color = Just SLink.Secondary } "Click me") )
    , ( "link--04", leaf (Link { lnk | color = Just SLink.Accent } "Click me") )
    , ( "link--05", leaf (Link { lnk | color = Just SLink.Success } "Click me") )
    , ( "link--06", leaf (Link { lnk | color = Just SLink.Info } "Click me") )
    , ( "link--07", leaf (Link { lnk | color = Just SLink.Warning } "Click me") )
    , ( "link--08", leaf (Link { lnk | color = Just SLink.Error } "Click me") )
    , ( "link--09", leaf (Link { lnk | style = Just SLink.Hover } "Click me") )
    , ( "radio--00", leaf (Radio rad radData) )
    , ( "radio--01", leaves (List.map (\size -> Radio { rad | size = Just size } radData) SRadio.allSizes) )
    , ( "radio--02", leaf (Radio { rad | color = Just SRadio.Neutral } radData) )
    , ( "radio--03", leaf (Radio { rad | color = Just SRadio.Primary } radData) )
    , ( "radio--04", leaf (Radio { rad | color = Just SRadio.Secondary } radData) )
    , ( "radio--05", leaf (Radio { rad | color = Just SRadio.Accent } radData) )
    , ( "radio--06", leaf (Radio { rad | color = Just SRadio.Success } radData) )
    , ( "radio--07", leaf (Radio { rad | color = Just SRadio.Warning } radData) )
    , ( "radio--08", leaf (Radio { rad | color = Just SRadio.Info } radData) )
    , ( "radio--09", leaf (Radio { rad | color = Just SRadio.Error } radData) )
    , ( "radio--10", leaf (Radio rad radData) )
    , ( "radio--11", leaf (Radio rad radData) )
    , ( "select--00", leaf (Select sel selData) )
    , ( "select--01", leaf (Select { sel | style = Just SSelect.Ghost } selData) )
    , ( "select--02", block (fieldsetOf "Page title" [ field "Browser" (Select sel selData) ]) )
    , ( "select--03", leaf (Select { sel | color = Just SSelect.Primary } selData) )
    , ( "select--04", leaf (Select { sel | color = Just SSelect.Secondary } selData) )
    , ( "select--05", leaf (Select { sel | color = Just SSelect.Accent } selData) )
    , ( "select--06", leaf (Select { sel | color = Just SSelect.Neutral } selData) )
    , ( "select--07", leaf (Select { sel | color = Just SSelect.Info } selData) )
    , ( "select--08", leaf (Select { sel | color = Just SSelect.Success } selData) )
    , ( "select--09", leaf (Select { sel | color = Just SSelect.Warning } selData) )
    , ( "select--10", leaf (Select { sel | color = Just SSelect.Error } selData) )
    , ( "select--11", leaves (List.map (\size -> Select { sel | size = Just size } selData) SSelect.allSizes) )
    , ( "select--12", leaf (Select sel selData) )
    , ( "select--13", leaf (Select sel selData) )
    , ( "select--14", leaf (Select sel selData) )
    , ( "textarea--00", leaf (Textarea txa) )
    , ( "textarea--01", leaf (Textarea { txa | style = Just STextarea.Ghost }) )
    , ( "textarea--02", block (fieldsetOf "Your bio" [ field "Bio" (Textarea txa) ]) )
    , ( "textarea--03", leaves (List.map (\color -> Textarea { txa | color = Just color }) STextarea.allColors) )
    , ( "textarea--04", leaves (List.map (\size -> Textarea { txa | size = Just size }) STextarea.allSizes) )
    , ( "textarea--05", leaf (Textarea txa) )
    , ( "toggle--00", leaf (Toggle tgl { checked = False }) )
    , ( "toggle--01", block (fieldsetOf "Login" [ field "Remember me" (Toggle tgl { checked = False }) ]) )
    , ( "toggle--02", leaves (List.map (\size -> Toggle { tgl | size = Just size } { checked = False }) SToggle.allSizes) )
    , ( "toggle--03", leaves (List.map (\color -> Toggle { tgl | color = Just color } { checked = True }) SToggle.allColors) )
    , ( "toggle--04", leaf (Toggle tgl { checked = False }) )
    , ( "toggle--05", leaf (Toggle tgl { checked = False }) )
    , ( "toggle--06", leaf (Toggle tgl { checked = False }) )
    , ( "toggle--07", leaf (Toggle tgl { checked = False }) )
    ]


statEntries : List ( String, Node )
statEntries =
    let
        item =
            { figure = Nothing
            , title = "Total Page Views"
            , value = "89,400"
            , trend = Nothing
            , desc = Just "21% more than last month"
            , actions = []
            }

        stats direction figure =
            block (Stat { direction = Fixed direction } [ { item | figure = figure } ])
    in
    [ ( "stat--00", stats Nothing Nothing )
    , ( "stat--01"
      , stats Nothing (Just (Avatar { defaultAvatarConfig | modifiers = [ SAvatar.Online ] } img))
      )
    , ( "stat--02", stats Nothing (Just (Loading defaultLoadingConfig)) )
    , ( "stat--03", stats Nothing Nothing )
    , ( "stat--04", stats (Just SStat.Vertical) Nothing )
    , ( "stat--05", stats (Just SStat.Vertical) Nothing )
    , ( "stat--06"
      , block
            (Stat defaultStatConfig
                [ { item
                    | desc = Nothing
                    , actions =
                        [ Button { btn | size = Just SButton.Xs, color = Just Success } "Add funds"
                        , Button { btn | size = Just SButton.Xs } "Withdrawal"
                        ]
                  }
                ]
            )
      )
    ]


tableEntries : List ( String, Node )
tableEntries =
    let
        rows =
            [ { header = True
              , cells = List.map tableCell [ Text "Name", Text "Job", Text "Favorite Color" ]
              }
            , { header = False
              , cells =
                    List.map tableCell
                        [ Text "Cy Ganderton", Text "Quality Control Specialist", Text "Blue" ]
              }
            ]

        table config =
            block (Table config rows)
    in
    [ ( "table--00", table defaultTableConfig )
    , ( "table--01", table defaultTableConfig )
    , ( "table--02", table defaultTableConfig )
    , ( "table--03", table defaultTableConfig )
    , ( "table--04", table { defaultTableConfig | modifiers = [ STable.Zebra ] } )
    , ( "table--05"
      , block
            (Table defaultTableConfig
                [ { header = False
                  , cells =
                        List.map tableCell
                            [ Checkbox chk
                            , Avatar defaultAvatarConfig img
                            , Image { defaultImageConfig | mask = Just { defaultMaskConfig | style = Just SMask.Squircle } } img
                            , Badge { bdg | style = Just SBadge.Ghost, size = Just SBadge.Sm } "Desktop Support Technician"
                            , Button { btn | style = Just SButton.Ghost, size = Just SButton.Xs } "details"
                            ]
                  }
                ]
            )
      )
    , ( "table--06", table { defaultTableConfig | size = Just STable.Xs } )
    , ( "table--07", table { defaultTableConfig | modifiers = [ STable.PinRows ] } )
    , ( "table--08"
      , table
            { size = Just STable.Xs
            , modifiers = [ STable.PinRows, STable.PinCols ]
            }
      )
    ]


accordionEntries : List ( String, Node )
accordionEntries =
    let
        item =
            { title = "How do I create an account?"
            , content = [ Text "Click the \"Sign Up\" button in the top right corner." ]
            }

        accordion modifiers =
            block (Accordion { defaultAccordionConfig | modifiers = modifiers } [ item ])

        collapse modifiers =
            block
                (Collapse { modifiers = modifiers }
                    { title = "How do I create an account?"
                    , content = [ Text "Click the \"Sign Up\" button in the top right corner." ]
                    }
                )

        crumbs =
            block (Breadcrumbs [ Link lnk "Home", Link lnk "Documents", Link lnk "Add Document" ])
    in
    [ ( "accordion--00", accordion [] )
    , ( "accordion--01", accordion [] )
    , ( "accordion--02", accordion [ SAccordion.Arrow ] )
    , ( "accordion--03", accordion [ SAccordion.Plus ] )
    , ( "breadcrumbs--00", crumbs )
    , ( "breadcrumbs--01", crumbs )
    , ( "breadcrumbs--02", crumbs )
    , ( "collapse--00", collapse [] )
    , ( "collapse--01", collapse [] )
    , ( "collapse--02", collapse [] )
    , ( "collapse--03", collapse [] )
    , ( "collapse--04", collapse [] )
    , ( "collapse--05", collapse [ SCollapse.Arrow ] )
    , ( "collapse--06", collapse [ SCollapse.Plus ] )
    , ( "collapse--07", collapse [ SCollapse.Arrow ] )
    , ( "collapse--08", collapse [ SCollapse.Open ] )
    , ( "collapse--09", collapse [ SCollapse.Close ] )
    , ( "collapse--10", collapse [] )
    , ( "collapse--11", collapse [] )
    , ( "drawer--00", drawerNode defaultDrawerConfig )
    , ( "drawer--02", drawerNode defaultDrawerConfig )
    ]


drawerNode : DrawerConfig -> Node
drawerNode config =
    overlay
        (Drawer config
            [ Stack defaultStackConfig
                [ Menu defaultMenuConfig [ menuItem "Sidebar Item 1", menuItem "Sidebar Item 2" ] ]
            ]
        )


dropdownEntries : List ( String, Node )
dropdownEntries =
    let
        dropdownButton placement modifiers =
            leaf
                (Button
                    { btn
                        | dropdown =
                            Just
                                { config = { placement = placement, modifiers = modifiers }
                                , menu = { config = defaultMenuConfig, items = [ menuItem "Item 1", menuItem "Item 2" ] }
                                }
                    }
                    "Click"
                )

        at placement =
            dropdownButton (Just placement) []
    in
    [ ( "dropdown--00", dropdownButton Nothing [] )
    , ( "dropdown--02", dropdownButton Nothing [] )
    , ( "dropdown--03", at SDropdown.Start )
    , ( "dropdown--04", at SDropdown.End )
    , ( "dropdown--05", at SDropdown.Center )
    , ( "dropdown--06", at SDropdown.Top )
    , ( "dropdown--09", at SDropdown.Bottom )
    , ( "dropdown--12", at SDropdown.Left )
    , ( "dropdown--15", at SDropdown.Right )
    , ( "dropdown--18", dropdownButton Nothing [ SDropdown.Hover ] )
    , ( "dropdown--19", dropdownButton Nothing [ SDropdown.Open ] )
    , ( "dropdown--20", dropdownButton Nothing [ SDropdown.Close ] )
    , ( "dropdown--22"
      , section
            (Navbar
                { emptyNavbarParts
                    | end =
                        [ Button
                            { btn
                                | style = Just SButton.Ghost
                                , dropdown =
                                    Just
                                        { config = { placement = Just SDropdown.End, modifiers = [] }
                                        , menu = { config = defaultMenuConfig, items = [ menuItem "Item 1" ] }
                                        }
                            }
                            "Menu"
                        ]
                }
            )
      )
    ]


footerEntries : List ( String, Node )
footerEntries =
    let
        column =
            Nav { title = Just "Services" }
                [ Link { lnk | style = Just SLink.Hover } "Branding"
                , Link { lnk | style = Just SLink.Hover } "Design"
                ]

        footer direction placement columns =
            section (Footer { direction = direction, placement = placement } columns)

        plain =
            footer Nothing Nothing [ column ]
    in
    [ ( "footer--00", plain )
    , ( "footer--01", plain )
    , ( "footer--03", footer Nothing Nothing [ Nav { title = Just "Services" } [] ] )
    , ( "footer--04", footer Nothing (Just SFooter.Center) [ Prose [ Text "Copyright" ] ] )
    , ( "footer--05", footer Nothing Nothing [ Prose [ Text "Copyright" ] ] )
    , ( "footer--06", plain )
    , ( "footer--07", plain )
    , ( "footer--08"
      , footer (Just SFooter.Horizontal) (Just SFooter.Center) [ Prose [ Text "Copyright" ] ]
      )
    , ( "footer--09"
      , footer (Just SFooter.Horizontal)
            (Just SFooter.Center)
            [ Nav defaultNavConfig [ Link { lnk | style = Just SLink.Hover } "About us" ] ]
      )
    , ( "footer--10", plain )
    ]


heroEntries : List ( String, Node )
heroEntries =
    let
        hero overlayFlag content =
            PageNode
                (Page
                    { header = Nothing
                    , shell = Plain
                    , sections = Sections1 (Hero { overlay = overlayFlag } content)
                    , cta = cta "Get Started" Clicked
                    , overlays = []
                    , theme = Light
                    , dock = Nothing
                    , fab = Nothing
                    }
                )

        copy =
            [ Prose [ Text "Hello there", Text "Provident cupiditate voluptatem et in." ] ]
    in
    [ ( "hero--00", hero False copy )
    , ( "hero--01", hero False (Prose [ Image defaultImageConfig img ] :: copy) )
    , ( "hero--02", hero False (Prose [ Image defaultImageConfig img ] :: copy) )
    , ( "hero--03"
      , hero False
            [ Card crd
                { emptyCardParts
                    | body =
                        [ CardForm
                            [ { legend = Nothing
                              , columns = OneColumn
                              , fields =
                                    [ field "Email" (Input inp)
                                    , field "Password" (Input { inp | inputType = InputPassword })
                                    , { label = Nothing
                                      , labelPlacement = LabelStart
                                      , control = Link { lnk | style = Just SLink.Hover } "Forgot password?"
                                      , validate = False
                                      , hint = Nothing
                                      }
                                    , { label = Nothing
                                      , labelPlacement = LabelStart
                                      , control = Button { btn | color = Just Neutral } "Login"
                                      , validate = False
                                      , hint = Nothing
                                      }
                                    ]
                              }
                            ]
                        ]
                }
            ]
      )
    , ( "hero--04", hero True copy )
    ]


menuEntries : List ( String, Node )
menuEntries =
    let
        items =
            [ menuItem "Item 1", menuItem "Item 2", menuItem "Item 3" ]

        menu config =
            block (Menu config items)

        plain =
            menu defaultMenuConfig

        titled =
            block
                (Menu defaultMenuConfig
                    (MenuItem
                        { label = "Title"
                        , href = Nothing
                        , glyph = Nothing
                        , badge = Nothing
                        , active = False
                        , disabled = False
                        , focus = False
                        , title = True
                        , onClick = Nothing
                        , submenu = []
                        }
                        :: items
                    )
                )

        flagged toFlag =
            block
                (Menu defaultMenuConfig
                    [ menuItem "Item 1"
                    , MenuItem
                        (toFlag
                            { label = "Item 2"
                            , href = Nothing
                            , glyph = Nothing
                            , badge = Nothing
                            , active = False
                            , disabled = False
                            , focus = False
                            , title = False
                            , onClick = Nothing
                            , submenu = []
                            }
                        )
                    ]
                )

        submenu =
            block
                (Menu defaultMenuConfig
                    [ MenuItem
                        { label = "Parent"
                        , href = Nothing
                        , glyph = Nothing
                        , badge = Nothing
                        , active = False
                        , disabled = False
                        , focus = False
                        , title = False
                        , onClick = Nothing
                        , submenu = [ menuItem "Submenu 1", menuItem "Submenu 2" ]
                        }
                    ]
                )
    in
    [ ( "menu--00", plain )
    , ( "menu--01", menu { defaultMenuConfig | direction = Just SMenu.Vertical } )
    , ( "menu--02"
      , menu { defaultMenuConfig | direction = Just SMenu.Vertical, modifiers = [ SMenu.Paged ] }
      )
    , ( "menu--03", plain )
    , ( "menu--04", menu { defaultMenuConfig | direction = Just SMenu.Horizontal } )
    , ( "menu--07", blocks (List.map (\size -> Menu { defaultMenuConfig | size = Just size } items) SMenu.allSizes) )
    , ( "menu--08", flagged (\item -> { item | disabled = True }) )
    , ( "menu--09", plain )
    , ( "menu--10"
      , block
            (Menu defaultMenuConfig
                (List.map
                    (\color ->
                        MenuItem
                            { label = "Inbox"
                            , href = Nothing
                            , glyph = Nothing
                            , badge =
                                Just
                                    { config = { bdg | color = color, size = Just SBadge.Xs }
                                    , label = "99+"
                                    }
                            , active = False
                            , disabled = False
                            , focus = False
                            , title = False
                            , onClick = Nothing
                            , submenu = []
                            }
                    )
                    [ Nothing, Just SBadge.Warning, Just SBadge.Info ]
                )
            )
      )
    , ( "menu--11", plain )
    , ( "menu--12", titled )
    , ( "menu--13", titled )
    , ( "menu--14", submenu )
    , ( "menu--15", plain )
    , ( "menu--17", menu { defaultMenuConfig | size = Just SMenu.Xs } )
    , ( "menu--18", flagged (\item -> { item | active = True }) )
    , ( "menu--19", menu { defaultMenuConfig | direction = Just SMenu.Horizontal } )
    , ( "menu--20", menu { defaultMenuConfig | direction = Just SMenu.Horizontal } )
    , ( "menu--21", plain )
    , ( "menu--22", plain )
    ]


modalEntries : List ( String, Node )
modalEntries =
    let
        modal config =
            PageNode
                (Page
                    { header = Nothing
                    , shell = Plain
                    , sections = Sections1 (Stack defaultStackConfig [ Prose [ Button btn "open modal" ] ])
                    , cta = cta "Close" Clicked
                    , overlays = [ Modal config [ Prose [ Text "Press ESC key or click the button below to close" ] ] ]
                    , theme = Light
                    , dock = Nothing
                    , fab = Nothing
                    }
                )

        plain =
            modal { defaultModalConfig | title = Just "Hello!", actions = [ Button btn "Close" ] }
    in
    [ ( "modal--00", plain )
    , ( "modal--01", plain )
    , ( "modal--02"
      , modal
            { defaultModalConfig
                | title = Just "Hello!"
                , actions =
                    [ Button
                        { btn | size = Just SButton.Sm, style = Just SButton.Ghost, modifiers = [ SButton.Circle ] }
                        "x"
                    ]
            }
      )
    , ( "modal--03", plain )
    , ( "modal--04", modal { defaultModalConfig | placement = Just SModal.Bottom, actions = [ Button btn "Close" ] } )
    , ( "modal--05", plain )
    , ( "modal--06", plain )
    , ( "modal--07", plain )
    , ( "modal--08", plain )
    , ( "modal--09", plain )
    ]


navbarEntries : List ( String, Node )
navbarEntries =
    let
        ghost label =
            Button { btn | style = Just SButton.Ghost } label

        square =
            Button { btn | style = Just SButton.Ghost, modifiers = [ SButton.Square ] } ""
    in
    [ ( "navbar--00", section (Navbar { emptyNavbarParts | start = [ ghost "daisyUI" ] }) )
    , ( "navbar--01"
      , section (Navbar { emptyNavbarParts | start = [ ghost "daisyUI" ], end = [ square ] })
      )
    , ( "navbar--02"
      , section (Navbar { emptyNavbarParts | start = [ square ], end = [ ghost "daisyUI" ] })
      )
    , ( "navbar--06"
      , section
            (Navbar
                { start =
                    [ Button
                        { btn
                            | style = Just SButton.Ghost
                            , modifiers = [ SButton.Circle ]
                            , dropdown =
                                Just
                                    { config = defaultDropdownConfig
                                    , menu =
                                        { config = { defaultMenuConfig | size = Just SMenu.Sm }
                                        , items = [ menuItem "Homepage" ]
                                        }
                                    }
                        }
                        ""
                    ]
                , center = [ ghost "daisyUI" ]
                , end =
                    [ Button
                        { btn
                            | style = Just SButton.Ghost
                            , modifiers = [ SButton.Circle ]
                            , indicator =
                                Just
                                    { config = defaultIndicatorConfig
                                    , payload =
                                        IndicatorBadge
                                            { bdg | color = Just SBadge.Primary, size = Just SBadge.Xs }
                                            ""
                                    }
                        }
                        ""
                    ]
                }
            )
      )
    , ( "navbar--09", section (Navbar { emptyNavbarParts | start = [ ghost "daisyUI" ] }) )
    ]


tabEntries : List ( String, Node )
tabEntries =
    let
        tabList =
            [ { label = "Tab 1", active = False, disabled = False, content = [ Text "Tab content 1" ], onClick = Nothing }
            , { label = "Tab 2", active = True, disabled = False, content = [ Text "Tab content 2" ], onClick = Nothing }
            ]

        tabs style =
            block (Tabs { defaultTabsConfig | style = style } tabList)
    in
    [ ( "tab--00", tabs Nothing )
    , ( "tab--01", tabs (Just STab.Border) )
    , ( "tab--02", tabs (Just STab.Lift) )
    , ( "tab--03", tabs (Just STab.Box) )
    , ( "tab--04", tabs (Just STab.Box) )
    , ( "tab--05"
      , blocks
            (Tabs { defaultTabsConfig | style = Just STab.Lift } tabList
                :: List.map
                    (\size -> Tabs { defaultTabsConfig | style = Just STab.Lift, size = Just size } tabList)
                    STab.allSizes
            )
      )
    , ( "tab--06", tabs (Just STab.Border) )
    , ( "tab--07", tabs (Just STab.Lift) )
    , ( "tab--08", tabs (Just STab.Lift) )
    , ( "tab--09"
      , block
            (Tabs
                { defaultTabsConfig | style = Just STab.Lift, placement = Just STab.Bottom }
                tabList
            )
      )
    , ( "tab--10", tabs (Just STab.Box) )
    , ( "tab--11", tabs (Just STab.Lift) )
    , ( "tab--12", tabs (Just STab.Lift) )
    ]


toastEntries : List ( String, Node )
toastEntries =
    let
        toast placement =
            overlay
                (Toast { placement = placement }
                    [ Alert { defaultAlertConfig | color = Just SAlert.Info } [ Text "New message arrived." ]
                    , Alert { defaultAlertConfig | color = Just SAlert.Success } [ Text "Message sent successfully." ]
                    ]
                )
    in
    [ ( "toast--00", toast Nothing )
    , ( "toast--07", toast (Just SToast.Start) )
    , ( "toast--08", toast (Just SToast.Center) )
    , ( "toast--09", toast (Just SToast.End) )
    ]


avatarEntries : List ( String, Node )
avatarEntries =
    let
        avatar config =
            leaf (Avatar config img)

        masked style =
            Avatar { defaultAvatarConfig | mask = Just { defaultMaskConfig | style = Just style } } img

        placeholder =
            { defaultAvatarConfig | modifiers = [ SAvatar.Placeholder ] }
    in
    [ ( "avatar--00", avatar defaultAvatarConfig )
    , ( "avatar--01", avatar defaultAvatarConfig )
    , ( "avatar--02", avatar defaultAvatarConfig )
    , ( "avatar--03"
      , leaves [ masked SMask.Heart, masked SMask.Squircle, masked SMask.Hexagon2 ]
      )
    , ( "avatar--04"
      , leaf (AvatarGroup [ { config = defaultAvatarConfig, src = img }, { config = defaultAvatarConfig, src = img } ])
      )
    , ( "avatar--05"
      , leaf (AvatarGroup [ { config = defaultAvatarConfig, src = img }, { config = placeholder, src = img } ])
      )
    , ( "avatar--06", avatar defaultAvatarConfig )
    , ( "avatar--07"
      , leaves
            [ Avatar { defaultAvatarConfig | modifiers = [ SAvatar.Online ] } img
            , Avatar { defaultAvatarConfig | modifiers = [ SAvatar.Offline ] } img
            ]
      )
    , ( "avatar--08"
      , leaves
            [ Avatar placeholder img
            , Avatar { defaultAvatarConfig | modifiers = [ SAvatar.Online, SAvatar.Placeholder ] } img
            ]
      )
    ]


auraEntries : List ( String, Node )
auraEntries =
    let
        auraCard style size =
            block (Card { crd | aura = Just { style = style, size = size } } { emptyCardParts | body = cardBody [ Text "Aura" ] })

        auraButton style size =
            leaf (Button { btn | aura = Just { style = style, size = size } } "Button")
    in
    [ ( "aura--00", auraCard Nothing Nothing )
    , ( "aura--01", auraButton Nothing Nothing )
    , ( "aura--02", auraCard (Just SAura.Dual) Nothing )
    , ( "aura--03", auraCard (Just SAura.Rainbow) Nothing )
    , ( "aura--04", auraCard (Just SAura.Holo) Nothing )
    , ( "aura--05", auraCard (Just SAura.Glow) Nothing )
    , ( "aura--06", auraCard (Just SAura.Gold) Nothing )
    , ( "aura--07", auraCard (Just SAura.Silver) Nothing )
    , ( "aura--08", auraCard Nothing Nothing )
    , ( "aura--09", auraCard Nothing Nothing )
    , ( "aura--10"
      , pageBlocks
            { buyNow | label = "Subscribe", modifiers = [ SButton.Block ] }
            [ Card
                { crd | aura = Just { style = Just SAura.Rainbow, size = Nothing } }
                { emptyCardParts
                    | body =
                        cardBody
                            [ Badge { bdg | color = Just SBadge.Warning, size = Just SBadge.Xs } "MOST POPULAR"
                            , Text "$29 / month"
                            ]
                }
            ]
      )
    , ( "aura--11"
      , leaves
            (auraLeaf Nothing
                :: List.map (\size -> auraLeaf (Just size)) SAura.allSizes
            )
      )
    , ( "aura--12", auraCard (Just SAura.Rainbow) Nothing )
    ]


auraLeaf : Maybe SAura.Size -> Leaf Msg
auraLeaf size =
    Button { btn | aura = Just { style = Nothing, size = size } } "Button"


carouselEntries : List ( String, Node )
carouselEntries =
    let
        items content =
            [ { content = content }, { content = content } ]

        carousel config content =
            block (Carousel config (items content))

        images =
            [ Image defaultImageConfig img ]

        snapped snap =
            carousel { defaultCarouselConfig | snap = Just snap } images
    in
    [ ( "carousel--00", carousel defaultCarouselConfig images )
    , ( "carousel--01", snapped SnapCenter )
    , ( "carousel--02", snapped SnapEnd )
    , ( "carousel--03", carousel defaultCarouselConfig images )
    , ( "carousel--04", carousel { defaultCarouselConfig | direction = Just SCarousel.Vertical } images )
    , ( "carousel--05", carousel defaultCarouselConfig images )
    , ( "carousel--06", snapped SnapCenter )
    , ( "carousel--07"
      , carousel defaultCarouselConfig (Image defaultImageConfig img :: [ Button { btn | size = Just SButton.Xs } "1" ])
      )
    , ( "carousel--08"
      , carousel defaultCarouselConfig
            (Image defaultImageConfig img :: [ Button { btn | modifiers = [ SButton.Circle ] } "❮" ])
      )
    ]


chatEntries : List ( String, Node )
chatEntries =
    let
        message placement =
            { placement = placement
            , color = Nothing
            , image = Nothing
            , header = Nothing
            , footer = Nothing
            , bubble = [ Text "It was said that you would, destroy the Sith, not join them." ]
            }

        withImage placement =
            { placement = placement, color = Nothing, image = Just img, header = Nothing, footer = Nothing, bubble = [ Text "Hi" ] }

        full placement =
            { placement = placement
            , color = Nothing
            , image = Just img
            , header = Just "Obi-Wan Kenobi"
            , footer = Just "Delivered"
            , bubble = [ Text "You were the Chosen One!" ]
            }
    in
    [ ( "chat--00", block (Chat [ message SChat.Start, message SChat.End ]) )
    , ( "chat--01", block (Chat [ withImage SChat.Start ]) )
    , ( "chat--02", block (Chat [ full SChat.Start, full SChat.End ]) )
    , ( "chat--03"
      , block
            (Chat
                [ { placement = SChat.Start
                  , color = Nothing
                  , image = Nothing
                  , header = Just "Obi-Wan Kenobi"
                  , footer = Just "Seen"
                  , bubble = [ Text "You were the Chosen One!" ]
                  }
                ]
            )
      )
    , ( "chat--04"
      , block
            (Chat
                (List.map
                    (\color -> { placement = SChat.Start, color = Just color, image = Nothing, header = Nothing, footer = Nothing, bubble = [ Text "Hi" ] })
                    SChat.allColors
                    ++ [ message SChat.End ]
                )
            )
      )
    ]


dividerEntries : List ( String, Node )
dividerEntries =
    let
        divider config =
            Divider config (Just "OR")

        inCard config =
            block (Card crd { emptyCardParts | body = cardBody [ divider config ] })

        plain =
            defaultDividerConfig
    in
    [ ( "divider--00", inCard plain )
    , ( "divider--01", inCard { plain | direction = Just SDivider.Horizontal } )
    , ( "divider--02", inCard plain )
    , ( "divider--03", inCard plain )
    , ( "divider--04"
      , leaves (divider plain :: List.map (\color -> divider { plain | color = Just color }) SDivider.allColors)
      )
    , ( "divider--05"
      , leaves
            [ divider { plain | placement = Just SDivider.Start }
            , divider plain
            , divider { plain | placement = Just SDivider.End }
            ]
      )
    , ( "divider--06"
      , leaves
            [ divider { plain | direction = Just SDivider.Horizontal, placement = Just SDivider.Start }
            , divider { plain | direction = Just SDivider.Horizontal }
            , divider { plain | direction = Just SDivider.Horizontal, placement = Just SDivider.End }
            ]
      )
    ]


dockEntries : List ( String, Node )
dockEntries =
    let
        dock size =
            PageNode
                (Page
                    { header = Nothing
                    , shell = Plain
                    , sections = Sections1 (Stack defaultStackConfig [ Prose [ Text "page" ] ])
                    , cta = cta "Save" Clicked
                    , overlays = []
                    , theme = Light
                    , dock =
                        Just
                            { config = { size = size }
                            , items =
                                [ { icon = Just "*", label = "Home", active = True, onClick = Nothing }
                                , { icon = Just "*", label = "Inbox", active = False, onClick = Nothing }
                                ]
                            }
                    , fab = Nothing
                    }
                )
    in
    [ ( "dock--00", dock Nothing )
    , ( "dock--01", dock (Just SDock.Xs) )
    , ( "dock--02", dock (Just SDock.Sm) )
    , ( "dock--03", dock (Just SDock.Md) )
    , ( "dock--04", dock (Just SDock.Lg) )
    , ( "dock--05", dock (Just SDock.Xl) )
    , ( "dock--06", dock Nothing )
    ]


fabEntries : List ( String, Node )
fabEntries =
    let
        round color =
            Button
                { btn | color = color, size = Just SButton.Lg, modifiers = [ SButton.Circle ] }
                "A"

        fabWith config main mainAction actions close =
            PageNode
                (Page
                    { header = Nothing
                    , shell = Plain
                    , sections = Sections1 (Stack defaultStackConfig [ Prose [ Text "page" ] ])
                    , cta = cta "Save" Clicked
                    , overlays = []
                    , theme = Light
                    , dock = Nothing
                    , fab =
                        Just
                            { config = config
                            , main = main
                            , mainAction = mainAction
                            , actions = actions
                            , close = close
                            }
                    }
                )

        fab config main actions close =
            fabWith config main Nothing actions close

        flower =
            { defaultFabConfig | modifiers = [ SFab.Flower ] }

        tipped =
            Button
                { btn
                    | size = Just SButton.Lg
                    , modifiers = [ SButton.Circle ]
                    , tooltip = Just { text = "Label", config = { defaultTooltipConfig | placement = Just STooltip.Left } }
                }
                "A"
    in
    [ ( "fab--01", fab defaultFabConfig (round (Just Secondary)) [ round Nothing ] Nothing )
    , ( "fab--02", fab defaultFabConfig (round (Just Success)) [ round Nothing ] Nothing )
    , ( "fab--03"
      , fab defaultFabConfig
            (round (Just Success))
            [ Button { btn | size = Just SButton.Lg } "Label" ]
            Nothing
      )
    , ( "fab--04"
      , fab defaultFabConfig
            (round (Just Info))
            [ round Nothing ]
            (Just (round (Just Error)))
      )
    , ( "fab--07"
      , fabWith flower (round (Just Success)) (Just (round Nothing)) [ round Nothing ] Nothing
      )
    , ( "fab--10"
      , fabWith flower
            (round (Just Info))
            (Just (round (Just Success)))
            [ tipped, Button { btn | size = Just SButton.Lg, modifiers = [ SButton.Circle ], tooltip = Just (tooltip "Label") } "A" ]
            Nothing
      )
    ]


fieldsetEntries : List ( String, Node )
fieldsetEntries =
    [ ( "fieldset--00", block (fieldsetOf "Page title" [ field "What is your name?" (Input inp) ]) )
    , ( "fieldset--01", block (fieldsetOf "Page title" [ field "What is your name?" (Input inp) ]) )
    , ( "fieldset--02"
      , block (fieldsetOf "Page details" [ field "Title" (Input inp), field "Slug" (Input inp) ])
      )
    , ( "fieldset--03"
      , block
            (fieldsetOf "Page details"
                [ field "Slug"
                    (Join defaultJoinConfig [ JoinInput inp, JoinButton btn "Join" ])
                ]
            )
      )
    , ( "fieldset--04"
      , block
            (fieldsetOf "Login"
                [ field "Email" (Input inp)
                , field "Password" (Input inp)
                , { label = Nothing
                  , labelPlacement = LabelStart
                  , control = Button { btn | color = Just Neutral } "Login"
                  , validate = False
                  , hint = Nothing
                  }
                ]
            )
      )
    , ( "file-input--00", leaf (FileInput defaultFileInputConfig) )
    , ( "file-input--01", leaf (FileInput { defaultFileInputConfig | style = Just SFileInput.Ghost }) )
    , ( "file-input--02", block (fieldsetOf "Pick a file" [ field "Upload" (FileInput defaultFileInputConfig) ]) )
    , ( "file-input--03"
      , leaves (List.map (\size -> FileInput { defaultFileInputConfig | size = Just size }) SFileInput.allSizes)
      )
    , ( "file-input--04"
      , leaves (List.map (\color -> FileInput { defaultFileInputConfig | color = Just color }) SFileInput.allColors)
      )
    , ( "file-input--05", leaf (FileInput defaultFileInputConfig) )
    , ( "label--00", block (fieldsetOf "Login" [ field "https://" (Input inp) ]) )
    , ( "label--01"
      , block
            (Form
                [ { legend = Nothing
                  , columns = OneColumn
                  , fields =
                        [ { label = Just ".com"
                          , labelPlacement = LabelEnd
                          , control = Input inp
                          , validate = False
                          , hint = Nothing
                          }
                        ]
                  }
                ]
            )
      )
    , ( "label--02", block (fieldsetOf "Login" [ field "Currency" (Select sel selData) ]) )
    , ( "label--03", block (fieldsetOf "Login" [ field "Publish date" (Input inp) ]) )
    , ( "label--04", block (Form [ { legend = Nothing, columns = OneColumn, fields = [ floating "Your name" (Input { inp | size = Just SInput.Md }) ] } ]) )
    , ( "label--05"
      , block
            (Form
                [ { legend = Nothing
                  , columns = OneColumn
                  , fields =
                        List.map
                            (\size -> floating "Your name" (Input { inp | size = Just size }))
                            SInput.allSizes
                  }
                ]
            )
      )
    , ( "label--06"
      , block
            (Form
                [ { legend = Nothing
                  , columns = OneColumn
                  , fields =
                        [ floating "Your name" (Input { inp | size = Just SInput.Xs })
                        , floating "Your bio" (Textarea { txa | size = Just STextarea.Xs })
                        , floating "Your country" (Select { sel | size = Just SSelect.Xs } selData)
                        ]
                  }
                ]
            )
      )
    ]


floating : String -> Leaf Msg -> Field Msg
floating label control =
    { label = Just label
    , labelPlacement = LabelFloating
    , control = control
    , validate = False
    , hint = Nothing
    }


joinEntries : List ( String, Node )
joinEntries =
    let
        join direction items =
            leaf (Join { defaultJoinConfig | direction = direction } items)

        buttons =
            [ JoinButton btn "Button", JoinButton btn "Button" ]
    in
    [ ( "join--00", join Nothing buttons )
    , ( "join--01", join (Just SJoin.Vertical) buttons )
    , ( "join--02", join (Just SJoin.Vertical) buttons )
    , ( "join--03"
      , join Nothing
            [ JoinInput
                { inp
                    | indicator =
                        Just
                            { config = defaultIndicatorConfig
                            , payload = IndicatorBadge { bdg | color = Just SBadge.Secondary } "Required"
                            }
                }
            , JoinSelect sel selData
            , JoinButton btn "Search"
            ]
      )
    , ( "join--04", join Nothing [ JoinInput inp, JoinButton btn "Search" ] )
    , ( "join--05", join Nothing buttons )
    , ( "pagination--00", block (Pagination defaultPaginationConfig { pages = [ "1", "2", "3" ], active = 1 }) )
    , ( "pagination--01"
      , leaves
            (List.map
                (\size ->
                    Join defaultJoinConfig
                        [ JoinButton { btn | size = Just size } "1"
                        , JoinButton { btn | size = Just size, behaviors = [ SButton.Active ] } "2"
                        ]
                )
                SButton.allSizes
            )
      )
    , ( "pagination--02"
      , join Nothing
            [ JoinButton btn "Prev"
            , JoinButton { btn | behaviors = [ SButton.Disabled ] } "Next"
            ]
      )
    , ( "pagination--03", join Nothing buttons )
    , ( "pagination--04"
      , join Nothing
            [ JoinButton { btn | style = Just SButton.Outline } "Prev"
            , JoinButton { btn | style = Just SButton.Outline } "Next"
            ]
      )
    , ( "pagination--05"
      , join Nothing [ JoinButton { btn | modifiers = [ SButton.Square ] } "1" ]
      )
    ]


maskEntries : List ( String, Node )
maskEntries =
    let
        masked style =
            leaf (Image { defaultImageConfig | mask = Just { defaultMaskConfig | style = Just style } } img)
    in
    [ ( "mask--00", masked SMask.Squircle )
    , ( "mask--01", masked SMask.Heart )
    , ( "mask--02", masked SMask.Hexagon )
    , ( "mask--03", masked SMask.Hexagon2 )
    , ( "mask--04", masked SMask.Decagon )
    , ( "mask--05", masked SMask.Pentagon )
    , ( "mask--06", masked SMask.Diamond )
    , ( "mask--07", masked SMask.Circle )
    , ( "mask--08", masked SMask.Star )
    , ( "mask--09", masked SMask.Star2 )
    , ( "mask--10", masked SMask.Triangle )
    , ( "mask--11", masked SMask.Triangle2 )
    , ( "mask--12", masked SMask.Triangle3 )
    , ( "mask--13", masked SMask.Triangle4 )
    ]


megamenuEntries : List ( String, Node )
megamenuEntries =
    let
        panel menuConfig items =
            { label = "Products"
            , active = True
            , menu = { config = menuConfig, items = items }
            }

        megamenu config menuConfig items =
            leaf (Megamenu config [ panel menuConfig items ])

        plainItems =
            [ menuItem "Item 1", menuItem "Item 2" ]

        titleItem =
            MenuItem
                { label = "Title"
                , href = Nothing
                , glyph = Nothing
                , badge = Nothing
                , active = False
                , disabled = False
                , focus = False
                , title = True
                , onClick = Nothing
                , submenu = []
                }
    in
    [ ( "megamenu--00", megamenu defaultMegamenuConfig defaultMenuConfig plainItems )
    , ( "megamenu--01"
      , megamenu
            { defaultMegamenuConfig | modifiers = [ SMegamenu.Wide ] }
            { defaultMenuConfig | direction = Just SMenu.Horizontal }
            plainItems
      )
    , ( "megamenu--02"
      , megamenu
            { defaultMegamenuConfig | modifiers = [ SMegamenu.Wide ] }
            defaultMenuConfig
            (titleItem :: plainItems)
      )
    , ( "megamenu--03"
      , section
            (Navbar
                { start = [ Button { btn | style = Just SButton.Ghost } "daisyUI" ]
                , center =
                    [ Megamenu
                        { defaultMegamenuConfig | modifiers = [ SMegamenu.Full ] }
                        [ panel defaultMenuConfig plainItems ]
                    ]
                , end = [ Button btn "Login" ]
                }
            )
      )
    , ( "megamenu--04", megamenu defaultMegamenuConfig defaultMenuConfig plainItems )
    , ( "megamenu--05"
      , leaves
            (List.map
                (\size ->
                    Megamenu { defaultMegamenuConfig | size = Just size } [ panel defaultMenuConfig plainItems ]
                )
                SMegamenu.allSizes
            )
      )
    ]


mockupEntries : List ( String, Node )
mockupEntries =
    let
        browser =
            block (MockupBrowser { toolbar = Just "https://daisyui.com", content = [ Text "Hello!" ] })

        code lines =
            block (MockupCode lines)

        phone =
            block (MockupPhone { content = [ Text "It's Glowtime." ] })

        window =
            block (MockupWindow { title = Just "Window", content = [ Text "Hello!" ] })
    in
    [ ( "mockup-browser--00", browser )
    , ( "mockup-browser--01", browser )
    , ( "mockup-code--00", code [ { prefix = Just "$", text = "npm i daisyui" } ] )
    , ( "mockup-code--01"
      , code
            [ { prefix = Just "1", text = "npm i daisyui" }
            , { prefix = Just "2", text = "installing..." }
            ]
      )
    , ( "mockup-code--02", code [ { prefix = Just "1", text = "npm i daisyui" } ] )
    , ( "mockup-code--03", code [ { prefix = Just "~", text = "Magnam dolore beatae necessitatibus" } ] )
    , ( "mockup-code--04", code [ { prefix = Nothing, text = "without prefix" } ] )
    , ( "mockup-code--05", code [ { prefix = Just "$", text = "npm i daisyui" } ] )
    , ( "mockup-phone--00", phone )
    , ( "mockup-phone--01", phone )
    , ( "mockup-window--00", window )
    , ( "mockup-window--01", window )
    ]


leafEntries : List ( String, Node )
leafEntries =
    let
        countdown =
            leaf (Countdown 59)

        kbd config =
            leaf (Kbd config "K")

        loading style =
            leaves
                (List.map
                    (\size -> Loading { defaultLoadingConfig | style = Just style, size = Just size })
                    SLoading.allSizes
                )

        otp config =
            leaf (Otp config { digits = 4 })

        progress color =
            leaf (Progress { defaultProgressConfig | color = color } { value = Just 40, max = 100 })

        radial =
            leaf (RadialProgress { value = 70, label = "70%", size = RadialDefault, ariaLabel = Nothing })

        range config =
            leaf (Range config { min = 0, max = 100, value = 40 })

        skeleton modifiers =
            leaf (Skeleton { defaultSkeletonConfig | modifiers = modifiers })

        status config =
            leaf (Status config)

        textRotate =
            leaf (TextRotate [ "designer", "developer", "creator" ])
    in
    [ ( "countdown--00", countdown )
    , ( "countdown--01", countdown )
    , ( "countdown--02", countdown )
    , ( "countdown--03", countdown )
    , ( "countdown--04", countdown )
    , ( "countdown--05", countdown )
    , ( "countdown--06", countdown )
    , ( "diff--00", block (Diff { item1 = Image defaultImageConfig img, item2 = Image defaultImageConfig img }) )
    , ( "diff--01", block (Diff { item1 = Text "DAISY", item2 = Text "DAISY" }) )
    , ( "filter--00"
      , leaf
            (Filter
                { name = "frameworks"
                , options = [ "Svelte", "Vue", "React" ]
                , selected = Nothing
                , reset = Just (ResetButton [ SButton.Square ])
                , onSelect = Nothing
                }
            )
      )
    , ( "filter--01"
      , leaf
            (Filter
                { name = "frameworks"
                , options = [ "Svelte", "Vue", "React" ]
                , selected = Nothing
                , reset = Just ResetPart
                , onSelect = Nothing
                }
            )
      )
    , ( "filter--02"
      , leaf
            (Filter
                { name = "frameworks"
                , options = [ "Svelte", "Vue", "React" ]
                , selected = Nothing
                , reset = Just (ResetButton [ SButton.Square ])
                , onSelect = Nothing
                }
            )
      )
    , ( "hover-3d--00", leaf (Image { defaultImageConfig | hover3d = True } img) )
    , ( "hover-3d--01"
      , block (Card { crd | hover3d = True } { emptyCardParts | body = cardBody [ Text "Card" ] })
      )
    , ( "hover-3d--02", leaf (Image { defaultImageConfig | hover3d = True } img) )
    , ( "hover-gallery--00", leaf (HoverGallery [ img, img, img ]) )
    , ( "hover-gallery--01"
      , block
            (Card { crd | size = Just SCard.Sm }
                { emptyCardParts
                    | figure = Just (HoverGallery [ img, img ])
                    , title = Just "Card Title"
                }
            )
      )
    , ( "kbd--00", kbd defaultKbdConfig )
    , ( "kbd--01", leaves (List.map (\size -> Kbd { defaultKbdConfig | size = Just size } "K") SKbd.allSizes) )
    , ( "kbd--02", kbd { defaultKbdConfig | size = Just SKbd.Sm } )
    , ( "kbd--03", kbd defaultKbdConfig )
    , ( "kbd--04", kbd defaultKbdConfig )
    , ( "kbd--05", kbd defaultKbdConfig )
    , ( "kbd--06", kbd defaultKbdConfig )
    , ( "list--00"
      , block
            (ListBlock
                [ { cells =
                        [ listCell (Text "Dio Lupa")
                        , listCell (Button { btn | style = Just SButton.Ghost, modifiers = [ SButton.Square ] } "▶")
                        ]
                  }
                ]
            )
      )
    , ( "list--01"
      , block
            (ListBlock
                [ { cells =
                        [ listCell (Text "Dio Lupa")
                        , { content = Text "Remaining Reason", grow = True, wrap = False }
                        , listCell (Button { btn | style = Just SButton.Ghost, modifiers = [ SButton.Square ] } "▶")
                        ]
                  }
                ]
            )
      )
    , ( "list--02"
      , block
            (ListBlock
                [ { cells =
                        [ listCell (Text "Dio Lupa")
                        , { content = Text "Remaining Reason", grow = False, wrap = True }
                        , listCell (Button { btn | style = Just SButton.Ghost, modifiers = [ SButton.Square ] } "▶")
                        ]
                  }
                ]
            )
      )
    , ( "loading--00", loading SLoading.Spinner )
    , ( "loading--01", loading SLoading.Dots )
    , ( "loading--02", loading SLoading.Ring )
    , ( "loading--03", loading SLoading.Ball )
    , ( "loading--04", loading SLoading.Bars )
    , ( "loading--05", loading SLoading.Infinity )
    , ( "loading--06", leaf (Loading { defaultLoadingConfig | style = Just SLoading.Spinner }) )
    , ( "otp--00", otp defaultOtpConfig )
    , ( "otp--01", otp defaultOtpConfig )
    , ( "otp--02", otp { defaultOtpConfig | modifiers = [ SOtp.Joined ] } )
    , ( "otp--03"
      , leaves (List.map (\size -> Otp { defaultOtpConfig | size = Just size } { digits = 4 }) SOtp.allSizes)
      )
    , ( "otp--04"
      , leaves (List.map (\color -> Otp { defaultOtpConfig | color = Just color } { digits = 4 }) SOtp.allColors)
      )
    , ( "progress--00", progress Nothing )
    , ( "progress--01", progress (Just SProgress.Primary) )
    , ( "progress--02", progress (Just SProgress.Secondary) )
    , ( "progress--03", progress (Just SProgress.Accent) )
    , ( "progress--04", progress (Just SProgress.Neutral) )
    , ( "progress--05", progress (Just SProgress.Info) )
    , ( "progress--06", progress (Just SProgress.Success) )
    , ( "progress--07", progress (Just SProgress.Warning) )
    , ( "progress--08", progress (Just SProgress.Error) )
    , ( "progress--09", leaf (Progress defaultProgressConfig { value = Nothing, max = 100 }) )
    , ( "radial-progress--00", radial )
    , ( "radial-progress--01", radial )
    , ( "radial-progress--02", radial )
    , ( "radial-progress--03", radial )
    , ( "radial-progress--04", radial )
    , ( "range--00", range defaultRangeConfig )
    , ( "range--01", range defaultRangeConfig )
    , ( "range--02", range { defaultRangeConfig | color = Just SRange.Neutral } )
    , ( "range--03", range { defaultRangeConfig | color = Just SRange.Primary } )
    , ( "range--04", range { defaultRangeConfig | color = Just SRange.Secondary } )
    , ( "range--05", range { defaultRangeConfig | color = Just SRange.Accent } )
    , ( "range--06", range { defaultRangeConfig | color = Just SRange.Success } )
    , ( "range--07", range { defaultRangeConfig | color = Just SRange.Warning } )
    , ( "range--08", range { defaultRangeConfig | color = Just SRange.Info } )
    , ( "range--09", range { defaultRangeConfig | color = Just SRange.Error } )
    , ( "range--10"
      , leaves
            (List.map
                (\size -> Range { defaultRangeConfig | size = Just size } { min = 0, max = 100, value = 40 })
                SRange.allSizes
            )
      )
    , ( "range--11", range defaultRangeConfig )
    , ( "range--12", range { defaultRangeConfig | direction = Just SRange.Vertical } )
    , ( "skeleton--00", skeleton [] )
    , ( "skeleton--01", skeleton [] )
    , ( "skeleton--02", skeleton [] )
    , ( "skeleton--03", skeleton [ SSkeleton.Text ] )
    , ( "status--00", status defaultStatusConfig )
    , ( "status--01"
      , leaves (List.map (\size -> Status { defaultStatusConfig | size = Just size }) SStatus.allSizes)
      )
    , ( "status--02"
      , leaves (List.map (\color -> Status { defaultStatusConfig | color = Just color }) SStatus.allColors)
      )
    , ( "status--03", status { defaultStatusConfig | color = Just SStatus.Error } )
    , ( "status--04", status { defaultStatusConfig | color = Just SStatus.Info } )
    , ( "stack--00", block (Stacked defaultStackedConfig [ Text "1", Text "2", Text "3" ]) )
    , ( "stack--01", block (Stacked defaultStackedConfig [ Image defaultImageConfig img ]) )
    , ( "text-rotate--00", textRotate )
    , ( "text-rotate--01", textRotate )
    , ( "text-rotate--02", textRotate )
    , ( "text-rotate--03", textRotate )
    , ( "text-rotate--04", textRotate )
    ]


ratingEntries : List ( String, Node )
ratingEntries =
    let
        stars config =
            { name = "rating", count = 5, value = 3, clearable = False }

        rating config =
            leaf (Rating config (stars config))
    in
    [ ( "rating--00", rating { defaultRatingConfig | shape = Just SMask.Star } )
    , ( "rating--01", rating { defaultRatingConfig | shape = Just SMask.Star } )
    , ( "rating--02", rating defaultRatingConfig )
    , ( "rating--03", rating { defaultRatingConfig | shape = Just SMask.Heart } )
    , ( "rating--04", rating defaultRatingConfig )
    , ( "rating--05"
      , leaves
            (List.map
                (\size ->
                    Rating
                        { defaultRatingConfig | size = Just size }
                        { name = "rating", count = 5, value = 3, clearable = False }
                )
                SRating.allSizes
            )
      )
    , ( "rating--06"
      , leaf
            (Rating
                { defaultRatingConfig | size = Just SRating.Lg }
                { name = "rating", count = 5, value = 3, clearable = True }
            )
      )
    , ( "rating--07"
      , leaf
            (Rating
                { defaultRatingConfig | size = Just SRating.Lg, modifiers = [ RatingHalf ] }
                { name = "rating", count = 10, value = 3, clearable = True }
            )
      )
    ]


stepsEntries : List ( String, Node )
stepsEntries =
    let
        step label color =
            { label = label, color = color, icon = Nothing }

        steps direction list =
            block (Steps { direction = direction } list)
    in
    [ ( "steps--00", steps Nothing [ step "Register" (Just SSteps.Primary), step "Choose plan" Nothing ] )
    , ( "steps--01", steps (Just SSteps.Vertical) [ step "Register" (Just SSteps.Primary), step "Choose plan" Nothing ] )
    , ( "steps--02", steps (Just SSteps.Vertical) [ step "Register" (Just SSteps.Primary), step "Choose plan" Nothing ] )
    , ( "steps--03"
      , steps Nothing
            [ { label = "Step 1", color = Just SSteps.Neutral, icon = Just "★" }
            , step "Step 2" Nothing
            ]
      )
    , ( "steps--04", steps Nothing [ step "Step 1" (Just SSteps.Neutral) ] )
    , ( "steps--05", steps Nothing [ step "Fly to moon" (Just SSteps.Info), step "Sink" (Just SSteps.Error) ] )
    , ( "steps--06"
      , steps Nothing
            (step "Step 1" Nothing
                :: List.map (\color -> step "Step" (Just color)) SSteps.allColors
            )
      )
    ]


swapEntries : List ( String, Node )
swapEntries =
    let
        faces =
            { on = "ON", off = "OFF", indeterminate = Nothing }

        swap config =
            leaf (Swap config faces)
    in
    [ ( "swap--00", swap defaultSwapConfig )
    , ( "swap--01", swap defaultSwapConfig )
    , ( "swap--02", swap { defaultSwapConfig | style = Just SSwap.Rotate } )
    , ( "swap--04", swap { defaultSwapConfig | style = Just SSwap.Flip } )
    , ( "swap--05"
      , leaves
            [ Swap defaultSwapConfig faces
            , Swap { defaultSwapConfig | modifiers = [ SSwap.Active ] } faces
            ]
      )
    ]


themeEntries : List ( String, Node )
themeEntries =
    let
        controller presentation =
            leaf
                (ThemeSelect
                    { themes = [ Light, Dark ]
                    , current = Light
                    , presentation = presentation
                    , onSelect = Nothing
                    }
                )
    in
    [ ( "theme-controller--00", controller ThemeAsToggle )
    , ( "theme-controller--01", controller ThemeAsCheckbox )
    , ( "theme-controller--03", controller ThemeAsToggle )
    , ( "theme-controller--04", controller ThemeAsToggle )
    , ( "theme-controller--06", controller ThemeAsToggle )
    , ( "theme-controller--09", controller ThemeAsDropdown )
    ]


timelineEntries : List ( String, Node )
timelineEntries =
    let
        entry start startBox end endBox =
            { start = start
            , startBox = startBox
            , middle = Just (Text "*")
            , end = end
            , endBox = endBox
            }

        timeline direction items =
            block (Timeline { direction = direction, modifiers = [] } items)

        horizontal =
            timeline Nothing

        vertical =
            timeline (Just STimeline.Vertical)

        bothSides =
            [ entry (Just "1984") False (Just "First Macintosh computer") True ]

        endOnly =
            [ { start = Nothing
              , startBox = False
              , middle = Just (Text "*")
              , end = Just "First Macintosh computer"
              , endBox = True
              }
            ]

        startOnly =
            [ entry (Just "1984") True Nothing False ]

        alternating =
            [ entry (Just "1984") True Nothing False
            , entry Nothing False (Just "iMac") True
            ]

        noIcons =
            [ { start = Just "1984", startBox = True, middle = Nothing, end = Nothing, endBox = False }
            , { start = Nothing, startBox = False, middle = Nothing, end = Just "iMac", endBox = True }
            ]
    in
    [ ( "timeline--00", horizontal bothSides )
    , ( "timeline--01", horizontal endOnly )
    , ( "timeline--02", horizontal startOnly )
    , ( "timeline--03", horizontal alternating )
    , ( "timeline--04", horizontal alternating )
    , ( "timeline--05", horizontal noIcons )
    , ( "timeline--06", vertical bothSides )
    , ( "timeline--07", vertical endOnly )
    , ( "timeline--08", vertical startOnly )
    , ( "timeline--09", vertical alternating )
    , ( "timeline--10", vertical alternating )
    , ( "timeline--11", vertical noIcons )
    , ( "timeline--12", vertical bothSides )
    , ( "timeline--13"
      , block
            (Timeline
                { direction = Just STimeline.Vertical, modifiers = [ TimelineSnapIcon ] }
                [ entry (Just "1984") False (Just "First Macintosh computer") False ]
            )
      )
    ]


tooltipEntries : List ( String, Node )
tooltipEntries =
    let
        tip config =
            leaf (Button { btn | tooltip = Just { text = "hello", config = config } } "Hover me")

        colored color =
            leaf
                (Button
                    { btn
                        | color = Just color
                        , tooltip =
                            Just
                                { text = "hello"
                                , config = { defaultTooltipConfig | color = Just (tooltipColor color), modifiers = [ STooltip.Open ] }
                                }
                    }
                    "Hover me"
                )
    in
    [ ( "tooltip--00", tip defaultTooltipConfig )
    , ( "tooltip--01", tip defaultTooltipConfig )
    , ( "tooltip--02", tip { defaultTooltipConfig | modifiers = [ STooltip.Open ] } )
    , ( "tooltip--07"
      , pageOf
            { buyNow
                | label = "Hover me"
                , tooltip =
                    Just
                        { text = "hello"
                        , config = { defaultTooltipConfig | color = Just STooltip.Primary, modifiers = [ STooltip.Open ] }
                        }
            }
            []
      )
    , ( "tooltip--08", colored Secondary )
    , ( "tooltip--09", colored Accent )
    , ( "tooltip--10", colored Info )
    , ( "tooltip--11", colored Success )
    , ( "tooltip--12", colored Warning )
    , ( "tooltip--13", colored Error )
    , ( "tooltip--14", leaf (Button btn "Hover me") )
    , ( "tooltip--15", tip { defaultTooltipConfig | placement = Just STooltip.Start } )
    ]


tooltipColor : ButtonColor -> STooltip.Color
tooltipColor color =
    case color of
        Secondary ->
            STooltip.Secondary

        Accent ->
            STooltip.Accent

        Info ->
            STooltip.Info

        Success ->
            STooltip.Success

        Warning ->
            STooltip.Warning

        Error ->
            STooltip.Error

        Neutral ->
            STooltip.Primary


validatorEntries : List ( String, Node )
validatorEntries =
    let
        validator control hint =
            block (Form [ { legend = Nothing, columns = OneColumn, fields = [ validated "Value" control hint ] } ])

        input =
            validator (Input inp) "Enter a valid value"
    in
    [ ( "validator--00"
      , block
            (Form
                [ { legend = Nothing
                  , columns = OneColumn
                  , fields =
                        [ { label = Nothing
                          , labelPlacement = LabelStart
                          , control = Input inp
                          , validate = True
                          , hint = Nothing
                          }
                        ]
                  }
                ]
            )
      )
    , ( "validator--01", input )
    , ( "validator--02", input )
    , ( "validator--03", input )
    , ( "validator--04", input )
    , ( "validator--05", input )
    , ( "validator--06", input )
    , ( "validator--07", input )
    , ( "validator--08", validator (Checkbox chk) "Required" )
    , ( "validator--09", validator (Toggle tgl { checked = False }) "Required" )
    , ( "validator--10"
      , block
            (Form
                [ { legend = Nothing
                  , columns = OneColumn
                  , fields =
                        [ validated "Browser" (Select sel selData) "Required"
                        , { label = Nothing
                          , labelPlacement = LabelStart
                          , control = Button btn "Submit"
                          , validate = False
                          , hint = Nothing
                          }
                        ]
                  }
                ]
            )
      )
    , ( "validator--11"
      , block
            (Form
                [ { legend = Just "Login"
                  , columns = OneColumn
                  , fields =
                        [ validated "Email" (Input inp) "Enter valid email address"
                        , { label = Nothing
                          , labelPlacement = LabelStart
                          , control = Button { btn | color = Just Neutral } "Login"
                          , validate = False
                          , hint = Nothing
                          }
                        , { label = Nothing
                          , labelPlacement = LabelStart
                          , control = Button { btn | style = Just SButton.Ghost } "Cancel"
                          , validate = False
                          , hint = Nothing
                          }
                        ]
                  }
                ]
            )
      )
    ]


indicatorEntries : List ( String, Node )
indicatorEntries =
    let
        indicator placement payload =
            leaf (Button { btn | indicator = Just { config = { placement = placement }, payload = payload } } "Button")

        badge color =
            IndicatorBadge { bdg | color = color } "99+"
    in
    [ ( "indicator--00"
      , indicator Nothing (IndicatorStatus { defaultStatusConfig | color = Just SStatus.Success })
      )
    , ( "indicator--01", indicator Nothing (badge (Just SBadge.Primary)) )
    , ( "indicator--02", indicator Nothing (badge (Just SBadge.Secondary)) )
    , ( "indicator--05"
      , leaf
            (Input
                { inp
                    | indicator =
                        Just { config = defaultIndicatorConfig, payload = badge Nothing }
                }
            )
      )
    , ( "indicator--08", indicator (Just SIndicator.Start) (badge (Just SBadge.Secondary)) )
    , ( "indicator--09", indicator (Just SIndicator.Center) (badge (Just SBadge.Secondary)) )
    , ( "indicator--10", indicator Nothing (badge (Just SBadge.Secondary)) )
    , ( "indicator--13", indicator (Just SIndicator.Middle) (badge (Just SBadge.Secondary)) )
    , ( "indicator--16", indicator (Just SIndicator.Bottom) (badge (Just SBadge.Secondary)) )
    , ( "indicator--18", indicator (Just SIndicator.Start) (badge (Just SBadge.Secondary)) )
    ]
