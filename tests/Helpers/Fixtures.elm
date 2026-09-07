module Helpers.Fixtures exposing
    ( Msg(..)
    , blocks
    , groups
    , leaves
    , overlays
    , pages
    , sections
    )

{-| Tree values that between them exercise every constructor, every exclusive
option and every modifier of `Daisy.Tree`.

`CoverageTest` renders all of them and compares the emitted class set with
`Daisy.Schema.allClasses`; `ExclusivityTest`, `PartsTest` and
`RenderPurityTest` reuse the same list, so a constructor added to the tree only
has to be added here once.

-}

import Daisy.Chart as Chart
import Daisy.Icon as DIcon
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
import Daisy.Tree as Tree exposing (..)
import Date
import Html exposing (Html)
import Time


{-| Every message a fixture can send. One constructor per handler shape the
tree accepts.
-}
type Msg
    = Clicked
    | Typed String
    | Checked Bool
    | Rated Int
    | Themed Theme
    | CalendarChanged CalendarMsg
    | Picked CalendarValue


{-| The fixtures, in named chunks. Chunking keeps each rendered tree small
enough to read in a failure message.
-}
groups : List ( String, Html Msg )
groups =
    List.indexedMap
        (\i chunk -> ( "leaves " ++ String.fromInt i, Html.div [] (List.map Render.leaf chunk) ))
        (chunksOf 40 leaves)
        ++ List.indexedMap
            (\i chunk -> ( "blocks " ++ String.fromInt i, Html.div [] (List.map Render.block chunk) ))
            (chunksOf 20 blocks)
        ++ List.indexedMap
            (\i s -> ( "section " ++ String.fromInt i, Render.section s ))
            sections
        ++ List.indexedMap
            (\i o -> ( "overlay " ++ String.fromInt i, Render.overlay o ))
            overlays
        ++ List.indexedMap
            (\i p -> ( "page " ++ String.fromInt i, Render.page p ))
            pages


chunksOf : Int -> List a -> List (List a)
chunksOf size list =
    if List.isEmpty list then
        []

    else
        List.take size list :: chunksOf size (List.drop size list)



-- PROPERTIES ----------------------------------------------------------------


tooltips : List Tooltip
tooltips =
    List.map (\v -> { text = "tip", config = { defaultTooltipConfig | color = Just v } }) STooltip.allColors
        ++ List.map (\v -> { text = "tip", config = { defaultTooltipConfig | placement = Just v } }) STooltip.allPlacements
        ++ [ { text = "tip", config = { defaultTooltipConfig | modifiers = STooltip.allModifiers } } ]


dropdowns : List (Dropdown Msg)
dropdowns =
    List.map
        (\v -> { config = { defaultDropdownConfig | placement = Just v }, menu = sidebarMenu })
        SDropdown.allPlacements
        ++ [ { config = { defaultDropdownConfig | modifiers = SDropdown.allModifiers }, menu = sidebarMenu } ]


indicators : List Indicator
indicators =
    List.map
        (\v ->
            { config = { defaultIndicatorConfig | placement = Just v }
            , payload = IndicatorBadge defaultBadgeConfig "9"
            }
        )
        SIndicator.allPlacements
        ++ [ { config = defaultIndicatorConfig, payload = IndicatorStatus defaultStatusConfig } ]


masks : List MaskConfig
masks =
    List.map (\v -> { defaultMaskConfig | style = Just v }) SMask.allStyles
        ++ [ { defaultMaskConfig | modifiers = SMask.allModifiers } ]


auras : List AuraConfig
auras =
    List.map (\v -> { defaultAuraConfig | style = Just v }) SAura.allStyles
        ++ List.map (\v -> { defaultAuraConfig | size = Just v }) SAura.allSizes



-- LEAVES --------------------------------------------------------------------


{-| Every `Leaf` constructor, every exclusive option and every modifier.
-}
leaves : List (Leaf Msg)
leaves =
    avatarLeaves
        ++ badgeLeaves
        ++ buttonLeaves
        ++ calendarLeaves
        ++ checkboxLeaves
        ++ dividerLeaves
        ++ fileInputLeaves
        ++ iconLeaves
        ++ imageLeaves
        ++ inputLeaves
        ++ joinLeaves
        ++ kbdLeaves
        ++ linkLeaves
        ++ loadingLeaves
        ++ megamenuLeaves
        ++ otpLeaves
        ++ progressLeaves
        ++ radioLeaves
        ++ rangeLeaves
        ++ ratingLeaves
        ++ selectLeaves
        ++ skeletonLeaves
        ++ statusLeaves
        ++ swapLeaves
        ++ textareaLeaves
        ++ themeLeaves
        ++ toggleLeaves
        ++ plainLeaves


