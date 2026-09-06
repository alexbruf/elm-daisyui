module Main exposing (main)

{-| The demo router.

`Browser.application` over three routes — `/` (Admin), `/analytics`,
`/settings` — sharing one model. Everything the three demos render comes from
`Daisy.Tree`; this module only holds state and turns it into a `Page`.

Conventions the Tier C specs rely on:

  - **Theme.** `?theme=<name>` on any URL sets the initial theme; `<name>` is
    any of the 35 values `Daisy.Tree.themeToString` produces. The navbar
    switcher writes the same field, so a theme chosen on one demo survives
    navigation to the others.
  - **Debug pane.** Every demo renders a `Prose` block whose text is
    `last-msg: <Name>`, where `<Name>` is the constructor name of the last
    `Msg` `update` handled (`none` before the first one). It is expressed in
    the tree like everything else, because `demo/src` may not import
    `Html.Attributes`.

This module imports no `Html` at all: `Browser.Document` gives the `view`
signature and `Daisy.Render.page` produces the body.

-}

import Browser
import Browser.Navigation as Nav
import Daisy.Render
import Daisy.Tree as Tree exposing (Theme(..))
import Demo.Admin
import Demo.Analytics
import Demo.Settings
import Process
import Task
import Url



-- MAIN ----------------------------------------------------------------------


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }



-- ROUTE ---------------------------------------------------------------------


type Route
    = AdminRoute
    | AnalyticsRoute
    | SettingsRoute


routeFromUrl : Url.Url -> Route
routeFromUrl url =
    case normalisePath url.path of
        "/analytics" ->
            AnalyticsRoute

        "/settings" ->
            SettingsRoute

        _ ->
            AdminRoute


normalisePath : String -> String
normalisePath path =
    if String.endsWith "/" path && String.length path > 1 then
        String.dropRight 1 path

    else
        path


{-| `?theme=<name>` wins over the default, for any of the 35 themes.
-}
themeFromUrl : Url.Url -> Theme
themeFromUrl url =
    url.query
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.filterMap themeFromPair
        |> List.head
        |> Maybe.withDefault Light


themeFromPair : String -> Maybe Theme
themeFromPair pair =
    case String.split "=" pair of
        [ key, value ] ->
            if key == "theme" then
                themeByName value

            else
                Nothing

        _ ->
            Nothing


themeByName : String -> Maybe Theme
themeByName name =
    Tree.allThemes
        |> List.filter (\theme -> Tree.themeToString theme == name)
        |> List.head



-- MODEL ---------------------------------------------------------------------


type alias Model =
    { key : Nav.Key
    , route : Route
    , theme : Theme
    , lastMsg : String
    , toastVisible : Bool
    , modalOpen : Bool
    , dateRange : String
    , workspaceName : String
    , contactEmail : String
    , currency : String
    , retention : String
    , digest : Bool
    , anonymize : Bool
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , route = routeFromUrl url
      , theme = themeFromUrl url
      , lastMsg = "none"
      , toastVisible = False
      , modalOpen = False
      , dateRange = firstOr "Last 30 days" (List.drop 1 Demo.Analytics.dateRanges)
      , workspaceName = "Acme Inc"
      , contactEmail = "ops@acme.test"
      , currency = firstOr "USD" Demo.Settings.currencies
      , retention = firstOr "90 days" (List.drop 1 Demo.Settings.retentionWindows)
      , digest = True
      , anonymize = False
      }
    , Cmd.none
    )


firstOr : String -> List String -> String
firstOr fallback list =
    Maybe.withDefault fallback (List.head list)



-- UPDATE --------------------------------------------------------------------


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | NavigateTo String
    | ThemeChanged Theme
    | ExportClicked
    | ToastDismissed
    | OrderViewed String
    | RangeSelected String
    | DownloadClicked
    | WorkspaceNameChanged String
    | ContactEmailChanged String
    | CurrencySelected String
    | RetentionSelected String
    | DigestToggled Bool
    | AnonymizeToggled Bool
    | SaveClicked
    | ModalConfirmed
    | ModalCancelled


