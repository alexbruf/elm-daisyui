module PartsTest exposing (suite)

{-| Tier A, row 3: every element carrying a `part` class sits inside an element
carrying the matching `component` class.

`Helpers.Classes` reconstructs the ancestor chain of every rendered element
from elm-test's indented HTML dump, so the check is "some ancestor carries the
component", not merely "the component appears somewhere in the render". A few
parts are declared by more than one component (`join-item` belongs to `join`
and, through `pagination`, to `join` again), so an element passes when any one
of its declared owners encloses it.

The last describe re-asks the same question through `Test.Html.Query`, which
cannot enumerate elements but can count them, as an independent check on the
parser.

-}

import Daisy.Render as Render
import Daisy.Schema as Schema
import Daisy.Schema.Card as SCard
import Daisy.Schema.Modal as SModal
import Daisy.Schema.Navbar as SNavbar
import Daisy.Schema.Stat as SStat
import Daisy.Tree exposing (..)
import Expect
import Helpers.Classes as Classes
import Helpers.Fixtures as Fixtures exposing (Msg)
import Html exposing (Html)
import Set
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


{-| Every element of every fixture, with its ancestors.
-}
allElements : List Classes.Element
allElements =
    List.concatMap (\( _, html ) -> Classes.elementsIn html) Fixtures.groups


elementsWith : String -> List Classes.Element
elementsWith class =
    List.filter (\element -> Set.member class element.classes) allElements


suite : Test
suite =
    describe "parts stay inside their component"
        [ describe "every part is exercised by a fixture"
            (List.map
                (\entry ->
                    test (entry.component ++ " / " ++ entry.part) <|
                        \_ ->
                            elementsWith entry.part
                                |> List.length
                                |> Expect.greaterThan 0
                )
                (dedupeParts Schema.parts)
            )
        , describe "every part sits inside its component"
            (List.map
                (\entry ->
                    test (entry.component ++ " / " ++ entry.part) <|
                        \_ ->
                            elementsWith entry.part
                                |> List.filter
                                    (\element ->
                                        not (List.any (Set.member entry.component) element.ancestors)
                                    )
                                |> List.map (\element -> "<" ++ element.tag ++ "> outside " ++ entry.component)
                                |> Classes.expectNoProblems
                )
                (List.filter
                    (\entry -> not (List.member entry.part Classes.siblingParts))
                    (dedupeParts Schema.parts)
                )
            )
        , describe "no fixture has an orphaned part"
            (List.map
                (\( name, html ) ->
                    test name <|
                        \_ -> Classes.expectNoProblems (Classes.partProblems (Classes.elementsIn html))
                )
                Fixtures.groups
            )
        , describe "sibling parts follow their component"
            (List.map
                (\( name, html ) ->
                    test name <|
                        \_ ->
                            Classes.expectNoProblems
                                (Classes.siblingPartProblems (Classes.elementsIn html))
                )
                Fixtures.groups
            )
        , describe "cross-checked with Test.Html.Query"
            [ test "card-body only appears inside a card" <|
                \_ -> expectPartUnderComponent SCard.component (partAt 1 SCard.parts) cardHtml
            , test "card-title only appears inside a card" <|
                \_ -> expectPartUnderComponent SCard.component (partAt 0 SCard.parts) cardHtml
            , test "stat only appears inside stats" <|
                \_ -> expectPartUnderComponent SStat.component (partAt 0 SStat.parts) statHtml
            , test "modal-box only appears inside a modal" <|
                \_ -> expectPartUnderComponent SModal.component (partAt 0 SModal.parts) modalHtml
            , test "navbar-start only appears inside a navbar" <|
                \_ -> expectPartUnderComponent SNavbar.component (partAt 0 SNavbar.parts) navbarHtml
            ]
        ]


{-| Parts declared by more than one component are checked once per owner
elsewhere; here one entry per part class is enough.
-}
dedupeParts : List { component : String, part : String } -> List { component : String, part : String }
dedupeParts entries =
    List.foldl
        (\entry acc ->
            if List.any (\seen -> seen.part == entry.part) acc then
                acc

            else
                acc ++ [ entry ]
        )
        []
        entries


partAt : Int -> List String -> String
partAt index list =
    List.drop index list |> List.head |> Maybe.withDefault ""


{-| The number of elements carrying `part` under the one element carrying
`component` equals the number in the whole render.
-}
expectPartUnderComponent : String -> String -> Query.Single Msg -> Expect.Expectation
expectPartUnderComponent component part query =
    let
        inside =
            query
                |> Query.find [ Selector.class component ]
                |> Query.findAll [ Selector.class part ]

        everywhere =
            query |> Query.findAll [ Selector.class part ]
    in
    Expect.all
        [ \_ -> inside |> Query.count (Expect.greaterThan 0)
        , \_ -> everywhere |> Query.count (Expect.greaterThan 0)
        ]
        ()


{-| `Query.find` looks at descendants only, so each render is wrapped in a
plain element to make the component itself findable.
-}
wrapped : Html Msg -> Query.Single Msg
wrapped html =
    Query.fromHtml (Html.div [] [ html ])


cardHtml : Query.Single Msg
cardHtml =
    wrapped (Render.block (Card defaultCardConfig { emptyCardParts | title = Just "Title" }))


statHtml : Query.Single Msg
statHtml =
    wrapped (Render.block (Stat defaultStatConfig [ emptyStatItem "Downloads" "31K" ]))


modalHtml : Query.Single Msg
modalHtml =
    wrapped (Render.overlay (Modal defaultModalConfig [ Prose [ Text "body" ] ]))


navbarHtml : Query.Single Msg
navbarHtml =
    wrapped (Render.section (Navbar { emptyNavbarParts | start = [ Text "Start" ] }))