plainLeaves : List (Leaf Msg)
plainLeaves =
    [ Countdown 12
    , HoverGallery [ "a.png", "b.png" ]
    , RadialProgress { value = 70, label = "70%" }
    , Text "plain text"
    , TextRotate [ "one", "two" ]
    , Filter
        { name = "filter-fixture"
        , options = [ "All", "Some" ]
        , selected = Just "All"
        , reset = Just ResetPart
        , onSelect = Just Typed
        }
    , Filter
        { name = "filter-form-fixture"
        , options = [ "All", "Some" ]
        , selected = Nothing
        , reset = Just (ResetButton [ SButton.Square ])
        , onSelect = Nothing
        }
    , Heading H1 "Page title"
    , Heading H2 "Section title"
    , Heading H3 "Block title"
    ]


{-| One `Leaf.Calendar` per picker kind, so `cally` is emitted and the three
`CalendarState` branches of the renderer are all walked.

The date is fixed rather than read from the clock: a fixture that renders
"today" would change what it emits every midnight, and `RenderPurityTest`
compares two renders for equality.

-}
calendarLeaves : List (Leaf Msg)
calendarLeaves =
    let
        today : Date.Date
        today =
            Date.fromCalendarDate 2026 Time.Sep 7

        config : Tree.CalendarConfig Msg
        config =
            defaultCalendarConfig
                { id = "calendar-fixture"
                , today = today
                , toMsg = CalendarChanged
                , onChange = Picked
                }
    in
    [ Calendar config (Render.initCalendarDate config (Just today))
    , Calendar { config | locale = EnUS, months = TwoMonths }
        (Render.initCalendarRange
            { config | locale = EnUS, months = TwoMonths }
            (Just ( today, Date.add Date.Days 6 today ))
        )
    , Calendar config (Render.initCalendarMulti config [ today ])
    ]


avatarLeaves : List (Leaf Msg)
avatarLeaves =
    [ Avatar { defaultAvatarConfig | modifiers = SAvatar.allModifiers } "a.png"
    , AvatarGroup [ { config = defaultAvatarConfig, src = "a.png" } ]
    ]
        ++ List.map (\m -> Avatar { defaultAvatarConfig | mask = Just m } "a.png") masks
        ++ List.map (\d -> Avatar { defaultAvatarConfig | dropdown = Just d } "a.png") dropdowns
        ++ List.map (\i -> Avatar { defaultAvatarConfig | indicator = Just i } "a.png") indicators
        ++ List.map (\t -> Avatar { defaultAvatarConfig | tooltip = Just t } "a.png") tooltips


badgeConfigs : List BadgeConfig
badgeConfigs =
    List.map (\v -> { defaultBadgeConfig | color = Just v }) SBadge.allColors
        ++ List.map (\v -> { defaultBadgeConfig | style = Just v }) SBadge.allStyles
        ++ List.map (\v -> { defaultBadgeConfig | size = Just v }) SBadge.allSizes


badgeLeaves : List (Leaf Msg)
badgeLeaves =
    List.map (\c -> Badge c "9") badgeConfigs
        ++ [ Badge { defaultBadgeConfig | tooltip = Just (tooltip "tip") } "9" ]


buttonConfigs : List (ButtonConfig Msg)
buttonConfigs =
    List.map (\v -> { defaultButtonConfig | color = Just v }) allButtonColors
        ++ List.map (\v -> { defaultButtonConfig | style = Just v }) SButton.allStyles
        ++ List.map (\v -> { defaultButtonConfig | size = Just v }) SButton.allSizes
        ++ [ { defaultButtonConfig | modifiers = SButton.allModifiers }
           , { defaultButtonConfig | behaviors = SButton.allBehaviors }
           , { defaultButtonConfig | onClick = Just Clicked }
           , { defaultButtonConfig | icon = Just DIcon.Download }
           , { defaultButtonConfig | icon = Just DIcon.Eye, ariaLabel = Just "View order" }
           ]


buttonLeaves : List (Leaf Msg)
buttonLeaves =
    List.map (\c -> Button c "Go") buttonConfigs
        ++ List.map (\a -> Button { defaultButtonConfig | aura = Just a } "Go") auras
        ++ List.map (\d -> Button { defaultButtonConfig | dropdown = Just d } "Go") dropdowns
        ++ List.map (\t -> Button { defaultButtonConfig | tooltip = Just t } "Go") tooltips
        ++ List.map (\i -> Button { defaultButtonConfig | indicator = Just i } "Go") indicators


