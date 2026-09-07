module Main exposing (main)

{-| The demo router.

`Browser.application` over four routes — `/` (Admin), `/analytics`,
`/settings`, `/theme` (the theme generator) — sharing one model. Everything the
four demos render comes from
`Daisy.Tree`; this module only holds state and turns it into a `Page`.

Conventions the Tier C specs rely on:

  - **Theme.** `?theme=<name>` on any URL sets the initial theme; `<name>` is
    any of the 35 values `Daisy.Tree.themeToString` produces, or `acme`, the
    demo's own `Daisy.Tree.Theme.Custom` (`Demo.Themes.acme`) and the default.
    The navbar switcher and the `/theme` editor write the same field, so a
    theme chosen or built on one demo survives navigation to the others.

  - **Ports.** `demo/src/Ports.elm` holds all three, implemented in
    `demo/src/main.js`: the clipboard, and the request/response pair that turns
    the edited theme into daisyUI's own `#theme=` hash. `ThemeLinkReady` is the
    second `paneName` exception, for the same reason `CalendarMsg` is: it
    arrives from JavaScript after the `ThemeEdited` that caused it, so stamping
    it would make every `last-msg:` assertion on `/theme` racy.

  - **Debug pane.** Every demo renders a `Prose` block whose text is
    `last-msg: <Name>`, where `<Name>` is the constructor name of the last
    `Msg` `update` handled (`none` before the first one). It is expressed in
    the tree like everything else, because `demo/src` may not import
    `Html.Attributes`.

    One constructor is deliberately invisible to it: `CalendarMsg`, the
    picker's own internal traffic. `Daisy.Render.updateCalendar` batches the
    `onChange` callback with the `Browser.Dom.focus` call the roving
    `tabindex` needs, and that focus task comes back as another `CalendarMsg`
    — arriving _after_ `DateRangeChanged` about half the time. Stamping it
    would make the pane say "CalendarMsg" for every calendar-driven change and
    make the assertion racy, so `paneName` reports the last message the
    application acted on rather than the last one the runtime delivered.

  - **Base path.** The demo is served from `/` locally and from
    `/elm-daisyui/` on GitHub Pages. Vite's `base` reaches the bundle as
    `import.meta.env.BASE_URL` and `demo/src/main.js` passes it in as the
    `basePath` flag; `BasePath.strip` takes it off an incoming `Url` before
    routing and `BasePath.join` puts it back on every `href` and `pushUrl`.
    The four routes themselves stay base-free.

  - **Today.** `Leaf.Calendar` needs a `today`, and the theme screenshots have
    to be byte-identical from one run to the next, so it is the fixed date
    `2026-09-07` rather than a `Time.now` task. A real application would read
    the clock in `init`; nothing else about the wiring would change.

This module imports no `Html` at all: `Browser.Document` gives the `view`
signature and `Daisy.Render.page` produces the body, and no `port` either: all
three live in `demo/src/Ports.elm`, which `subscriptions` and `update` call like
any other module.

-}

import BasePath
import Browser
import Browser.Navigation as Nav
import Daisy.Render
import Daisy.Tree as Tree exposing (Theme(..))
import Date exposing (Date)
import Demo.Admin
import Demo.Analytics
import Demo.Settings
import Demo.ThemeGenerator as ThemeGenerator
import Demo.Themes
import Ports
import Process
import Task
import Time
import Url



-- MAIN ----------------------------------------------------------------------


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }



-- ROUTE ---------------------------------------------------------------------


type Route
    = AdminRoute
    | AnalyticsRoute
    | SettingsRoute
    | ThemeRoute


{-| What `demo/src/main.js` hands over. `basePath` is Vite's `BASE_URL`: `"/"`
for the dev server, `vite preview` and Playwright, `"/elm-daisyui/"` for the
GitHub Pages build.
-}
type alias Flags =
    { basePath : String }


