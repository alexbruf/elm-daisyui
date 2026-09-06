module Demo.Settings exposing (Config, currencies, retentionWindows, page)

{-| The form-heavy demo (SPEC.md step 7, row "Settings").

Plain shell, two `Form` blocks made of `Fieldset`s carrying toggles, selects
and inputs (one of them validated), the page's single primary CTA, and a
`Modal` confirm overlay whose confirm button fires a message.

Like every `Demo.*` module this imports no `Html`.

@docs Config, currencies, retentionWindows, page

-}

import Daisy.Schema.Alert as SAlert
import Daisy.Schema.Button as SButton
import Daisy.Schema.Input as SInput
import Daisy.Schema.Modal as SModal
import Daisy.Schema.Toggle as SToggle
import Daisy.Tree as Tree
    exposing
        ( Block(..)
        , Field
        , Fieldset
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
    { theme : Theme
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
section rather than in a navbar.

-}
page : Config msg -> Page msg
page config =
    Page
        { shell = Plain
        , sections =
            Sections4
                navSection
                headerSection
                (formsSection config)
                (footerSection config)
        , cta = Tree.cta "Save changes" config.onSave
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
navSection : Section msg
navSection =
    Navbar navbarParts


navbarParts : NavbarParts msg
navbarParts =
    { start = [ Text "Acme Console" ]
    , center = []
    , end =
        [ navLink "Overview" "/"
        , navLink "Analytics" "/analytics"
        ]
    }


navLink : String -> String -> Leaf msg
navLink label url =
    Link { defaultLink | href = url } label


defaultLink : Tree.LinkConfig msg
defaultLink =
    Tree.defaultLinkConfig


headerSection : Section msg
headerSection =
    Stack Tree.defaultStackConfig
        [ Prose
            [ Text "Workspace settings apply to everyone on the Acme account." ]
        ]


formsSection : Config msg -> Section msg
formsSection config =
    Grid { columns = Tree.Cols2 }
        [ Form
            [ workspaceFieldset config
            , notificationFieldset config
            ]
        , Form
            [ dataFieldset config ]
        ]


workspaceFieldset : Config msg -> Fieldset msg
workspaceFieldset config =
    { legend = Just "Workspace"
    , fields =
        [ Tree.field "Workspace name"
            (Input
                { defaultInput
                    | placeholder = "Acme Inc"
                    , value = config.workspaceName
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


{-| A `Stack`, not a one-column `Grid`. With `Shell.Plain` the renderer appends
the page CTA to the _last section's_ container, so a `Grid` here would stretch
the CTA across the whole band.
-}
footerSection : Config msg -> Section msg
footerSection config =
    Stack Tree.defaultStackConfig
        [ Alert
            { color = Just SAlert.Warning, style = Nothing, direction = Nothing }
            [ Text "Saving asks for confirmation: retention changes delete history permanently." ]
        , debugPane config
        ]


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