checkboxLeaves : List (Leaf Msg)
checkboxLeaves =
    List.map (\v -> Checkbox { defaultCheckboxConfig | color = Just v }) SCheckbox.allColors
        ++ List.map (\v -> Checkbox { defaultCheckboxConfig | size = Just v }) SCheckbox.allSizes
        ++ [ Checkbox { defaultCheckboxConfig | checked = True, onCheck = Just Checked, tooltip = Just (tooltip "t") } ]


dividerLeaves : List (Leaf Msg)
dividerLeaves =
    List.map (\v -> Divider { defaultDividerConfig | color = Just v } (Just "or")) SDivider.allColors
        ++ List.map (\v -> Divider { defaultDividerConfig | direction = Just v } Nothing) SDivider.allDirections
        ++ List.map (\v -> Divider { defaultDividerConfig | placement = Just v } Nothing) SDivider.allPlacements


fileInputLeaves : List (Leaf Msg)
fileInputLeaves =
    List.map (\v -> FileInput { defaultFileInputConfig | color = Just v }) SFileInput.allColors
        ++ List.map (\v -> FileInput { defaultFileInputConfig | style = Just v }) SFileInput.allStyles
        ++ List.map (\v -> FileInput { defaultFileInputConfig | size = Just v }) SFileInput.allSizes
        ++ [ FileInput { defaultFileInputConfig | onInput = Just Typed } ]