routeFromUrl : String -> Url.Url -> Route
routeFromUrl basePath url =
    Maybe.withDefault AdminRoute (routeFor basePath url)


{-| The route a URL names, or `Nothing` for a path this application does not
own — `<base>docs/`, the generated documentation site that
`tools/build-docs-site.js` writes beside the demo. `UrlRequested` needs the
difference: a link to a non-route has to be a real page load, not a `pushUrl`
that would land back on the dashboard.
-}
routeFor : String -> Url.Url -> Maybe Route
routeFor basePath url =
    case normalisePath (BasePath.strip basePath url.path) of
        "/" ->
            Just AdminRoute

        "/analytics" ->
            Just AnalyticsRoute

        "/settings" ->
            Just SettingsRoute

        "/theme" ->
            Just ThemeRoute

        _ ->
            Nothing


normalisePath : String -> String
normalisePath path =
    if String.endsWith "/" path && String.length path > 1 then
        String.dropRight 1 path

    else
        path


{-| `?theme=<name>` wins over the default, for any of the 35 built-ins or
`acme`.
-}
themeFromUrl : Url.Url -> Theme
themeFromUrl url =
    url.query
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.filterMap themeFromPair
        |> List.head
        |> Maybe.withDefault defaultTheme


{-| The demo's default: `acme`, a theme daisyUI does not ship.

It is a `Daisy.Tree.Theme.Custom`, so nothing in `demo/app.css` declares it —
`Daisy.Render.page` writes its twenty-nine declarations onto the page root as
inline CSS custom properties, and daisyUI's components read them from there.

-}
defaultTheme : Theme
defaultTheme =
    Tree.Custom Demo.Themes.acme


themeFromPair : String -> Maybe Theme
themeFromPair pair =
    case String.split "=" pair of
        [ key, value ] ->
            if key == "theme" then
                Demo.Themes.named value

            else
                Nothing

        _ ->
            Nothing



-- MODEL ---------------------------------------------------------------------


type alias Model =
    { key : Nav.Key
    , basePath : String
    , route : Route
    , theme : Theme
    , lastMsg : String
    , toastVisible : Bool
    , modalOpen : Bool
    , search : String
    , dateRange : String
    , calendar : Tree.CalendarState
    , dateRangeCaption : String
    , workspaceName : String
    , contactEmail : String
    , currency : String
    , retention : String
    , digest : Bool
    , anonymize : Bool
    , generatorUrl : String
    , themeSeed : Int
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , basePath = flags.basePath
      , route = routeFromUrl flags.basePath url
      , theme = themeFromUrl url
      , lastMsg = "none"
      , toastVisible = False
      , modalOpen = False
      , search = ""
      , dateRange = firstOr "Last 30 days" (List.drop 1 Demo.Analytics.dateRanges)
      , calendar = Daisy.Render.initCalendarRange analyticsCalendarConfig Nothing
      , dateRangeCaption = noRangeCaption
      , workspaceName = "Acme Inc"
      , contactEmail = "ops@acme.test"
      , currency = firstOr "USD" Demo.Settings.currencies
      , retention = firstOr "90 days" (List.drop 1 Demo.Settings.retentionWindows)
      , digest = True
      , anonymize = False
      , generatorUrl = generatorFallback
      , themeSeed = 0
      }
    , Ports.encodeTheme (ThemeGenerator.exportJson (Demo.Themes.rename (themeFromUrl url)))
    )


{-| The link the export card shows until the first `Ports.themeEncoded` lands.

Compressing a theme into daisyUI's `#theme=` hash goes through
`CompressionStream`, which is asynchronous, so the anchor needs a real `href`
from the very first render. The bare generator URL is that href: it opens the
tool, just without this theme in it.

-}
generatorFallback : String
generatorFallback =
    "https://daisyui.com/theme-generator/"


firstOr : String -> List String -> String
firstOr fallback list =
    Maybe.withDefault fallback (List.head list)