{-| The constructor name of a `Msg`, for the debug pane. Payloads are left off
so the pane's text is exactly one stable token per constructor.
-}
msgName : Msg -> String
msgName msg =
    case msg of
        UrlRequested _ ->
            "UrlRequested"

        UrlChanged _ ->
            "UrlChanged"

        NavigateTo _ ->
            "NavigateTo"

        ThemeChanged _ ->
            "ThemeChanged"

        ExportClicked ->
            "ExportClicked"

        ToastDismissed ->
            "ToastDismissed"

        OrderViewed _ ->
            "OrderViewed"

        RangeSelected _ ->
            "RangeSelected"

        DownloadClicked ->
            "DownloadClicked"

        WorkspaceNameChanged _ ->
            "WorkspaceNameChanged"

        ContactEmailChanged _ ->
            "ContactEmailChanged"

        CurrencySelected _ ->
            "CurrencySelected"

        RetentionSelected _ ->
            "RetentionSelected"

        DigestToggled _ ->
            "DigestToggled"

        AnonymizeToggled _ ->
            "AnonymizeToggled"

        SaveClicked ->
            "SaveClicked"

        ModalConfirmed ->
            "ModalConfirmed"

        ModalCancelled ->
            "ModalCancelled"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( updated, command ) =
            step msg model
    in
    ( { updated | lastMsg = msgName msg }, command )


step : Msg -> Model -> ( Model, Cmd Msg )
step msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            ( { model | route = routeFromUrl url }, Cmd.none )

        NavigateTo path ->
            ( model, Nav.pushUrl model.key path )

        ThemeChanged theme ->
            ( { model | theme = theme }, Cmd.none )

        ExportClicked ->
            ( { model | toastVisible = True }
            , Task.perform (\_ -> ToastDismissed) (Process.sleep 3000)
            )

        ToastDismissed ->
            ( { model | toastVisible = False }, Cmd.none )

        OrderViewed _ ->
            ( model, Cmd.none )

        RangeSelected range ->
            ( { model | dateRange = range }, Cmd.none )

        DownloadClicked ->
            ( model, Cmd.none )

        WorkspaceNameChanged name ->
            ( { model | workspaceName = name }, Cmd.none )

        ContactEmailChanged email ->
            ( { model | contactEmail = email }, Cmd.none )

        CurrencySelected currency ->
            ( { model | currency = currency }, Cmd.none )

        RetentionSelected retention ->
            ( { model | retention = retention }, Cmd.none )

        DigestToggled on ->
            ( { model | digest = on }, Cmd.none )

        AnonymizeToggled on ->
            ( { model | anonymize = on }, Cmd.none )

        SaveClicked ->
            ( { model | modalOpen = True }, Cmd.none )

        ModalConfirmed ->
            ( { model | modalOpen = False }, Cmd.none )

        ModalCancelled ->
            ( { model | modalOpen = False }, Cmd.none )



-- VIEW ----------------------------------------------------------------------


view : Model -> Browser.Document Msg
view model =
    { title = title model.route
    , body = [ Daisy.Render.page (pageFor model) ]
    }


title : Route -> String
title route =
    case route of
        AdminRoute ->
            "Acme Console — Overview"

        AnalyticsRoute ->
            "Acme Console — Analytics"

        SettingsRoute ->
            "Acme Console — Settings"


pageFor : Model -> Tree.Page Msg
pageFor model =
    case model.route of
        AdminRoute ->
            Demo.Admin.page
                { theme = model.theme
                , lastMsg = model.lastMsg
                , toastVisible = model.toastVisible
                , onNavigate = NavigateTo
                , onTheme = ThemeChanged
                , onExport = ExportClicked
                , onRowAction = OrderViewed
                }

        AnalyticsRoute ->
            Demo.Analytics.page
                { theme = model.theme
                , lastMsg = model.lastMsg
                , dateRange = model.dateRange
                , onNavigate = NavigateTo
                , onRangeSelect = RangeSelected
                , onDownload = DownloadClicked
                }

        SettingsRoute ->
            Demo.Settings.page
                { theme = model.theme
                , lastMsg = model.lastMsg
                , workspaceName = model.workspaceName
                , contactEmail = model.contactEmail
                , currency = model.currency
                , retention = model.retention
                , digest = model.digest
                , anonymize = model.anonymize
                , modalOpen = model.modalOpen
                , onWorkspaceName = WorkspaceNameChanged
                , onContactEmail = ContactEmailChanged
                , onCurrency = CurrencySelected
                , onRetention = RetentionSelected
                , onDigest = DigestToggled
                , onAnonymize = AnonymizeToggled
                , onSave = SaveClicked
                , onConfirm = ModalConfirmed
                , onCancel = ModalCancelled
                }
