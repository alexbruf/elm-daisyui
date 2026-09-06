module Helpers.ClassesTest exposing (suite)

{-| The other Tier A tests all read rendered classes back through
`Helpers.Classes`, which parses elm-test's own HTML printer. If that printer
ever changes shape, the parse would quietly return nothing and every test built
on it would pass vacuously. These tests pin the parse down against renders
whose classes are known by hand, and check that the two problem detectors
actually fire on a hand-built offending element.
-}

import Daisy.Render as Render
import Daisy.Schema.Badge as SBadge
import Daisy.Schema.Card as SCard
import Daisy.Tree exposing (..)
import Expect
import Helpers.Classes as Classes
import Set
import Test exposing (Test, describe, test)


badge : Classes.Element
badge =
    Render.leaf (Badge { defaultBadgeConfig | color = List.head SBadge.allColors } "9")
        |> Classes.elementsIn
        |> List.head
        |> Maybe.withDefault { index = 0, parent = Nothing, depth = 0, tag = "none", classes = Set.empty, ancestors = [] }


card : List Classes.Element
card =
    Render.block (Card defaultCardConfig { emptyCardParts | title = Just "Title" })
        |> Classes.elementsIn


suite : Test
suite =
    describe "reading classes back out of rendered Html"
        [ test "an element's tag is parsed" <|
            \_ -> Expect.equal "span" badge.tag
        , test "an element's classes are parsed" <|
            \_ ->
                Expect.equal
                    (Set.fromList
                        (SBadge.component
                            :: List.map SBadge.colorToClass (List.take 1 SBadge.allColors)
                        )
                    )
                    badge.classes
        , test "a nested element records its ancestors" <|
            \_ ->
                let
                    titlePart =
                        List.head SCard.parts |> Maybe.withDefault ""
                in
                card
                    |> List.filter (\element -> Set.member titlePart element.classes)
                    |> List.concatMap .ancestors
                    |> List.any (Set.member SCard.component)
                    |> Expect.equal True
        , test "depth grows with nesting" <|
            \_ ->
                card
                    |> List.map .depth
                    |> List.maximum
                    |> Expect.equal (Just 3)
        , test "an exclusive-group clash is detected" <|
            \_ ->
                [ { index = 0
                  , parent = Nothing
                  , depth = 0
                  , tag = "span"
                  , classes = Set.fromList (List.map SBadge.colorToClass (List.take 2 SBadge.allColors))
                  , ancestors = []
                  }
                ]
                    |> Classes.exclusivityProblems
                    |> List.length
                    |> Expect.equal 1
        , test "an orphaned part is detected" <|
            \_ ->
                [ { index = 0
                  , parent = Nothing
                  , depth = 0
                  , tag = "div"
                  , classes = Set.fromList (List.take 1 SCard.parts)
                  , ancestors = [ Set.empty ]
                  }
                ]
                    |> Classes.partProblems
                    |> List.length
                    |> Expect.equal 1
        , test "a well-formed render has no problems" <|
            \_ ->
                Classes.expectNoProblems
                    (Classes.exclusivityProblems card ++ Classes.partProblems card)
        ]