{-| The demo's "today". Fixed on purpose: `e2e/themes.spec.ts` compares 105
full-page screenshots byte for byte, and a calendar drawn from the real clock
would move its `today` highlight — and, at a month boundary, its whole grid —
every day. A real application would use `Task.perform ... Date.today` in
`init`.
-}
today : Date
today =
    Date.fromCalendarDate 2026 Time.Sep 7


{-| The one `CalendarConfig` for the analytics range picker. `Demo.Analytics`
owns it (the id and month count must match what it renders); `init` and
`update` use it to build and advance the state.
-}
analyticsCalendarConfig : Tree.CalendarConfig Msg
analyticsCalendarConfig =
    Demo.Analytics.calendarConfig
        { today = today
        , toMsg = CalendarMsg
        , onChange = DateRangeChanged
        }


noRangeCaption : String
noRangeCaption =
    "No range picked yet — click a start day, then an end day."



-- UPDATE --------------------------------------------------------------------


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | NavigateTo String
    | ThemeChanged Theme
    | SearchChanged String
    | NotificationsOpened
    | ExportClicked
    | ToastDismissed
    | OrderViewed String
    | RangeSelected String
    | CalendarMsg Tree.CalendarMsg
    | DateRangeChanged Tree.CalendarValue
    | DownloadClicked
    | WorkspaceNameChanged String
    | ContactEmailChanged String
    | CurrencySelected String
    | RetentionSelected String
    | DigestToggled Bool
    | AnonymizeToggled Bool
    | SaveClicked
    | DeleteRequested
    | ModalConfirmed
    | ModalCancelled
    | ThemeEdited ThemeGenerator.ThemeEdit
    | ThemeExported
    | ThemeLinkReady String


{-| The constructor name of a `Msg`, for the debug pane, or `Nothing` for a
message the pane deliberately ignores. Payloads are left off so the pane's
text is exactly one stable token per constructor.

`CalendarMsg` and `ThemeLinkReady` are the two `Nothing`s: see the module
comment. Both arrive _after_ the message that caused them and neither is a
message the application acted on.

-}
paneName : Msg -> Maybe String
paneName msg =
    case msg of
        CalendarMsg _ ->
            Nothing

        ThemeLinkReady _ ->
            Nothing

        _ ->
            Just (msgName msg)


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

        SearchChanged _ ->
            "SearchChanged"

        NotificationsOpened ->
            "NotificationsOpened"

        ExportClicked ->
            "ExportClicked"

        ToastDismissed ->
            "ToastDismissed"

        OrderViewed _ ->
            "OrderViewed"

        RangeSelected _ ->
            "RangeSelected"

        CalendarMsg _ ->
            "CalendarMsg"

        DateRangeChanged _ ->
            "DateRangeChanged"

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

        DeleteRequested ->
            "DeleteRequested"

        ModalConfirmed ->
            "ModalConfirmed"

        ModalCancelled ->
            "ModalCancelled"

        ThemeEdited _ ->
            "ThemeEdited"

        ThemeExported ->
            "ThemeExported"

        ThemeLinkReady _ ->
            "ThemeLinkReady"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( updated, command ) =
            step msg model
    in
    ( case paneName msg of
        Just name ->
            { updated | lastMsg = name }

        Nothing ->
            updated
    , command
    )


