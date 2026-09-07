module Demo.Settings exposing (Config, currencies, retentionWindows, page)

{-| The form-heavy demo (SPEC.md step 7, row "Settings").

The same `Shell.Dashboard` and the same header band as `Demo.Admin`, then a
two-column grid of settings cards — each a `card-title`, a one-line
`description` and a `Form` of `Fieldset`s — a "Danger zone" card, a save bar,
and a `Modal` confirm overlay whose confirm button fires a message.

SPEC.md pins this demo to `Shell.Plain`. It is now `Dashboard`, and that
deviation is recorded in `docs/tree-decisions.md` ("Fixes from live review"):
the page is a workspace's settings screen inside the same console as the other
two demos, and on the plain shell it read as a floating navbar strip over a
loose form. `Shell.Plain` stays exercised — `tests/Helpers/Fixtures.elm` and
`tools/should-not-compile/` both build plain pages, and `e2e/layers.spec.ts`
reads the plain `<main>` — so nothing about it goes untested.

Everything SPEC.md asks this demo to exercise is still here: fieldsets, a
toggle, selects, a real `type="email" required` field with daisyUI's
`validator-hint`, exactly one primary CTA, and a modal confirm.

Like every `Demo.*` module this imports no `Html`.

@docs Config, currencies, retentionWindows, page

-}

import BasePath
import Daisy.Icon as Icon
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Button as SButton
import Daisy.Schema.Card as SCard
import Daisy.Schema.Input as SInput
import Daisy.Schema.Modal as SModal
import Daisy.Schema.Toggle as SToggle
import Daisy.Tree as Tree
    exposing
        ( Align(..)
        , Block(..)
        , CardChild(..)
        , DashboardShell
        , Field
        , Fieldset
        , FieldsetColumns(..)
        , IndicatorPayload(..)
        , InputType(..)
        , LabelPlacement(..)
        , Leaf(..)
        , MenuGlyph(..)
        , MenuItem(..)
        , MenuSpec
        , NavbarParts
        , Overlay(..)
        , Page(..)
        , Section(..)
        , Sections(..)
        , Shell(..)
        , Theme
        )


{-| What the settings page needs from the router.
-}
type alias Config msg =
    { basePath : String
    , theme : Theme
    , lastMsg : String
    , workspaceName : String
    , contactEmail : String
    , currency : String
    , retention : String
    , digest : Bool
    , anonymize : Bool
    , modalOpen : Bool
    , onNavigate : String -> msg
    , onTheme : Theme -> msg
    , onNotifications : msg
    , onWorkspaceName : String -> msg
    , onContactEmail : String -> msg
    , onCurrency : String -> msg
    , onRetention : String -> msg
    , onDigest : Bool -> msg
    , onAnonymize : Bool -> msg
    , onSave : msg
    , onDelete : msg
    , onConfirm : msg
    , onCancel : msg
    }


{-| The currencies the billing select offers. `Main` uses the head as the
initial value.
-}
currencies : List String
currencies =
    [ "USD — US dollar", "EUR — Euro", "GBP — Pound sterling", "JPY — Japanese yen" ]


{-| The retention windows the data select offers.
-}
retentionWindows : List String
retentionWindows =
    [ "30 days", "90 days", "12 months", "Keep forever" ]


{-| The whole settings screen as one `Page`.

`Cta.placement = InHeader`, so the single `btn-primary` sits at the right-hand
end of the title band — where Nexus's own settings page puts the action that
belongs to the whole screen. The save bar at the bottom carries the secondary
half of that pair ("Cancel"); it cannot carry the primary one, because the tree
allows exactly one and the shell decides where it goes.

-}
page : Config msg -> Page msg
page config =
    Page
        { header = Just headerBar
        , shell = Dashboard (dashboard config)
        , sections =
            Sections4
                (accountSection config)
                (dataSection config)
                (saveBarSection config)
                (footerSection config)
        , cta = saveCta config
        , overlays = [ confirmModal config ]
        , theme = config.theme
        , dock = Nothing
        , fab = Nothing
        }



-- SHELL ---------------------------------------------------------------------


{-| The same dashboard chrome the other two consoles carry: the brand, the two
labelled sidebar groups with `Settings` active, the signed-in user pinned to the
bottom of the panel, and the navbar.
-}
dashboard : Config msg -> DashboardShell msg
dashboard config =
    { brand = Just { icon = Icon.ChartBar, name = "Acme" }
    , sidebar = sidebar config
    , sidebarFooter = Just sidebarUser
    , navbar = navbar config
    , edges = True
    }


