module RenderPurityTest exposing (suite)

{-| Tier A, row 4: rendering is a pure function of the tree, and the class
budget is closed.

Two claims:

1.  Equal trees render to equal `Html`. Structural equality is checked both
    directly (`Expect.equal` on two renders of one handler-free tree) and
    through the printed markup, which also covers attributes and text.
2.  Every class the renderer emits is either a daisyUI class from
    `Daisy.Schema.allClasses` or a layout token from `Daisy.Render.tokens`,
    the two delegated libraries (`terezka/elm-charts` inside `Block.Chart`,
    `alexbruf/elm-cally` inside `Leaf.Calendar`) aside — see
    `chartLibraryPrefix` and `calendarLibraryClasses`, each pinned by its own
    test.
    `Helpers.Classes` enumerates the classes actually emitted across every
    fixture, so this is an exhaustive check rather than a spot check. The list
    of plausible-but-forbidden utilities below is a second, independent
    formulation of the same rule through `Test.Html.Query`, and
    `tools/render-class-audit.js` checks the source statically: no string
    literal in `Daisy.Render` may be a daisyUI class, and every literal that
    looks like a utility must be a `tokens` entry.

-}

import Daisy.Render as Render
import Daisy.Schema as Schema
import Daisy.Tree exposing (..)
import Expect
import Helpers.Classes as Classes
import Helpers.Fixtures as Fixtures exposing (Msg(..))
import Set exposing (Set)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


allowed : Set String
allowed =
    Set.union Schema.allClasses (Set.fromList Render.tokens)


{-| `terezka/elm-charts` writes its own class names onto the SVG it builds
(`elm-charts__container`, `elm-charts__bar`, ...). They are the charting
library's internal styling hooks inside `Block.Chart`, not classes
`Daisy.Render` chooses, and they are neither daisyUI classes nor Tailwind
utilities. The budget rule therefore reads "everything the renderer chooses",
and a separate test pins down that every class outside the budget carries this
prefix or is one of the two `calendarLibraryClasses` below, so nothing else can
hide behind the exception.
-}
chartLibraryPrefix : String
chartLibraryPrefix =
    "elm-charts__"


{-| `alexbruf/elm-cally` writes exactly two class names of its own inside
`Leaf.Calendar`, and no others: `vh` on the visually-hidden live region and the
`<th>`/day labels, and `num` on the tabular-numeral cells. Everything else it
emits is a `part` attribute, which is not a class at all.

They are **not** added to `Render.tokens`. `tokens` is the list of utilities
`Daisy.Render` may _choose to emit_, and every entry there has a named constant
in `Render.elm`; these two are chosen by the picker, exactly like the
`elm-charts__` names above, and `demo/cally-base.css` is what styles them. The
honest statement is "the renderer's own budget is closed, and two foreign
libraries bring their own class names", which is what the two tests below say —
the first exempts them, the second pins the exemption to this exact list so a
third name could not appear unnoticed.

-}
calendarLibraryClasses : Set String
calendarLibraryClasses =
    Set.fromList [ "vh", "num" ]


{-| A class the renderer did not choose: it came from one of the two libraries
a leaf/block delegates to.
-}
fromLibrary : String -> Bool
fromLibrary class =
    String.startsWith chartLibraryPrefix class || Set.member class calendarLibraryClasses


outsideBudget : Set String
outsideBudget =
    Set.diff emitted allowed


emitted : Set String
emitted =
    Fixtures.groups
        |> List.foldl (\( _, html ) acc -> Set.union (Classes.allClassesIn html) acc) Set.empty


{-| Utilities a renderer is tempted to sprinkle inline. None of them may appear
in any render: spacing, sizing and colour are decided by `Render.tokens`, and
`btn-primary` may only come from `Page.cta`.

Four entries have left this list, each because it became a named `Daisy.Render`
token with one job, not because a render wanted room.

Three went in the Nexus design pass (2026-09-07):

  - `gap-6` is `tokenGapMd`, the single vertical rhythm between the bands of a
    page.
  - `text-xs` is `tokenTextXs`, the caption step — a chart legend, the second
    line of a `Leaf.UserChip`.
  - `rounded-lg` is `tokenRoundedLg`, the fixed 8px corner of the small
    surfaces the renderer paints itself (`stat-figure`'s tile, a boxed user
    chip). `rounded-box` stays forbidden: it resolves to `--radius-box`, which
    is 1rem or more in daisyUI's stock themes, so a 36px square would come out
    a circle.

The fourth went in the custom-theme pass (2026-09-07):

  - `bg-primary` is `tokenSwatchBgPrimary`, one of the eighteen colour tokens
    `Leaf.Swatch` paints a palette chip from. A swatch is a picture of a theme
    variable, not a component, so daisyUI ships no class for it and the pair
    (`bg-primary` + `text-primary-content`) has to be named in the renderer. Each
    constant has exactly one use site, `Daisy.Render.swatchClasses`, and no
    caller can reach one: `Leaf.Swatch` takes a closed
    `Daisy.Tree.SwatchColor`, never a class.

`text-primary` did **not** follow it and stays forbidden: it is a _foreground_
utility over an arbitrary element, which is exactly the sprinkled colour this
list exists to prevent, and no swatch needs it — a chip's foreground is
`text-primary-content`, the colour daisyUI itself pairs with that surface.

`opacity-50` also stays: de-emphasis is `tokenTextMuted`
(`text-base-content/60`), which is the colour daisyUI's own `.stat-title` and
`.stat-desc` paint, and which `e2e/contrast.spec.ts` therefore classifies as
daisyUI's own colour pair. A blanket `opacity-*` on an element would dim it
_without_ changing the computed `color`, which is invisible to that classifier —
a de-emphasis that fails contrast and reads as passing.

-}
forbidden : List String
forbidden =
    [ "mt-4"
    , "mb-4"
    , "px-6"
    , "py-6"
    , "m-2"
    , "gap-10"
    , "text-lg"
    , "shadow-xl"
    , "shadow-md"
    , "rounded-box"
    , "w-96"
    , "w-32"
    , "h-32"
    , "bg-white"
    , "text-primary"
    , "grid-cols-5"
    , "grid-cols-6"
    , "max-w-md"
    , "space-y-4"
    , "border"
    , "opacity-50"
    ]