{-| Every [`Daisy.Icon.Icon`](Daisy-Icon#Icon) at every
[`IconSize`](Daisy-Tree#IconSize), plus one labelled icon, so all three size
tokens and both accessibility shapes are walked.

`Leaf.Icon` emits no daisyUI class at all, so it changes nothing in
`CoverageTest`; it is here for `RenderPurityTest`'s budget check (the size
tokens) and for `ExclusivityTest`'s per-element sweep.

-}
iconLeaves : List (Leaf Msg)
iconLeaves =
    List.map (Icon defaultIconConfig) DIcon.allIcons
        ++ List.map
            (\size -> Icon { defaultIconConfig | size = size } DIcon.Bell)
            [ IconSm, IconMd, IconLg ]
        ++ [ Icon { defaultIconConfig | label = Just "Notifications" } DIcon.Bell ]


imageLeaves : List (Leaf Msg)
imageLeaves =
    List.map (\m -> Image { defaultImageConfig | mask = Just m } "a.png") masks
        ++ [ Image { defaultImageConfig | hover3d = True } "a.png"
           , Image { defaultImageConfig | alt = "alt", onClick = Just Clicked, tooltip = Just (tooltip "t") } "a.png"
           ]


inputConfigs : List (InputConfig Msg)
inputConfigs =
    List.map (\v -> { defaultInputConfig | color = Just v }) SInput.allColors
        ++ List.map (\v -> { defaultInputConfig | style = Just v }) SInput.allStyles
        ++ List.map (\v -> { defaultInputConfig | size = Just v }) SInput.allSizes


inputLeaves : List (Leaf Msg)
inputLeaves =
    List.map Input inputConfigs
        ++ List.map (\i -> Input { defaultInputConfig | indicator = Just i }) indicators
        ++ [ Input { defaultInputConfig | placeholder = "p", value = "v", onInput = Just Typed }
           , Input
                { defaultInputConfig
                    | inputType = InputEmail
                    , required = True
                    , pattern = Just "[^@]+@[^@]+"
                    , minLength = Just 3
                    , maxLength = Just 64
                    , ariaLabel = Just "Contact email"
                }
           ]


joinLeaves : List (Leaf Msg)
joinLeaves =
    List.map
        (\v ->
            Join { defaultJoinConfig | direction = Just v }
                [ JoinButton defaultButtonConfig "one"
                , JoinInput defaultInputConfig
                , JoinSelect defaultSelectConfig { options = [ "a" ], selected = Nothing }
                , JoinText "of"
                ]
        )
        SJoin.allDirections


kbdLeaves : List (Leaf Msg)
kbdLeaves =
    List.map (\v -> Kbd { defaultKbdConfig | size = Just v } "K") SKbd.allSizes


linkLeaves : List (Leaf Msg)
linkLeaves =
    List.map (\v -> Link { defaultLinkConfig | color = Just v } "link") SLink.allColors
        ++ List.map (\v -> Link { defaultLinkConfig | style = Just v } "link") SLink.allStyles
        ++ [ Link { defaultLinkConfig | href = "/x", onClick = Just Clicked } "link"
           , Link { defaultLinkConfig | dropdown = List.head dropdowns } "link"
           , Link { defaultLinkConfig | indicator = List.head indicators } "link"
           ]


loadingLeaves : List (Leaf Msg)
loadingLeaves =
    List.map (\v -> Loading { defaultLoadingConfig | style = Just v }) SLoading.allStyles
        ++ List.map (\v -> Loading { defaultLoadingConfig | size = Just v }) SLoading.allSizes


megamenuLeaves : List (Leaf Msg)
megamenuLeaves =
    List.map (\v -> Megamenu { defaultMegamenuConfig | size = Just v } megamenuItems) SMegamenu.allSizes
        ++ List.map (\v -> Megamenu { defaultMegamenuConfig | direction = Just v } megamenuItems) SMegamenu.allDirections
        ++ [ Megamenu { defaultMegamenuConfig | modifiers = SMegamenu.allModifiers } megamenuItems ]


megamenuItems : List (MegamenuItem Msg)
megamenuItems =
    [ { label = "Products", active = True, menu = sidebarMenu } ]


otpLeaves : List (Leaf Msg)
otpLeaves =
    List.map (\v -> Otp { defaultOtpConfig | color = Just v } { digits = 2 }) SOtp.allColors
        ++ List.map (\v -> Otp { defaultOtpConfig | size = Just v } { digits = 2 }) SOtp.allSizes
        ++ [ Otp { defaultOtpConfig | modifiers = SOtp.allModifiers, onInput = Just Typed } { digits = 2 } ]


progressLeaves : List (Leaf Msg)
progressLeaves =
    List.map (\v -> Progress { defaultProgressConfig | color = Just v } { value = Just 40, max = 100 }) SProgress.allColors
        ++ [ Progress defaultProgressConfig { value = Nothing, max = 100 } ]


radioLeaves : List (Leaf Msg)
radioLeaves =
    List.map (\v -> Radio { defaultRadioConfig | color = Just v } radioData) SRadio.allColors
        ++ List.map (\v -> Radio { defaultRadioConfig | size = Just v } radioData) SRadio.allSizes
        ++ [ Radio { defaultRadioConfig | onCheck = Just Checked } radioData ]


radioData : RadioData
radioData =
    { name = "radio-fixture", checked = True }


rangeLeaves : List (Leaf Msg)
rangeLeaves =
    List.map (\v -> Range { defaultRangeConfig | color = Just v } rangeData) SRange.allColors
        ++ List.map (\v -> Range { defaultRangeConfig | size = Just v } rangeData) SRange.allSizes
        ++ List.map (\v -> Range { defaultRangeConfig | direction = Just v } rangeData) SRange.allDirections
        ++ [ Range { defaultRangeConfig | onInput = Just Typed } rangeData ]


rangeData : RangeData
rangeData =
    { min = 0, max = 100, value = 50 }


ratingLeaves : List (Leaf Msg)
ratingLeaves =
    List.map (\v -> Rating { defaultRatingConfig | size = Just v } ratingData) SRating.allSizes
        ++ List.map (\v -> Rating { defaultRatingConfig | shape = Just v } ratingData) SMask.allStyles
        ++ [ Rating
                { defaultRatingConfig
                    | modifiers = allRatingModifiers
                    , ariaLabel = Just "Rate this"
                    , onRate = Just Rated
                }
                { ratingData | clearable = True }
           ]


ratingData : RatingData
ratingData =
    { name = "rating-fixture", count = 3, value = 2, clearable = False }


selectLeaves : List (Leaf Msg)
selectLeaves =
    List.map (\v -> Select { defaultSelectConfig | color = Just v } selectData) SSelect.allColors
        ++ List.map (\v -> Select { defaultSelectConfig | style = Just v } selectData) SSelect.allStyles
        ++ List.map (\v -> Select { defaultSelectConfig | size = Just v } selectData) SSelect.allSizes
        ++ [ Select { defaultSelectConfig | onSelect = Just Typed } selectData ]


selectData : SelectData
selectData =
    { options = [ "a", "b" ], selected = Just "a" }


skeletonLeaves : List (Leaf Msg)
skeletonLeaves =
    [ Skeleton { defaultSkeletonConfig | modifiers = SSkeleton.allModifiers } ]


statusLeaves : List (Leaf Msg)
statusLeaves =
    List.map (\v -> Status { defaultStatusConfig | color = Just v }) SStatus.allColors
        ++ List.map (\v -> Status { defaultStatusConfig | size = Just v }) SStatus.allSizes


swapLeaves : List (Leaf Msg)
swapLeaves =
    List.map (\v -> Swap { defaultSwapConfig | style = Just v } swapFaces) SSwap.allStyles
        ++ [ Swap { defaultSwapConfig | modifiers = SSwap.allModifiers, onCheck = Just Checked } swapFaces ]


swapFaces : SwapFaces
swapFaces =
    { on = "ON", off = "OFF", indeterminate = Just "?" }


textareaLeaves : List (Leaf Msg)
textareaLeaves =
    List.map (\v -> Textarea { defaultTextareaConfig | color = Just v }) STextarea.allColors
        ++ List.map (\v -> Textarea { defaultTextareaConfig | style = Just v }) STextarea.allStyles
        ++ List.map (\v -> Textarea { defaultTextareaConfig | size = Just v }) STextarea.allSizes
        ++ [ Textarea { defaultTextareaConfig | placeholder = "p", value = "v", onInput = Just Typed } ]


themeLeaves : List (Leaf Msg)
themeLeaves =
    List.map
        (\presentation ->
            ThemeSelect
                { themes = [ Light, Dark ]
                , current = Light
                , presentation = presentation
                , onSelect = Just Themed
                }
        )
        [ ThemeAsSelect, ThemeAsRadios, ThemeAsToggle, ThemeAsCheckbox, ThemeAsSwap, ThemeAsDropdown ]


toggleLeaves : List (Leaf Msg)
toggleLeaves =
    List.map (\v -> Toggle { defaultToggleConfig | color = Just v } { checked = True }) SToggle.allColors
        ++ List.map (\v -> Toggle { defaultToggleConfig | size = Just v } { checked = False }) SToggle.allSizes



-- BLOCKS --------------------------------------------------------------------


{-| Every `Block` constructor, every exclusive option and every modifier.
-}
blocks : List (Block Msg)
blocks =
    accordionBlocks
        ++ alertBlocks
        ++ cardBlocks
        ++ carouselBlocks
        ++ chartBlocks
        ++ chatBlocks
        ++ collapseBlocks
        ++ listBlocks
        ++ menuBlocks
        ++ mockupBlocks
        ++ paginationBlocks
        ++ stackedBlocks
        ++ statBlocks
        ++ stepsBlocks
        ++ tableBlocks
        ++ tabsBlocks
        ++ timelineBlocks
        ++ plainBlocks


plainBlocks : List (Block Msg)
plainBlocks =
    [ Breadcrumbs [ Link defaultLinkConfig "Home", Text "Here" ]
    , Diff { item1 = Image defaultImageConfig "a.png", item2 = Image defaultImageConfig "b.png" }
    , Prose [ Text "prose" ]
    , Nav { title = Just "Column" } [ Link defaultLinkConfig "One" ]
    , Form formFieldsets
    ]


formFieldsets : List (Fieldset Msg)
formFieldsets =
    [ { legend = Just "Account"
      , fields =
            [ { label = Just "Email"
              , labelPlacement = LabelStart
              , control = Input defaultInputConfig
              , validate = True
              , hint = Just "Enter a valid email"
              }
            , { label = Just "Agree"
              , labelPlacement = LabelEnd
              , control = Checkbox defaultCheckboxConfig
              , validate = False
              , hint = Nothing
              }
            , { label = Just "Name"
              , labelPlacement = LabelFloating
              , control = Input defaultInputConfig
              , validate = True
              , hint = Just "Tell us your name"
              }
            ]
      }
    ]


accordionBlocks : List (Block Msg)
accordionBlocks =
    [ Accordion { defaultAccordionConfig | modifiers = SAccordion.allModifiers } accordionItems ]


accordionItems : List (AccordionItem Msg)
accordionItems =
    [ { title = "One", content = [ Text "first" ] } ]


alertBlocks : List (Block Msg)
alertBlocks =
    List.map (\v -> Alert { defaultAlertConfig | color = Just v } alertContent) SAlert.allColors
        ++ List.map (\v -> Alert { defaultAlertConfig | style = Just v } alertContent) SAlert.allStyles
        ++ List.map (\v -> Alert { defaultAlertConfig | direction = Just v } alertContent) SAlert.allDirections


alertContent : List (Leaf Msg)
alertContent =
    [ Text "Saved" ]


cardBlocks : List (Block Msg)
cardBlocks =
    List.map (\v -> Card { defaultCardConfig | style = Just v } cardParts) SCard.allStyles
        ++ List.map (\v -> Card { defaultCardConfig | size = Just v } cardParts) SCard.allSizes
        ++ [ Card { defaultCardConfig | modifiers = SCard.allModifiers } cardParts
           , Card { defaultCardConfig | hover3d = True } cardParts
           , Card defaultCardConfig cardBlockChildren
           ]
        ++ List.map (\a -> Card { defaultCardConfig | aura = Just a } cardParts) auras


cardParts : CardParts Msg
cardParts =
    { figure = Just (Image defaultImageConfig "a.png")
    , title = Just "Title"
    , body = [ CardLeaf (Text "body") ]
    , actions = [ Button defaultButtonConfig "Buy" ]
    }


{-| A card whose body holds one of each block-shaped `CardChild`.
-}
cardBlockChildren : CardParts Msg
cardBlockChildren =
    { cardParts
        | body =
            [ CardLeaf (Text "body")
            , CardAlert defaultAlertConfig [ Text "Saved" ]
            , CardChart Chart.Line chartData
            , CardTable defaultTableConfig tableRows
            , CardStat defaultStatConfig statItems
            , CardForm formFieldsets
            ]
    }


carouselBlocks : List (Block Msg)
carouselBlocks =
    List.map (\v -> Carousel { defaultCarouselConfig | direction = Just v } carouselItems) SCarousel.allDirections
        ++ [ Carousel { defaultCarouselConfig | modifiers = SCarousel.allModifiers } carouselItems ]
        ++ List.map
            (\snap -> Carousel { defaultCarouselConfig | snap = Just snap } carouselItems)
            [ SnapStart, SnapCenter, SnapEnd ]


carouselItems : List (CarouselItem Msg)
carouselItems =
    [ { content = [ Image defaultImageConfig "a.png" ] } ]


chartBlocks : List (Block Msg)
chartBlocks =
    List.map (\config -> Chart config chartData) Chart.allChartConfigs


chartData : Chart.ChartData
chartData =
    { series =
        List.map
            (\color -> { name = "s", color = color, points = [ 1, 2, 3 ] })
            Chart.allSemanticColors
    , xLabels = [ "Jan", "Feb", "Mar" ]
    }


chatBlocks : List (Block Msg)
chatBlocks =
    [ Chat
        (List.map
            (\color ->
                { placement = firstChatPlacement
                , color = Just color
                , image = Just "a.png"
                , header = Just "Obi-Wan"
                , footer = Just "Seen"
                , bubble = [ Text "Hello there" ]
                }
            )
            SChat.allColors
            ++ List.map
                (\placement ->
                    { placement = placement
                    , color = Nothing
                    , image = Nothing
                    , header = Nothing
                    , footer = Nothing
                    , bubble = [ Text "Hi" ]
                    }
                )
                SChat.allPlacements
        )
    ]


firstChatPlacement : SChat.Placement
firstChatPlacement =
    List.head SChat.allPlacements |> Maybe.withDefault SChat.Start


collapseBlocks : List (Block Msg)
collapseBlocks =
    [ Collapse { defaultCollapseConfig | modifiers = SCollapse.allModifiers }
        { title = "More", content = [ Text "details" ] }
    ]


listBlocks : List (Block Msg)
listBlocks =
    [ ListBlock
        [ { cells =
                [ listCell (Text "row")
                , { content = Text "grows", grow = True, wrap = False }
                , { content = Text "wraps", grow = False, wrap = True }
                ]
          }
        ]
    ]


menuBlocks : List (Block Msg)
menuBlocks =
    List.map (\v -> Menu { defaultMenuConfig | size = Just v } menuItems) SMenu.allSizes
        ++ List.map (\v -> Menu { defaultMenuConfig | direction = Just v } menuItems) SMenu.allDirections
        ++ [ Menu { defaultMenuConfig | modifiers = SMenu.allModifiers } menuItems ]


menuItems : List (MenuItem Msg)
menuItems =
    [ MenuItem
        { label = "Section"
        , href = Nothing
        , icon = Nothing
        , badge = Nothing
        , active = False
        , disabled = False
        , focus = False
        , title = True
        , onClick = Nothing
        , submenu = []
        }
    , MenuItem
        { label = "Dashboard"
        , href = Nothing
        , icon = Just DIcon.Home
        , badge = Just { config = defaultBadgeConfig, label = "2" }
        , active = True
        , disabled = True
        , focus = True
        , title = False
        , onClick = Just Clicked
        , submenu = []
        }
    , MenuItem
        { label = "More"
        , href = Nothing
        , icon = Nothing
        , badge = Nothing
        , active = False
        , disabled = False
        , focus = False
        , title = False
        , onClick = Nothing
        , submenu = [ menuItem "Nested" ]
        }
    ]


sidebarMenu : MenuSpec Msg
sidebarMenu =
    { config = defaultMenuConfig, items = [ menuItem "Home" ] }


mockupBlocks : List (Block Msg)
mockupBlocks =
    [ MockupBrowser { toolbar = Just "https://daisyui.com", content = [ Text "page" ] }
    , MockupCode [ { prefix = Just "$", text = "bun install" } ]
    , MockupPhone { content = [ Text "phone" ] }
    , MockupWindow { title = Just "Window", content = [ Text "window" ] }
    ]


paginationBlocks : List (Block Msg)
paginationBlocks =
    List.map
        (\v -> Pagination { defaultPaginationConfig | direction = Just v } { pages = [ "1", "2" ], active = 0 })
        SPagination.allDirections


stackedBlocks : List (Block Msg)
stackedBlocks =
    [ Stacked { defaultStackedConfig | modifiers = SStack.allModifiers } [ Image defaultImageConfig "a.png" ] ]
        ++ List.map
            (\align -> Stacked { defaultStackedConfig | align = Just align } [ Text "top" ])
            [ StackedTop, StackedBottom, StackedStart, StackedEnd ]


statBlocks : List (Block Msg)
statBlocks =
    List.map (\v -> Stat { direction = Fixed (Just v) } statItems) SStat.allDirections
        ++ [ Stat { direction = Responsive } statItems ]


statItems : List (StatItem Msg)
statItems =
    [ { figure = Just (Loading defaultLoadingConfig)
      , title = "Downloads"
      , value = "31K"
      , desc = Just "Jan 1st"
      , actions = [ Button defaultButtonConfig "Details" ]
      }
    ]


stepsBlocks : List (Block Msg)
stepsBlocks =
    List.map (\v -> Steps { defaultStepsConfig | direction = Just v } steps) SSteps.allDirections


steps : List Step
steps =
    { label = "Register", color = Nothing, icon = Just "1" }
        :: List.map (\color -> { label = "Step", color = Just color, icon = Nothing }) SSteps.allColors


tableBlocks : List (Block Msg)
tableBlocks =
    List.map (\v -> Table { defaultTableConfig | size = Just v } tableRows) STable.allSizes
        ++ [ Table { defaultTableConfig | modifiers = STable.allModifiers } tableRows ]


tableRows : List (Row Msg)
tableRows =
    [ { header = True, cells = [ tableCell (Text "Name") ] }
    , { header = False, cells = [ tableCell (Text "Cy Ganderton") ] }

    -- A cell with a `leading` leaf: the avatar-and-name idiom, which is the
    -- only branch of `tableCellHtml` that emits a wrapper.
    , { header = False
      , cells =
            [ { leading = Just (Avatar defaultAvatarConfig "a.png")
              , content = Text "Hart Hagerty"
              }
            ]
      }
    ]


tabsBlocks : List (Block Msg)
tabsBlocks =
    List.map (\v -> Tabs { defaultTabsConfig | style = Just v } tabs) STab.allStyles
        ++ List.map (\v -> Tabs { defaultTabsConfig | size = Just v } tabs) STab.allSizes
        ++ List.map (\v -> Tabs { defaultTabsConfig | placement = Just v } tabs) STab.allPlacements


tabs : List (Tab Msg)
tabs =
    [ { label = "Tab 1", active = True, disabled = False, content = [ Text "one" ] }
    , { label = "Tab 2", active = False, disabled = True, content = [ Text "two" ] }
    ]


timelineBlocks : List (Block Msg)
timelineBlocks =
    List.map (\v -> Timeline { defaultTimelineConfig | direction = Just v } timelineItems) STimeline.allDirections
        ++ [ Timeline { defaultTimelineConfig | modifiers = allTimelineModifiers } timelineItems ]


timelineItems : List (TimelineItem Msg)
timelineItems =
    [ { start = Just "1984"
      , startBox = True
      , middle = Just (Badge defaultBadgeConfig "ok")
      , end = Just "First Macintosh"
      , endBox = True
      }
    ]



-- SECTIONS ------------------------------------------------------------------


{-| Every `Section` constructor and every exclusive option.
-}
sections : List (Section Msg)
sections =
    [ Hero { overlay = True } [ Prose [ Text "hero" ] ]
    , Hero defaultHeroConfig [ Prose [ Text "hero" ] ]
    , Navbar { start = [ Text "Start" ], center = [ Text "Center" ], end = [ Button defaultButtonConfig "End" ] }
    , Grid { columns = Cols1 } [ Prose [ Text "a" ] ]
    , Grid { columns = Cols2 } [ Prose [ Text "a" ] ]
    , Grid { columns = Cols3 } [ Prose [ Text "a" ] ]
    , Grid { columns = Cols4 } [ Prose [ Text "a" ] ]
    , Stack { align = AlignStart } [ Prose [ Text "a" ] ]
    , Stack { align = AlignCenter } [ Prose [ Text "a" ] ]
    , Stack { align = AlignEnd } [ Prose [ Text "a" ] ]
    , Stack { align = AlignStretch } [ Prose [ Text "a" ] ]
    ]
        ++ List.map (\v -> Footer { defaultFooterConfig | direction = Just v } footerBlocks) SFooter.allDirections
        ++ List.map (\v -> Footer { defaultFooterConfig | placement = Just v } footerBlocks) SFooter.allPlacements


footerBlocks : List (Block Msg)
footerBlocks =
    [ Nav { title = Just "Services" } [ Link defaultLinkConfig "Branding" ] ]



-- OVERLAYS ------------------------------------------------------------------


{-| Every `Overlay` constructor and every exclusive option.
-}
overlays : List (Overlay Msg)
overlays =
    List.map (\v -> Modal { modalConfig | placement = Just v } modalBlocks) SModal.allPlacements
        ++ [ Modal { modalConfig | modifiers = SModal.allModifiers } modalBlocks ]
        ++ List.map (\v -> Drawer { defaultDrawerConfig | placement = Just v } drawerSections) SDrawer.allPlacements
        ++ [ Drawer { defaultDrawerConfig | modifiers = SDrawer.allModifiers } drawerSections ]
        ++ List.map (\v -> Toast { defaultToastConfig | placement = Just v } toastBlocks) SToast.allPlacements


modalConfig : ModalConfig Msg
modalConfig =
    { defaultModalConfig
        | title = Just "Confirm"
        , actions = [ Button defaultButtonConfig "Close" ]
    }


modalBlocks : List (Block Msg)
modalBlocks =
    [ Prose [ Text "Are you sure?" ] ]


drawerSections : List (Section Msg)
drawerSections =
    [ Stack defaultStackConfig [ Menu defaultMenuConfig [ menuItem "Home" ] ] ]


toastBlocks : List (Block Msg)
toastBlocks =
    [ Alert defaultAlertConfig [ Text "Saved" ] ]



-- PAGES ---------------------------------------------------------------------


{-| Every `Shell`, every `Sections` arity and the page-level chrome.
-}
pages : List (Page Msg)
pages =
    [ Page
        { shell = Plain
        , sections = Sections1 (Stack defaultStackConfig [ Prose [ Text "one" ] ])
        , cta = cta "Save" Clicked
        , overlays = []
        , theme = Light
        , dock = Nothing
        , fab = Nothing
        }
    , Page
        { shell = Dashboard { sidebar = sidebarMenu, navbar = emptyNavbarParts }
        , sections =
            Sections5 plainSection plainSection plainSection plainSection plainSection
        , cta = fullCta
        , overlays = [ Toast defaultToastConfig toastBlocks, Modal modalConfig modalBlocks, Drawer defaultDrawerConfig drawerSections ]
        , theme = Dark
        , dock = Just dock
        , fab = Just fab
        }
    , Page
        { shell = Plain
        , sections = Sections2 plainSection plainSection
        , cta = ctaWithProperties
        , overlays = []
        , theme = Cupcake
        , dock = Nothing
        , fab = Nothing
        }
    , Page
        { shell = Plain
        , sections = Sections3 plainSection plainSection plainSection
        , cta = cta "Save" Clicked
        , overlays = []
        , theme = Night
        , dock = Nothing
        , fab = Nothing
        }
    , Page
        { shell = Plain
        , sections = Sections4 plainSection plainSection plainSection plainSection
        , cta = cta "Save" Clicked
        , overlays = []
        , theme = Silk
        , dock = Nothing
        , fab = Nothing
        }
    ]
        ++ List.map dockPage SDock.allSizes


dockPage : SDock.Size -> Page Msg
dockPage size =
    Page
        { shell = Plain
        , sections = Sections1 plainSection
        , cta = cta "Save" Clicked
        , overlays = []
        , theme = Light
        , dock = Just { dock | config = { size = Just size } }
        , fab = Nothing
        }


plainSection : Section Msg
plainSection =
    Stack defaultStackConfig [ Prose [ Text "section" ] ]


fullCta : Cta Msg
fullCta =
    let
        base =
            cta "Save" Clicked
    in
    { base
        | size = List.head SButton.allSizes
        , style = List.head SButton.allStyles
        , modifiers = SButton.allModifiers
        , behaviors = SButton.allBehaviors
    }


ctaWithProperties : Cta Msg
ctaWithProperties =
    let
        base =
            cta "Save" Clicked
    in
    { base
        | tooltip = Just (tooltip "Save the page")
        , aura = List.head auras
        , indicator = List.head indicators
        , icon = Just DIcon.Download
    }


dock : Dock Msg
dock =
    { config = { size = List.head SDock.allSizes }
    , items =
        [ { icon = Just "*", label = "Home", active = True, onClick = Just Clicked }
        , { icon = Nothing, label = "Inbox", active = False, onClick = Nothing }
        ]
    }


fab : Fab Msg
fab =
    { config = { modifiers = SFab.allModifiers }
    , main = Button defaultButtonConfig "+"
    , mainAction = Just (Button defaultButtonConfig "Main")
    , actions = [ Button defaultButtonConfig "A" ]
    , close = Just (Button defaultButtonConfig "x")
    }