step : Msg -> Model -> ( Model, Cmd Msg )
step msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            case routeFor model.basePath url of
                Just _ ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Nothing ->
                    ( model, Nav.load (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            ( { model | route = routeFromUrl model.basePath url }, Cmd.none )

        NavigateTo path ->
            ( model, Nav.pushUrl model.key (BasePath.join model.basePath path) )

        ThemeChanged theme ->
            ( { model | theme = theme }, Cmd.none )

        SearchChanged text ->
            ( { model | search = text }, Cmd.none )

        NotificationsOpened ->
            ( model, Cmd.none )

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

        CalendarMsg calendarMsg ->
            let
                ( calendar, command ) =
                    Daisy.Render.updateCalendar analyticsCalendarConfig calendarMsg model.calendar
            in
            ( { model | calendar = calendar }, command )

        DateRangeChanged value ->
            ( { model
                | calendar = Tree.setCalendarValue value model.calendar
                , dateRangeCaption = rangeCaption value
              }
            , Cmd.none
            )

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

        DeleteRequested ->
            ( { model | modalOpen = True }, Cmd.none )

        ModalConfirmed ->
            ( { model | modalOpen = False }, Cmd.none )

        ModalCancelled ->
            ( { model | modalOpen = False }, Cmd.none )

        ThemeEdited edit ->
            let
                edited : Tree.CustomTheme
                edited =
                    ThemeGenerator.apply model.themeSeed edit (editedTheme model.theme)
            in
            ( { model | theme = Custom edited, themeSeed = model.themeSeed + 1 }
            , Ports.encodeTheme (ThemeGenerator.exportJson edited)
            )

        ThemeExported ->
            ( model
            , Ports.copyToClipboard (ThemeGenerator.exportCss (editedTheme model.theme))
            )

        ThemeLinkReady url ->
            ( { model | generatorUrl = url }, Cmd.none )


{-| The caption under the picker. A `Cally.Range` value is sorted already, so
this only has to format it.
-}
rangeCaption : Tree.CalendarValue -> String
rangeCaption value =
    case value of
        Tree.PickedRange (Just ( from, to )) ->
            Date.toIsoString from ++ " to " ++ Date.toIsoString to

        _ ->
            noRangeCaption


{-| The theme the `/theme` editor is showing.

The router keeps one `Theme`, which is either a built-in name or a
`CustomTheme`. `Demo.Themes.rename` covers both: a built-in becomes its
`Daisy.Themes` values under the demo's own `acme` name, and a `Custom` is
already what is wanted. That renaming is what makes `?theme=nord` on `/theme`
open the editor _on_ nord's palette while still rendering `data-theme="acme"`,
so the page can only be painted by the inline properties.

-}
editedTheme : Theme -> Tree.CustomTheme
editedTheme =
    Demo.Themes.rename



-- SUBSCRIPTIONS -------------------------------------------------------------


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.themeEncoded ThemeLinkReady



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

        ThemeRoute ->
            "Acme Console — Theme generator"


pageFor : Model -> Tree.Page Msg
pageFor model =
    case model.route of
        AdminRoute ->
            Demo.Admin.page
                { basePath = model.basePath
                , theme = model.theme
                , lastMsg = model.lastMsg
                , toastVisible = model.toastVisible
                , search = model.search
                , onNavigate = NavigateTo
                , onTheme = ThemeChanged
                , onSearch = SearchChanged
                , onNotifications = NotificationsOpened
                , onExport = ExportClicked
                , onRowAction = OrderViewed
                }

        AnalyticsRoute ->
            Demo.Analytics.page
                { basePath = model.basePath
                , theme = model.theme
                , lastMsg = model.lastMsg
                , dateRange = model.dateRange
                , dateRangeCaption = model.dateRangeCaption
                , calendar = model.calendar
                , today = today
                , onNavigate = NavigateTo
                , onRangeSelect = RangeSelected
                , onCalendarMsg = CalendarMsg
                , onCalendarChange = DateRangeChanged
                , onNotifications = NotificationsOpened
                , onDownload = DownloadClicked
                }

        SettingsRoute ->
            Demo.Settings.page
                { basePath = model.basePath
                , theme = model.theme
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
                , onDelete = DeleteRequested
                , onConfirm = ModalConfirmed
                , onCancel = ModalCancelled
                }

        ThemeRoute ->
            ThemeGenerator.page
                { basePath = model.basePath
                , edited = editedTheme model.theme
                , lastMsg = model.lastMsg
                , generatorUrl = model.generatorUrl
                , onNavigate = NavigateTo
                , onEdit = ThemeEdited
                , onExport = ThemeExported
                }