sidebar : Config msg -> MenuSpec msg
sidebar config =
    { config = sidebarMenuConfig
    , items =
        [ sectionTitle "Dashboards"
        , navItem "Overview" Icon.Home (href config "/") (config.onNavigate "/") False
        , navItem "Analytics" Icon.ChartBar (href config "/analytics") (config.onNavigate "/analytics") False
        , sectionTitle "Workspace"
        , navItem "Settings" Icon.Cog (href config "/settings") (config.onNavigate "/settings") True
        , sectionTitle "Tools"
        , navItem "Theme generator" Icon.Sun (href config "/theme") (config.onNavigate "/theme") False
        , docsItem config
        ]
    }


sidebarMenuConfig : Tree.MenuConfig
sidebarMenuConfig =
    { defaultMenu | activeStyle = Tree.TintedActive }


defaultMenu : Tree.MenuConfig
defaultMenu =
    Tree.defaultMenuConfig


{-| A `menu-title` row: it labels the group under it and is not a link.
-}
sectionTitle : String -> MenuItem msg
sectionTitle label =
    let
        (MenuItem base) =
            Tree.menuItem label
    in
    MenuItem { base | title = True }


{-| The generated documentation site, which lives beside the demo in
`dist/docs/` rather than being an Elm route. A plain link with no `onClick`, so
`Main.step` answers its `UrlRequest` with `Browser.Navigation.load`.
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


navItem : String -> Icon.Icon -> String -> msg -> Bool -> MenuItem msg
navItem label icon path onClick active =
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
        }


{-| A route as it must appear in an `href`: the demo's own path with the
deployment's base path in front of it.
-}
href : Config msg -> String -> String
href config path =
    BasePath.join config.basePath path


{-| `navbar-center` stays empty: daisyUI fixes the two halves at 50% each, so
anything between them has no width to shrink into at 375.
-}
navbar : Config msg -> NavbarParts msg
navbar config =
    { start = []
    , center = []
    , end = [ themeSwitcher config, notificationsButton config, navbarUser ]
    }


themeSwitcher : Config msg -> Leaf msg
themeSwitcher config =
    ThemeSelect
        { themes = Tree.allThemes
        , current = config.theme
        , presentation = Tree.ThemeAsIconDropdown
        , onSelect = Just config.onTheme
        }


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


navbarUser : Leaf msg
navbarUser =
    UserChip defaultUserChip { avatar = avatarSrc, name = "Denish N", subtitle = "Team" }


sidebarUser : Leaf msg
sidebarUser =
    UserChip
        { defaultUserChip | boxed = True }
        { avatar = avatarSrc, name = "Denish N", subtitle = "@withden" }


defaultUserChip : Tree.UserChipConfig msg
defaultUserChip =
    Tree.defaultUserChipConfig


{-| The same inline `data:` portrait the other demos use, so the theme
screenshots need no network.
-}
avatarSrc : String
avatarSrc =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2040%2040'%3E"
        ++ "%3Crect%20width='40'%20height='40'%20fill='slateblue'/%3E"
        ++ "%3Ccircle%20cx='20'%20cy='16'%20r='7'%20fill='white'/%3E"
        ++ "%3Cpath%20d='M7%2040c0-7.2%205.8-12%2013-12s13%204.8%2013%2012z'%20fill='white'/%3E%3C/svg%3E"



-- SECTIONS ------------------------------------------------------------------


{-| The title band, rendered by the shell above the sections rather than
costing one — the same band `Demo.Admin` and `Demo.Analytics` carry.
-}
headerBar : Tree.PageHeader msg
headerBar =
    let
        base : Tree.PageHeader msg
        base =
            Tree.pageHeader "Workspace settings"
    in
    { base
        | breadcrumbs =
            [ Link { defaultLink | href = "#" } "Acme"
            , Text "Workspace"
            , Text "Settings"
            ]
    }


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig


{-| The first row of the card grid: who the workspace belongs to, and what it
sends.
-}
accountSection : Config msg -> Section msg
accountSection config =
    gridSection Tree.Cols2
        [ settingsCard "Workspace"
            "The name and the address every export, invoice and alert is sent from."
            [ workspaceFieldset config ]
        , settingsCard "Notifications"
            "What Acme sends, and in which currency it is priced."
            [ notificationFieldset config ]
        ]


{-| The second row: what is kept, and what can be destroyed.
-}
dataSection : Config msg -> Section msg
dataSection config =
    gridSection Tree.Cols2
        [ settingsCard "Privacy"
            "How long raw events live, and whether visitor addresses are stored at all."
            [ dataFieldset config ]
        , dangerCard config
        ]


