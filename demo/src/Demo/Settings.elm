module Demo.Settings exposing (Config, currencies, retentionWindows, page)

{-| The form-heavy demo (SPEC.md step 7, row "Settings").

Plain shell, two `Card`s each holding a `Form` of `Fieldset`s carrying toggles,
selects and inputs (one of them a real `type="email" required` field, so
daisyUI's `validator-hint` can actually show), the page's single primary CTA,
and a `Modal` confirm overlay whose confirm button fires a message.

Section titles are `Leaf.Heading` leaves inside `Prose` plus each card's
`card-title` (an `<h2>`), which gives the page its document outline.

Like every `Demo.*` module this imports no `Html`.

@docs Config, currencies, retentionWindows, page

-}

import BasePath
import Daisy.Icon as Icon
import Daisy.Schema.Alert as SAlert
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
        , Field
        , Fieldset
        , HeadingLevel(..)
        , InputType(..)
        , LabelPlacement(..)
        , Leaf(..)
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

The shell is `Plain`, so `Daisy.Render` places the CTA at the end of the last
section rather than in a navbar. That is why the warning band and the footer
are two sections rather than one: the warning wants `AlignStretch` to fill the
band, and a stretched _last_ section would stretch the CTA across the page.

-}
page : Config msg -> Page msg
page config =
    Page
        { header = Just headerBar
        , shell = Plain
        , sections =
            Sections4
                (navSection config)
                (formsSection config)
                (dangerSection config)
                (footerSection config)
        , cta = saveCta config
        , overlays = [ confirmModal config ]
        , theme = config.theme
        , dock = Nothing
        , fab = Nothing
        }



-- SECTIONS ------------------------------------------------------------------


{-| `Shell.Plain` draws no navbar, so the cross-demo navigation is a `Navbar`
section instead. These are real `Link` leaves with an `href`, so
`Browser.application` intercepts the click as a `UrlRequest`.
-}
navSection : Config msg -> Section msg
navSection config =
    Navbar (navbarParts config)


navbarParts : Config msg -> NavbarParts msg
navbarParts config =
    { start = [ Text "Acme Console" ]
    , center = []
    , end =
        [ navLink config "Overview" "/"
        , navLink config "Analytics" "/analytics"
        , navLink config "Theme" "/theme"
        ]
    }


{-| A cross-demo link. The `href` carries the deployment's base path in front
of the demo's own route (`/` locally, `/elm-daisyui/` on GitHub Pages), which
is what `BasePath.join` adds.
-}
navLink : Config msg -> String -> String -> Leaf msg
navLink config label url =
    Link { defaultLink | href = BasePath.join config.basePath url } label


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig


{-| The same title band the two dashboards carry, rendered by the shell above
the sections.

SPEC.md pins this demo to `Shell.Plain`, so it keeps its own `Navbar` section
for cross-demo navigation; everything below that — the header row, the `text-sm`
content density, the `gap-6` rhythm between bands and the card sizing — is the
shell's, shared with `Demo.Admin` and `Demo.Analytics`.

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


{-| The two form groups, each in a `Card`. The `card-title` is the group's
heading (`Daisy.Render` draws it as an `<h2>`), which is also why no `Prose`
heading sits on top: a `Prose` block in a two-column grid would take one of the
two cells, and the card already carries the rank.
-}
formsSection : Config msg -> Section msg
formsSection config =
    Grid { columns = Tree.Cols2 }
        [ formCard "General"
            [ workspaceFieldset config
            , notificationFieldset config
            ]
        , formCard "Privacy"
            [ dataFieldset config ]
        ]


formCard : String -> List (Fieldset msg) -> Block msg
formCard title fieldsets =
    Card borderedCard
        { emptyCard | title = Just title, body = [ CardForm fieldsets ] }


emptyCard : Tree.CardParts msg
emptyCard =
    Tree.emptyCardParts


{-| `card-border`. `Daisy.Render` paints every card `bg-base-100 shadow-sm` on
the `bg-base-200` page ground, so a card already reads as its own panel; the
border is what daisyUI's dashboard examples add on top.
-}
borderedCard : Tree.CardConfig
borderedCard =
    { defaultCard | style = Just SCard.Border }


defaultCard : Tree.CardConfig
defaultCard =
    Tree.defaultCardConfig


workspaceFieldset : Config msg -> Fieldset msg
workspaceFieldset config =
    { legend = Just "Workspace"
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
    { legend = Just "Notifications"
    , fields =
        [ toggleField "Weekly email digest"
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
    { legend = Just "Data retention"
    , fields =
        [ Tree.field "Keep raw events for"
            (Select
                { defaultSelect | onSelect = Just config.onRetention }
                { options = retentionWindows, selected = Just config.retention }
            )
        , toggleField "Anonymise visitor addresses"
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


toggleField : String -> Leaf msg -> Field msg
toggleField label control =
    let
        base : Field msg
        base =
            Tree.field label control
    in
    { base | labelPlacement = LabelEnd }


{-| The danger zone, on its own so it can stretch. An `AlignStart` stack shrinks
a `Card` to its content width; `AlignStretch` fills the band.

The card holds an error `Alert` as a `CardAlert` child — the same helper
`Block.Alert` renders, so an alert in a card and a bare alert are one markup —
and a destructive `Trash` action in `card-actions`. The action is deliberately
**not** primary: `Page.cta` ("Save changes") is the page's only `btn-primary`,
which the type system enforces (`Leaf.Button`'s colour type has no `Primary`).

-}
dangerSection : Config msg -> Section msg
dangerSection config =
    Stack { align = AlignStretch }
        [ Card borderedCard
            { emptyCard
                | title = Just "Danger zone"
                , body =
                    [ CardAlert
                        { color = Just SAlert.Error, style = Nothing, direction = Nothing }
                        [ Text "Deleting the workspace removes every event, export and invoice. This cannot be undone." ]
                    , CardLeaf
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
        ]


{-| The last section, and it deliberately keeps `AlignStart`. With `Shell.Plain`
the renderer appends the page CTA to the _last section's_ container, so a
stretched stack (or a one-column `Grid`) here would stretch the single primary
button across the whole page.
-}
footerSection : Config msg -> Section msg
footerSection config =
    Stack Tree.defaultStackConfig
        [ debugPane config ]


{-| The page CTA, with a leading `Check` glyph.
-}
saveCta : Config msg -> Tree.Cta msg
saveCta config =
    let
        base : Tree.Cta msg
        base =
            Tree.cta "Save changes" config.onSave
    in
    { base | icon = Just Icon.Check }


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
