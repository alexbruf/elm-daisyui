module ExclusivityTest exposing (suite)

{-| Tier A, row 2: no rendered element ever carries two classes from one
exclusive group of `Daisy.Schema.exclusiveGroups`.

Every config type gets a fuzzer that picks a random value (or nothing) from
each of its exclusive groups and a random subset of its modifiers and
behaviors, so the fuzzer explores combinations no hand-written fixture would.

The check itself compares each rendered element's class set against every
exclusive group at once, rather than asking `Test.Html.Query` about one pair of
classes at a time: `Helpers.Classes` can enumerate the elements of a render, so
the pairwise `Query.findAll [ class a, class b ]` walk is unnecessary and the
whole-set check is strictly stronger — it catches a third class in the group as
well as the pair.

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
import Daisy.Tree exposing (..)
import Date
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Helpers.Classes as Classes
import Helpers.Fixtures as Fixtures exposing (Msg(..))
import Html exposing (Html)
import Test exposing (Test, describe, fuzz, test)
import Time



-- FUZZ HELPERS --------------------------------------------------------------


{-| `Nothing`, or any one value of an exclusive group.
-}
maybeOf : List a -> Fuzzer (Maybe a)
maybeOf list =
    Fuzz.oneOf (Fuzz.constant Nothing :: List.map (Just >> Fuzz.constant) list)


{-| Any subset of a set-valued group (`modifier`, `behavior`).
-}
subsetOf : List a -> Fuzzer (List a)
subsetOf list =
    Fuzz.listOfLength (List.length list) Fuzz.bool
        |> Fuzz.map
            (\flags ->
                List.map2 Tuple.pair flags list
                    |> List.filter Tuple.first
                    |> List.map Tuple.second
            )


expectExclusive : Html msg -> Expectation
expectExclusive html =
    Classes.expectNoProblems (Classes.exclusivityProblems (Classes.elementsIn html))



-- PROPERTY FUZZERS ----------------------------------------------------------


tooltipFuzzer : Fuzzer Tooltip
tooltipFuzzer =
    Fuzz.map3
        (\color placement modifiers ->
            { text = "tip"
            , config = { color = color, placement = placement, modifiers = modifiers }
            }
        )
        (maybeOf STooltip.allColors)
        (maybeOf STooltip.allPlacements)
        (subsetOf STooltip.allModifiers)


dropdownFuzzer : Fuzzer (Dropdown Msg)
dropdownFuzzer =
    Fuzz.map2
        (\placement modifiers ->
            { config = { placement = placement, modifiers = modifiers }
            , menu = { config = defaultMenuConfig, items = [ menuItem "Home" ] }
            }
        )
        (maybeOf SDropdown.allPlacements)
        (subsetOf SDropdown.allModifiers)


indicatorFuzzer : Fuzzer Indicator
indicatorFuzzer =
    Fuzz.map2
        (\placement badge -> { config = { placement = placement }, payload = badge })
        (maybeOf SIndicator.allPlacements)
        (Fuzz.oneOf
            [ Fuzz.map (\c -> IndicatorBadge c "9") badgeConfigFuzzer
            , Fuzz.map IndicatorStatus statusConfigFuzzer
            ]
        )


maskFuzzer : Fuzzer MaskConfig
maskFuzzer =
    Fuzz.map2 (\style modifiers -> { style = style, modifiers = modifiers })
        (maybeOf SMask.allStyles)
        (subsetOf SMask.allModifiers)


auraFuzzer : Fuzzer AuraConfig
auraFuzzer =
    Fuzz.map2 (\style size -> { style = style, size = size })
        (maybeOf SAura.allStyles)
        (maybeOf SAura.allSizes)



-- LEAF FUZZERS --------------------------------------------------------------


badgeConfigFuzzer : Fuzzer BadgeConfig
badgeConfigFuzzer =
    Fuzz.map4 (\color style size tip -> { color = color, style = style, size = size, tooltip = tip })
        (maybeOf SBadge.allColors)
        (maybeOf SBadge.allStyles)
        (maybeOf SBadge.allSizes)
        (Fuzz.maybe tooltipFuzzer)


statusConfigFuzzer : Fuzzer StatusConfig
statusConfigFuzzer =
    Fuzz.map3 (\color size tip -> { color = color, size = size, tooltip = tip })
        (maybeOf SStatus.allColors)
        (maybeOf SStatus.allSizes)
        (Fuzz.maybe tooltipFuzzer)


{-| A button config plus the two fields an icon-only button needs. Split off
`plainButtonConfigFuzzer` because `Fuzz.map5` is the widest map there is and
the class groups already use all five.
-}
buttonConfigFuzzer : Fuzzer (ButtonConfig Msg)
buttonConfigFuzzer =
    Fuzz.map2
        (\base ( icon, aria ) -> { base | icon = icon, ariaLabel = aria })
        plainButtonConfigFuzzer
        (Fuzz.pair
            (Fuzz.maybe (Fuzz.oneOfValues DIcon.allIcons))
            (Fuzz.maybe (Fuzz.constant "View order"))
        )


plainButtonConfigFuzzer : Fuzzer (ButtonConfig Msg)
plainButtonConfigFuzzer =
    Fuzz.map5
        (\color style size modifiers behaviors ->
            { defaultButtonConfig
                | color = color
                , style = style
                , size = size
                , modifiers = modifiers
                , behaviors = behaviors
            }
        )
        (maybeOf allButtonColors)
        (maybeOf SButton.allStyles)
        (maybeOf SButton.allSizes)
        (subsetOf SButton.allModifiers)
        (subsetOf SButton.allBehaviors)


decoratedButtonFuzzer : Fuzzer (ButtonConfig Msg)
decoratedButtonFuzzer =
    Fuzz.map4
        (\config tip drop aura ->
            { config | tooltip = tip, dropdown = drop, aura = aura }
        )
        buttonConfigFuzzer
        (Fuzz.maybe tooltipFuzzer)
        (Fuzz.maybe dropdownFuzzer)
        (Fuzz.maybe auraFuzzer)


inputConfigFuzzer : Fuzzer (InputConfig Msg)
inputConfigFuzzer =
    Fuzz.map3
        (\base ( inputType, required, aria ) icon ->
            { base
                | inputType = inputType
                , required = required
                , ariaLabel = aria

                -- `icon` switches the whole element: `Just` wraps the control
                -- in a `<label class="input">` and leaves the `<input>` bare,
                -- so both shapes have to be explored.
                , icon = icon
            }
        )
        plainInputConfigFuzzer
        (Fuzz.triple
            (Fuzz.oneOfValues allInputTypes)
            Fuzz.bool
            (Fuzz.maybe (Fuzz.constant "Contact email"))
        )
        (Fuzz.maybe (Fuzz.oneOfValues DIcon.allIcons))


plainInputConfigFuzzer : Fuzzer (InputConfig Msg)
plainInputConfigFuzzer =
    Fuzz.map5
        (\color style size ind tip ->
            { defaultInputConfig | color = color, style = style, size = size, indicator = ind, tooltip = tip }
        )
        (maybeOf SInput.allColors)
        (maybeOf SInput.allStyles)
        (maybeOf SInput.allSizes)
        (Fuzz.maybe indicatorFuzzer)
        (Fuzz.maybe tooltipFuzzer)


{-| Every [`InputType`](Daisy-Tree#InputType). The type is closed, and
`Daisy.Tree` exposes no `allInputTypes`, so the list lives here.
-}
allInputTypes : List InputType
allInputTypes =
    [ InputText
    , InputEmail
    , InputPassword
    , InputNumber
    , InputUrl
    , InputTel
    , InputSearch
    , InputDate
    ]


{-| `Leaf.Icon` declares no class group at all — it emits no daisyUI class, like
`Leaf.Heading` — so there is nothing here for the exclusivity rule to make
contradictory. The fuzzer exists because the harness enumerates one entry per
leaf constructor, and it does sweep both closed fields (all three sizes, both
accessibility shapes) across all twenty-five drawings, which keeps the row
honest if an icon ever grows a group.
-}
iconConfigFuzzer : Fuzzer IconConfig
iconConfigFuzzer =
    Fuzz.map2 (\size label -> { size = size, label = label })
        (Fuzz.oneOfValues [ IconSm, IconMd, IconLg ])
        (Fuzz.maybe (Fuzz.constant "Notifications"))


selectConfigFuzzer : Fuzzer (SelectConfig Msg)
selectConfigFuzzer =
    Fuzz.map5
        (\color style size tip aria ->
            { defaultSelectConfig
                | color = color
                , style = style
                , size = size
                , tooltip = tip
                , ariaLabel = aria
            }
        )
        (maybeOf SSelect.allColors)
        (maybeOf SSelect.allStyles)
        (maybeOf SSelect.allSizes)
        (Fuzz.maybe tooltipFuzzer)
        (Fuzz.maybe (Fuzz.constant "Date range"))


{-| `calendar` has no exclusive group at all — one `component` class, no
`color`/`size`/`style`, no parts — so there is nothing for this row to make
contradictory. The fuzzer is here anyway because the harness enumerates one
entry per leaf constructor, and it does sweep the two closed fields the config
does have (locale, month count) across all three picker kinds, which is what
keeps the assertion honest if `calendar` ever grows a group.
-}
calendarLeafFuzzer : Fuzzer (Leaf Msg)
calendarLeafFuzzer =
    let
        today : Date.Date
        today =
            Date.fromCalendarDate 2026 Time.Sep 7

        configWith : CalendarLocale -> CalendarMonths -> CalendarConfig Msg
        configWith locale months =
            let
                base : CalendarConfig Msg
                base =
                    defaultCalendarConfig
                        { id = "calendar-fuzz"
                        , today = today
                        , toMsg = CalendarChanged
                        , onChange = Picked
                        }
            in
            { base | locale = locale, months = months }
    in
    Fuzz.map3
        (\locale months kind ->
            let
                config : CalendarConfig Msg
                config =
                    configWith locale months
            in
            Calendar config (kind config)
        )
        (Fuzz.oneOfValues [ EnGB, EnUS ])
        (Fuzz.oneOfValues [ OneMonth, TwoMonths ])
        (Fuzz.oneOfValues
            [ \config -> Render.initCalendarDate config (Just today)
            , \config -> Render.initCalendarRange config (Just ( today, Date.add Date.Days 3 today ))
            , \config -> Render.initCalendarMulti config [ today ]
            ]
        )


leafFuzzers : List ( String, Fuzzer (Leaf Msg) )
leafFuzzers =
    [ ( "avatar"
      , Fuzz.map4
            (\modifiers mask drop ind ->
                Avatar
                    { defaultAvatarConfig | modifiers = modifiers, mask = mask, dropdown = drop, indicator = ind }
                    "a.png"
            )
            (subsetOf SAvatar.allModifiers)
            (Fuzz.maybe maskFuzzer)
            (Fuzz.maybe dropdownFuzzer)
            (Fuzz.maybe indicatorFuzzer)
      )
    , ( "badge", Fuzz.map (\c -> Badge c "9") badgeConfigFuzzer )
    , ( "calendar", calendarLeafFuzzer )
    , ( "button", Fuzz.map (\c -> Button c "Go") decoratedButtonFuzzer )
    , ( "checkbox"
      , Fuzz.map3
            (\color size aria ->
                Checkbox { defaultCheckboxConfig | color = color, size = size, ariaLabel = aria }
            )
            (maybeOf SCheckbox.allColors)
            (maybeOf SCheckbox.allSizes)
            (Fuzz.maybe (Fuzz.constant "Agree"))
      )
    , ( "divider"
      , Fuzz.map3
            (\color direction placement ->
                Divider { defaultDividerConfig | color = color, direction = direction, placement = placement } (Just "or")
            )
            (maybeOf SDivider.allColors)
            (maybeOf SDivider.allDirections)
            (maybeOf SDivider.allPlacements)
      )
    , ( "file-input"
      , Fuzz.map4
            (\color style size aria ->
                FileInput
                    { defaultFileInputConfig
                        | color = color
                        , style = style
                        , size = size
                        , ariaLabel = aria
                    }
            )
            (maybeOf SFileInput.allColors)
            (maybeOf SFileInput.allStyles)
            (maybeOf SFileInput.allSizes)
            (Fuzz.maybe (Fuzz.constant "Avatar"))
      )
    , ( "icon"
      , Fuzz.map2 Icon iconConfigFuzzer (Fuzz.oneOfValues DIcon.allIcons)
      )
    , ( "image", Fuzz.map (\mask -> Image { defaultImageConfig | mask = Just mask } "a.png") maskFuzzer )
    , ( "input", Fuzz.map Input inputConfigFuzzer )
    , ( "user-chip"
      , Fuzz.map2
            (\boxed drop ->
                UserChip
                    { defaultUserChipConfig | boxed = boxed, dropdown = drop }
                    { avatar = "a.png", name = "Ada Lovelace", subtitle = "@ada" }
            )
            Fuzz.bool
            (Fuzz.maybe dropdownFuzzer)
      )
    , ( "join"
      , Fuzz.map3
            (\direction button config ->
                Join { defaultJoinConfig | direction = direction }
                    [ JoinButton button "one", JoinInput config, JoinText "of" ]
            )
            (maybeOf SJoin.allDirections)
            buttonConfigFuzzer
            inputConfigFuzzer
      )
    , ( "kbd", Fuzz.map (\size -> Kbd { defaultKbdConfig | size = size } "K") (maybeOf SKbd.allSizes) )
    , ( "link"
      , Fuzz.map3
            (\color style drop -> Link { defaultLinkConfig | color = color, style = style, dropdown = drop } "link")
            (maybeOf SLink.allColors)
            (maybeOf SLink.allStyles)
            (Fuzz.maybe dropdownFuzzer)
      )
    , ( "loading"
      , Fuzz.map2 (\style size -> Loading { defaultLoadingConfig | style = style, size = size })
            (maybeOf SLoading.allStyles)
            (maybeOf SLoading.allSizes)
      )
    , ( "megamenu"
      , Fuzz.map3
            (\size direction modifiers ->
                Megamenu
                    { defaultMegamenuConfig | size = size, direction = direction, modifiers = modifiers }
                    [ { label = "Products"
                      , active = True
                      , menu = { config = defaultMenuConfig, items = [ menuItem "Home" ] }
                      }
                    ]
            )
            (maybeOf SMegamenu.allSizes)
            (maybeOf SMegamenu.allDirections)
            (subsetOf SMegamenu.allModifiers)
      )
    , ( "otp"
      , Fuzz.map3
            (\color size modifiers ->
                Otp { defaultOtpConfig | color = color, size = size, modifiers = modifiers } { digits = 2 }
            )
            (maybeOf SOtp.allColors)
            (maybeOf SOtp.allSizes)
            (subsetOf SOtp.allModifiers)
      )
    , ( "progress"
      , Fuzz.map
            (\color -> Progress { defaultProgressConfig | color = color } { value = Just 40, max = 100 })
            (maybeOf SProgress.allColors)
      )
    , ( "radio"
      , Fuzz.map3
            (\color size aria ->
                Radio
                    { defaultRadioConfig | color = color, size = size, ariaLabel = aria }
                    { name = "r", checked = True }
            )
            (maybeOf SRadio.allColors)
            (maybeOf SRadio.allSizes)
            (Fuzz.maybe (Fuzz.constant "Plan"))
      )
    , ( "range"
      , Fuzz.map4
            (\color size direction aria ->
                Range
                    { defaultRangeConfig
                        | color = color
                        , size = size
                        , direction = direction
                        , ariaLabel = aria
                    }
                    { min = 0, max = 100, value = 50 }
            )
            (maybeOf SRange.allColors)
            (maybeOf SRange.allSizes)
            (maybeOf SRange.allDirections)
            (Fuzz.maybe (Fuzz.constant "Volume"))
      )
    , ( "rating"
      , Fuzz.map4
            (\size modifiers shape clearable ->
                Rating
                    { defaultRatingConfig | size = size, modifiers = modifiers, shape = shape }
                    { name = "r", count = 3, value = 2, clearable = clearable }
            )
            (maybeOf SRating.allSizes)
            (subsetOf allRatingModifiers)
            (maybeOf SMask.allStyles)
            Fuzz.bool
      )
    , ( "select"
      , Fuzz.map (\c -> Select c { options = [ "a", "b" ], selected = Just "a" }) selectConfigFuzzer
      )
    , ( "skeleton"
      , Fuzz.map (\modifiers -> Skeleton { defaultSkeletonConfig | modifiers = modifiers })
            (subsetOf SSkeleton.allModifiers)
      )
    , ( "status", Fuzz.map Status statusConfigFuzzer )
    , ( "swap"
      , Fuzz.map2
            (\style modifiers ->
                Swap { defaultSwapConfig | style = style, modifiers = modifiers }
                    { on = "ON", off = "OFF", indeterminate = Just "?" }
            )
            (maybeOf SSwap.allStyles)
            (subsetOf SSwap.allModifiers)
      )
    , ( "textarea"
      , Fuzz.map4
            (\color style size required ->
                Textarea
                    { defaultTextareaConfig
                        | color = color
                        , style = style
                        , size = size
                        , required = required
                    }
            )
            (maybeOf STextarea.allColors)
            (maybeOf STextarea.allStyles)
            (maybeOf STextarea.allSizes)
            Fuzz.bool
      )
    , ( "toggle"
      , Fuzz.map3
            (\color size aria ->
                Toggle
                    { defaultToggleConfig | color = color, size = size, ariaLabel = aria }
                    { checked = True }
            )
            (maybeOf SToggle.allColors)
            (maybeOf SToggle.allSizes)
            (Fuzz.maybe (Fuzz.constant "Dark mode"))
      )
    ]



-- BLOCK FUZZERS -------------------------------------------------------------


{-| One `card-body` child of each shape, so the fuzzer covers the block-shaped
ones as well as the leaves.
-}
cardChildren : List (CardChild Msg)
cardChildren =
    [ CardLeaf (Text "body")
    , CardAlert defaultAlertConfig [ Text "Saved" ]
    , CardChart Chart.Line { series = [], xLabels = [] }
    , CardTable defaultTableConfig [ { header = True, cells = [ tableCell (Text "Name") ] } ]
    , CardStat defaultStatConfig [ emptyStatItem "Downloads" "31K" ]
    , CardForm [ { legend = Just "Account", fields = [ field "Email" (Input defaultInputConfig) ] } ]
    ]


blockFuzzers : List ( String, Fuzzer (Block Msg) )
blockFuzzers =
    [ ( "accordion"
      , Fuzz.map
            (\modifiers ->
                Accordion { defaultAccordionConfig | modifiers = modifiers }
                    [ { title = "One", content = [ Text "first" ] } ]
            )
            (subsetOf SAccordion.allModifiers)
      )
    , ( "alert"
      , Fuzz.map3
            (\color style direction ->
                Alert { color = color, style = style, direction = direction } [ Text "Saved" ]
            )
            (maybeOf SAlert.allColors)
            (maybeOf SAlert.allStyles)
            (maybeOf SAlert.allDirections)
      )
    , ( "card"
      , Fuzz.map4
            (\style size modifiers aura ->
                Card
                    { style = style, size = size, modifiers = modifiers, aura = aura, hover3d = True }
                    { figure = Just (Image defaultImageConfig "a.png")
                    , title = Just "Title"
                    , titleIcon = Just DIcon.ChartBar
                    , headerTabs =
                        Just
                            { config = { style = Just STab.Box, size = Just STab.Xs, placement = Nothing }
                            , tabs =
                                [ { label = "Day", active = False, disabled = False, content = [] }
                                , { label = "Year", active = True, disabled = False, content = [] }
                                ]
                            }
                    , headerActions = [ Button defaultButtonConfig "Report" ]
                    , body = cardChildren
                    , actions = [ Button defaultButtonConfig "Buy" ]
                    }
            )
            (maybeOf SCard.allStyles)
            (maybeOf SCard.allSizes)
            (subsetOf SCard.allModifiers)
            (Fuzz.maybe auraFuzzer)
      )
    , ( "card body children"
      , Fuzz.map
            (\style ->
                Card
                    { defaultCardConfig | style = style }
                    { emptyCardParts | title = Just "Title", body = cardChildren }
            )
            (maybeOf SCard.allStyles)
      )
    , ( "carousel"
      , Fuzz.map3
            (\direction modifiers snap ->
                Carousel
                    { direction = direction, modifiers = modifiers, snap = snap }
                    [ { content = [ Image defaultImageConfig "a.png" ] } ]
            )
            (maybeOf SCarousel.allDirections)
            (subsetOf SCarousel.allModifiers)
            (maybeOf [ SnapStart, SnapCenter, SnapEnd ])
      )
    , ( "chat"
      , Fuzz.map2
            (\placement color ->
                Chat
                    [ { placement = placement
                      , color = color
                      , image = Just "a.png"
                      , header = Just "Obi-Wan"
                      , footer = Just "Seen"
                      , bubble = [ Text "Hello" ]
                      }
                    ]
            )
            (Fuzz.oneOfValues SChat.allPlacements)
            (maybeOf SChat.allColors)
      )
    , ( "collapse"
      , Fuzz.map
            (\modifiers ->
                Collapse { modifiers = modifiers } { title = "More", content = [ Text "details" ] }
            )
            (subsetOf SCollapse.allModifiers)
      )
    , ( "list"
      , Fuzz.map2
            (\grow wrap ->
                ListBlock
                    [ { cells =
                            [ listCell (Text "row")
                            , { content = Text "cell", grow = grow, wrap = wrap }
                            ]
                      }
                    ]
            )
            Fuzz.bool
            Fuzz.bool
      )
    , ( "menu"
      , Fuzz.map3
            (\size direction modifiers ->
                Menu { size = size, direction = direction, modifiers = modifiers }
                    [ menuItem "Home" ]
            )
            (maybeOf SMenu.allSizes)
            (maybeOf SMenu.allDirections)
            (subsetOf SMenu.allModifiers)
      )
    , ( "pagination"
      , Fuzz.map
            (\direction -> Pagination { direction = direction } { pages = [ "1", "2" ], active = 0 })
            (maybeOf SPagination.allDirections)
      )
    , ( "stacked"
      , Fuzz.map2
            (\modifiers align ->
                Stacked { modifiers = modifiers, align = align } [ Image defaultImageConfig "a.png" ]
            )
            (subsetOf SStack.allModifiers)
            (maybeOf [ StackedTop, StackedBottom, StackedStart, StackedEnd ])
      )
    , ( "stat"
      , Fuzz.map
            (\direction ->
                Stat { direction = direction }
                    [ { figure = Just (Loading defaultLoadingConfig)
                      , title = "Downloads"
                      , value = "31K"
                      , trend =
                            Just
                                (Badge
                                    { defaultBadgeConfig
                                        | color = Just SBadge.Success
                                        , style = Just SBadge.Soft
                                        , size = Just SBadge.Sm
                                    }
                                    "+10.8%"
                                )
                      , desc = Just "Jan 1st"
                      , actions = [ Button defaultButtonConfig "Details" ]
                      }
                    ]
            )
            (Fuzz.oneOf
                (Fuzz.constant Responsive
                    :: List.map (Fixed >> Fuzz.constant) (Nothing :: List.map Just SStat.allDirections)
                )
            )
      )
    , ( "steps"
      , Fuzz.map2
            (\direction color ->
                Steps { direction = direction } [ { label = "One", color = color, icon = Just "1" } ]
            )
            (maybeOf SSteps.allDirections)
            (maybeOf SSteps.allColors)
      )
    , ( "table"
      , Fuzz.map2
            (\size modifiers ->
                Table { size = size, modifiers = modifiers }
                    [ { header = True, cells = [ tableCell (Text "Name") ] }
                    , { header = False
                      , cells =
                            [ { leading = Just (Avatar defaultAvatarConfig "a.png")
                              , content = Text "Cy"
                              }
                            ]
                      }
                    ]
            )
            (maybeOf STable.allSizes)
            (subsetOf STable.allModifiers)
      )
    , ( "tabs"
      , Fuzz.map3
            (\style size placement ->
                Tabs { style = style, size = size, placement = placement }
                    [ { label = "Tab 1", active = True, disabled = False, content = [ Text "one" ] } ]
            )
            (maybeOf STab.allStyles)
            (maybeOf STab.allSizes)
            (maybeOf STab.allPlacements)
      )
    , ( "timeline"
      , Fuzz.map4
            (\direction modifiers startBox endBox ->
                Timeline { direction = direction, modifiers = modifiers }
                    [ { start = Just "1984"
                      , startBox = startBox
                      , middle = Just (Badge defaultBadgeConfig "ok")
                      , end = Just "First Macintosh"
                      , endBox = endBox
                      }
                    ]
            )
            (maybeOf STimeline.allDirections)
            (subsetOf allTimelineModifiers)
            Fuzz.bool
            Fuzz.bool
      )
    ]



-- SECTION, OVERLAY AND PAGE FUZZERS -----------------------------------------


sectionFuzzers : List ( String, Fuzzer (Section Msg) )
sectionFuzzers =
    [ ( "footer"
      , Fuzz.map2
            (\direction placement ->
                Footer { direction = direction, placement = placement }
                    [ Nav { title = Just "Services" } [ Link defaultLinkConfig "Branding" ] ]
            )
            (maybeOf SFooter.allDirections)
            (maybeOf SFooter.allPlacements)
      )
    ]


overlayFuzzers : List ( String, Fuzzer (Overlay Msg) )
overlayFuzzers =
    [ ( "modal"
      , Fuzz.map2
            (\placement modifiers ->
                Modal
                    { defaultModalConfig | placement = placement, modifiers = modifiers }
                    [ Prose [ Text "Are you sure?" ] ]
            )
            (maybeOf SModal.allPlacements)
            (subsetOf SModal.allModifiers)
      )
    , ( "drawer"
      , Fuzz.map2
            (\placement modifiers ->
                Drawer
                    { defaultDrawerConfig | placement = placement, modifiers = modifiers }
                    [ Stack defaultStackConfig [ Menu defaultMenuConfig [ menuItem "Home" ] ] ]
            )
            (maybeOf SDrawer.allPlacements)
            (subsetOf SDrawer.allModifiers)
      )
    , ( "toast"
      , Fuzz.map
            (\placement -> Toast { placement = placement } [ Alert defaultAlertConfig [ Text "Saved" ] ])
            (maybeOf SToast.allPlacements)
      )
    ]


pageFuzzer : Fuzzer (Page Msg)
pageFuzzer =
    Fuzz.map4
        (\theme dockSize fabModifiers ctaConfig ->
            Page
                { header =
                    Just
                        { title = "Overview"
                        , breadcrumbs = [ Link defaultLinkConfig "Acme", Text "Overview" ]
                        , actions = [ Button defaultButtonConfig "Export" ]
                        }
                , shell =
                    Dashboard
                        { brand = Just { icon = DIcon.Home, name = "Acme" }
                        , sidebar = { config = defaultMenuConfig, items = [ menuItem "Home" ] }
                        , sidebarFooter =
                            Just
                                (UserChip
                                    { defaultUserChipConfig | boxed = True }
                                    { avatar = "a.png", name = "Ada", subtitle = "@ada" }
                                )
                        , navbar = emptyNavbarParts
                        }
                , sections = Sections1 (Stack defaultStackConfig [ Prose [ Text "one" ] ])
                , cta = ctaConfig
                , overlays = []
                , theme = theme
                , dock =
                    Just
                        { config = { size = dockSize }
                        , items = [ { icon = Just "*", label = "Home", active = True, onClick = Nothing } ]
                        }
                , fab =
                    Just
                        { config = { modifiers = fabModifiers }
                        , main = Button defaultButtonConfig "+"
                        , mainAction = Just (Button defaultButtonConfig "Main")
                        , actions = [ Button defaultButtonConfig "A" ]
                        , close = Just (Button defaultButtonConfig "x")
                        }
                }
        )
        (Fuzz.oneOfValues allThemes)
        (maybeOf SDock.allSizes)
        (subsetOf SFab.allModifiers)
        ctaFuzzer


ctaFuzzer : Fuzzer (Cta Msg)
ctaFuzzer =
    Fuzz.map5
        (\size style modifiers behaviors icon ->
            let
                base =
                    cta "Save" Clicked
            in
            { base
                | size = size
                , style = style
                , modifiers = modifiers
                , behaviors = behaviors
                , icon = icon
            }
        )
        (maybeOf SButton.allSizes)
        (maybeOf SButton.allStyles)
        (subsetOf SButton.allModifiers)
        (subsetOf SButton.allBehaviors)
        (Fuzz.maybe (Fuzz.oneOfValues DIcon.allIcons))



-- SUITE ---------------------------------------------------------------------


suite : Test
suite =
    describe "one class per exclusive group per element"
        [ describe "leaves"
            (List.map (\( name, f ) -> fuzz f name (Render.leaf >> expectExclusive)) leafFuzzers)
        , describe "blocks"
            (List.map (\( name, f ) -> fuzz f name (Render.block >> expectExclusive)) blockFuzzers)
        , describe "sections"
            (List.map (\( name, f ) -> fuzz f name (Render.section >> expectExclusive)) sectionFuzzers)
        , describe "overlays"
            (List.map (\( name, f ) -> fuzz f name (Render.overlay >> expectExclusive)) overlayFuzzers)
        , fuzz pageFuzzer "page" (Render.page >> expectExclusive)
        , describe "coverage fixtures"
            (List.map
                (\( name, html ) -> test name (\_ -> expectExclusive html))
                Fixtures.groups
            )
        ]