{-| A settings panel: a `card-title`, the one line under it that says what the
panel is for, and a `Form`.

The description is `CardParts.description`, not a leaf at the top of the body:
that is what keeps it directly under the title and in the caption colour, on
every card, without any of them saying so.

-}
settingsCard : String -> String -> List (Fieldset msg) -> Block msg
settingsCard title description fieldsets =
    Card borderedCard
        { emptyCard
            | title = Just title
            , description = Just description
            , body = [ CardForm fieldsets ]
        }


emptyCard : Tree.CardParts msg
emptyCard =
    Tree.emptyCardParts


{-| `card-border`. `Daisy.Render` paints every card `bg-base-100 shadow-sm` on
the `bg-base-200` content ground, so a card already reads as its own panel; the
border is what daisyUI's dashboard examples add on top.
-}
borderedCard : Tree.CardConfig
borderedCard =
    { defaultCard | style = Just SCard.Border }


{-| Every panel on this page carries the 20px `card-body` gutter daisyUI's own
dashboard templates set, which is `CardPadding.PaddingDashboard`.
-}
defaultCard : Tree.CardConfig
defaultCard =
    { baseCard | padding = Tree.PaddingDashboard }


baseCard : Tree.CardConfig
baseCard =
    Tree.defaultCardConfig


{-| The name and the contact address, side by side.

`FieldsetColumns.Columns2`: two text fields in a half-width card is the shape
every settings page has, and stacking them made the card twice as tall as the
one beside it. It drops back to one column below `sm`, so the 375 layout is
unchanged.

-}
workspaceFieldset : Config msg -> Fieldset msg
workspaceFieldset config =
    { legend = Nothing
    , columns = Columns2
    , fields =
        [ Tree.field "Workspace name"
            (Input
                { defaultInput
                    | placeholder = "Acme Inc"
                    , value = config.workspaceName
                    , required = True
                    , minLength = Just 2
                    , maxLength = Just 60
                    , onInput = Just config.onWorkspaceName
                }
            )
        , validatedField "Contact email"
            "Enter an address we can actually reach, e.g. ops@acme.test"
            (Input
                { defaultInput
                    | color = Just SInput.Info
                    , placeholder = "ops@acme.test"
                    , value = config.contactEmail
                    , inputType = InputEmail
                    , required = True
                    , onInput = Just config.onContactEmail
                }
            )
        ]
    }


notificationFieldset : Config msg -> Fieldset msg
notificationFieldset config =
    { legend = Nothing
    , columns = OneColumn
    , fields =
        [ toggleRow "Weekly email digest"
            (Toggle
                { defaultToggle
                    | color = Just SToggle.Success
                    , onCheck = Just config.onDigest
                }
                { checked = config.digest }
            )
        , Tree.field "Billing currency"
            (Select
                { defaultSelect | onSelect = Just config.onCurrency }
                { options = currencies, selected = Just config.currency }
            )
        ]
    }


dataFieldset : Config msg -> Fieldset msg
dataFieldset config =
    { legend = Nothing
    , columns = OneColumn
    , fields =
        [ Tree.field "Keep raw events for"
            (Select
                { defaultSelect | onSelect = Just config.onRetention }
                { options = retentionWindows, selected = Just config.retention }
            )
        , toggleRow "Anonymise visitor addresses"
            (Toggle
                { defaultToggle | onCheck = Just config.onAnonymize }
                { checked = config.anonymize }
            )
        ]
    }


validatedField : String -> String -> Leaf msg -> Field msg
validatedField label hint control =
    let
        base : Field msg
        base =
            Tree.field label control
    in
    { base | validate = True, hint = Just hint }


{-| A switch row: the setting's name on the left, the toggle hard against the
right edge, both inside a bordered box.

`LabelPlacement.LabelRow`. It was `LabelEnd` — control first, label after it —
which is daisyUI's shape for a checkbox in a sentence and reads as a stray
switch in a column of stacked fields.

-}
toggleRow : String -> Leaf msg -> Field msg
toggleRow label control =
    let
        base : Field msg
        base =
            Tree.field label control
    in
    { base | labelPlacement = LabelRow }