{-| A tree with no event handlers, so `Expect.equal` can compare the rendered
values themselves (Elm cannot compare functions).
-}
staticPage : Page Msg
staticPage =
    Page
        { header = Nothing
        , shell = Dashboard (dashboardShell { config = defaultMenuConfig, items = [ menuItem "Home" ] })
        , sections =
            Sections2
                (Stack defaultStackConfig [ Card defaultCardConfig { emptyCardParts | title = Just "Title" } ])
                (Grid defaultGridConfig [ Stat defaultStatConfig [ emptyStatItem "Downloads" "31K" ] ])
        , cta = staticCta
        , overlays = [ Modal defaultModalConfig [ Prose [ Text "sure?" ] ] ]
        , theme = Dark
        , dock = Nothing
        , fab = Nothing
        }


staticCta : Cta Msg
staticCta =
    let
        base =
            cta "Save" Clicked
    in
    { base | onClick = Clicked }


suite : Test
suite =
    describe "render purity"
        [ describe "equal trees render to equal Html"
            [ test "two renders of one page are equal values" <|
                \_ -> Expect.equal (Render.page staticPage) (Render.page staticPage)
            , test "two renders of one page print the same markup" <|
                \_ ->
                    Expect.equal
                        (Classes.dump (Render.page staticPage))
                        (Classes.dump (Render.page staticPage))
            , test "two renders of one block are equal values" <|
                \_ ->
                    let
                        card =
                            Card defaultCardConfig { emptyCardParts | title = Just "Title" }
                    in
                    Expect.equal (Render.block card) (Render.block card)
            , test "every fixture group renders identically twice" <|
                \_ ->
                    Expect.equalLists
                        (List.map (Tuple.second >> Classes.dump) Fixtures.groups)
                        (List.map (Tuple.second >> Classes.dump) Fixtures.groups)
            ]
        , describe "the class budget is closed"
            [ test "every emitted class is a schema class or a render token" <|
                \_ ->
                    outsideBudget
                        |> Set.filter (\class -> not (fromLibrary class))
                        |> Set.toList
                        |> List.map (\class -> class ++ " is neither in Schema.allClasses nor in Render.tokens")
                        |> Classes.expectNoProblems
            , test "the only classes outside the budget come from elm-charts or elm-cally" <|
                \_ ->
                    outsideBudget
                        |> Set.toList
                        |> List.filter (\class -> not (fromLibrary class))
                        |> Expect.equalLists []
            , test "elm-cally contributes exactly the two classes it is exempted for" <|
                \_ ->
                    Set.intersect emitted calendarLibraryClasses
                        |> Expect.equal calendarLibraryClasses
            , test "at least one token is actually used" <|
                \_ ->
                    Set.intersect emitted (Set.fromList Render.tokens)
                        |> Set.size
                        |> Expect.greaterThan 20
            , test "every token is a plain utility, never a daisyUI class" <|
                \_ ->
                    Set.intersect (Set.fromList Render.tokens) Schema.allClasses
                        |> Set.toList
                        |> List.map (\class -> class ++ " is a daisyUI class listed as a layout token")
                        |> Classes.expectNoProblems
            ]
        , describe "no forbidden utility is emitted"
            (List.map
                (\class ->
                    test class <|
                        \_ ->
                            Fixtures.groups
                                |> List.filter
                                    (\( _, html ) -> Set.member class (Classes.allClassesIn html))
                                |> List.map (\( name, _ ) -> name ++ " emits " ++ class)
                                |> Classes.expectNoProblems
                )
                forbidden
            )
        , describe "cross-checked with Test.Html.Query"
            (List.map
                (\class ->
                    test class <|
                        \_ ->
                            Query.fromHtml (Render.page staticPage)
                                |> Query.findAll [ Selector.class class ]
                                |> Query.count (Expect.equal 0)
                )
                forbidden
            )
        ]