{-| The danger zone: what the destructive action does, and the action.

A quiet card with one loud button in it, not the full-width solid `alert` this
used to open with. A red band across the page is the shape of something that has
already _gone wrong_; deleting a workspace is a control the reader may never
touch, so the warning is the card's `description` and the danger is in the
button.

The button is **solid** `btn-error` rather than `btn-outline btn-error`, and
that is the one place this card does not follow the live-review note. An
outlined one paints `--color-error` as a _foreground_ on `--color-base-100`,
which is 2.86:1 in the stock `light` theme — `e2e/contrast.spec.ts`'s composed
row and axe's `color-contrast` both fail it, and neither waiver covers it
(they cover daisyUI's own `--color-X` under `--color-X-content` pair, which is
exactly what the solid button is). It is the same reason `Demo.ThemeGenerator`'s
link back to daisyUI is a plain `link` and not `link-primary`.

The action is deliberately not primary: `Page.cta` ("Save changes") is the
page's only `btn-primary`, which the type system enforces — `Leaf.Button`'s
colour type has no `Primary`.

-}
dangerCard : Config msg -> Block msg
dangerCard config =
    Card borderedCard
        { emptyCard
            | title = Just "Danger zone"
            , description = Just "Deleting the workspace removes every event, export and invoice. This cannot be undone."
            , body =
                [ CardLeaf
                    (Text "Saving asks for confirmation first: retention changes delete history permanently.")
                ]
            , actions =
                [ Button
                    { defaultButton
                        | icon = Just Icon.Trash
                        , color = Just Tree.Error
                        , onClick = Just config.onDelete
                    }
                    "Delete workspace"
                ]
        }


{-| The save bar: what saving will do, and the way out of it.

The primary half of the pair is `Page.cta`, which the `Dashboard` shell draws in
the header band (`CtaPlacement.InHeader`); a page has exactly one primary
button and the shell decides where it goes, so this row carries the cancel.

-}
saveBarSection : Config msg -> Section msg
saveBarSection config =
    Stack { align = AlignStretch }
        [ Card borderedCard
            { emptyCard
                | title = Just "Save"
                , description = Just "Changes apply to every member of this workspace, and the confirm dialog says what they cost."
                , actions =
                    [ Button
                        { defaultButton | style = Just SButton.Ghost, onClick = Just config.onCancel }
                        "Discard changes"
                    ]
            }
        ]


{-| The last section. `AlignStart`, which is `defaultStackConfig`.
-}
footerSection : Config msg -> Section msg
footerSection config =
    Stack Tree.defaultStackConfig
        [ debugPane config ]


{-| The page CTA, with a leading `Check` glyph, in the header band beside the
title.
-}
saveCta : Config msg -> Tree.Cta msg
saveCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Save changes" config.onSave
    in
    { base
        | icon = Just Icon.Check
        , size = Just SButton.Sm
        , placement = Tree.InHeader
    }


{-| The debug pane the Tier C "interaction" spec reads. Same convention on
every demo: exactly `last-msg: <constructor name of the last Msg handled>`.
-}
debugPane : Config msg -> Block msg
debugPane config =
    Prose [ Text ("last-msg: " ++ config.lastMsg) ]



-- OVERLAY -------------------------------------------------------------------


{-| The confirm overlay. It is always in `Page.overlays` so the DOM node is
stable; `modal-open` is what makes it visible, and the confirm button fires
`onConfirm`. `onClose` catches the browser's own dismissal (the `Escape` key
on the native `<dialog>`) and reports it as `onCancel`.
-}
confirmModal : Config msg -> Overlay msg
confirmModal config =
    Modal
        { defaultModal
            | id = "confirm-save"
            , title = Just "Apply these settings?"
            , onClose = Just config.onCancel
            , modifiers =
                if config.modalOpen then
                    [ SModal.Open ]

                else
                    []
            , actions =
                [ Button
                    { defaultButton
                        | style = Just SButton.Ghost
                        , onClick = Just config.onCancel
                    }
                    "Cancel"
                , Button
                    { defaultButton
                        | color = Just Tree.Success
                        , onClick = Just config.onConfirm
                    }
                    "Apply changes"
                ]
        }
        [ Prose
            [ Text "Retention drops to the window you chose and cannot be undone." ]
        ]


defaultModal : Tree.ModalConfig msg
defaultModal =
    Tree.defaultModalConfig


defaultInput : Tree.InputConfig msg
defaultInput =
    Tree.defaultInputConfig


defaultSelect : Tree.SelectConfig msg
defaultSelect =
    Tree.defaultSelectConfig


defaultToggle : Tree.ToggleConfig msg
defaultToggle =
    Tree.defaultToggleConfig


defaultButton : Tree.ButtonConfig msg
defaultButton =
    Tree.defaultButtonConfig


{-| A `Section.Grid` of equal columns.
-}
gridSection : Tree.GridColumns -> List (Block msg) -> Section msg
gridSection columns blocks =
    Grid (Tree.Columns { columns = columns } blocks)
